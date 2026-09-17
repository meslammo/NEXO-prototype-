import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/nexo_theme.dart';
import '../services/economy_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: NexoColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Consumer<EconomyService>(
          builder: (context, economy, _) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(economy: economy)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: _Stories()),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              const SliverToBoxAdapter(child: _SectionTitle(title: 'آخر النشاطات')),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: _FeedPost(
                name: 'Shadoww',
                text: 'دخلنا Games النهارده 🎮',
                meta: 'الآن',
                icon: Icons.sports_esports_rounded,
              )),
              const SliverToBoxAdapter(child: _FeedPost(
                name: 'GalaxyGirl',
                text: 'هدية جديدة وصلتني 💜',
                meta: 'منذ 8 دقائق',
                icon: Icons.card_giftcard_rounded,
              )),
              const SliverToBoxAdapter(child: _FeedPost(
                name: 'Prince_X',
                text: 'Trade request جاهز في Market',
                meta: 'منذ 17 دقيقة',
                icon: Icons.swap_horiz_rounded,
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final notifications = context.read<NotificationService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: NexoColors.surface,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: 420,
          child: Consumer<NotificationService>(
            builder: (context, state, _) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                      TextButton(onPressed: state.unreadCount == 0 ? null : state.markAllRead, child: const Text('قراءة الكل')),
                    ],
                  ),
                ),
                Expanded(
                  child: state.items.isEmpty
                    ? const Center(child: Text('مفيش إشعارات جديدة', style: TextStyle(color: NexoColors.textSecondary)))
                    : ListView.builder(
                        itemCount: state.items.length,
                        itemBuilder: (_, i) {
                          final n = state.items[i];
                          return ListTile(
                            leading: Icon(n.kind == 'gift' ? Icons.card_giftcard : n.kind == 'trade' ? Icons.swap_horiz : Icons.notifications_none, color: NexoColors.primary),
                            title: Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            subtitle: Text(n.body, style: const TextStyle(color: NexoColors.textSecondary)),
                            onTap: () => notifications.markRead(n.id),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NexoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            runSpacing: 10,
            children: const [
              ListTile(leading: Icon(Icons.text_fields), title: Text('منشور نصي')),
              ListTile(leading: Icon(Icons.image_outlined), title: Text('Story / صورة')),
              ListTile(leading: Icon(Icons.card_giftcard_outlined), title: Text('هدية')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final EconomyService economy;
  const _Header({required this.economy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Row(
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
              Consumer<NotificationService>(
                builder: (context, notifications, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () => _showNotifications(context),
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                    ),
                    if (notifications.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: NexoColors.secondary, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            notifications.unreadCount > 99 ? '99+' : notifications.unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _WalletChip(
                icon: Icons.diamond_rounded,
                label: 'Gems',
                value: _fmt(economy.gems),
                color: NexoColors.primary,
              )),
              const SizedBox(width: 10),
              Expanded(child: _WalletChip(
                icon: Icons.bolt_rounded,
                label: 'Energy',
                value: '${economy.energy}/100',
                color: NexoColors.gold,
              )),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(int value) {
    final s = value.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }
}

class _WalletChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _WalletChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: NexoColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11))),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    ),
  );
}

class _Stories extends StatelessWidget {
  const _Stories();

  @override
  Widget build(BuildContext context) {
    final names = ['Your Story', 'Shadoww', 'GalaxyGirl', 'Prince_X', 'Ahmed'];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: i == 0
                      ? [NexoColors.cardBorder, NexoColors.cardBorder]
                      : [NexoColors.primary, NexoColors.secondary],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: NexoColors.surface,
                child: i == 0
                    ? const Icon(Icons.add, color: Colors.white)
                    : Text(names[i][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(names[i], maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
  );
}

class _FeedPost extends StatelessWidget {
  final String name;
  final String text;
  final String meta;
  final IconData icon;
  const _FeedPost({required this.name, required this.text, required this.meta, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: NexoColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: NexoColors.cardBorder),
    ),
    child: Row(
      children: [
        CircleAvatar(backgroundColor: NexoColors.primary.withOpacity(0.18), child: Icon(icon, color: NexoColors.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 5),
          Text(meta, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ])),
      ],
    ),
  );
}
