
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/economy_service.dart';
import '../services/nexo_purchase_service.dart';
import '../theme/nexo_theme.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});
  static const packs = [
    {'id':'starter_499','gems':500,'price':'4.99'},
    {'id':'plus_999','gems':1200,'price':'9.99'},
    {'id':'pro_1999','gems':3000,'price':'19.99'},
    {'id':'ultra_24999','gems':8000,'price':'49.99'},
  ];
  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  late final NexoPurchaseService _purchases;
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;
  final Map<String,String> _pendingOrders = {};
  bool _storeAvailable = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _purchases = NexoPurchaseService();
    _purchaseSubscription = _purchases.updates.listen(_handlePurchase);
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    try {
      await _purchases.initialize();
      if (mounted) setState(() { _storeAvailable = _purchases.isAvailable; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _storeAvailable = false; _loading = false; });
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final orderId = _pendingOrders[purchase.productID];
    if (purchase.status == PurchaseStatus.pending) return;
    if (purchase.status == PurchaseStatus.error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الدفع لم يكتمل: ${purchase.error?.message ?? 'خطأ غير معروف'}'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (purchase.status != PurchaseStatus.purchased && purchase.status != PurchaseStatus.restored) return;
    if (orderId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم العثور على عملية شراء بلا Order محفوظ؛ لن تُضاف Gems تلقائيًا لحماية الرصيد.')),
      );
      return;
    }
    final auth = context.read<AuthService>();
    if (!NexoApiConfig.configured || !auth.online) return;
    try {
      final token = purchase.verificationData.serverVerificationData;
      if (token.trim().isEmpty) throw StateError('No purchase token');
      final api = context.read<ApiClient>();
      if (purchase.verificationData.source == 'google_play') {
        await api.postJson('/payments/google/verify', {
          'orderId': orderId,
          'productId': purchase.productID,
          'purchaseToken': token,
        });
      } else {
        throw StateError('App Store server verification is not configured');
      }
      final wallet = await api.getJson('/wallet');
      final economy = context.read<EconomyService>();
      economy.setGems((wallet['gems'] as num?)?.toInt() ?? economy.gems);
      _pendingOrders.remove(purchase.productID);
      await _purchases.complete(purchase);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم تأكيد ${purchase.productID} وإضافة Gems من السيرفر')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لم يتم منح Gems: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _buy(Map<String,Object> pack) async {
    final auth = context.read<AuthService>();
    final id = pack['id']! as String;
    if (!NexoApiConfig.configured || !auth.online) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السيرفر غير متاح؛ لن يتم إنشاء رصيد وهمي.')),
      );
      return;
    }
    if (!_storeAvailable) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متجر التطبيقات غير متاح في نسخة الاختبار الحالية.')),
      );
      return;
    }
    if (!_purchases.hasProduct(id)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('المنتج $id غير منشور في المتجر لهذا التطبيق.')),
      );
      return;
    }
    try {
      final result = await context.read<ApiClient>().postJson('/payments/create-order', {'packageId': id});
      final orderId = result['orderId']?.toString();
      if (orderId == null || orderId.isEmpty) throw StateError('No order id');
      _pendingOrders[id] = orderId;
      await _purchases.savePendingOrder(id, orderId);
      await _purchases.buy(id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر بدء عملية الدفع: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _purchases.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NexoColors.background,
    appBar: AppBar(
      backgroundColor: NexoColors.background,
      title: const Text('Gems / VIP'),
      centerTitle: true,
      leading: const BackButton(color: Colors.white),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Consumer<EconomyService>(
          builder: (_, e, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NexoColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NexoColors.primary.withOpacity(.28)),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_rounded, color: NexoColors.primary, size: 30),
                const SizedBox(width: 10),
                const Text('رصيدك', style: TextStyle(color: Colors.white70)),
                const Spacer(),
                Text('${e.gems} Gems', style: const TextStyle(color: NexoColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
        if (!_loading && !_storeAvailable)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('نسخة الاختبار تحتاج متجرًا منشورًا للمنتجات قبل تشغيل الدفع الحقيقي.', style: TextStyle(color: NexoColors.textSecondary), textAlign: TextAlign.center),
          ),
        ...RechargeScreen.packs.map((p) => Card(
          color: NexoColors.card,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.diamond_rounded)),
            title: Text('${p['gems']} Gems', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${p['id']} · Store Product', style: const TextStyle(color: NexoColors.textSecondary)),
            trailing: ElevatedButton(
              onPressed: () => _buy(p),
              child: Text('\$${p['price']}'),
            ),
          ),
        )),
        const SizedBox(height: 14),
        const Text(
          'العملة الوحيدة للمستخدم: Gems. الرصيد لا يزيد إلا بعد التحقق من عملية الشراء على السيرفر.',
          style: TextStyle(color: NexoColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
