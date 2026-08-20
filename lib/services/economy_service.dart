import 'package:flutter/foundation.dart';

class EconomyService extends ChangeNotifier {
  int _energy = 100;
  int _tickets = 12450;
  int _socialPoints = 5420;
  Map<String, int> _inventory = {};

  int get energy => _energy;
  int get tickets => _tickets;
  int get socialPoints => _socialPoints;
  Map<String, int> get inventory => _inventory;

  EconomyService() {
    _initializeInventory();
  }

  void _initializeInventory() {
    _inventory = {
      'crown_shine': 2,
      'galaxy_aura': 1,
      'neon_heart': 3,
      'shadow_flame': 1,
      'rainbow_ticket': 5,
      'diamond_glow': 1,
      'fire_wings': 1,
    };
  }

  bool spendEnergy(int amount) {
    if (_energy < amount) return false;
    _energy -= amount;
    notifyListeners();
    return true;
  }

  void addEnergy(int amount) {
    _energy = (_energy + amount).clamp(0, 200);
    notifyListeners();
  }

  bool spendTickets(int amount) {
    if (_tickets < amount) return false;
    _tickets -= amount;
    notifyListeners();
    return true;
  }

  void addTickets(int amount) {
    _tickets += amount;
    notifyListeners();
  }

  bool spendSocialPoints(int amount) {
    if (_socialPoints < amount) return false;
    _socialPoints -= amount;
    notifyListeners();
    return true;
  }

  void addSocialPoints(int amount) {
    _socialPoints += amount;
    notifyListeners();
  }

  void addItem(String itemId, int quantity) {
    _inventory[itemId] = (_inventory[itemId] ?? 0) + quantity;
    notifyListeners();
  }

  bool removeItem(String itemId, int quantity) {
    if ((_inventory[itemId] ?? 0) < quantity) return false;
    _inventory[itemId] = (_inventory[itemId] ?? 0) - quantity;
    if (_inventory[itemId] == 0) _inventory.remove(itemId);
    notifyListeners();
    return true;
  }

  void resetDaily() {
    _energy = 100;
    notifyListeners();
  }
}
