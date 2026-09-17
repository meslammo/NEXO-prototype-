import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';

class OurClubScreen extends StatelessWidget {
  const OurClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(title: const Text('Our Club'), backgroundColor: NexoColors.background),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF172E56), Color(0xFF132F4C)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NexoColors.primary.withOpacity(0.45)),
            ),
            child: const Column(children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Color(0x332BDEFF),
                child: Icon(Icons.groups_rounded, color: Color(0xFF66E0FF), size: 34),
              ),
              SizedBox(height: 12),
              Text('NEXO Our Club', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text(
                'مساحة المجتمع والعضوية والنشاط الاجتماعي داخل NEXO',
                textAlign: TextAlign.center,
                style: TextStyle(color: NexoColors.textSecondary, fontSize: 12),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const _ClubTile(icon: Icons.star_rounded, title: 'Club Level', value: '12'),
          const _ClubTile(icon: Icons.groups_rounded, title: 'Club Members', value: '248'),
          const _ClubTile(icon: Icons.event_available_rounded, title: 'Weekly Activity', value: '86%'),
          const _ClubTile(icon: Icons.verified_rounded, title: 'Membership', value: 'Premium'),
        ],
      ),
    );
  }
}

class _ClubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _ClubTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: NexoColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: NexoColors.cardBorder),
    ),
    child: Row(children: [
      Icon(icon, color: NexoColors.primary),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]),
  );
}
