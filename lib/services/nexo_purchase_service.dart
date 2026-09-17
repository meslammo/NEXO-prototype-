import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NexoPurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final StreamController<PurchaseDetails> _updates = StreamController<PurchaseDetails>.broadcast();
  final Map<String, ProductDetails> _products = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  SharedPreferences? _prefs;

  Stream<PurchaseDetails> get updates => _updates.stream;
  bool get isAvailable => _iap.isAvailable;
  bool hasProduct(String id) => _products.containsKey(id);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _subscription = _iap.purchaseStream.listen((list) {
      for (final purchase in list) {
        _updates.add(purchase);
      }
    });
    final available = await _iap.isAvailable();
    if (!available) return;
    const ids = {
      'starter_499',
      'plus_999',
      'pro_1999',
      'ultra_24999',
    };
    final response = await _iap.queryProductDetails(ids);
    _products
      ..clear()
      ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
  }

  Future<void> buy(String productId) async {
    final product = _products[productId];
    if (product == null) throw StateError('Product not found: $productId');
    final param = PurchaseParam(productDetails: product);
    final started = await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
    if (!started) throw StateError('Store did not start purchase');
  }

  Future<void> savePendingOrder(String productId, String orderId) async {
    await _prefs?.setString('nexo.pending.$productId', orderId);
  }

  Future<String?> loadPendingOrder(String productId) async {
    return _prefs?.getString('nexo.pending.$productId');
  }

  Future<void> clearPendingOrder(String productId) async {
    await _prefs?.remove('nexo.pending.$productId');
  }

  Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
    await clearPendingOrder(purchase.productID);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _updates.close();
  }
}