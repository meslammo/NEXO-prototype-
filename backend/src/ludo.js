function b(req){return req.body&&typeof req.body==="object"?req.body:{};}
function send(reply,status,data){return reply.code(status).send(data);}
function uid(req){return req.user.sub;}
function code(){const a="ABCDEFGHJKLMNPQRSTUVWXYZ23456789";let s="";for(let i=0;i<6;i++)s+=a[Math.floor(Math.random()*a.length)];return s;}
function initState(){return{pawns:[[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]]};}
function cell(seat,pos){return(seat*13+(pos-1))%52;}
function safe(c){return c===0||c===13||c===26||c===39;}
function winner(p){return p.every(x=>Number(x)===57);}
async function view(q,id){
 const r=await q("SELECT * FROM nexo.ludo_rooms WHERE id=$1",[id]); if(!r.rowCount)return null;
 const room=r.rows[0];
 const ps=await q("SELECT p.seat,p.ready,p.user_id,u.username,u.display_name FROM nexo.ludo_room_players p JOIN nexo.users u ON u.id=p.user_id WHERE p.room_id=$1 ORDER BY p.seat",[id]);
 const state=room.state&&typeof room.state==="object"?room.state:initState();
 return{id:room.id,inviteCode:room.invite_code,maxPlayers:Number(room.max_players),status:room.status,turnSeat:Number(room.turn_seat),dice:Number(room.dice||0),state,winnerUserId:room.winner_user_id,players:ps.rows.map(x=>({seat:Number(x.seat),ready:Boolean(x.ready),userId:x.user_id,username:x.username,displayName:x.display_name}))};
}
async function registerLudo(app,auth,q){
 const guard=(req,reply)=>auth(req,reply);
 app.post("/games/ludo/rooms",{preHandler:guard},async(req,reply)=>{
  const max=Math.min(4,Math.max(2,Number(b(req).maxPlayers||4)));
  for(let i=0;i<8;i++){try{const r=await q("INSERT INTO nexo.ludo_rooms(invite_code,host_id,max_players,state) VALUES($1,$2,$3,$4::jsonb) RETURNING id",[code(),uid(req),max,JSON.stringify(initState())]);await q("INSERT INTO nexo.ludo_room_players(room_id,user_id,seat,ready) VALUES($1,$2,0,true)",[r.rows[0].id,uid(req)]);return view(q,r.rows[0].id);}catch(e){}}
  return send(reply,500,{error:"LUDO_ROOM_CREATE_FAILED"});
 });
 app.post("/games/ludo/match",{preHandler:guard},async(req,reply)=>{
  const max=Math.min(4,Math.max(2,Number(b(req).maxPlayers||4)));
  const w=await q("SELECT r.id FROM nexo.ludo_rooms r WHERE r.status='waiting' AND r.max_players=$1 AND r.host_id<>$2 AND (SELECT COUNT(*) FROM nexo.ludo_room_players p WHERE p.room_id=r.id)<r.max_players ORDER BY r.created_at LIMIT 1",[max,uid(req)]);
  if(!w.rowCount){req.body={...b(req),maxPlayers:max};return app.inject({method:"POST",url:"/games/ludo/rooms",payload:req.body,headers:{authorization:req.headers.authorization}}).then(x=>reply.code(x.statusCode).send(x.json()));}
  const id=w.rows[0].id,c=await q("SELECT COUNT(*)::int AS n FROM nexo.ludo_room_players WHERE room_id=$1",[id]),seat=Number(c.rows[0].n);
  await q("INSERT INTO nexo.ludo_room_players(room_id,user_id,seat,ready) VALUES($1,$2,$3,false)",[id,uid(req),seat]);
  return view(q,id);
 });
 app.post("/games/ludo/rooms/:id/join",{preHandler:guard},async(req,reply)=>{
  const ref=String(req.params.id||"").trim(),r=await q("SELECT * FROM nexo.ludo_rooms WHERE id::text=$1 OR upper(invite_code)=upper($1) LIMIT 1",[ref]);
  if(!r.rowCount)return send(reply,404,{error:"LUDO_ROOM_NOT_FOUND"});
  const room=r.rows[0],me=uid(req);
  const exists=await q("SELECT seat FROM nexo.ludo_room_players WHERE room_id=$1 AND user_id=$2",[room.id,me]);
  if(exists.rowCount)return view(q,room.id);
  if(room.status!=="waiting")return send(reply,409,{error:"LUDO_ROOM_NOT_JOINABLE"});
  const count=await q("SELECT COUNT(*)::int AS n FROM nexo.ludo_room_players WHERE room_id=$1",[room.id]);
  if(Number(count.rows[0].n)>=Number(room.max_players))return send(reply,409,{error:"LUDO_ROOM_FULL"});
  const used=await q("SELECT seat FROM nexo.ludo_room_players WHERE room_id=$1",[room.id]),set=new Set(used.rows.map(x=>Number(x.seat)));let seat=0;while(set.has(seat))seat++;
  await q("INSERT INTO nexo.ludo_room_players(room_id,user_id,seat,ready) VALUES($1,$2,$3,false)",[room.id,me,seat]);
  return view(q,room.id);
 });
 app.post("/games/ludo/rooms/:id/ready",{preHandler:guard},async(req,reply)=>{
  const id=req.params.id,ready=Boolean(b(req).ready),r=await q("SELECT * FROM nexo.ludo_rooms WHERE id=$1",[id]);if(!r.rowCount)return send(reply,404,{error:"LUDO_ROOM_NOT_FOUND"});
  const me=await q("SELECT seat FROM nexo.ludo_room_players WHERE room_id=$1 AND user_id=$2",[id,uid(req)]);if(!me.rowCount)return send(reply,403,{error:"LUDO_NOT_IN_ROOM"});
  await q("UPDATE nexo.ludo_room_players SET ready=$1 WHERE room_id=$2 AND user_id=$3",[ready,id,uid(req)]);
  const ps=await q("SELECT ready FROM nexo.ludo_room_players WHERE room_id=$1",[id]);
  if(ps.rowCount>=2&&ps.rows.every(x=>x.ready))await q("UPDATE nexo.ludo_rooms SET status='ready' WHERE id=$1 AND status='waiting'",[id]);
  return view(q,id);
 });
 app.post("/games/ludo/rooms/:id/start",{preHandler:guard},async(req,reply)=>{
  const id=req.params.id,r=await q("SELECT * FROM nexo.ludo_rooms WHERE id=$1",[id]);if(!r.rowCount)return send(reply,404,{error:"LUDO_ROOM_NOT_FOUND"});
  if(String(r.rows[0].host_id)!==String(uid(req)))return send(reply,403,{error:"LUDO_HOST_ONLY"});
  const ps=await q("SELECT ready FROM nexo.ludo_room_players WHERE room_id=$1",[id]);
  if(ps.rowCount<2||!ps.rows.every(x=>x.ready))return send(reply,409,{error:"LUDO_NOT_READY"});
  await q("UPDATE nexo.ludo_rooms SET status='playing',turn_seat=0,dice=0 WHERE id=$1",[id]);return view(q,id);
 });
 app.post("/games/ludo/rooms/:id/roll",{preHandler:guard},async(req,reply)=>{
  const id=req.params.id,r=await q("SELECT * FROM nexo.ludo_rooms WHERE id=$1",[id]);if(!r.rowCount)return send(reply,404,{error:"LUDO_ROOM_NOT_FOUND"});
  const room=r.rows[0];if(room.status!=="playing")return send(reply,409,{error:"LUDO_NOT_PLAYING"});
  const me=await q("SELECT seat FROM nexo.ludo_room_players WHERE room_id=$1 AND user_id=$2",[id,uid(req)]);if(!me.rowCount||Number(me.rows[0].seat)!==Number(room.turn_seat))return send(reply,409,{error:"LUDO_NOT_YOUR_TURN"});
  if(Number(room.dice)!==0)return send(reply,409,{error:"LUDO_MOVE_PENDING"});
  const dice=1+Math.floor(Math.random()*6),state=room.state||initState(),pawns=state.pawns.map(x=>x.slice()),seat=Number(room.turn_seat);
  const can=pawns[seat].some(pos=>(Number(pos)===-1&&dice===6)||(Number(pos)>=1&&Number(pos)+dice<=57));
  if(!can){const members=(await q("SELECT seat FROM nexo.ludo_room_players WHERE room_id=$1 ORDER BY seat",[id])).rows.map(x=>Number(x.seat)),ix=members.indexOf(seat),next=members.length?members[(ix+1)%members.length]:seat;await q("UPDATE nexo.ludo_rooms SET dice=0,turn_seat=$1 WHERE id=$2",[next,id]);}
  else await q("UPDATE nexo.ludo_rooms SET dice=$1 WHERE id=$2",[dice,id]);
  return view(q,id);
 });
 app.post("/games/ludo/rooms/:id/move",{preHandler:guard},async(req,reply)=>{
  const id=req.params.id,pawnIndex=Number(b(req).pawnIndex),r=await q("SELECT * FROM nexo.ludo_rooms WHERE id=$1",[id]);if(!r.rowCount)return send(reply,404,{error:"LUDO_ROOM_NOT_FOUND"});
  const room=r.rows[0];if(!Number.isInteger(pawnIndex)||pawnIndex<0||pawnIndex>3)return send(reply,400,{error:"INVALID_PAWN"});if(room.status!=="playing")return send(reply,409,{error:"LUDO_NOT_PLAYING"});
  const me=await q("SELECT seat FROM nexo.ludo_room_players WHERE room_id=$1 AND user_id=$2",[id,uid(req)]);if(!me.rowCount||Number(me.rows[0].seat)!==Number(room.turn_seat))return send(reply,409,{error:"LUDO_NOT_YOUR_TURN"});
  const dice=Number(room.dice||0);if(dice<1||dice>6)return send(reply,409,{error:"LUDO_ROLL_FIRST"});
  const state=room.state||initState(),pawns=state.pawns.map(x=>x.slice()),seat=Number(room.turn_seat),cur=Number(pawns[seat][pawnIndex]);let next;
  if(cur===-1){if(dice!==6)return send(reply,409,{error:"LUDO_NEEDS_SIX"});next=1;}else{next=cur+dice;if(next>57)return send(reply,409,{error:"LUDO_OVERSHOOT"});}
  pawns[seat][pawnIndex]=next;
  let captured=false;
  if(next<52&&!safe(cell(seat,next))){for(let s=0;s<4;s++){if(s===seat)continue;for(let p=0;p<4;p++){const op=Number(pawns[s][p]);if(op>=0&&op<52&&cell(s,op)===cell(seat,next)){pawns[s][p]=-1;captured=true;break;}}if(captured)break;}}
  let status=room.status,winner=null,turn=seat;if(winner(pawns[seat])){status="finished";winner=uid(req);}else if(!(dice===6||captured)){const members=(await q("SELECT seat FROM nexo.ludo_room_players WHERE room_id=$1 ORDER BY seat",[id])).rows.map(x=>Number(x.seat)),ix=members.indexOf(seat);turn=members.length?members[(ix+1)%members.length]:seat;}
  await q("UPDATE nexo.ludo_rooms SET state=$1::jsonb,dice=0,status=$2,turn_seat=$3,winner_user_id=$4 WHERE id=$5",[JSON.stringify({...state,pawns}),status,turn,winner,id]);return view(q,id);
 });
 app.get("/games/ludo/rooms/:id",{preHandler:guard},async(req,reply)=>{
  const r=await q("SELECT host_id,guest_id FROM nexo.ludo_rooms WHERE id=$1",[req.params.id]);if(!r.rowCount)return send(reply,404,{error:"LUDO_ROOM_NOT_FOUND"});
  if(String(r.rows[0].host_id)!==String(uid(req))&&String(r.rows[0].guest_id||"")!==String(uid(req)))return send(reply,403,{error:"LUDO_NOT_IN_ROOM"});return view(q,req.params.id);
 });
}
module.exports={registerLudo};