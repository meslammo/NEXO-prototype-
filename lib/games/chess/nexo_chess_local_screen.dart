
import 'package:flutter/material.dart';
import 'package:chess_on_dart/chess_on_dart.dart';
import '../../theme/nexo_theme.dart';

class NexoChessLocalScreen extends StatefulWidget {
  const NexoChessLocalScreen({super.key});
  @override
  State<NexoChessLocalScreen> createState() => _NexoChessLocalScreenState();
}

class _NexoChessLocalScreenState extends State<NexoChessLocalScreen> {
  static const initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  final Game game = Game();
  String? selected;
  bool whiteBottom = true;

  String get turn => game.toFEN().split(' ').elementAt(1) == 'b' ? 'black' : 'white';

  List<String> get board {
    final part = game.toFEN().split(' ').first;
    final out = <String>[];
    for (final ch in part.split('')) {
      final n = int.tryParse(ch);
      if (n != null) out.addAll(List<String>.filled(n, ''));
      else if (RegExp(r'[prnbqkPRNBQK]').hasMatch(ch)) out.add(ch);
    }
    while (out.length < 64) out.add('');
    return out.take(64).toList();
  }

  String squareAt(int visual) {
    final row = visual ~/ 8, col = visual % 8;
    final r = whiteBottom ? row : 7 - row;
    final c = whiteBottom ? col : 7 - col;
    return String.fromCharCode(97 + c) + (8 - r).toString();
  }

  bool own(String p) => p.isNotEmpty && (turn == 'white' ? p == p.toUpperCase() : p == p.toLowerCase());

  List<Move> movesFrom(String from) => game.legalMoves.where((m) => m.uci().substring(0, 2) == from).toList();

  Future<void> tap(String sq) async {
    if (game.isFinished) return;
    final pieces = board;
    final file = sq.codeUnitAt(0) - 97;
    final rank = int.parse(sq[1]);
    final index = (8 - rank) * 8 + file;
    final p = pieces[index];

    if (selected == null) {
      if (own(p)) setState(() => selected = sq);
      return;
    }
    if (sq == selected) { setState(() => selected = null); return; }

    final candidates = movesFrom(selected!);
    final matching = candidates.where((m) => m.uci().substring(2, 4) == sq).toList();
    if (matching.isEmpty) {
      if (own(p)) setState(() => selected = sq); else setState(() => selected = null);
      return;
    }

    var m = matching.first;
    if (matching.length > 1) {
      final choice = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: NexoColors.card,
          title: const Text('اختار الترقية'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final x in const [('q','♕'),('r','♖'),('b','♗'),('n','♘')])
                OutlinedButton(onPressed: () => Navigator.pop(context, x.$1), child: Text(x.$2, style: const TextStyle(fontSize: 28))),
            ],
          ),
        ),
      );
      if (choice == null) return;
      m = matching.firstWhere((x) => x.uci().endsWith(choice), orElse: () => matching.first);
    }

    setState(() {
      selected = null;
      game.tryMove(m);
    });
  }

  String glyph(String p) => const {
    'K':'♔','Q':'♕','R':'♖','B':'♗','N':'♘','P':'♙',
    'k':'♚','q':'♛','r':'♜','b':'♝','n':'♞','p':'♟',
  }[p] ?? '';

  @override
  Widget build(BuildContext context) {
    final b = board;
    final check = game.isCheck;
    final finished = game.isFinished;
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(
        title: const Text('NEXO Chess', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () => setState(() { game.loadFEN(initialFen); selected = null; }), icon: const Icon(Icons.refresh_rounded)),
          IconButton(onPressed: () => setState(() => whiteBottom = !whiteBottom), icon: const Icon(Icons.flip_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              Expanded(child: Text(finished ? '🏁 انتهت المباراة' : 'دور ' + (turn == 'white' ? 'الأبيض' : 'الأسود'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              if (check && !finished) const Text('CHECK', style: TextStyle(color: Color(0xFFFF7B7B), fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 64,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
              itemBuilder: (_, i) {
                final sq = squareAt(i);
                final p = b[(8 - int.parse(sq[1])) * 8 + sq.codeUnitAt(0) - 97];
                final selectedHere = selected == sq;
                final legal = selected != null && movesFrom(selected!).any((m) => m.uci().substring(2,4) == sq);
                final row = i ~/ 8, col = i % 8;
                return GestureDetector(
                  onTap: () => tap(sq),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (row + col).isOdd ? const Color(0xFF58708A) : const Color(0xFFD7E4EA),
                      border: selectedHere ? Border.all(color: NexoColors.primary, width: 3) : null,
                    ),
                    child: Stack(children: [
                      Center(child: Text(glyph(p), style: const TextStyle(fontSize: 31))),
                      if (legal) Center(child: Container(width: p.isEmpty ? 12 : 30, height: p.isEmpty ? 12 : 30, decoration: BoxDecoration(color: NexoColors.primary.withOpacity(.32), shape: BoxShape.circle))),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            finished ? (game.isCheckmate ? 'كش مات' : 'تعادل') : 'وضع لاعبين على نفس الجهاز • تحريك قانوني كامل',
            textAlign: TextAlign.center,
            style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
