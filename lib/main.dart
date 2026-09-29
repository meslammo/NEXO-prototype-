import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'services/frame_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnergyStorageService.loadOnStartup();
  final frameService = FrameService();
  await frameService.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: NexoColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => EconomyService()),
      ChangeNotifierProvider(create: (_) => MiningService()),
      ChangeNotifierProvider(create: (_) => NexoService()),
      ChangeNotifierProvider(create: (_) => SocialEngine()),
      ChangeNotifierProvider(create: (_) => TradeService()),
      ChangeNotifierProvider.value(value: frameService),
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
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const MainShell(),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [HomeScreen(),ChatScreen(),TradeScreen(),CraftScreen(),MoreScreen()];
  final List<NavigationDestination> _destinations = const [
    NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'الرئيسية'),
    NavigationDestination(icon:Icon(Icons.chat_bubble_outline),selectedIcon:Icon(Icons.chat_bubble_rounded),label:'الشات'),
    NavigationDestination(icon:Icon(Icons.swap_horiz_outlined),selectedIcon:Icon(Icons.swap_horiz_rounded),label:'التداول'),
    NavigationDestination(icon:Icon(Icons.handyman_outlined),selectedIcon:Icon(Icons.handyman_rounded),label:'التصنيع'),
    NavigationDestination(icon:Icon(Icons.apps_outlined),selectedIcon:Icon(Icons.apps_rounded),label:'المزيد'),
  ];
  @override Widget build(BuildContext context)=>AdaptiveScaffold(
    selectedIndex:_selectedIndex,
    onDestinationSelected:(i)=>setState(()=>_selectedIndex=i),
    destinations:_destinations,
    body:IndexedStack(index:_selectedIndex,children:_screens),
  );
}