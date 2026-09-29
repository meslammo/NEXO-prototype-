import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/frame_model.dart';

class FrameService extends ChangeNotifier {
  static const _key = 'nexo_selected_frame';
  String? _selected;
  String? get selectedFrameId => _selected;
  NexoFrame? get selectedFrame => _selected == null ? null : nexoFrames.firstWhere((f)=>f.id==_selected, orElse:()=>nexoFrames.first);

  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    _selected=p.getString(_key);
    notifyListeners();
  }

  Future<void> equip(String id) async {
    if (!nexoFrames.any((f)=>f.id==id)) return;
    _selected=id;
    notifyListeners();
    final p=await SharedPreferences.getInstance();
    await p.setString(_key,id);
  }
}