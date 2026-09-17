import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'realtime_service.dart';

class NexoNotification {
  final String id;
  final String kind;
  final String title;
  final String body;
  final bool read;
  NexoNotification({required this.id,required this.kind,required this.title,required this.body,required this.read});
  factory NexoNotification.fromMap(Map<String,dynamic> m) => NexoNotification(
    id:m['id']?.toString() ?? '',
    kind:m['kind']?.toString() ?? 'system',
    title:m['title']?.toString() ?? 'NEXO',
    body:m['body']?.toString() ?? '',
    read:m['read']==true,
  );
}

class NotificationService extends ChangeNotifier {
  final ApiClient api;
  final RealtimeService realtime;
  StreamSubscription<Map<String,dynamic>>? _eventsSubscription;
  final List<NexoNotification> _items=[];
  NotificationService(this.api,this.realtime);

  List<NexoNotification> get items=>List.unmodifiable(_items);
  int get unreadCount=>_items.where((x)=>!x.read).length;

  Future<void> initialize() async {
    try {
      final raw=await api.getJson('/notifications');
      final data=raw['data'];
      if(data is List){
        _items
          ..clear()
          ..addAll(data.whereType<Map>().map((m)=>NexoNotification.fromMap(Map<String,dynamic>.from(m))));
      }
    } catch (_) {}
    _eventsSubscription=realtime.events.listen((event){
      if(event['type']!='notification')return;
      final raw=event['notification'];
      if(raw is Map){
        _items.insert(0,NexoNotification.fromMap(Map<String,dynamic>.from(raw)));
        if(_items.length>100)_items.removeLast();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    try{await api.postJson('/notifications/$id/read',{});}catch(_){return;}
    final i=_items.indexWhere((x)=>x.id==id);
    if(i>=0){final x=_items[i];_items[i]=NexoNotification(id:x.id,kind:x.kind,title:x.title,body:x.body,read:true);notifyListeners();}
  }

  Future<void> markAllRead() async {
    try{await api.postJson('/notifications/read-all',{});}catch(_){return;}
    for(var i=0;i<_items.length;i++){
      final x=_items[i];_items[i]=NexoNotification(id:x.id,kind:x.kind,title:x.title,body:x.body,read:true);
    }
    notifyListeners();
  }

  @override
  void dispose(){_eventsSubscription?.cancel();super.dispose();}
}