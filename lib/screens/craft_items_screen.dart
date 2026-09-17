import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/economy_service.dart';
import '../theme/nexo_theme.dart';

class CraftItemsScreen extends StatelessWidget {
  const CraftItemsScreen({super.key});

  static const recipes = [
    {'id': 'crown_shine', 'name': 'Crown Shine', 'cost': 250, 'icon': Icons.workspace_premium_rounded, 'rarity': 'Legendary'},
    {'id': 'galaxy_aura', 'name': 'Galaxy Aura', 'cost': 350, 'icon': Icons.star_rounded, 'rarity': 'Epic'},
    {'id': 'shadow_flame', 'name': 'Shadow Flame', 'cost': 220, 'icon': Icons.local_fire_department_rounded, 'rarity': 'Rare'},
    {'id': 'neon_heart', 'name': 'Neon Heart', 'cost': 200, 'icon': Icons.favorite_rounded, 'rarity': 'Common'},
    {'id': 'diamond_glow', 'name': 'Diamond Glow', 'cost': 300, 'icon': Icons.diamond_rounded, 'rarity': 'Epic'},
  ];

  void _craft(BuildContext context, Map<String, dynamic> r) {
    final economy = context.read<EconomyService>();
    final cost = r['cost'] as int;
    if (!economy.spendGems(cost)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Gems غير كافية للتصنيع')));
      return;
    }
    economy.addItem('crafted_' + (r['name'] as String), 1);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم تصنيع ' + (r['name'] as String) + ' وإضافته إلى Crafted داخل Inventory')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NexoColors.background,
    body: SafeArea(
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(8, 8, 16, 8), child: Row(children: [const BackButton(color: Colors.white), const Expanded(child: Text('Workshop / Craft', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))), const SizedBox(width: 48)])),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), child: Text('العناصر المصنّعة هنا فقط. لا تظهر كعناصر شراء في Market؛ بعد التصنيع تدخل المخزون.', style: TextStyle(color: NexoColors.textSecondary), textAlign: TextAlign.center)),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (_, i) {
            final r = recipes[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: NexoColors.primary.withOpacity(.25))),
              child: Row(children: [
                Container(width: 54, height: 54, decoration: BoxDecoration(color: NexoColors.primary.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(r['icon'] as IconData, color: NexoColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text((r['rarity'] as String) + ' · تكلفة تصنيع ' + (r['cost'] as int).toString() + ' Gems', style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
                ])),
                ElevatedButton(onPressed: () => _craft(context, r), child: const Text('تصنيع')),
              ]),
            );
          },
        )),
      ]),
    ),
  );
}