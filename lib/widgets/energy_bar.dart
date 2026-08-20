import 'package:flutter/material.dart';

class EnergyBar extends StatelessWidget {
  final int current;
  final int maximum;

  const EnergyBar({
    Key? key,
    required this.current,
    this.maximum = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = current / maximum;
    final color = percentage > 0.5
        ? const Color(0xFF00d4ff)
        : percentage > 0.25
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '⚡ Energy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$current/$maximum',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: const Color(0xFF0a1929),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
