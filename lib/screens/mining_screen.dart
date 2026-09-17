import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import '../services/energy_service.dart';
import '../widgets/energy_battery_widget.dart';

/// شاشة التعدين - كل 4 ضغطات على الصخرة تكافئ طاقة.
class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});

  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen>
    with SingleTickerProviderStateMixin {
  int _hits = 0;
  static const int _hitsNeeded = 4;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onTapRock() {
    setState(() => _hits++);
    _shakeController.forward(from: 0);

    if (_hits >= _hitsNeeded) {
      setState(() => _hits = 0);
      EnergyService.instance.rewardMining();

      final gained = EnergyService.miningReward.toInt();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          backgroundColor: NexoColors.card,
          content: Row(
            children: [
              const Icon(Icons.bolt, color: Color(0xFFFFEB3B), size: 18),
              const SizedBox(width: 6),
              Text('+$gained طاقة', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_hits / _hitsNeeded).clamp(0.0, 1.0);

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
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'التعدين',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const EnergyBatteryWidget(),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) {
                        final direction =
                            (_shakeController.value * 30).round().isEven
                                ? 1.0
                                : -1.0;
                        final offset =
                            (1 - _shakeController.value) * 4 * direction;
                        return Transform.translate(
                          offset: Offset(
                              _shakeController.isAnimating ? offset : 0, 0),
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap: _onTapRock,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                NexoColors.primary.withOpacity(0.5),
                                NexoColors.card,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: NexoColors.primary.withOpacity(0.35),
                                blurRadius: 25,
                              ),
                            ],
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                          child: const Center(
                            child: Icon(Icons.diamond,
                                size: 64, color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: NexoColors.card,
                          valueColor:
                              const AlwaysStoppedAnimation(NexoColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'اضغط على الصخرة عشان تعدّن',
                      style: TextStyle(
                          color: NexoColors.textSecondary, fontSize: 12),
                    ),
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
