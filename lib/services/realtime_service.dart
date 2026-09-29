import 'dart:async';
import '../config/api_config.dart';
import 'api_client.dart';

class RealtimeService {
  final ApiClient api;
  final _events = StreamController<Map<String,dynamic>>.broadcast();
  Timer? _pollTimer;
  bool _polling = false;
  Stream<Map<String,dynamic>> get events => _events.stream;
  RealtimeService(this.api);

  Future<void> connect() async {
    if (!NexoApiConfig.configured || api.token == null) return;
    await disconnect();
    await _pollSignals();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _pollSignals();
    });
    try { await api.postJson('/presence', {'online': true}); } catch (_) {}
  }

  Future<void> _pollSignals() async {
    if (_polling || api.token == null) return;
    _polling = true;
    try {
      final data = await api.getJson('/signal/poll');
      final raw = data['data'];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map<String,dynamic>) _events.add(Map<String,dynamic>.from(e));
        }
      }
    } catch (_) {
    } finally {
      _polling = false;
    }
  }

  void sendSignal(String toUserId, Map<String,dynamic> payload) {
    if (!NexoApiConfig.configured || api.token == null) return;
    api.postJson('/signal/send', {
      'toUserId': toUserId,
      'payload': payload,
    }).catchError((_) => <String,dynamic>{});
  }

  Future<void> setPresence(bool online) async {
    if (!NexoApiConfig.configured || api.token == null) return;
    try { await api.postJson('/presence', {'online': online}); } catch (_) {}
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    try { await setPresence(false); } catch (_) {}
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }
}