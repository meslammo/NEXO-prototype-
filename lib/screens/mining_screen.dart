import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/nexo_theme.dart';
import '../services/economy_service.dart';

/// Mining remains a Games subsystem, not a primary navigation tab.
class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen> with SingleTickerProviderStateMixin {
  int _hits = 0;
  static const _hitsNeeded = 4;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
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
      context.read<EconomyService>().addEnergy(2);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('+2 Energy · Mining reward')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EconomyService>().energy;
    final progress = (_hits / _hitsNeeded).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(title: const Text('⛏ Mining'), backgroundColor: NexoColors.background),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.bolt_rounded, color: NexoColors.gold),
              const SizedBox(width: 6),
              Text('$energy/100 Energy', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final sign = (_shakeController.value * 30).round().isEven ? 1.0 : -1.0;
                      final offset = (1 - _shakeController.value) * 4 * sign;
                      return Transform.translate(offset: Offset(_shakeController.isAnimating ? offset : 0, 0), child: child);
                    },
                    child: GestureDetector(
                      onTap: _onTapRock,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [NexoColors.primary.withOpacity(0.5), NexoColors.card]),
                          boxShadow: [BoxShadow(color: NexoColors.primary.withOpacity(0.35), blurRadius: 25)],
                        ),
                        child: const Center(child: Icon(Icons.diamond, size: 64, color: Colors.white70)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: NexoColors.card,
                      valueColor: const AlwaysStoppedAnimation(NexoColors.gold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('اضغط 4 مرات لتحصل على مكافأة الطاقة', style: TextStyle(color: NexoColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
