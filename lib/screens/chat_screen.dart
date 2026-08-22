import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import '../widgets/energy_battery_widget.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = [
      {'name': 'Shadoww', 'msg': 'مرحبا كيف حالك؟', 'time': '10:30 PM', 'unread': 2, 'online': true},
      {'name': 'GalaxyGirl', 'msg': 'تحب هذا الإيموجي 💜', 'time': '10:28 PM', 'unread': 1, 'online': true},
      {'name': 'Prince_X', 'msg': 'تم إرسال طلب تداول ؟', 'time': '10:26 PM', 'unread': 1, 'online': false},
      {'name': 'Ahmed', 'msg': 'شكرا لك!', 'time': '10:25 PM', 'unread': 0, 'online': false},
      {'name': 'M:Dark', 'msg': 'مرحبا!', 'time': '10:20 PM', 'unread': 0, 'online': false},
    ];

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  'الشات',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const EnergyBatteryWidget(),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.people_outline, color: Colors.white70),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث عن مستخدم...',
                hintStyle: const TextStyle(color: NexoColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: NexoColors.textSecondary),
                filled: true,
                fillColor: NexoColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Online avatars
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              itemBuilder: (context, i) {
                final names = ['Shadoww', 'GalaxyGirl', 'Prince_X', 'Ahmed'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: NexoColors.primary.withOpacity(0.3),
                            child: Text(names[i][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: NexoColors.background, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(names[i], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(color: NexoColors.cardBorder, height: 1),

          // Chat list
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final c = chats[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: NexoColors.primary.withOpacity(0.25),
                    child: Text(
                      (c['name'] as String)[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  title: Text(
                    c['name'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    c['msg'] as String,
                    style: const TextStyle(color: NexoColors.textSecondary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        c['time'] as String,
                        style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11),
                      ),
                      if ((c['unread'] as int) > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: NexoColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${c['unread']}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
