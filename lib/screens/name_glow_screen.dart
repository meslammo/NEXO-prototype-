import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';

class NameGlowScreen extends StatefulWidget {
  const NameGlowScreen({super.key});

  @override
  State<NameGlowScreen> createState() => _NameGlowScreenState();
}

class _NameGlowScreenState extends State<NameGlowScreen> {
  int currentStep = 0; // 0 = Step 1, 1 = Step 2
  Color selectedColor = const Color(0xFF7B5CFF);

  final List<Color> glowColors = [
    const Color(0xFFFF1744),
    const Color(0xFFFF9100),
    const Color(0xFFFFEA00),
    const Color(0xFF00E676),
    const Color(0xFF00E5FF),
    const Color(0xFF2979FF),
    const Color(0xFFD500F9),
    const Color(0xFFFF4081),
    const Color(0xFF7C4DFF),
    const Color(0xFFFF6E40),
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
                    onPressed: () {
                      if (currentStep == 1) {
                        setState(() => currentStep = 0);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      currentStep == 0 ? 'Name Glow - Step 1' : 'Name Glow - Step 2',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: currentStep == 0 ? _buildStep1() : _buildStep2(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ticket preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B5CFF), Color(0xFF00D4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: NexoColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Name Glow Ticket',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'تذكرة تغيير لون الاسم',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Required materials
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NexoColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NexoColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'عناصر التصنيع المطلوبة',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _materialChip(Icons.confirmation_number, '200/100', NexoColors.ticket),
                    _materialChip(Icons.diamond, '50/30', const Color(0xFF00E5FF)),
                    _materialChip(Icons.workspace_premium, '25/10', NexoColors.gold),
                    _materialChip(Icons.diamond, '15/5', const Color(0xFFE040FB)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cost
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NexoColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تكلفة التصنيع', style: TextStyle(color: NexoColors.textSecondary)),
                Row(
                  children: [
                    const Icon(Icons.confirmation_number, size: 18, color: NexoColors.ticket),
                    const SizedBox(width: 6),
                    const Text('300', style: TextStyle(color: NexoColors.ticket, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Craft button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => currentStep = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: NexoColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'تصنيع التذكرة',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'اختر لون الاسم',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Preview name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: NexoColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selectedColor.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                'NEXO_KING',
                style: TextStyle(
                  color: selectedColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: selectedColor.withOpacity(0.8), blurRadius: 16),
                    Shadow(color: selectedColor.withOpacity(0.4), blurRadius: 32),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Color picker
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: glowColors.map((color) {
              final isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => selectedColor = color),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12)]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Preview button
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: NexoColors.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('معاينة الاسم', style: TextStyle(color: Colors.white70)),
          ),

          const SizedBox(height: 28),

          // Use ticket button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [selectedColor, selectedColor.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تغيير لون الاسم بنجاح! ✨')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.confirmation_number, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'استخدام التذكرة  x1',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialChip(IconData icon, String text, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
