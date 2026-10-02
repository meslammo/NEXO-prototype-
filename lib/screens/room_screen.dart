import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/room_voice_service.dart';
import '../theme/nexo_theme.dart';
import '../games/ludo/nexo_ludo_online_screen.dart';
import '../games/domino/nexo_domino_online_screen.dart';
import '../games/chess/nexo_chess_online_screen.dart';

class VoiceRoomsScreen extends StatefulWidget{
  const VoiceRoomsScreen({super.key});
  @override State<VoiceRoomsScreen> createState()=>_VoiceRoomsScreenState();
}
class _VoiceRoomsScreenState extends State<VoiceRoomsScreen>{
  List<Map<String,dynamic>> rooms=[];
  bool loading=true;
  Timer? timer;
  @override void initState(){super.initState();_load();timer=Timer.periodic(const Duration(seconds:3),(_)=>_load());}
  @override void dispose(){timer?.cancel();super.dispose();}
  Future<void> _load() async{
    if(!NexoApiConfig.configured){if(mounted)setState(()=>loading=false);return;}
    try{
      final r=await context.read<ApiClient>().getJson('/rooms');
      final raw=r['rooms'];
      if(raw is List&&mounted){
        setState((){rooms=raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList();loading=false;});
      }
    }catch(_){if(mounted)setState(()=>loading=false);}
  }
  Future<void> _create() async{
    if(!NexoApiConfig.configured){
      if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>const NexoRoomScreen()));
      return;
    }
    try{
      final r=await context.read<ApiClient>().postJson('/rooms',{'title':'NEXO Party Room'});
      if(!mounted)return;
      await Navigator.push(context,MaterialPageRoute(builder:(_)=>NexoRoomScreen(roomId:(r['room'] as Map?)?['id']?.toString())));
      _load();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إنشاء الغرفة: '+e.toString()),backgroundColor:Colors.redAccent));}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFF0A0A1B),
    appBar:AppBar(backgroundColor:Colors.transparent,title:const Text('NEXO Rooms',style:TextStyle(fontWeight:FontWeight.w900)),centerTitle:true),
    body:loading?const Center(child:CircularProgressIndicator()):Column(children:[
      Padding(padding:const EdgeInsets.all(14),child:Row(children:[
        const Expanded(child:Text('غرف صوتية • كراسي • مايك • ألعاب داخل الغرفة',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800))),
        FilledButton.icon(onPressed:_create,icon:const Icon(Icons.add_rounded),label:const Text('إنشاء'))
      ])),
      Expanded(child:rooms.isEmpty?const Center(child:Text('مفيش غرف حاليًا — اعمل أول غرفة.',style:TextStyle(color:Colors.white54))):ListView.builder(
        padding:const EdgeInsets.symmetric(horizontal:14),itemCount:rooms.length,itemBuilder:(_,i){
          final r=rooms[i];
          return Card(color:NexoColors.card,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),child:ListTile(
            contentPadding:const EdgeInsets.all(12),
            leading:CircleAvatar(radius:26,backgroundColor:NexoColors.primary.withOpacity(.13),child:const Icon(Icons.record_voice_over_rounded,color:NexoColors.primary)),
            title:Text(r['title']?.toString()??'NEXO Party',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),
            subtitle:Text((r['occupants']??0).toString()+'/'+(r['maxSeats']??9).toString()+' • '+(r['activeGame']?.toString()??'Chat'),style:const TextStyle(color:Colors.white54)),
            trailing:FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>NexoRoomScreen(roomId:r['id']?.toString()))),child:const Text('Join')),
          ));
        }))
    ])
  );
}

class NexoRoomScreen extends StatefulWidget{
  final String? roomId;
  const NexoRoomScreen({super.key,this.roomId});
  @override State<NexoRoomScreen> createState()=>_NexoRoomScreenState();
}

class _NexoRoomScreenState extends State<NexoRoomScreen>{
  Map<String,dynamic>? room;
  List<Map<String,dynamic>> seats=[];
  Timer? poll;
  bool muted=false;
  late final RoomVoiceService voice;
  bool get online=>NexoApiConfig.configured&&context.read<AuthService>().userId!=null;
  String get myId=>context.read<AuthService>().userId??'';
  @override void initState(){
    super.initState();
    voice=RoomVoiceService(context.read<RealtimeService>(),context.read<ApiClient>(),myId);
    _boot();
  }
  @override void dispose(){poll?.cancel();voice.dispose();super.dispose();}
  Future<void> _boot() async{
    if(!online)return;
    try{
      Map<String,dynamic> r;
      if(widget.roomId==null||widget.roomId!.isEmpty){
        final created=await context.read<ApiClient>().postJson('/rooms',{'title':'NEXO Party Room'});
        r=Map<String,dynamic>.from(created['room'] as Map);
      }else{
        await context.read<ApiClient>().postJson('/rooms/'+widget.roomId!+'/join',{});
        r=Map<String,dynamic>.from(await context.read<ApiClient>().getJson('/rooms/'+widget.roomId!));
      }
      if(!mounted)return;
      setState((){
        room=Map<String,dynamic>.from(r['room']??r);
        seats=(r['seats'] as List?)?.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList()??[];
      });
      await _startVoice();
      poll=Timer.periodic(const Duration(seconds:2),(_)=>_refresh());
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('الغرفة مش متاحة: '+e.toString()),backgroundColor:Colors.redAccent));
    }
  }
  Future<void> _refresh() async{
    final id=room?['id']?.toString();if(id==null)return;
    try{
      final r=await context.read<ApiClient>().getJson('/rooms/'+id);
      if(!mounted)return;
      final rs=(r['seats'] as List?)?.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList()??[];
      setState((){
        room=Map<String,dynamic>.from(r['room']??r);
        seats=rs;
      });
      final peers=seats.map((e)=>e['userId']?.toString()??'').where((e)=>e.isNotEmpty&&e!=myId).toList();
      if(peers.isNotEmpty && voice.roomId!=id)await voice.start(id,peers);
    }catch(_){}
  }
  Future<void> _startVoice() async{
    final id=room?['id']?.toString()??'';
    final peers=seats.map((e)=>e['userId']?.toString()??'').where((e)=>e.isNotEmpty&&e!=myId).toList();
    if(id.isEmpty||peers.isEmpty||!online)return;
    if(voice.roomId==id)return;
    await voice.start(id,peers);
  }
  Future<void> _mic() async{
    muted=!muted;
    await voice.setMuted(muted);
    final id=room?['id']?.toString();
    if(id!=null&&online){try{await context.read<ApiClient>().postJson('/rooms/'+id+'/mic',{'muted':muted,'speaking':!muted});}catch(_){}}
    if(mounted)setState((){});
  }
  Future<void> _game(String game) async{
    final id=room?['id']?.toString();if(id==null)return;
    if(online){try{await context.read<ApiClient>().postJson('/rooms/'+id+'/game',{'game':game});}catch(_){}}
    if(!mounted)return;
    final h=MediaQuery.of(context).size.height*.90;
    await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF060816),shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),builder:(_)=>SizedBox(height:h,child:game=='ludo'?const NexoLudoOnlineScreen():game=='domino'?const NexoDominoOnlineScreen():const NexoChessOnlineScreen()));
  }
  Widget _seat(Map<String,dynamic>? s,int index){
    final occupied=s!=null&&s['userId']!=null;
    final name=occupied?(s['displayName']?.toString()??'User'):'المقعد '+(index+1).toString();
    final mic=occupied&&s['muted']!=true;
    return Container(
      padding:const EdgeInsets.all(6),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:LinearGradient(colors:[Colors.white.withOpacity(.08),Colors.white.withOpacity(.02)]),border:Border.all(color:occupied?NexoColors.primary.withOpacity(.7):Colors.white.withOpacity(.08),width:occupied?1.5:1)),
      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Stack(children:[
          CircleAvatar(radius:25,backgroundColor:occupied?NexoColors.primary.withOpacity(.12):Colors.black26,child:Icon(occupied?Icons.person_rounded:Icons.event_seat_rounded,color:occupied?Colors.white54:Colors.white24,size:27)),
          if(index==0&&occupied)const Positioned(right:0,top:0,child:Icon(Icons.workspace_premium_rounded,color:Colors.amber,size:15)),
          if(occupied)Positioned(left:0,bottom:0,child:CircleAvatar(radius:9,backgroundColor:mic?Colors.greenAccent:Colors.redAccent,child:Icon(mic?Icons.mic:Icons.mic_off,color:Colors.black,size:11)))
        ]),
        const SizedBox(height:5),
        Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:occupied?Colors.white:Colors.white30,fontSize:10,fontWeight:FontWeight.w800))
      ])
    );
  }
  @override Widget build(BuildContext context){
    final grid=<Map<String,dynamic>?>[];
    for(int i=0;i<9;i++){Map<String,dynamic>? x;for(final s in seats){if(int.tryParse(s['seat']?.toString()??'')==i)x=s;}grid.add(x);}
    return Scaffold(
      backgroundColor:const Color(0xFF09091C),
      appBar:AppBar(backgroundColor:Colors.transparent,title:Text(room?['title']?.toString()??'NEXO Party',style:const TextStyle(fontWeight:FontWeight.w900)),centerTitle:true,actions:[
        if(room?['inviteCode']!=null)Padding(padding:const EdgeInsets.symmetric(horizontal:10),child:Center(child:Text(room!['inviteCode'].toString(),style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.w900))))
      ]),
      body:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(14,6,14,10),child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF291956),Color(0xFF102D4E)]),borderRadius:BorderRadius.circular(18)),child:Row(children:[
          const Icon(Icons.forum_rounded,color:NexoColors.primary),const SizedBox(width:8),Expanded(child:Text(seats.length.toString()+'/9 على المايك • '+(room?['activeGame']?.toString()??'Chat'),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800))),
          const Icon(Icons.lock_open_rounded,color:Colors.white54,size:18)
        ]))),
        Expanded(child:GridView.builder(padding:const EdgeInsets.all(14),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.88),itemCount:9,itemBuilder:(_,i)=>_seat(grid[i],i))),
        Container(padding:const EdgeInsets.fromLTRB(14,10,14,14),decoration:BoxDecoration(color:const Color(0xFF11112A),boxShadow:[BoxShadow(color:Colors.black45,blurRadius:18)]),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
          IconButton(onPressed:_mic,icon:Icon(muted?Icons.mic_off_rounded:Icons.mic_rounded,color:muted?Colors.redAccent:NexoColors.primary)),
          IconButton(onPressed:()=>_game('ludo'),icon:const Icon(Icons.casino_rounded,color:Colors.white)),
          IconButton(onPressed:()=>_game('domino'),icon:const Icon(Icons.grid_4x4_rounded,color:Colors.white)),
          IconButton(onPressed:()=>_game('chess'),icon:const Icon(Icons.extension_rounded,color:Colors.white)),
          IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.logout_rounded,color:Colors.redAccent))
        ]))
      ]))
    );
  }
}
