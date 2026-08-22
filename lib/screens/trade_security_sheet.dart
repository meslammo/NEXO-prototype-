import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';

/// Bottom sheet that explains trade security + app fee percentage
class TradeSecuritySheet extends StatelessWidget {
  final int itemValue;
  final double feePercent;
  final int feeAmount;
  final int totalReceive;

  const TradeSecuritySheet({
    super.key,
    required this.itemValue,
    this.feePercent = 5.0,
    required this.feeAmount,
    required this.totalReceive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NexoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: NexoColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          const Row(
            children: [
              Icon(Icons.shield_rounded, color: NexoColors.success, size: 28),
              SizedBox(width: 10),
              Text(
                'أمان التداول ونسبة التطبيق',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Security features
          _securityItem(
            icon: Icons.lock_rounded,
            title: 'صفقة مؤمنة (Escrow)',
            subtitle: 'العناصر تتحجز عند التطبيق لحد ما الطرفين يؤكدوا الاستلام',
          ),
          _securityItem(
            icon: Icons.verified_user_rounded,
            title: 'تحقق من الهوية',
            subtitle: 'كل الأطراف لازم يكون حسابهم مفعّل وفيه مستوى أمان كافي',
          ),
          _securityItem(
            icon: Icons.history_rounded,
            title: 'سجل كامل للصفقة',
            subtitle: 'كل تفاصيل التداول محفوظة ويمكن الرجوع ليها في أي وقت',
          ),
          _securityItem(
            icon: Icons.support_agent_rounded,
            title: 'دعم فني 24/7',
            subtitle: 'لو حصلت أي مشكلة فريق الدعم بيتدخل فورًا',
          ),

          const SizedBox(height: 16),
          const Divider(color: NexoColors.cardBorder),
          const SizedBox(height: 12),

          // Fee breakdown
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'تفاصيل نسبة التطبيق',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 12),

          _feeRow('قيمة العناصر', '$itemValue', NexoColors.ticket),
          _feeRow('نسبة التطبيق ($feePercent%)', '$feeAmount', Colors.redAccent),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NexoColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NexoColors.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المبلغ النهائي للمستلم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text('$totalReceive', style: const TextStyle(color: NexoColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.confirmation_number, size: 18, color: NexoColors.success),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'نسبة التطبيق ثابتة $feePercent% على كل صفقة تداول وتُخصم تلقائيًا لضمان استمرار الخدمة والأمان.',
            style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _securityItem({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NexoColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: NexoColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
          Row(
            children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 4),
              Icon(Icons.confirmation_number, size: 14, color: color),
            ],
          ),
        ],
      ),
    );
  }
}
