import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import 'inventory_screen.dart';
import 'recharge_screen.dart';
import 'rewards_screen.dart';
import 'powers_collection_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'الـ Powers', 'subtitle': 'الكولكشن · تفعيل وإيقاف القوى', 'icon': Icons.auto_awesome, 'color': Color(0xFFE040FB), 'screen': const PowersCollectionScreen()},
      {'title': 'المخزون', 'subtitle': 'عرض كل العناصر والتذاكر', 'icon': Icons.inventory_2_rounded, 'color': Color(0xFF7B5CFF), 'screen': const InventoryScreen()},
      {'title': 'الشحن والعروض', 'subtitle': 'شراء تذاكر وعضوية VIP', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFFFFB300), 'screen': const RechargeScreen()},
      {'title': 'نظام المكافآت', 'subtitle': 'المكافآت اليومية ومكافآت النشاط', 'icon': Icons.card_giftcard_rounded, 'color': Color(0xFF00E676), 'screen': const RewardsScreen()},
      {'title': 'السوق', 'subtitle': 'قريبًا', 'icon': Icons.storefront_rounded, 'color': Color(0xFF00BCD4), 'screen': null},
      {'title': 'الصوت', 'subtitle': 'قريبًا', 'icon': Icons.mic_rounded, 'color': Color(0xFF536DFE), 'screen': null},
      {'title': 'الفيديو', 'subtitle': 'قريبًا', 'icon': Icons.videocam_rounded, 'color': Color(0xFF651FFF), 'screen': null},
      {'title': 'غرف VIP', 'subtitle': 'قريبًا', 'icon': Icons.workspace_premium_rounded, 'color': Color(0xFFFFD700), 'screen': null},
      {'title': 'الإعدادات', 'subtitle': 'قريبًا', 'icon': Icons.settings_rounded, 'color': Color(0xFFB0B0C0), 'screen': null},
    ];

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'المزيد',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      if (item['screen'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item['screen'] as Widget),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('قريبًا...')),
                        );
                      }
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: (item['color'] as Color).withOpacity(0.3)),
                    ),
                    tileColor: NexoColors.card,
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 26),
                    ),
                    title: Text(
                      item['title'] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item['subtitle'] as String,
                      style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: (item['color'] as Color).withOpacity(0.7), size: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
