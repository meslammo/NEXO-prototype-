import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/economy_service.dart';
import '../theme/nexo_theme.dart';
import '../config/api_config.dart';

class MembershipScreen extends StatefulWidget{final String? initialKind;const MembershipScreen({super.key,this.initialKind});@override State<MembershipScreen> createState()=>_MembershipScreenState();}
class _MembershipScreenState extends State<MembershipScreen>{
  List<Map<String,dynamic>> products=[];Map<String,dynamic> current={};String filter='all';bool loading=true;
  @override void initState(){super.initState();filter=widget.initialKind??'all';load();}
  Future<void> load() async{
    final fallback=<Map<String,dynamic>>[
      {'id':'vip_1_30','kind':'vip','name':'VIP I','durationDays':30,'gemsPrice':1500,'benefits':{'dailyGems':30,'extraDailyMissions':1,'storeDiscountPercent':3,'entranceEffects':true}},
      {'id':'vip_2_30','kind':'vip','name':'VIP II','durationDays':30,'gemsPrice':3000,'benefits':{'dailyGems':60,'extraDailyMissions':2,'storeDiscountPercent':5}},
      {'id':'vip_3_30','kind':'vip','name':'VIP III','durationDays':30,'gemsPrice':6500,'benefits':{'dailyGems':100,'extraDailyMissions':3,'profileBadge':true}},
      {'id':'vip_4_30','kind':'vip','name':'VIP IV','durationDays':30,'gemsPrice':12000,'benefits':{'dailyGems':160,'extraDailyMissions':4,'entranceEffects':true}},
      {'id':'vip_5_30','kind':'vip','name':'VIP V','durationDays':30,'gemsPrice':22000,'benefits':{'dailyGems':250,'extraDailyMissions':5,'exclusiveStore':true}},
      {'id':'svip_1_30','kind':'svip','name':'SVIP I','durationDays':30,'gemsPrice':10000,'benefits':{'dailyGems':250,'extraDailyMissions':5,'missionBonusPercent':10,'exclusiveStore':true}},
      {'id':'svip_2_30','kind':'svip','name':'SVIP II','durationDays':30,'gemsPrice':18000,'benefits':{'dailyGems':400,'extraDailyMissions':6,'missionBonusPercent':15}},
      {'id':'svip_3_30','kind':'svip','name':'SVIP III','durationDays':30,'gemsPrice':30000,'benefits':{'dailyGems':650,'extraDailyMissions':7,'missionBonusPercent':20,'exclusiveStore':true}},
    ];
    products=fallback;
    current={'vipActive':false,'svipActive':false,'vipLevel':0,'aristocracyLevel':0};
    if(NexoApiConfig.configured){
      try{
        final api=context.read<ApiClient>();
        final p=await api.getJson('/memberships/catalog');
        final c=await api.getJson('/memberships/current');
        final raw=p['data'];
        if(raw is List && raw.isNotEmpty) products=raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList();
        current=c;
      }catch(_){}
    }
    if(mounted)setState((){loading=false;});
  }
  Future<void> buy(Map<String,dynamic> p) async{if(!NexoApiConfig.configured){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('فعّل الـOnline Backend للشراء والحفظ عبر الأجهزة')));return;}final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(backgroundColor:NexoColors.card,title:Text(p['name'].toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),content:Text('شراء مقابل '+p['gemsPrice'].toString()+' Gems؟',style:const TextStyle(color:Colors.white70)),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),ElevatedButton(onPressed:()=>Navigator.pop(context,true),child:const Text('شراء'))]));if(ok!=true)return;try{await context.read<ApiClient>().postJson('/memberships/buy',{'productId':p['id'],'idempotencyKey':'membership-'+p['id'].toString()+'-'+DateTime.now().microsecondsSinceEpoch.toString()});final w=await context.read<ApiClient>().getJson('/wallet');final e=context.read<EconomyService>();e.setGems((w['gems'] as num?)?.toInt()??e.gems);await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('✅ تم تفعيل '+p['name'].toString())));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الشراء: '+e.toString()),backgroundColor:Colors.redAccent));}}
  String benefit(String k,dynamic v){if(k=='dailyGems')return '+'+v.toString()+' Gems يوميًا';if(k=='storeDiscountPercent')return v.toString()+'% خصم متجر';if(k=='extraDailyMissions')return '+'+v.toString()+' مهام';if(k=='missionBonusPercent')return '+'+v.toString()+'% مكافآت';if(k=='exclusiveStore'&&v==true)return 'متجر حصري';if(k=='profileBadge'&&v==true)return 'شارة Profile';if(k=='entranceEffects'&&v==true)return 'Entrance Effects';return k+': '+v.toString();}
  @override Widget build(BuildContext context){final visible=products.where((p)=>filter=='all'||p['kind']==filter).toList();return Scaffold(backgroundColor:NexoColors.background,appBar:AppBar(backgroundColor:NexoColors.background,title:const Text('VIP / SVIP'),centerTitle:true),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF261A48),Color(0xFF0E192C)]),borderRadius:BorderRadius.circular(20)),child:Row(children:[CircleAvatar(backgroundColor:NexoColors.gold.withOpacity(.13),child:Icon(current['svipActive']==true?Icons.workspace_premium:current['vipActive']==true?Icons.verified:Icons.star,color:NexoColors.gold)),const SizedBox(width:9),Expanded(child:Text(current['svipActive']==true?'SVIP ACTIVE':current['vipActive']==true?'VIP ACTIVE':'NEXO MEMBER',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)))])),const SizedBox(height:10),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:['all','vip','svip'].map((x)=>Padding(padding:const EdgeInsetsDirectional.only(end:7),child:ChoiceChip(label:Text(x.toUpperCase()),selected:filter==x,onSelected:(_){setState(()=>filter=x);}))).toList())),const SizedBox(height:10),...visible.map((p)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(17),border:Border.all(color:p['kind']=='svip'?NexoColors.gold.withOpacity(.35):NexoColors.primary.withOpacity(.22))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(p['name'].toString(),style:TextStyle(color:p['kind']=='svip'?NexoColors.gold:Colors.white,fontWeight:FontWeight.w900,fontSize:16))),Text(p['gemsPrice'].toString()+' 💎',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.w900))]),Text(p['durationDays'].toString()+' يوم',style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)),const SizedBox(height:7),Wrap(spacing:6,runSpacing:6,children:((p['benefits'] is Map)?Map<String,dynamic>.from(p['benefits']):<String,dynamic>{}).entries.map((e)=>Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:Colors.white.withOpacity(.05),borderRadius:BorderRadius.circular(8)),child:Text(benefit(e.key,e.value),style:const TextStyle(color:Colors.white70,fontSize:9)))).toList()),const SizedBox(height:8),SizedBox(width:double.infinity,child:ElevatedButton(onPressed:()=>buy(p),child:const Text('شراء بالـGems')))]))) ])));}}
