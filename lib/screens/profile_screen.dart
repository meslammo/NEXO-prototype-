import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nexo_service.dart';
import '../services/economy_service.dart';
import 'our_club_screen.dart';
import 'powers_collection_screen.dart';
import 'inventory_screen.dart';
import 'recharge_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        title: const Text('👤 Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))],
      ),
      body: Consumer2<NexoService, EconomyService>(
        builder: (context, nexo, economy, _) {
          final user = nexo.currentUser;
          final nameColor = Color(int.parse('0xFF${user.nameColor.replaceFirst('#', '')}'));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            children: [
              Center(child: CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF132F4C),
                child: Text(user.username.isNotEmpty ? user.username[0] : '?', style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 32, fontWeight: FontWeight.bold)),
              )),
              const SizedBox(height: 10),
              Center(child: Text(user.displayName, style: TextStyle(
                color: nameColor, fontSize: 21, fontWeight: FontWeight.bold,
                shadows: user.glow ? [Shadow(color: nameColor, blurRadius: 10)] : null,
              ))),
              const SizedBox(height: 6),
              Center(child: Wrap(spacing: 8, children: [
                _Tag(label: user.vipLevel, icon: Icons.workspace_premium_rounded),
                _Tag(label: '💎 ${economy.gems}', icon: Icons.diamond_rounded),
              ])),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _Stat(label: 'Level', value: '${user.level}')),
                const SizedBox(width: 8),
                Expanded(child: _Stat(label: 'Reputation', value: '${user.reputation}')),
                const SizedBox(width: 8),
                Expanded(child: _Stat(label: 'NEXO Score', value: '${user.nexoScore}')),
              ]),
              const SizedBox(height: 22),
              const Text('حسابك', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _MenuTile(icon: Icons.groups_rounded, title: 'Our Club', subtitle: 'المجتمع والعضوية والنشاط', color: const Color(0xFF00D4FF),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OurClubScreen()))),
              _MenuTile(icon: Icons.auto_awesome_rounded, title: 'Powers', subtitle: 'الكولكشن · تفعيل وإيقاف القوى', color: const Color(0xFFE040FB),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PowersCollectionScreen()))),
              _MenuTile(icon: Icons.inventory_2_rounded, title: 'Collection / Inventory', subtitle: 'العناصر والتأثيرات والممتلكات', color: const Color(0xFF7B5CFF),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()))),
              _MenuTile(icon: Icons.verified_rounded, title: 'Badges', subtitle: user.badges.isEmpty ? 'لا توجد شارات بعد' : user.badges.join(' · '), color: const Color(0xFFFFB300), onTap: () {}),
              _MenuTile(icon: Icons.workspace_premium_rounded, title: 'VIP', subtitle: 'العضوية والمزايا', color: const Color(0xFFFFD54F),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeScreen()))),
            ],
          );
        },
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Tag({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFF132F4C), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2B4660))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.white70), const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]),
  );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(color: const Color(0xFF132F4C), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 10)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    ]),
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: const Color(0xFF132F4C), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.14), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11)),
      trailing: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
    ),
  );
}
