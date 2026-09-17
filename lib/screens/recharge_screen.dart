import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/economy_service.dart';
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
          trailing: ElevatedButton(onPressed: () {
            context.read<EconomyService>().addGems(p['gems'] as int);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة ' + (p['gems'] as int).toString() + ' Gems (Prototype Wallet)')));
          }, child: Text('\$' + (p['price'] as String))),
        ))),
        const SizedBox(height: 14),
        const Text('العملة الوحيدة للمستخدم: Gems. أي أسماء Tickets قديمة ليست نظام عملة ثاني.', style: TextStyle(color: NexoColors.textSecondary), textAlign: TextAlign.center),
      ],
    ),
  );
}