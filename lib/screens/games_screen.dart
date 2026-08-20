import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/economy_service.dart';
import '../services/social_engine.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final games = [
    {
      'title': '⛏ Mining Game I',
      'description': 'Mining سريع للحصول على Reward.',
      'icon': '⛏️',
      'energyCost': 3,
    },
    {
      'title': '💎 Mining Game II',
      'description': 'ابحث عن Rare Ore.',
      'icon': '💎',
      'energyCost': 5,
    },
    {
      'title': '⚡ Mining Game III',
      'description': 'إدارة Energy والوقت.',
      'icon': '⚡',
      'energyCost': 8,
    },
  ];

  void _playGame(int index, BuildContext context) {
    final economy = Provider.of<EconomyService>(context, listen: false);
    final social = Provider.of<SocialEngine>(context, listen: false);
    final energyCost = games[index]['energyCost'] as int;

    if (economy.spendEnergy(energyCost)) {
      final reward = (15 + index * 10) + (index * 5);
      economy.addTickets(reward);
      social.logGameWin(reward);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 You won! +$reward Tickets'),
          backgroundColor: const Color(0xFF00d4ff),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Not enough energy!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Games'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0a1929),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF132f4c),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00d4ff), width: 2),
                ),
                child: const Column(
                  children: [
                    Text('🎮 Mining Games',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('ألعاب مرتبطة بنظام المكافآت والاقتصاد',
                        style: TextStyle(
                            color: Color(0xFF90a4ae), fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              games.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () => _playGame(index, context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132f4c),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF7c3aed), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(games[index]['icon'] as String,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(games[index]['title'] as String,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text(games[index]['description'] as String,
                                  style: const TextStyle(
                                      color: Color(0xFF90a4ae),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00d4ff),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Play',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
