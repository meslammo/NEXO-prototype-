import 'package:flutter/foundation.dart';

class SocialEngine extends ChangeNotifier {
  List<Map<String, dynamic>> _activities = [];
  int _totalNexoScore = 0;
  Map<String, int> _activityWeights = {
    'chat': 10,
    'voice_call': 25,
    'video_call': 30,
    'game_win': 50,
    'mining': 15,
    'trade': 20,
    'emoji_use': 5,
    'gift_send': 15,
  };

  List<Map<String, dynamic>> get activities => _activities;
  int get totalNexoScore => _totalNexoScore;

  void logActivity(String type, {int? points}) {
    final weight = _activityWeights[type] ?? 0;
    final finalPoints = points ?? weight;

    _activities.add({
      'type': type,
      'points': finalPoints,
      'timestamp': DateTime.now(),
    });

    _totalNexoScore += finalPoints;
    notifyListeners();
  }

  void logChatMessage() => logActivity('chat');
  void logVoiceCall() => logActivity('voice_call');
  void logVideoCall() => logActivity('video_call');
  void logGameWin(int reward) => logActivity('game_win', points: reward);
  void logMining(int reward) => logActivity('mining', points: reward);
  void logTrade() => logActivity('trade');
  void logEmojiUse() => logActivity('emoji_use');
  void logGiftSend() => logActivity('gift_send');

  int getDailyScore() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _activities
        .where((a) => (a['timestamp'] as DateTime).isAfter(today))
        .fold(0, (sum, a) => sum + (a['points'] as int));
  }

  int getWeeklyScore() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    return _activities
        .where((a) => (a['timestamp'] as DateTime).isAfter(weekAgo))
        .fold(0, (sum, a) => sum + (a['points'] as int));
  }

  void reset() {
    _activities.clear();
    _totalNexoScore = 0;
    notifyListeners();
  }
}
