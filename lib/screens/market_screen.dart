import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nexo_catalog.dart';
import '../services/economy_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../theme/nexo_theme.dart';
import 'trade_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _buy(NexoGift gift) async {
    final economy = context.read<EconomyService>();
    final auth = context.read<AuthService>();
    if (NexoApiConfig.configured && auth.online) {
      try {
        final api = context.read<ApiClient>();
        final result = await api.postJson('/gifts/buy', {
          'giftId': gift.id,
          'idempotencyKey': 'buy-${gift.id}-${DateTime.now().microsecondsSinceEpoch}',
        });
        economy.setGems((result['gems'] as num?)?.toInt() ?? economy.gems);
        economy.addItem(gift.id, 1);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${gift.name} دخل المخزون من السيرفر')));
        return;
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إتمام الشراء: $e'), backgroundColor: Colors.redAccent));
        return;
      }
    }
    if (!economy.spendGems(gift.gems)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Gems غير كافية')));
      return;
    }
    economy.addItem(gift.id, 1);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ' + gift.name + ' دخل المخزون محليًا')));
  }

  @override
  Widget build(BuildContext context) {
    final gems = context.watch<EconomyService>().gems;
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(
        backgroundColor: NexoColors.background,
        title: const Text('Market'),
        centerTitle: true,
        actions: [Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Center(child: Text('💎 ' + gems.toString(), style: const TextStyle(color: NexoColors.primary, fontWeight: FontWeight.bold))))],
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Shop'), Tab(text: 'Trade Hub')]),
      ),
      body: TabBarView(controller: _tabs, children: [
        ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: nexoGifts.length,
          itemBuilder: (_, i) {
            final g = nexoGifts[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: g.rarity.color.withOpacity(.3))),
              child: Row(children: [
                SizedBox(width: 66, height: 66, child: Image.asset(g.image, fit: BoxFit.contain)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(g.rarity.label, style: TextStyle(color: g.rarity.color, fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(g.tagline, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(g.gems.toString() + ' Gems · ' + (g.tradeable ? 'Tradeable' : 'Non-tradeable'), style: const TextStyle(color: NexoColors.primary, fontSize: 11)),
                ])),
                ElevatedButton(onPressed: () => _buy(g), child: const Text('شراء')),
              ]),
            );
          },
        ),
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: NexoColors.primary.withOpacity(.28))),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trade Hub', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('P2P Trade اختياري من الشات أو من هنا. 4 slots + Gems + Escrow + 5% fee + cancellation/dispute.', style: TextStyle(color: NexoColors.textSecondary, height: 1.5)),
              ]),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TradeScreen())), icon: const Icon(Icons.swap_horiz_rounded), label: const Text('فتح صفقة 1-to-1')),
          ],
        ),
      ]),
    );
  }
}