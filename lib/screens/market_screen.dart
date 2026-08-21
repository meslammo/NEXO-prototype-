import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/economy_service.dart';
import '../services/trade_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TradeService _tradeService = TradeService();

  final items = [
    {'name': '⛏ Pickaxe', 'rarity': 'Common', 'price': 100},
    {'name': '💎 Rare Ore', 'rarity': 'Rare', 'price': 500},
    {'name': '👑 Legendary Ore', 'rarity': 'Legendary', 'price': 2000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _buyItem(int index, BuildContext context) {
    final economy = Provider.of<EconomyService>(context, listen: false);
    final price = items[index]['price'] as int;

    if (economy.spendTickets(price)) {
      economy.addItem(items[index]['name']!, 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Purchased ${items[index]['name']}'),
          backgroundColor: const Color(0xFF00d4ff),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Not enough tickets!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Market'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0a1929),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00d4ff),
          tabs: const [
            Tab(text: 'Shop'),
            Tab(text: 'Trade'),
            Tab(text: 'Crafting'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Shop Tab
          ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => _buyItem(index, context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132f4c),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF7c3aed), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[index]['name'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7c3aed),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(items[index]['rarity'] as String,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00d4ff),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                            '🎫 ${items[index]['price']}',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Trade Tab
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🤝 Trade Hub',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                      'Trade directly with other players\nor use the marketplace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF90a4ae), fontSize: 12)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trading hub coming soon')),
                    ),
                    child: const Text('Start Trading'),
                  ),
                ],
              ),
            ),
          ),
          // Crafting Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔨 Crafting',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Combine materials to create items',
                    style: TextStyle(
                        color: Color(0xFF90a4ae), fontSize: 12)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Open Crafting'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
