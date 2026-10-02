
const Fastify = require('fastify');
const cors = require('@fastify/cors');
const helmet = require('@fastify/helmet');
const rateLimit = require('@fastify/rate-limit');
const jwt = require('@fastify/jwt');
const websocket = require('@fastify/websocket');
const { randomUUID, randomBytes } = require('crypto');

const app = Fastify({ logger: true });
const PORT = Number(process.env.PORT || 3000);
const JWT_SECRET = process.env.JWT_SECRET || randomBytes(32).toString('hex');

app.register(cors, { origin: true });
app.register(helmet, { global: true });
app.register(rateLimit, { global: true, max: 240, timeWindow: '1 minute', keyGenerator: req => req.ip });
app.register(jwt, { secret: JWT_SECRET });
app.register(websocket);

const users = new Map();
const sessions = new Map();
const chessRooms = new Map();
const ludoRooms = new Map();
const dominoRooms = new Map();
const sockets = new Map();

const clean = v => String(v ?? '').trim();
function id(){ return randomUUID(); }
function code(){ return randomBytes(4).toString('hex').slice(0,6).toUpperCase(); }
function unique(map){ let c=''; do c=code(); while([...map.values()].some(r => r.inviteCode===c)); return c; }
function publicUser(u){ return {id:u.id,username:u.username,displayName:u.displayName,avatar:u.avatar,gems:u.gems,energy:u.energy,level:1,experience:0,reputation:0,vipLevel:'Base',nameColor:'#54d6ff',glow:true,role:'user',banned:false}; }

async function auth(req, reply){
  try {
    await req.jwtVerify();
    const u=users.get(req.user.sub);
    if(!u) return reply.code(401).send({error:'UNAUTHORIZED'});
    req.qaUser=u;
  } catch(_) { return reply.code(401).send({error:'UNAUTHORIZED'}); }
}
function newUser({username,displayName,deviceId}){
  const u={id:id(),username:username||('guest_'+clean(deviceId||id()).slice(0,30)),displayName:displayName||username||'NEXO Guest',avatar:'001.jpg',gems:10000,energy:100,deviceId:deviceId||null};
  users.set(u.id,u); return u;
}
function tokenFor(u){
  const t=app.jwt.sign({sub:u.id,username:u.username},{expiresIn:'30d'});
  sessions.set(t,u.id); return t;
}
function pairPlayers(list){
  return list.map((p,i)=>({seat:i,userId:p.userId,username:p.username,displayName:p.displayName,ready:!!p.ready,color:p.color}));
}

app.get('/health', async()=>({ok:true,service:'nexo-qa-games',games:['chess','ludo','domino']}));
app.post('/auth/guest', async(req)=>{
  const deviceId=clean(req.body?.deviceId)||id();
  let u=[...users.values()].find(x=>x.deviceId===deviceId);
  if(!u) u=newUser({deviceId});
  return {token:tokenFor(u),user:publicUser(u)};
});
app.post('/auth/register', async(req,reply)=>{
  const b=req.body||{}, username=clean(b.username).toLowerCase(), email=clean(b.email).toLowerCase(), password=clean(b.password);
  if(!/^[a-zA-Z0-9_]{3,24}$/.test(username)||!email||password.length<8) return reply.code(400).send({error:'INVALID_ACCOUNT_INPUT'});
  const u=newUser({username,displayName:clean(b.displayName)||username}); return {token:tokenFor(u),user:publicUser(u)};
});
app.post('/auth/login', async(req,reply)=>{
  const ident=clean(req.body?.identifier||req.body?.identity||req.body?.email||req.body?.username).toLowerCase();
  const password=clean(req.body?.password);
  if(!ident||!password) return reply.code(400).send({error:'LOGIN_REQUIRED'});
  if(ident!=='nexo_demo'||password!=='12345678') return reply.code(401).send({error:'INVALID_CREDENTIALS'});
  const u=newUser({username:'nexo_demo',displayName:'NEXO Demo'}); return {token:tokenFor(u),user:publicUser(u)};
});
app.get('/me',{preHandler:auth},async req=>({user:publicUser(req.qaUser)}));
app.post('/auth/logout',{preHandler:auth},async()=>({ok:true}));
app.get('/wallet',{preHandler:auth},async req=>({gems:req.qaUser.gems,energy:req.qaUser.energy}));
app.get('/inventory',{preHandler:auth},async()=>[]);
app.get('/catalog',async()=>[]);
app.get('/profile/equipped',{preHandler:auth},async()=>[]);
app.get('/notifications',{preHandler:auth},async()=>[]);
app.post('/presence',{preHandler:auth},async(req)=>({online:!!req.body?.online}));
app.get('/presence/:id',async()=>({online:true,last_seen:new Date().toISOString()}));

app.register(async function(wsPlugin){
  wsPlugin.get('/ws',{websocket:true},(socket,req)=>{
    try{
      const decoded=app.jwt.verify(clean(req.query?.token));
      const uid=decoded.sub;
      if(!sockets.has(uid))sockets.set(uid,new Set());
      sockets.get(uid).add(socket);
      socket.on('close',()=>{ const set=sockets.get(uid); if(set){set.delete(socket);if(!set.size)sockets.delete(uid);} });
    }catch(_){ try{socket.close();}catch(e){} }
  });
});

function visibleLudo(r, me){
  const players=r.players.map(p=>({...p}));
  const my=players.find(p=>p.userId===me);
  return {id:r.id,inviteCode:r.inviteCode,maxPlayers:r.maxPlayers,status:r.status,turnSeat:r.turnSeat,dice:r.dice,state:r.state,winnerUserId:r.winnerUserId||null,players:pairPlayers(players.map(p=>({...p,color:null}))),meSeat:my?.seat??0};
}
function ludoInit(){return {pawns:[[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]]};}
function ludoCell(seat,pos){return (seat*13+(pos-1))%52;}
function ludoSafe(c){return c===0||c===13||c===26||c===39;}
function ludoWinner(p){return p.every(x=>Number(x)===57);}
function ludoMembers(r){return r.players.slice().sort((a,b)=>a.seat-b.seat);}
function ludoNext(r,seat){
  const p=ludoMembers(r), i=p.findIndex(x=>x.seat===seat); return p.length ? p[(i+1)%p.length].seat : seat;
}
function createLudo(u,maxPlayers=4){let r={id:id(),inviteCode:unique(ludoRooms),hostId:u.id,maxPlayers:Math.min(4,Math.max(2,Number(maxPlayers)||4)),status:'waiting',turnSeat:0,dice:0,state:ludoInit(),winnerUserId:null,players:[{seat:0,userId:u.id,username:u.username,displayName:u.displayName,ready:true}],createdAt:Date.now()};ludoRooms.set(r.id,r);return r;}
async function ludoCreate(req,reply){
  const u=req.qaUser,max=Math.min(4,Math.max(2,Number(req.body?.maxPlayers)||4)),r=createLudo(u,max); return visibleLudo(r,u.id);
}
app.post('/games/ludo/rooms',{preHandler:auth},ludoCreate);
app.post('/games/ludo/match',{preHandler:auth},async(req)=>{const u=req.qaUser,max=Math.min(4,Math.max(2,Number(req.body?.maxPlayers)||4));let r=[...ludoRooms.values()].find(x=>x.status==='waiting'&&x.maxPlayers===max&&x.hostId!==u.id&&x.players.length<x.maxPlayers);if(!r)r=createLudo(u,max);else{r.players.push({seat:r.players.length,userId:u.id,username:u.username,displayName:u.displayName,ready:false});}return visibleLudo(r,u.id);});
function getLudoRoom(ref){return [...ludoRooms.values()].find(x=>x.id===ref||x.inviteCode.toUpperCase()===ref.toUpperCase());}
app.post('/games/ludo/rooms/:ref/join',{preHandler:auth},async(req,reply)=>{const u=req.qaUser,r=getLudoRoom(req.params.ref);if(!r)return reply.code(404).send({error:'LUDO_ROOM_NOT_FOUND'});if(r.players.some(p=>p.userId===u.id))return visibleLudo(r,u.id);if(r.status!=='waiting')return reply.code(409).send({error:'LUDO_ROOM_NOT_JOINABLE'});if(r.players.length>=r.maxPlayers)return reply.code(409).send({error:'LUDO_ROOM_FULL'});r.players.push({seat:r.players.length,userId:u.id,username:u.username,displayName:u.displayName,ready:false});return visibleLudo(r,u.id);});
app.get('/games/ludo/rooms/:id',{preHandler:auth},async(req,reply)=>{const r=ludoRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'LUDO_ROOM_NOT_FOUND'});if(!r.players.some(p=>p.userId===req.qaUser.id))return reply.code(403).send({error:'LUDO_NOT_IN_ROOM'});return visibleLudo(r,req.qaUser.id);});
app.post('/games/ludo/rooms/:id/ready',{preHandler:auth},async(req,reply)=>{const r=ludoRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'LUDO_ROOM_NOT_FOUND'});const p=r.players.find(p=>p.userId===req.qaUser.id);if(!p)return reply.code(403).send({error:'LUDO_NOT_IN_ROOM'});p.ready=req.body?.ready!==false;if(r.players.length>=2&&r.players.every(p=>p.ready))r.status='ready';return visibleLudo(r,req.qaUser.id);});
app.post('/games/ludo/rooms/:id/start',{preHandler:auth},async(req,reply)=>{const r=ludoRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'LUDO_ROOM_NOT_FOUND'});if(r.hostId!==req.qaUser.id)return reply.code(403).send({error:'LUDO_HOST_ONLY'});if(r.players.length<2||!r.players.every(p=>p.ready))return reply.code(409).send({error:'LUDO_NOT_READY'});r.status='playing';r.turnSeat=r.players[0].seat;r.dice=0;return visibleLudo(r,req.qaUser.id);});
app.post('/games/ludo/rooms/:id/roll',{preHandler:auth},async(req,reply)=>{const r=ludoRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'LUDO_ROOM_NOT_FOUND'});const me=r.players.find(p=>p.userId===req.qaUser.id);if(!me||me.seat!==r.turnSeat)return reply.code(409).send({error:'LUDO_NOT_YOUR_TURN'});if(r.status!=='playing')return reply.code(409).send({error:'LUDO_NOT_PLAYING'});if(r.dice)return reply.code(409).send({error:'LUDO_MOVE_PENDING'});const d=1+Math.floor(Math.random()*6),pawns=r.state.pawns;const can=pawns[me.seat].some(pos=>(pos===-1&&d===6)||(pos>=1&&pos+d<=57));if(!can){r.dice=0;r.turnSeat=ludoNext(r,me.seat);}else r.dice=d;return visibleLudo(r,req.qaUser.id);});
app.post('/games/ludo/rooms/:id/move',{preHandler:auth},async(req,reply)=>{const r=ludoRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'LUDO_ROOM_NOT_FOUND'});const me=r.players.find(p=>p.userId===req.qaUser.id);const pi=Number(req.body?.pawnIndex);if(!me)return reply.code(403).send({error:'LUDO_NOT_IN_ROOM'});if(r.status!=='playing')return reply.code(409).send({error:'LUDO_NOT_PLAYING'});if(me.seat!==r.turnSeat)return reply.code(409).send({error:'LUDO_NOT_YOUR_TURN'});if(!Number.isInteger(pi)||pi<0||pi>3)return reply.code(400).send({error:'INVALID_PAWN'});const d=r.dice;if(!d)return reply.code(409).send({error:'LUDO_ROLL_FIRST'});let cur=Number(r.state.pawns[me.seat][pi]),next;if(cur===-1){if(d!==6)return reply.code(409).send({error:'LUDO_NEEDS_SIX'});next=1;}else{next=cur+d;if(next>57)return reply.code(409).send({error:'LUDO_OVERSHOOT'});}r.state.pawns[me.seat][pi]=next;let captured=false;if(next<52&&!ludoSafe(ludoCell(me.seat,next))){for(const op of r.players){if(op.seat===me.seat)continue;for(let p=0;p<4;p++){const ov=Number(r.state.pawns[op.seat][p]);if(ov>=0&&ov<52&&ludoCell(op.seat,ov)===ludoCell(me.seat,next)){r.state.pawns[op.seat][p]=-1;captured=true;break;}}if(captured)break;}}const won=ludoWinner(r.state.pawns[me.seat]);r.dice=0;if(won){r.status='finished';r.winnerUserId=req.qaUser.id;}else if(d===6||captured){}else r.turnSeat=ludoNext(r,me.seat);return visibleLudo(r,req.qaUser.id);});

function chessColor(p){return p?(p===p.toUpperCase()?'white':'black'):null;}
const INITIAL='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
function chessParse(fen){const p=String(fen||INITIAL).trim().split(/\s+/),board=new Array(64).fill(null);let i=0;for(const ch of p[0]){if(ch==='/')continue;if(ch>='1'&&ch<='8')i+=Number(ch);else board[i++]=ch;}return{board,turn:p[1]==='b'?'black':'white',castling:p[2]&&p[2]!=='-'?p[2]:'',ep:p[3]&&p[3]!=='-'?p[3]:null,half:Number(p[4]||0),full:Number(p[5]||1)};}
function chessSq(s){s=String(s||'').toLowerCase();return/^[a-h][1-8]$/.test(s)?(8-Number(s[1]))*8+s.charCodeAt(0)-97:-1;}
function chessName(i){return String.fromCharCode(97+i%8)+(8-Math.floor(i/8));}
function bounds(r,c){return r>=0&&r<8&&c>=0&&c<8;}
function attacked(st,target,by){const tr=Math.floor(target/8),tc=target%8,ww=by==='white';for(let i=0;i<64;i++){const p=st.board[i];if(!p||chessColor(p)!==by)continue;const r=Math.floor(i/8),c=i%8,t=p.toLowerCase();if(t==='p'){const dr=ww?-1:1;if(r+dr===tr&&(c-1===tc||c+1===tc))return true;}else if(t==='n'){for(const x of[[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]])if(r+x[0]===tr&&c+x[1]===tc)return true;}else if(t==='k'){if(Math.max(Math.abs(tr-r),Math.abs(tc-c))===1)return true;}else{const ds=[];if(t==='b'||t==='q')ds.push([-1,-1],[-1,1],[1,-1],[1,1]);if(t==='r'||t==='q')ds.push([-1,0],[1,0],[0,-1],[0,1]);for(const [dr,dc] of ds){let rr=r+dr,cc=c+dc;while(bounds(rr,cc)){const idx=rr*8+cc;if(idx===target)return true;if(st.board[idx])break;rr+=dr;cc+=dc;}}}}return false;}
function king(st,c){return st.board.findIndex(p=>p===(c==='white'?'K':'k'));}
function inCheck(st,c){const k=king(st,c);return k>=0&&attacked(st,k,c==='white'?'black':'white');}
function cloneChess(st){return{board:st.board.slice(),turn:st.turn,castling:st.castling,ep:st.ep,half:st.half,full:st.full};}
function addChess(out,from,to,prom,flags){out.push({from,to,promotion:prom||null,castle:!!flags?.castle,ep:!!flags?.ep});}
function pseudo(st){const out=[],w=st.turn==='white';for(let i=0;i<64;i++){const p=st.board[i];if(!p||chessColor(p)!==st.turn)continue;const r=Math.floor(i/8),c=i%8,t=p.toLowerCase();if(t==='p'){const dir=w?-1:1,start=w?6:1,promo=w?0:7,rr=r+dir;if(bounds(rr,c)&&!st.board[rr*8+c]){const to=rr*8+c;if(rr===promo)for(const x of['q','r','b','n'])addChess(out,i,to,x);else addChess(out,i,to);const rr2=r+2*dir;if(r===start&&!st.board[rr2*8+c])addChess(out,i,rr2*8+c);}for(const dc of[-1,1]){const r2=r+dir,c2=c+dc;if(!bounds(r2,c2))continue;const to=r2*8+c2,target=st.board[to];if(target&&chessColor(target)!==st.turn){if(r2===promo)for(const x of['q','r','b','n'])addChess(out,i,to,x);else addChess(out,i,to);}else if(st.ep===chessName(to))addChess(out,i,to,null,{ep:true});}}else if(t==='n'){for(const[dr,dc]of[[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]]){const rr=r+dr,cc=c+dc;if(!bounds(rr,cc))continue;const q=st.board[rr*8+cc];if(!q||chessColor(q)!==st.turn)addChess(out,i,rr*8+cc);}}else if(t==='b'||t==='r'||t==='q'){const ds=[];if(t==='b'||t==='q')ds.push([-1,-1],[-1,1],[1,-1],[1,1]);if(t==='r'||t==='q')ds.push([-1,0],[1,0],[0,-1],[0,1]);for(const[dr,dc]of ds){let rr=r+dr,cc=c+dc;while(bounds(rr,cc)){const to=rr*8+cc,q=st.board[to];if(!q)addChess(out,i,to);else{if(chessColor(q)!==st.turn)addChess(out,i,to);break;}rr+=dr;cc+=dc;}}}else if(t==='k'){for(const[dr,dc]of[[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]){const rr=r+dr,cc=c+dc;if(!bounds(rr,cc))continue;const q=st.board[rr*8+cc];if(!q||chessColor(q)!==st.turn)addChess(out,i,rr*8+cc);}const e=w?'black':'white';if(w&&i===60&&!inCheck(st,'white')){if(st.castling.includes('K')&&!st.board[61]&&!st.board[62]&&!attacked(st,61,e)&&!attacked(st,62,e))addChess(out,60,62,null,{castle:true});if(st.castling.includes('Q')&&!st.board[59]&&!st.board[58]&&!st.board[57]&&!attacked(st,59,e)&&!attacked(st,58,e))addChess(out,60,58,null,{castle:true});}if(!w&&i===4&&!inCheck(st,'black')){if(st.castling.includes('k')&&!st.board[5]&&!st.board[6]&&!attacked(st,5,e)&&!attacked(st,6,e))addChess(out,4,6,null,{castle:true});if(st.castling.includes('q')&&!st.board[3]&&!st.board[2]&&!st.board[1]&&!attacked(st,3,e)&&!attacked(st,2,e))addChess(out,4,2,null,{castle:true});}}}return out;}
function applyChess(st,m){const n=cloneChess(st),p=n.board[m.from],cap=n.board[m.to],pawn=p&&p.toLowerCase()==='p';n.board[m.from]=null;if(m.ep)n.board[m.to+(p==='P'?8:-8)]=null;let placed=p;if(m.promotion)placed=p==='P'?m.promotion.toUpperCase():m.promotion;n.board[m.to]=placed;if(m.castle){if(m.to===62){n.board[63]=null;n.board[61]='R';}if(m.to===58){n.board[56]=null;n.board[59]='R';}if(m.to===6){n.board[7]=null;n.board[5]='r';}if(m.to===2){n.board[0]=null;n.board[3]='r';}}let rights=n.castling;if(p==='K')rights=rights.replace('K','').replace('Q','');if(p==='k')rights=rights.replace('k','').replace('q','');if(m.from===63||m.to===63)rights=rights.replace('K','');if(m.from===56||m.to===56)rights=rights.replace('Q','');if(m.from===7||m.to===7)rights=rights.replace('k','');if(m.from===0||m.to===0)rights=rights.replace('q','');n.castling=rights;n.ep=null;if(pawn&&Math.abs(m.to-m.from)===16)n.ep=chessName((m.to+m.from)/2);n.half=pawn||cap||m.ep?0:n.half+1;if(st.turn==='black')n.full++;n.turn=st.turn==='white'?'black':'white';return n;}
function legalChess(st){const o=[];for(const m of pseudo(st)){const n=applyChess(st,m);if(!inCheck(n,st.turn))o.push(m);}return o;}
function uci(m){return chessName(m.from)+chessName(m.to)+(m.promotion||'');}
function chessFen(st){const rows=[];for(let r=0;r<8;r++){let row='',e=0;for(let c=0;c<8;c++){const p=st.board[r*8+c];if(!p)e++;else{if(e){row+=e;e=0;}row+=p;}}if(e)row+=e;rows.push(row);}return rows.join('/')+' '+(st.turn==='white'?'w':'b')+' '+(st.castling||'-')+' '+(st.ep||'-')+' '+st.half+' '+st.full;}
function chessView(r,me){return{id:r.id,inviteCode:r.inviteCode,status:r.status,turnColor:r.turnColor,fen:r.fen,winnerUserId:r.winnerUserId||null,drawReason:r.drawReason||null,moves:r.moves,players:r.players.map(p=>({userId:p.userId,username:p.username,displayName:p.displayName,color:p.color,ready:!!p.ready})),meColor:r.players.find(p=>p.userId===me)?.color||'white'};}
function createChess(u){const r={id:id(),inviteCode:unique(chessRooms),hostId:u.id,status:'waiting',turnColor:'white',fen:INITIAL,winnerUserId:null,drawReason:null,moves:[],players:[{userId:u.id,username:u.username,displayName:u.displayName,color:'white',ready:true}]};chessRooms.set(r.id,r);return r;}
function getChessRoom(ref){return [...chessRooms.values()].find(r=>r.id===ref||r.inviteCode===String(ref).toUpperCase());}
app.post('/games/chess/rooms',{preHandler:auth},async req=>chessView(createChess(req.qaUser),req.qaUser.id));
app.post('/games/chess/match',{preHandler:auth},async req=>{const u=req.qaUser;let r=[...chessRooms.values()].find(r=>r.status==='waiting'&&r.hostId!==u.id&&r.players.length<2);if(!r)r=createChess(u);else{r.players.push({userId:u.id,username:u.username,displayName:u.displayName,color:'black',ready:false});}return chessView(r,u.id);});
app.post('/games/chess/rooms/:ref/join',{preHandler:auth},async(req,reply)=>{const u=req.qaUser,r=getChessRoom(req.params.ref);if(!r)return reply.code(404).send({error:'CHESS_ROOM_NOT_FOUND'});if(r.players.some(p=>p.userId===u.id))return chessView(r,u.id);if(r.status!=='waiting'||r.players.length>=2)return reply.code(409).send({error:'CHESS_ROOM_FULL'});r.players.push({userId:u.id,username:u.username,displayName:u.displayName,color:'black',ready:false});return chessView(r,u.id);});
app.get('/games/chess/rooms/:id',{preHandler:auth},async(req,reply)=>{const r=chessRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'CHESS_ROOM_NOT_FOUND'});if(!r.players.some(p=>p.userId===req.qaUser.id))return reply.code(403).send({error:'CHESS_NOT_IN_ROOM'});return chessView(r,req.qaUser.id);});
app.post('/games/chess/rooms/:id/ready',{preHandler:auth},async(req,reply)=>{const r=chessRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'CHESS_ROOM_NOT_FOUND'});const p=r.players.find(p=>p.userId===req.qaUser.id);if(!p)return reply.code(403).send({error:'CHESS_NOT_IN_ROOM'});p.ready=req.body?.ready!==false;return chessView(r,req.qaUser.id);});
app.post('/games/chess/rooms/:id/start',{preHandler:auth},async(req,reply)=>{const r=chessRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'CHESS_ROOM_NOT_FOUND'});if(r.hostId!==req.qaUser.id)return reply.code(403).send({error:'CHESS_HOST_ONLY'});if(r.players.length!==2||!r.players.every(p=>p.ready))return reply.code(409).send({error:'CHESS_NEEDS_TWO_READY'});r.status='playing';r.turnColor='white';return chessView(r,req.qaUser.id);});
app.post('/games/chess/rooms/:id/move',{preHandler:auth},async(req,reply)=>{const r=chessRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'CHESS_ROOM_NOT_FOUND'});if(r.status!=='playing')return reply.code(409).send({error:'CHESS_NOT_PLAYING'});const p=r.players.find(p=>p.userId===req.qaUser.id);if(!p)return reply.code(403).send({error:'CHESS_NOT_IN_ROOM'});if(p.color!==r.turnColor)return reply.code(409).send({error:'CHESS_NOT_YOUR_TURN'});const mv=clean(req.body?.uci).toLowerCase();if(!/^[a-h][1-8][a-h][1-8][qrbn]?$/.test(mv))return reply.code(400).send({error:'CHESS_INVALID_UCI'});const st=chessParse(r.fen),m=legalChess(st).find(z=>uci(z)===mv);if(!m)return reply.code(409).send({error:'CHESS_ILLEGAL_MOVE'});const n=applyChess(st,m);r.fen=chessFen(n);r.turnColor=n.turn;r.moves.push(mv);const ls=legalChess(n);if(!ls.length){r.status='finished';if(inCheck(n,n.turn))r.winnerUserId=req.qaUser.id;else r.drawReason='stalemate';}else if(n.half>=100){r.status='finished';r.drawReason='fifty_move';}return chessView(r,req.qaUser.id);});

function dominoDeck(){const d=[];for(let a=0;a<=6;a++)for(let b=a;b<=6;b++)d.push([a,b]);for(let i=d.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[d[i],d[j]]=[d[j],d[i]];}return d;}
function sameTile(a,b){return Array.isArray(a)&&Array.isArray(b)&&a[0]===b[0]&&a[1]===b[1];}
function removeTile(h,t){const i=h.findIndex(x=>sameTile(x,t));if(i<0)return null;return h.splice(i,1)[0];}
function orient(tile,side,end){const[a,b]=tile;if(side==='left'){if(a===end)return[b,a];if(b===end)return[a,b];}else{if(a===end)return[a,b];if(b===end)return[b,a];}return null;}
function dominoView(r,me){const meHand=r.hands[me]||[];const opp=r.players.find(x=>x.userId!==me);return{id:r.id,inviteCode:r.inviteCode,status:r.status,hostId:r.hostId,guestId:r.guestId,hostReady:!!r.hostReady,guestReady:!!r.guestReady,turnUserId:r.turnUserId,winnerUserId:r.winnerUserId||null,endedReason:r.endedReason||null,hand:meHand,opponentHandCount:opp?(r.hands[opp.userId]||[]).length:0,board:r.board,leftEnd:r.leftEnd,rightEnd:r.rightEnd,boneyardCount:r.boneyard.length,passes:r.passes,scores:r.scores,players:r.players.map(p=>({id:p.userId,username:p.username,displayName:p.displayName,avatar:'001.jpg',ready:p.ready}))};}
function createDomino(u){const r={id:id(),inviteCode:unique(dominoRooms),hostId:u.id,guestId:null,hostReady:true,guestReady:false,status:'waiting',turnUserId:null,winnerUserId:null,endedReason:null,hands:{},boneyard:[],board:[],leftEnd:null,rightEnd:null,passes:0,scores:{},players:[{userId:u.id,username:u.username,displayName:u.displayName,ready:true}]};dominoRooms.set(r.id,r);return r;}
function startDomino(r){const d=dominoDeck(),p=r.players.slice(0,2);r.hands={[p[0].userId]:d.splice(0,7),[p[1].userId]:d.splice(0,7)};r.boneyard=d;r.board=[];r.leftEnd=null;r.rightEnd=null;r.passes=0;r.scores={[p[0].userId]:0,[p[1].userId]:0};let starter=p[0].userId,best=-1;for(const [h,u] of [[r.hands[p[0].userId],p[0].userId],[r.hands[p[1].userId],p[1].userId]])for(const t of h)if(t[0]===t[1]&&t[0]>best){best=t[0];starter=u;}r.turnUserId=starter;r.status='playing';}
function maybeStartDomino(r){if(r.players.length===2&&r.hostReady&&r.guestReady&&r.status==='waiting')startDomino(r);}
function getDominoRoom(ref){return [...dominoRooms.values()].find(r=>r.id===ref||r.inviteCode===String(ref).toUpperCase());}
app.post('/games/domino/rooms',{preHandler:auth},async req=>dominoView(createDomino(req.qaUser),req.qaUser.id));
app.post('/games/domino/match',{preHandler:auth},async req=>{const u=req.qaUser;let r=[...dominoRooms.values()].find(r=>r.status==='waiting'&&r.guestId===null&&r.hostId!==u.id);if(!r)r=createDomino(u);else{r.guestId=u.id;r.players.push({userId:u.id,username:u.username,displayName:u.displayName,ready:false});}return dominoView(r,u.id);});
app.post('/games/domino/rooms/:ref/join',{preHandler:auth},async(req,reply)=>{const u=req.qaUser,r=getDominoRoom(req.params.ref);if(!r)return reply.code(404).send({error:'DOMINO_ROOM_NOT_FOUND'});if(r.players.some(p=>p.userId===u.id))return dominoView(r,u.id);if(r.status!=='waiting'||r.guestId)return reply.code(409).send({error:'DOMINO_ROOM_FULL'});r.guestId=u.id;r.players.push({userId:u.id,username:u.username,displayName:u.displayName,ready:false});return dominoView(r,u.id);});
app.get('/games/domino/rooms/:id',{preHandler:auth},async(req,reply)=>{const r=dominoRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'DOMINO_ROOM_NOT_FOUND'});if(!r.players.some(p=>p.userId===req.qaUser.id))return reply.code(403).send({error:'DOMINO_NOT_IN_ROOM'});return dominoView(r,req.qaUser.id);});
app.post('/games/domino/rooms/:id/ready',{preHandler:auth},async(req,reply)=>{const r=dominoRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'DOMINO_ROOM_NOT_FOUND'});const p=r.players.find(p=>p.userId===req.qaUser.id);if(!p)return reply.code(403).send({error:'DOMINO_NOT_IN_ROOM'});const rd=req.body?.ready!==false;if(r.hostId===req.qaUser.id)r.hostReady=rd;else r.guestReady=rd;p.ready=rd;maybeStartDomino(r);return dominoView(r,req.qaUser.id);});
app.post('/games/domino/rooms/:id/start',{preHandler:auth},async(req,reply)=>{const r=dominoRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'DOMINO_ROOM_NOT_FOUND'});if(!r.players.some(p=>p.userId===req.qaUser.id))return reply.code(403).send({error:'DOMINO_NOT_IN_ROOM'});maybeStartDomino(r);return dominoView(r,req.qaUser.id);});
app.post('/games/domino/rooms/:id/move',{preHandler:auth},async(req,reply)=>{const r=dominoRooms.get(req.params.id);if(!r)return reply.code(404).send({error:'DOMINO_ROOM_NOT_FOUND'});const me=req.qaUser.id;if(r.status!=='playing')return reply.code(409).send({error:'DOMINO_NOT_PLAYING'});if(r.turnUserId!==me)return reply.code(409).send({error:'DOMINO_NOT_YOUR_TURN'});const a=clean(req.body?.action).toLowerCase();const hand=r.hands[me]||[];if(a==='draw'){if(!r.boneyard.length)return reply.code(409).send({error:'DOMINO_BONEYARD_EMPTY'});hand.push(r.boneyard.shift());return dominoView(r,me);}if(a==='pass'){const playable=(r.leftEnd==null)||hand.some(t=>t[0]===r.leftEnd||t[1]===r.leftEnd||t[0]===r.rightEnd||t[1]===r.rightEnd);if(playable)return reply.code(409).send({error:'DOMINO_PLAYABLE_TILE_EXISTS'});if(r.boneyard.length)return reply.code(409).send({error:'DOMINO_DRAW_REQUIRED'});r.passes++;if(r.passes>=2){const a1=hand.reduce((s,t)=>s+t[0]+t[1],0),opp=r.players.find(p=>p.userId!==me),b1=(r.hands[opp.userId]||[]).reduce((s,t)=>s+t[0]+t[1],0);if(a1<b1)r.winnerUserId=me;else if(b1<a1)r.winnerUserId=opp.userId;else r.endedReason='draw';r.status='finished';}else r.turnUserId=r.players.find(p=>p.userId!==me)?.userId||me;return dominoView(r,me);}if(a==='play'){const tile=Array.isArray(req.body?.tile)?[Number(req.body.tile[0]),Number(req.body.tile[1])]:null,side=clean(req.body?.side).toLowerCase();if(!tile||tile.length!==2||tile.some(x=>!Number.isInteger(x)||x<0||x>6)||!['left','right'].includes(side))return reply.code(400).send({error:'INVALID_DOMINO_MOVE'});const picked=removeTile(hand,tile);if(!picked)return reply.code(409).send({error:'DOMINO_TILE_NOT_OWNED'});if(!r.board.length){r.board.push(picked);r.leftEnd=picked[0];r.rightEnd=picked[1];}else{const placed=orient(picked,side,side==='left'?r.leftEnd:r.rightEnd);if(!placed){hand.push(picked);return reply.code(409).send({error:'DOMINO_TILE_DOES_NOT_MATCH'});}if(side==='left'){r.board.unshift(placed);r.leftEnd=placed[0];}else{r.board.push(placed);r.rightEnd=placed[1];}}r.passes=0;if(!hand.length){r.winnerUserId=me;r.status='finished';r.endedReason='domino';}else r.turnUserId=r.players.find(p=>p.userId!==me)?.userId||me;return dominoView(r,me);}return reply.code(400).send({error:'INVALID_DOMINO_ACTION'});});

app.setErrorHandler((err,req,reply)=>{req.log.error(err);if(!reply.sent)reply.code(500).send({error:'INTERNAL_ERROR'});});
app.listen({host:'0.0.0.0',port:PORT}).then(()=>app.log.info({port:PORT},'NEXO QA online games server started')).catch(err=>{app.log.error(err);process.exit(1);});
