import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/nexo_theme.dart';
import 'widgets/adaptive_scaffold.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/craft_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/recharge_screen.dart';
import 'screens/more_screen.dart';
import 'services/energy_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnergyStorageService.loadOnStartup();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: NexoColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const NexoApp());
}

class NexoApp extends StatelessWidget {
  const NexoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXO',
      debugShowCheckedModeBanner: false,
      theme: NexoTheme.darkTheme,
      // Support Arabic RTL
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatScreen(),
    TradeScreen(),
    CraftScreen(),
    MoreScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'الرئيسية',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: 'الشات',
    ),
    NavigationDestination(
      icon: Icon(Icons.swap_horiz_outlined),
      selectedIcon: Icon(Icons.swap_horiz_rounded),
      label: 'التداول',
    ),
    NavigationDestination(
      icon: Icon(Icons.handyman_outlined),
      selectedIcon: Icon(Icons.handyman_rounded),
      label: 'التصنيع',
    ),
    NavigationDestination(
      icon: Icon(Icons.apps_outlined),
      selectedIcon: Icon(Icons.apps_rounded),
      label: 'المزيد',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: _destinations,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}
