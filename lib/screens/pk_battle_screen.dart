import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/nexo_theme.dart';
import 'room_screen.dart';

class PkBattleScreen extends StatefulWidget{
  const PkBattleScreen({super.key});
  @override State<PkBattleScreen> createState()=>_PkBattleScreenState();
}
class _PkBattleScreenState extends State<PkBattleScreen>{
  List<Map<String,dynamic>> rooms=[];List<Map<String,dynamic>> gifts=[];Map<String,dynamic>? battle;
  String? selectedRoomId;final battleCode=TextEditingController();final joinRoomId=TextEditingController();
  Timer? poll;bool busy=false;String? error;
  @override void initState(){super.initState();load();}
  @override void dispose(){poll?.cancel();battleCode.dispose();joinRoomId.dispose();super.dispose();}
  Future<void> load() async{
    if(!NexoApiConfig.configured){if(mounted)setState(()=>error='السيرفر غير مهيأ.');return;}
    try{
      final api=context.read<ApiClient>();
      final r=await api.getJson('/rooms');final raw=r['rooms'];
      if(raw is List&&mounted)setState(()=>rooms=raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList());
      final g=await api.getJson('/gifts');final gr=g is List?g:g['data'];
      if(gr is List&&mounted)setState(()=>gifts=gr.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).take(8).toList());
    }catch(_){if(mounted)setState(()=>error='تعذر تحميل غرف NEXO.');}
  }
  List<Map<String,dynamic>> get myRooms{final me=context.read<AuthService>().userId;return rooms.where((r)=>me!=null&&r['hostId']?.toString()==me).toList();}
  Future<void> createBattle() async{
    if(selectedRoomId==null){setState(()=>error='اختار غرفة أنت الـHost بتاعها.');return;}
    setState(()=>busy=true);
    try{final r=await context.read<ApiClient>().postJson('/pk/battles',{'roomId':selectedRoomId});if(mounted){setState(()=>battle=Map<String,dynamic>.from(r));_startPoll();}}
    catch(e){if(mounted)setState(()=>error='تعذر إنشاء PK: '+e.toString());}finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> joinBattle() async{
    final code=battleCode.text.trim().toUpperCase(),room=joinRoomId.text.trim();
    if(code.length<4||room.isEmpty){setState(()=>error='اكتب Battle Code وRoom ID بتوع غرفتك.');return;}
    setState(()=>busy=true);
    try{final r=await context.read<ApiClient>().postJson('/pk/battles/'+code+'/join',{'roomId':room});if(mounted){setState(()=>battle=Map<String,dynamic>.from(r));_startPoll();}}
    catch(e){if(mounted)setState(()=>error='تعذر الانضمام للـPK: '+e.toString());}finally{if(mounted)setState(()=>busy=false);}
  }
  void _startPoll(){
    poll?.cancel();poll=Timer.periodic(const Duration(seconds:1),(_) async{
      final id=battle?['id']?.toString();if(id==null)return;
      try{final r=await context.read<ApiClient>().getJson('/pk/battles/'+id);if(mounted)setState(()=>battle=Map<String,dynamic>.from(r));if(r['status']=='finished')poll?.cancel();}catch(_){}
    });
  }
  Future<void> sendGift(Map<String,dynamic> giftData) async{
    final id=battle?['id']?.toString();if(id==null)return;
    try{
      final r=await context.read<ApiClient>().postJson('/pk/battles/'+id+'/gift',{'giftId':giftData['id'],'idempotencyKey':'pk-'+giftData['id'].toString()+'-'+DateTime.now().microsecondsSinceEpoch.toString()});
      if(mounted)setState(()=>battle=Map<String,dynamic>.from(r));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر دعم الفريق: '+e.toString()),backgroundColor:Colors.redAccent));}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:NexoColors.background,appBar:AppBar(backgroundColor:NexoColors.background,title:const Text('NEXO Battle'),centerTitle:true),
    body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF351B55),Color(0xFF102E47)]),borderRadius:BorderRadius.circular(24),border:Border.all(color:NexoColors.primary.withOpacity(.30))),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('⚔️ Battle Rush',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900)),SizedBox(height:5),Text('غرفتان • 5 دقائق • الهدايا = نقاط للفريق',style:TextStyle(color:NexoColors.textSecondary,fontSize:11))
      ])),
      const SizedBox(height:14),
      if(myRooms.isNotEmpty)...[
        const Text('غرفي كـHost',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),const SizedBox(height:7),
        DropdownButtonFormField<String>(value:selectedRoomId,dropdownColor:NexoColors.card,items:myRooms.map((r)=>DropdownMenuItem(value:r['id'].toString(),child:Text(r['title']?.toString()??'NEXO Room'))).toList(),onChanged:(v)=>setState(()=>selectedRoomId=v),decoration:const InputDecoration(filled:true,fillColor:NexoColors.card,labelText:'اختار الغرفة')),
        const SizedBox(height:8),FilledButton.icon(onPressed:busy?null:createBattle,icon:const Icon(Icons.flash_on_rounded),label:const Text('Create Battle'))
      ]else
        FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const VoiceRoomsScreen())),icon:const Icon(Icons.meeting_room),label:const Text('أنشئ غرفة أولًا')),
      const SizedBox(height:16),const Divider(color:Colors.white12),const SizedBox(height:10),
      const Text('Join Battle',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),const SizedBox(height:7),
      TextField(controller:battleCode,textCapitalization:TextCapitalization.characters,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(labelText:'Battle Code',filled:true,fillColor:NexoColors.card)),
      const SizedBox(height:7),TextField(controller:joinRoomId,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(labelText:'Your Room ID',filled:true,fillColor:NexoColors.card)),
      const SizedBox(height:8),FilledButton.icon(onPressed:busy?null:joinBattle,icon:const Icon(Icons.sports_kabaddi_rounded),label:const Text('Join Battle')),
      if(battle!=null)...[const SizedBox(height:18),_battleCard(),if(battle!['status']=='live'&&gifts.isNotEmpty)...[
        const SizedBox(height:10),const Text('ادعم فريقك بهدية',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),const SizedBox(height:8),
        SizedBox(height:92,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:gifts.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i){
          final giftData=gifts[i];
          return SizedBox(width:105,child:FilledButton(onPressed:()=>sendGift(giftData),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Text('🎁',style:TextStyle(fontSize:20)),Text(giftData['name']?.toString()??'Gift',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10)),Text((giftData['gems']??0).toString()+' 💎',style:const TextStyle(fontSize:9))])));
        }))
      ]],
      if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.redAccent,fontSize:11))),
      const SizedBox(height:20),OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const VoiceRoomsScreen())),icon:const Icon(Icons.record_voice_over),label:const Text('فتح NEXO Rooms')),
    ])),
  );
  Widget _battleCard(){
    final a=(battle?['teamAScore'] as num?)?.toInt()??0,b=(battle?['teamBScore'] as num?)?.toInt()??0,status=battle?['status']?.toString()??'waiting',winner=battle?['winnerTeam']?.toString();
    return Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(20),border:Border.all(color:NexoColors.primary.withOpacity(.28))),child:Column(children:[
      Text('Code: '+(battle?['inviteCode']?.toString()??'-'),style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.w900,letterSpacing:2)),const SizedBox(height:13),
      Row(children:[Expanded(child:_score('TEAM A',a,NexoColors.primary)),const Padding(padding:EdgeInsets.symmetric(horizontal:10),child:Text('VS',style:TextStyle(color:Colors.white54,fontWeight:FontWeight.w900))),Expanded(child:_score('TEAM B',b,Colors.purpleAccent))]),
      const SizedBox(height:10),Text(status=='finished'?(winner==null?'تعادل':'🏆 الفائز: TEAM '+winner!.toUpperCase()):status=='live'?'LIVE • 5 MIN':'WAITING FOR OPPONENT',style:TextStyle(color:status=='finished'?NexoColors.gold:NexoColors.success,fontWeight:FontWeight.w900,fontSize:11))
    ]));
  }
  Widget _score(String title,int score,Color color)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:color.withOpacity(.08),borderRadius:BorderRadius.circular(15),border:Border.all(color:color.withOpacity(.3))),child:Column(children:[Text(title,style:TextStyle(color:color,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(score.toString(),style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900))]));
}
