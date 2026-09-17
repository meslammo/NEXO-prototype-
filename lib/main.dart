import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/nexo_theme.dart';
import 'widgets/adaptive_scaffold.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/craft_screen.dart';
import 'screens/more_screen.dart';
import 'services/energy_storage_service.dart';
import 'services/economy_service.dart';
import 'services/mining_service.dart';
import 'services/nexo_service.dart';
import 'services/social_engine.dart';
import 'services/trade_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnergyStorageService.loadOnStartup();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: NexoColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EconomyService()),
        ChangeNotifierProvider(create: (_) => MiningService()),
        ChangeNotifierProvider(create: (_) => NexoService()),
        ChangeNotifierProvider(create: (_) => SocialEngine()),
        ChangeNotifierProvider(create: (_) => TradeService()),
      ],
      child: const NexoApp(),
    ),
  );
}

class NexoApp extends StatelessWidget {
  const NexoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXO',
      debugShowCheckedModeBanner: false,
      theme: NexoTheme.darkTheme,
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
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

  static const _screens = <Widget>[
    HomeScreen(),
    ChatScreen(),
    TradeScreen(),
    CraftScreen(),
    MoreScreen(),
  ];

  static const _destinations = <NavigationDestination>[
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
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: _destinations,
      body: IndexedStack(index: _selectedIndex, children: _screens),
    );
  }
}
