import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/economy_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../theme/nexo_theme.dart';
import 'chat_screen.dart';
import 'games_screen.dart';
import 'market_screen.dart';
import 'missions_screen.dart';
import 'our_club_screen.dart';
import 'membership_screen.dart';
import 'profile_screen.dart';
import 'recharge_screen.dart';
import 'pk_battle_screen.dart';
import 'leaderboards_screen.dart';
import 'room_screen.dart';
import '../config/api_config.dart';

/// NEXO Home: original social/party hub using a similar feature vocabulary
/// to modern voice-social apps, but with NEXO branding and implementation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String,dynamic>> _users = [];
  Map<String,dynamic> _membership = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      if(!NexoApiConfig.configured){if(mounted)setState(()=>_loading=false);return;}
      final results = await Future.wait<dynamic>([
        api.getJson('/users'),
        api.getJson('/memberships/current'),
      ]);
      final raw = results[0]['data'] ?? results[0];
      if (raw is List) {
        _users = raw.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
      }
      _membership = Map<String,dynamic>.from(results[1]);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _go(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final econ = context.watch<EconomyService>();
    final notifications = context.watch<NotificationService>();
    final auth = context.watch<AuthService>();
    final online = _users.where((u) => u['online'] == true).take(12).toList();

    return Scaffold(
      backgroundColor: NexoColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreate(context),
        backgroundColor: NexoColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: NexoColors.primary,
        backgroundColor: NexoColors.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(econ, notifications, auth)),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(child: _hero()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _sectionTitle('اكتشف NEXO')),
            SliverToBoxAdapter(child: _quickGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _sectionTitle('متصل الآن')),
            SliverToBoxAdapter(child: _onlineStrip(online)),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _sectionTitle('الألعاب')),
            SliverToBoxAdapter(child: _gamesStrip()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _sectionTitle('NEXO Tribe')),
            SliverToBoxAdapter(child: _tribeCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _sectionTitle('العضوية')),
            SliverToBoxAdapter(child: _membershipCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _sectionTitle('مستخدمون جدد')),
            SliverToBoxAdapter(child: _newUsers()),
            const SliverToBoxAdapter(child: SizedBox(height: 34)),
          ],
        ),
      ),
    );
  }

  Widget _header(EconomyService econ, NotificationService n, AuthService auth) {
    final name = auth.user?['displayName']?.toString() ??
        auth.user?['username']?.toString() ?? 'NEXO';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(children: [
        Row(children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF54D6FF), Color(0xFFB44CFF), Color(0xFFFF6B9D)],
            ).createShader(b),
            child: const Text('NEXO', style: TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2,
            )),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('أهلًا $name', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          IconButton(
            onPressed: () => _showNotifications(context),
            icon: Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.white70),
              if (n.unreadCount > 0)
                Positioned(
                  right: -2, top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: NexoColors.secondary, borderRadius: BorderRadius.circular(10)),
                    child: Text(n.unreadCount > 99 ? '99+' : n.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _wallet('💎', '\${_fmt(econ.gems)} Gems', NexoColors.primary, () => _go(const RechargeScreen())),
          const SizedBox(width: 8),
          _wallet('⚡', '\${econ.energy}/100', NexoColors.gold, () => _go(const MissionsScreen())),
        ]),
      ]),
    );
  }

  Widget _wallet(String icon, String text, Color color, VoidCallback tap) => Expanded(
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(.25))),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12))),
          const Icon(Icons.add_circle_outline, color: Colors.white38, size: 17),
        ]),
      ),
    ),
  );

  Widget _hero() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF32215E), Color(0xFF11273A)]),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: NexoColors.primary.withOpacity(.30)),
      boxShadow: [BoxShadow(color: NexoColors.primary.withOpacity(.10), blurRadius: 20, spreadRadius: 2)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const CircleAvatar(radius: 24, backgroundColor: Color(0x2254D6FF), child: Icon(Icons.graphic_eq_rounded, color: NexoColors.primary, size: 27)),
        const SizedBox(width: 11),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NEXO Party', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          SizedBox(height: 3),
          Text('صوت • فيديو • غرف • أصحاب جدد', style: TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(color: const Color(0x2254D6FF), borderRadius: BorderRadius.circular(10)),
          child: const Text('LIVE', style: TextStyle(color: NexoColors.primary, fontSize: 9, fontWeight: FontWeight.w900)),
        ),
      ]),
      const SizedBox(height: 15),
      Row(children: [
        Expanded(child: _heroAction('مكالمة صوتية', Icons.call_rounded, NexoColors.primary, () => _go(const ChatScreen()))),
        const SizedBox(width: 8),
        Expanded(child: _heroAction('غرفة صوتية', Icons.mic_external_on_rounded, Colors.deepPurpleAccent, () => _go(const VoiceRoomsScreen()))),
        const SizedBox(width: 8),
        Expanded(child: _heroAction('غرفة فيديو', Icons.videocam_rounded, Colors.pinkAccent, () => _go(const ChatScreen()))),
      ]),
    ]),
  );

  Widget _heroAction(String label, IconData icon, Color color, VoidCallback tap) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 7),
      decoration: BoxDecoration(color: Colors.black.withOpacity(.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(.22))),
      child: Column(children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(height: 5),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  Widget _quickGrid() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(children: [
      Row(children: [
        Expanded(child: _miniCard('Moments', 'شارك لحظتك', Icons.photo_camera_back_outlined, Colors.orangeAccent, () => _go(const ProfileScreen()))),
        const SizedBox(width: 8),
        Expanded(child: _miniCard('Store', 'Gifts & Identity', Icons.storefront_outlined, NexoColors.primary, () => _go(const MarketScreen()))),
        const SizedBox(width: 8),
        Expanded(child: _miniCard('Tribe', 'Our community', Icons.groups_rounded, Colors.purpleAccent, () => _go(const OurClubScreen()))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _miniCard('Missions', 'Daily + Events', Icons.task_alt_rounded, NexoColors.gold, () => _go(const MissionsScreen()))),
        const SizedBox(width: 8),
        Expanded(child: _miniCard('Battle', 'PK rooms', Icons.sports_kabaddi_rounded, Colors.pinkAccent, () => _go(const PkBattleScreen()))),
        const SizedBox(width: 8),
        Expanded(child: _miniCard('Ranks', 'Top NEXO', Icons.emoji_events_rounded, NexoColors.primary, () => _go(const LeaderboardsScreen()))),
      ]),
    ]),
  );

  Widget _miniCard(String title, String sub, IconData icon, Color color, VoidCallback tap) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(17),
    child: Container(
      height: 104,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(17), border: Border.all(color: color.withOpacity(.23))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 7),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
        const SizedBox(height: 2),
        Text(sub, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 8)),
      ]),
    ),
  );

  Widget _onlineStrip(List<Map<String,dynamic>> users) {
    if (users.isEmpty) {
      return const SizedBox(height: 88, child: Center(child: Text('مفيش حد ظاهر Online دلوقتي', style: TextStyle(color: NexoColors.textSecondary))));
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final u = users[i];
          final name = u['display_name']?.toString() ?? u['username']?.toString() ?? 'User';
          final power = u['power_id']?.toString();
          return SizedBox(
            width: 72,
            child: InkWell(
              onTap: () => _go(const ChatScreen()),
              borderRadius: BorderRadius.circular(16),
              child: Column(children: [
                Stack(children: [
                  Container(
                    width: 62, height: 62,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF54D6FF), Color(0xFFB44CFF)])),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundColor: NexoColors.surface,
                      child: Text(name.isEmpty ? '?' : name.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  Positioned(
                    right: 1, bottom: 1,
                    child: Container(width: 13, height: 13, decoration: BoxDecoration(color: const Color(0xFF3EE08A), shape: BoxShape.circle, border: Border.all(color: NexoColors.surface, width: 2))),
                  ),
                ]),
                const SizedBox(height: 5),
                Text(power == null ? name : '⚡ $name', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _gamesStrip() => SizedBox(
    height: 102,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      children: [
        _gameTile('Quick Challenge', '3⚡', Icons.flash_on_rounded, () => _go(const GamesScreen())),
        const SizedBox(width: 9),
        _gameTile('Mini Puzzle', '5⚡', Icons.extension_rounded, () => _go(const GamesScreen())),
        const SizedBox(width: 9),
        _gameTile('Daily Arena', '8⚡', Icons.emoji_events_rounded, () => _go(const GamesScreen())),
        const SizedBox(width: 9),
        _gameTile('Ludo', '2–4 Online', Icons.casino_rounded, () => _go(const GamesScreen())),
        const SizedBox(width: 9),
        _gameTile('Chess', '2 Online', Icons.extension_rounded, () => _go(const GamesScreen())),
        const SizedBox(width: 9),
        _gameTile('Live Duel', 'Online', Icons.sports_kabaddi_rounded, () => _go(const GamesScreen())),
      ],
    ),
  );

  Widget _gameTile(String title, String sub, IconData icon, VoidCallback tap) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      width: 135,
      padding: const EdgeInsets.all(13),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF182B46), Color(0xFF2E1B52)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: NexoColors.primary, size: 27),
        const Spacer(),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 9)),
      ]),
    ),
  );

  Widget _tribeCard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: InkWell(
      onTap: () => _go(const OurClubScreen()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purpleAccent.withOpacity(.20))),
        child: Row(children: [
          const CircleAvatar(radius: 26, backgroundColor: Color(0x224C2B67), child: Icon(Icons.groups_rounded, color: Colors.purpleAccent, size: 28)),
          const SizedBox(width: 11),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Our Tribe', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
            SizedBox(height: 3),
            Text('أعضاء • مهام • شات • نشاطات', style: TextStyle(color: NexoColors.textSecondary, fontSize: 10)),
          ])),
          const Icon(Icons.chevron_left_rounded, color: Colors.white38),
        ]),
      ),
    ),
  );

  Widget _membershipCard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: InkWell(
      onTap: () => _go(const MembershipScreen()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF251B3A), Color(0xFF11243A)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NexoColors.gold.withOpacity(.25)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: NexoColors.gold.withOpacity(.12),
            child: Icon(
              _membership['svipActive'] == true
                  ? Icons.workspace_premium_rounded
                  : _membership['vipActive'] == true
                      ? Icons.verified_rounded
                      : Icons.star_outline_rounded,
              color: NexoColors.gold,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _membership['svipActive'] == true
                  ? 'SVIP ACTIVE'
                  : _membership['vipActive'] == true
                      ? 'VIP ACTIVE'
                      : 'NEXO Membership',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text('ميدالية • شارة • Entrance Effects • خصومات متجر', style: TextStyle(color: NexoColors.textSecondary, fontSize: 9)),
          ])),
          const Icon(Icons.chevron_left_rounded, color: NexoColors.gold),
        ]),
      ),
    ),
  );

  Widget _newUsers() {
    final list = _users.where((u) => u['online'] != true).take(6).toList();
    if (list.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('ابدأ محادثة جديدة من قسم Chat', style: TextStyle(color: NexoColors.textSecondary)));
    }
    return SizedBox(
      height: 128,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final u = list[i];
          final name = u['display_name']?.toString() ?? u['username']?.toString() ?? 'User';
          return InkWell(
            onTap: () => _go(const ChatScreen()),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 118,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: NexoColors.cardBorder)),
              child: Column(children: [
                CircleAvatar(radius: 27, backgroundColor: NexoColors.surface, child: Text(name.isEmpty ? '?' : name.substring(0, 1), style: const TextStyle(color: NexoColors.primary, fontWeight: FontWeight.w900, fontSize: 21))),
                const SizedBox(height: 7),
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
                const SizedBox(height: 3),
                const Text('مستخدم NEXO', style: TextStyle(color: NexoColors.textSecondary, fontSize: 8)),
                const SizedBox(height: 6),
                const Text('ابدأ Chat', style: TextStyle(color: NexoColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
  );

  void _showCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NexoColors.surface,
      showDragHandle: true,
      builder: (_) => SafeArea(child: Wrap(children: [
        ListTile(leading: const Icon(Icons.edit_rounded, color: NexoColors.primary), title: const Text('منشور جديد'), onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.auto_stories_rounded, color: NexoColors.primary), title: const Text('Story'), onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.card_giftcard_rounded, color: Colors.amber), title: const Text('إهداء'), onTap: () { Navigator.pop(context); _go(const ChatScreen()); }),
      ])),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NexoColors.surface,
      showDragHandle: true,
      builder: (_) => Consumer<NotificationService>(
        builder: (_, state, __) => SafeArea(
          child: SizedBox(
            height: 430,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(children: [
                  const Expanded(child: Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                  TextButton(onPressed: state.unreadCount == 0 ? null : state.markAllRead, child: const Text('قراءة الكل')),
                ]),
              ),
              Expanded(
                child: state.items.isEmpty
                    ? const Center(child: Text('مفيش إشعارات جديدة', style: TextStyle(color: NexoColors.textSecondary)))
                    : ListView(
                        children: state.items.map((n) => ListTile(
                          leading: const Icon(Icons.notifications_none, color: NexoColors.primary),
                          title: Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          subtitle: Text(n.body, style: const TextStyle(color: NexoColors.textSecondary)),
                          onTap: () => state.markRead(n.id),
                        )).toList(),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  String _fmt(int value) {
    final s = value.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}