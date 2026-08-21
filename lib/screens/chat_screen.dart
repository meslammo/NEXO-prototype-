import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> messages = [
    {'user': 'Shadow', 'message': 'مرحبا كيف حالك؟', 'time': '10:30 PM'},
    {'user': 'Galaxy Girl', 'message': 'هاي! كيف تمام؟', 'time': '10:28 PM'},
    {'user': 'Prince_X', 'message': 'تم إرسال لك دعوة لعبة', 'time': '10:26 PM'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Chat'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0a1929),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00d4ff),
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Rooms'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Friends Tab
          ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF132f4c),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF132f4c),
                      child: Text(msg['user']![0],
                          style: const TextStyle(color: Color(0xFF00d4ff))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg['user']!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(msg['message']!,
                              style: const TextStyle(
                                  color: Color(0xFF90a4ae), fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(msg['time']!,
                        style: const TextStyle(
                            color: Color(0xFF90a4ae), fontSize: 10)),
                  ],
                ),
              );
            },
          ),
          // Rooms Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⭐ VIP Rooms',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('VIP rooms coming soon')),
                  ),
                  child: const Text('Join VIP Room'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00d4ff),
        onPressed: () {},
        child: const Icon(Icons.message, color: Colors.black),
      ),
    );
  }
}
