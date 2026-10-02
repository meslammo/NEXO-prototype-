
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/nexo_theme.dart';

class NexoDominoLocalScreen extends StatefulWidget {
  const NexoDominoLocalScreen({super.key});
  @override
  State<NexoDominoLocalScreen> createState() => _NexoDominoLocalScreenState();
}

class _NexoDominoLocalScreenState extends State<NexoDominoLocalScreen> {
  final random = Random();
  List<List<int>> handA = [], handB = [], board = [], bone = [];
  int turn = 0, passes = 0;
  int? left, right, winner;
  bool finished = false;

  @override
  void initState() { super.initState(); reset(); }

  void reset() {
    final d = <List<int>>[];
    for (var a=0;a<=6;a++) for (var b=a;b<=6;b++) d.add([a,b]);
    d.shuffle(random);
    setStateIfMounted(() {
      handA = d.take(7).map((x)=>List<int>.from(x)).toList();
      handB = d.skip(7).take(7).map((x)=>List<int>.from(x)).toList();
      bone = d.skip(14).map((x)=>List<int>.from(x)).toList();
      board = []; left = null; right = null; turn = 0; passes = 0; winner = null; finished = false;
    });
  }

  void setStateIfMounted(VoidCallback fn) { if (mounted) setState(fn); else fn(); }

  List<List<int>> get hand => turn == 0 ? handA : handB;
  bool playable(List<int> t) => left == null || t.contains(left) || t.contains(right);

  List<int>? orient(List<int> t, String side) {
    final end = side == 'left' ? left : right;
    if (end == null) return List<int>.from(t);
    if (t[0] == end) return side == 'left' ? [t[1], t[0]] : [t[0], t[1]];
    if (t[1] == end) return side == 'left' ? [t[0], t[1]] : [t[1], t[0]];
    return null;
  }

  void next() { turn = 1 - turn; passes = 0; }

  void draw() {
    if (finished || bone.isEmpty) return;
    hand.add(bone.removeAt(0));
    setState(() {});
  }

  void pass() {
    if (finished || bone.isNotEmpty || hand.any(playable)) return;
    passes++;
    if (passes >= 2) {
      final sa=handA.fold(0,(s,t)=>s+t[0]+t[1]), sb=handB.fold(0,(s,t)=>s+t[0]+t[1]);
      winner = sa < sb ? 0 : (sb < sa ? 1 : null);
      finished = true;
    } else {
      next();
    }
    setState(() {});
  }

  Future<void> playTile(int i) async {
    if (finished || i < 0 || i >= hand.length) return;
    final tile = hand[i];
    if (!playable(tile)) return;
    var side = 'right';
    if (board.isNotEmpty && tile.contains(left) && tile.contains(right) && left != right) {
      final s = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: NexoColors.card,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Expanded(child: FilledButton(onPressed: ()=>Navigator.pop(context,'left'), child: const Text('الشمال'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: ()=>Navigator.pop(context,'right'), child: const Text('اليمين'))),
            ]),
          ),
        ),
      );
      if (s == null) return;
      side = s;
    } else if (board.isNotEmpty && !tile.contains(right) && tile.contains(left)) {
      side = 'left';
    }

    final placed = orient(tile, side);
    if (placed == null) return;
    hand.removeAt(i);
    if (board.isEmpty) { board.add(placed); left=placed[0]; right=placed[1]; }
    else if (side=='left') { board.insert(0, placed); left=placed[0]; }
    else { board.add(placed); right=placed[1]; }
    passes = 0;
    if (hand.isEmpty) { winner=turn; finished=true; }
    else next();
    setState(() {});
  }

  Widget tile(List<int> t) => Container(
    width: 62, height: 44,
    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(blurRadius:3,color:Colors.black26)]),
    child: Row(children: [
      Expanded(child: Center(child: Text(t[0].toString(),style:const TextStyle(color:Colors.black,fontSize:18,fontWeight:FontWeight.bold)))),
      Container(width:1,color:Colors.black26),
      Expanded(child: Center(child: Text(t[1].toString(),style:const TextStyle(color:Colors.black,fontSize:18,fontWeight:FontWeight.bold)))),
    ]),
  );

  Widget handView(List<List<int>> h, int owner) => Wrap(
    alignment: WrapAlignment.center,
    children: [for (var i=0;i<h.length;i++) GestureDetector(onTap: owner==turn&&!finished ? ()=>playTile(i) : null, child: tile(h[i]))],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071522),
    appBar: AppBar(
      title: const Text('NEXO Domino',style:TextStyle(fontWeight:FontWeight.w900)),
      centerTitle:true,
      actions:[IconButton(onPressed:reset,icon:const Icon(Icons.refresh_rounded))],
    ),
    body: ListView(padding:const EdgeInsets.all(12),children:[
      Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(16)),child:Row(children:[
        Expanded(child:Text(finished?(winner==null?'تعادل':'🏆 اللاعب ' + (winner==0?'1':'2') + ' فاز'): 'دور اللاعب ' + (turn+1).toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))),
        Text('المخزون ' + bone.length.toString(),style:const TextStyle(color:NexoColors.textSecondary,fontSize:11)),
      ])),
      const SizedBox(height:10),
      Container(padding:const EdgeInsets.all(8),constraints:const BoxConstraints(minHeight:100),decoration:BoxDecoration(color:const Color(0xFF0E2637),borderRadius:BorderRadius.circular(16)),child:Wrap(alignment:WrapAlignment.center,children:[for(final t in board) tile(t)])),
      const SizedBox(height:8),
      Text('لاعب 2 • ' + handB.length.toString() + ' حجر',textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:11)),
      const SizedBox(height:6),
      handView(handB,1),
      const SizedBox(height:10),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        FilledButton.icon(onPressed:!finished&&turn==0&&bone.isNotEmpty?draw:null,icon:const Icon(Icons.add),label:const Text('سحب')),
        const SizedBox(width:8),
        OutlinedButton(onPressed:!finished&&turn==0?pass:null,child:const Text('Pass')),
      ]),
      const Divider(color:Colors.white12,height:24),
      Text('لاعب 1 • ' + handA.length.toString() + ' حجر',textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:11)),
      const SizedBox(height:6),
      handView(handA,0),
      const SizedBox(height:18),
      if (!finished) Center(child: const Text('اللاعب الحالي هو الوحيد الذي يقدر يلعب',style:TextStyle(color:NexoColors.textSecondary,fontSize:10))),
      if (finished) Center(child: FilledButton(onPressed:reset,child:const Text('مباراة جديدة'))),
    ]),
  );
}
