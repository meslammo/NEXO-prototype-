import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/economy_service.dart';
import '../services/social_engine.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import 'mining_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  static const _games = [
    ('🎯', 'Quick Challenge', 'لعبة سريعة مرتبطة بالمكافآت', 3, 20),
    ('🧩', 'Mini Puzzle', 'حل لغز واحصل على Gems', 5, 35),
    ('🏆', 'Daily Arena', 'منافسة يومية خفيفة', 8, 55),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        title: const Text('🎮 Games'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _MiningEntryCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MiningScreen()))),
          const SizedBox(height: 14),
          ...List.generate(_games.length, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GameCard(index: index),
          )),
          const _ArchitectureNote(),
        ],
      ),
    );
  }
}

class _MiningEntryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiningEntryCard({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Ink(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF173B4F), Color(0xFF132F4C)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 28, backgroundColor: Color(0x3300D4FF), child: Text('⛏️', style: TextStyle(fontSize: 26))),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mining', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('التعدين داخل Games — ليس زرًا مستقلًا في الـNavigation', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
          ])),
          Icon(Icons.chevron_left_rounded, color: Color(0xFF00D4FF)),
        ],
      ),
    ),
  );
}

class _GameCard extends StatelessWidget {
  final int index;
  const _GameCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final g = GamesScreen._games[index];
    return InkWell(
      onTap: () => _play(context, g.$2, g.$4, g.$5),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF132F4C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Text(g.$1, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(g.$3, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
              const SizedBox(height: 6),
              Text('تكلفة: ${g.$4} Energy · ربح: ${g.$5} Gems', style: const TextStyle(color: Color(0xFF66E0FF), fontSize: 11)),
            ])),
            const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF00D4FF), size: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _play(BuildContext context, String title, int cost, int reward) async {
    final economy = context.read<EconomyService>();
    final social = context.read<SocialEngine>();
    final auth = context.read<AuthService>();
    const gameIds = {
      'Quick Challenge': 'quick_challenge',
      'Mini Puzzle': 'mini_puzzle',
      'Daily Arena': 'daily_arena',
    };
    if (NexoApiConfig.configured && auth.online) {
      try {
        final api = context.read<ApiClient>();
        final result = await api.postJson('/games/play', {
          'gameId': gameIds[title] ?? 'quick_challenge',
          'idempotencyKey': 'game-${DateTime.now().microsecondsSinceEpoch}',
        });
        economy.hydrateFromServer(
          gems: (result['gems'] as num?)?.toInt() ?? economy.gems,
          energy: (result['energy'] as num?)?.toInt() ?? economy.energy,
        );
        social.logGameWin((result['rewardGems'] as num?)?.toInt() ?? reward);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 $title: +${result['rewardGems'] ?? reward} Gems')),
        );
        return;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('اللعبة لم تُقبل من السيرفر: $e'), backgroundColor: Colors.redAccent),
        );
        return;
      }
    }
    if (!economy.spendEnergy(cost)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ الطاقة غير كافية')));
      return;
    }
    economy.addGems(reward);
    social.logGameWin(reward);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 $title: +$reward Gems محليًا')));
  }
}

class _ArchitectureNote extends StatelessWidget {
  const _ArchitectureNote();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF0F2236), borderRadius: BorderRadius.circular(14)),
    child: const Text(
      'Games تضم Mini Games + Mining + Missions/Rewards. التعدين موجود في المعمارية ومكانه هنا.',
      style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );
}
