import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nexo_catalog.dart';
import '../services/economy_service.dart';
import '../services/social_engine.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/webrtc_call_service.dart';
import '../config/api_config.dart';
import '../theme/nexo_theme.dart';
import 'trade_screen.dart';

class _ChatLine {
  final String from;
  final String text;
  final String? giftId;
  _ChatLine(this.from, this.text, {this.giftId});
}

final Map<String, List<_ChatLine>> _chatMessages = {
  'shadoww': [_ChatLine('Shadoww', 'جاهز للشات؟'), _ChatLine('NEXO_KING', 'أيوة، وعايز أجرب الهدايا.'), _ChatLine('Shadoww', 'افتح صندوق الهدايا وجرب واحدة.')],
  'galaxygirl': [_ChatLine('GalaxyGirl', 'الإيموجي ده جامد ✨')],
  'prince': [_ChatLine('Prince_X', 'نبعت Trade؟')],
  'ahmed': [_ChatLine('Ahmed', 'شكراً يا صاحبي!')],
  'mdark': [_ChatLine('M:Dark', 'نقابلك في الروم؟')],
};

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  static const people = [
    _Person('Shadoww', 'shadoww', true, Color(0xFFB44CFF)),
    _Person('GalaxyGirl', 'galaxygirl', true, Color(0xFFFF6B9D)),
    _Person('Prince_X', 'prince', false, Color(0xFFF5C14A)),
    _Person('Ahmed', 'ahmed', false, Color(0xFF3EE08A)),
    _Person('M:Dark', 'mdark', true, Color(0xFF6EB6FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: NexoColors.background,
        actions: [
          Consumer<EconomyService>(
            builder: (_, e, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(child: Text('💎 ' + e.gems.toString(), style: const TextStyle(color: NexoColors.primary, fontWeight: FontWeight.bold))),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث عن مستخدم أو غرفة...',
                hintStyle: const TextStyle(color: NexoColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: NexoColors.textSecondary),
                filled: true,
                fillColor: NexoColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: people.where((p) => p.online).map((p) => GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatThreadScreen(person: p))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(children: [_Avatar(name: p.name, color: p.color, online: true), const SizedBox(height: 4), Text(p.name, style: const TextStyle(color: Colors.white70, fontSize: 11))]),
                ),
              )).toList(),
            ),
          ),
          const Divider(color: NexoColors.cardBorder, height: 1),
          Expanded(
            child: ListView(
              children: people.map((p) {
                final list = _chatMessages[p.id] ?? const <_ChatLine>[];
                final preview = list.isEmpty ? 'بدون رسائل' : (list.last.giftId != null ? '🎁 هدية' : list.last.text);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  leading: _Avatar(name: p.name, color: p.color, online: p.online),
                  title: Text(p.name, style: TextStyle(color: p.color, fontWeight: FontWeight.bold, shadows: [Shadow(color: p.color.withOpacity(.45), blurRadius: 8)])),
                  subtitle: Text(preview, style: const TextStyle(color: NexoColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatThreadScreen(person: p))),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرومات الحية موجودة داخل تدفق Chat Room.'))),
              icon: const Icon(Icons.record_voice_over_rounded),
              label: const Text('Live Rooms'),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatThreadScreen extends StatefulWidget {
  final _Person person;
  const ChatThreadScreen({super.key, required this.person});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _controller = TextEditingController();
  Timer? _callTimer;
  String? _callKind;
  int _callMinutes = 0;
  late final WebRtcCallService _callService;
  StreamSubscription<MediaStream>? _remoteStreamSubscription;
  MediaStream? _remoteStream;

  bool get _remoteMode {
    final auth = context.read<AuthService>();
    return NexoApiConfig.configured && auth.online;
  }

  List<_ChatLine> get _lines => _chatMessages[widget.person.id] ?? const <_ChatLine>[];

  @override
  void initState() {
    super.initState();
    _callService = WebRtcCallService(context.read<RealtimeService>());
    _remoteStreamSubscription = _callService.remoteStreams.listen((stream) {
      if (mounted) setState(() => _remoteStream = stream);
    });
    Future.microtask(() async {
      await _callService.listenForIncoming(widget.person.id);
      await _loadRemoteHistory();
    });
  }

  Future<void> _loadRemoteHistory() async {
    if (!_remoteMode) return;
    try {
      final api = context.read<ApiClient>();
      final response = await api.getJson('/chat/${widget.person.id}/messages');
      final raw = response['data'];
      if (raw is! List || !mounted) return;
      final lines = <_ChatLine>[];
      for (final row in raw) {
        if (row is! Map) continue;
        lines.add(_ChatLine(
          row['sender_username']?.toString() ?? row['sender_id']?.toString() ?? 'User',
          row['body']?.toString() ?? '',
          giftId: row['gift_id']?.toString(),
        ));
      }
      setState(() => _chatMessages[widget.person.id] = lines);
    } catch (_) {}
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _remoteStreamSubscription?.cancel();
    _callService.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    if (_remoteMode) {
      try {
        await context.read<ApiClient>().postJson(
          '/chat/${widget.person.id}/messages',
          {'body': value},
        );
        final me = context.read<AuthService>().user?['username']?.toString() ?? 'NEXO_KING';
        setState(() {
          (_chatMessages[widget.person.id] ??= []).add(_ChatLine(me, value));
          _controller.clear();
        });
        context.read<SocialEngine>().logChatMessage();
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر إرسال الرسالة: $e'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }
    }
    setState(() {
      (_chatMessages[widget.person.id] ??= []).add(_ChatLine('NEXO_KING', value));
      _controller.clear();
    });
    context.read<SocialEngine>().logChatMessage();
  }

  void _showUserInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NexoColors.surface,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _Avatar(name: widget.person.name, color: widget.person.color, online: widget.person.online, radius: 34),
            const SizedBox(height: 10),
            Text(widget.person.name, style: TextStyle(color: widget.person.color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(leading: const Icon(Icons.person_outline, color: NexoColors.primary), title: const Text('معلومات المستخدم'), subtitle: Text(widget.person.online ? 'Online الآن' : 'Offline'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.swap_horiz_rounded, color: NexoColors.primary), title: const Text('Trade'), onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => TradeScreen(peerId: widget.person.id, peerName: widget.person.name)));
            }),
          ]),
        ),
      ),
    );
  }

  Future<void> _openGiftSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NexoColors.surface,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .78,
          minChildSize: .55,
          maxChildSize: .92,
          builder: (_, scroll) => Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scroll,
              children: [
                Row(children: [
                  const Icon(Icons.redeem_rounded, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Gift Box', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close, color: Colors.white70)),
                ]),
                const Text('Catalog → Rarity → Details → Gems / owned → Send → Chat → Inventory → Trade', style: TextStyle(color: NexoColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nexoGifts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .72),
                  itemBuilder: (_, i) {
                    final gift = nexoGifts[i];
                    final owned = context.watch<EconomyService>().inventory[gift.id] ?? 0;
                    return InkWell(
                      onTap: () => _giftDetails(gift, owned, sheetContext),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: gift.rarity.color.withOpacity(.38))),
                        child: Column(children: [
                          Expanded(child: Image.asset(gift.image, fit: BoxFit.contain)),
                          Text(gift.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 3),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: gift.rarity.color.withOpacity(.15), borderRadius: BorderRadius.circular(10)), child: Text(gift.rarity.label, style: TextStyle(color: gift.rarity.color, fontSize: 9, fontWeight: FontWeight.bold))),
                          const SizedBox(height: 3),
                          Text(owned > 0 ? 'مملوك x' + owned.toString() : gift.gems.toString() + ' Gems', style: TextStyle(color: owned > 0 ? NexoColors.success : NexoColors.primary, fontSize: 10)),
                        ]),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _giftDetails(NexoGift gift, int owned, BuildContext sheetContext) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: NexoColors.card,
        title: Text(gift.name, style: TextStyle(color: gift.rarity.color, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: 100, child: Image.asset(gift.image, fit: BoxFit.contain)),
          Text(gift.rarity.label, style: TextStyle(color: gift.rarity.color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(gift.tagline, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('قابل للتداول: ' + (gift.tradeable ? 'نعم' : 'لا'), style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('رجوع')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final economy = context.read<EconomyService>();
              if (_remoteMode) {
                try {
                  final result = await context.read<ApiClient>().postJson('/gifts/send', {
                    'toUserId': widget.person.id,
                    'giftId': gift.id,
                    'idempotencyKey': 'gift-${gift.id}-${DateTime.now().microsecondsSinceEpoch}',
                  });
                  final wallet = await context.read<ApiClient>().getJson('/wallet');
                  economy.setGems((wallet['gems'] as num?)?.toInt() ?? economy.gems);
                  final me = context.read<AuthService>().user?['username']?.toString() ?? 'NEXO_KING';
                  setState(() => (_chatMessages[widget.person.id] ??= []).add(_ChatLine(me, 'تم إرسال ${gift.name}', giftId: gift.id)));
                  context.read<SocialEngine>().logGiftSend();
                  return;
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الهدية: $e'), backgroundColor: Colors.redAccent));
                  return;
                }
              }
              if (owned > 0) {
                economy.removeItem(gift.id, 1);
              } else if (!economy.spendGems(gift.gems)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Gems غير كافية')));
                return;
              }
              setState(() => (_chatMessages[widget.person.id] ??= []).add(_ChatLine('NEXO_KING', 'تم إرسال ' + gift.name, giftId: gift.id)));
              context.read<SocialEngine>().logGiftSend();
              Navigator.pop(sheetContext);
            },
            icon: const Icon(Icons.send_rounded),
            label: Text(owned > 0 ? 'إرسال من المخزون' : 'شراء وإرسال بـ ' + gift.gems.toString() + ' Gems'),
          ),
        ],
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    _controller.value = TextEditingValue(text: text.replaceRange(start, end, emoji), selection: TextSelection.collapsed(offset: start + emoji.length));
  }

  Future<void> _startCall(String kind) async {
    final economy = context.read<EconomyService>();
    final cost = kind == 'video' ? 4 : 1;
    if (!economy.spendEnergy(cost)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ الطاقة غير كافية')));
      return;
    }
    try {
      if (_remoteMode) {
        await _callService.start(widget.person.id, video: kind == 'video');
      }
      _callTimer?.cancel();
      setState(() { _callKind = kind; _callMinutes = 0; });
      _callTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
        if (!mounted || _callKind == null) return;
        final extra = _callKind == 'video' ? 4 : 1;
        if (!economy.spendEnergy(extra)) {
          _endCall(showToast: true);
          return;
        }
        if (mounted) setState(() => _callMinutes++);
      });
      context.read<SocialEngine>().logActivity(kind == 'video' ? 'video_call' : 'voice_call');
    } catch (e) {
      if (_remoteMode) setState(() => economy.setEnergy(economy.energy + cost));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر بدء المكالمة: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _endCall({bool showToast = false}) async {
    _callTimer?.cancel();
    _callTimer = null;
    await _callService.stop();
    if (mounted) setState(() { _callKind = null; _remoteStream = null; });
    if (showToast && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انتهت المكالمة لأن الطاقة خلصت.')));
  }

  void _openEmojiPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NexoColors.surface,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['🔥', '💜', '💎', '👑', '✨', '😂', '⚡', '❤️', '😍', '😎', '🥳', '🤝', '🫶', '🎉', '😈', '🙌'].map(
              (e) => InkWell(
                onTap: () { Navigator.pop(context); _insertEmoji(e); },
                child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(12)), child: Text(e, style: const TextStyle(fontSize: 24))),
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(
        backgroundColor: NexoColors.background,
        leading: const BackButton(color: Colors.white),
        titleSpacing: 0,
        title: Row(children: [
          GestureDetector(onTap: _showUserInfo, child: _Avatar(name: widget.person.name, color: widget.person.color, online: widget.person.online)),
          const SizedBox(width: 9),
          GestureDetector(onTap: _showUserInfo, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.person.name, style: TextStyle(color: widget.person.color, fontWeight: FontWeight.bold)),
            Text(widget.person.online ? 'Online' : 'Offline', style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
          ])),
        ]),
        actions: [
          IconButton(onPressed: () => _callKind == 'voice' ? _endCall() : _startCall('voice'), icon: Icon(_callKind == 'voice' ? Icons.call_end : Icons.call_rounded, color: _callKind == 'voice' ? Colors.redAccent : Colors.white70)),
          IconButton(onPressed: () => _callKind == 'video' ? _endCall() : _startCall('video'), icon: Icon(_callKind == 'video' ? Icons.videocam_off_rounded : Icons.videocam_rounded, color: _callKind == 'video' ? Colors.redAccent : Colors.white70)),
        ],
      ),
      body: Column(children: [
        if (_callKind == 'video' && _remoteStream != null)
          Container(
            height: 220,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black),
            child: RTCVideoView(
              RTCVideoRenderer()..setSrcObject(_remoteStream),
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        if (_callKind != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (_callKind == 'video' ? Colors.deepPurpleAccent : NexoColors.primary).withOpacity(.14), borderRadius: BorderRadius.circular(14), border: Border.all(color: (_callKind == 'video' ? Colors.deepPurpleAccent : NexoColors.primary).withOpacity(.35))),
            child: Row(children: [
              Icon(_callKind == 'video' ? Icons.videocam : Icons.call, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text((_callKind == 'video' ? 'Video' : 'Voice') + ' call · ' + _callMinutes.toString() + ' min · ' + (_callKind == 'video' ? '4' : '1') + ' Energy/min', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              TextButton(onPressed: _endCall, child: const Text('إنهاء')),
            ]),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            itemCount: lines.length,
            itemBuilder: (_, i) {
              final line = lines[i];
              final mine = line.from == 'NEXO_KING';
              final person = mine ? const _Person('NEXO_KING', 'me', true, NexoColors.primary) : widget.person;
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Avatar(name: person.name, color: person.color, online: person.online, radius: 18),
                  const SizedBox(width: 8),
                  Expanded(child: RichText(text: TextSpan(children: [
                    TextSpan(text: line.from + '  ', style: TextStyle(color: person.color, fontWeight: FontWeight.bold, shadows: [Shadow(color: person.color.withOpacity(.55), blurRadius: 9)])),
                    if (line.giftId != null) ...[
                      const TextSpan(text: '🎁 '),
                      TextSpan(text: giftById(line.giftId!)?.name ?? 'Gift', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ] else TextSpan(text: line.text, style: const TextStyle(color: Colors.white, height: 1.45)),
                  ]))),
                ]),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Column(children: [
            const Divider(color: NexoColors.cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(children: [
                IconButton(onPressed: _openEmojiPanel, icon: const Text('☺️', style: TextStyle(fontSize: 24))),
                IconButton(onPressed: _openGiftSheet, icon: const Icon(Icons.card_giftcard_rounded, color: Colors.amber)),
                IconButton(onPressed: _showUserInfo, icon: const Icon(Icons.info_outline_rounded, color: Colors.white70)),
                IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TradeScreen(peerId: widget.person.id, peerName: widget.person.name))), icon: const Icon(Icons.swap_horiz_rounded, color: NexoColors.primary)),
                Expanded(
                  child: TextField(controller: _controller, onSubmitted: (_) => _sendText(), style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'اكتب رسالة...', hintStyle: const TextStyle(color: NexoColors.textSecondary), filled: true, fillColor: NexoColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
                ),
                IconButton(onPressed: _sendText, icon: const Icon(Icons.send_rounded, color: NexoColors.primary)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Person {
  final String name;
  final String id;
  final bool online;
  final Color color;
  const _Person(this.name, this.id, this.online, this.color);
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final bool online;
  final double radius;
  const _Avatar({required this.name, required this.color, required this.online, this.radius = 25});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      CircleAvatar(radius: radius, backgroundColor: color.withOpacity(.13), child: Text(name.isEmpty ? '?' : name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: radius))),
      if (online) Positioned(right: 0, bottom: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: NexoColors.background, width: 2)))),
    ],
  );
}