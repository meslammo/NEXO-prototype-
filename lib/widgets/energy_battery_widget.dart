import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import '../models/energy_model.dart';
import '../services/energy_service.dart';

/// أيقونة بطارية خضراء بصاعقة صفراء تعبّر عن رصيد الطاقة،
/// بتتحدث تلقائيًا لما الرصيد يتغير (عن طريق EnergyService.instance.stream).
///
/// استخدامها في أي مكان (مثلاً في الـ AppBar أو أعلى شاشة الشات):
///   const EnergyBatteryWidget()
class EnergyBatteryWidget extends StatelessWidget {
  final bool showLabel;
  final VoidCallback? onTap;

  const EnergyBatteryWidget({
    super.key,
    this.showLabel = true,
    this.onTap,
  });

  Color _colorForPercent(double percent) {
    if (percent > 0.6) return NexoColors.success; // أخضر
    if (percent > 0.3) return NexoColors.ticket; // أصفر/برتقالي
    return const Color(0xFFFF4D4D); // أحمر تحذيري
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EnergyModel>(
      stream: EnergyService.instance.stream,
      initialData: EnergyService.instance.current,
      builder: (context, snapshot) {
        final energy = snapshot.data ?? EnergyModel.initial();
        final percent = energy.percent;
        final color = _colorForPercent(percent);
        final isLow = energy.isLow;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: NexoColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
              boxShadow: isLow
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 26,
                  height: 16,
                  child: CustomPaint(
                    painter: _BatteryPainter(percent: percent, color: color),
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${energy.current.toInt()}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// رسم شكل البطارية + مستوى الشحن + صاعقة صفراء ثابتة فوقها
class _BatteryPainter extends CustomPainter {
  final double percent;
  final Color color;

  _BatteryPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyWidth = size.width - 3; // نسيب مساحة لطرف البطارية الصغير
    final bodyRect = Rect.fromLTWH(0, 0, bodyWidth, size.height);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(3));

    // إطار البطارية
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(bodyRRect, borderPaint);

    // طرف البطارية الصغير (الطرف الموجب)
    final tipPaint = Paint()..color = Colors.white.withOpacity(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyWidth, size.height * 0.28, 3, size.height * 0.44),
        const Radius.circular(1),
      ),
      tipPaint,
    );

    // مستوى الشحن (بيقل من اليمين لليسار عشان يشتغل صح مع RTL)
    final fillWidth = (bodyWidth - 3) * percent.clamp(0.0, 1.0);
    if (fillWidth > 0) {
      final fillPaint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bodyWidth - 1.5 - fillWidth, 1.5, fillWidth, size.height - 3),
          const Radius.circular(1.5),
        ),
        fillPaint,
      );
    }

    // الصاعقة الصفراء فوق البطارية
    final boltPaint = Paint()..color = const Color(0xFFFFEB3B);
    final path = Path();
    final cx = bodyWidth / 2;
    final cy = size.height / 2;
    path.moveTo(cx + 2, 0);
    path.lineTo(cx - 3, cy + 1);
    path.lineTo(cx, cy + 1);
    path.lineTo(cx - 2, size.height);
    path.lineTo(cx + 3, cy - 1);
    path.lineTo(cx, cy - 1);
    path.close();
    canvas.drawPath(path, boltPaint);
    final boltBorder = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawPath(path, boltBorder);
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}
