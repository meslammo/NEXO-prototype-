import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/economy_service.dart';

class InventoryPreviewWidget extends StatelessWidget {
  const InventoryPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<EconomyService>(
            builder: (context, economy, _) {
              final items = economy.inventory;
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132F4C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00D4FF),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'No items yet. Start mining or trading!',
                      style: TextStyle(
                        color: Color(0xFF90A4AE),
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final itemId = items.keys.toList()[index];
                  final quantity = items[itemId]!;
                  const itemEmojis = <String, String>{
                    'crown_shine': '👑',
                    'galaxy_aura': '✨',
                    'neon_heart': '❤️',
                    'shadow_flame': '🔥',
                    'rainbow_ticket': '🎫',
                    'diamond_glow': '💎',
                    'fire_wings': '🦅',
                  };

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF132F4C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF7C3AED),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                itemEmojis[itemId] ?? '📦',
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'x$quantity',
                                style: const TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Consumer<EconomyService>(
            builder: (context, economy, _) => Center(
              child: Text(
                'Total Items: ${economy.inventory.length}',
                style: const TextStyle(
                  color: Color(0xFF90A4AE),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
