import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';

class NexoDominoOnlineScreen extends StatefulWidget {
  const NexoDominoOnlineScreen({super.key});
  @override
  State<NexoDominoOnlineScreen> createState() => _NexoDominoOnlineScreenState();
}

class _NexoDominoOnlineScreenState extends State<NexoDominoOnlineScreen> {
  Map<String,dynamic>? room;
  Timer? pollTimer;
  bool busy=false;
  final codeController=TextEditingController();

  String get myId => context.read<AuthService>().userId ?? '';

  @override
  void dispose() {
    pollTimer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  Future<void> poll() async {
    if (room == null) return;
    try {
      final r=await context.read<ApiClient>().getJson('/games/domino/rooms/'+room!['id'].toString());
      if (mounted) setState(() => room=r);
    } catch (_) {}
  }

  void beginPolling() {
    pollTimer?.cancel();
    pollTimer=Timer.periodic(const Duration(seconds:1), (_) => poll());
  }

  String err(Object e) {
    final s=e.toString();
    if (s.contains('DOMINO_ROOM_FULL')) return 'الغرفة ممتلئة';
    if (s.contains('DOMINO_NOT_YOUR_TURN')) return 'الدور مش بتاعك';
    if (s.contains('DOMINO_TILE_NOT_OWNED')) return 'الحجر ده مش موجود في إيدك';
    if (s.contains('DOMINO_TILE_DOES_NOT_MATCH')) return 'الحجر لا يطابق الطرف المختار';
    if (s.contains('DOMINO_DRAW_REQUIRED')) return 'اسحب حجر الأول';
    if (s.contains('DOMINO_BONEYARD_EMPTY')) return 'مفيش أحجار متبقية';
    if (s.contains('DOMINO_PLAYABLE_TILE_EXISTS')) return 'عندك حجر قابل للعب';
    if (s.contains('DOMINO_NEEDS_TWO_READY')) return 'محتاج لاعبين جاهزين';
    if (s.contains('UNAUTHORIZED')) return 'جلسة الدخول انتهت';
    return 'تعذر تنفيذ حركة الدومينو';
  }

  Future<void> act(Future<Map<String,dynamic>> Function() fn) async {
    if (busy) return;
    setState(() => busy=true);
    try {
      final r=await fn();
      if (!mounted) return;
      setState(() => room=r);
      beginPolling();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content:Text(err(e)),backgroundColor:Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => busy=false);
    }
  }

  Future<void> create() => act(() => context.read<ApiClient>().postJson('/games/domino/rooms', {}));
  Future<void> match() => act(() => context.read<ApiClient>().postJson('/games/domino/match', {}));

  Future<void> join() async {
    final code=codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اكتب كود الغرفة')));
      return;
    }
    await act(() => context.read<ApiClient>().postJson('/games/domino/rooms/'+code+'/join', {}));
  }

  Future<void> ready() => act(() => context.read<ApiClient>().postJson('/games/domino/rooms/'+room!['id'].toString()+'/ready', {'ready':true}));

  Future<void> move(Map<String,dynamic> payload) {
    final key=DateTime.now().microsecondsSinceEpoch.toString()+'-'+payload['action'].toString();
    final body={...payload,'moveKey':key};
    return act(() => context.read<ApiClient>().postJson('/games/domino/rooms/'+room!['id'].toString()+'/move', body));
  }

  Future<void> choose(List<int> tile) async {
    final board=(room?['board'] as List?) ?? const [];
    if (board.isEmpty) {
      await move({'action':'play','tile':tile,'side':'right'});
      return;
    }
    if (!mounted) return;
    final side=await showModalBottomSheet<String>(
      context:context,
      backgroundColor:const Color(0xFF132F4C),
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(22))),
      builder:(_) => SafeArea(
        child:Padding(
          padding:const EdgeInsets.all(18),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            const Text('اختار مكان الحجر',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w800)),
            const SizedBox(height:12),
            Row(children:[
              Expanded(child:ElevatedButton(onPressed:()=>Navigator.pop(context,'left'),child:const Text('الشمال'))),
              const SizedBox(width:8),
              Expanded(child:ElevatedButton(onPressed:()=>Navigator.pop(context,'right'),child:const Text('اليمين'))),
            ]),
          ]),
        ),
      ),
    );
    if (side != null) await move({'action':'play','tile':tile,'side':side});
  }

  List<int> asTile(dynamic v) => [(v as List)[0] as int,(v as List)[1] as int];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color(0xFF071522),
      appBar:AppBar(
        backgroundColor:const Color(0xFF071522),
        title:const Text('NEXO Domino',style:TextStyle(fontWeight:FontWeight.w900)),
        centerTitle:true,
      ),
      body:room==null ? lobby() : (room!['status']=='playing' || room!['status']=='finished' ? boardView() : waitingView()),
    );
  }

  Widget lobby() {
    return ListView(
      padding:const EdgeInsets.all(16),
      children:[
        Container(
          padding:const EdgeInsets.all(20),
          decoration:BoxDecoration(
            gradient:const LinearGradient(colors:[Color(0xFF103B55),Color(0xFF1B2552)]),
            borderRadius:BorderRadius.circular(22),
            border:Border.all(color:const Color(0xFF31D6FF).withOpacity(.4)),
          ),
          child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Domino Online',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),
            SizedBox(height:8),
            Text('لعبة دومينو NEXO أصلية — غرف، كود، لعب بين جهازين، ونقاط للمباراة.',style:TextStyle(color:Color(0xFFB8D4DF),height:1.45)),
          ]),
        ),
        const SizedBox(height:15),
        SizedBox(height:52,child:ElevatedButton.icon(onPressed:busy?null:match,icon:const Icon(Icons.bolt_rounded),label:Text(busy?'جارٍ البحث...':'Quick Match'))),
        const SizedBox(height:9),
        SizedBox(height:52,child:OutlinedButton.icon(onPressed:busy?null:create,icon:const Icon(Icons.add_circle_outline),label:const Text('Create Room'))),
        const SizedBox(height:16),
        Container(
          padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(color:const Color(0xFF102839),borderRadius:BorderRadius.circular(18)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            const Text('Join by Code',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
            const SizedBox(height:8),
            TextField(
              controller:codeController,
              textAlign:TextAlign.center,
              textDirection:TextDirection.ltr,
              style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,letterSpacing:2),
              decoration:InputDecoration(hintText:'مثال: 45YMA7',filled:true,fillColor:const Color(0xFF0A1D2C),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)),
            ),
            const SizedBox(height:8),
            SizedBox(height:48,child:ElevatedButton(onPressed:busy?null:join,child:const Text('Join'))),
          ]),
        ),
        const SizedBox(height:12),
        const Text('نسخة الاختبار دي للّعب بالنقاط فقط، بدون مراهنة أو تحويل كاش حقيقي.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xFF7896A1),fontSize:11)),
      ],
    );
  }

  Widget waitingView() {
    final players=(room!['players'] as List?)?.cast<Map>() ?? const <Map>[];
    final mine=players.firstWhere((p)=>p['id'].toString()==myId,orElse:()=>{});
    final readyMine=mine['ready']==true;
    return ListView(
      padding:const EdgeInsets.all(16),
      children:[
        Container(
          padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(color:const Color(0xFF102839),borderRadius:BorderRadius.circular(20)),
          child:Column(children:[
            const Text('غرفة الدومينو',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),
            const SizedBox(height:7),
            SelectableText(room!['inviteCode'].toString(),style:const TextStyle(color:Color(0xFF3FE0FF),fontSize:28,fontWeight:FontWeight.w900,letterSpacing:5)),
            const SizedBox(height:7),
            const Text('ابعت الكود للجهاز التاني',style:TextStyle(color:Color(0xFF95AFBA))),
          ]),
        ),
        const SizedBox(height:12),
        ...players.map((p)=>Container(
          margin:const EdgeInsets.only(bottom:8),
          padding:const EdgeInsets.all(12),
          decoration:BoxDecoration(color:const Color(0xFF0C2030),borderRadius:BorderRadius.circular(15)),
          child:Row(children:[
            const CircleAvatar(radius:19,child:Icon(Icons.person)),
            const SizedBox(width:10),
            Expanded(child:Text(p['displayName'].toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),
            Text(p['ready']==true?'READY':'WAITING',style:TextStyle(color:p['ready']==true?Colors.greenAccent:const Color(0xFF8FA9B5),fontWeight:FontWeight.w800)),
          ]),
        )),
        const SizedBox(height:5),
        SizedBox(height:52,child:ElevatedButton.icon(
          onPressed:busy||readyMine?null:ready,
          icon:Icon(readyMine?Icons.check_circle:Icons.check_circle_outline),
          label:Text(readyMine?'جاهز':'أنا جاهز'),
        )),
      ],
    );
  }

  Widget boardView() {
    final hand=((room!['hand'] as List?) ?? const []).map(asTile).toList();
    final board=((room!['board'] as List?) ?? const []).map(asTile).toList();
    final myTurn=room!['turnUserId']?.toString()==myId;
    final finished=room!['status'].toString()=='finished';
    final winner=room!['winnerUserId']?.toString();
    final scores=(room!['scores'] as Map?)?.map((k,v)=>MapEntry(k.toString(),(v as num?)?.toInt() ?? 0)) ?? {};
    return Column(children:[
      Container(
        margin:const EdgeInsets.fromLTRB(12,10,12,8),
        padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(color:const Color(0xFF102839),borderRadius:BorderRadius.circular(18)),
        child:Row(children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(finished?'انتهت المباراة':myTurn?'دورك الآن':'دور الخصم',style:TextStyle(color:myTurn?const Color(0xFF3FE0FF):Colors.white,fontWeight:FontWeight.w900,fontSize:16)),
            const SizedBox(height:4),
            Text('الخصم معه '+(room!['opponentHandCount'] ?? 0).toString()+' حجر • السحب '+(room!['boneyardCount'] ?? 0).toString(),style:const TextStyle(color:Color(0xFF91ABB7),fontSize:11)),
          ])),
          Text('نقاطك: '+(scores[myId] ?? 0).toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
        ]),
      ),
      Expanded(
        child:Container(
          margin:const EdgeInsets.symmetric(horizontal:12),
          decoration:BoxDecoration(
            gradient:const LinearGradient(colors:[Color(0xFF123D34),Color(0xFF0B2C28)]),
            borderRadius:BorderRadius.circular(22),
            border:Border.all(color:const Color(0xFF2ABAA2).withOpacity(.35)),
          ),
          child:Column(children:[
            const SizedBox(height:12),
            const Text('BOARD',style:TextStyle(color:Color(0xFF9BEBDD),fontSize:10,fontWeight:FontWeight.w900,letterSpacing:2)),
            const SizedBox(height:8),
            Expanded(
              child:board.isEmpty
                ? const Center(child:Text('ابدأ أول حجر',style:TextStyle(color:Color(0xFF7EA59E))))
                : SingleChildScrollView(
                    scrollDirection:Axis.horizontal,
                    padding:const EdgeInsets.all(18),
                    child:Row(children:board.map((t)=>Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:_Tile(value:t,small:true))).toList()),
                  ),
            ),
            if(finished) Container(
              margin:const EdgeInsets.fromLTRB(14,0,14,14),
              padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:const Color(0xAA071522),borderRadius:BorderRadius.circular(14)),
              child:Center(child:Text(winner==null?'تعادل':winner==myId?'أنت الفائز':'الخصم فاز',style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w900))),
            ),
          ]),
        ),
      ),
      Container(
        padding:const EdgeInsets.fromLTRB(12,9,12,12),
        child:Column(children:[
          Align(alignment:Alignment.centerRight,child:Text('إيدك ('+hand.length.toString()+')',style:const TextStyle(color:Color(0xFF9CB3BD),fontWeight:FontWeight.w700))),
          const SizedBox(height:7),
          SizedBox(
            height:66,
            child:ListView.separated(
              scrollDirection:Axis.horizontal,
              itemCount:hand.length,
              separatorBuilder:(_,__)=>const SizedBox(width:7),
              itemBuilder:(_,index)=>GestureDetector(
                onTap:myTurn&&!finished&&!busy?()=>choose(hand[index]):null,
                child:Opacity(opacity:myTurn&&!finished?1:.55,child:_Tile(value:hand[index])),
              ),
            ),
          ),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child:OutlinedButton.icon(onPressed:myTurn&&!finished&&!busy?()=>move({'action':'draw'}):null,icon:const Icon(Icons.download_rounded),label:const Text('سحب'))),
            const SizedBox(width:8),
            Expanded(child:OutlinedButton.icon(onPressed:myTurn&&!finished&&!busy?()=>move({'action':'pass'}):null,icon:const Icon(Icons.skip_next_rounded),label:const Text('Pass'))),
          ]),
        ]),
      ),
    ]);
  }
}

class _Tile extends StatelessWidget {
  final List<int> value;
  final bool small;
  const _Tile({required this.value,this.small=false});

  @override
  Widget build(BuildContext context) {
    final w=small?56.0:66.0;
    final h=small?37.0:48.0;
    return Container(
      width:w,height:h,
      decoration:BoxDecoration(
        color:const Color(0xFFF3F8FA),
        borderRadius:BorderRadius.circular(9),
        boxShadow:[BoxShadow(color:Colors.black.withOpacity(.22),blurRadius:6,offset:const Offset(0,3))],
      ),
      child:Row(children:[
        Expanded(child:Center(child:Text(value[0].toString(),style:TextStyle(color:const Color(0xFF0C2733),fontSize:small?14:17,fontWeight:FontWeight.w900)))),
        Container(width:1,height:h*.72,color:const Color(0xFF98AEB6)),
        Expanded(child:Center(child:Text(value[1].toString(),style:TextStyle(color:const Color(0xFF0C2733),fontSize:small?14:17,fontWeight:FontWeight.w900)))),
      ]),
    );
  }
}
