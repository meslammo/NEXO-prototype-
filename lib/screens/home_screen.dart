import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nexo_service.dart';
import '../services/economy_service.dart';
import '../services/social_engine.dart';
import '../widgets/profile_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/inventory_preview.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXO'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0a1929),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Card
            Consumer<NexoService>(
              builder: (context, nexoService, _) {
                return ProfileCard(user: nexoService.currentUser);
              },
            ),
            const SizedBox(height: 20),

            // Economy Status
            Consumer<EconomyService>(
              builder: (context, economy, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132f4c),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00d4ff),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text('⚡ Energy',
                                  style: TextStyle(
                                      color: Color(0xFF90a4ae),
                                      fontSize: 12)),
                              Text('${economy.energy}/100',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132f4c),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF7c3aed),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text('🎫 Tickets',
                                  style: TextStyle(
                                      color: Color(0xFF90a4ae),
                                      fontSize: 12)),
                              Text('${economy.tickets}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132f4c),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00d4ff),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text('✨ Points',
                                  style: TextStyle(
                                      color: Color(0xFF90a4ae),
                                      fontSize: 12)),
                              Text('${economy.socialPoints}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Quick Actions
            const QuickActionsWidget(),
            const SizedBox(height: 20),

            // NEXO Score
            Consumer<SocialEngine>(
              builder: (context, social, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132f4c),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF7c3aed),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NEXO Score',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${social.totalNexoScore}',
                              style: const TextStyle(
                                  color: Color(0xFF00d4ff),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Daily: ${social.getDailyScore()}',
                                    style: const TextStyle(
                                        color: Color(0xFF90a4ae),
                                        fontSize: 12)),
                                Text('Weekly: ${social.getWeeklyScore()}',
                                    style: const TextStyle(
                                        color: Color(0xFF90a4ae),
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Inventory Preview
            const InventoryPreviewWidget(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
