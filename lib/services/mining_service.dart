import 'package:flutter/foundation.dart';

class MiningService extends ChangeNotifier {
  int _totalMined = 0;
  List<Map<String, dynamic>> _miningHistory = [];

  int get totalMined => _totalMined;
  List<Map<String, dynamic>> get miningHistory => _miningHistory;

  void minePrimary(int reward) {
    _totalMined += reward;
    _miningHistory.add({
      'type': 'primary',
      'reward': reward,
      'timestamp': DateTime.now(),
    });
    notifyListeners();
  }

  void mineRare(int reward) {
    _totalMined += reward * 2;
    _miningHistory.add({
      'type': 'rare',
      'reward': reward * 2,
      'timestamp': DateTime.now(),
    });
    notifyListeners();
  }

  void mineLegendary(int reward) {
    _totalMined += reward * 5;
    _miningHistory.add({
      'type': 'legendary',
      'reward': reward * 5,
      'timestamp': DateTime.now(),
    });
    notifyListeners();
  }
}
