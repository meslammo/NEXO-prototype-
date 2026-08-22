import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> elements = [
    {'name': 'Crown Shine', 'icon': Icons.workspace_premium, 'color': Color(0xFFFFD700), 'qty': 2},
    {'name': 'Galaxy Aura', 'icon': Icons.star, 'color': Color(0xFFFFB300), 'qty': 1},
    {'name': 'Neon Heart', 'icon': Icons.favorite, 'color': Color(0xFFFF6B9D), 'qty': 3},
    {'name': 'Shadow Flame', 'icon': Icons.local_fire_department, 'color': Color(0xFF9C27B0), 'qty': 1},
    {'name': 'Name Glow Ticket', 'icon': Icons.confirmation_number, 'color': Color(0xFF7B5CFF), 'qty': 2},
    {'name': 'VIP Emblem', 'icon': Icons.workspace_premium, 'color': Color(0xFFFFD700), 'qty': 1, 'isVip': true},
    {'name': 'Rainbow Ticket', 'icon': Icons.confirmation_number, 'color': Color(0xFFE040FB), 'qty': 5},
    {'name': 'Diamond Glow', 'icon': Icons.diamond, 'color': Color(0xFF00E5FF), 'qty': 1},
    {'name': 'Fire Wings', 'icon': Icons.flutter_dash, 'color': Color(0xFFFF6E40), 'qty': 1},
  ];

  final List<Map<String, dynamic>> tickets = [
    {'name': 'Name Glow Ticket', 'icon': Icons.confirmation_number, 'color': Color(0xFF7B5CFF), 'qty': 2},
    {'name': 'Rainbow Ticket', 'icon': Icons.confirmation_number, 'color': Color(0xFFE040FB), 'qty': 5},
  ];

  final List<Map<String, dynamic>> effects = [
    {'name': 'Galaxy Aura', 'icon': Icons.star, 'color': Color(0xFFFFB300), 'qty': 1},
    {'name': 'Shadow Flame', 'icon': Icons.local_fire_department, 'color': Color(0xFF9C27B0), 'qty': 1},
    {'name': 'Fire Wings', 'icon': Icons.flutter_dash, 'color': Color(0xFFFF6E40), 'qty': 1},
    {'name': 'Diamond Glow', 'icon': Icons.diamond, 'color': Color(0xFF00E5FF), 'qty': 1},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'المخزون (Inventory)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: NexoColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: NexoColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: NexoColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'العناصر'),
                  Tab(text: 'التذاكر'),
                  Tab(text: 'التأثيرات'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Grid content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGrid(elements),
                  _buildGrid(tickets),
                  _buildGrid(effects),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: NexoColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (item['color'] as Color).withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: (item['color'] as Color).withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item['isVip'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: NexoColors.gold, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(color: NexoColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 28,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                item['name'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'x${item['qty']}',
                style: TextStyle(
                  color: item['color'] as Color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
