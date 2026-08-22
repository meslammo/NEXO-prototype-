import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import '../services/energy_service.dart';
import '../screens/mining_screen.dart';

/// دالة مساعدة تستخدمها قبل أي زرار "بدء مكالمة صوت/فيديو" في أي شاشة.
/// لو الطاقة كفاية بترجع true وتقدر تكمل فتح المكالمة عادي.
/// لو مش كفاية، بتفتح Dialog يوجه المستخدم للتعدين وترجع false.
Future<bool> ensureEnergyForCall(BuildContext context, {required bool isVideo}) async {
  final ok = isVideo
      ? EnergyService.instance.canStartVideo()
      : EnergyService.instance.canStartVoice();

  if (ok) return true;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: NexoColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.battery_alert, color: Color(0xFFFF4D4D)),
          SizedBox(width: 8),
          Text('الطاقة خلصت', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
      content: const Text(
        'محتاج تعدّن أو تكمل مهامك اليومية عشان تجمع طاقة وتقدر تفتح المكالمة.',
        style: TextStyle(color: NexoColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لاحقًا', style: TextStyle(color: NexoColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: NexoColors.primary),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MiningScreen()));
          },
          child: const Text('يلا نعدّن', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  return false;
}

/// يتنادى كل دقيقة أثناء مكالمة شغالة (مثلاً جوه Timer.periodic).
/// بيرجع false لو الطاقة خلصت عشان تقفل المكالمة تلقائي من مكان استدعائها.
bool tickCallEnergy({required bool isVideo}) {
  return isVideo
      ? EnergyService.instance.tickVideoMinute()
      : EnergyService.instance.tickVoiceMinute();
}
