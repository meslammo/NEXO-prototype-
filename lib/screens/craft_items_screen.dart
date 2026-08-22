import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import '../services/energy_service.dart';

class CraftItemsScreen extends StatefulWidget {
  const CraftItemsScreen({super.key});

  @override
  State<CraftItemsScreen> createState() => _CraftItemsScreenState();
}

class _CraftItemsScreenState extends State<CraftItemsScreen> {
  String selectedCategory = 'الكل';

  final List<Map<String, dynamic>> items = [
    {
      'name': 'Crown Shine',
      'icon': Icons.workspace_premium,
      'color': const Color(0xFFFFD700),
      'cost': 250,
      'materials': ['5/10', '0/5', '0/5'],
    },
    {
      'name': 'Galaxy Aura',
      'icon': Icons.star,
      'color': const Color(0xFFFFB300),
      'cost': 350,
      'materials': ['5/15', '0/8', '0/5'],
    },
    {
      'name': 'Shadow Flame',
      'icon': Icons.local_fire_department,
      'color': const Color(0xFF9C27B0),
      'cost': 220,
      'materials': ['1/5', '0/5', '0/5'],
    },
    {
      'name': 'Neon Heart',
      'icon': Icons.favorite,
      'color': const Color(0xFFFF6B9D),
      'cost': 200,
      'materials': ['0/5', '0/5', '0/5'],
    },
    {
      'name': 'Diamond Glow',
      'icon': Icons.diamond,
      'color': const Color(0xFF00E5FF),
      'cost': 300,
      'materials': ['0/5', '0/5', '0/5'],
    },
  ];

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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'التصنيع - Craft Items',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'بحث عن عنصر...',
                  hintStyle: const TextStyle(color: NexoColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: NexoColors.textSecondary),
                  filled: true,
                  fillColor: NexoColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Categories
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['الكل', 'إيموجيات', 'تأثيرات', 'VIP'].map((cat) {
                  final isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? NexoColors.primary : NexoColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? NexoColors.primary : NexoColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : NexoColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NexoColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (item['color'] as Color).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] as String,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: (item['materials'] as List<String>).map((m) {
                                  return Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: NexoColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(m, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.confirmation_number, size: 14, color: NexoColors.ticket),
                                const SizedBox(width: 4),
                                Text(
                                  '${item['cost']}',
                                  style: const TextStyle(color: NexoColors.ticket, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                EnergyService.instance.rewardCrafting();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تم تصنيع ${item['name']} بنجاح! +${EnergyService.craftingReward.toInt()} طاقة',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: NexoColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'تصنيع',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
