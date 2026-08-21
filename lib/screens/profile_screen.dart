import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nexo_service.dart';
import '../services/economy_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0a1929),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Header
            Consumer<NexoService>(
              builder: (context, nexoService, _) {
                final user = nexoService.currentUser;
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF132f4c),
                      child: Text(user.username[0],
                          style: const TextStyle(
                              color: Color(0xFF00d4ff), fontSize: 32)),
                    ),
                    const SizedBox(height: 12),
                    Text(user.displayName,
                        style: TextStyle(
                            color: Color(int.parse(
                                '0xFF${user.nameColor.replaceFirst('#', '')}')),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: user.glow
                                ? [
                                    Shadow(
                                      color: Color(int.parse(
                                          '0xFF${user.nameColor.replaceFirst('#', '')}')),
                                      blurRadius: 10,
                                    )
                                  ]
                                : [])),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7c3aed),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(user.vipLevel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Stats
            Consumer2<NexoService, EconomyService>(
              builder: (context, nexoService, economy, _) {
                final user = nexoService.currentUser;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF132f4c),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Text('Level',
                                      style: TextStyle(
                                          color: Color(0xFF90a4ae),
                                          fontSize: 12)),
                                  Text('${user.level}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
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
                              ),
                              child: Column(
                                children: [
                                  const Text('Experience',
                                      style: TextStyle(
                                          color: Color(0xFF90a4ae),
                                          fontSize: 12)),
                                  Text('${user.experience}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
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
                              ),
                              child: Column(
                                children: [
                                  const Text('Reputation',
                                      style: TextStyle(
                                          color: Color(0xFF90a4ae),
                                          fontSize: 12)),
                                  Text('${user.reputation}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // NEXO Score
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132f4c),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF00d4ff), width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('NEXO Score',
                                    style: TextStyle(
                                        color: Color(0xFF90a4ae),
                                        fontSize: 12)),
                                Text('${user.nexoScore}',
                                    style: const TextStyle(
                                        color: Color(0xFF00d4ff),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Social Points',
                                    style: TextStyle(
                                        color: Color(0xFF90a4ae),
                                        fontSize: 12)),
                                Text('${user.socialPoints}',
                                    style: const TextStyle(
                                        color: Color(0xFF00d4ff),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Badges
            Consumer<NexoService>(
              builder: (context, nexoService, _) {
                final user = nexoService.currentUser;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Badges',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: user.badges
                            .map((badge) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7c3aed),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(badge,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
