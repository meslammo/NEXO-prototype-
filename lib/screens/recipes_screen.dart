import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String selectedFilter = 'الكل';

  final List<Map<String, dynamic>> recipes = [
    {
      'name': 'Crown Shine Recipe',
      'icon': Icons.workspace_premium,
      'color': const Color(0xFFFFD700),
      'cost': 250,
      'materials': ['5/10', '0/5', '0/5'],
    },
    {
      'name': 'Galaxy Aura Recipe',
      'icon': Icons.star,
      'color': const Color(0xFFFFB300),
      'cost': 350,
      'materials': ['5/15', '0/8', '0/5'],
    },
    {
      'name': 'Name Glow Ticket Recipe',
      'icon': Icons.confirmation_number,
      'color': const Color(0xFF7B5CFF),
      'cost': 300,
      'materials': ['1/5', '0/5'],
    },
    {
      'name': 'VIP Emblem Recipe',
      'icon': Icons.workspace_premium,
      'color': const Color(0xFFFFD700),
      'cost': 400,
      'materials': ['1/5', '0/5', '0/5'],
      'isVip': true,
    },
    {
      'name': 'Rainbow Ticket Recipe',
      'icon': Icons.confirmation_number,
      'color': const Color(0xFFE040FB),
      'cost': 300,
      'materials': ['1/5', '0/5'],
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
                      'Recipes - جميع الوصفات',
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
                  hintText: 'بحث عن...',
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

            // Filters
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['الكل', 'إيموجيات', 'تأثيرات', 'VIP'].map((f) {
                  final isSelected = selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? NexoColors.primary : NexoColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? NexoColors.primary : NexoColors.cardBorder),
                        ),
                        child: Text(
                          f,
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

            // Recipes list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final r = recipes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NexoColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (r['color'] as Color).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (r['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: r['isVip'] == true
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: NexoColors.gold, width: 1.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('VIP', style: TextStyle(color: NexoColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                              : Icon(r['icon'] as IconData, color: r['color'] as Color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['name'] as String,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: (r['materials'] as List<String>).map((m) {
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
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number, size: 16, color: NexoColors.ticket),
                            const SizedBox(width: 4),
                            Text(
                              '${r['cost']}',
                              style: const TextStyle(color: NexoColors.ticket, fontWeight: FontWeight.bold, fontSize: 15),
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
