/// نماذج نظام التداول و Escrow في NEXO

enum TradeStatus {
  pending,
  locked,
  confirmedA,
  confirmedB,
  completed,
  cancelled,
  disputed,
  expired,
  resolved, // تم حل النزاع
}

extension TradeStatusX on TradeStatus {
  String get labelAr {
    switch (this) {
      case TradeStatus.pending:
        return 'في الانتظار';
      case TradeStatus.locked:
        return 'محجوزة (Escrow)';
      case TradeStatus.confirmedA:
        return 'تم تأكيد الطرف الأول';
      case TradeStatus.confirmedB:
        return 'تم تأكيد الطرف الثاني';
      case TradeStatus.completed:
        return 'مكتملة';
      case TradeStatus.cancelled:
        return 'ملغاة';
      case TradeStatus.disputed:
        return 'نزاع مفتوح';
      case TradeStatus.expired:
        return 'منتهية الصلاحية';
      case TradeStatus.resolved:
        return 'تم حل النزاع';
    }
  }

  bool get isActive =>
      this == TradeStatus.pending ||
      this == TradeStatus.locked ||
      this == TradeStatus.confirmedA ||
      this == TradeStatus.confirmedB;

  bool get canCancel =>
      this == TradeStatus.pending || this == TradeStatus.locked;

  bool get isFinal =>
      this == TradeStatus.completed ||
      this == TradeStatus.cancelled ||
      this == TradeStatus.expired ||
      this == TradeStatus.resolved;
}

enum DisputeResolution {
  refundBoth,      // إرجاع العناصر للطرفين
  favorFrom,       // لصالح الطرف الأول (from)
  favorTo,         // لصالح الطرف الثاني (to)
  completeAsIs,    // إكمال الصفقة كما هي
}

extension DisputeResolutionX on DisputeResolution {
  String get labelAr {
    switch (this) {
      case DisputeResolution.refundBoth:
        return 'إرجاع العناصر للطرفين';
      case DisputeResolution.favorFrom:
        return 'لصالح الطرف الأول';
      case DisputeResolution.favorTo:
        return 'لصالح الطرف الثاني';
      case DisputeResolution.completeAsIs:
        return 'إكمال الصفقة كما هي';
    }
  }
}

class TradeItem {
  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final int qty;
  final int unitValue;

  const TradeItem({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.qty,
    required this.unitValue,
  });

  int get totalValue => qty * unitValue;

  TradeItem copyWith({int? qty}) => TradeItem(
        id: id,
        name: name,
        iconName: iconName,
        colorValue: colorValue,
        qty: qty ?? this.qty,
        unitValue: unitValue,
      );
}

class Trade {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final List<TradeItem> fromItems;
  final List<TradeItem> toItems;
  final int totalValue;
  final double feePercent;
  final int appFee;
  final int netAmount;
  final TradeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool fromConfirmed;
  final bool toConfirmed;
  final String? cancelReason;
  final String? disputeReason;
  final String? disputeOpenedBy;
  final DisputeResolution? resolution;
  final String? resolutionNote;

  const Trade({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.fromItems,
    required this.toItems,
    required this.totalValue,
    this.feePercent = 5.0,
    required this.appFee,
    required this.netAmount,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.fromConfirmed = false,
    this.toConfirmed = false,
    this.cancelReason,
    this.disputeReason,
    this.disputeOpenedBy,
    this.resolution,
    this.resolutionNote,
  });

  Duration get remainingTime {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return Duration.zero;
    return expiresAt.difference(now);
  }

  bool get isExpired => remainingTime == Duration.zero && status.isActive;

  Trade copyWith({
    TradeStatus? status,
    bool? fromConfirmed,
    bool? toConfirmed,
    String? cancelReason,
    String? disputeReason,
    String? disputeOpenedBy,
    DisputeResolution? resolution,
    String? resolutionNote,
  }) {
    return Trade(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      fromItems: fromItems,
      toItems: toItems,
      totalValue: totalValue,
      feePercent: feePercent,
      appFee: appFee,
      netAmount: netAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      fromConfirmed: fromConfirmed ?? this.fromConfirmed,
      toConfirmed: toConfirmed ?? this.toConfirmed,
      cancelReason: cancelReason ?? this.cancelReason,
      disputeReason: disputeReason ?? this.disputeReason,
      disputeOpenedBy: disputeOpenedBy ?? this.disputeOpenedBy,
      resolution: resolution ?? this.resolution,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }
}
