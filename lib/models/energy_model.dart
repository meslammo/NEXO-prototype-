/// نموذج بيانات نظام الطاقة في NEXO
/// الطاقة منفصلة تمامًا عن التذاكر (Tickets) - بتتكسب باللعب فقط
/// وبتُستهلك في المكالمات الصوتية والفيديو.

class EnergyModel {
  /// الرصيد الحالي من الطاقة
  final double current;

  /// الحد الأقصى للطاقة (Cap)
  final double max;

  /// آخر وقت اتحدث فيه الرصيد (يُستخدم لحساب الاستهلاك أثناء المكالمات
  /// ولحساب انتهاء صلاحية أي بونص مؤقت مستقبلاً)
  final DateTime lastUpdated;

  /// تاريخ آخر مرة أخد فيها المستخدم مكافأة الدخول اليومي
  final DateTime? lastDailyClaim;

  /// عدد أيام الدخول المتتالية (يُستخدم لحساب مكافأة الدخول اليومي المتصاعدة)
  final int consecutiveLoginDays;

  const EnergyModel({
    required this.current,
    this.max = 500,
    required this.lastUpdated,
    this.lastDailyClaim,
    this.consecutiveLoginDays = 0,
  });

  /// نسبة الطاقة من 0.0 إلى 1.0 - تُستخدم لرسم شكل البطارية
  double get percent => max <= 0 ? 0 : (current / max).clamp(0.0, 1.0);

  /// هل الطاقة منخفضة (أقل من 30%) - يُستخدم لإظهار تحذير باللون الأحمر
  bool get isLow => percent < 0.3;

  /// هل الطاقة فاضية تمامًا
  bool get isEmpty => current <= 0;

  /// هل ممكن يبدأ مكالمة صوت (لازم دقيقة واحدة على الأقل)
  bool canStartVoiceCall({double costPerMinute = 1}) => current >= costPerMinute;

  /// هل ممكن يبدأ مكالمة فيديو (لازم دقيقة واحدة على الأقل)
  bool canStartVideoCall({double costPerMinute = 3}) => current >= costPerMinute;

  EnergyModel copyWith({
    double? current,
    double? max,
    DateTime? lastUpdated,
    DateTime? lastDailyClaim,
    int? consecutiveLoginDays,
  }) {
    return EnergyModel(
      current: current ?? this.current,
      max: max ?? this.max,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastDailyClaim: lastDailyClaim ?? this.lastDailyClaim,
      consecutiveLoginDays: consecutiveLoginDays ?? this.consecutiveLoginDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'current': current,
        'max': max,
        'lastUpdated': lastUpdated.toIso8601String(),
        'lastDailyClaim': lastDailyClaim?.toIso8601String(),
        'consecutiveLoginDays': consecutiveLoginDays,
      };

  factory EnergyModel.fromJson(Map<String, dynamic> json) => EnergyModel(
        current: (json['current'] as num).toDouble(),
        max: (json['max'] as num?)?.toDouble() ?? 500,
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
        lastDailyClaim: json['lastDailyClaim'] != null
            ? DateTime.parse(json['lastDailyClaim'] as String)
            : null,
        consecutiveLoginDays: json['consecutiveLoginDays'] as int? ?? 0,
      );

  factory EnergyModel.initial() => EnergyModel(
        current: 50,
        max: 500,
        lastUpdated: DateTime.now(),
      );
}

/// أنواع مصادر كسب الطاقة - يُستخدم في السجل (Log) وتحليل النشاط لاحقًا
enum EnergySource {
  mining,
  crafting,
  dailyLogin,
  levelUp,
  dailyMission,
  purchase, // مسار احتياطي لو حبيت مستقبلاً تبيع طاقة بالتذاكر
}

/// أنواع استهلاك الطاقة
enum EnergyDrain {
  voiceCall,
  videoCall,
}
