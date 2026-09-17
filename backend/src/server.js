const Fastify = require('fastify');
const cors = require('@fastify/cors');
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

app.register(cors, { origin: true });
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

app.get('/health', async () => ({ ok:true, service:'nexo-api', time:new Date().toISOString() }));

app.post('/auth/guest', async (req, reply) => {
  const deviceId=String((req.body||{}).deviceId||'').trim().slice(0,60);
  const username='guest_'+(deviceId || randomUUID().slice(0,12));
  let r=await q('SELECT * FROM nexo.users WHERE username=$1',[username]);
  let u=r.rows[0];
  if(!u){ r=await q('INSERT INTO nexo.users(id,username,display_name) VALUES($1,$2,$3) RETURNING *',[randomUUID(),username,'NEXO Guest']); u=r.rows[0]; }
  const token=app.jwt.sign({sub:u.id,username:u.username});
  return { token, user:publicUser(u) };
});

app.post('/auth/register', async (req, reply) => {
  const body=req.body||{}, email=String(body.email||'').trim().toLowerCase(), username=String(body.username||'').trim().toLowerCase(), password=String(body.password||'');
  if(!email||!username||password.length<8) return reply.code(400).send({error:'INVALID_INPUT'});
  const hash=await bcrypt.hash(password,12);
  try{
    const r=await q('INSERT INTO nexo.users(id,username,email,password_hash,display_name) VALUES($1,$2,$3,$4,$5) RETURNING *',[randomUUID(),username,email,hash,username]);
    const u=r.rows[0]; return {token:app.jwt.sign({sub:u.id,username:u.username}),user:publicUser(u)};
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
  if(!Number.isInteger(amount)||amount<1||amount>100||!key) return reply.code(400).send({error:'INVALID_INPUT'});
  try{
    return await tx(async c=>{
      const prior=await c.query('SELECT balance_after FROM nexo.energy_ledger WHERE idempotency_key=$1',[key]);
      if(prior.rowCount)return {energy:prior.rows[0].balance_after};
      const u=await c.query('SELECT energy FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
      if(!u.rowCount||u.rows[0].energy<amount) throw Object.assign(new Error('INSUFFICIENT_ENERGY'),{code:409});
      const energy=u.rows[0].energy-amount;
      await c.query('UPDATE nexo.users SET energy=$1,last_active=NOW() WHERE id=$2',[energy,uid(req)]);
      await c.query('INSERT INTO nexo.energy_ledger(id,user_id,kind,amount,balance_after,idempotency_key) VALUES($1,$2,$3,$4,$5,$6)',[randomUUID(),uid(req),'spend',-amount,energy,key]);
      return {energy};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'ENERGY_ERROR'});}
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
    const msg=r.rows[0]; emit(peerId,{type:'chat_message',message:msg}); return msg;
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
      emit(to,{type:'gift',from:userId(req),giftId});
      return {ok:true,giftId};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'GIFT_SEND_FAILED'});}
});
app.post('/trades',{preHandler:auth},async(req,reply)=>{
  const b=req.body||{}, to=String(b.toUserId||''), items=Array.isArray(b.fromItems)?b.fromItems:[], fromGems=Math.max(0,Number(b.fromGems||0));
  if(!to||to===uid(req))return reply.code(400).send({error:'INVALID_PEER'});
  try{
    return await tx(async c=>{
      const seen=new Set();
      for(const it of items){
        const id=String(it.itemId||''), qty=Number(it.quantity||1);
        if(!id||seen.has(id)||!Number.isInteger(qty)||qty<1)throw Object.assign(new Error('INVALID_TRADE_ITEM'),{code:400});
        seen.add(id);
        const own=await c.query('SELECT i.quantity,g.tradeable FROM nexo.inventory i JOIN nexo.gifts g ON g.id=i.item_id WHERE i.user_id=$1 AND i.item_id=$2 FOR UPDATE',[uid(req),id]);
        if(!own.rowCount||own.rows[0].quantity<qty)throw Object.assign(new Error('INSUFFICIENT_ITEM'),{code:409});
        if(!own.rows[0].tradeable)throw Object.assign(new Error('ITEM_NOT_TRADEABLE'),{code:409});
      }
      if(fromGems>0){
        const u=await c.query('SELECT gems FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
        if(Number(u.rows[0].gems)<fromGems)throw Object.assign(new Error('INSUFFICIENT_GEMS'),{code:409});
      }
      const id=randomUUID(), fee=Math.ceil(fromGems*0.05);
      await c.query('INSERT INTO nexo.trades(id,from_user_id,to_user_id,from_items,from_gems,fee_gems,expires_at) VALUES($1,$2,$3,$4::jsonb,$5,$6,NOW()+INTERVAL \'24 hours\')',[id,uid(req),to,JSON.stringify(items),fromGems,fee]);
      for(const it of items) await c.query('UPDATE nexo.inventory SET quantity=quantity-$1 WHERE user_id=$2 AND item_id=$3',[Number(it.quantity||1),uid(req),it.itemId]);
      if(fromGems) await c.query('UPDATE nexo.users SET gems=gems-$1 WHERE id=$2',[fromGems,uid(req)]);
      emit(to,{type:'trade_created',tradeId:id});
      return {id,status:'locked',feeGems:fee};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'TRADE_CREATE_FAILED'});}
});

app.post('/trades/:id/confirm',{preHandler:auth},async(req,reply)=>{
  try{
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.trades WHERE id=$1 FOR UPDATE',[req.params.id]); if(!r.rowCount)return reply.code(404).send({error:'TRADE_NOT_FOUND'});
      const t=r.rows[0]; const from=t.from_user_id===uid(req), to=t.to_user_id===uid(req);
      if(!from&&!to)throw Object.assign(new Error('FORBIDDEN'),{code:403});
      if(from)t.from_confirmed=true; if(to)t.to_confirmed=true;
      if(t.from_confirmed&&t.to_confirmed){
        t.status='completed';
        for(const it of t.from_items||[]) await c.query('INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+EXCLUDED.quantity',[t.to_user_id,it.itemId,Number(it.quantity||1)]);
        if(Number(t.from_gems)>0) await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2',[t.from_gems,t.to_user_id]);
      }else t.status=from?'confirmedA':'confirmedB';
      await c.query('UPDATE nexo.trades SET status=$1,from_confirmed=$2,to_confirmed=$3 WHERE id=$4',[t.status,t.from_confirmed,t.to_confirmed,t.id]);
      emit(t.from_user_id,{type:'trade_update',tradeId:t.id,status:t.status}); emit(t.to_user_id,{type:'trade_update',tradeId:t.id,status:t.status});
      return t;
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'TRADE_CONFIRM_FAILED'});}
});

app.post('/trades/:id/cancel',{preHandler:auth},async(req,reply)=>{
  try{
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.trades WHERE id=$1 FOR UPDATE',[req.params.id]); if(!r.rowCount)return reply.code(404).send({error:'TRADE_NOT_FOUND'});
      const t=r.rows[0]; if(t.from_user_id!==uid(req)&&t.to_user_id!==uid(req))throw Object.assign(new Error('FORBIDDEN'),{code:403});
      if(!['locked','confirmedA','confirmedB'].includes(t.status))throw Object.assign(new Error('TRADE_NOT_CANCELABLE'),{code:409});
      for(const it of t.from_items||[]) await c.query('INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+EXCLUDED.quantity',[t.from_user_id,it.itemId,Number(it.quantity||1)]);
      if(Number(t.from_gems)>0) await c.query('UPDATE nexo.users SET gems=gems+$1 WHERE id=$2',[t.from_gems,t.from_user_id]);
      await c.query('UPDATE nexo.trades SET status=\'cancelled\' WHERE id=$1',[t.id]); return {id:t.id,status:'cancelled'};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'TRADE_CANCEL_FAILED'});}
});

app.post('/trades/:id/dispute',{preHandler:auth},async(req,reply)=>{
  const reason=String((req.body||{}).reason||'').trim();
  if(!reason)return reply.code(400).send({error:'INVALID_REASON'});
  const r=await q('UPDATE nexo.trades SET status=\'disputed\',dispute_reason=$1 WHERE id=$2 AND status IN (\'locked\',\'confirmedA\',\'confirmedB\') AND (from_user_id=$3 OR to_user_id=$3) RETURNING *',[reason,req.params.id,uid(req)]);
  if(!r.rowCount)return reply.code(409).send({error:'TRADE_NOT_DISPUTABLE'});
  const t=r.rows[0]; emit(t.from_user_id,{type:'trade_update',tradeId:t.id,status:t.status}); emit(t.to_user_id,{type:'trade_update',tradeId:t.id,status:t.status}); return t;
});

app.post('/economy/daily-claim',{preHandler:auth},async(req,reply)=>{
  try{
    return await tx(async c=>{
      const today=(await c.query('SELECT CURRENT_DATE AS d')).rows[0].d;
      const prev=await c.query('SELECT claim_date,streak FROM nexo.daily_claims WHERE user_id=$1 FOR UPDATE',[uid(req)]);
      if(prev.rowCount && String(prev.rows[0].claim_date)===String(today))throw Object.assign(new Error('ALREADY_CLAIMED'),{code:409});
      let streak=1;
      if(prev.rowCount){
        const d=new Date(prev.rows[0].claim_date); const td=new Date(today);
        const diff=Math.round((td-d)/86400000);
        streak=diff===1 ? Math.min(7,prev.rows[0].streak+1) : 1;
      }
      const reward=Math.min(50,20+(streak-1)*5);
      const u=await c.query('SELECT energy FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
      const energy=Math.min(100,Number(u.rows[0].energy)+reward);
      await c.query('UPDATE nexo.users SET energy=$1 WHERE id=$2',[energy,uid(req)]);
      await c.query(`INSERT INTO nexo.daily_claims(user_id,claim_date,streak) VALUES($1,$2,$3)
        ON CONFLICT(user_id) DO UPDATE SET claim_date=EXCLUDED.claim_date,streak=EXCLUDED.streak`,[uid(req),today,streak]);
      return {energy,reward,streak};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'DAILY_CLAIM_FAILED'});}
});
app.post('/economy/energy/convert',{preHandler:auth},async(req,reply)=>{
  try{return await tx(async c=>{
    const u=await c.query('SELECT energy FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
    if(!u.rowCount||u.rows[0].energy<100)throw Object.assign(new Error('INSUFFICIENT_ENERGY'),{code:409});
    const r=await c.query('UPDATE nexo.users SET energy=energy-100,gems=gems+25 WHERE id=$1 RETURNING energy,gems',[uid(req)]);
    return r.rows[0];
  });}catch(e){return reply.code(e.code||500).send({error:e.code||'ENERGY_CONVERSION_FAILED'});}
});
app.post('/games/play',{preHandler:auth},async(req,reply)=>{
  const gameId=String((req.body||{}).gameId||''), key=String((req.body||{}).idempotencyKey||'');
  const games={quick_challenge:{cost:3,reward:20},mini_puzzle:{cost:5,reward:35},daily_arena:{cost:8,reward:55}};
  const game=games[gameId];
  if(!game||!key)return reply.code(400).send({error:'INVALID_GAME'});
  try{return await tx(async c=>{
    const prior=await c.query('SELECT reward_gems FROM nexo.game_events WHERE idempotency_key=$1',[key]);
    if(prior.rowCount)return {ok:true,idempotent:true,rewardGems:Number(prior.rows[0].reward_gems)};
    const u=await c.query('SELECT energy,gems FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
    if(Number(u.rows[0].energy)<game.cost)throw Object.assign(new Error('INSUFFICIENT_ENERGY'),{code:409});
    const energy=Number(u.rows[0].energy)-game.cost, gems=Number(u.rows[0].gems)+game.reward;
    await c.query('UPDATE nexo.users SET energy=$1,gems=$2 WHERE id=$3',[energy,gems,uid(req)]);
    await c.query('INSERT INTO nexo.game_events(id,user_id,game_id,cost_energy,reward_gems,idempotency_key) VALUES($1,$2,$3,$4,$5,$6)',[randomUUID(),uid(req),gameId,game.cost,game.reward,key]);
    return {ok:true,energy,gems,rewardGems:game.reward};
  });}catch(e){return reply.code(e.code||500).send({error:e.code||'GAME_FAILED'});}
});
app.post('/payments/create-order',{preHandler:auth},async(req,reply)=>{
  const packs={starter_499:{gems:500,amountMinor:499},plus_999:{gems:1200,amountMinor:999},pro_1999:{gems:3000,amountMinor:1999},ultra_24999:{gems:8000,amountMinor:24999}};
  const id=String((req.body||{}).packageId||''), p=packs[id]; if(!p)return reply.code(400).send({error:'UNKNOWN_PACKAGE'});
  const orderId=randomUUID(); await q('INSERT INTO nexo.payment_orders(id,user_id,package_id,gems,amount_minor,currency,provider) VALUES($1,$2,$3,$4,$5,$6,$7)',[orderId,uid(req),id,p.gems,p.amountMinor,process.env.PAYMENT_CURRENCY||'USD',process.env.PAYMENT_PROVIDER||'test']);
  return {orderId,status:'pending',provider:process.env.PAYMENT_PROVIDER||'test'};
});

app.post('/payments/webhook/:provider',async(req,reply)=>{
  const secret=process.env.PAYMENT_WEBHOOK_SECRET;
  if(secret && req.headers['x-nexo-webhook-secret']!==secret)return reply.code(401).send({error:'INVALID_WEBHOOK'});
  const b=req.body||{}, orderId=String(b.orderId||''), providerTransactionId=String(b.providerTransactionId||'');
  if(!orderId||!providerTransactionId)return reply.code(400).send({error:'INVALID_WEBHOOK'});
  try{
    return await tx(async c=>{
      const r=await c.query('SELECT * FROM nexo.payment_orders WHERE id=$1 FOR UPDATE',[orderId]); if(!r.rowCount)return reply.code(404).send({error:'ORDER_NOT_FOUND'});
      const o=r.rows[0]; if(o.status==='completed')return {ok:true,idempotent:true};
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
  socket.on('message',raw=>{try{const m=JSON.parse(raw.toString()); if(m.type==='signal'&&m.toUserId)emit(m.toUserId,{type:'signal',fromUserId:id,payload:m.payload});}catch(_){}}); 
  socket.on('close',()=>{const set=sockets.get(id);if(set){set.delete(socket);if(!set.size)sockets.delete(id);}q('UPDATE nexo.presence SET online=false,last_seen=NOW() WHERE user_id=$1',[id]).catch(()=>{});});
});

app.setErrorHandler((err,req,reply)=>{req.log.error(err);if(!reply.sent)reply.code(500).send({error:'INTERNAL_ERROR'});});

async function start(){
  const schema=fs.readFileSync(path.join(__dirname,'..','schema.sql'),'utf8');
  await q(schema);
  await app.listen({host:'0.0.0.0',port:PORT});
}
start().catch(err=>{app.log.error(err);process.exit(1);});
