import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ProfileCard extends StatelessWidget {
  final UserModel user;

  const ProfileCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF132f4c),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00d4ff), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00d4ff).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF00d4ff),
                child: Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                        color: Color(int.parse(
                            '0xFF${user.nameColor.replaceFirst('#', '')}')),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: user.glow
                            ? [
                                Shadow(
                                  color: Color(int.parse(
                                      '0xFF${user.nameColor.replaceFirst('#', '')}')),
                                  blurRadius: 8,
                                )
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7c3aed),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '👑 ${user.vipLevel}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lv. ${user.level}',
                          style: const TextStyle(
                            color: Color(0xFF90a4ae),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (user.experience % 10000) / 10000,
              minHeight: 8,
              backgroundColor: const Color(0xFF0a1929),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00d4ff),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP: ${user.experience}',
                style: const TextStyle(
                  color: Color(0xFF90a4ae),
                  fontSize: 11,
                ),
              ),
              Text(
                'NEXO Score: ${user.nexoScore}',
                style: const TextStyle(
                  color: Color(0xFF00d4ff),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
