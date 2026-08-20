import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
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

  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatar,
    this.level = 1,
    this.experience = 0,
    this.nexoScore = 0,
    this.socialPoints = 0,
    this.energy = 100,
    this.tickets = 1250,
    this.vipLevel = 'Base',
    this.nameColor = '#54d6ff',
    this.glow = true,
    this.reputation = 0,
    this.badges = const [],
    this.achievements = const [],
    required this.createdAt,
    required this.lastActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
