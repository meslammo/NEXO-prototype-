import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/games_screen.dart';
import 'screens/market_screen.dart';
import 'screens/profile_screen.dart';
import 'services/nexo_service.dart';
import 'services/social_engine.dart';
import 'services/economy_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexoApp());
}

class NexoApp extends StatelessWidget {
  const NexoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NexoService()),
        ChangeNotifierProvider(create: (_) => SocialEngine()),
        ChangeNotifierProvider(create: (_) => EconomyService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NEXO',
        theme: AppTheme.darkTheme,
        home: const MainApp(),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const GamesScreen(),
    const MarketScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0a1929),
        selectedItemColor: const Color(0xFF00d4ff),
        unselectedItemColor: const Color(0xFF546e7a),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: 'Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
