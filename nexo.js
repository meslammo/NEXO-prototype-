
const NEXO={
 key:"NEXO_MVP12",
 user:JSON.parse(localStorage.getItem("nexoUser")||'{"name":"NEXO Player","energy":100,"coins":1250,"vip":"Base","color":"#54d6ff","glow":true,"antiCheat":true}'),
 save(){localStorage.setItem("nexoUser",JSON.stringify(this.user));},
 toast(msg){let x=document.createElement("div");x.textContent=msg;x.style="position:fixed;top:70px;right:15px;z-index:99;background:#102a40;border:1px solid #2b6282;padding:12px 16px;border-radius:10px";document.body.appendChild(x);setTimeout(()=>x.remove(),1800)},
 spendEnergy(n){if(this.user.energy<n){this.toast("Energy غير كافية");return false}this.user.energy-=n;this.save();renderUser();return true},
 addCoins(n){this.user.coins+=n;this.save();renderUser()},
};
function renderUser(){document.querySelectorAll("[data-energy]").forEach(x=>x.textContent=NEXO.user.energy);document.querySelectorAll("[data-coins]").forEach(x=>x.textContent=NEXO.user.coins);document.querySelectorAll("[data-name]").forEach(x=>{x.textContent=NEXO.user.name;x.style.color=NEXO.user.color;x.style.textShadow=NEXO.user.glow?"0 0 12px "+NEXO.user.color:"none"});}
document.addEventListener("DOMContentLoaded",()=>{renderUser();document.querySelectorAll("[data-action]").forEach(b=>b.onclick=()=>action(b.dataset.action));});
function action(a){
 if(a==="voice"||a==="video"){if(NEXO.spendEnergy(5))NEXO.toast(a==="voice"?"Voice call demo started":"Video call demo started")}
 if(a==="mine"){if(NEXO.spendEnergy(3)){let reward=Math.floor(Math.random()*50)+10;NEXO.addCoins(reward);NEXO.toast("Mining reward +"+reward)}}
 if(a==="craft"){NEXO.toast("Crafting queue opened")}
 if(a==="buy"){NEXO.addCoins(-100);NEXO.toast("Item purchased")}
 if(a==="search")NEXO.toast("Search engine opened")
}
