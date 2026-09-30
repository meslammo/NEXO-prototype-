
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/nexo_theme.dart';
import 'nexo_ludo_game.dart';

class NexoLudoOnlineScreen extends StatefulWidget {
  const NexoLudoOnlineScreen({super.key});
  @override
  State<NexoLudoOnlineScreen> createState() => _NexoLudoOnlineScreenState();
}

class _NexoLudoOnlineScreenState extends State<NexoLudoOnlineScreen> {
  Timer? _timer;
  final codeController = TextEditingController();
  Map<String,dynamic>? room;
  List<List<List<Rect>>>? tracks;
  int maxPlayers=4;
  bool busy=false;
  String? error;

  @override
  void dispose(){_timer?.cancel();codeController.dispose();super.dispose();}

  void startPoll(){
    _timer?.cancel();
    _timer=Timer.periodic(const Duration(seconds:1),(_)=>refreshRoom());
  }

  Future<void> refreshRoom() async {
    final id=room?['id']?.toString();
    if(id==null||id.isEmpty)return;
    try{
      final r=await context.read<ApiClient>().getJson('/games/ludo/rooms/'+id);
      if(mounted)setState(()=>room=Map<String,dynamic>.from(r));
    }catch(_){}
  }

  Future<void> create({bool quick=false}) async {
    setState((){busy=true;error=null;});
    try{
      final api=context.read<ApiClient>();
      final r=quick
        ? await api.postJson('/games/ludo/match',{'maxPlayers':maxPlayers})
        : await api.postJson('/games/ludo/rooms',{'maxPlayers':maxPlayers});
      if(!mounted)return;
      setState(()=>room=Map<String,dynamic>.from(r));
      startPoll();
    }catch(_){if(mounted)setState(()=>error='تعذر فتح غرفة Ludo.');}
    finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> join() async {
    final code=codeController.text.trim().toUpperCase();
    if(code.length<4){setState(()=>error='اكتب كود الغرفة.');return;}
    setState((){busy=true;error=null;});
    try{
      final r=await context.read<ApiClient>().postJson('/games/ludo/rooms/'+code+'/join',{'code':code});
      if(!mounted)return;
      setState(()=>room=Map<String,dynamic>.from(r));
      startPoll();
    }catch(_){if(mounted)setState(()=>error='الكود غير صحيح أو الغرفة ممتلئة.');}
    finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> action(String name,[Map<String,dynamic> body=const <String,dynamic>{}]) async {
    final id=room?['id']?.toString();
    if(id==null)return;
    try{
      final r=await context.read<ApiClient>().postJson('/games/ludo/rooms/'+id+'/'+name,body);
      if(mounted)setState(()=>room=Map<String,dynamic>.from(r));
    }catch(_){if(mounted)setState(()=>error='استنى شوية أو جرّب تاني.');}
  }

  List<List<int>> get pawns {
    final st=room?['state'];
    final raw=st is Map?st['pawns']:null;
    return List.generate(4,(s)=>List.generate(4,(p){
      if(raw is List && s<raw.length && raw[s] is List && p<(raw[s] as List).length){
        final v=(raw[s] as List)[p];
        return v is num?v.toInt():int.tryParse(v.toString())??-1;
      }
      return -1;
    }));
  }

  int get turnSeat=>int.tryParse((room?['turnSeat']??0).toString())??0;
  int get dice=>int.tryParse((room?['dice']??0).toString())??0;
  List<Map<String,dynamic>> get players=>(room?['players'] as List?)?.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList()??[];
  int mySeat(){
    final me=context.read<AuthService>().userId;
    for(final p in players){
      if(me!=null&&me==p['userId']?.toString())return int.tryParse((p['seat']??0).toString())??0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context){
    final status=(room?['status']??'idle').toString();
    final playing=status=='playing'||status=='finished';
    return Scaffold(
      backgroundColor:NexoColors.background,
      appBar:AppBar(
        title:const Text('NEXO Ludo',style:TextStyle(fontWeight:FontWeight.w900)),
        centerTitle:true,
      ),
      body:SafeArea(child:room==null?_lobby():playing?_game():_room()),
    );
  }

  Widget _lobby(){
    return ListView(
      padding:const EdgeInsets.all(16),
      children:[
        Container(
          padding:const EdgeInsets.all(20),
          decoration:BoxDecoration(
            gradient:const LinearGradient(colors:[Color(0xFF2A1F59),Color(0xFF123047)]),
            borderRadius:BorderRadius.circular(24),
          ),
          child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('🎲 NEXO Ludo',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.w900)),
            SizedBox(height:6),
            Text('لعب سريع أو Room خاصة من 2 لـ4 لاعبين.',style:TextStyle(color:NexoColors.textSecondary,fontSize:12)),
          ]),
        ),
        const SizedBox(height:18),
        const Text('عدد اللاعبين',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),
        const SizedBox(height:8),
        SegmentedButton<int>(
          segments:[
            ButtonSegment(value:2,label:Text('2')),
            ButtonSegment(value:3,label:Text('3')),
            ButtonSegment(value:4,label:Text('4')),
          ],
          selected:{maxPlayers},
          onSelectionChanged:busy?null:(s)=>setState(()=>maxPlayers=s.first),
        ),
        const SizedBox(height:16),
        _bigButton('⚡ Quick Match','ادخل أقرب لعبة متاحة.',NexoColors.primary,()=>create(quick:true)),
        const SizedBox(height:10),
        _bigButton('➕ Create Room','اعمل غرفة وابعث الكود.',Colors.purpleAccent,()=>create()),
        const SizedBox(height:18),
        const Text('Join by Code',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),
        const SizedBox(height:8),
        Row(children:[
          Expanded(child:TextField(
            controller:codeController,
            textCapitalization:TextCapitalization.characters,
            style:const TextStyle(color:Colors.white,letterSpacing:2,fontWeight:FontWeight.w800),
            decoration:const InputDecoration(
              hintText:'ABC123',
              filled:true,
              fillColor:NexoColors.card,
              border:OutlineInputBorder(borderSide:BorderSide.none,borderRadius:BorderRadius.all(Radius.circular(14))),
            ),
          )),
          const SizedBox(width:8),
          FilledButton(onPressed:busy?null:join,child:const Text('Join')),
        ]),
        if(error!=null)_error(error!),
        if(busy)const Padding(padding:EdgeInsets.all(14),child:Center(child:CircularProgressIndicator())),
      ],
    );
  }

  Widget _bigButton(String title,String sub,Color color,VoidCallback tap)=>InkWell(
    onTap:busy?null:tap,
    borderRadius:BorderRadius.circular(18),
    child:Ink(
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(18),border:Border.all(color:color.withOpacity(.25))),
      child:Row(children:[
        CircleAvatar(radius:25,backgroundColor:color.withOpacity(.13),child:Text(title.substring(0,2),style:TextStyle(color:color,fontWeight:FontWeight.bold))),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(title.substring(2),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),
          const SizedBox(height:4),
          Text(sub,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)),
        ])),
        const Icon(Icons.chevron_left_rounded,color:Colors.white38),
      ]),
    ),
  );

  Widget _room(){
    final ps=players;
    final max=(room?['maxPlayers'] is num)?(room!['maxPlayers'] as num).toInt():maxPlayers;
    final allReady=ps.length>=2&&ps.every((p)=>p['ready']==true);
    return ListView(
      padding:const EdgeInsets.all(16),
      children:[
        Container(
          padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(22)),
          child:Column(children:[
            const Text('Room Code',style:TextStyle(color:NexoColors.textSecondary)),
            const SizedBox(height:4),
            Row(mainAxisAlignment:MainAxisAlignment.center,children:[
              SelectableText((room?['inviteCode']??'').toString(),style:const TextStyle(color:NexoColors.primary,fontSize:30,fontWeight:FontWeight.w900,letterSpacing:5)),
              IconButton(
                onPressed:()=>Clipboard.setData(ClipboardData(text:(room?['inviteCode']??'').toString())),
                icon:const Icon(Icons.copy_rounded,color:Colors.white54),
              ),
            ]),
            Text(ps.length.toString()+'/'+max.toString()+' لاعبين',style:const TextStyle(color:Colors.white38,fontSize:11)),
          ]),
        ),
        const SizedBox(height:14),
        ...List.generate(max,(i){
          final p=i<ps.length?ps[i]:null;
          final ready=p!=null&&p['ready']==true;
          final name=p==null?'Waiting for player':(p['displayName']??p['username']??'Player').toString();
          return Container(
            margin:const EdgeInsets.only(bottom:9),
            padding:const EdgeInsets.all(12),
            decoration:BoxDecoration(color:NexoColors.surface,borderRadius:BorderRadius.circular(15)),
            child:Row(children:[
              CircleAvatar(child:Text((i+1).toString())),
              const SizedBox(width:10),
              Expanded(child:Text(name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800))),
              Text(p==null?'':(ready?'READY':'Not ready'),style:TextStyle(color:ready?NexoColors.success:Colors.white38,fontSize:10)),
            ]),
          );
        }),
        const SizedBox(height:8),
        Row(children:[
          Expanded(child:OutlinedButton(onPressed:busy?null:()=>action('ready',{'ready':true}),child:const Text('Ready'))),
          const SizedBox(width:8),
          Expanded(child:FilledButton(onPressed:busy||!allReady?null:()=>action('start'),child:const Text('Start'))),
        ]),
        if(error!=null)_error(error!),
      ],
    );
  }

  Widget _game(){
    final my=mySeat();
    final mineTurn=my==turnSeat;
    final finished=room?['status']=='finished';
    return ListView(
      padding:const EdgeInsets.all(10),
      children:[
        Container(
          padding:const EdgeInsets.all(10),
          decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(15)),
          child:Row(children:[
            Expanded(child:Text(finished?'🏆 انتهت المباراة':'دور Seat '+(turnSeat+1).toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))),
            Text('🎲 '+dice.toString(),style:const TextStyle(color:NexoColors.primary,fontSize:18,fontWeight:FontWeight.w900)),
          ]),
        ),
        const SizedBox(height:10),
        AspectRatio(
          aspectRatio:1,
          child:ClipRRect(
            borderRadius:BorderRadius.circular(18),
            child:Stack(fit:StackFit.expand,children:[
              CustomPaint(painter:BoardPainter(trackCalculationListener:(t){tracks=t;})),
              CustomPaint(painter:_PawnPainter(tracks:tracks,pawns:pawns)),
            ]),
          ),
        ),
        const SizedBox(height:10),
        Wrap(
          alignment:WrapAlignment.center,
          spacing:7,
          children:List.generate(4,(i){
            final pos=pawns[my][i];
            return OutlinedButton(
              onPressed:busy||finished||!mineTurn||dice==0?null:()=>action('move',{'pawnIndex':i}),
              child:Text('♟ '+(i+1).toString()+' • '+(pos<0?'Home':pos.toString())),
            );
          }),
        ),
        const SizedBox(height:8),
        Center(child:FilledButton.icon(
          onPressed:busy||finished||!mineTurn||dice!=0?null:()=>action('roll'),
          icon:const Icon(Icons.casino_rounded),
          label:Text(dice==0?'ROLL DICE':'MOVE PAWN'),
        )),
        const SizedBox(height:10),
        SizedBox(
          height:68,
          child:ListView.separated(
            scrollDirection:Axis.horizontal,
            itemCount:players.length,
            separatorBuilder:(_,__)=>const SizedBox(width:7),
            itemBuilder:(_,i){
              final p=players[i];
              return Container(
                width:112,
                padding:const EdgeInsets.all(9),
                decoration:BoxDecoration(
                  color:(int.tryParse((p['seat']??i).toString())??i)==turnSeat?const Color(0x223BD9FF):NexoColors.card,
                  borderRadius:BorderRadius.circular(13),
                ),
                child:Text(
                  ((int.tryParse((p['seat']??i).toString())??i)+1).toString()+'. '+(p['displayName']??p['username']??'Player').toString(),
                  maxLines:1,
                  overflow:TextOverflow.ellipsis,
                  style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700),
                ),
              );
            },
          ),
        ),
        if(error!=null)_error(error!),
      ],
    );
  }

  Widget _error(String s)=>Container(
    margin:const EdgeInsets.only(top:12),
    padding:const EdgeInsets.all(10),
    decoration:BoxDecoration(color:const Color(0x22FF5370),borderRadius:BorderRadius.circular(10)),
    child:Text(s,style:const TextStyle(color:Colors.white70,fontSize:11)),
  );
}

class _PawnPainter extends CustomPainter{
  final List<List<List<Rect>>>? tracks;
  final List<List<int>> pawns;
  _PawnPainter({required this.tracks,required this.pawns});
  @override
  void paint(Canvas c,Size size){
    final t=tracks;
    if(t==null)return;
    const colors=[Color(0xFFE53935),Color(0xFF2EBD69),Color(0xFFF3C623),Color(0xFF3487E8)];
    for(var s=0;s<4;s++){
      for(var p=0;p<4;p++){
        final pos=pawns[s][p];
        final idx=pos<0?0:pos;
        if(idx>=t[s][p].length)continue;
        final center=t[s][p][idx].center+Offset((p%2==0?-1:1)*5,(p<2?-1:1)*5);
        c.drawCircle(center+const Offset(0,2),11,Paint()..color=Colors.black54);
        c.drawCircle(center,10,Paint()..color=colors[s]);
        c.drawCircle(center,10,Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=Colors.white);
      }
    }
  }
  @override bool shouldRepaint(covariant _PawnPainter old)=>true;
}
