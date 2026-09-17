import 'package:flutter/foundation.dart';

class EconomyService extends ChangeNotifier {
  static const int maxEnergy = 100;
  static const int freeDailyEnergy = 50;
  static const int energyPer100Gems = 100;
  static const int gemsPer100Energy = 25;

  int _energy = freeDailyEnergy;
  int _gems = 12450;
  final Map<String, int> _inventory = {};

  int get energy => _energy;
  int get gems => _gems;
  Map<String, int> get inventory => Map.unmodifiable(_inventory);

  // Legacy aliases only. Gems هي العملة الوحيدة الظاهرة.
  int get tickets => _gems;

  EconomyService() {
    _inventory.addAll({
      'crown-shine': 2,
      'galaxy-aura': 1,
      'neon-heart': 3,
      'shadow-flame': 1,
      'diamond-glow': 1,
      'fire-wings': 1,
      'name-glow': 1,
      'vip-emblem': 1,
    });
  }

  bool spendEnergy(int amount) {
    if (amount <= 0 || _energy < amount) return false;
    _energy -= amount;
    notifyListeners();
    return true;
  }

  void addEnergy(int amount) {
    if (amount <= 0) return;
    _energy = (_energy + amount).clamp(0, maxEnergy);
    notifyListeners();
  }

  bool spendGems(int amount) {
    if (amount <= 0 || _gems < amount) return false;
    _gems -= amount;
    notifyListeners();
    return true;
  }

  void addGems(int amount) {
    if (amount <= 0) return;
    _gems += amount;
    notifyListeners();
  }

  bool spendTickets(int amount) => spendGems(amount);
  void addTickets(int amount) => addGems(amount);

  void addItem(String itemId, int quantity) {
    if (quantity <= 0) return;
    _inventory[itemId] = (_inventory[itemId] ?? 0) + quantity;
    notifyListeners();
  }

  bool removeItem(String itemId, int quantity) {
    if (quantity <= 0 || (_inventory[itemId] ?? 0) < quantity) return false;
    _inventory[itemId] = (_inventory[itemId] ?? 0) - quantity;
    if (_inventory[itemId] == 0) _inventory.remove(itemId);
    notifyListeners();
    return true;
  }

  int convertEnergyToGems() {
    if (_energy < energyPer100Gems) return 0;
    _energy -= energyPer100Gems;
    _gems += gemsPer100Energy;
    notifyListeners();
    return gemsPer100Energy;
  }

  void resetDaily() {
    _energy = freeDailyEnergy;
    notifyListeners();
  }

  void hydrateFromServer({required int gems, required int energy, Map<String,int>? inventory}) {
    _gems = gems;
    _energy = energy.clamp(0, maxEnergy);
    if (inventory != null) {
      _inventory
        ..clear()
        ..addAll(inventory);
    }
    notifyListeners();
  }

  void setGems(int gems) {
    _gems = gems < 0 ? 0 : gems;
    notifyListeners();
  }

  void setEnergy(int energy) {
    _energy = energy.clamp(0, maxEnergy);
    notifyListeners();
  }

  void replaceInventory(Map<String,int> items) {
    _inventory
      ..clear()
      ..addAll(items);
    notifyListeners();
  }
}