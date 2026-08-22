import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';

class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<NavigationDestination> destinations;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 600) {
      // Phone → Bottom NavigationBar
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          backgroundColor: NexoColors.surface,
          indicatorColor: NexoColors.primary.withOpacity(0.25),
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      );
    }

    if (width < 1200) {
      // Tablet → NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: NexoColors.surface,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: NexoColors.primary),
              unselectedIconTheme: const IconThemeData(color: NexoColors.textSecondary),
              selectedLabelTextStyle: const TextStyle(color: NexoColors.primary, fontSize: 12),
              unselectedLabelTextStyle: const TextStyle(color: NexoColors.textSecondary, fontSize: 12),
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1, color: NexoColors.cardBorder),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Desktop → Extended NavigationRail
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            backgroundColor: NexoColors.surface,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            selectedIconTheme: const IconThemeData(color: NexoColors.primary),
            unselectedIconTheme: const IconThemeData(color: NexoColors.textSecondary),
            destinations: destinations
                .map((d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: NexoColors.cardBorder),
          Expanded(child: body),
        ],
      ),
    );
  }
}
