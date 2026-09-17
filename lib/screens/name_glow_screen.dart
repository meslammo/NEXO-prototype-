import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nexo_service.dart';
import '../theme/nexo_theme.dart';

class NameGlowScreen extends StatefulWidget {
  const NameGlowScreen({super.key});
  @override
  State<NameGlowScreen> createState() => _NameGlowScreenState();
}

class _NameGlowScreenState extends State<NameGlowScreen> {
  static const colors = [Color(0xFF3DDCFF), Color(0xFFF5C14A), Color(0xFFB44CFF), Color(0xFFFF6B9D), Color(0xFF3EE08A), Color(0xFF6EB6FF)];
  Color selected = const Color(0xFF3DDCFF);
  bool glow = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<NexoService>().currentUser;
    selected = _parseColor(user.nameColor);
    glow = user.glow;
  }

  Color _parseColor(String value) {
    try { return Color(int.parse('0xFF' + value.replaceFirst('#', ''))); } catch (_) { return colors.first; }
  }

  String _hex(Color c) => '#' + c.value.toRadixString(16).substring(2).toUpperCase();

  Future<void> _save() async {
    await context.read<NexoService>().updateUserProfile(nameColor: _hex(selected), glow: glow);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Font Colour اتطبق على الاسم والـChat.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NexoColors.background,
    appBar: AppBar(backgroundColor: NexoColors.background, title: const Text('Font Colour'), centerTitle: true, leading: const BackButton(color: Colors.white)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
          decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected.withOpacity(.4))),
          child: Column(children: [
            Text('NEXO_KING', style: TextStyle(color: selected, fontSize: 30, fontWeight: FontWeight.w900, shadows: glow ? [Shadow(color: selected, blurRadius: 14), Shadow(color: selected.withOpacity(.45), blurRadius: 30)] : null)),
            const SizedBox(height: 8),
            const Text('ده نفس الـFont Colour اللي بيظهر على الاسم داخل Chat.', style: TextStyle(color: NexoColors.textSecondary), textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('اختيار اللون', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 14, runSpacing: 14, children: colors.map((c) => GestureDetector(
          onTap: () => setState(() => selected = c),
          child: Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: c, border: Border.all(color: selected.value == c.value ? Colors.white : Colors.transparent, width: 3), boxShadow: [BoxShadow(color: c.withOpacity(.35), blurRadius: 12)])),
        )).toList()),
        const SizedBox(height: 20),
        SwitchListTile(value: glow, onChanged: (v) => setState(() => glow = v), activeColor: selected, title: const Text('Glow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: const Text('وهج الاسم في Profile وChat', style: TextStyle(color: NexoColors.textSecondary))),
        const SizedBox(height: 18),
        SizedBox(height: 52, child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.check_circle_outline), label: const Text('حفظ Font Colour'))),
      ],
    ),
  );
}