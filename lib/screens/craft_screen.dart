import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import 'craft_items_screen.dart';
import 'name_glow_screen.dart';
import 'recipes_screen.dart';

class CraftScreen extends StatelessWidget {
  const CraftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    'التصنيع (Craft)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _craftCard(
                    context,
                    title: 'Craft Items',
                    subtitle: 'اصنع إيموجيات وتأثيرات مميزة',
                    icon: Icons.handyman_rounded,
                    color: const Color(0xFFE040FB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CraftItemsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _craftCard(
                    context,
                    title: 'Name Glow',
                    subtitle: 'اصنع تذكرة تغيير لون اسمك',
                    icon: Icons.confirmation_number_rounded,
                    color: const Color(0xFF7B5CFF),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NameGlowScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _craftCard(
                    context,
                    title: 'Recipes',
                    subtitle: 'استعرض جميع وصفات التصنيع',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF00E676),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecipesScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _craftCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: NexoColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: NexoColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.7), size: 18),
          ],
        ),
      ),
    );
  }
}
