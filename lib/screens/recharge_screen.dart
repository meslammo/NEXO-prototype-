import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';

class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

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
                      'الشحن والعروض',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recharge column
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '(Recharge)',
                            style: TextStyle(color: NexoColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          _ticketPack(
                            tickets: 500,
                            price: '\$4.99',
                            bonus: '+50 Bonus',
                            color: const Color(0xFFFFB300),
                          ),
                          const SizedBox(height: 12),
                          _ticketPack(
                            tickets: 1200,
                            price: '\$9.99',
                            bonus: '+200 Bonus',
                            color: const Color(0xFFFF9100),
                          ),
                          const SizedBox(height: 12),
                          _ticketPack(
                            tickets: 3000,
                            price: '\$19.99',
                            bonus: '+600 Bonus',
                            color: const Color(0xFFFF6D00),
                          ),
                          const SizedBox(height: 12),
                          _ticketPack(
                            tickets: 8000,
                            price: '\$49.99',
                            bonus: '+2,000 Bonus',
                            color: const Color(0xFFE65100),
                            isPopular: true,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'رسوم الشحن 5% من كل عملية شحن',
                            style: TextStyle(color: NexoColors.textSecondary, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Offers / VIP column
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '(Offers)',
                            style: TextStyle(color: NexoColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          _vipCard(
                            title: 'VIP',
                            subtitle: 'عضوية شهرية',
                            price: '\$4.99',
                            benefits: '+10% مميزات نقاط',
                            color: const Color(0xFFFFD700),
                            icon: Icons.workspace_premium,
                          ),
                          const SizedBox(height: 12),
                          _vipCard(
                            title: 'VIP Plus',
                            subtitle: 'شهرية',
                            price: '\$9.99',
                            benefits: '+20% مميزات إضافية نقاط',
                            color: const Color(0xFF7B5CFF),
                            icon: Icons.diamond,
                          ),
                          const SizedBox(height: 12),
                          _vipCard(
                            title: 'VIP Premium',
                            subtitle: 'شهرية',
                            price: '\$19.99',
                            benefits: '+30% كل المميزات نقاط',
                            color: const Color(0xFF00E5FF),
                            icon: Icons.diamond,
                            isBest: true,
                          ),
                        ],
                      ),
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

  Widget _ticketPack({
    required int tickets,
    required String price,
    required String bonus,
    required Color color,
    bool isPopular = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NexoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'الأكثر مبيعًا',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          Icon(Icons.confirmation_number_rounded, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            '$tickets Tickets',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            bonus,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _vipCard({
    required String title,
    required String subtitle,
    required String price,
    required String benefits,
    required Color color,
    required IconData icon,
    bool isBest = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NexoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isBest)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'الأفضل قيمة',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            benefits,
            style: TextStyle(color: color.withOpacity(0.85), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
