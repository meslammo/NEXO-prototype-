import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/nexo_theme.dart';
import 'models/nexo_catalog.dart';
import 'widgets/adaptive_scaffold.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/games_screen.dart';
import 'screens/our_club_screen.dart';
import 'screens/market_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/missions_screen.dart';
import 'services/energy_storage_service.dart';
import 'services/economy_service.dart';
import 'services/mining_service.dart';
import 'services/nexo_service.dart';
import 'services/social_engine.dart';
import 'services/power_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/realtime_service.dart';
import 'services/notification_service.dart';
import 'services/catalog_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnergyStorageService.loadOnStartup();
  final api = ApiClient();
  final auth = AuthService(api);
  await auth.initialize();
  final realtime = RealtimeService(api);
  final catalog = NexoCatalogService(api);
  await catalog.load();
  final notifications = NotificationService(api, realtime);
  final economy = EconomyService();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: NexoColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      ChangeNotifierProvider<AuthService>.value(value: auth),
      Provider<RealtimeService>.value(value: realtime),
      ChangeNotifierProvider<NexoCatalogService>.value(value: catalog),
      ChangeNotifierProvider<NotificationService>.value(value: notifications),
      ChangeNotifierProvider<EconomyService>.value(value: economy),
      ChangeNotifierProvider(create: (_) => MiningService()),
      ChangeNotifierProvider(create: (_) => NexoService()),
      ChangeNotifierProvider(create: (_) => SocialEngine()),
      ChangeNotifierProvider(create: (_) => PowerService()),
    ],
    child: const NexoApp(),
  ));
}

class NexoApp extends StatelessWidget {
  const NexoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
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
    builder: (c, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthService>();
    if (!a.initialized) {
      return const Scaffold(
        backgroundColor: NexoColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return a.online ? const OnlineShell() : const LoginScreen();
  }
}

class OnlineShell extends StatefulWidget {
  const OnlineShell({super.key});
  @override
  State<OnlineShell> createState() => _OnlineShellState();
}

class _OnlineShellState extends State<OnlineShell> {
  bool booted = false;

  Future<void> boot() async {
    if (booted) return;
    booted = true;
    try {
      final api = context.read<ApiClient>();
      try {
        await context.read<RealtimeService>().connect();
        await context.read<RealtimeService>().setPresence(true);
      } catch (_) {}
      try {
        await context.read<NotificationService>().initialize();
      } catch (_) {}

      final w = await api.getJson('/wallet');
      final i = await api.getJson('/inventory');

      // Live API may return a bare array; ApiClient wraps it as {data:[...]}.
      final raw = i['data'] ?? i;
      final map = <String, int>{};
      if (raw is List) {
        for (final e in raw.whereType<Map>()) {
          final id = (e['id'] ?? e['itemId'])?.toString();
          if (id == null || id.isEmpty) continue;
          map[id] = (e['quantity'] as num?)?.toInt() ?? 0;
        }
      }
      context.read<EconomyService>().hydrateFromServer(
        gems: (w['gems'] as num?)?.toInt() ?? 0,
        energy: (w['energy'] as num?)?.toInt() ?? 50,
        inventory: map,
      );

      final pRaw = await api.getJson('/profile/equipped');
      final equipped = pRaw['data'] ?? pRaw;
      String? activeStyle;
      if (equipped is List) {
        for (final e in equipped.whereType<Map>()) {
          final slot = e['slot']?.toString();
          if (slot == 'name_color' || slot == 'power') {
            activeStyle = e['itemId']?.toString();
            break;
          }
        }
      }

      final power = context.read<PowerService>();
      power.syncCatalog(context.read<NexoCatalogService>().byType(NexoItemType.power));
      power.syncInventory(map.keys.where((id) => id.startsWith('power_')).toSet());
      if (activeStyle != null && activeStyle.isNotEmpty) {
        final styleItem = context.read<NexoCatalogService>().getById(activeStyle);
        if (styleItem?.type == NexoItemType.power) power.setActivePower(activeStyle);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    boot();
  }

  @override
  Widget build(BuildContext context) => const MainShell();
}

class StartupMissionsGate extends StatefulWidget {
  final Widget child;
  const StartupMissionsGate({super.key, required this.child});
  @override
  State<StartupMissionsGate> createState() => _StartupMissionsGateState();
}

class _StartupMissionsGateState extends State<StartupMissionsGate> {
  bool opened = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!opened) {
      opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MissionsScreen()),
          );
        }
      });
    }
  }
  @override
  Widget build(BuildContext context) => widget.child;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  // Social-first NEXO order: Home → Chat → Tribe → Store → Profile.
  // Games are opened inside live rooms and from Home.
  static const screens = <Widget>[
    HomeScreen(),
    ChatScreen(),
    OurClubScreen(),
    MarketScreen(),
    ProfileScreen(),
  ];
  static const destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
    NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'الشات'),
    NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Tribe'),
    NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded), label: 'السوق'),
    NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'الملف'),
  ];

  @override
  Widget build(BuildContext context) => AdaptiveScaffold(
    selectedIndex: index,
    onDestinationSelected: (i) => setState(() => index = i),
    destinations: destinations,
    body: IndexedStack(index: index, children: screens),
  );
}