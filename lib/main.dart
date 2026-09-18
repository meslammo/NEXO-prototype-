import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/nexo_theme.dart';
import 'widgets/adaptive_scaffold.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/games_screen.dart';
import 'screens/market_screen.dart';
import 'screens/profile_screen.dart';
import 'services/energy_storage_service.dart';
import 'services/economy_service.dart';
import 'services/mining_service.dart';
import 'services/nexo_service.dart';
import 'services/social_engine.dart';
import 'services/trade_service.dart';
import 'services/power_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/realtime_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnergyStorageService.loadOnStartup();

  final apiClient = ApiClient();
  final authService = AuthService(apiClient);
  await authService.initialize();
  final realtimeService = RealtimeService(apiClient);
  await realtimeService.connect();
  await realtimeService.setPresence(true);

  final notificationService = NotificationService(apiClient, realtimeService);
  if (authService.online) {
    await notificationService.initialize();
  }

  final economyService = EconomyService();
  if (authService.online) {
    try {
      final wallet = await apiClient.getJson('/wallet');
      final inventoryResponse = await apiClient.getJson('/inventory');
      final rows = inventoryResponse['data'];
      final inventory = <String, int>{};
      if (rows is List) {
        for (final row in rows) {
          if (row is Map && row['id'] != null) {
            inventory[row['id'].toString()] = (row['quantity'] as num?)?.toInt() ?? 0;
          }
        }
      }
      economyService.hydrateFromServer(
        gems: (wallet['gems'] as num?)?.toInt() ?? economyService.gems,
        energy: (wallet['energy'] as num?)?.toInt() ?? economyService.energy,
        inventory: inventory,
      );
      try {
        final daily = await apiClient.postJson('/economy/energy/daily-claim', {});
        if (daily['energy'] != null) {
          economyService.setEnergy((daily['energy'] as num).toInt());
        }
      } catch (_) {}
    } catch (_) {}
  }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: NexoColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<RealtimeService>.value(value: realtimeService),
        ChangeNotifierProvider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<EconomyService>.value(value: economyService),
        ChangeNotifierProvider(create: (_) => MiningService()),
        ChangeNotifierProvider(create: (_) => NexoService()),
        ChangeNotifierProvider(create: (_) => SocialEngine()),
        ChangeNotifierProvider(create: (_) => TradeService()),
        ChangeNotifierProvider(create: (_) => PowerService()),
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
      supportedLocales: const [Locale('ar'), Locale('en')],
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
    GamesScreen(),
    MarketScreen(),
    ProfileScreen(),
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
      icon: Icon(Icons.sports_esports_outlined),
      selectedIcon: Icon(Icons.sports_esports_rounded),
      label: 'الألعاب',
    ),
    NavigationDestination(
      icon: Icon(Icons.storefront_outlined),
      selectedIcon: Icon(Icons.storefront_rounded),
      label: 'السوق',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'الملف',
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
