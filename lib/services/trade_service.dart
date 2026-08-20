import 'package:flutter/foundation.dart';
import '../models/item_model.dart';

class TradeService extends ChangeNotifier {
  List<Map<String, dynamic>> _tradeHistory = [];
  List<Map<String, dynamic>> _activeListings = [];

  List<Map<String, dynamic>> get tradeHistory => _tradeHistory;
  List<Map<String, dynamic>> get activeListings => _activeListings;

  void createListing(String itemId, String itemName, int price, int quantity) {
    _activeListings.add({
      'id': DateTime.now().toString(),
      'itemId': itemId,
      'itemName': itemName,
      'price': price,
      'quantity': quantity,
      'seller': 'NEXO_KING',
      'createdAt': DateTime.now(),
    });
    notifyListeners();
  }

  void buyItem(String listingId, int quantity) {
    final listing = _activeListings.firstWhere((l) => l['id'] == listingId);
    
    _tradeHistory.add({
      'type': 'buy',
      'itemName': listing['itemName'],
      'quantity': quantity,
      'price': listing['price'] * quantity,
      'timestamp': DateTime.now(),
    });

    listing['quantity'] -= quantity;
    if (listing['quantity'] <= 0) {
      _activeListings.removeWhere((l) => l['id'] == listingId);
    }
    notifyListeners();
  }

  void playerToPlayerTrade(String traderId, List<ItemModel> offeredItems, List<ItemModel> requestedItems) {
    _tradeHistory.add({
      'type': 'p2p_trade',
      'traderId': traderId,
      'offered': offeredItems.length,
      'requested': requestedItems.length,
      'timestamp': DateTime.now(),
    });
    notifyListeners();
  }
}
