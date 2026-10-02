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
const { randomUUID, pbkdf2, timingSafeEqual } = require('crypto');
const fs = require('fs');
const path = require('path');
const { registerDomino } = require('./domino');
const { registerLudo } = require('./ludo');
const { registerChess } = require('./chess');

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
  try {
    await req.jwtVerify();
    const r=await q('SELECT banned FROM nexo.users WHERE id=$1',[uid(req)]);
    if(r.rowCount&&r.rows[0].banned)return reply.code(403).send({error:'ACCOUNT_BANNED'});
  } catch (_) { return reply.code(401).send({ error: 'UNAUTHORIZED' }); }
}

const DEFAULT_SETTINGS={
  'economy.dailyFreeEnergy':50,'economy.maxEnergy':100,'economy.voicePerMinute':1,'economy.videoPerMinute':4,
  'economy.energyToGemsEnergy':100,'economy.energyToGemsReward':25,'trade.feePercent':5,
  'games.quick_challenge.cost':3,'games.quick_challenge.reward':20,
  'games.mini_puzzle.cost':5,'games.mini_puzzle.reward':35,
  'games.daily_arena.cost':8,'games.daily_arena.reward':55
};

const MEMBERSHIP_CATALOG = [
  {id:'vip_1_30',kind:'vip',tier:1,name:'VIP I',durationDays:30,gemsPrice:1500,benefits:{dailyGems:30,extraDailyMissions:1,storeDiscountPercent:3,entranceEffects:true},welcomeGift:'vip-emblem'},
  {id:'vip_2_30',kind:'vip',tier:2,name:'VIP II',durationDays:30,gemsPrice:3000,benefits:{dailyGems:60,extraDailyMissions:2,storeDiscountPercent:5,entranceEffects:true},welcomeGift:'vip-emblem'},
  {id:'vip_3_30',kind:'vip',tier:3,name:'VIP III',durationDays:30,gemsPrice:6500,benefits:{dailyGems:100,extraDailyMissions:3,storeDiscountPercent:8,entranceEffects:true,profileBadge:true},welcomeGift:'crown-shine'},
  {id:'vip_4_30',kind:'vip',tier:4,name:'VIP IV',durationDays:30,gemsPrice:12000,benefits:{dailyGems:160,extraDailyMissions:4,storeDiscountPercent:10,entranceEffects:true,profileBadge:true},welcomeGift:'fire-wings'},
  {id:'vip_5_30',kind:'vip',tier:5,name:'VIP V',durationDays:30,gemsPrice:22000,benefits:{dailyGems:250,extraDailyMissions:5,storeDiscountPercent:12,entranceEffects:true,profileBadge:true,exclusiveStore:true},welcomeGift:'royal-chest'},
  {id:'svip_1_30',kind:'svip',tier:1,name:'SVIP I',durationDays:30,gemsPrice:10000,benefits:{dailyGems:250,extraDailyMissions:5,missionBonusPercent:10,storeDiscountPercent:10,exclusiveStore:true,entranceEffects:true},welcomeGift:'dragon'},
  {id:'svip_2_30',kind:'svip',tier:2,name:'SVIP II',durationDays:30,gemsPrice:18000,benefits:{dailyGems:400,extraDailyMissions:6,missionBonusPercent:15,storeDiscountPercent:12,exclusiveStore:true,entranceEffects:true},welcomeGift:'phoenix'},
  {id:'svip_3_30',kind:'svip',tier:3,name:'SVIP III',durationDays:30,gemsPrice:30000,benefits:{dailyGems:650,extraDailyMissions:7,missionBonusPercent:20,storeDiscountPercent:15,exclusiveStore:true,entranceEffects:true,profileBadge:true},welcomeGift:'unicorn'},
  {id:'svip_4_30',kind:'svip',tier:4,name:'SVIP IV',durationDays:30,gemsPrice:50000,benefits:{dailyGems:900,extraDailyMissions:8,missionBonusPercent:25,storeDiscountPercent:18,exclusiveStore:true,entranceEffects:true,profileBadge:true},welcomeGift:'al-hurra'},
  {id:'svip_5_30',kind:'svip',tier:5,name:'SVIP V',durationDays:30,gemsPrice:80000,benefits:{dailyGems:1400,extraDailyMissions:10,missionBonusPercent:35,storeDiscountPercent:20,exclusiveStore:true,entranceEffects:true,profileBadge:true},welcomeGift:'royal-chest'}
];

const ARISTOCRACY_CATALOG = [
  {id:'noble_1',level:1,name:'Noble I',gemsPrice:5000,rewardItem:'frame-21-noble',benefits:['Noble badge','Exclusive frame','Room entrance glow']},
  {id:'noble_2',level:2,name:'Noble II',gemsPrice:9000,rewardItem:'frame-22-scribe',benefits:['Higher room aura','VIP gift bonus']},
  {id:'noble_3',level:3,name:'Noble III',gemsPrice:15000,rewardItem:'frame-23-vizier',benefits:['Rare entrance effect','Priority room styling']},
  {id:'noble_4',level:4,name:'Noble IV',gemsPrice:25000,rewardItem:'frame-24-platinum-lv100',benefits:['Platinum frame','Premium name styling']},
  {id:'noble_5',level:5,name:'Noble V',gemsPrice:40000,rewardItem:'frame-25-anniversary',benefits:['Anniversary frame','Exclusive profile aura']},
  {id:'noble_6',level:6,name:'Noble VI',gemsPrice:65000,rewardItem:'frame-30-new-year',benefits:['Mythic prestige','Limited room effect']}
];

const MISSION_DEFS = [
  {id:'daily_login',group:'daily',title:'دخول NEXO',description:'افتح NEXO اليوم',activityType:'login',target:1,rewardGems:20,requiresVip:false,requiresSvip:false},
  {id:'daily_chat',group:'daily',title:'3 رسائل شات',description:'ابعت 3 رسائل',activityType:'chat',target:3,rewardGems:15,requiresVip:false,requiresSvip:false},
  {id:'daily_gift',group:'daily',title:'إرسال هدية',description:'ابعت هدية واحدة',activityType:'gift_send',target:1,rewardGems:30,requiresVip:false,requiresSvip:false},
  {id:'daily_game',group:'daily',title:'فوز لعبة',description:'حقق فوزًا في لعبة',activityType:'game_win',target:1,rewardGems:35,requiresVip:false,requiresSvip:false},
  {id:'vip_chat',group:'vip',title:'VIP Social',description:'ابعت 10 رسائل وأكمل مهمة VIP',activityType:'chat',target:10,rewardGems:80,requiresVip:true,requiresSvip:false},
  {id:'vip_gift',group:'vip',title:'VIP Gifter',description:'أرسل 3 هدايا',activityType:'gift_send',target:3,rewardGems:120,requiresVip:true,requiresSvip:false},
  {id:'svip_voice',group:'svip',title:'SVIP Party',description:'شارك في 5 أنشطة غرفة',activityType:'voice_activity',target:5,rewardGems:180,requiresVip:false,requiresSvip:true},
  {id:'svip_game',group:'svip',title:'SVIP Gamer',description:'حقق 3 انتصارات',activityType:'game_win',target:3,rewardGems:220,requiresVip:false,requiresSvip:true},
  {id:'tribe_chat',group:'tribe',title:'Tribe Together',description:'3 رسائل داخل المجتمع',activityType:'tribe_chat',target:3,rewardGems:50,requiresVip:false,requiresSvip:false},
  {id:'tribe_gift',group:'tribe',title:'Tribe Gift',description:'أرسل هدية للمجتمع',activityType:'tribe_gift',target:1,rewardGems:70,requiresVip:false,requiresSvip:false}
];

async function settingNumber(db,key,fallback){
  try{const r=await db.query('SELECT value FROM nexo.app_settings WHERE key=$1',[key]);const v=r.rowCount?Number(r.rows[0].value):Number(fallback);return Number.isFinite(v)?v:Number(fallback);}
  catch(_){return Number(fallback);}
}
async function adminAuth(req,reply){
  const configured=String(process.env.NEXO_ADMIN_KEY||'');
  if(configured.length<24)return reply.code(503).send({error:'ADMIN_KEY_NOT_CONFIGURED'});
  const supplied=String(req.headers['x-admin-key']||'');
  if(!supplied||supplied!==configured)return reply.code(403).send({error:'ADMIN_FORBIDDEN'});
  return true;
}
async function adminAudit(req,action,targetId=null,details={}){
  await q('INSERT INTO nexo.admin_actions(id,admin_subject,action,target_id,details) VALUES($1,$2,$3,$4,$5::jsonb)',
    [randomUUID(),String(req.headers['x-admin-key']||'').slice(0,12),action,targetId,JSON.stringify(details)]);
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


async function bumpActivity(db,userId,activityType,amount=1){
  try{
    await db.query('INSERT INTO nexo.activity_daily(user_id,activity_date,activity_type,count) VALUES($1,CURRENT_DATE,$2,$3) ON CONFLICT(user_id,activity_date,activity_type) DO UPDATE SET count=nexo.activity_daily.count+EXCLUDED.count',[userId,activityType,amount]);
  }catch(_){}
}
async function grantInventoryIfPresent(db,userId,itemId,quantity=1){
  if(!itemId)return;
  const r=await db.query('SELECT id FROM nexo.gifts WHERE id=$1 AND active=true',[itemId]);
  if(!r.rowCount)return;
  await db.query('INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+EXCLUDED.quantity',[userId,itemId,quantity]);
}

function emit(toUserId, event) {
  const list = sockets.get(toUserId);
  if (!list) return;
  const raw = JSON.stringify(event);
  for (const ws of list) { try { ws.send(raw); } catch (_) {} }
}
function pbkdf2Verify(password, stored) {
  return new Promise((resolve) => {
    const parts=String(stored||'').split('$');
    if(parts.length!==4 || parts[0]!=='pbkdf2sha256') return resolve(false);
    const iterations=Number(parts[1]);
    if(!Number.isInteger(iterations)||iterations<1) return resolve(false);
    const salt=Buffer.from(parts[2],'hex');
    const expected=Buffer.from(parts[3],'hex');
    if(!salt.length || expected.length!==32) return resolve(false);
    pbkdf2(password,salt,iterations,32,'sha256',(err,key)=>{
      if(err||!key||expected.length!==key.length)return resolve(false);
      resolve(timingSafeEqual(expected,key));
    });
  });
}
function publicUser(u) {
  if (!u) return null;
  return {
    id:u.id, username:u.username, displayName:u.display_name, avatar:u.avatar,
    gems:Number(u.gems), energy:Number(u.energy), level:u.level, experience:Number(u.experience),
    reputation:u.reputation, vipLevel:u.vip_level, nameColor:u.name_color, glow:u.glow,
    createdAt:u.created_at, lastActive:u.last_active, role:u.role, banned:Boolean(u.banned)
  };
}

app.post('/auth/guest', async (req, reply) => {
  const deviceId=String((req.body||{}).deviceId||'').trim().slice(0,60);
  const username='guest_'+(deviceId || randomUUID().slice(0,12));
  let r=await q('SELECT * FROM nexo.users WHERE username=$1',[username]);
  let u=r.rows[0];
  if(!u){ r=await q('INSERT INTO nexo.users(id,username,display_name) VALUES($1,$2,$3) RETURNING *',[randomUUID(),username,'NEXO Guest']); u=r.rows[0];
    const starter=[['neon-heart',2],['shadow-flame',1],['galaxy-aura',1],['crown-shine',1],['frame-cyan',1],['asset-cosmic',1],['emoji-heart',2],['crafted-shadow-mask',1],['power_chat_spark',1],['power_glow_frame',1]];
    for(const [itemId,quantity] of starter){
      await q("INSERT INTO nexo.inventory(user_id,item_id,quantity) SELECT $1,id,$2 FROM nexo.gifts WHERE id=$3 ON CONFLICT(user_id,item_id) DO NOTHING",[u.id,quantity,itemId]);
    }
  }
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
  const body=req.body||{}, identity=String(body.identity||body.identifier||body.email||body.username||'').trim().toLowerCase(), password=String(body.password||'');
  if(!identity||!password) return reply.code(400).send({error:'LOGIN_REQUIRED'});
  const r=await q('SELECT * FROM nexo.users WHERE lower(username)=lower($1) OR lower(email)=lower($1) LIMIT 1',[identity]), u=r.rows[0];
  if(!u||u.banned||!u.password_hash) return reply.code(u?.banned?403:401).send({error:u?.banned?'ACCOUNT_BANNED':'INVALID_CREDENTIALS'});
  let valid=false, legacy=false;
  if(String(u.password_hash).startsWith('pbkdf2sha256$')) { legacy=true; valid=await pbkdf2Verify(password,u.password_hash); }
  else valid=await bcrypt.compare(password,u.password_hash);
  if(!valid) return reply.code(401).send({error:'INVALID_CREDENTIALS'});
  if(legacy){
    const upgraded=await bcrypt.hash(password,12);
    await q('UPDATE nexo.users SET password_hash=$1,last_active=NOW() WHERE id=$2',[upgraded,u.id]);
  } else {
    await q('UPDATE nexo.users SET last_active=NOW() WHERE id=$1',[u.id]);
  }
  return {token:app.jwt.sign({sub:u.id,username:u.username},{expiresIn:'30d'}),user:publicUser(u)};
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

const CATALOG_SELECT=`SELECT id,name,rarity,gems,tradeable,image,tagline,description,item_type AS "itemType",category,animation,
  market_visible AS "marketVisible",active,sort_order AS "sortOrder",tags,metadata FROM nexo.gifts`;

app.get('/catalog',async(req)=>{
  const qs=req.query||{},type=String(qs.type||'').trim().toLowerCase(),category=String(qs.category||'').trim().toLowerCase(),market=String(qs.market||'')==='1';
  const clauses=['active=true'],params=[];
  if(type){params.push(type);clauses.push('item_type=$'+params.length);}
  if(category){params.push(category);clauses.push('category=$'+params.length);}
  if(market)clauses.push('market_visible=true');
  return (await q(CATALOG_SELECT+' WHERE '+clauses.join(' AND ')+' ORDER BY sort_order,gems,name',params)).rows;
});
app.get('/gifts',async()=> (await q(CATALOG_SELECT+" WHERE active=true AND item_type='gift' ORDER BY sort_order,gems,name")).rows);
app.get('/profile/equipped',{preHandler:auth},async(req)=> (await q(`SELECT e.slot,g.id,g.name,g.item_type AS "itemType",g.image,g.rarity,g.gems,g.tradeable,g.animation,g.description
  FROM nexo.user_equipped e LEFT JOIN nexo.gifts g ON g.id=e.item_id WHERE e.user_id=$1 ORDER BY e.slot`,[uid(req)])).rows);
app.post('/profile/equipped',{preHandler:auth},async(req,reply)=>{
  const slot=String((req.body||{}).slot||'').trim(),itemId=String((req.body||{}).itemId||'').trim();
  const slots=new Set(['frame','profile_asset','emoji','name_effect','name_color','entrance_effect','room_background','power']);
  if(!slots.has(slot))return reply.code(400).send({error:'INVALID_SLOT'});
  try{return await tx(async c=>{
    if(!itemId){await c.query('DELETE FROM nexo.user_equipped WHERE user_id=$1 AND slot=$2',[uid(req),slot]);return {ok:true,slot,itemId:null};}
    const item=await c.query('SELECT id,item_type,active FROM nexo.gifts WHERE id=$1',[itemId]);
    if(!item.rowCount||!item.rows[0].active)throw Object.assign(new Error('ITEM_NOT_FOUND'),{code:404});
    const expectedMap={frame:'frame',profile_asset:'asset',emoji:'emoji',name_effect:'gift',name_color:'name_color',entrance_effect:'entrance_effect',room_background:'room_background',power:'power'};
    const expected=expectedMap[slot];
    if(item.rows[0].item_type!==expected)throw Object.assign(new Error('ITEM_SLOT_MISMATCH'),{code:400});
    const own=await c.query('SELECT quantity FROM nexo.inventory WHERE user_id=$1 AND item_id=$2',[uid(req),itemId]);
    if(!own.rowCount||Number(own.rows[0].quantity)<1)throw Object.assign(new Error('ITEM_NOT_OWNED'),{code:409});
    if(slot==='name_color'){
      const hex=item.rows[0].metadata?.hex;
      if(!hex)throw Object.assign(new Error('NO_COLOR_VALUE'),{code:400});
      await c.query('UPDATE nexo.users SET name_color=$1,last_active=NOW() WHERE id=$2',[String(hex),uid(req)]);
    }
    await c.query(`INSERT INTO nexo.user_equipped(user_id,slot,item_id,updated_at) VALUES($1,$2,$3,NOW())
      ON CONFLICT(user_id,slot) DO UPDATE SET item_id=EXCLUDED.item_id,updated_at=NOW()`,[uid(req),slot,itemId]);
    return {ok:true,slot,itemId};
  });}catch(e){return reply.code(e.code||500).send({error:e.code||'EQUIP_FAILED'});}
});
app.post('/push/register',{preHandler:auth},async(req,reply)=>{
  const b=req.body||{},platform=String(b.platform||'unknown').toLowerCase().slice(0,20),token=String(b.token||'').trim().slice(0,4096);
  if(!token)return reply.code(400).send({error:'INVALID_PUSH_TOKEN'});
  await q(`INSERT INTO nexo.device_tokens(id,user_id,platform,token,active,last_seen) VALUES($1,$2,$3,$4,true,NOW())
    ON CONFLICT(token) DO UPDATE SET user_id=EXCLUDED.user_id,platform=EXCLUDED.platform,active=true,last_seen=NOW()`,[randomUUID(),uid(req),platform,token]);
  return {ok:true};
});
app.post('/push/unregister',{preHandler:auth},async(req,reply)=>{
  const token=String((req.body||{}).token||'').trim(); if(!token)return reply.code(400).send({error:'INVALID_PUSH_TOKEN'});
  await q('UPDATE nexo.device_tokens SET active=false,last_seen=NOW() WHERE token=$1 AND user_id=$2',[token,uid(req)]); return {ok:true};
});
app.get('/admin',async(req,reply)=>{try{reply.type('text/html').send(fs.readFileSync(path.join(__dirname,'..','admin.html'),'utf8'));}catch(_){reply.code(404).send({error:'ADMIN_UI_NOT_FOUND'});}});
app.get('/admin/styles.css',async(req,reply)=>{try{reply.type('text/css').send(fs.readFileSync(path.join(__dirname,'..','assets','nexo.css'),'utf8'));}catch(_){reply.code(404).send({error:'ADMIN_CSS_NOT_FOUND'});}});
app.get('/admin/settings',{preHandler:adminAuth},async()=>{
  const rows=(await q('SELECT key,value,updated_at AS "updatedAt" FROM nexo.app_settings ORDER BY key')).rows;
  const out={...DEFAULT_SETTINGS}; for(const row of rows)out[row.key]=row.value; return out;
});
app.post('/admin/settings',{preHandler:adminAuth},async(req,reply)=>{
  const key=String((req.body||{}).key||'').trim(),value=Number((req.body||{}).value);
  if(!Object.prototype.hasOwnProperty.call(DEFAULT_SETTINGS,key))return reply.code(400).send({error:'SETTING_NOT_ALLOWED'});
  if(!Number.isFinite(value))return reply.code(400).send({error:'SETTING_VALUE_INVALID'});
  const ranges={'economy.dailyFreeEnergy':[0,100],'economy.maxEnergy':[1,1000],'economy.voicePerMinute':[0,100],'economy.videoPerMinute':[0,100],'economy.energyToGemsEnergy':[1,1000],'economy.energyToGemsReward':[0,1000000],'trade.feePercent':[0,25]};
  const range=ranges[key]||[0,1000000]; if(value<range[0]||value>range[1])return reply.code(400).send({error:'SETTING_OUT_OF_RANGE'});
  await q(`INSERT INTO nexo.app_settings(key,value,updated_at) VALUES($1,to_jsonb($2::numeric),NOW())
    ON CONFLICT(key) DO UPDATE SET value=EXCLUDED.value,updated_at=NOW()`,[key,value]);
  await adminAudit(req,'setting_update',key,{value}); return {ok:true,key,value};
});
app.get('/admin/overview',{preHandler:adminAuth},async()=>{
  const [users,items,inventory,trades,security]=await Promise.all([
    q('SELECT COUNT(*)::int AS count FROM nexo.users'),
    q('SELECT COUNT(*)::int AS count FROM nexo.gifts WHERE active=true'),
    q('SELECT COUNT(*)::int AS count FROM nexo.inventory WHERE quantity>0'),
    q("SELECT COUNT(*)::int AS count FROM nexo.trades WHERE status IN ('locked','confirmedA','confirmedB','disputed')"),
    q('SELECT COUNT(*)::int AS count FROM nexo.security_events WHERE created_at>NOW()-INTERVAL \'24 hours\'')
  ]);
  return {users:users.rows[0].count,catalog:items.rows[0].count,inventoryRows:inventory.rows[0].count,activeTrades:trades.rows[0].count,security24h:security.rows[0].count};
});
app.get('/admin/catalog',{preHandler:adminAuth},async()=> (await q(CATALOG_SELECT+' ORDER BY item_type,sort_order,gems,name')).rows);
app.post('/admin/catalog/upsert',{preHandler:adminAuth},async(req,reply)=>{
  const b=req.body||{},id=String(b.id||'').trim(),name=String(b.name||'').trim(),itemType=String(b.itemType||'gift').trim().toLowerCase();
  const rarity=String(b.rarity||'Common').trim(),image=String(b.image||'').trim(),category=String(b.category||itemType).trim();
  const tagline=String(b.tagline||'').trim(),description=String(b.description||tagline).trim(),animation=String(b.animation||'pulse').trim();
  const gems=Math.max(0,Number(b.gems||0)),tradeable=b.tradeable!==false,active=b.active!==false,marketVisible=b.marketVisible!==false;
  if(!id||!name||!image||!['gift','frame','asset','emoji','crafted','name_color','entrance_effect','room_background','power'].includes(itemType)||!Number.isInteger(gems))return reply.code(400).send({error:'INVALID_CATALOG_ITEM'});
  try{
    const result=await q(`INSERT INTO nexo.gifts(id,name,rarity,gems,tradeable,image,tagline,active,item_type,category,description,animation,market_visible,sort_order,tags,metadata)
      VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15::jsonb,$16::jsonb)
      ON CONFLICT(id) DO UPDATE SET name=EXCLUDED.name,rarity=EXCLUDED.rarity,gems=EXCLUDED.gems,tradeable=EXCLUDED.tradeable,image=EXCLUDED.image,
      tagline=EXCLUDED.tagline,active=EXCLUDED.active,item_type=EXCLUDED.item_type,category=EXCLUDED.category,description=EXCLUDED.description,
      animation=EXCLUDED.animation,market_visible=EXCLUDED.market_visible,sort_order=EXCLUDED.sort_order,tags=EXCLUDED.tags,metadata=EXCLUDED.metadata RETURNING id`,
      [id,name,rarity,gems,tradeable,image,tagline,active,itemType,category,description,animation,marketVisible,Number(b.sortOrder||0),
       JSON.stringify(Array.isArray(b.tags)?b.tags:[]),JSON.stringify(b.metadata&&typeof b.metadata==='object'?b.metadata:{})]);
    await adminAudit(req,'catalog_upsert',id,{name,itemType,rarity,gems}); return {ok:true,id:result.rows[0].id};
  }catch(e){return reply.code(e.code||500).send({error:e.code||'CATALOG_UPSERT_FAILED'});}
});
app.post('/admin/catalog/:id/toggle',{preHandler:adminAuth},async(req,reply)=>{
  const r=await q('UPDATE nexo.gifts SET active=NOT active WHERE id=$1 RETURNING id,active',[req.params.id]);
  if(!r.rowCount)return reply.code(404).send({error:'ITEM_NOT_FOUND'}); await adminAudit(req,'catalog_toggle',req.params.id,r.rows[0]); return r.rows[0];
});

app.post('/admin/catalog/:id/delete',{preHandler:adminAuth},async(req,reply)=>{
  const r=await q("UPDATE nexo.gifts SET active=false,market_visible=false WHERE id=$1 RETURNING id",[req.params.id]);
  if(!r.rowCount)return reply.code(404).send({error:'ITEM_NOT_FOUND'});
  await adminAudit(req,'catalog_delete',req.params.id,{softDelete:true});
  return {ok:true,id:r.rows[0].id,deleted:true};
});

app.post('/admin/catalog/price-filter',{preHandler:adminAuth},async(req,reply)=>{
  const b=req.body||{},type=String(b.itemType||'').trim().toLowerCase(),rarity=String(b.rarity||'').trim(),gems=Number(b.gems);
  const validTypes=['gift','frame','asset','emoji','crafted','name_color','entrance_effect','room_background','power'];
  if(!validTypes.includes(type)||!rarity||!Number.isInteger(gems)||gems<0)return reply.code(400).send({error:'INVALID_PRICE_FILTER'});
  const r=await q('UPDATE nexo.gifts SET gems=$1 WHERE item_type=$2 AND rarity=$3 RETURNING id',[gems,type,rarity]);
  await adminAudit(req,'catalog_price_filter',null,{itemType:type,rarity,gems,count:r.rowCount});
  return {ok:true,updated:r.rowCount,itemType:type,rarity,gems};
});
app.get('/admin/users',{preHandler:adminAuth},async()=> (await q(`SELECT id,username,display_name AS "displayName",avatar,gems,energy,level,reputation,vip_level AS "vipLevel",role,banned,last_active AS "lastActive"
  FROM nexo.users ORDER BY last_active DESC LIMIT 250`)).rows);
app.post('/admin/users/:id/wallet',{preHandler:adminAuth},async(req,reply)=>{
  const gemsDelta=Number((req.body||{}).gemsDelta||0),energyDelta=Number((req.body||{}).energyDelta||0);
  if(!Number.isInteger(gemsDelta)||!Number.isInteger(energyDelta))return reply.code(400).send({error:'INVALID_DELTA'});
  const r=await q('UPDATE nexo.users SET gems=GREATEST(0,gems+$1),energy=LEAST(100,GREATEST(0,energy+$2)) WHERE id=$3 RETURNING id,gems,energy',[gemsDelta,energyDelta,req.params.id]);
  if(!r.rowCount)return reply.code(404).send({error:'USER_NOT_FOUND'}); await adminAudit(req,'wallet_adjust',req.params.id,{gemsDelta,energyDelta}); return r.rows[0];
});
app.post('/admin/users/:id/status',{preHandler:adminAuth},async(req,reply)=>{
  const banned=Boolean((req.body||{}).banned),r=await q('UPDATE nexo.users SET banned=$1 WHERE id=$2 RETURNING id,banned',[banned,req.params.id]);
  if(!r.rowCount)return reply.code(404).send({error:'USER_NOT_FOUND'}); await adminAudit(req,banned?'ban_user':'unban_user',req.params.id,{banned}); return r.rows[0];
});

app.post('/admin/users/:id/inventory',{preHandler:adminAuth},async(req,reply)=>{
  const itemId=String((req.body||{}).itemId||'').trim(),quantity=Number((req.body||{}).quantity||0);
  if(!itemId||!Number.isInteger(quantity)||quantity<1||quantity>100000)return reply.code(400).send({error:'INVALID_GRANT'});
  try{return await tx(async c=>{
    const item=await c.query('SELECT id,active FROM nexo.gifts WHERE id=$1',[itemId]);
    if(!item.rowCount||!item.rows[0].active)throw Object.assign(new Error('ITEM_NOT_FOUND'),{code:404});
    const r=await c.query('INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+EXCLUDED.quantity RETURNING quantity',[req.params.id,itemId,quantity]);
    await adminAudit(req,'inventory_grant',req.params.id,{itemId,quantity});
    return {ok:true,userId:req.params.id,itemId,quantity:r.rows[0].quantity};
  });}catch(e){return reply.code(e.code||500).send({error:e.code||'GRANT_FAILED'});}
});
app.get('/admin/security-events',{preHandler:adminAuth},async()=> (await q(`SELECT id,user_id AS "userId",event_type AS "eventType",severity,ip,details,created_at AS "createdAt"
  FROM nexo.security_events ORDER BY created_at DESC LIMIT 250`)).rows);

app.get('/admin/messages',{preHandler:adminAuth},async(req)=>{
  const limit=Math.min(250,Math.max(1,Number((req.query||{}).limit||100)));
  return (await q(`SELECT m.id,m.sender_id AS "senderId",su.username AS "senderUsername",m.recipient_id AS "recipientId",ru.username AS "recipientUsername",m.kind,m.body,m.gift_id AS "giftId",m.created_at AS "createdAt"
    FROM nexo.messages m JOIN nexo.users su ON su.id=m.sender_id JOIN nexo.users ru ON ru.id=m.recipient_id ORDER BY m.created_at DESC LIMIT $1`,[limit])).rows;
});
app.get('/admin/trades',{preHandler:adminAuth},async()=> (await q(`SELECT id,from_user_id AS "fromUserId",to_user_id AS "toUserId",status,from_items AS "fromItems",to_items AS "toItems",
  from_gems AS "fromGems",to_gems AS "toGems",fee_gems AS "feeGems",created_at AS "createdAt",expires_at AS "expiresAt"
  FROM nexo.trades ORDER BY created_at DESC LIMIT 250`)).rows);
app.post('/admin/announce',{preHandler:adminAuth},async(req,reply)=>{
  const title=String((req.body||{}).title||'').trim().slice(0,120),body=String((req.body||{}).body||'').trim().slice(0,2000);
  if(!title||!body)return reply.code(400).send({error:'INVALID_ANNOUNCEMENT'});
  const users=await q('SELECT id FROM nexo.users WHERE banned=false');
  for(const u of users.rows)await notify(u.id,'announcement',title,body,{admin:true});
  await adminAudit(req,'announce',null,{title,recipients:users.rowCount}); return {ok:true,recipients:users.rowCount};
});
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
app.get('/inventory',{preHandler:auth},async req=> (await q(`SELECT i.item_id AS id,g.name,g.rarity,g.gems,g.tradeable,g.image,g.tagline,g.description,
  g.item_type AS "itemType",g.category,g.animation,g.market_visible AS "marketVisible",i.quantity
  FROM nexo.inventory i JOIN nexo.gifts g ON g.id=i.item_id WHERE i.user_id=$1 AND i.quantity>0 ORDER BY g.item_type,g.sort_order,g.gems`,[uid(req)])).rows);

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
      const dailyFree=await settingNumber(c,'economy.dailyFreeEnergy',50); const maxEnergy=await settingNumber(c,'economy.maxEnergy',100); const energy=Math.min(maxEnergy,before+dailyFree);
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
      const convertEnergy=await settingNumber(c,'economy.energyToGemsEnergy',100);
      const convertReward=await settingNumber(c,'economy.energyToGemsReward',25);
      if(Number(u.rows[0].energy)<convertEnergy)throw Object.assign(new Error('INSUFFICIENT_ENERGY'),{code:409});
      const energy=Number(u.rows[0].energy)-convertEnergy, gems=Number(u.rows[0].gems)+convertReward;
      const key=String((req.body||{}).idempotencyKey||'');
      if(!key)return reply.code(400).send({error:'INVALID_INPUT'});
      const prior=await c.query('SELECT 1 FROM nexo.energy_ledger WHERE idempotency_key=$1',[key]);
      if(prior.rowCount)return {energy:Number(u.rows[0].energy),gems:Number(u.rows[0].gems),idempotent:true};
      await c.query('UPDATE nexo.users SET energy=$1,gems=$2,last_active=NOW() WHERE id=$3',[energy,gems,uid(req)]);
      await c.query('INSERT INTO nexo.energy_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',
        [randomUUID(),uid(req),'convert',-convertEnergy,energy,'energy_to_gems',key]);
      await c.query('INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',
        [randomUUID(),uid(req),'energy_convert',convertReward,gems,'energy_to_gems',key+':gems']);
      return {energy,gems,gemsAdded:convertReward};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'ENERGY_CONVERT_FAILED'});}
});

app.post('/craft',{preHandler:auth},async(req,reply)=>{
  const itemId=String((req.body||{}).itemId||''),key=String((req.body||{}).idempotencyKey||'');
  const costs={'crafted-shadow-mask':400,'crafted-phoenix-seal':1200,'crafted-prism-token':300,'crafted-nebula-core':800,'crafted-golden-signet':1400,'crafted-arcana':5000};
  const cost=costs[itemId]; if(!cost||!key)return reply.code(400).send({error:'INVALID_RECIPE'});
  try{return await tx(async c=>{
    const prior=await c.query('SELECT 1 FROM nexo.wallet_ledger WHERE idempotency_key=$1',[key]);
    if(prior.rowCount)return {ok:true,idempotent:true,itemId};
    const item=await c.query("SELECT id,item_type,active FROM nexo.gifts WHERE id=$1",[itemId]);
    if(!item.rowCount||!item.rows[0].active||item.rows[0].item_type!=='crafted')throw Object.assign(new Error('CRAFT_ITEM_NOT_FOUND'),{code:404});
    const u=await c.query('SELECT gems FROM nexo.users WHERE id=$1 FOR UPDATE',[uid(req)]);
    if(Number(u.rows[0].gems)<cost)throw Object.assign(new Error('INSUFFICIENT_GEMS'),{code:409});
    const gems=Number(u.rows[0].gems)-cost;
    await c.query('UPDATE nexo.users SET gems=$1 WHERE id=$2',[gems,uid(req)]);
    await c.query('INSERT INTO nexo.inventory(user_id,item_id,quantity) VALUES($1,$2,1) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=nexo.inventory.quantity+1',[uid(req),itemId]);
    await c.query('INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)',[randomUUID(),uid(req),'craft',-cost,gems,itemId,key]);
    return {ok:true,itemId,gems,cost};
  });}catch(e){return reply.code(e.code||500).send({error:e.code||'CRAFT_FAILED'});}
});
app.post('/gifts/buy',{preHandler:auth},async(req,reply)=>{
  const giftId=String((req.body||{}).giftId||''), key=String((req.body||{}).idempotencyKey||'');
  if(!giftId||!key)return reply.code(400).send({error:'INVALID_INPUT'});
  try{
    return await tx(async c=>{
      const prior=await c.query('SELECT 1 FROM nexo.wallet_ledger WHERE idempotency_key=$1',[key]);
      if(prior.rowCount)return {ok:true,idempotent:true};
      const g=await c.query('SELECT * FROM nexo.gifts WHERE id=$1 AND active=true AND market_visible=true',[giftId]);
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
    const msg=r.rows[0]; await bumpActivity(q,uid(req),'chat',1); emit(peerId,{type:'chat_message',message:msg}); await notify(peerId,'chat','رسالة جديدة','لديك رسالة جديدة في NEXO',{senderId:uid(req)}); return msg;
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
      const g=await c.query("SELECT * FROM nexo.gifts WHERE id=$1 AND active=true AND item_type='gift'",[giftId]);
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
      if(!Array.isArray(t.from_items)||!Array.isArray(t.to_items)||t.from_items.length>4||t.to_items.length>4)throw Object.assign(new Error('INVALID_TRADE'),{code:409});
      if(new Date(t.expires_at).getTime()<Date.now())throw Object.assign(new Error('TRADE_EXPIRED'),{code:409});
      if(from)t.from_confirmed=true;if(to)t.to_confirmed=true;
      if(t.from_confirmed&&t.to_confirmed){
        const feePercent=await settingNumber(c,'trade.feePercent',5); const fee=Math.ceil((Number(t.from_gems)+Number(t.to_gems))*feePercent/100);
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
  const gameDefaults={
    quick_challenge:{cost:3,reward:20},
    mini_puzzle:{cost:5,reward:35},
    daily_arena:{cost:8,reward:55}
  };
  const defaults=gameDefaults[gameId];
  if(!defaults||!key)return reply.code(400).send({error:'INVALID_GAME_INPUT'});
  try{
    return await tx(async c=>{
      const game={cost:await settingNumber(c,'games.'+gameId+'.cost',defaults.cost),reward:await settingNumber(c,'games.'+gameId+'.reward',defaults.reward)};
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


app.post('/signal/send',{preHandler:auth},async(req,reply)=>{
  const b=req.body||{}, target=String(b.toUserId||'');
  const payload=b.payload&&typeof b.payload==='object'?b.payload:{};
  if(!target)return reply.code(400).send({error:'SIGNAL_TARGET_REQUIRED'});
  try{
    const to=await resolveUserId({query:q},target);
    await q("INSERT INTO nexo.signal_queue(from_user_id,to_user_id,payload) VALUES($1,$2,$3::jsonb)",[uid(req),to,JSON.stringify(payload)]);
    return {ok:true};
  }catch(e){return reply.code(e.code||500).send({error:e.code||'SIGNAL_SEND_FAILED'});}
});
app.get('/signal/poll',{preHandler:auth},async req=>{
  try{
    const rows=await tx(async c=>{
      return (await c.query("DELETE FROM nexo.signal_queue WHERE to_user_id=$1 AND created_at < NOW()-INTERVAL '5 minutes' RETURNING id",[uid(req)])).rows;
    });
    await q("DELETE FROM nexo.signal_queue WHERE to_user_id=$1 AND created_at < NOW()-INTERVAL '5 minutes'",[uid(req)]);
    const picked=await tx(async c=>{
      return (await c.query("WITH picked AS (SELECT id FROM nexo.signal_queue WHERE to_user_id=$1 ORDER BY created_at LIMIT 100) DELETE FROM nexo.signal_queue s USING picked p WHERE s.id=p.id RETURNING s.from_user_id,s.payload",[uid(req)])).rows;
    });
    return {data:picked.map(x=>({type:'signal',fromUserId:x.from_user_id,payload:x.payload}))};
  }catch(e){return reply.code(500).send({error:'SIGNAL_POLL_FAILED'});}
});
app.get('/rtc/config',async(req)=>({iceServers:[{urls:['stun:stun.l.google.com:19302']}]}) );

app.get('/memberships/catalog',{preHandler:auth},async req=>{
  return {data:MEMBERSHIP_CATALOG};
});
app.get('/memberships/current',{preHandler:auth},async req=>{
  const r=await q("SELECT vip_level,svip_active,svip_expires_at,aristocracy_level FROM nexo.users WHERE id=$1",[uid(req)]);
  if(!r.rowCount)return {vipLevel:0,svipActive:false,svipExpiresAt:null,aristocracyLevel:0};
  const u=r.rows[0], active=Boolean(u.svip_active)&&(!u.svip_expires_at||new Date(u.svip_expires_at)>new Date());
  return {vipLevel:Number(u.vip_level||0),svipActive:active,svipExpiresAt:u.svip_expires_at,aristocracyLevel:Number(u.aristocracy_level||0)};
});
app.post('/memberships/buy',{preHandler:auth},async(req,reply)=>{
  const b=req.body||{}, productId=String(b.productId||''), key=String(b.idempotencyKey||'');
  const p=MEMBERSHIP_CATALOG.find(x=>x.id===productId);
  if(!p||!key)return reply.code(400).send({error:'INVALID_MEMBERSHIP'});
  try{
    return await tx(async c=>{
      const prior=await c.query("SELECT balance_after FROM nexo.wallet_ledger WHERE idempotency_key=$1",[key]);
      if(prior.rowCount)return {ok:true,idempotent:true,gems:Number(prior.rows[0].balance_after)};
      const u=await c.query("SELECT gems,vip_level,svip_active,svip_expires_at FROM nexo.users WHERE id=$1 FOR UPDATE",[uid(req)]);
      if(!u.rowCount)throw Object.assign(new Error('USER_NOT_FOUND'),{code:404});
      if(Number(u.rows[0].gems)<p.gemsPrice)throw Object.assign(new Error('INSUFFICIENT_GEMS'),{code:409});
      const gems=Number(u.rows[0].gems)-p.gemsPrice;
      if(p.kind==='vip'){
        await c.query("UPDATE nexo.users SET gems=$1,vip_level=GREATEST(vip_level,$2),last_active=NOW() WHERE id=$3",[gems,p.tier,uid(req)]);
      }else{
        await c.query("UPDATE nexo.users SET gems=$1,svip_active=true,svip_expires_at=GREATEST(COALESCE(svip_expires_at,NOW()),NOW())+($2::int*INTERVAL '1 day'),last_active=NOW() WHERE id=$3",[gems,p.durationDays,uid(req)]);
      }
      await c.query("INSERT INTO nexo.membership_entitlements(user_id,kind,product_id,starts_at,expires_at) VALUES($1,$2,$3,NOW(),NOW()+($4::int*INTERVAL '1 day'))",[uid(req),p.kind,p.id,p.durationDays]);
      await grantInventoryIfPresent(c,uid(req),p.welcomeGift,1);
      await c.query("INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)",[randomUUID(),uid(req),'membership_purchase',-p.gemsPrice,gems,p.id,key]);
      return {ok:true,kind:p.kind,productId:p.id,gems,benefits:p.benefits,welcomeGift:p.welcomeGift};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'MEMBERSHIP_BUY_FAILED'});}
});

app.get('/aristocracy/catalog',{preHandler:auth},async req=>{
  const r=await q("SELECT aristocracy_level FROM nexo.users WHERE id=$1",[uid(req)]);
  return {currentLevel:Number(r.rows[0]?.aristocracy_level||0),products:ARISTOCRACY_CATALOG};
});
app.post('/aristocracy/buy',{preHandler:auth},async(req,reply)=>{
  const b=req.body||{}, productId=String(b.productId||''), key=String(b.idempotencyKey||'');
  const p=ARISTOCRACY_CATALOG.find(x=>x.id===productId);
  if(!p||!key)return reply.code(400).send({error:'INVALID_ARISTOCRACY'});
  try{
    return await tx(async c=>{
      const prior=await c.query("SELECT balance_after FROM nexo.wallet_ledger WHERE idempotency_key=$1",[key]);
      if(prior.rowCount)return {ok:true,idempotent:true,gems:Number(prior.rows[0].balance_after)};
      const u=await c.query("SELECT gems,aristocracy_level FROM nexo.users WHERE id=$1 FOR UPDATE",[uid(req)]);
      const current=Number(u.rows[0]?.aristocracy_level||0);
      if(p.level!==current+1)throw Object.assign(new Error('ARISTOCRACY_SEQUENCE'),{code:409});
      if(Number(u.rows[0].gems)<p.gemsPrice)throw Object.assign(new Error('INSUFFICIENT_GEMS'),{code:409});
      const gems=Number(u.rows[0].gems)-p.gemsPrice;
      await c.query("UPDATE nexo.users SET gems=$1,aristocracy_level=$2,last_active=NOW() WHERE id=$3",[gems,p.level,uid(req)]);
      await grantInventoryIfPresent(c,uid(req),p.rewardItem,1);
      await c.query("INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)",[randomUUID(),uid(req),'aristocracy_upgrade',-p.gemsPrice,gems,p.id,key]);
      return {ok:true,level:p.level,gems,rewardItem:p.rewardItem,benefits:p.benefits};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'ARISTOCRACY_BUY_FAILED'});}
});

app.get('/missions/today',{preHandler:auth},async req=>{
  const u=await q("SELECT vip_level,svip_active,svip_expires_at,aristocracy_level FROM nexo.users WHERE id=$1",[uid(req)]);
  const user=u.rows[0]||{};
  const svip=Boolean(user.svip_active)&&(!user.svip_expires_at||new Date(user.svip_expires_at)>new Date());
  const vip=Number(user.vip_level||0)>0;
  const visible=MISSION_DEFS.filter(m=>(!m.requiresVip||vip)&&(!m.requiresSvip||svip));
  const counts=(await q("SELECT activity_type,count FROM nexo.activity_daily WHERE user_id=$1 AND activity_date=CURRENT_DATE",[uid(req)])).rows;
  const countMap=Object.fromEntries(counts.map(x=>[x.activity_type,Number(x.count)]));
  const claimed=(await q("SELECT mission_id,claimed FROM nexo.mission_progress WHERE user_id=$1 AND mission_date=CURRENT_DATE",[uid(req)])).rows;
  const claimedMap=Object.fromEntries(claimed.map(x=>[x.mission_id,Boolean(x.claimed)]));
  return {date:new Date().toISOString().slice(0,10),vip,svip,aristocracyLevel:Number(user.aristocracy_level||0),missions:visible.map(m=>({...m,progress:Math.min(m.target,Number(countMap[m.activityType]||0)),claimed:Boolean(claimedMap[m.id])}))};
});

app.post('/missions/claim/:id',{preHandler:auth},async(req,reply)=>{
  const mission=MISSION_DEFS.find(m=>m.id===String(req.params.id||''));
  if(!mission)return reply.code(404).send({error:'MISSION_NOT_FOUND'});
  try{
    return await tx(async c=>{
      const u=(await c.query("SELECT vip_level,svip_active,svip_expires_at,gems FROM nexo.users WHERE id=$1 FOR UPDATE",[uid(req)])).rows[0];
      const svip=Boolean(u.svip_active)&&(!u.svip_expires_at||new Date(u.svip_expires_at)>new Date());
      const vip=Number(u.vip_level||0)>0;
      if((mission.requiresVip&&!vip)||(mission.requiresSvip&&!svip))throw Object.assign(new Error('MISSION_LOCKED'),{code:403});
      const p=await c.query("SELECT claimed FROM nexo.mission_progress WHERE user_id=$1 AND mission_date=CURRENT_DATE AND mission_id=$2 FOR UPDATE",[uid(req),mission.id]);
      if(p.rowCount&&p.rows[0].claimed)throw Object.assign(new Error('MISSION_ALREADY_CLAIMED'),{code:409});
      const a=await c.query("SELECT count FROM nexo.activity_daily WHERE user_id=$1 AND activity_date=CURRENT_DATE AND activity_type=$2",[uid(req),mission.activityType]);
      if(Number(a.rows[0]?.count||0)<mission.target)throw Object.assign(new Error('MISSION_NOT_COMPLETE'),{code:409});
      const bonus=svip&&mission.group!=='daily'?Math.round(mission.rewardGems*.1):0, reward=mission.rewardGems+bonus, gems=Number(u.gems)+reward;
      await c.query("INSERT INTO nexo.mission_progress(user_id,mission_date,mission_id,claimed,claimed_at) VALUES($1,CURRENT_DATE,$2,true,NOW()) ON CONFLICT(user_id,mission_date,mission_id) DO UPDATE SET claimed=true,claimed_at=NOW()",[uid(req),mission.id]);
      await c.query("UPDATE nexo.users SET gems=$1,last_active=NOW() WHERE id=$2",[gems,uid(req)]);
      await c.query("INSERT INTO nexo.wallet_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES($1,$2,$3,$4,$5,$6,$7)",[randomUUID(),uid(req),'mission_reward',reward,gems,mission.id,'mission:'+uid(req)+':'+mission.id+':'+new Date().toISOString().slice(0,10)]);
      return {ok:true,missionId:mission.id,rewardGems:reward,gems};
    });
  }catch(e){return reply.code(e.code||500).send({error:e.code||'MISSION_CLAIM_FAILED'});}
});

app.get('/rooms',{preHandler:auth},async req=>{
  const r=await q("SELECT r.id,r.invite_code AS \"inviteCode\",r.title,r.room_theme AS \"roomTheme\",r.max_seats AS \"maxSeats\",r.active_game AS \"activeGame\",r.status,COUNT(s.user_id)::int AS occupants FROM nexo.voice_rooms r LEFT JOIN nexo.voice_room_seats s ON s.room_id=r.id WHERE r.status='live' GROUP BY r.id ORDER BY r.updated_at DESC LIMIT 100");
  return {rooms:r.rows};
});
app.post('/rooms',{preHandler:auth},async(req,reply)=>{
  const title=String((req.body||{}).title||'NEXO Party').trim().slice(0,80)||'NEXO Party';
  const roomId=randomUUID(), code='NEXO-'+Math.random().toString(36).slice(2,8).toUpperCase();
  try{
    const room=await tx(async c=>{
      await c.query("INSERT INTO nexo.voice_rooms(id,invite_code,host_id,title,max_seats,status) VALUES($1,$2,$3,$4,9,'live')",[roomId,code,uid(req),title]);
      await c.query("INSERT INTO nexo.voice_room_seats(room_id,seat,user_id) VALUES($1,0,$2)",[roomId,uid(req)]);
      return (await c.query("SELECT r.id,r.invite_code AS \"inviteCode\",r.title,r.room_theme AS \"roomTheme\",r.max_seats AS \"maxSeats\",r.active_game AS \"activeGame\",r.status FROM nexo.voice_rooms r WHERE r.id=$1",[roomId])).rows[0];
    });
    await bumpActivity(q,uid(req),'voice_activity',1);
    return {room,seats:[{seat:0,userId:uid(req),muted:false,speaking:false}]};
  }catch(e){return reply.code(e.code||500).send({error:'ROOM_CREATE_FAILED'});}
});
app.get('/rooms/:id',{preHandler:auth},async(req,reply)=>{
  const r=await q("SELECT r.id,r.invite_code AS \"inviteCode\",r.host_id AS \"hostId\",r.title,r.room_theme AS \"roomTheme\",r.max_seats AS \"maxSeats\",r.active_game AS \"activeGame\",r.status FROM nexo.voice_rooms r WHERE r.id=$1",[req.params.id]);
  if(!r.rowCount)return reply.code(404).send({error:'ROOM_NOT_FOUND'});
  const seats=(await q("SELECT s.seat,s.user_id AS \"userId\",COALESCE(u.display_name,u.username,'Guest') AS \"displayName\",s.muted,s.speaking FROM nexo.voice_room_seats s LEFT JOIN nexo.users u ON u.id=s.user_id WHERE s.room_id=$1 ORDER BY s.seat",[req.params.id])).rows;
  return {room:r.rows[0],seats};
});
app.post('/rooms/:id/join',{preHandler:auth},async(req,reply)=>{
  try{
    return await tx(async c=>{
      const r=await c.query("SELECT * FROM nexo.voice_rooms WHERE id=$1 AND status='live' FOR UPDATE",[req.params.id]);
      if(!r.rowCount)throw Object.assign(new Error('ROOM_NOT_FOUND'),{code:404});
      const existing=await c.query("SELECT seat FROM nexo.voice_room_seats WHERE room_id=$1 AND user_id=$2",[req.params.id,uid(req)]);
      if(existing.rowCount)return {ok:true,seat:Number(existing.rows[0].seat)};
      const free=await c.query("SELECT x.seat FROM generate_series(0,(SELECT max_seats-1 FROM nexo.voice_rooms WHERE id=$1)) x(seat) WHERE NOT EXISTS(SELECT 1 FROM nexo.voice_room_seats s WHERE s.room_id=$1 AND s.seat=x.seat) ORDER BY x.seat LIMIT 1",[req.params.id]);
      if(!free.rowCount)throw Object.assign(new Error('ROOM_FULL'),{code:409});
      const seat=Number(free.rows[0].seat);
      await c.query("INSERT INTO nexo.voice_room_seats(room_id,seat,user_id) VALUES($1,$2,$3)",[req.params.id,seat,uid(req)]);
      await c.query("UPDATE nexo.voice_rooms SET updated_at=NOW() WHERE id=$1",[req.params.id]);
      return {ok:true,seat};
    }).then(async out=>{await bumpActivity(q,uid(req),'voice_activity',1);return out;});
  }catch(e){return reply.code(e.code||500).send({error:e.code||'ROOM_JOIN_FAILED'});}
});
app.post('/rooms/:id/leave',{preHandler:auth},async(req,reply)=>{
  await q("DELETE FROM nexo.voice_room_seats WHERE room_id=$1 AND user_id=$2",[req.params.id,uid(req)]);
  await q("UPDATE nexo.voice_rooms SET updated_at=NOW() WHERE id=$1",[req.params.id]);
  return {ok:true};
});
app.post('/rooms/:id/mic',{preHandler:auth},async(req,reply)=>{
  const muted=Boolean((req.body||{}).muted), speaking=Boolean((req.body||{}).speaking);
  const r=await q("UPDATE nexo.voice_room_seats SET muted=$1,speaking=$2 WHERE room_id=$3 AND user_id=$4 RETURNING seat,muted,speaking",[muted,speaking,req.params.id,uid(req)]);
  if(!r.rowCount)return reply.code(404).send({error:'SEAT_NOT_FOUND'});
  return r.rows[0];
});
app.post('/rooms/:id/game',{preHandler:auth},async(req,reply)=>{
  const game=String((req.body||{}).game||'').trim().toLowerCase();
  if(!['ludo','domino','chess'].includes(game))return reply.code(400).send({error:'INVALID_ROOM_GAME'});
  const r=await q("UPDATE nexo.voice_rooms SET active_game=$1,updated_at=NOW() WHERE id=$2 AND EXISTS(SELECT 1 FROM nexo.voice_room_seats s WHERE s.room_id=nexo.voice_rooms.id AND s.user_id=$3) RETURNING id,active_game AS \"activeGame\"",[game,req.params.id,uid(req)]);
  if(!r.rowCount)return reply.code(404).send({error:'ROOM_NOT_FOUND_OR_NOT_JOINED'});
  return {ok:true,activeGame:r.rows[0].activeGame};
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

registerDomino(app,auth,uid,tx,q);
registerLudo(app,auth,q);
registerChess(app,auth,q);

async function start(){
  const schema=fs.readFileSync(path.join(__dirname,'..','schema.sql'),'utf8');
  await q(schema);
  await app.listen({host:'0.0.0.0',port:PORT});
}
start().catch(err=>{app.log.error(err);process.exit(1);});
