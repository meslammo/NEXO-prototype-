import { db } from "hatchable";

export const access = "admin";

const json=(req)=>req.body&&typeof req.body==="object"?req.body:{};
const parts=(req)=>Array.isArray(req.params?.path)?req.params.path:[];
const route=(req)=>"/"+parts(req).join("/");
const out=(res,status,data)=>res.status(status).json(data);

async function audit(action,targetId,details){
  await db.query(
    "INSERT INTO admin_actions(id,admin_subject,action,target_id,details) VALUES(gen_random_uuid(),'hatchable-admin',$1,$2,$3::jsonb)",
    [action,targetId||null,JSON.stringify(details||{})]
  );
}

async function overview(res){
  const q=await Promise.all([
    db.query("SELECT count(*)::int AS n FROM users"),
    db.query("SELECT count(*)::int AS n FROM users WHERE banned=true"),
    db.query("SELECT count(*)::int AS n FROM gifts WHERE active=true"),
    db.query("SELECT count(*)::int AS n FROM trades WHERE status IN ('locked','confirmedA','confirmedB','disputed')"),
    db.query("SELECT COALESCE(sum(gems),0)::bigint AS n FROM users"),
    db.query("SELECT count(*)::int AS n FROM messages WHERE created_at>NOW()-INTERVAL '24 hours'")
  ]);
  return res.json({users:q[0].rows[0].n,banned:q[1].rows[0].n,activeItems:q[2].rows[0].n,activeTrades:q[3].rows[0].n,totalGems:Number(q[4].rows[0].n),messages24h:q[5].rows[0].n});
}

async function catalog(res){
  const r=await db.query('SELECT id,name,rarity,gems,tradeable,image,tagline,description,item_type AS "itemType",category,animation,market_visible AS "marketVisible",active,sort_order AS "sortOrder",tags,metadata FROM gifts ORDER BY sort_order,gems,name');
  return res.json(r.rows);
}

async function catalogUpsert(req,res){
  const b=json(req),id=String(b.id||"").trim(),name=String(b.name||"").trim();
  if(!id||!name)return out(res,400,{error:"ID_AND_NAME_REQUIRED"});
  const data=[id,name,String(b.rarity||"Common"),Math.max(0,Number(b.gems||0)),b.tradeable!==false,String(b.image||""),String(b.tagline||name),String(b.description||""),String(b.itemType||"gift"),String(b.category||"gifts"),String(b.animation||"pulse"),b.marketVisible!==false,b.active!==false,Number(b.sortOrder||0)];
  const r=await db.query(
    'INSERT INTO gifts(id,name,rarity,gems,tradeable,image,tagline,description,item_type,category,animation,market_visible,active,sort_order) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) ON CONFLICT(id) DO UPDATE SET name=EXCLUDED.name,rarity=EXCLUDED.rarity,gems=EXCLUDED.gems,tradeable=EXCLUDED.tradeable,image=EXCLUDED.image,tagline=EXCLUDED.tagline,description=EXCLUDED.description,item_type=EXCLUDED.item_type,category=EXCLUDED.category,animation=EXCLUDED.animation,market_visible=EXCLUDED.market_visible,active=EXCLUDED.active,sort_order=EXCLUDED.sort_order RETURNING id',
    data
  );
  await audit("catalog.upsert",id,{id,name});
  return res.json({ok:true,id:r.rows[0].id});
}

async function catalogToggle(req,res){
  const id=parts(req)[1];
  if(!id)return out(res,400,{error:"ITEM_ID_REQUIRED"});
  const r=await db.query("UPDATE gifts SET active=NOT active WHERE id=$1 RETURNING id,active",[id]);
  if(!r.rowCount)return out(res,404,{error:"ITEM_NOT_FOUND"});
  await audit("catalog.toggle",id,{active:r.rows[0].active});
  return res.json({ok:true,id:r.rows[0].id,active:r.rows[0].active});
}

async function bulkPrice(req,res){
  const b=json(req),itemType=String(b.itemType||"").trim(),rarity=String(b.rarity||"").trim(),gems=Math.max(0,Number(b.gems||0));
  if(!itemType||!rarity)return out(res,400,{error:"TYPE_AND_RARITY_REQUIRED"});
  const r=await db.query("UPDATE gifts SET gems=$1 WHERE item_type=$2 AND rarity=$3",[gems,itemType,rarity]);
  await audit("catalog.bulk_price",null,{itemType,rarity,gems,updated:r.rowCount});
  return res.json({ok:true,updated:r.rowCount});
}

async function users(res){
  const r=await db.query('SELECT id,username,display_name AS "displayName",avatar,gems,energy,level,role,banned,created_at AS "createdAt",last_active AS "lastActive" FROM users ORDER BY created_at DESC LIMIT 500');
  return res.json(r.rows.map(x=>({...x,gems:Number(x.gems),energy:Number(x.energy),level:Number(x.level)})));
}

async function userWallet(req,res){
  const id=parts(req)[1],b=json(req),gd=Math.trunc(Number(b.gemsDelta||0)),ed=Math.trunc(Number(b.energyDelta||0));
  if(!id)return out(res,400,{error:"USER_ID_REQUIRED"});
  const r=await db.query("UPDATE users SET gems=GREATEST(0,gems+$1),energy=LEAST(100,GREATEST(0,energy+$2)),last_active=NOW() WHERE id=$3 RETURNING id,gems,energy",[gd,ed,id]);
  if(!r.rowCount)return out(res,404,{error:"USER_NOT_FOUND"});
  await audit("user.wallet",id,{gemsDelta:gd,energyDelta:ed});
  return res.json({ok:true,userId:r.rows[0].id,gems:Number(r.rows[0].gems),energy:Number(r.rows[0].energy)});
}

async function userInventory(req,res){
  const id=parts(req)[1],b=json(req),itemId=String(b.itemId||"").trim(),quantity=Math.max(1,Math.trunc(Number(b.quantity||1)));
  if(!id||!itemId)return out(res,400,{error:"USER_AND_ITEM_REQUIRED"});
  const g=await db.query("SELECT id FROM gifts WHERE id=$1 AND active=true",[itemId]);
  if(!g.rowCount)return out(res,404,{error:"ITEM_NOT_FOUND"});
  const r=await db.query("INSERT INTO inventory(user_id,item_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=inventory.quantity+EXCLUDED.quantity RETURNING quantity",[id,itemId,quantity]);
  await audit("user.grant_item",id,{itemId,quantity});
  return res.json({ok:true,userId:id,itemId,quantity:Number(r.rows[0].quantity)});
}

async function userStatus(req,res){
  const id=parts(req)[1],b=json(req),banned=Boolean(b.banned);
  if(!id)return out(res,400,{error:"USER_ID_REQUIRED"});
  const r=await db.query("UPDATE users SET banned=$1 WHERE id=$2 RETURNING id,banned",[banned,id]);
  if(!r.rowCount)return out(res,404,{error:"USER_NOT_FOUND"});
  await audit("user.status",id,{banned});
  return res.json({ok:true,userId:id,banned:r.rows[0].banned});
}

async function messages(req,res){
  const limit=Math.min(500,Math.max(1,Number(req.query?.limit||150)));
  const r=await db.query('SELECT m.created_at AS "createdAt",su.username AS "senderUsername",ru.username AS "recipientUsername",m.kind,m.body,m.gift_id AS "giftId" FROM messages m JOIN users su ON su.id=m.sender_id JOIN users ru ON ru.id=m.recipient_id ORDER BY m.created_at DESC LIMIT $1',[limit]);
  return res.json(r.rows);
}

async function trades(res){
  const r=await db.query('SELECT id,status,from_user_id AS "fromUserId",to_user_id AS "toUserId",from_gems AS "fromGems",to_gems AS "toGems",fee_gems AS "feeGems",created_at AS "createdAt",expires_at AS "expiresAt" FROM trades ORDER BY created_at DESC LIMIT 500');
  return res.json(r.rows.map(x=>({...x,fromGems:Number(x.fromGems),toGems:Number(x.toGems),feeGems:Number(x.feeGems)})));
}

async function security(res){
  const r=await db.query('SELECT created_at AS "createdAt",event_type AS "eventType",severity,user_id AS "userId",ip,details FROM security_events ORDER BY created_at DESC LIMIT 500');
  return res.json(r.rows);
}

async function settings(req,res){
  if(req.method==="GET"){
    const r=await db.query("SELECT key,value FROM app_settings ORDER BY key");
    const d={};
    for(const x of r.rows){const v=x.value;d[x.key]=typeof v==="number"?v:Number(v?.value??v);}
    return res.json(d);
  }
  const b=json(req),key=String(b.key||"").trim(),value=Number(b.value);
  if(!key||!Number.isFinite(value))return out(res,400,{error:"INVALID_SETTING"});
  await db.query("INSERT INTO app_settings(key,value,updated_at) VALUES($1,to_jsonb($2::numeric),NOW()) ON CONFLICT(key) DO UPDATE SET value=EXCLUDED.value,updated_at=NOW()",[key,value]);
  await audit("setting.update",null,{key,value});
  return res.json({ok:true,key,value});
}

async function announce(req,res){
  const b=json(req),title=String(b.title||"").trim(),body=String(b.body||"").trim();
  if(!title||!body)return out(res,400,{error:"TITLE_AND_BODY_REQUIRED"});
  const r=await db.query("SELECT id FROM users WHERE banned=false");
  for(const u of r.rows)await db.query("INSERT INTO notifications(id,user_id,kind,title,body,data) VALUES(gen_random_uuid(),$1,'global_announcement',$2,$3,'{}'::jsonb)",[u.id,title,body]);
  await audit("announcement.broadcast",null,{title,recipients:r.rowCount});
  return res.json({ok:true,recipients:r.rowCount});
}

export default async function handler(req,res){
  const r=route(req),p=parts(req);
  if(r==="/overview"&&req.method==="GET")return overview(res);
  if(r==="/catalog"&&req.method==="GET")return catalog(res);
  if(r==="/catalog/upsert"&&req.method==="POST")return catalogUpsert(req,res);
  if(r==="/catalog/price-filter"&&req.method==="POST")return bulkPrice(req,res);
  if(p[0]==="catalog"&&p[2]==="toggle"&&req.method==="POST")return catalogToggle(req,res);
  if(r==="/users"&&req.method==="GET")return users(res);
  if(p[0]==="users"&&p[2]==="wallet"&&req.method==="POST")return userWallet(req,res);
  if(p[0]==="users"&&p[2]==="inventory"&&req.method==="POST")return userInventory(req,res);
  if(p[0]==="users"&&p[2]==="status"&&req.method==="POST")return userStatus(req,res);
  if(r==="/messages"&&req.method==="GET")return messages(req,res);
  if(r==="/trades"&&req.method==="GET")return trades(res);
  if(r==="/security-events"&&req.method==="GET")return security(res);
  if(r==="/settings"&&(req.method==="GET"||req.method==="POST"))return settings(req,res);
  if(r==="/announce"&&req.method==="POST")return announce(req,res);
  return out(res,404,{error:"NOT_FOUND"});
}