import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import '../services/energy_service.dart';
import '../widgets/energy_battery_widget.dart';

/// شاشة المهام اليومية - كل مهمة بتديلك طاقة لما تكملها.
/// دلوقتي بتتابع التقدم في الذاكرة بس (in-memory)؛ لو عايز التقدم يتحفظ
/// بين الجلسات، اربطها بـ energy_storage_service أو بسيرفر لاحقًا.
class DailyMissionsScreen extends StatefulWidget {
  const DailyMissionsScreen({super.key});

  @override
  State<DailyMissionsScreen> createState() => _DailyMissionsScreenState();
}

class _Mission {
  final String id;
  final String title;
  final IconData icon;
  final int target;
  final double reward;
  int progress;
  bool claimed;

  _Mission({
    required this.id,
    required this.title,
    required this.icon,
    required this.target,
    required this.reward,
    this.progress = 0,
    this.claimed = false,
  });

  bool get isComplete => progress >= target;
}

class _DailyMissionsScreenState extends State<DailyMissionsScreen> {
  final List<_Mission> _missions = [
    _Mission(id: 'mine_5', title: 'عدّن 5 مرات', icon: Icons.diamond, target: 5, reward: 10, progress: 5),
    _Mission(id: 'craft_1', title: 'اصنع عنصر واحد', icon: Icons.handyman_rounded, target: 1, reward: 10, progress: 0),
    _Mission(id: 'chat_3', title: 'ابعت 3 رسائل شات', icon: Icons.chat_bubble_rounded, target: 3, reward: 5, progress: 1),
    _Mission(id: 'voice_1', title: 'ادخل مكالمة صوت لدقيقة', icon: Icons.mic_rounded, target: 1, reward: 15, progress: 0),
  ];

  void _claim(_Mission m) {
    if (!m.isComplete || m.claimed) return;
    setState(() {
      m.claimed = true;
      EnergyService.instance.rewardDailyMission(m.reward, m.id);
    });

    final allClaimed = _missions.every((x) => x.claimed);
    if (allClaimed) {
      // بونص إكمال كل المهام
      EnergyService.instance.rewardDailyMission(30, 'daily_missions_all_done');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: NexoColors.card,
          content: Text('🎉 كملت كل المهام! +30 طاقة إضافية', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoColors.background,
      body: SafeArea(
        child: Column(
          children: [
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
                      'المهام اليومية',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const EnergyBatteryWidget(),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _missions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final m = _missions[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NexoColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NexoColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: NexoColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(m.icon, color: NexoColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${m.progress}/${m.target}  •  +${m.reward.toInt()} طاقة',
                                  style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: m.isComplete && !m.claimed ? () => _claim(m) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: m.claimed ? NexoColors.cardBorder : NexoColors.success,
                            disabledBackgroundColor: NexoColors.cardBorder,
                          ),
                          child: Text(
                            m.claimed ? 'تم' : 'استلام',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
