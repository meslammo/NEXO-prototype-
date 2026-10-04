import 'package:flutter/material.dart';
import 'missions_screen.dart';

/// Compatibility wrapper.
/// The old screen was in-memory and contained the removed Craft mission.
/// NEXO now uses the real server-backed MissionsScreen for Daily/Tribe/VIP/SVIP.
class DailyMissionsScreen extends StatelessWidget {
  const DailyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) => const MissionsScreen();
}
