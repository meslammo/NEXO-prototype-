import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/nexo_catalog.dart';
import 'api_client.dart';

class NexoCatalogService extends ChangeNotifier {
  final ApiClient api;
  List<NexoCatalogItem> _items=List.unmodifiable(nexoCatalogSeed);
  bool loading=false;
  String? error;
  NexoCatalogService(this.api);
  List<NexoCatalogItem> get items=>_items;
  List<NexoGift> get gifts=>_items.where((e)=>e.type==NexoItemType.gift).cast<NexoGift>().toList(growable:false);
  List<NexoCatalogItem> byType(NexoItemType type)=>_items.where((e)=>e.type==type).toList(growable:false);
  List<NexoCatalogItem> get marketItems=>_items.where((e)=>e.active&&e.marketVisible).toList(growable:false);
  Future<void> load() async {
    if(!NexoApiConfig.configured)return;
    loading=true;error=null;notifyListeners();
    try{
      final response=await api.getJson('/catalog');
      final raw=response['data'];
      if(raw is List&&raw.isNotEmpty){_items=List.unmodifiable(raw.whereType<Map>().map((e)=>NexoCatalogItem.fromJson(Map<String,dynamic>.from(e))));}
    }catch(e){error=e.toString();}
    finally{loading=false;notifyListeners();}
  }
  Future<void> refresh()=>load();
  NexoCatalogItem? getById(String id){for(final x in _items){if(x.id==id)return x;}return null;}
}
