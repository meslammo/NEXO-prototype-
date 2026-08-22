import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import 'trade_screen.dart';
import 'craft_screen.dart';
import 'rewards_screen.dart';
import 'inventory_screen.dart';
import 'recharge_screen.dart';
import 'mining_screen.dart';
import 'daily_missions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: 18),
            const _ProfileCard(),
            const SizedBox(height: 16),
            const _StatsRow(),
            const SizedBox(height: 18),
            const _FeatureGrid(),
            const SizedBox(height: 18),
            const _VipBanner(),
            const SizedBox(height: 18),
            const _DailyRewardsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF7B5CFF), Color(0xFF00D4FF)],
          ).createShader(bounds),
          child: const Text(
            'NEXO',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
          ),
        ),
        const Spacer(),
        _Badge(icon: Icons.confirmation_number_rounded, value: '12,450', color: NexoColors.ticket),
        const SizedBox(width: 8),
        _Badge(icon: Icons.star_rounded, value: '8,250', color: NexoColors.social),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 16, color: Colors.black87),
              SizedBox(width: 4),
              Text('VIP', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _Badge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NexoColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexoColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NexoColors.cardBorder),
        boxShadow: [BoxShadow(color: NexoColors.primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: NexoColors.primary, width: 2),
              gradient: const LinearGradient(colors: [Color(0xFF7B5CFF), Color(0xFF00D4FF)]),
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: NexoColors.surface,
              child: Icon(Icons.person, size: 36, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('NEXO_KING', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    const Icon(Icons.workspace_premium, size: 18, color: NexoColors.gold),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: NexoColors.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: const Text('VIP', style: TextStyle(color: NexoColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Lv. 12', style: TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.75,
                    minHeight: 6,
                    backgroundColor: NexoColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(NexoColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('75%', style: TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.confirmation_number_rounded,
            label: 'Tickets',
            value: '12,450',
            color: NexoColors.ticket,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            label: 'Social Points',
            value: '8,250',
            color: NexoColors.social,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NexoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final features = [
      _Feature(Icons.chat_bubble_rounded, 'Chat', const Color(0xFF7B5CFF), () {}),
      _Feature(Icons.diamond_rounded, 'Mining', const Color(0xFF00E676), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MiningScreen()));
      }),
      _Feature(Icons.swap_horiz_rounded, 'Trade', const Color(0xFF00BCD4), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TradeScreen()));
      }),
      _Feature(Icons.handyman_rounded, 'Craft', const Color(0xFFE040FB), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CraftScreen()));
      }),
      _Feature(Icons.storefront_rounded, 'Market', const Color(0xFF7C4DFF), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeScreen()));
      }),
      _Feature(Icons.mic_rounded, 'Voice', const Color(0xFF536DFE), () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الصوت — قريبًا')));
      }),
      _Feature(Icons.videocam_rounded, 'Video', const Color(0xFF651FFF), () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الفيديو — قريبًا')));
      }),
      _Feature(Icons.workspace_premium_rounded, 'VIP Room', const Color(0xFFFFD700), () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('غرف VIP — قريبًا')));
      }),
      _Feature(Icons.inventory_2_rounded, 'Inventory', const Color(0xFFAA00FF), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        return GestureDetector(
          onTap: f.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: NexoColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: f.color.withOpacity(0.35)),
              boxShadow: [BoxShadow(color: f.color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: f.color.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(f.icon, color: f.color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(f.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _Feature(this.icon, this.label, this.color, this.onTap);
}

class _VipBanner extends StatelessWidget {
  const _VipBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [NexoColors.gold.withOpacity(0.2), NexoColors.primary.withOpacity(0.15)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NexoColors.gold.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: NexoColors.gold, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('VIP مميزات حصرية تنتظرك', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: NexoColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NexoColors.gold.withOpacity(0.5)),
              ),
              child: const Text('عرض المزايا', style: TextStyle(color: NexoColors.gold, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyRewardsSection extends StatelessWidget {
  const _DailyRewardsSection();

  @override
  Widget build(BuildContext context) {
    final rewards = [
      {'label': 'التداول', 'value': '+250', 'sub': 'هذا اليوم', 'icon': Icons.swap_horiz, 'color': NexoColors.gold},
      {'label': 'التصنيع', 'value': '+180', 'sub': 'هذا اليوم', 'icon': Icons.handyman, 'color': NexoColors.primary},
      {'label': 'النقاط', 'value': '+320', 'sub': 'هذا اليوم', 'icon': Icons.star, 'color': NexoColors.social},
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('مكافآت اليوم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyMissionsScreen())),
                  child: const Text('المهام اليومية', style: TextStyle(color: NexoColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
                  child: const Text('عرض الكل ←', style: TextStyle(color: NexoColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: rewards.map((r) {
            return Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: NexoColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: (r['color'] as Color).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(r['icon'] as IconData, color: r['color'] as Color, size: 22),
                      const SizedBox(height: 6),
                      Text(r['value'] as String, style: TextStyle(color: r['color'] as Color, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(r['label'] as String, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
                      Text(r['sub'] as String, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
