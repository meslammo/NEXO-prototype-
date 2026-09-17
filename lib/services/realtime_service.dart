import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class RealtimeService {
  final ApiClient api;
  WebSocketChannel? _channel;
  final _events=StreamController<Map<String,dynamic>>.broadcast();
  Stream<Map<String,dynamic>> get events=>_events.stream;
  RealtimeService(this.api);

  Future<void> connect() async {
    if(!NexoApiConfig.configured||api.token==null)return;
    await disconnect();
    final uri=Uri.parse(NexoApiConfig.websocketUrl).replace(queryParameters:{'token':api.token!});
    _channel=WebSocketChannel.connect(uri);
    _channel!.stream.listen((raw){
      try{final data=jsonDecode(raw.toString());if(data is Map<String,dynamic>)_events.add(data);}catch(_){}
    },onError:(_){},onDone:(){});
  }
  void sendSignal(String toUserId,Map<String,dynamic> payload){
    _channel?.sink.add(jsonEncode({'type':'signal','toUserId':toUserId,'payload':payload}));
  }
  Future<void> setPresence(bool online) async {
    if(!NexoApiConfig.configured||api.token==null)return;
    try{await api.postJson('/presence',{'online':online});}catch(_){}
  }
  Future<void> disconnect() async {try{await _channel?.sink.close();}catch(_){} _channel=null;}
  Future<void> dispose() async {await disconnect();await _events.close();}
}