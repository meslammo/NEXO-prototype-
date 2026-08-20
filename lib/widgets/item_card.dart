import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final String name;
  final String emoji;
  final String rarity;
  final int price;
  final VoidCallback onTap;

  const ItemCard({
    Key? key,
    required this.name,
    required this.emoji,
    required this.rarity,
    required this.price,
    required this.onTap,
  }) : super(key: key);

  Color _getRarityColor() {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return const Color(0xFFffc107);
      case 'epic':
        return const Color(0xFF7c3aed);
      case 'rare':
        return const Color(0xFF00d4ff);
      default:
        return const Color(0xFF90a4ae);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF132f4c),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getRarityColor(),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getRarityColor().withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRarityColor(),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                rarity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '🎫 $price',
              style: const TextStyle(
                color: Color(0xFF00d4ff),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
