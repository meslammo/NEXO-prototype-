import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nexo_catalog.dart';
import '../services/economy_service.dart';
import '../theme/nexo_theme.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: NexoColors.background,
        appBar: AppBar(
          backgroundColor: NexoColors.background,
          title: const Text('Collection / Inventory'),
          centerTitle: true,
          leading: const BackButton(color: Colors.white),
          bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Gifts'), Tab(text: 'Frames'), Tab(text: 'Assets'), Tab(text: 'Crafted')]),
        ),
        body: Consumer<EconomyService>(
          builder: (_, economy, __) => TabBarView(children: [_gifts(economy), _frames(), _assets(), _crafted(economy)]),
        ),
      ),
    );
  }

  Widget _gifts(EconomyService economy) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: nexoGifts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .78),
      itemBuilder: (_, i) {
        final gift = nexoGifts[i];
        final qty = economy.inventory[gift.id] ?? 0;
        return _Tile(border: gift.rarity.color, child: Column(children: [
          Expanded(child: Image.asset(gift.image, fit: BoxFit.contain)),
          Text(gift.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(gift.rarity.label, style: TextStyle(color: gift.rarity.color, fontSize: 9)),
          Text('x' + qty.toString(), style: const TextStyle(color: NexoColors.primary, fontWeight: FontWeight.bold)),
        ]));
      },
    );
  }

  Widget _frames() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: nexoFrames.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2),
      itemBuilder: (_, i) {
        final f = nexoFrames[i];
        final c = (f['rarity'] as NexoRarity).color;
        return _Tile(border: c, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 78, height: 78, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 4), boxShadow: [BoxShadow(color: c.withOpacity(.35), blurRadius: 18)]), child: Icon(f['icon'] as IconData, color: c, size: 34)),
          const SizedBox(height: 8),
          Text(f['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text((f['rarity'] as NexoRarity).label, style: TextStyle(color: c, fontSize: 10)),
        ]));
      },
    );
  }

  Widget _assets() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: nexoAssets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .92),
      itemBuilder: (_, i) {
        final a = nexoAssets[i];
        final c = (a['rarity'] as NexoRarity).color;
        return _Tile(border: c, child: Column(children: [
          Expanded(child: Image.asset(a['image'] as String, fit: BoxFit.contain)),
          Text(a['name'] as String, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          Text((a['rarity'] as NexoRarity).label, style: TextStyle(color: c, fontSize: 10)),
        ]));
      },
    );
  }

  Widget _crafted(EconomyService economy) {
    final crafted = economy.inventory.entries.where((e) => e.key.startsWith('crafted_')).toList();
    if (crafted.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(28), child: Text('مفيش عناصر مصنّعة لسه.\\nادخل Workshop / Craft من Profile؛ المنتج هنا يدخل المخزون ومش بيتكرر في Market.', textAlign: TextAlign.center, style: TextStyle(color: NexoColors.textSecondary, height: 1.6))));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: crafted.map((entry) {
        return Card(
          color: NexoColors.card,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.handyman_rounded)),
            title: Text(
              entry.key.replaceFirst('crafted_', ''),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              'x${entry.value}',
              style: const TextStyle(color: NexoColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Tile extends StatelessWidget {
  final Color border;
  final Widget child;
  const _Tile({required this.border, required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border.withOpacity(.32))), child: child);
}