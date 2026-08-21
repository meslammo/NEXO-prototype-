import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String avatar;
  final int level;
  final int experience;
  final int nexoScore;
  final int socialPoints;
  final int energy;
  final int tickets;
  final String vipLevel;
  final String nameColor;
  final bool glow;
  final int reputation;
  final List<String> badges;
  final List<String> achievements;
  final DateTime createdAt;
  final DateTime lastActive;

  const UserModel({required this.id, required this.username, required this.displayName, required this.avatar, this.level = 1, this.experience = 0, this.nexoScore = 0, this.socialPoints = 0, this.energy = 100, this.tickets = 1250, this.vipLevel = 'Base', this.nameColor = '#54d6ff', this.glow = true, this.reputation = 0, this.badges = const [], this.achievements = const [], required this.createdAt, required this.lastActive});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String, username: json['username'] as String, displayName: json['displayName'] as String, avatar: json['avatar'] as String,
    level: (json['level'] as num?)?.toInt() ?? 1, experience: (json['experience'] as num?)?.toInt() ?? 0, nexoScore: (json['nexoScore'] as num?)?.toInt() ?? 0, socialPoints: (json['socialPoints'] as num?)?.toInt() ?? 0, energy: (json['energy'] as num?)?.toInt() ?? 100, tickets: (json['tickets'] as num?)?.toInt() ?? 1250,
    vipLevel: json['vipLevel'] as String? ?? 'Base', nameColor: json['nameColor'] as String? ?? '#54d6ff', glow: json['glow'] as bool? ?? true, reputation: (json['reputation'] as num?)?.toInt() ?? 0,
    badges: List<String>.from(json['badges'] as List? ?? const []), achievements: List<String>.from(json['achievements'] as List? ?? const []), createdAt: DateTime.parse(json['createdAt'] as String), lastActive: DateTime.parse(json['lastActive'] as String),
  );

  Map<String, dynamic> toJson() => {'id': id, 'username': username, 'displayName': displayName, 'avatar': avatar, 'level': level, 'experience': experience, 'nexoScore': nexoScore, 'socialPoints': socialPoints, 'energy': energy, 'tickets': tickets, 'vipLevel': vipLevel, 'nameColor': nameColor, 'glow': glow, 'reputation': reputation, 'badges': badges, 'achievements': achievements, 'createdAt': createdAt.toIso8601String(), 'lastActive': lastActive.toIso8601String()};
}
