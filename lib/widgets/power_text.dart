import 'package:flutter/material.dart';

/// NEXO Power visual layer.
/// Powers affect the username/message glyphs directly; there is intentionally no message bubble.
class NexoPowerText extends StatelessWidget {
  final String text;
  final String? powerId;
  final TextStyle? style;

  const NexoPowerText({
    super.key,
    required this.text,
    this.powerId,
    this.style,
  });

  _PowerVisual get _visual {
    switch (powerId) {
      case 'power_chat_spark':
        return const _PowerVisual(
          colors: [Color(0xFF54D6FF), Color(0xFFB44CFF)],
          shadows: [
            Shadow(color: Color(0xFF54D6FF), blurRadius: 7),
            Shadow(color: Color(0xFFB44CFF), blurRadius: 16),
            Shadow(color: Color(0x8054D6FF), blurRadius: 28),
          ],
        );
      case 'power_vip_aura':
        return const _PowerVisual(
          colors: [Color(0xFF54D6FF), Color(0xFF7B5CFF), Color(0xFFB44CFF)],
          shadows: [
            Shadow(color: Color(0xFF54D6FF), blurRadius: 8),
            Shadow(color: Color(0xFFB44CFF), blurRadius: 18),
            Shadow(color: Color(0x667B5CFF), blurRadius: 32),
          ],
        );
      case 'power_fire_wings':
        return const _PowerVisual(
          colors: [Color(0xFFFFD166), Color(0xFFFF7A3D), Color(0xFFFF4D6D)],
          shadows: [
            Shadow(color: Color(0xFFFF7A3D), blurRadius: 8),
            Shadow(color: Color(0xFFFF4D6D), blurRadius: 18),
            Shadow(color: Color(0x66FF7A3D), blurRadius: 32),
          ],
        );
      case 'power_mythic_crown':
        return const _PowerVisual(
          colors: [Color(0xFFFFD166), Color(0xFFFF6B9D), Color(0xFFB44CFF), Color(0xFF54D6FF)],
          shadows: [
            Shadow(color: Color(0xFFFFD166), blurRadius: 9),
            Shadow(color: Color(0xFFFF6B9D), blurRadius: 18),
            Shadow(color: Color(0xFFB44CFF), blurRadius: 30),
            Shadow(color: Color(0x6654D6FF), blurRadius: 40),
          ],
        );
      case 'power_glow_frame':
        return const _PowerVisual(
          colors: [Color(0xFF54D6FF)],
          shadows: [
            Shadow(color: Color(0xFF54D6FF), blurRadius: 7),
            Shadow(color: Color(0x8054D6FF), blurRadius: 18),
            Shadow(color: Color(0x4054D6FF), blurRadius: 30),
          ],
        );
      default:
        return const _PowerVisual(colors: [Colors.white], shadows: []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (powerId == null || powerId!.isEmpty) {
      return Text(text, style: style);
    }

    final visual = _visual;
    final merged = (style ?? const TextStyle()).copyWith(
      color: Colors.white,
      shadows: [
        ...?style?.shadows,
        ...visual.shadows,
      ],
    );

    if (visual.colors.length == 1) {
      return Text(text, style: merged.copyWith(color: visual.colors.first));
    }

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: visual.colors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(text, style: merged),
    );
  }
}

class _PowerVisual {
  final List<Color> colors;
  final List<Shadow> shadows;
  const _PowerVisual({required this.colors, required this.shadows});
}
