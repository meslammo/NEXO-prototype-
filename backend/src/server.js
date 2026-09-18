const Fastify = require('fastify');
const cors = require('@fastify/cors');
const helmet = require('@fastify/helmet');
const rateLimit = require('@fastify/rate-limit');
const { androidpublisher } = require('@googleapis/androidpublisher');
const { JWT } = require('google-auth-library');
const jwt = require('@fastify/jwt');
const websocket = require('@fastify/websocket');
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');
const { randomUUID } = require('crypto');
const fs = require('fs');
const path = require('path');

const app = Fastify({ logger: true });
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.PGSSL === 'false' ? false : { rejectUnauthorized: false }
});
const PORT = Number(process.env.PORT || 3000);
const JWT_SECRET = process.env.JWT_SECRET || '';
if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
if (JWT_SECRET.length < 32) throw new Error('JWT_SECRET must be 32+ chars');

app.register(cors, { origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : true });
app.register(helmet, { global: true });
app.register(rateLimit, { global: true, max: 120, timeWindow: '1 minute', keyGenerator: (req) => req.ip });
app.register(jwt, { secret: JWT_SECRET });
app.register(websocket);

const sockets = new Map();
const q = (sql, params) => pool.query(sql, params || []);
const uid = (req) => req.user.sub;

async function auth(req, reply) {
  try { await req.jwtVerify(); }
  catch (_) { return reply.code(401).send({ error: 'UNAUTHORIZED' }); }
}


const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
async function resolveUserId(db, reference) {
  const value = String(reference || '').trim();
  if (!value) throw Object.assign(new Error('INVALID_USER'), { code: 400 });
  if (UUID_RE.test(value)) {
    const r = await db.query('SELECT id FROM nexo.users WHERE id=$1', [value]);
    if (r.rowCount) return r.rows[0].id;
  }
  const r = await db.query('SELECT id FROM nexo.users WHERE lower(username)=lower($1)', [value]);
  if (!r.rowCount) throw Object.assign(new Error('USER_NOT_FOUND'), { code: 404 });
  return r.rows[0].id;
}

async function tx(fn) {
  const client = await pool.connect();
  try { await client.query('BEGIN'); const out = await fn(client); await client.query('COMMIT'); return out; }
  catch (e) { await client.query('ROLLBACK'); throw e; }
  finally { client.release(); }
}

async function securityEvent(req, eventType, severity='info', details={}) {
  try {
    await q('INSERT INTO nexo.security_events(id,user_id,event_type,severity,ip,details) VALUES($1,$2,$3,$4,$5,$6::jsonb)',
      [randomUUID(),req.user?.sub || null,eventType,severity,req.ip,JSON.stringify(details)]);
  } catch (_) {}
}

async function notify(userId, kind, title, body, data={}) {
  try {
    const id=randomUUID();
    await q('INSERT INTO nexo.notifications(id,user_id,kind,title,body,data) VALUES($1,$2,$3,$4,$5,$6::jsonb)',[id,userId,kind,title,body,JSON.stringify(data)]);
    emit(userId,{type:'notification',notification:{id,userId,kind,title,body,data,read:false}});
  } catch (_) {}
}

function emit(toUserId, event) {
  const list = sockets.get(toUserId);
  if (!list) return;
  const raw = JSON.stringify(event);
  for (const ws of list) { try { ws.send(raw); } catch (_) {} }
}
function publicUser(u) {
  if (!u) return null;
  return {
    id:u.id, username:u.username, displayName:u.display_name, avatar:u.avatar,
    gems:Number(u.gems), energy:u.energy, level:u.level, experience:Number(u.experience),
    reputation:u.reputation, vipLevel:u.vip_level, nameColor:u.name_color, glow:u.glow,
    createdAt:u.created_at, lastActive:u.last_active
  };
}

app.get('/health', async (req, reply) => {
  try {
    await q('SELECT 1');
    return {ok:true,service:'nexo-api',database:'ok',time:new Date().toISOString()};
  } catch (_) {
    return reply.code(503).send({ok:false,service:'nexo-api',database:'down'});
  }
});
app.get('/rtc/config',{preHandler:auth},async(req)=>{
  let servers;
  try { servers=JSON.parse(process.env.RTC_ICE_SERVERS_JSON||'[{"urls":["stun:stun.l.google.com:19302"]}]'); }
  catch(_){ servers=[{urls:['stun:stun.l.google.com:19302']}]; }
  return {iceServers:servers};
});



app.post('/auth/guest', async (req, reply) => {
  const deviceId=String((req.body||{}).deviceId||'').trim().slice(0,60);
  const username='guest_'+(deviceId || randomUUID().slice(0,12));
  let r=await q('SELECT * FROM nexo.users WHERE username=$1',[username]);
  let u=r.rows[0];
  if(!u){ r=await q('INSERT INTO nexo.users(id,username,display_name) VALUES($1,$2,$3) RETURNING *',[randomUUID(),username,'NEXO Guest']); u=r.rows[0]; await q(`INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES ($1,'neon-heart',2),($1,'shadow-flame',1),($1,'galaxy-aura',1),($1,'crown-shine',1) ON CONFLICT(user_id,item_id) DO NOTHING`,[u.id]); }
  const token=app.jwt.sign({sub:u.id,username:u.username},{expiresIn:'30d'});
  return { token, user:publicUser(u) };
});

app.post('/auth/register', async (req, reply) => {
  const body=req.body||{}, email=String(body.email||'').trim().toLowerCase(), username=String(body.username||'').trim().toLowerCase(), password=String(body.password||'');
  if(!email||!username||password.length<8) return reply.code(400).send({error:'INVALID_INPUT'});
  const hash=await bcrypt.hash(password,12);
  try{
    const r=await q('INSERT INTO nexo.users(id,username,email,password_hash,display_name) VALUES($1,$2,$3,$4,$5) RETURNING *',[randomUUID(),username,email,hash,username]);
    const u=r.rows[0]; return {token:app.jwt.sign({sub:u.id,username:u.username},{expiresIn:'30d'}),user:publicUser(u)};
  }catch(_){ return reply.code(409).send({error:'ACCOUNT_EXISTS'}); }
});

app.post('/auth/login', async (req, reply) => {
  const body=req.body||{}, identity=String(body.identity||'').trim().toLowerCase(), password=String(body.password||'');
  const r=await q('SELECT * FROM nexo.users WHERE username=$1 OR email=$1 LIMIT 1',[identity]), u=r.rows[0];
  if(!u||!u.password_hash||!(await bcrypt.compare(password,u.password_hash))) return reply.code(401).send({error:'INVALID_CREDENTIALS'});
  await q('UPDATE nexo.users SET last_active=NOW() WHERE id=$1',[u.id]);
  return {token:app.jwt.sign({sub:u.id,username:u.username}),user:publicUser(u)};
});

app.get('/me',{preHandler:auth},async req=>{
  const r=await q('SELECT * FROM nexo.users WHERE id=$1',[uid(req)]); return {user:publicUser(r.rows[0])};
});
app.get('/notifications',{preHandler:auth},async req=>{
  return (await q('SELECT id,kind,title,body,data,read,created_at FROM nexo.notifications WHERE user_id=$1 ORDER BY created_at DESC LIMIT 100',[uid(req)])).rows;
});
app.post('/notifications/:id/read',{preHandler:auth},async(req,reply)=>{
  const r=await q('UPDATE nexo.notifications SET read=true WHERE id=$1 AND user_id=$2 RETURNING id',[req.params.id,uid(req)]);
  if(!r.rowCount)return reply.code(404).send({error:'NOTIFICATION_NOT_FOUND'});
  return {ok:true};
});
app.post('/notifications/read-all',{preHandler:auth},async req=>{
  await q('UPDATE nexo.notifications SET read=true WHERE user_id=$1 AND read=false',[uid(req)]);
  return {ok:true};
});

app.get('/gifts',async()=> (await q('SELECT id,name,rarity,gems,tradeable,image,tagline FROM nexo.gifts WHERE active=true ORDER BY gems')).rows);
app.get('/users/search', async (req, reply) => {
  const query = String((req.query || {}).q || '').trim().slice(0,40);
  if (!query) return [];
  return (await q(`SELECT u.id,u.username,u.display_name AS "displayName",u.avatar,u.name_color AS "nameColor",
    u.vip_level AS "vipLevel",COALESCE(p.online,false) AS online
    FROM nexo.users u LEFT JOIN nexo.presence p ON p.user_id=u.id
    WHERE lower(u.username) LIKE lower($1) OR lower(u.display_name) LIKE lower($1)
    ORDER BY online DESC,u.username ASC LIMIT 20`, ['%'+query+'%'])).rows;
});
app.get('/users/lookup/:reference', async (req, reply) => {
  try {
    const id = await resolveUserId({ query: q }, req.params.reference);
    const r = await q(`SELECT u.id,u.username,u.display_name AS "displayName",u.avatar,u.name_color AS "nameColor",
      u.vip_level AS "vipLevel",COALESCE(p.online,false) AS online
      FROM nexo.users u LEFT JOIN nexo.presence p ON p.user_id=u.id WHERE u.id=$1`,[id]);
    return r.rows[0] || reply.code(404).send({error:'USER_NOT_FOUND'});
  } catch(e){ return reply.code(e.code||500).send({error:e.code||'USER_LOOKUP_FAILED'}); }
});
app.get('/wallet',{preHandler:auth},async req=> (await q('SELECT gems,energy,level,experience,reputation,vip_level,name_color,glow FROM nexo.users WHERE id=$1',[uid(req)])).rows[0]);
app.get('/inventory',{preHandler:auth},async req=> (await q('SELECT i.item_id AS id,g.name,g.rarity,g.gems,g.tradeable,g.image,g.tagline,i.quantity FROM nexo.inventory i JOIN nexo.gifts g ON g.id=i.item_id WHERE i.user_id=$1 AND i.quantity>0 ORDER BY g.gems',[uid(req)])).rows);

app.post('/economy/energy/spend',{preHandler:auth},async(req,reply)=>{
  const amount=Number((req.body||{}).amount||0), key=String((req.body||{}).idempotencyKey||'');
  if(!Number.isInteger(amount)||amount<1||amount>100||!key){await securityEvent(req,'invalid_energy_spend','warning',{amount});return reply.code(400).send({error:'INVALID_INPUT'});}
  try{
    return await tx(async c=>{
      const prior=await c.query('SELECT balance_after FROM nexo.energy_ledger WHERE idempotency_key=$1',[key]);
      if(prior.rowCount)return {energy:prior.rows[0].balance_after};
      const u=await c.query('SELECT energy FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
      if(!u.rowCount||u.rows[0].energy<amount){await securityEvent(req,'energy_abuse_attempt','warning',{amount});throw Object.assign(new Error('INSUFFICIENT_ENERGY'),{code:409});}
      const energy=u.rows[0].energy-amount;
      await c.query('UPDATE nexo.users SET energy=$1,last_active=NOW() WHERE id=$2',[energy,uid(req)]);
      await c.query('INSERT INTO nexo.energy_ledger(id,user_id,kind,amount,balance_after,idempotency_key) VALUES($1,$2,$3,$4,$5,$6)',[randomUUID(),uid(req),'spend',-amount,energy,key]);
      return {energy};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'ENERGY_ERROR'});}
});

app.post('/economy/energy/daily-claim',{preHandler:auth},async(req,reply)=>{
  try{
    return await tx(async c=>{
      const today=(await c.query('SELECT CURRENT_DATE AS today')).rows[0].today;
      const existing=await c.query('SELECT claim_date,streak FROM nexo.daily_claims WHERE user_id=$1 FOR UPDATE',[uid(req)]);
      if(existing.rowCount && String(existing.rows[0].claim_date)===String(today)){
        const u=await c.query('SELECT energy FROM nexo.users WHERE id=$1',[uid(req)]);
        return {claimed:false,energy:Number(u.rows[0].energy),streak:Number(existing.rows[0].streak)};
      }
      const u=await c.query('SELECT energy FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
      const before=Number(u.rows[0].energy);
      const energy=Math.min(100,before+50);
      let streak=1;
      if(existing.rowCount){
        const prev=String(existing.rows[0].claim_date);
        const prior=await c.query('SELECT $1::date = CURRENT_DATE - INTERVAL \'1 day\' AS consecutive',[prev]);
        streak=prior.rows[0].consecutive ? Number(existing.rows[0].streak)+1 : 1;
        await c.query('UPDATE nexo.daily_claims SET claim_date=$1,streak=$2 WHERE user_id=$3',[today,streak,uid(req)]);
      }else{
        await c.query('INSERT INTO nexo.daily_claims(user_id,claim_date,streak) VALUES($1,$2,$3)',[uid(req),today,1]);
      }
      const delta=energy-before;
      await c.query('UPDATE nexo.users SET energy=$1,last_active=NOW() WHERE id=$2',[energy,uid(req)]);
      if(delta) await c.query('INSERT INTO nexo.energy_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',
        [randomUUID(),uid(req),'daily_claim',delta,energy,'daily:'+today,'daily:'+uid(req)+':'+today]);
      return {claimed:true,energy,streak};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'DAILY_CLAIM_FAILED'});}
});

app.post('/economy/energy/convert',{preHandler:auth},async(req,reply)=>{
  try{
    return await tx(async c=>{
      const u=await c.query('SELECT energy,gems FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
      if(!u.rowCount)return reply.code(404).send({error:'USER_NOT_FOUND'});
      if(Number(u.rows[0].energy)<100)return reply.code(409).send({error:'INSUFFICIENT_ENERGY'});
      const energy=Number(u.rows[0].energy)-100, gems=Number(u.rows[0].gems)+25;
      const key=String((req.body||{}).idempotencyKey||'');
      if(!key)return reply.code(400).send({error:'INVALID_INPUT'});
      const prior=await c.query('SELECT 1 FROM nexo.energy_ledger WHERE idempotency_key=$1',[key]);
      if(prior.rowCount)return {energy:Number(u.rows[0].energy),gems:Number(u.rows[0].gems),idempotent:true};
      await c.query('UPDATE nexo.users SET energy=$1,gems=$2,last_active=NOW() WHERE id=$3',[energy,gems,uid(req)]);
      await c.query('INSERT INTO nexo.energy_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',
        [randomUUID(),uid(req),'convert',-100,energy,'energy_to_gems',key]);
      await c.query('INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',
        [randomUUID(),uid(req),'energy_convert',25,gems,'energy_to_gems',key+':gems']);
      return {energy,gems,gemsAdded:25};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'ENERGY_CONVERT_FAILED'});}
});

app.post('/gifts/buy',{preHandler:auth},async(req,reply)=>{
  const giftId=String((req.body||{}).giftId||''), key=String((req.body||{}).idempotencyKey||'');
  if(!giftId||!key)return reply.code(400).send({error:'INVALID_INPUT'});
  try{
    return await tx(async c=>{
      const prior=await c.query('SELECT 1 FROM nexo.wallet_ledger WHERE idempotency_key=$1',[key]);
      if(prior.rowCount)return {ok:true,idempotent:true};
      const g=await c.query('SELECT * FROM nexo.gifts WHERE id=$1 AND active=true',[giftId]);
      if(!g.rowCount)throw Object.assign(new Error('GIFT_NOT_FOUND'),{code:404});
      const u=await c.query('SELECT gems FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]), price=g.rows[0].gems;
      if(Number(u.rows[0].gems)<price)throw Object.assign(new Error('INSUFFICIENT_GEMS'),{code:409});
      const gems=Number(u.rows[0].gems)-price;
      await c.query('UPDATE nexo.users SET gems=$1 WHERE id=$2',[gems,uid(req)]);
      await c.query('INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,1) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+1',[uid(req),giftId]);
      await c.query('INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',[randomUUID(),uid(req),'gift_purchase',-price,gems,giftId,key]);
      return {ok:true,gems,inventoryItem:giftId};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'GIFT_BUY_FAILED'});}
});

app.post('/chat/:peerId/messages',{preHandler:auth},async(req,reply)=>{
  try{
    const peerId=await resolveUserId({query:q},req.params.peerId);
    const body=String((req.body||{}).body||'').trim();
    if(!body||body.length>4000)return reply.code(400).send({error:'INVALID_MESSAGE'});
    const r=await q('INSERT INTO nexo.messages(id,sender_id,recipient_id,body) VALUES($1,$2,$3,$4) RETURNING *',[randomUUID(),uid(req),peerId,body]);
    const msg=r.rows[0]; emit(peerId,{type:'chat_message',message:msg}); await notify(peerId,'chat','رسالة جديدة','لديك رسالة جديدة في NEXO',{senderId:uid(req)}); return msg;
  }catch(e){return reply.code(e.code||500).send({error:e.code||'CHAT_SEND_FAILED'});}
});
app.get('/chat/:peerId/messages',{preHandler:auth},async(req,reply)=>{
  try{
    const peerId=await resolveUserId({query:q},req.params.peerId);
    return (await q('SELECT m.id,m.sender_id,m.recipient_id,m.kind,m.body,m.gift_id,m.created_at,u.username AS sender_username FROM nexo.messages m JOIN nexo.users u ON u.id=m.sender_id WHERE (m.sender_id=$1 AND m.recipient_id=$2) OR (m.sender_id=$2 AND m.recipient_id=$1) ORDER BY m.created_at ASC LIMIT 200',[uid(req),peerId])).rows;
  }catch(e){return reply.code(e.code||500).send({error:e.code||'CHAT_HISTORY_FAILED'});}
});
app.post('/gifts/send',{preHandler:auth},async(req,reply)=>{
  const b=req.body||{}, giftId=String(b.giftId||''), key=String(b.idempotencyKey||'');
  if(!giftId||!key)return reply.code(400).send({error:'INVALID_INPUT'});
  try{
    return await tx(async c=>{
      const to=await resolveUserId(c,b.toUserId);
      if(to===uid(req))throw Object.assign(new Error('INVALID_RECIPIENT'),{code:400});
      const prior=await c.query('SELECT 1 FROM nexo.wallet_ledger WHERE idempotency_key=$1',[key]);
      if(prior.rowCount)return {ok:true,idempotent:true};
      const g=await c.query('SELECT * FROM nexo.gifts WHERE id=$1 AND active=true',[giftId]);
      if(!g.rowCount)throw Object.assign(new Error('GIFT_NOT_FOUND'),{code:404});
      const own=await c.query('SELECT quantity FROM nexo.inventory WHERE user_id=$1 AND item_id=$2 FOR UPDATE',[uid(req),giftId]);
      if(own.rowCount&&own.rows[0].quantity>0){
        await c.query('UPDATE nexo.inventory SET quantity=quantity-1 WHERE user_id=$1 AND item_id=$2',[uid(req),giftId]);
        const bal=(await c.query('SELECT gems FROM nexo.users WHERE id=$1',[uid(req)])).rows[0].gems;
        await c.query('INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,0,$4,$5,$6)',[randomUUID(),uid(req),'gift_send_owned',bal,giftId,key]);
      } else {
        const price=g.rows[0].gems;
        const u=await c.query('SELECT gems FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
        if(Number(u.rows[0].gems)<price)throw Object.assign(new Error('INSUFFICIENT_GEMS'),{code:409});
        const gems=Number(u.rows[0].gems)-price;
        await c.query('UPDATE nexo.users SET gems=$1 WHERE id=$2',[gems,uid(req)]);
        await c.query('INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',[randomUUID(),uid(req),'gift_send_purchase',-price,gems,giftId,key]);
      }
      await c.query('INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,1) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+1',[to,giftId]);
      await c.query('INSERT INTO nexo.messages(id,sender_id,recipient_id,kind,gift_id) VALUES($1,$2,$3,\'gift\',$4)',[randomUUID(),uid(req),to,giftId]);
      emit(to,{type:'gift',from:uid(req),giftId});
      return {ok:true,giftId};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'GIFT_SEND_FAILED'});}
});
async function lockTradeItems(c, tradeId, ownerId, items, req) {
  if (!Array.isArray(items) || items.length > 4) throw Object.assign(new Error('MAX_4_TRADE_SLOTS'), { code: 400 });
  const seen = new Set();
  for (const it of items) {
    const itemId = String(it.itemId || '').trim();
    const quantity = Number(it.quantity || 1);
    if (!itemId || seen.has(itemId) || !Number.isInteger(quantity) || quantity < 1) {
      throw Object.assign(new Error('INVALID_TRADE_ITEM'), { code: 400 });
    }
    seen.add(itemId);
    const locked = await c.query(`SELECT 1 FROM nexo.trade_locks tl
      JOIN nexo.trades t ON t.id=tl.trade_id
      WHERE tl.user_id=$1 AND tl.item_id=$2
        AND t.status IN ('locked','confirmedA','confirmedB','disputed') LIMIT 1`, [ownerId, itemId]);
    if (locked.rowCount) throw Object.assign(new Error('ITEM_ALREADY_LOCKED'), { code: 409 });

    const own = await c.query(`SELECT i.quantity,g.tradeable FROM nexo.inventory i
      JOIN nexo.gifts g ON g.id=i.item_id WHERE i.user_id=$1 AND i.item_id=$2 FOR UPDATE`, [ownerId, itemId]);
    if (!own.rowCount || Number(own.rows[0].quantity) < quantity) {
      throw Object.assign(new Error('INSUFFICIENT_ITEM'), { code: 409 });
    }
    if (!own.rows[0].tradeable) { await securityEvent(req,'trade_nontradeable_item','warning',{itemId}); throw Object.assign(new Error('ITEM_NOT_TRADEABLE'), { code: 409 }); }

    await c.query('UPDATE nexo.inventory SET quantity=quantity-$1 WHERE user_id=$2 AND item_id=$3', [quantity, ownerId, itemId]);
    await c.query('INSERT INTO nexo.trade_locks(trade_id,user_id,item_id,quantity) VALUES($1,$2,$3,$4)', [tradeId, ownerId, itemId, quantity]);
  }
}

async function unlockTradeSide(c, tradeId, ownerId) {
  const locks = await c.query('SELECT item_id,quantity FROM nexo.trade_locks WHERE trade_id=$1 AND user_id=$2 FOR UPDATE', [tradeId, ownerId]);
  for (const item of locks.rows) {
    await c.query(`INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,$3)
      ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+EXCLUDED.quantity`,
      [ownerId, item.item_id, item.quantity]);
  }
  await c.query('DELETE FROM nexo.trade_locks WHERE trade_id=$1 AND user_id=$2', [tradeId, ownerId]);
}

async function validateTradeGems(c, ownerId, amount) {
  if (!Number.isInteger(amount) || amount < 0) throw Object.assign(new Error('INVALID_GEMS'), { code: 400 });
  if (amount === 0) return;
  const u = await c.query('SELECT gems FROM nexo.users WHERE id=$1 FOR UPDATE', [ownerId]);
  if (!u.rowCount || Number(u.rows[0].gems) < amount) throw Object.assign(new Error('INSUFFICIENT_GEMS'), { code: 409 });
}

app.post('/trades', { preHandler: auth }, async (req, reply) => {
  const b=req.body||{}, to=await resolveUserId({query:q},b.toUserId);
  const items=Array.isArray(b.fromItems)?b.fromItems:[], gems=Math.max(0,Number(b.fromGems||0));
  if(to===uid(req)) return reply.code(400).send({error:'INVALID_PEER'});
  try {
    return await tx(async c=>{
      await validateTradeGems(c,uid(req),gems);
      const id=randomUUID();
      await c.query(`INSERT INTO nexo.trades(id,from_user_id,to_user_id,from_items,from_gems,expires_at)
        VALUES($1,$2,$3,'[]'::jsonb,$4,NOW()+INTERVAL '24 hours')`,[id,uid(req),to,gems]);
      await lockTradeItems(c,id,uid(req),items,req);
      await c.query('UPDATE nexo.trades SET from_items=$1::jsonb WHERE id=$2',[JSON.stringify(items),id]);
      if(gems>0) await c.query('UPDATE nexo.users SET gems=gems-$1 WHERE id=$2',[gems,uid(req)]);
      emit(to,{type:'trade_created',tradeId:id}); await notify(to,'trade','عرض Trade جديد','لديك عرض Trade ينتظر الرد',{tradeId:id,fromUserId:uid(req)});
      return {id,status:'locked',fromItems:items,fromGems:gems,toItems:[],toGems:0};
    });
  } catch(e) { return reply.code(e.code||500).send({error:e.code||'TRADE_CREATE_FAILED'}); }
});

app.get('/trades/:id', { preHandler: auth }, async (req, reply) => {
  try {
    const r=await q('SELECT * FROM nexo.trades WHERE id=$1 AND (from_user_id=$2 OR to_user_id=$2)',[req.params.id,uid(req)]);
    if(!r.rowCount)return reply.code(404).send({error:'TRADE_NOT_FOUND'});
    const t=r.rows[0];
    if(new Date(t.expires_at).getTime()<Date.now() && ['locked','confirmedA','confirmedB'].includes(t.status)){
      await q('UPDATE nexo.trades SET status=\'expired\' WHERE id=$1',[t.id]);
      await tx(async c=>{
        await unlockTradeSide(c,t.id,t.from_user_id);
        await unlockTradeSide(c,t.id,t.to_user_id);
        if(Number(t.from_gems)>0)await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2',[t.from_gems,t.from_user_id]);
        if(Number(t.to_gems)>0)await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2',[t.to_gems,t.to_user_id]);
      });
      t.status='expired';
    }
    return t;
  } catch(e){return reply.code(e.code||500).send({error:e.code||'TRADE_GET_FAILED'});}
});

app.post('/trades/:id/offer',{ preHandler: auth }, async (req, reply) => {
  try {
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.trades WHERE id=$1 FOR UPDATE',[req.params.id]);
      if(!r.rowCount)return reply.code(404).send({error:'TRADE_NOT_FOUND'});
      const t=r.rows[0];
      if(t.to_user_id!==uid(req))throw Object.assign(new Error('FORBIDDEN'),{code:403});
      if(!['locked','confirmedB'].includes(t.status))throw Object.assign(new Error('TRADE_NOT_EDITABLE'),{code:409});
      if(new Date(t.expires_at).getTime()<Date.now())throw Object.assign(new Error('TRADE_EXPIRED'),{code:409});
      if(t.to_confirmed)throw Object.assign(new Error('TRADE_ALREADY_CONFIRMED'),{code:409});

      await unlockTradeSide(c,t.id,t.to_user_id);
      const b=req.body||{}, items=Array.isArray(b.toItems)?b.toItems:[], gems=Math.max(0,Number(b.toGems||0));
      await validateTradeGems(c,t.to_user_id,gems);
      await lockTradeItems(c,t.id,t.to_user_id,items,req);
      await c.query('UPDATE nexo.trades SET to_items=$1::jsonb,to_gems=$2,from_confirmed=false,to_confirmed=false,status=\'locked\' WHERE id=$3',[JSON.stringify(items),gems,t.id]);
      if(gems>0)await c.query('UPDATE nexo.users SET gems=gems-$1 WHERE id=$2',[gems,t.to_user_id]);
      emit(t.from_user_id,{type:'trade_update',tradeId:t.id,status:'locked'});
      return {id:t.id,status:'locked',fromItems:t.from_items,fromGems:Number(t.from_gems),toItems:items,toGems:gems};
    });
  } catch(e){return reply.code(e.code||500).send({error:e.code||'TRADE_OFFER_FAILED'});}
});

app.post('/trades/:id/confirm', { preHandler: auth }, async (req, reply) => {
  try {
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.trades WHERE id=$1 FOR UPDATE',[req.params.id]);
      if(!r.rowCount)return reply.code(404).send({error:'TRADE_NOT_FOUND'});
      const t=r.rows[0], from=t.from_user_id===uid(req), to=t.to_user_id===uid(req);
      if(!from&&!to)throw Object.assign(new Error('FORBIDDEN'),{code:403});
      if(!Array.isArray(t.to_items)||t.to_items.length<0)throw Object.assign(new Error('INVALID_TRADE'),{code:409});
      if(from)t.from_confirmed=true;if(to)t.to_confirmed=true;
      if(t.from_confirmed&&t.to_confirmed){
        const fee=Math.ceil((Number(t.from_gems)+Number(t.to_gems))*0.05);
        const feeFrom=Math.min(fee,Number(t.from_gems)), feeTo=fee-feeFrom;
        for(const it of t.from_items||[])await c.query(`INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,$3)
          ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+EXCLUDED.quantity`,[t.to_user_id,it.itemId,Number(it.quantity||1)]);
        for(const it of t.to_items||[])await c.query(`INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,$3)
          ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+EXCLUDED.quantity`,[t.from_user_id,it.itemId,Number(it.quantity||1)]);
        const creditTo=Math.max(0,Number(t.from_gems)-feeFrom), creditFrom=Math.max(0,Number(t.to_gems)-feeTo);
        if(creditTo)await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2',[creditTo,t.to_user_id]);
        if(creditFrom)await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2',[creditFrom,t.from_user_id]);
        if(fee)await c.query('INSERT INTO nexo.treasury_ledger(id,trade_id,kind,amount) VALUES($1,$2,\'trade_fee\',$3)',[randomUUID(),t.id,fee]);
        await c.query('DELETE FROM nexo.trade_locks WHERE trade_id=$1',[t.id]);
        t.status='completed';t.fee_gems=fee;
      } else t.status=from?'confirmedA':'confirmedB';
      await c.query('UPDATE nexo.trades SET status=$1,from_confirmed=$2,to_confirmed=$3,fee_gems=$4 WHERE id=$5',[t.status,t.from_confirmed,t.to_confirmed,t.fee_gems||0,t.id]);
      emit(t.from_user_id,{type:'trade_update',tradeId:t.id,status:t.status});
      emit(t.to_user_id,{type:'trade_update',tradeId:t.id,status:t.status});
      await notify(t.from_user_id,'trade','Trade updated',`حالة الـTrade أصبحت ${t.status}`,{tradeId:t.id});
      await notify(t.to_user_id,'trade','Trade updated',`حالة الـTrade أصبحت ${t.status}`,{tradeId:t.id});
      return t;
    });
  } catch(e){return reply.code(e.code||500).send({error:e.code||'TRADE_CONFIRM_FAILED'});}
});

app.post('/trades/:id/cancel', { preHandler: auth }, async (req, reply) => {
  try {
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.trades WHERE id=$1 FOR UPDATE',[req.params.id]);
      if(!r.rowCount)return reply.code(404).send({error:'TRADE_NOT_FOUND'});
      const t=r.rows[0];if(t.from_user_id!==uid(req)&&t.to_user_id!==uid(req))throw Object.assign(new Error('FORBIDDEN'),{code:403});
      if(!['locked','confirmedA','confirmedB','disputed'].includes(t.status))throw Object.assign(new Error('TRADE_NOT_CANCELABLE'),{code:409});
      await unlockTradeSide(c,t.id,t.from_user_id);await unlockTradeSide(c,t.id,t.to_user_id);
      if(Number(t.from_gems)>0)await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2',[t.from_gems,t.from_user_id]);
      if(Number(t.to_gems)>0)await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2',[t.to_gems,t.to_user_id]);
      await c.query('UPDATE nexo.trades SET status=\'cancelled\' WHERE id=$1',[t.id]);
      emit(t.from_user_id,{type:'trade_update',tradeId:t.id,status:'cancelled'});
      emit(t.to_user_id,{type:'trade_update',tradeId:t.id,status:'cancelled'});
      return {id:t.id,status:'cancelled'};
    });
  } catch(e){return reply.code(e.code||500).send({error:e.code||'TRADE_CANCEL_FAILED'});}
});

app.post('/trades/:id/dispute', { preHandler: auth }, async (req, reply) => {
  const reason=String((req.body||{}).reason||'').trim().slice(0,1000);
  if(!reason)return reply.code(400).send({error:'INVALID_REASON'});
  const r=await q('UPDATE nexo.trades SET status=\'disputed\',dispute_reason=$1 WHERE id=$2 AND status IN (\'locked\',\'confirmedA\',\'confirmedB\') AND (from_user_id=$3 OR to_user_id=$3) RETURNING *',[reason,req.params.id,uid(req)]);
  if(!r.rowCount)return reply.code(409).send({error:'TRADE_NOT_DISPUTABLE'});
  const t=r.rows[0];emit(t.from_user_id,{type:'trade_update',tradeId:t.id,status:t.status});emit(t.to_user_id,{type:'trade_update',tradeId:t.id,status:t.status});return t;
});
async function googlePublisher() {
  const raw=process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
  if(!raw) return null;
  const credentials=JSON.parse(raw);
  const authClient=new JWT({
    email:credentials.client_email,
    key:credentials.private_key,
    scopes:['https://www.googleapis.com/auth/androidpublisher'],
  });
  return androidpublisher({version:'v3',auth:authClient});
}

app.post('/games/play',{preHandler:auth},async(req,reply)=>{
  const b=req.body||{}, gameId=String(b.gameId||''), key=String(b.idempotencyKey||'');
  const games={
    quick_challenge:{cost:3,reward:20},
    mini_puzzle:{cost:5,reward:35},
    daily_arena:{cost:8,reward:55}
  };
  const game=games[gameId];
  if(!game||!key)return reply.code(400).send({error:'INVALID_GAME_INPUT'});
  try{
    return await tx(async c=>{
      const prior=await c.query('SELECT 1 FROM nexo.game_events WHERE idempotency_key=$1',[key]);
      if(prior.rowCount){
        const u=await c.query('SELECT gems,energy FROM nexo.users WHERE id=$1',[uid(req)]);
        return {idempotent:true,gems:Number(u.rows[0].gems),energy:Number(u.rows[0].energy),rewardGems:0};
      }
      const u=await c.query('SELECT gems,energy FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
      if(!u.rowCount)return reply.code(404).send({error:'USER_NOT_FOUND'});
      if(Number(u.rows[0].energy)<game.cost){
        await securityEvent(req,'game_insufficient_energy','warning',{gameId,cost:game.cost});
        throw Object.assign(new Error('INSUFFICIENT_ENERGY'),{code:409});
      }
      const energy=Number(u.rows[0].energy)-game.cost;
      const gems=Number(u.rows[0].gems)+game.reward;
      await c.query('UPDATE nexo.users SET energy=$1,gems=$2,last_active=NOW() WHERE id=$3',[energy,gems,uid(req)]);
      await c.query('INSERT INTO nexo.game_events(id,user_id,game_id,cost_energy,reward_gems,idempotency_key) VALUES($1,$2,$3,$4,$5,$6)',
        [randomUUID(),uid(req),gameId,game.cost,game.reward,key]);
      await c.query('INSERT INTO nexo.energy_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',
        [randomUUID(),uid(req),'game',-game.cost,energy,gameId,'game:'+key]);
      await c.query('INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',
        [randomUUID(),uid(req),'game_reward',game.reward,gems,gameId,'reward:'+key]);
      emit(uid(req),{type:'game_reward',gameId,rewardGems:game.reward,gems,energy});
      return {idempotent:false,gems,energy,rewardGems:game.reward};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'GAME_PLAY_FAILED'});}
});

app.post('/games/rooms',{preHandler:auth},async(req,reply)=>{
  const gameId=String((req.body||{}).gameId||'online_duel');
  if(!['online_duel','daily_arena'].includes(gameId))return reply.code(400).send({error:'INVALID_ONLINE_GAME'});
  try{
    return await tx(async c=>{
      const waiting=await c.query(`SELECT * FROM nexo.game_rooms
        WHERE game_id=$1 AND status='waiting' AND host_id<>$2
        ORDER BY created_at ASC LIMIT 1 FOR UPDATE`,[gameId,uid(req)]);
      if(waiting.rowCount){
        const room=waiting.rows[0];
        await c.query(`UPDATE nexo.game_rooms SET guest_id=$1,status='matched',updated_at=NOW() WHERE id=$2`,[uid(req),room.id]);
        emit(room.host_id,{type:'game_room_matched',roomId:room.id,gameId});
        return {...room,guest_id:uid(req),status:'matched'};
      }
      const r=await c.query(`INSERT INTO nexo.game_rooms(id,game_id,host_id) VALUES($1,$2,$3) RETURNING *`,[randomUUID(),gameId,uid(req)]);
      return r.rows[0];
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'ROOM_CREATE_FAILED'});}
});

app.get('/games/rooms/:id',{preHandler:auth},async(req,reply)=>{
  const r=await q('SELECT * FROM nexo.game_rooms WHERE id=$1 AND (host_id=$2 OR guest_id=$2)',[req.params.id,uid(req)]);
  if(!r.rowCount)return reply.code(404).send({error:'ROOM_NOT_FOUND'});
  return r.rows[0];
});

app.post('/games/rooms/:id/join',{preHandler:auth},async(req,reply)=>{
  try{
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.game_rooms WHERE id=$1 FOR UPDATE',[req.params.id]);
      if(!r.rowCount)return reply.code(404).send({error:'ROOM_NOT_FOUND'});
      const room=r.rows[0];
      if(room.host_id===uid(req)||room.guest_id===uid(req))return room;
      if(room.status!=='waiting'||room.guest_id)throw Object.assign(new Error('ROOM_FULL'),{code:409});
      await c.query(`UPDATE nexo.game_rooms SET guest_id=$1,status='matched',updated_at=NOW() WHERE id=$2`,[uid(req),room.id]);
      emit(room.host_id,{type:'game_room_matched',roomId:room.id,gameId:room.game_id});
      return {...room,guest_id:uid(req),status:'matched'};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'ROOM_JOIN_FAILED'});}
});

app.post('/games/rooms/:id/ready',{preHandler:auth},async(req,reply)=>{
  try{
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.game_rooms WHERE id=$1 FOR UPDATE',[req.params.id]);
      if(!r.rowCount)return reply.code(404).send({error:'ROOM_NOT_FOUND'});
      const room=r.rows[0];
      if(room.host_id!==uid(req)&&room.guest_id!==uid(req))throw Object.assign(new Error('FORBIDDEN'),{code:403});
      const ready=Boolean((req.body||{}).ready);
      if(room.host_id===uid(req))room.host_ready=ready;else room.guest_ready=ready;
      if(room.host_ready&&room.guest_ready)room.status='ready';
      await c.query('UPDATE nexo.game_rooms SET host_ready=$1,guest_ready=$2,status=$3,updated_at=NOW() WHERE id=$4',[room.host_ready,room.guest_ready,room.status,room.id]);
      const event={type:'game_room_update',roomId:room.id,status:room.status};
      emit(room.host_id,event);if(room.guest_id)emit(room.guest_id,event);
      return room;
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'ROOM_READY_FAILED'});}
});

app.post('/games/rooms/:id/score',{preHandler:auth},async(req,reply)=>{
  const score=Number((req.body||{}).score||0);
  if(!Number.isInteger(score)||score<0||score>10000)return reply.code(400).send({error:'INVALID_SCORE'});
  try{
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.game_rooms WHERE id=$1 AND status IN (\'ready\',\'playing\',\'matched\') FOR UPDATE',[req.params.id]);
      if(!r.rowCount)return reply.code(404).send({error:'ROOM_NOT_ACTIVE'});
      const room=r.rows[0];
      if(room.host_id!==uid(req)&&room.guest_id!==uid(req))throw Object.assign(new Error('FORBIDDEN'),{code:403});
      await c.query(`INSERT INTO nexo.game_room_scores(room_id,user_id,score)
        VALUES($1,$2,$3) ON CONFLICT(room_id,user_id) DO UPDATE SET score=EXCLUDED.score,created_at=NOW()`,[room.id,uid(req),score]);
      const scores=(await c.query('SELECT user_id,score FROM nexo.game_room_scores WHERE room_id=$1',[room.id])).rows;
      if(scores.length>=2){
        await c.query('UPDATE nexo.game_rooms SET status=\'completed\',updated_at=NOW() WHERE id=$1',[room.id]);
      }
      return {roomId:room.id,scores,status:scores.length>=2?'completed':room.status};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'SCORE_SUBMIT_FAILED'});}
});

app.post('/payments/google/verify',{preHandler:auth},async(req,reply)=>{
  const b=req.body||{},orderId=String(b.orderId||''),productId=String(b.productId||''),purchaseToken=String(b.purchaseToken||'');
  if(!orderId||!productId||!purchaseToken)return reply.code(400).send({error:'INVALID_PURCHASE'});
  const publisher=await googlePublisher();
  if(!publisher)return reply.code(503).send({error:'GOOGLE_PLAY_NOT_CONFIGURED'});
  const packageName=process.env.ANDROID_PACKAGE_NAME||'com.example.nexo_app';
  try{
    const orderResult=await q('SELECT * FROM nexo.payment_orders WHERE id=$1 AND user_id=$2 FOR UPDATE',[orderId,uid(req)]);
    if(!orderResult.rowCount)return reply.code(404).send({error:'ORDER_NOT_FOUND'});
    const order=orderResult.rows[0];
    if(order.status==='completed')return {ok:true,idempotent:true,gemsAdded:Number(order.gems)};
    if(order.package_id!==productId)return reply.code(409).send({error:'PRODUCT_MISMATCH'});
    const existing=await q('SELECT 1 FROM nexo.purchase_tokens WHERE purchase_token=$1',[purchaseToken]);
    if(existing.rowCount)return reply.code(409).send({error:'PURCHASE_TOKEN_REPLAYED'});

    const google=await publisher.purchases.products.get({packageName,productId,token:purchaseToken});
    const purchase=google.data;
    if(Number(purchase.purchaseState)!==0)return reply.code(409).send({error:'PURCHASE_NOT_COMPLETED'});
    if(Number(purchase.acknowledgementState||0)===0){
      // Acknowledgement/consumption is attempted after entitlement is persisted.
    }

    await tx(async c=>{
      await c.query('INSERT INTO nexo.purchase_tokens(purchase_token,user_id,product_id,order_id) VALUES($1,$2,$3,$4)',[purchaseToken,uid(req),productId,orderId]);
      const u=await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2 RETURNING gems',[order.gems,uid(req)]);
      await c.query('UPDATE nexo.payment_orders SET status=\'completed\',provider=\'google_play\',provider_transaction_id=$1,completed_at=NOW() WHERE id=$2',[purchaseToken,orderId]);
      await c.query('INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,\'google_play_purchase\',$3,$4,$5,$6)',
        [randomUUID(),uid(req),order.gems,u.rows[0].gems,orderId,'google:'+purchaseToken]);
      emit(uid(req),{type:'payment_completed',orderId,gems:Number(order.gems)});
    });

    try {
      if(Number(purchase.consumptionState||0)===0){
        await publisher.purchases.products.consume({packageName,productId,token:purchaseToken});
      }
    } catch(_) {
      // Entitlement is not granted twice because purchase_tokens is unique.
    }
    return {ok:true,gemsAdded:Number(order.gems)};
  }catch(e){
    req.log.error(e);
    return reply.code(502).send({error:'GOOGLE_VERIFICATION_FAILED'});
  }
});

app.post('/payments/create-order',{preHandler:auth},async(req,reply)=>{
  const packs={starter_499:{gems:500,amountMinor:499},plus_999:{gems:1200,amountMinor:999},pro_1999:{gems:3000,amountMinor:1999},ultra_24999:{gems:8000,amountMinor:24999}};
  const id=String((req.body||{}).packageId||''), p=packs[id]; if(!p)return reply.code(400).send({error:'UNKNOWN_PACKAGE'});
  const orderId=randomUUID(); await q('INSERT INTO nexo.payment_orders(id,user_id,package_id,gems,amount_minor,currency,provider) VALUES($1,$2,$3,$4,$5,$6,$7)',[orderId,uid(req),id,p.gems,p.amountMinor,process.env.PAYMENT_CURRENCY||'USD',process.env.PAYMENT_PROVIDER||'test']);
  return {orderId,status:'pending',provider:process.env.PAYMENT_PROVIDER||'test'};
});

app.post('/payments/webhook/:provider',async(req,reply)=>{
  const secret=process.env.PAYMENT_WEBHOOK_SECRET;
  const expectedProvider=String(process.env.PAYMENT_PROVIDER||'').trim();
  if(!secret)return reply.code(503).send({error:'PAYMENT_WEBHOOK_NOT_CONFIGURED'});
  if(req.headers['x-nexo-webhook-secret']!==secret)return reply.code(401).send({error:'INVALID_WEBHOOK'});
  if(expectedProvider && String(req.params.provider||'')!==expectedProvider)return reply.code(404).send({error:'UNKNOWN_PAYMENT_PROVIDER'});
  const b=req.body||{}, orderId=String(b.orderId||''), providerTransactionId=String(b.providerTransactionId||'');
  if(!orderId||!providerTransactionId)return reply.code(400).send({error:'INVALID_WEBHOOK'});
  try{
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.payment_orders WHERE id=$1 FOR UPDATE',[orderId]); if(!r.rowCount)return reply.code(404).send({error:'ORDER_NOT_FOUND'});
      const o=r.rows[0]; if(o.status==='completed')return {ok:true,idempotent:true};
      const dup=await c.query('SELECT id FROM nexo.payment_orders WHERE provider_transaction_id=$1 AND id<>$2',[providerTransactionId,orderId]);
      if(dup.rowCount)return reply.code(409).send({error:'PROVIDER_TRANSACTION_REPLAYED'});
      await c.query('UPDATE nexo.payment_orders SET status=\'completed\',provider_transaction_id=$1,completed_at=NOW() WHERE id=$2',[providerTransactionId,orderId]);
      const u=await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2 RETURNING gems',[o.gems,o.user_id]);
      await c.query('INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,\'purchase\',$3,$4,$5,$6)',[randomUUID(),o.user_id,o.gems,u.rows[0].gems,orderId,'payment:'+providerTransactionId]);
      emit(o.user_id,{type:'payment_completed',orderId,gems:Number(o.gems)});
      return {ok:true,gemsAdded:Number(o.gems)};
    });
  }catch(_){return reply.code(500).send({error:'PAYMENT_WEBHOOK_FAILED'});}
});

app.post('/presence',{preHandler:auth},async(req)=>{const online=Boolean((req.body||{}).online);await q('INSERT INTO nexo.presence(user_id,online,last_seen) VALUES($1,$2,NOW()) ON CONFLICT(user_id) DO UPDATE SET online=$2,last_seen=NOW()',[uid(req),online]);return{online};});
app.get('/presence/:peerId',async(req)=>{const r=await q('SELECT online,last_seen FROM nexo.presence WHERE user_id=$1',[req.params.peerId]);return r.rows[0]||{online:false,last_seen:null};});

app.get('/ws',{websocket:true},(socket,req)=>{
  let decoded; try{decoded=app.jwt.verify(String(req.query&&req.query.token||''));}catch(_){socket.close();return;}
  const id=decoded.sub; if(!sockets.has(id))sockets.set(id,new Set()); sockets.get(id).add(socket);
  q('INSERT INTO nexo.presence(user_id,online,last_seen) VALUES($1,true,NOW()) ON CONFLICT(user_id) DO UPDATE SET online=true,last_seen=NOW()',[id]).catch(()=>{});
  socket.on('message',async raw=>{try{const m=JSON.parse(raw.toString()); if(m.type==='signal'&&m.toUserId){const target=await resolveUserId({query:q},m.toUserId);emit(target,{type:'signal',fromUserId:id,payload:m.payload});}}catch(_){}}); 
  socket.on('close',()=>{const set=sockets.get(id);if(set){set.delete(socket);if(!set.size)sockets.delete(id);}q('UPDATE nexo.presence SET online=false,last_seen=NOW() WHERE user_id=$1',[id]).catch(()=>{});});
});

app.setErrorHandler((err,req,reply)=>{req.log.error(err);if(!reply.sent)reply.code(500).send({error:'INTERNAL_ERROR'});});

async function start(){
  const schema=fs.readFileSync(path.join(__dirname,'..','schema.sql'),'utf8');
  await q(schema);
  await app.listen({host:'0.0.0.0',port:PORT});
}
start().catch(err=>{app.log.error(err);process.exit(1);});
