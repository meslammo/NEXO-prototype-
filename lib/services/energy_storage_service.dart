// يحتاج باكدج shared_preferences في pubspec.yaml:
//
//   dependencies:
//     shared_preferences: ^2.2.3
//
// ثم: flutter pub get

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/energy_model.dart';
import 'energy_service.dart';

/// طبقة حفظ/تحميل حالة الطاقة محليًا على الجهاز عشان الرصيد
/// ميرجعش لـ 50 كل ما المستخدم يقفل التطبيق.
/// لاحقًا لو ضفت سيرفر، استبدل الجسم الداخلي بنداء API بنفس الشكل.
class EnergyStorageService {
  EnergyStorageService._();
  static const _key = 'nexo_energy_state';

  /// يتنادى مرة واحدة عند بدء التطبيق (في main.dart) قبل ما تشغّل الواجهة
  static Future<void> loadOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        EnergyService.instance.loadState(EnergyModel.fromJson(json));
      } catch (_) {
        // لو البيانات المحفوظة اتعطبت لأي سبب، كمل بالرصيد الافتراضي
      }
    }

    // بيسمع لأي تغيير في الرصيد ويحفظه أوتوماتيك من غير ما تنادي حاجة يدوي
    EnergyService.instance.stream.listen((energy) => _save(energy));
  }

  static Future<void> _save(EnergyModel energy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(energy.toJson()));
  }
}
