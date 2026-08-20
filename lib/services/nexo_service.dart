import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class NexoService extends ChangeNotifier {
  late UserModel _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NexoService() {
    _initializeUser();
  }

  void _initializeUser() {
    _currentUser = UserModel(
      id: '1',
      username: 'NEXO_KING',
      displayName: 'NEXO Player',
      avatar: 'assets/avatars/default.png',
      level: 12,
      experience: 45000,
      nexoScore: 8250,
      socialPoints: 5420,
      energy: 100,
      tickets: 12450,
      vipLevel: 'Premium',
      nameColor: '#54d6ff',
      glow: true,
      reputation: 850,
      badges: ['Founder', 'Active', 'VIP'],
      achievements: ['First Chat', 'Mining Master', 'Social Butterfly'],
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastActive: DateTime.now(),
    );
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? nameColor,
    bool? glow,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      _currentUser = UserModel(
        id: _currentUser.id,
        username: _currentUser.username,
        displayName: displayName ?? _currentUser.displayName,
        avatar: _currentUser.avatar,
        level: _currentUser.level,
        experience: _currentUser.experience,
        nexoScore: _currentUser.nexoScore,
        socialPoints: _currentUser.socialPoints,
        energy: _currentUser.energy,
        tickets: _currentUser.tickets,
        vipLevel: _currentUser.vipLevel,
        nameColor: nameColor ?? _currentUser.nameColor,
        glow: glow ?? _currentUser.glow,
        reputation: _currentUser.reputation,
        badges: _currentUser.badges,
        achievements: _currentUser.achievements,
        createdAt: _currentUser.createdAt,
        lastActive: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExperience(int amount) async {
    final newExp = _currentUser.experience + amount;
    final newLevel = _currentUser.level + (newExp ~/ 10000);

    _currentUser = UserModel(
      id: _currentUser.id,
      username: _currentUser.username,
      displayName: _currentUser.displayName,
      avatar: _currentUser.avatar,
      level: newLevel,
      experience: newExp,
      nexoScore: _currentUser.nexoScore,
      socialPoints: _currentUser.socialPoints,
      energy: _currentUser.energy,
      tickets: _currentUser.tickets,
      vipLevel: _currentUser.vipLevel,
      nameColor: _currentUser.nameColor,
      glow: _currentUser.glow,
      reputation: _currentUser.reputation,
      badges: _currentUser.badges,
      achievements: _currentUser.achievements,
      createdAt: _currentUser.createdAt,
      lastActive: DateTime.now(),
    );
    notifyListeners();
  }
}
