import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  static const _tokenKey='nexo.auth.token';
  static const _deviceKey='nexo.device.id';
  final ApiClient api;
  final FlutterSecureStorage storage;
  Map<String,dynamic>? _user;
  bool _initialized=false;
  bool _online=false;
  AuthService(this.api,{FlutterSecureStorage? storage}) : storage=storage ?? const FlutterSecureStorage();
  Map<String,dynamic>? get user=>_user;
  bool get initialized=>_initialized;
  bool get online=>_online;
  String? get userId=>_user?['id']?.toString();

  Future<void> initialize() async {
    if(_initialized)return;
    if(!NexoApiConfig.configured){_initialized=true;notifyListeners();return;}
    try{
      final token=await storage.read(key:_tokenKey);
      if(token!=null&&token.isNotEmpty){
        api.token=token;
        try{final me=await api.getJson('/me');_user=Map<String,dynamic>.from(me['user'] as Map);_online=true;}
        catch(_){api.token=null;await storage.delete(key:_tokenKey);}
      }
      if(api.token==null){
        var device=await storage.read(key:_deviceKey);
        if(device==null||device.isEmpty){
          device='android-${DateTime.now().microsecondsSinceEpoch}';
          await storage.write(key:_deviceKey,value:device);
        }
        final guest=await api.postJson('/auth/guest',{'deviceId':device});
        api.token=guest['token']?.toString();
        if(api.token!=null)await storage.write(key:_tokenKey,value:api.token!);
        _user=Map<String,dynamic>.from(guest['user'] as Map);
        _online=true;
      }
    }catch(_){_online=false;}
    finally{_initialized=true;notifyListeners();}
  }
  Future<void> logout() async {
    await storage.delete(key:_tokenKey);api.token=null;_user=null;_online=false;notifyListeners();
  }
}