import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/economy_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../theme/nexo_theme.dart';

class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

  static const packs = [
    {'id': 'starter_499', 'gems': 500, 'price': '4.99', 'bonus': '+50'},
    {'id': 'plus_999', 'gems': 1200, 'price': '9.99', 'bonus': '+200'},
    {'id': 'pro_1999', 'gems': 3000, 'price': '19.99', 'bonus': '+600'},
    {'id': 'ultra_24999', 'gems': 8000, 'price': '49.99', 'bonus': '+2000'},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NexoColors.background,
    appBar: AppBar(backgroundColor: NexoColors.background, title: const Text('Gems / VIP'), centerTitle: true, leading: const BackButton(color: Colors.white)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Consumer<EconomyService>(builder: (_, e, __) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: NexoColors.primary.withOpacity(.28))), child: Row(children: [const Icon(Icons.diamond_rounded, color: NexoColors.primary, size: 30), const SizedBox(width: 10), const Text('رصيدك', style: TextStyle(color: Colors.white70)), const Spacer(), Text(e.gems.toString() + ' Gems', style: const TextStyle(color: NexoColors.primary, fontSize: 18, fontWeight: FontWeight.bold))]))),
        const SizedBox(height: 14),
        ...packs.map((p) => Card(color: NexoColors.card, child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.diamond_rounded)),
          title: Text((p['gems'] as int).toString() + ' Gems', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text((p['id'] as String) + ' · Bonus ' + (p['bonus'] as String) + ' Gems', style: const TextStyle(color: NexoColors.textSecondary)),
          trailing: ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthService>();
              if (NexoApiConfig.configured && auth.online) {
                try {
                  final api = context.read<ApiClient>();
                  final result = await api.postJson('/payments/create-order', {
                    'packageId': p['id'],
                  });
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: NexoColors.card,
                      title: const Text('تم إنشاء طلب الدفع', style: TextStyle(color: Colors.white)),
                      content: Text(
                        'Order: ${result['orderId']}\\nProvider: ${result['provider']}\\nالرصيد لن يزيد إلا بعد تأكيد مزود الدفع من السيرفر.',
                        style: const TextStyle(color: NexoColors.textSecondary),
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))],
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تعذر إنشاء طلب الدفع: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
                return;
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الدفع الحقيقي يحتاج ربط مزود دفع؛ لن أضيف Gems وهمية.')),
                );
              }
            },
            child: Text('\
        ))),
        const SizedBox(height: 14),
        const Text('العملة الوحيدة للمستخدم: Gems. الرصيد يُضاف فقط بعد تأكيد الدفع من السيرفر.', style: TextStyle(color: NexoColors.textSecondary), textAlign: TextAlign.center),
      ],
    ),
  );
} + (p['price'] as String)),
          ),
        ))),
        const SizedBox(height: 14),
        const Text('العملة الوحيدة للمستخدم: Gems. أي أسماء Tickets قديمة ليست نظام عملة ثاني.', style: TextStyle(color: NexoColors.textSecondary), textAlign: TextAlign.center),
      ],
    ),
  );
}