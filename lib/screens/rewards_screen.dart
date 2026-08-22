import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  // Daily rewards status
  final List<Map<String, dynamic>> dailyRewards = [
    {'day': 1, 'reward': 50, 'type': 'tickets', 'claimed': true},
    {'day': 2, 'reward': 80, 'type': 'tickets', 'claimed': true},
    {'day': 3, 'reward': 100, 'type': 'tickets', 'claimed': false, 'today': true},
    {'day': 4, 'reward': 120, 'type': 'tickets', 'claimed': false},
    {'day': 5, 'reward': 150, 'type': 'tickets', 'claimed': false},
    {'day': 6, 'reward': 200, 'type': 'tickets', 'claimed': false},
    {'day': 7, 'reward': 500, 'type': 'tickets', 'claimed': false, 'special': true},
  ];

  final List<Map<String, dynamic>> activityRewards = [
    {'title': 'التداول اليومي', 'desc': 'أكمل 3 صفقات', 'progress': 1, 'total': 3, 'reward': 250, 'icon': Icons.swap_horiz, 'color': Color(0xFFFFD700)},
    {'title': 'التصنيع', 'desc': 'اصنع 2 عنصر', 'progress': 0, 'total': 2, 'reward': 180, 'icon': Icons.handyman, 'color': Color(0xFFE040FB)},
    {'title': 'التفاعل الاجتماعي', 'desc': 'أرسل 10 رسائل', 'progress': 4, 'total': 10, 'reward': 320, 'icon': Icons.chat_bubble, 'color': Color(0xFF4FC3F7)},
    {'title': 'تسجيل الدخول', 'desc': 'سجل دخول 7 أيام متتالية', 'progress': 3, 'total': 7, 'reward': 500, 'icon': Icons.calendar_today, 'color': Color(0xFF00E676)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'نظام المكافآت',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily streak header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NexoColors.primary.withOpacity(0.3),
                            NexoColors.secondary.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: NexoColors.primary.withOpacity(0.4)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.local_fire_department, color: Color(0xFFFF6D00), size: 36),
                          SizedBox(height: 8),
                          Text(
                            'سلسلة الدخول: 3 أيام 🔥',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            ' Continu سجل دخول كل يوم عشان ما تضيعش السلسلة',
                            style: TextStyle(color: NexoColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'المكافآت اليومية',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // 7-day rewards
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: dailyRewards.length,
                        itemBuilder: (context, index) {
                          final r = dailyRewards[index];
                          final claimed = r['claimed'] as bool;
                          final isToday = r['today'] == true;
                          final isSpecial = r['special'] == true;

                          return Container(
                            width: 72,
                            margin: const EdgeInsets.only(left: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: claimed
                                  ? NexoColors.card.withOpacity(0.5)
                                  : isToday
                                      ? NexoColors.primary.withOpacity(0.2)
                                      : NexoColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isToday
                                    ? NexoColors.primary
                                    : isSpecial
                                        ? NexoColors.gold
                                        : NexoColors.cardBorder,
                                width: isToday || isSpecial ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'يوم ${r['day']}',
                                  style: TextStyle(
                                    color: isToday ? NexoColors.primary : NexoColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Icon(
                                  claimed ? Icons.check_circle : Icons.confirmation_number,
                                  color: claimed
                                      ? NexoColors.success
                                      : isSpecial
                                          ? NexoColors.gold
                                          : NexoColors.ticket,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+${r['reward']}',
                                  style: TextStyle(
                                    color: claimed ? NexoColors.textSecondary : NexoColors.ticket,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (isToday && !claimed)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          dailyRewards[index]['claimed'] = true;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('تم استلام ${r['reward']} تذكرة! 🎉')),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: NexoColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('استلم', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Text(
                      'مكافآت النشاط',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    ...activityRewards.map((a) {
                      final progress = a['progress'] as int;
                      final total = a['total'] as int;
                      final percent = progress / total;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NexoColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (a['color'] as Color).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (a['color'] as Color).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(a['desc'] as String, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.confirmation_number, size: 14, color: NexoColors.ticket),
                                    const SizedBox(width: 4),
                                    Text('+${a['reward']}', style: const TextStyle(color: NexoColors.ticket, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 6,
                                backgroundColor: NexoColors.cardBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(a['color'] as Color),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$progress / $total',
                              style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
