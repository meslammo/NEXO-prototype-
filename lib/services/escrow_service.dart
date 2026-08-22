import '../models/trade_models.dart';

class EscrowService {
  EscrowService._();
  static final EscrowService instance = EscrowService._();

  static const double appFeePercent = 5.0;
  static const Duration tradeTimeout = Duration(hours: 24);

  final Map<String, Trade> _trades = {};
  final Map<String, List<TradeItem>> _lockedItems = {};
  final List<Map<String, dynamic>> _logs = [];

  Trade createAndLockTrade({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required List<TradeItem> fromItems,
    required List<TradeItem> toItems,
  }) {
    final totalValue = [
      ...fromItems.map((e) => e.totalValue),
      ...toItems.map((e) => e.totalValue),
    ].fold<int>(0, (a, b) => a + b);

    final appFee = (totalValue * appFeePercent / 100).round();
    final netAmount = totalValue - appFee;
    final now = DateTime.now();

    final trade = Trade(
      id: 'TRD-${now.millisecondsSinceEpoch}',
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      fromItems: fromItems,
      toItems: toItems,
      totalValue: totalValue,
      feePercent: appFeePercent,
      appFee: appFee,
      netAmount: netAmount,
      status: TradeStatus.locked,
      createdAt: now,
      expiresAt: now.add(tradeTimeout),
    );

    _lockItems(fromUserId, fromItems);
    _lockItems(toUserId, toItems);
    _trades[trade.id] = trade;
    _log(trade.id, 'locked', 'تم حجز العناصر (Escrow)');
    return trade;
  }

  Trade confirmReceipt({required String tradeId, required String userId}) {
    final trade = _trades[tradeId];
    if (trade == null) throw Exception('الصفقة غير موجودة');
    if (!trade.status.isActive) throw Exception('الصفقة مش نشطة');

    bool fromConfirmed = trade.fromConfirmed;
    bool toConfirmed = trade.toConfirmed;
    TradeStatus newStatus = trade.status;

    if (userId == trade.fromUserId) {
      fromConfirmed = true;
      _log(tradeId, 'confirm_a', 'الطرف الأول أكد الاستلام');
    } else if (userId == trade.toUserId) {
      toConfirmed = true;
      _log(tradeId, 'confirm_b', 'الطرف الثاني أكد الاستلام');
    } else {
      throw Exception('المستخدم مش طرف في الصفقة');
    }

    if (fromConfirmed && toConfirmed) {
      newStatus = TradeStatus.completed;
      _releaseItems(trade);
      _log(tradeId, 'completed', 'الصفقة اكتملت');
    } else if (fromConfirmed) {
      newStatus = TradeStatus.confirmedA;
    } else if (toConfirmed) {
      newStatus = TradeStatus.confirmedB;
    }

    final updated = trade.copyWith(
      status: newStatus,
      fromConfirmed: fromConfirmed,
      toConfirmed: toConfirmed,
    );
    _trades[tradeId] = updated;
    return updated;
  }

  Trade cancelTrade({required String tradeId, required String userId, String? reason}) {
    final trade = _trades[tradeId];
    if (trade == null) throw Exception('الصفقة غير موجودة');
    if (!trade.status.canCancel) throw Exception('لا يمكن إلغاء الصفقة في حالتها الحالية');

    _unlockItems(trade.fromUserId, trade.fromItems);
    _unlockItems(trade.toUserId, trade.toItems);

    final updated = trade.copyWith(
      status: TradeStatus.cancelled,
      cancelReason: reason ?? 'تم الإلغاء بواسطة المستخدم',
    );
    _trades[tradeId] = updated;
    _log(tradeId, 'cancelled', reason ?? 'إلغاء');
    return updated;
  }

  /// فتح نزاع
  Trade openDispute({
    required String tradeId,
    required String userId,
    required String reason,
  }) {
    final trade = _trades[tradeId];
    if (trade == null) throw Exception('الصفقة غير موجودة');
    if (trade.status == TradeStatus.disputed) throw Exception('النزاع مفتوح بالفعل');
    if (trade.status.isFinal) throw Exception('لا يمكن فتح نزاع على صفقة منتهية');

    final updated = trade.copyWith(
      status: TradeStatus.disputed,
      disputeReason: reason,
      disputeOpenedBy: userId,
    );
    _trades[tradeId] = updated;
    _log(tradeId, 'disputed', 'نزاع: $reason');
    return updated;
  }

  /// حل النزاع بنجاح (من الدعم / الأدمن)
  Trade resolveDispute({
    required String tradeId,
    required DisputeResolution resolution,
    String? note,
  }) {
    final trade = _trades[tradeId];
    if (trade == null) throw Exception('الصفقة غير موجودة');
    if (trade.status != TradeStatus.disputed) {
      throw Exception('الصفقة مش في حالة نزاع');
    }

    switch (resolution) {
      case DisputeResolution.refundBoth:
        _unlockItems(trade.fromUserId, trade.fromItems);
        _unlockItems(trade.toUserId, trade.toItems);
        break;
      case DisputeResolution.favorFrom:
        // الطرف الأول ياخد عناصر الطرف الثاني، ويرجع له عناصره
        _unlockItems(trade.fromUserId, trade.fromItems);
        _releaseItemsTo(trade.fromUserId, trade.toItems);
        break;
      case DisputeResolution.favorTo:
        _unlockItems(trade.toUserId, trade.toItems);
        _releaseItemsTo(trade.toUserId, trade.fromItems);
        break;
      case DisputeResolution.completeAsIs:
        _releaseItems(trade);
        break;
    }

    final updated = trade.copyWith(
      status: TradeStatus.resolved,
      resolution: resolution,
      resolutionNote: note ?? resolution.labelAr,
    );
    _trades[tradeId] = updated;
    _log(tradeId, 'resolved', 'حل النزاع: ${resolution.labelAr} — ${note ?? ""}');
    return updated;
  }

  Trade? checkExpiry(String tradeId) {
    final trade = _trades[tradeId];
    if (trade == null) return null;
    if (trade.isExpired && trade.status.isActive) {
      _unlockItems(trade.fromUserId, trade.fromItems);
      _unlockItems(trade.toUserId, trade.toItems);
      final updated = trade.copyWith(status: TradeStatus.expired);
      _trades[tradeId] = updated;
      _log(tradeId, 'expired', 'انتهت المهلة');
      return updated;
    }
    return trade;
  }

  Trade? getTrade(String id) => _trades[id];

  List<Trade> getDisputedTrades() {
    return _trades.values.where((t) => t.status == TradeStatus.disputed).toList();
  }

  List<Map<String, dynamic>> getLogs(String tradeId) {
    return _logs.where((l) => l['tradeId'] == tradeId).toList();
  }

  void _lockItems(String userId, List<TradeItem> items) {
    _lockedItems.putIfAbsent(userId, () => []);
    _lockedItems[userId]!.addAll(items);
  }

  void _unlockItems(String userId, List<TradeItem> items) {
    final locked = _lockedItems[userId];
    if (locked == null) return;
    for (final item in items) {
      locked.removeWhere((e) => e.id == item.id);
    }
  }

  void _releaseItems(Trade trade) {
    _unlockItems(trade.fromUserId, trade.fromItems);
    _unlockItems(trade.toUserId, trade.toItems);
  }

  void _releaseItemsTo(String userId, List<TradeItem> items) {
    // في الإنتاج: نقل الملكية لـ userId
    // هنا بنشيل القفل فقط
    for (final entry in _lockedItems.entries) {
      for (final item in items) {
        entry.value.removeWhere((e) => e.id == item.id);
      }
    }
  }

  void _log(String tradeId, String action, String message) {
    _logs.add({
      'tradeId': tradeId,
      'action': action,
      'message': message,
      'at': DateTime.now().toIso8601String(),
    });
  }
}
