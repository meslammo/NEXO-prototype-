import { db } from "hatchable";

export const access = "public";

const json = (req) => req.body && typeof req.body === "object" ? req.body : {};
const route = (req) => "/" + (Array.isArray(req.params?.path) ? req.params.path.join("/") : "");
const authHeader = (req) => String(req.headers?.authorization || "");
const tokenOf = (req) => { const h=authHeader(req); if(h.toLowerCase().startsWith("bearer ")) return h.slice(7).trim(); return String(req.query?.token || "").trim(); };

async function hashToken(token) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
  return Array.from(new Uint8Array(digest)).map(x => x.toString(16).padStart(2,"0")).join("");
}
function newToken() {
  const a = new Uint8Array(32);
  crypto.getRandomValues(a);
  return Array.from(a,x=>x.toString(16).padStart(2,"0")).join("");
}
function out(res,status,data) { return res.status(status).json(data); }

async function userFor(req) {
  const token = tokenOf(req);
  if (!token) return null;
  const h = await hashToken(token);
  const r = await db.query(
    "SELECT u.* FROM app_sessions s JOIN users u ON u.id=s.user_id WHERE s.token_hash=$1 AND s.expires_at>NOW()",
    [h]
  );
  return r.rowCount ? r.rows[0] : null;
}
async function needUser(req,res) {
  const u = await userFor(req);
  if (!u) { out(res,401,{error:"UNAUTHORIZED"}); return null; }
  if (u.banned) { out(res,403,{error:"ACCOUNT_BANNED"}); return null; }
  return u;
}
async function findUser(ref) {
  const v = String(ref || "").trim();
  if (!v) return null;
  const r = await db.query("SELECT * FROM users WHERE id::text=$1 OR lower(username)=lower($1) LIMIT 1",[v]);
  return r.rowCount ? r.rows[0] : null;
}
function publicUser(u) {
  return {
    id:u.id, username:u.username, displayName:u.display_name, avatar:u.avatar,
    gems:Number(u.gems), energy:Number(u.energy), level:Number(u.level),
    experience:Number(u.experience), reputation:Number(u.reputation),
    vipLevel:u.vip_level, nameColor:u.name_color, glow:Boolean(u.glow),
    createdAt:u.created_at, lastActive:u.last_active, role:u.role
  };
}
function itemsOf(raw) {
  return Array.isArray(raw) ? raw.filter(x=>x && typeof x==="object").map(x=>({
    itemId:String(x.itemId || ""), quantity:Math.max(1,Number(x.quantity || 1))
  })).filter(x=>x.itemId) : [];
}
async function issueSession(id) {
  const token = newToken();
  await db.query(
    "INSERT INTO app_sessions(token_hash,user_id,expires_at) VALUES($1,$2,NOW()+INTERVAL '30 days')",
    [await hashToken(token),id]
  );
  return token;
}
async function releaseTrade(t) {
  const locks = await db.query("SELECT user_id,item_id,quantity FROM trade_locks WHERE trade_id=$1",[t.id]);
  for (const x of locks.rows) {
    await db.query(
      "INSERT INTO inventory(user_id,item_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=inventory.quantity+EXCLUDED.quantity",
      [x.user_id,x.item_id,x.quantity]
    );
  }
  if (Number(t.from_gems)>0) await db.query("UPDATE users SET gems=gems+$1 WHERE id=$2",[Number(t.from_gems),t.from_user_id]);
  if (Number(t.to_gems)>0) await db.query("UPDATE users SET gems=gems+$1 WHERE id=$2",[Number(t.to_gems),t.to_user_id]);
  await db.query("DELETE FROM trade_locks WHERE trade_id=$1",[t.id]);
}

async function catalog(req,res) {
  const q = req.query || {};
  const clauses=["active=true"], params=[];
  const type=String(q.type || "").trim().toLowerCase();
  if(type){params.push(type);clauses.push("item_type=$"+params.length);}
  const cat=String(q.category || "").trim().toLowerCase();
  if(cat){params.push(cat);clauses.push("category=$"+params.length);}
  if(String(q.market || "")==="1") clauses.push("market_visible=true");
  const r=await db.query(
    'SELECT id,name,rarity,gems,tradeable,image,tagline,description,item_type AS "itemType",category,animation,market_visible AS "marketVisible",active,sort_order AS "sortOrder",tags,metadata FROM gifts WHERE '+clauses.join(" AND ")+' ORDER BY sort_order,gems,name',
    params
  );
  return res.json(r.rows);
}
async function chat(req,res,u) {
  const parts=req.params.path || [];
  const peer=await findUser(parts[1]);
  if(!peer) return out(res,404,{error:"USER_NOT_FOUND"});
  if(req.method==="GET"){
    const r=await db.query(
      'SELECT m.id,m.sender_id,m.recipient_id,m.kind,m.body,m.gift_id,m.created_at,u.username AS sender_username FROM messages m JOIN users u ON u.id=m.sender_id WHERE (m.sender_id=$1 AND m.recipient_id=$2) OR (m.sender_id=$2 AND m.recipient_id=$1) ORDER BY m.created_at ASC LIMIT 250',
      [u.id,peer.id]
    );
    return out(res,200,{data:r.rows});
  }
  const body=String(json(req).body || "").trim();
  if(!body || body.length>2000) return out(res,400,{error:"INVALID_MESSAGE"});
  const r=await db.query(
    "INSERT INTO messages(id,sender_id,recipient_id,kind,body) VALUES(gen_random_uuid(),$1,$2,'text',$3) RETURNING *",
    [u.id,peer.id,body]
  );
  return out(res,200,r.rows[0]);
}
async function sendGift(req,res,u) {
  const b=json(req), peer=await findUser(b.toUserId);
  const giftId=String(b.giftId || ""), key=String(b.idempotencyKey || "");
  if(!peer) return out(res,404,{error:"USER_NOT_FOUND"});
  if(!giftId || !key) return out(res,400,{error:"INVALID_GIFT_INPUT"});
  const g=await db.query("SELECT * FROM gifts WHERE id=$1 AND active=true",[giftId]);
  if(!g.rowCount) return out(res,404,{error:"GIFT_NOT_FOUND"});
  const old=await db.query("SELECT id FROM gift_transactions WHERE idempotency_key=$1",[key]);
  if(old.rowCount){
    const w=await db.query("SELECT gems FROM users WHERE id=$1",[u.id]);
    return out(res,200,{ok:true,idempotent:true,gems:Number(w.rows[0].gems),giftId});
  }
  let source="gems";
  const inv=await db.query("UPDATE inventory SET quantity=quantity-1 WHERE user_id=$1 AND item_id=$2 AND quantity>0 RETURNING quantity",[u.id,giftId]);
  if(!inv.rowCount){
    const w=await db.query("UPDATE users SET gems=gems-$1,last_active=NOW() WHERE id=$2 AND gems>=$1 RETURNING gems",[Number(g.rows[0].gems),u.id]);
    if(!w.rowCount) return out(res,409,{error:"INSUFFICIENT_GEMS"});
  } else source="inventory";
  await db.query(
    "INSERT INTO gift_transactions(id,user_id,to_user_id,gift_id,idempotency_key,source) VALUES(gen_random_uuid(),$1,$2,$3,$4,$5)",
    [u.id,peer.id,giftId,key,source]
  );
  await db.query(
    "INSERT INTO messages(id,sender_id,recipient_id,kind,body,gift_id) VALUES(gen_random_uuid(),$1,$2,'gift',$3,$4)",
    [u.id,peer.id,"Gift: "+g.rows[0].name,giftId]
  );
  const w=await db.query("SELECT gems FROM users WHERE id=$1",[u.id]);
  return out(res,200,{ok:true,idempotent:false,gems:Number(w.rows[0].gems),giftId});
}
async function trades(req,res,u) {
  const parts=req.params.path || [], id=parts[1], action=parts[2];
  if(req.method==="POST" && !id){
    const b=json(req), peer=await findUser(b.toUserId);
    if(!peer || String(peer.id)===String(u.id)) return out(res,400,{error:"INVALID_PEER"});
    const mine=itemsOf(b.fromItems), gems=Math.max(0,Number(b.fromGems || 0));
    const existing=await db.query(
      "SELECT * FROM trades WHERE status IN ('locked','confirmedA','confirmedB','disputed') AND ((from_user_id=$1 AND to_user_id=$2) OR (from_user_id=$2 AND to_user_id=$1)) ORDER BY created_at DESC LIMIT 1",
      [u.id,peer.id]
    );
    let t=existing.rowCount ? existing.rows[0] : null;
    const actingAsFrom=t ? String(t.from_user_id)===String(u.id) : true;
    if(t && !actingAsFrom && Array.isArray(t.to_items) && t.to_items.length===0){
      for(const it of mine){
        const own=await db.query("UPDATE inventory SET quantity=quantity-$1 WHERE user_id=$2 AND item_id=$3 AND quantity>=$1 RETURNING quantity",[it.quantity,u.id,it.itemId]);
        if(!own.rowCount) return out(res,409,{error:"ITEM_NOT_OWNED",itemId:it.itemId});
        await db.query("INSERT INTO trade_locks(trade_id,user_id,item_id,quantity) VALUES($1,$2,$3,$4)",[t.id,u.id,it.itemId,it.quantity]);
      }
      if(gems){
        const w=await db.query("UPDATE users SET gems=gems-$1 WHERE id=$2 AND gems>=$1 RETURNING gems",[gems,u.id]);
        if(!w.rowCount) return out(res,409,{error:"INSUFFICIENT_GEMS"});
      }
      const upd=await db.query("UPDATE trades SET to_items=$1::jsonb,to_gems=$2 WHERE id=$3 RETURNING *",[JSON.stringify(mine),gems,t.id]);
      return out(res,200,upd.rows[0]);
    }
    if(t) return out(res,200,t);
    for(const it of mine){
      const own=await db.query("UPDATE inventory SET quantity=quantity-$1 WHERE user_id=$2 AND item_id=$3 AND quantity>=$1 RETURNING quantity",[it.quantity,u.id,it.itemId]);
      if(!own.rowCount) return out(res,409,{error:"ITEM_NOT_OWNED",itemId:it.itemId});
    }
    if(gems){
      const w=await db.query("UPDATE users SET gems=gems-$1 WHERE id=$2 AND gems>=$1 RETURNING gems",[gems,u.id]);
      if(!w.rowCount) return out(res,409,{error:"INSUFFICIENT_GEMS"});
    }
    const c=await db.query(
      "INSERT INTO trades(id,from_user_id,to_user_id,status,from_items,to_items,from_gems,to_gems,expires_at) VALUES(gen_random_uuid(),$1,$2,'locked',$3::jsonb,'[]'::jsonb,$4,0,NOW()+INTERVAL '24 hours') RETURNING *",
      [u.id,peer.id,JSON.stringify(mine),gems]
    );
    t=c.rows[0];
    for(const it of mine) await db.query("INSERT INTO trade_locks(trade_id,user_id,item_id,quantity) VALUES($1,$2,$3,$4)",[t.id,u.id,it.itemId,it.quantity]);
    return out(res,200,t);
  }
  if(!id) return out(res,404,{error:"TRADE_NOT_FOUND"});
  const found=await db.query("SELECT * FROM trades WHERE id=$1 AND (from_user_id=$2 OR to_user_id=$2)",[id,u.id]);
  if(!found.rowCount) return out(res,404,{error:"TRADE_NOT_FOUND"});
  const t=found.rows[0];
  if(req.method==="GET"){
    if(new Date(t.expires_at).getTime()<Date.now() && ["locked","confirmedA","confirmedB","disputed"].includes(t.status)){
      await releaseTrade(t); t.status="expired";
    }
    const n=await db.query("SELECT id,username FROM users WHERE id=ANY($1::uuid[])",[[t.from_user_id,t.to_user_id]]);
    const names=new Map(n.rows.map(x=>[String(x.id),x.username]));
    return out(res,200,{...t,from_username:names.get(String(t.from_user_id)),to_username:names.get(String(t.to_user_id))});
  }
  if(req.method==="POST" && action==="confirm"){
    if(!["locked","confirmedA","confirmedB"].includes(t.status)) return out(res,409,{error:"TRADE_NOT_CONFIRMABLE"});
    if(new Date(t.expires_at).getTime()<Date.now()){await releaseTrade(t);return out(res,409,{error:"TRADE_EXPIRED"});}
    const isFrom=String(t.from_user_id)===String(u.id);
    t.from_confirmed=isFrom ? true : t.from_confirmed;
    t.to_confirmed=isFrom ? t.to_confirmed : true;
    if(t.from_confirmed && t.to_confirmed){
      const s=await db.query("SELECT value FROM app_settings WHERE key='trade.feePercent'");
      const feePercent=Number(s.rows[0]?.value || 5);
      const fee=Math.ceil((Number(t.from_gems)+Number(t.to_gems))*feePercent/100);
      const feeFrom=Math.min(fee,Number(t.from_gems)), feeTo=Math.max(0,fee-feeFrom);
      for(const it of itemsOf(t.from_items)) await db.query("INSERT INTO inventory(user_id,item_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=inventory.quantity+EXCLUDED.quantity",[t.to_user_id,it.itemId,it.quantity]);
      for(const it of itemsOf(t.to_items)) await db.query("INSERT INTO inventory(user_id,item_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=inventory.quantity+EXCLUDED.quantity",[t.from_user_id,it.itemId,it.quantity]);
      if(Number(t.from_gems)-feeFrom>0) await db.query("UPDATE users SET gems=gems+$1 WHERE id=$2",[Number(t.from_gems)-feeFrom,t.to_user_id]);
      if(Number(t.to_gems)-feeTo>0) await db.query("UPDATE users SET gems=gems+$1 WHERE id=$2",[Number(t.to_gems)-feeTo,t.from_user_id]);
      await db.query("DELETE FROM trade_locks WHERE trade_id=$1",[t.id]);
      const done=await db.query("UPDATE trades SET status='completed',from_confirmed=true,to_confirmed=true,fee_gems=$1 WHERE id=$2 RETURNING *",[fee,t.id]);
      return out(res,200,done.rows[0]);
    }
    const next=t.from_confirmed ? "confirmedA" : "confirmedB";
    const upd=await db.query("UPDATE trades SET status=$1,from_confirmed=$2,to_confirmed=$3 WHERE id=$4 RETURNING *",[next,t.from_confirmed,t.to_confirmed,t.id]);
    return out(res,200,upd.rows[0]);
  }
  if(req.method==="POST" && action==="cancel"){
    if(!["locked","confirmedA","confirmedB","disputed"].includes(t.status)) return out(res,409,{error:"TRADE_NOT_CANCELABLE"});
    await releaseTrade(t);
    const upd=await db.query("UPDATE trades SET status='cancelled' WHERE id=$1 RETURNING *",[t.id]);
    return out(res,200,upd.rows[0]);
  }
  if(req.method==="POST" && action==="dispute"){
    const reason=String(json(req).reason || "").trim().slice(0,1000);
    if(!reason) return out(res,400,{error:"INVALID_REASON"});
    const upd=await db.query("UPDATE trades SET status='disputed',dispute_reason=$1 WHERE id=$2 AND status IN ('locked','confirmedA','confirmedB') RETURNING *",[reason,t.id]);
    return out(res,upd.rowCount?200:409,upd.rowCount?upd.rows[0]:{error:"TRADE_NOT_DISPUTABLE"});
  }
  return out(res,404,{error:"NOT_FOUND"});
}
async function energy(req,res,u) {
  const b=json(req), amount=Number(b.amount||0), key=String(b.idempotencyKey||"");
  if(!Number.isInteger(amount) || amount<=0) return out(res,400,{error:"INVALID_AMOUNT"});
  if(key){
    const prior=await db.query("SELECT id FROM energy_ledger WHERE idempotency_key=$1",[key]);
    if(prior.rowCount){
      const w=await db.query("SELECT energy FROM users WHERE id=$1",[u.id]);
      return out(res,200,{energy:Number(w.rows[0].energy),idempotent:true});
    }
  }
  const r=await db.query("UPDATE users SET energy=energy-$1,last_active=NOW() WHERE id=$2 AND energy>=$1 RETURNING energy",[amount,u.id]);
  if(!r.rowCount) return out(res,409,{error:"INSUFFICIENT_ENERGY"});
  await db.query("INSERT INTO energy_ledger(id,user_id,kind,amount,balance_after,reference_id,idempotency_key) VALUES(gen_random_uuid(),$1,'spend',$2,$3,'remote',$4)",[u.id,-amount,r.rows[0].energy,key||null]);
  return out(res,200,{energy:Number(r.rows[0].energy)});
}
async function signals(req,res,u) {
  if(req.method==="POST"){
    const target=await findUser(json(req).toUserId);
    if(!target) return out(res,404,{error:"USER_NOT_FOUND"});
    await db.query("INSERT INTO signals(id,to_user_id,from_user_id,payload) VALUES(gen_random_uuid(),$1,$2,$3::jsonb)",[target.id,u.id,JSON.stringify(json(req).payload||{})]);
    return out(res,200,{ok:true});
  }
  const r=await db.query("SELECT id,from_user_id,payload,created_at FROM signals WHERE to_user_id=$1 AND consumed_at IS NULL ORDER BY created_at ASC LIMIT 50",[u.id]);
  if(r.rowCount) await db.query("UPDATE signals SET consumed_at=NOW() WHERE id=ANY($1::uuid[])",[r.rows.map(x=>x.id)]);
  return out(res,200,r.rows.map(x=>({type:"signal",fromUserId:x.from_user_id,payload:x.payload,createdAt:x.created_at})));
}

export default async function handler(req,res) {
  const r=route(req);
  if(r==="/health"){
    try{await db.query("SELECT 1");return res.json({ok:true,service:"nexo-online",database:"ok"});}
    catch(e){return out(res,503,{ok:false,database:"down",error:String(e)});}
  }
  if(r==="/auth/guest" && req.method==="POST"){
    const device=String(json(req).deviceId||"").trim();
    if(!device) return out(res,400,{error:"INVALID_DEVICE_ID"});
    let q=await db.query("SELECT * FROM users WHERE device_id=$1",[device]), u=q.rows[0];
    if(!u){
      let base="guest_"+device.replace(/[^a-zA-Z0-9]/g,"").slice(-16);
      let name=base, i=0;
      while((await db.query("SELECT 1 FROM users WHERE lower(username)=lower($1)",[name])).rowCount){i++;name=base+"_"+i;}
      q=await db.query("INSERT INTO users(id,username,display_name,device_id,gems,energy) VALUES(gen_random_uuid(),$1,'NEXO Guest',$2,1000,50) RETURNING *",[name,device]);
      u=q.rows[0];
      const starter=[
        ["neon-heart",5],["shadow-flame",2],["galaxy-aura",2],["crown-shine",2],["name-glow",1],
        ["diamond-glow",1],["fire-wings",1],["frame-cyan",1],["asset-cosmic",1],["emoji-love",3]
      ];
      for(const x of starter) await db.query("INSERT INTO inventory(user_id,item_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,item_id) DO NOTHING",[u.id,x[0],x[1]]);
    }
    const token=await issueSession(u.id);
    await db.query("UPDATE users SET last_active=NOW() WHERE id=$1",[u.id]);
    return res.json({token,user:publicUser(u)});
  }
  if(r==="/catalog" && req.method==="GET") return catalog(req,res);
  const u=await needUser(req,res); if(!u) return;
  if(r==="/users" && req.method==="GET"){
    const q=await db.query('SELECT u.id,u.username,u.display_name,u.avatar,u.level,u.name_color,u.glow,COALESCE(p.online,FALSE) AS online,u.last_active FROM users u LEFT JOIN presence p ON p.user_id=u.id WHERE u.id<>$1 AND u.banned=false ORDER BY COALESCE(p.online,FALSE) DESC,u.last_active DESC LIMIT 100',[u.id]);
    return res.json(q.rows.map(x=>({...x,online:Boolean(x.online || (new Date(x.last_active).getTime()>Date.now()-300000))})));
  }
  if(r==="/me" && req.method==="GET") return res.json({user:publicUser(u)});
  if(r==="/wallet" && req.method==="GET"){
    const w=await db.query("SELECT gems,energy FROM users WHERE id=$1",[u.id]);
    return res.json({gems:Number(w.rows[0].gems),energy:Number(w.rows[0].energy)});
  }
  if(r==="/inventory" && req.method==="GET"){
    const x=await db.query('SELECT i.item_id AS "itemId",i.quantity,g.name,g.image,g.rarity,g.gems,g.tradeable,g.item_type AS "itemType" FROM inventory i JOIN gifts g ON g.id=i.item_id WHERE i.user_id=$1 AND i.quantity>0 ORDER BY g.sort_order,g.name',[u.id]);
    return res.json(x.rows);
  }
  if(r==="/gifts" && req.method==="GET") return catalog({...req,query:{type:"gift"}},res);
  if(r.startsWith("/chat/") && r.endsWith("/messages")) return chat(req,res,u);
  if(r==="/gifts/send" && req.method==="POST") return sendGift(req,res,u);
  if(r.startsWith("/trades")) return trades(req,res,u);
  if(r==="/economy/energy/spend" && req.method==="POST") return energy(req,res,u);
  if(r==="/signal/send" && req.method==="POST") return signals(req,res,u);
  if(r==="/signal/poll" && req.method==="GET") return signals(req,res,u);
  if(r==="/rtc/config" && req.method==="GET") return res.json({iceServers:[{urls:["stun:stun.l.google.com:19302"]}]});
  if(r==="/presence" && req.method==="POST"){
    const online=Boolean(json(req).online);
    await db.query(
      "INSERT INTO presence(user_id,online,last_seen) VALUES($1,$2,NOW()) ON CONFLICT(user_id) DO UPDATE SET online=$2,last_seen=NOW()",
      [u.id,online]);
    return res.json({online});
  }
  if(r.startsWith("/presence/") && req.method==="GET"){
    const peer=await findUser(r.split("/")[2]);
    if(!peer) return out(res,404,{error:"USER_NOT_FOUND"});
    const p=await db.query("SELECT online,last_seen FROM presence WHERE user_id=$1",[peer.id]);
    return res.json(p.rows[0] || {online:false,last_seen:null});
  }
  if(r==="/notifications" && req.method==="GET"){
    const n=await db.query("SELECT id,kind,title,body,data,read,created_at FROM notifications WHERE user_id=$1 ORDER BY created_at DESC LIMIT 100",[u.id]);
    return res.json(n.rows);
  }
  if(r==="/notifications/read-all" && req.method==="POST"){
    await db.query("UPDATE notifications SET read=true WHERE user_id=$1 AND read=false",[u.id]);
    return res.json({ok:true});
  }
  return out(res,404,{error:"NOT_FOUND"});
}