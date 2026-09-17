import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nexo_service.dart';
import '../services/economy_service.dart';
import '../theme/nexo_theme.dart';
import 'name_glow_screen.dart';
import 'inventory_screen.dart';
import 'our_club_screen.dart';
import 'recharge_screen.dart';
import 'craft_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Color _parseColor(String value) {
    try { return Color(int.parse('0xFF' + value.replaceFirst('#', ''))); } catch (_) { return NexoColors.primary; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(title: const Text('Profile'), centerTitle: true, backgroundColor: NexoColors.background, actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))]),
      body: Consumer2<NexoService, EconomyService>(
        builder: (context, nexo, economy, _) {
          final user = nexo.currentUser;
          final color = _parseColor(user.nameColor);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            children: [
              Center(child: Stack(alignment: Alignment.bottomRight, children: [
                Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(.65), width: 3), boxShadow: [BoxShadow(color: color.withOpacity(.22), blurRadius: 20)]), child: CircleAvatar(radius: 50, backgroundColor: NexoColors.card, child: Text(user.username[0], style: TextStyle(color: color, fontSize: 34, fontWeight: FontWeight.bold)))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)), child: Text(user.vipLevel, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))),
              ])),
              const SizedBox(height: 10),
              Center(child: Text(user.displayName, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold, shadows: user.glow ? [Shadow(color: color, blurRadius: 14), Shadow(color: color.withOpacity(.45), blurRadius: 26)] : null))),
              const SizedBox(height: 6),
              Center(child: Text('💎 ' + economy.gems.toString() + ' Gems', style: const TextStyle(color: NexoColors.primary, fontWeight: FontWeight.bold))),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _Stat('Level', user.level.toString())),
                const SizedBox(width: 8),
                Expanded(child: _Stat('Reputation', user.reputation.toString())),
                const SizedBox(width: 8),
                Expanded(child: _Stat('NEXO Score', user.nexoScore.toString())),
              ]),
              const SizedBox(height: 22),
              const Text('حسابك', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _Menu(icon: Icons.auto_awesome_rounded, title: 'Font Colour', subtitle: 'لون ووهج الاسم + المعاينة داخل الشات', color: color, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NameGlowScreen()))),
              _Menu(icon: Icons.inventory_2_rounded, title: 'Collection / Inventory', subtitle: 'Gifts · Frames · Assets · Crafted Items', color: const Color(0xFF7B5CFF), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()))),
              _Menu(icon: Icons.handyman_rounded, title: 'Workshop / Craft', subtitle: 'التصنيع منفصل عن المتجر والمنتج يدخل المخزون', color: Colors.deepPurpleAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CraftScreen()))),
              _Menu(icon: Icons.groups_rounded, title: 'Our Club', subtitle: 'المجتمع والعضوية والنشاط', color: NexoColors.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OurClubScreen()))),
              _Menu(icon: Icons.military_tech_rounded, title: 'Badges', subtitle: user.badges.isEmpty ? 'لا توجد شارات بعد' : user.badges.join(' · '), color: Colors.amber, onTap: () {}),
              _Menu(icon: Icons.workspace_premium_rounded, title: 'VIP / Recharge', subtitle: 'العضوية والمزايا وشحن Gems', color: Colors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeScreen()))),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8), decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: NexoColors.cardBorder)), child: Column(children: [Text(label, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 10)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17))]));
}

class _Menu extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _Menu({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(.3))), child: ListTile(onTap: onTap, leading: CircleAvatar(backgroundColor: color.withOpacity(.14), child: Icon(icon, color: color)), title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text(subtitle, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11)), trailing: const Icon(Icons.chevron_left_rounded, color: Colors.white54)));
}