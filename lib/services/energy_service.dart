import 'dart:async';
import '../models/energy_model.dart';

/// خدمة إدارة نظام الطاقة في NEXO
/// نفس أسلوب EscrowService: Singleton بسيط يحمل الحالة والمنطق،
/// وسهل لاحقًا تستبدله بربط API/DB من غير ما تغيّر الشاشات اللي بتستخدمه.
class EnergyService {
  EnergyService._();
  static final EnergyService instance = EnergyService._();

  // ---------- إعدادات الخوارزمية ----------

  /// الحد الأقصى للطاقة
  static const double maxEnergy = 100;

  /// نقاط الطاقة من كل مصدر
  static const double miningReward = 2;
  static const double craftingReward = 5;
  static const double dailyLoginBase = 20;
  static const double dailyLoginMaxStreak = 7; // بعدها بيرجع يلف من الأول
  static const double dailyLoginStreakStep = 5; // +5 لكل يوم متتالي إضافي

  /// تكلفة الطاقة بالدقيقة
  static const double voiceCostPerMinute = 1;
  static const double videoCostPerMinute = 4;

  // ---------- الحالة ----------

  EnergyModel _energy = EnergyModel.initial();
  final _controller = StreamController<EnergyModel>.broadcast();

  /// Stream عشان أي Widget يقدر يسمع للتغييرات ويحدث نفسه تلقائيًا
  Stream<EnergyModel> get stream => _controller.stream;

  EnergyModel get current => _energy;

  final List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> get logs => List.unmodifiable(_logs);

  void _emit(EnergyModel updated) {
    _energy = updated;
    _controller.add(_energy);
  }

  void _log(String type, double amount, String reason) {
    _logs.add({
      'type': type, // 'earn' or 'spend'
      'amount': amount,
      'reason': reason,
      'balanceAfter': _energy.current,
      'time': DateTime.now(),
    });
  }

  // ---------- كسب الطاقة ----------

  /// إضافة طاقة (بيتقيد تلقائيًا بالحد الأقصى)
  void _addEnergy(double amount, EnergySource source, {String? reason}) {
    if (amount <= 0) return;
    final newValue = (_energy.current + amount).clamp(0, _energy.max).toDouble();
    _emit(_energy.copyWith(current: newValue, lastUpdated: DateTime.now()));
    _log('earn', amount, reason ?? source.name);
  }

  /// يُستدعى عند نجاح عملية تعدين
  void rewardMining() => _addEnergy(miningReward, EnergySource.mining);

  /// يُستدعى عند صناعة عنصر بنجاح
  void rewardCrafting() => _addEnergy(craftingReward, EnergySource.crafting);

  /// يُستدعى عند زيادة مستوى اللاعب - كل مستوى بيدي طاقة أكتر
  void rewardLevelUp(int newLevel) =>
      _addEnergy(15 * newLevel.toDouble(), EnergySource.levelUp,
          reason: 'level_up_to_$newLevel');

  /// يُستدعى عند إكمال مهمة يومية
  void rewardDailyMission(double amount, String missionId) =>
      _addEnergy(amount, EnergySource.dailyMission, reason: missionId);

  /// مكافأة الدخول اليومي - بتحسب تلقائيًا هل يستحقها النهاردة ولا لأ،
  /// وبتزود القيمة كل يوم متتالي لحد أسبوع وبعدين بترجع تلف من الأول.
  /// بترجع true لو أخد المكافأة، false لو أخدها بالفعل النهاردة.
  bool claimDailyLoginReward() {
    final now = DateTime.now();
    final last = _energy.lastDailyClaim;

    final alreadyClaimedToday = last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;

    if (alreadyClaimedToday) return false;

    final wasYesterday = last != null &&
        now.difference(DateTime(last.year, last.month, last.day)).inDays == 1;

    final newStreak = wasYesterday
        ? (_energy.consecutiveLoginDays % dailyLoginMaxStreak.toInt()) + 1
        : 1;

    final reward = dailyLoginBase + (newStreak - 1) * dailyLoginStreakStep;

    final newValue = (_energy.current + reward).clamp(0, _energy.max).toDouble();
    _emit(_energy.copyWith(
      current: newValue,
      lastUpdated: now,
      lastDailyClaim: now,
      consecutiveLoginDays: newStreak,
    ));
    _log('earn', reward, 'daily_login_streak_$newStreak');
    return true;
  }

  // ---------- استهلاك الطاقة ----------

  /// هل يقدر يبدأ مكالمة صوت دلوقتي
  bool canStartVoice() => _energy.canStartVoiceCall(costPerMinute: voiceCostPerMinute);

  /// هل يقدر يبدأ مكالمة فيديو دلوقتي
  bool canStartVideo() => _energy.canStartVideoCall(costPerMinute: videoCostPerMinute);

  /// بيتاخد كل دقيقة أثناء مكالمة صوت شغالة (استدعيه من Timer.periodic كل 60 ثانية)
  /// بترجع false لو الطاقة خلصت عشان تقفل المكالمة تلقائي
  bool tickVoiceMinute() => _drainPerMinute(voiceCostPerMinute, EnergyDrain.voiceCall);

  /// بيتاخد كل دقيقة أثناء مكالمة فيديو شغالة
  bool tickVideoMinute() => _drainPerMinute(videoCostPerMinute, EnergyDrain.videoCall);

  bool _drainPerMinute(double amount, EnergyDrain drain) {
    if (_energy.current <= 0) return false;
    final newValue = (_energy.current - amount).clamp(0, _energy.max).toDouble();
    _emit(_energy.copyWith(current: newValue, lastUpdated: DateTime.now()));
    _log('spend', amount, drain.name);
    return newValue > 0;
  }

  // ---------- تحميل حالة محفوظة (لو هتربطها بتخزين محلي أو سيرفر) ----------

  void loadState(EnergyModel saved) => _emit(saved);

  void dispose() => _controller.close();
}
