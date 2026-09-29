import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  static const _tokenKey='nexo.auth.token';
  final ApiClient api;
  final FlutterSecureStorage storage;
  Map<String,dynamic>? _user;
  bool _initialized=false,_online=false,_busy=false;
  AuthService(this.api,{FlutterSecureStorage? storage}) : storage=storage ?? const FlutterSecureStorage();
  Map<String,dynamic>? get user=>_user;
  bool get initialized=>_initialized;
  bool get online=>_online;
  bool get busy=>_busy;
  String? get userId=>_user?['id']?.toString();

  Future<void> initialize() async {
    if(_initialized)return;
    if(!NexoApiConfig.configured){_initialized=true;notifyListeners();return;}
    try{
      final token=await storage.read(key:_tokenKey);
      if(token!=null&&token.isNotEmpty){
        api.token=token;
        try{final r=await api.getJson('/me');_setUser(r['user']);}catch(_){await _clear();}
      }
    }catch(_){}
    _initialized=true;notifyListeners();
  }
  Future<void> _clear() async {api.token=null;_user=null;_online=false;await storage.delete(key:_tokenKey);}
  void _setUser(dynamic raw){if(raw is Map){_user=Map<String,dynamic>.from(raw);_online=true;notifyListeners();}}
  Future<void> login(String identifier,String password) async {
    _busy=true;notifyListeners();
    try{
      final r=await api.postJson('/auth/login',{'identifier':identifier.trim(),'password':password});
      final t=r['token']?.toString();if(t==null||t.isEmpty)throw StateError('No session token');
      api.token=t;await storage.write(key:_tokenKey,value:t);_setUser(r['user']);
    }finally{_busy=false;notifyListeners();}
  }
  Future<void> register({required String username,required String email,required String displayName,required String password}) async {
    _busy=true;notifyListeners();
    try{
      final r=await api.postJson('/auth/register',{'username':username.trim(),'email':email.trim(),'displayName':displayName.trim(),'password':password});
      final t=r['token']?.toString();if(t==null||t.isEmpty)throw StateError('No session token');
      api.token=t;await storage.write(key:_tokenKey,value:t);_setUser(r['user']);
    }finally{_busy=false;notifyListeners();}
  }
  Future<void> guest() async {
    _busy=true;notifyListeners();
    try{
      final device='android-'+DateTime.now().millisecondsSinceEpoch.toString();
      final r=await api.postJson('/auth/guest',{'deviceId':device});
      final t=r['token']?.toString();if(t==null||t.isEmpty)throw StateError('No guest token');
      api.token=t;await storage.write(key:_tokenKey,value:t);_setUser(r['user']);
    }finally{_busy=false;notifyListeners();}
  }
  Future<void> logout() async {try{if(api.token!=null)await api.postJson('/auth/logout',{});}catch(_){ }await _clear();notifyListeners();}
}