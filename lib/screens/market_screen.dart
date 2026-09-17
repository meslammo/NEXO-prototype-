import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/economy_service.dart';
import 'trade_screen.dart';
import 'craft_screen.dart';
import 'inventory_screen.dart';

class MarketItem {
  final String name;
  final String rarity;
  final int price;
  const MarketItem(this.name, this.rarity, this.price);
}

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const items = <MarketItem>[
    MarketItem('💎 Starter Gift', 'Common', 100),
    MarketItem('✨ Galaxy Aura', 'Rare', 500),
    MarketItem('👑 Royal Crown', 'Legendary', 2000),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _buyItem(MarketItem item, BuildContext context) {
    final economy = context.read<EconomyService>();
    if (!economy.spendGems(item.price)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Gems غير كافية')));
      return;
    }
    economy.addItem(item.name, 1);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ اشتريت ${item.name} بـ ${item.price} Gems')));
  }

  @override
  Widget build(BuildContext context) {
    final gems = context.watch<EconomyService>().gems;
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        title: const Text('🛒 Market'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('💎 $gems', style: const TextStyle(color: Color(0xFF66E0FF), fontWeight: FontWeight.bold)),
          )),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D4FF),
          tabs: const [Tab(text: 'Shop'), Tab(text: 'Trade'), Tab(text: 'Crafting')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: ListTile(
                  onTap: () => _buyItem(item, context),
                  tileColor: const Color(0xFF132F4C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: CircleAvatar(backgroundColor: const Color(0x3300D4FF), child: Text(item.name.characters.first)),
                  title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(item.rarity, style: const TextStyle(color: Color(0xFF90A4AE))),
                  trailing: Text('💎 ${item.price}', style: const TextStyle(color: Color(0xFF66E0FF), fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TradeHubCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TradeScreen())),
              ),
              const SizedBox(height: 12),
              const _InfoCard(icon: Icons.shield_rounded, title: 'Escrow', text: 'الحجز + تأكيد الطرفين + إلغاء/نزاع + 5% رسوم.'),
              const SizedBox(height: 12),
              const _InfoCard(icon: Icons.grid_view_rounded, title: '4 Slots', text: 'مساحة عرض واضحة للعناصر في كل طرف من الصفقة.'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('فتح Inventory'),
              ),
            ],
          ),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CraftScreen())),
              icon: const Icon(Icons.handyman_outlined),
              label: const Text('فتح Crafting'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeHubCard extends StatelessWidget {
  final VoidCallback onTap;
  const _TradeHubCard({required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Ink(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF142F52), Color(0xFF132F4C)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.45)),
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 26, backgroundColor: Color(0x3300D4FF), child: Icon(Icons.swap_horiz_rounded, color: Color(0xFF00D4FF))),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trade Hub', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('تبادل عناصر وGems مع لاعب آخر', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
          ])),
          Icon(Icons.chevron_left_rounded, color: Color(0xFF00D4FF)),
        ],
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoCard({required this.icon, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF132F4C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF243C52))),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF00E676)),
      const SizedBox(width: 10),
      Expanded(child: Text('$title\n$text', style: const TextStyle(color: Colors.white70, fontSize: 12))),
    ]),
  );
}
