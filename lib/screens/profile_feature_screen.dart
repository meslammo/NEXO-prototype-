import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/nexo_catalog.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../services/economy_service.dart';
import '../theme/nexo_theme.dart';
import 'market_screen.dart';
import 'recharge_screen.dart';
import 'our_club_screen.dart';

enum ProfileFeature { wealth, charm, shop, svip, aristocracy, pointsBank, moments, room, couple, connections, hallOfHonor }

class ProfileFeatureScreen extends StatefulWidget {
  final ProfileFeature feature;
  const ProfileFeatureScreen({super.key, required this.feature});
  @override State<ProfileFeatureScreen> createState() => _ProfileFeatureScreenState();
}

class _ProfileFeatureScreenState extends State<ProfileFeatureScreen> {
  Map<String,dynamic> data = {};
  bool loading = true;
  String? error;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!NexoApiConfig.configured || !context.read<AuthService>().online) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final raw = await context.read<ApiClient>().getJson('/profile/summary');
      if (mounted) setState(() => data = Map<String,dynamic>.from(raw));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String get title {
    switch (widget.feature) {
      case ProfileFeature.wealth: return 'Wealth Level';
      case ProfileFeature.charm: return 'Charm Level';
      case ProfileFeature.shop: return 'Shop';
      case ProfileFeature.svip: return 'SVIP';
      case ProfileFeature.aristocracy: return 'Aristocracy';
      case ProfileFeature.pointsBank: return 'Points Bank';
      case ProfileFeature.moments: return 'My Moments';
      case ProfileFeature.room: return 'My Room';
      case ProfileFeature.couple: return 'My Couple';
      case ProfileFeature.connections: return 'Connection';
      case ProfileFeature.hallOfHonor: return 'Hall Of Honor';
    }
  }

  @override Widget build(BuildContext context) {
    if (widget.feature == ProfileFeature.shop) return const MarketScreen();
    if (widget.feature == ProfileFeature.svip) return const RechargeScreen();
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(
        backgroundColor: NexoColors.background,
        title: Text(title),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('تعذر تحميل البيانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: () { setState(() { loading = true; error = null; }); _load(); }, child: const Text('إعادة المحاولة')),
            ]))
          : _body(),
    );
  }

  Widget _body() {
    switch (widget.feature) {
      case ProfileFeature.wealth:
        return _levelCard('Wealth Level', (data['wealthScore'] as num?)?.toInt() ?? 0, Icons.diamond_rounded, 'يزيد مع الشحن والمشتريات.');
      case ProfileFeature.charm:
        return _levelCard('Charm Level', (data['charmScore'] as num?)?.toInt() ?? 0, Icons.favorite_rounded, 'يزيد مع التفاعل واستقبال الهدايا.');
      case ProfileFeature.aristocracy:
        return _aristocracy();
      case ProfileFeature.pointsBank:
        return _pointsBank();
      case ProfileFeature.moments:
        return _moments();
      case ProfileFeature.room:
        return _room();
      case ProfileFeature.couple:
        return _couple();
      case ProfileFeature.connections:
        return _connections();
      case ProfileFeature.hallOfHonor:
        return _honor();
      case ProfileFeature.shop:
      case ProfileFeature.svip:
        return const SizedBox.shrink();
    }
  }

  int _level(int score) => score <= 0 ? 1 : (score / 100).floor().clamp(1, 999).toInt();
  Widget _levelCard(String label, int score, IconData icon, String help) {
    final level = _level(score);
    final progress = (score % 100) / 100;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1D173D), Color(0xFF0E1829)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NexoColors.primary.withOpacity(.30)),
        ),
        child: Column(children: [
          CircleAvatar(radius: 34, backgroundColor: NexoColors.primary.withOpacity(.14), child: Icon(icon, color: NexoColors.primary, size: 34)),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text('Lv. ' + level.toString(), style: const TextStyle(color: NexoColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(score.toString() + ' points', style: const TextStyle(color: Colors.white70)),
            Text((level * 100).toString() + ' للمرحلة التالية', style: const TextStyle(color: NexoColors.textSecondary)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      _infoTile(Icons.auto_awesome, 'التقدم', help),
      _infoTile(Icons.emoji_events_outlined, 'المزايا', 'مستويات أعلى تعني مزايا وهوية أقوى داخل NEXO.'),
    ]);
  }

  Widget _aristocracy() {
    final level = (data['aristocracyLevel'] as num?)?.toInt() ?? 0;
    const names = ['None','Baron','Viscount','Count','Marquis','Duke','Royal'];
    return ListView(padding: const EdgeInsets.all(16), children: [
      _heroStat(Icons.account_balance, 'Aristocracy', names[level.clamp(0, 6).toInt()], 'المستوى الحالي ' + level.toString() + ' / 6'),
      const SizedBox(height: 14),
      ...List.generate(6, (i) {
        final active = i < level;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? NexoColors.gold.withOpacity(.45) : NexoColors.cardBorder)),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: NexoColors.gold.withOpacity(active ? .15 : .05), child: Text((i + 1).toString(), style: TextStyle(color: active ? NexoColors.gold : Colors.white54, fontWeight: FontWeight.bold))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(names[i + 1], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('امتيازات الرتبة ' + (i + 1).toString(), style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
            ])),
            Icon(active ? Icons.check_circle : Icons.lock_outline, color: active ? NexoColors.success : Colors.white30),
          ]),
        );
      }),
    ]);
  }

  Widget _pointsBank() {
    final points = (data['pointsBank'] as num?)?.toInt() ?? 0;
    final canClaim = data['pointsClaimAvailable'] == true;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _heroStat(Icons.account_balance, 'Bank of Points', points.toString(), 'رصيدك المحفوظ'),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Text('المكافأة اليومية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('+100 Points', style: TextStyle(color: NexoColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: canClaim ? _claimPoints : null, icon: const Icon(Icons.add_card), label: Text(canClaim ? 'استلم نقاط اليوم' : 'تم الاستلام اليوم')),
        ]),
      ),
      const SizedBox(height: 12),
      _infoTile(Icons.savings_outlined, 'البنك', 'الرصيد محفوظ ويمكن استخدامه مع المكافآت والعروض داخل NEXO.'),
    ]);
  }

  Future<void> _claimPoints() async {
    try {
      final r = await context.read<ApiClient>().postJson('/profile/points-bank/claim', {});
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم إضافة ' + (r['added'] ?? 100).toString() + ' Points')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الاستلام: ' + e.toString()), backgroundColor: Colors.redAccent));
    }
  }

  Widget _moments() {
    final raw = data['moments'];
    final moments = raw is List ? raw.whereType<Map>().toList() : <Map>[];
    return ListView(padding: const EdgeInsets.all(14), children: [
      _MomentComposer(onPosted: _load),
      const SizedBox(height: 12),
      if (moments.isEmpty) _empty(Icons.photo_library_outlined, 'لسه مفيش Moments', 'اكتب أول لحظة ليك على NEXO.'),
      ...moments.map((m) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: NexoColors.cardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['body']?.toString() ?? '', style: const TextStyle(color: Colors.white, height: 1.45)),
          const SizedBox(height: 8),
          Text(m['createdAt']?.toString() ?? '', style: const TextStyle(color: NexoColors.textSecondary, fontSize: 10)),
        ]),
      )),
    ]);
  }

  Widget _room() {
    final currentBg = data['roomBackgroundId']?.toString();
    final currentEffect = data['entranceEffectId']?.toString();
    final catalog = context.watch<NexoCatalogService>();
    final rooms = catalog.byType(NexoItemType.roomBackground);
    final effects = catalog.byType(NexoItemType.entranceEffect);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF11182D), Color(0xFF29154B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.meeting_room, color: Colors.white70, size: 50),
              const SizedBox(height: 8),
              Text(
                currentBg ?? 'Default Room',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _choices('Room Background', rooms, currentBg, 'room_background'),
      const SizedBox(height: 10),
      _choices('Entrance Effect', effects, currentEffect, 'entrance_effect'),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketScreen())), icon: const Icon(Icons.storefront), label: const Text('افتح المتجر')),
    ]);
  }

  Widget _choices(String label, List<NexoCatalogItem> items, String? current, String slot) {
    final inv = context.watch<EconomyService>().inventory;
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: items.map((x) {
        final owned = inv[x.id] ?? 0;
        final active = current == x.id;
        return ActionChip(
          avatar: Icon(active ? Icons.check_circle : Icons.auto_awesome, size: 16, color: active ? NexoColors.success : NexoColors.primary),
          label: Text(x.name + (owned > 0 ? ' · x' + owned.toString() : '')),
          onPressed: owned > 0 ? () => _equip(x.id, slot) : null,
        );
      }).toList()),
    ]));
  }

  Future<void> _equip(String id, String slot) async {
    try {
      await context.read<ApiClient>().postJson('/profile/equipped', {'slot': slot, 'itemId': id});
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم التفعيل على البروفايل')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر التفعيل: ' + e.toString()), backgroundColor: Colors.redAccent));
    }
  }

  Widget _couple() {
    final couple = data['couple'];
    final controller = TextEditingController();
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (couple is Map) _heroStat(Icons.favorite, 'My Couple', couple['displayName']?.toString() ?? couple['username']?.toString() ?? 'NEXO Couple', 'مرتبط حاليًا')
      else _empty(Icons.favorite_border, 'My Couple', 'اربط حسابك بشخص واحد من NEXO.'),
      const SizedBox(height: 14),
      TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'اكتب Username', hintStyle: const TextStyle(color: NexoColors.textSecondary), filled: true, fillColor: NexoColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
      const SizedBox(height: 10),
      ElevatedButton.icon(onPressed: () => _setCouple(controller.text.trim()), icon: const Icon(Icons.favorite), label: const Text('تعيين Couple')),
      if (couple is Map) TextButton(onPressed: _removeCouple, child: const Text('إزالة الارتباط', style: TextStyle(color: Colors.redAccent))),
    ]);
  }

  Future<void> _setCouple(String username) async {
    if (username.isEmpty) return;
    try { await context.read<ApiClient>().postJson('/profile/couple', {'username': username}); await _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الربط: ' + e.toString()), backgroundColor: Colors.redAccent)); }
  }
  Future<void> _removeCouple() async {
    try { await context.read<ApiClient>().postJson('/profile/couple', {'username': ''}); await _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الإزالة: ' + e.toString()), backgroundColor: Colors.redAccent)); }
  }

  Widget _connections() {
    final followers = data['followers'] is List ? List<Map>.from((data['followers'] as List).whereType<Map>()) : <Map>[];
    final following = data['following'] is List ? List<Map>.from((data['following'] as List).whereType<Map>()) : <Map>[];
    return ListView(padding: const EdgeInsets.all(14), children: [
      _connectionBlock('Following', following),
      const SizedBox(height: 12),
      _connectionBlock('Followers', followers),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OurClubScreen())), icon: const Icon(Icons.group_outlined), label: const Text('Tribe Connections')),
    ]);
  }

  Widget _connectionBlock(String title, List<Map> users) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title + ' · ' + users.length.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      if (users.isEmpty) const Padding(padding: EdgeInsets.all(10), child: Text('مفيش مستخدمين هنا لسه', style: TextStyle(color: NexoColors.textSecondary, fontSize: 12))),
      ...users.map((u) => ListTile(
        dense: true,
        leading: CircleAvatar(backgroundColor: NexoColors.primary.withOpacity(.15), child: Text((u['displayName'] ?? u['username'] ?? '?').toString().substring(0, 1), style: const TextStyle(color: NexoColors.primary))),
        title: Text(u['displayName']?.toString() ?? u['username']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(u['username']?.toString() ?? '', style: const TextStyle(color: NexoColors.textSecondary, fontSize: 10)),
      )),
    ])
  );

  Widget _honor() {
    final raw = data['hallOfHonor'];
    final rows = raw is List ? raw.whereType<Map>().toList() : <Map>[];
    return DefaultTabController(length: 2, child: Column(children: [
      const SizedBox(height: 8),
      const TabBar(tabs: [Tab(text: 'Wealth'), Tab(text: 'Charm')]),
      Expanded(child: TabBarView(children: [_leaderRows(rows, 'wealthScore'), _leaderRows(rows, 'charmScore')])),
    ]));
  }

  Widget _leaderRows(List<Map> rows, String key) {
    final sorted = [...rows]..sort((a, b) => ((b[key] as num?) ?? 0).compareTo((a[key] as num?) ?? 0));
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final u = sorted[i];
        final name = u['displayName']?.toString() ?? u['username']?.toString() ?? '';
        final score = (u[key] as num?)?.toInt() ?? 0;
        return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(14)), child: Row(children: [
          SizedBox(width: 30, child: Text((i + 1).toString(), style: TextStyle(color: i < 3 ? NexoColors.gold : Colors.white54, fontWeight: FontWeight.w900))),
          CircleAvatar(backgroundColor: NexoColors.primary.withOpacity(.15), child: Text(name.isEmpty ? '?' : name.substring(0, 1), style: const TextStyle(color: NexoColors.primary))),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Text(score.toString(), style: const TextStyle(color: NexoColors.primary, fontWeight: FontWeight.bold)),
        ]));
      },
    );
  }

  Widget _heroStat(IconData icon, String label, String value, String subtitle) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1D173D), Color(0xFF10162B)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: NexoColors.primary.withOpacity(.25))),
    child: Row(children: [
      CircleAvatar(radius: 27, backgroundColor: NexoColors.primary.withOpacity(.13), child: Icon(icon, color: NexoColors.primary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21)),
        Text(subtitle, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 10)),
      ])),
    ])
  );

  Widget _infoTile(IconData icon, String title, String body) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: NexoColors.cardBorder)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: NexoColors.primary),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(body, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11, height: 1.4)),
      ])),
    ])
  );

  Widget _empty(IconData icon, String title, String body) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Icon(icon, color: NexoColors.primary, size: 48),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 4),
      Text(body, style: const TextStyle(color: NexoColors.textSecondary), textAlign: TextAlign.center),
    ])
  );
}

class _MomentComposer extends StatefulWidget {
  final Future<void> Function() onPosted;
  const _MomentComposer({required this.onPosted});
  @override State<_MomentComposer> createState() => _MomentComposerState();
}
class _MomentComposerState extends State<_MomentComposer> {
  final controller = TextEditingController();
  bool sending = false;
  Future<void> _post() async {
    final value = controller.text.trim();
    if (value.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await context.read<ApiClient>().postJson('/profile/moments', {'body': value});
      controller.clear();
      await widget.onPosted();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر النشر: ' + e.toString()), backgroundColor: Colors.redAccent));
    } finally { if (mounted) setState(() => sending = false); }
  }
  @override void dispose(){controller.dispose();super.dispose();}
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      TextField(controller: controller, maxLines: 4, maxLength: 1000, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'اكتب Moment جديدة...', hintStyle: TextStyle(color: NexoColors.textSecondary), border: InputBorder.none)),
      ElevatedButton.icon(onPressed: sending ? null : _post, icon: const Icon(Icons.send_rounded, size: 18), label: Text(sending ? 'جاري النشر' : 'نشر')),
    ])
  );
}