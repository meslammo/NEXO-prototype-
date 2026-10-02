import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../theme/nexo_theme.dart';
import '../config/api_config.dart';

class MissionsScreen extends StatefulWidget{const MissionsScreen({super.key});@override State<MissionsScreen> createState()=>_MissionsScreenState();}
class _MissionsScreenState extends State<MissionsScreen>{
  List<Map<String,dynamic>> data=[];bool loading=true;String date='';bool vip=false,svip=false;
  @override void initState(){super.initState();load();}
  Future<void> load() async{
    try{
      if(NexoApiConfig.configured){
        final r=await context.read<ApiClient>().getJson('/missions/today');
        final raw=r['missions'];
        final list=raw is List?raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];
        if(mounted)setState((){data=list;date=r['date']?.toString()??'';vip=r['vip']==true;svip=r['svip']==true;loading=false;});
        return;
      }
    }catch(_){}
    final seed=<Map<String,dynamic>>[
      {'id':'daily_login','group':'daily','title':'دخول NEXO','description':'افتح NEXO اليوم','activityType':'login','target':1,'progress':1,'rewardGems':20,'claimed':false},
      {'id':'daily_chat','group':'daily','title':'3 رسائل شات','description':'ابعت 3 رسائل','activityType':'chat','target':3,'progress':0,'rewardGems':15,'claimed':false},
      {'id':'daily_gift','group':'daily','title':'إرسال هدية','description':'ابعت هدية واحدة','activityType':'gift_send','target':1,'progress':0,'rewardGems':30,'claimed':false},
      {'id':'daily_game','group':'daily','title':'فوز لعبة','description':'حقق فوزًا في لعبة','activityType':'game_win','target':1,'progress':0,'rewardGems':35,'claimed':false},
      {'id':'tribe_chat','group':'tribe','title':'Tribe Together','description':'شارك داخل Tribe','activityType':'tribe_chat','target':3,'progress':0,'rewardGems':50,'claimed':false},
      {'id':'vip_chat','group':'vip','title':'VIP Social','description':'10 رسائل','activityType':'chat','target':10,'progress':0,'rewardGems':80,'claimed':false},
      {'id':'svip_game','group':'svip','title':'SVIP Gamer','description':'3 انتصارات','activityType':'game_win','target':3,'progress':0,'rewardGems':220,'claimed':false},
    ];
    if(mounted)setState((){data=seed;date=DateTime.now().toIso8601String().substring(0,10);vip=true;svip=true;loading=false;});
  }
  Future<void> claim(Map<String,dynamic> m) async{try{if(!NexoApiConfig.configured)return;final r=await context.read<ApiClient>().postJson('/missions/claim/'+m['id'].toString(),{});await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('✅ +'+r['rewardGems'].toString()+' Gems')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()),backgroundColor:Colors.redAccent));}}
  IconData icon(String? t){switch(t){case'login':return Icons.login;case'chat':return Icons.chat_bubble_outline;case'gift_send':return Icons.card_giftcard_outlined;case'emoji_use':return Icons.emoji_emotions_outlined;case'game_win':return Icons.sports_esports_outlined;case'voice_activity':return Icons.mic_none_rounded;case'moment_post':return Icons.photo_library_outlined;default:return Icons.task_alt;}}
  Widget section(String t,List<Map<String,dynamic>> l,IconData i)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(i,color:NexoColors.primary,size:20),const SizedBox(width:7),Text(t,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w900))]),const SizedBox(height:8),...l.map(card)]);
  Widget card(Map<String,dynamic> m){final target=(m['target'] as num?)?.toInt()??1,progress=(m['progress'] as num?)?.toInt()??0,reward=(m['rewardGems'] as num?)?.toInt()??0,done=m['claimed']==true,complete=progress>=target;return Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:complete?NexoColors.success.withOpacity(.4):NexoColors.cardBorder)),child:Row(children:[CircleAvatar(backgroundColor:NexoColors.primary.withOpacity(.1),child:Icon(icon(m['activityType']?.toString()),color:NexoColors.primary)),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m['title'].toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),Text(m['description'].toString(),style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)),const SizedBox(height:6),LinearProgressIndicator(value:(progress/target).clamp(0.0,1.0),minHeight:6,borderRadius:BorderRadius.circular(8)),const SizedBox(height:4),Text(progress.toString()+'/'+target.toString()+' • +'+reward.toString()+' Gems',style:TextStyle(color:complete?NexoColors.success:NexoColors.textSecondary,fontSize:10,fontWeight:FontWeight.bold))])),const SizedBox(width:6),SizedBox(width:66,child:ElevatedButton(onPressed:complete&&!done?()=>claim(m):null,child:Text(done?'تم':complete?'استلم':'ابدأ',style:const TextStyle(fontSize:9))))]));}
  @override Widget build(BuildContext context){final d=data.where((m)=>m['group']=='daily').toList(),v=data.where((m)=>m['group']=='vip').toList(),s=data.where((m)=>m['group']=='svip').toList();return Scaffold(backgroundColor:NexoColors.background,appBar:AppBar(backgroundColor:NexoColors.background,title:const Text('Missions • Daily / Tribe / VIP / SVIP'),centerTitle:true),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF24194D),Color(0xFF12152C)]),borderRadius:BorderRadius.circular(20)),child:Row(children:[CircleAvatar(backgroundColor:NexoColors.primary.withOpacity(.12),child:const Icon(Icons.today,color:NexoColors.primary)),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('مهام اليوم',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w900)),Text(date,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)),Text(svip?'SVIP Active':vip?'VIP Active':'Base Member',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.bold,fontSize:10))]))])),const SizedBox(height:12),section('Daily',d,Icons.today_outlined),const SizedBox(height:12),section('Tribe',data.where((m)=>m['group']=='tribe').toList(),Icons.groups_rounded),if(v.isNotEmpty)...[const SizedBox(height:12),section('VIP',v,Icons.workspace_premium_outlined)],if(s.isNotEmpty)...[const SizedBox(height:12),section('SVIP',s,Icons.auto_awesome)]])));}}
