
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chess_on_dart/chess_on_dart.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/nexo_theme.dart';

class NexoChessOnlineScreen extends StatefulWidget {
  const NexoChessOnlineScreen({super.key});
  @override
  State<NexoChessOnlineScreen> createState() => _NexoChessOnlineScreenState();
}

class _NexoChessOnlineScreenState extends State<NexoChessOnlineScreen> {
  static const initialFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  Timer? _poller;
  final codeController = TextEditingController();
  Map<String, dynamic>? room;
  bool busy = false;
  String? error;
  String? selectedSquare;
  Game? game;

  @override
  void dispose() {
    _poller?.cancel();
    codeController.dispose();
    super.dispose();
  }

  void _startPoll() {
    _poller?.cancel();
    _poller = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRoom(),
    );
  }

  Future<void> _refreshRoom() async {
    final id = room?['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      final r = await context.read<ApiClient>().getJson('/games/chess/rooms/\$id');
      if (!mounted) return;
      setState(() {
        room = Map<String, dynamic>.from(r);
        _syncGame();
      });
    } catch (_) {}
  }

  void _syncGame() {
    final fen = (room?['fen'] ?? initialFen).toString();
    try {
      final next = Game();
      next.loadFEN(fen);
      game = next;
    } catch (_) {
      game = Game();
    }
  }

  Future<void> _create({bool quick = false}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final r = quick
          ? await api.postJson('/games/chess/match', {})
          : await api.postJson('/games/chess/rooms', {});
      if (!mounted) return;
      setState(() {
        room = Map<String, dynamic>.from(r);
        _syncGame();
      });
      _startPoll();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'تعذر فتح غرفة الشطرنج.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _join() async {
    final code = codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => error = 'اكتب كود الغرفة.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await context
          .read<ApiClient>()
          .postJson('/games/chess/rooms/\$code/join', {'code': code});
      if (!mounted) return;
      setState(() {
        room = Map<String, dynamic>.from(r);
        _syncGame();
      });
      _startPoll();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'الكود غير صحيح أو الغرفة ممتلئة.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _action(
    String name, [
    Map<String, dynamic> body = const <String, dynamic>{},
  ]) async {
    final id = room?['id']?.toString();
    if (id == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await context
          .read<ApiClient>()
          .postJson('/games/chess/rooms/\$id/\$name', body);
      if (!mounted) return;
      setState(() {
        room = Map<String, dynamic>.from(r);
        selectedSquare = null;
        _syncGame();
      });
    } catch (_) {
      if (mounted) setState(() => error = 'الحركة أو العملية لم تُقبل.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<Map<String, dynamic>> get players =>
      (room?['players'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      [];

  String get myColor {
    final me = context.read<AuthService>().userId;
    for (final p in players) {
      if (me != null && me == p['userId']?.toString()) {
        return (p['color'] ?? 'white').toString();
      }
    }
    return 'white';
  }

  String get turnColor => (room?['turnColor'] ?? 'white').toString();
  bool get isMyTurn => myColor == turnColor;
  bool get isWhite => myColor != 'black';

  List<String> get _board {
    final fen = (room?['fen'] ?? initialFen).toString();
    final boardPart = fen.split(' ').first;
    final out = <String>[];
    for (final ch in boardPart.split('')) {
      final code = ch.codeUnitAt(0);
      if (code >= 49 && code <= 56) {
        out.addAll(List.filled(code - 48, ''));
      } else if (RegExp(r'[prnbqkPRNBQK]').hasMatch(ch)) {
        out.add(ch);
      }
    }
    while (out.length < 64) out.add('');
    return out.take(64).toList();
  }

  String _pieceForDisplay(String p) {
    const symbols = {
      'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘', 'P': '♙',
      'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
    };
    return symbols[p] ?? '';
  }

  String _squareAt(int visualIndex) {
    final row = visualIndex ~/ 8;
    final col = visualIndex % 8;
    final actualRow = isWhite ? row : 7 - row;
    final actualCol = isWhite ? col : 7 - col;
    final file = String.fromCharCode(97 + actualCol);
    final rank = (8 - actualRow).toString();
    return '\$file\$rank';
  }

  String _pieceAt(String square) {
    final file = square.codeUnitAt(0) - 97;
    final rank = int.parse(square[1]);
    final index = (8 - rank) * 8 + file;
    final b = _board;
    return (index >= 0 && index < b.length) ? b[index] : '';
  }

  bool _isOwnPiece(String piece) =>
      piece.isNotEmpty &&
      (myColor == 'white'
          ? piece == piece.toUpperCase()
          : piece == piece.toLowerCase());

  List<Move> _movesFrom(String from) {
    final g = game;
    if (g == null) return [];
    return g.legalMoves.where((m) => m.uci().substring(0, 2) == from).toList();
  }

  Future<void> _tapSquare(String square) async {
    if (busy ||
        room?['status']?.toString() != 'playing' ||
        !isMyTurn ||
        game == null) {
      return;
    }

    final piece = _pieceAt(square);
    if (selectedSquare == null) {
      if (_isOwnPiece(piece)) {
        setState(() => selectedSquare = square);
      }
      return;
    }

    if (selectedSquare == square) {
      setState(() => selectedSquare = null);
      return;
    }

    final candidates = _movesFrom(selectedSquare!);
    final matching = candidates
        .where((m) => m.uci().substring(2, 4) == square)
        .toList();

    if (matching.isEmpty) {
      if (_isOwnPiece(piece)) {
        setState(() => selectedSquare = square);
      } else {
        setState(() => selectedSquare = null);
      }
      return;
    }

    var move = matching.first;
    if (matching.length > 1) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: NexoColors.card,
          title: const Text('اختار الترقية'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _promotionButton(context, 'q', '♕'),
              _promotionButton(context, 'r', '♖'),
              _promotionButton(context, 'b', '♗'),
              _promotionButton(context, 'n', '♘'),
            ],
          ),
        ),
      );
      if (!mounted || choice == null) return;
      move = matching.firstWhere(
        (m) => m.uci().endsWith(choice),
        orElse: () => matching.first,
      );
    }

    setState(() => selectedSquare = null);
    await _action('move', {'uci': move.uci()});
  }

  Widget _promotionButton(BuildContext context, String value, String icon) {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context, value),
      child: Text(icon, style: const TextStyle(fontSize: 28)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (room?['status'] ?? 'idle').toString();
    final playing = status == 'playing' || status == 'finished';
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(
        title: const Text('NEXO Chess', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: room == null ? _lobby() : playing ? _game() : _room(),
      ),
    );
  }

  Widget _lobby() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1F255A), Color(0xFF10384A)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('♟ NEXO Chess', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('شطرنج أونلاين بسيط: Room خاصة أو Quick Match.', style: TextStyle(color: NexoColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _bigButton('⚡ Quick Match', 'ادخل أقرب مباراة متاحة.', NexoColors.primary, () => _create(quick: true)),
        const SizedBox(height: 10),
        _bigButton('➕ Create Room', 'اعمل غرفة وابعث الكود لصاحبك.', Colors.purpleAccent, _create),
        const SizedBox(height: 18),
        const Text('Join by Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  hintText: 'ABC123',
                  filled: true,
                  fillColor: NexoColors.card,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: busy ? null : _join, child: const Text('Join')),
          ],
        ),
        if (error != null) _error(error!),
        if (busy) const Padding(padding: EdgeInsets.all(14), child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _bigButton(String title, String sub, Color color, VoidCallback tap) {
    return InkWell(
      onTap: busy ? null : tap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NexoColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(.25)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(.13),
              child: Text(title.substring(0, 2), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.substring(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(sub, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _room() {
    final ps = players;
    final allReady = ps.length == 2 && ps.every((p) => p['ready'] == true);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(22)),
          child: Column(
            children: [
              const Text('Room Code', style: TextStyle(color: NexoColors.textSecondary)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    (room?['inviteCode'] ?? '').toString(),
                    style: const TextStyle(color: NexoColors.primary, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 5),
                  ),
                  IconButton(
                    onPressed: () => Clipboard.setData(ClipboardData(text: (room?['inviteCode'] ?? '').toString())),
                    icon: const Icon(Icons.copy_rounded, color: Colors.white54),
                  ),
                ],
              ),
              Text('\${ps.length}/2 لاعبين', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(2, (i) {
          final p = i < ps.length ? ps[i] : null;
          final ready = p != null && p['ready'] == true;
          final name = p == null ? 'Waiting for player' : (p['displayName'] ?? p['username'] ?? 'Player').toString();
          final color = (p?['color'] ?? (i == 0 ? 'white' : 'black')).toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: NexoColors.surface, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                CircleAvatar(child: Text(color == 'white' ? 'W' : 'B')),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                Text(
                  ready ? 'READY' : 'Not ready',
                  style: TextStyle(color: ready ? NexoColors.success : Colors.white38, fontSize: 10),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : () => _action('ready', {'ready': true}),
                child: const Text('Ready'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: busy || !allReady ? null : () => _action('start'),
                child: const Text('Start'),
              ),
            ),
          ],
        ),
        if (error != null) _error(error!),
      ],
    );
  }

  Widget _game() {
    final finished = room?['status'] == 'finished';
    final check = game?.isCheck ?? false;
    final over = game?.isCheckmate ?? false;
    final turnText = finished
        ? (room?['winnerUserId'] != null ? '🏆 انتهت المباراة' : 'تعادل')
        : isMyTurn ? 'دورك' : 'دور الخصم';

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '\$turnText • \${turnColor == 'white' ? 'الأبيض' : 'الأسود'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
              if (check && !finished)
                const Text('CHECK', style: TextStyle(color: Color(0xFFFF7B7B), fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 64,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
            itemBuilder: (context, visualIndex) {
              final square = _squareAt(visualIndex);
              final piece = _pieceAt(square);
              final row = visualIndex ~/ 8;
              final col = visualIndex % 8;
              final dark = (row + col).isOdd;
              final selected = square == selectedSquare;
              final legal = selectedSquare != null &&
                  _movesFrom(selectedSquare!).any((m) => m.uci().substring(2, 4) == square);
              return GestureDetector(
                onTap: () => _tapSquare(square),
                child: Container(
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF58708A) : const Color(0xFFD7E4EA),
                    border: selected ? Border.all(color: NexoColors.primary, width: 3) : null,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Text(
                          _pieceForDisplay(piece),
                          style: TextStyle(
                            fontSize: 31,
                            shadows: [
                              Shadow(
                                blurRadius: 2,
                                color: piece.isNotEmpty && piece == piece.toUpperCase()
                                    ? Colors.black54
                                    : Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (legal)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: piece.isEmpty ? 12 : 32,
                            height: piece.isEmpty ? 12 : 32,
                            decoration: BoxDecoration(
                              color: NexoColors.primary.withOpacity(.35),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _playerBadge(players.isNotEmpty ? players[0] : null, 'white')),
            const SizedBox(width: 8),
            Expanded(child: _playerBadge(players.length > 1 ? players[1] : null, 'black')),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          over ? 'Checkmate' : (finished ? 'المباراة انتهت' : 'اضغط على قطعة ثم المربع الهدف'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11),
        ),
        if (error != null) _error(error!),
      ],
    );
  }

  Widget _playerBadge(Map<String, dynamic>? p, String color) {
    final name = p == null ? 'Waiting' : (p['displayName'] ?? p['username'] ?? 'Player').toString();
    final active = turnColor == color;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? const Color(0x223BD9FF) : NexoColors.card,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 16, child: Text(color == 'white' ? 'W' : 'B')),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(String s) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0x22FF5370), borderRadius: BorderRadius.circular(10)),
        child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      );
}
