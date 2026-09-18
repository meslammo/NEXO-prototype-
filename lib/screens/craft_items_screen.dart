import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nexo_catalog.dart';
import '../services/catalog_service.dart';
import '../services/economy_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../theme/nexo_theme.dart';
import '../widgets/nexo_asset_art.dart';

class CraftItemsScreen extends StatelessWidget {
  const CraftItemsScreen({super.key});
  static const recipes=[
    {'id':'crafted-shadow-mask','cost':400},
    {'id':'crafted-phoenix-seal','cost':1200},
    {'id':'crafted-prism-token','cost':300},
    {'id':'crafted-nebula-core','cost':800},
    {'id':'crafted-golden-signet','cost':1400},
    {'id':'crafted-arcana','cost':5000},
  ];
  Future<void> _craft(BuildContext context,NexoCatalogItem item,int cost) async {
    final economy=context.read<EconomyService>(); final auth=context.read<AuthService>();
    if(NexoApiConfig.configured&&auth.online){
      try{
        final result=await context.read<ApiClient>().postJson('/craft',{'itemId':item.id,'idempotencyKey':'craft-${item.id}-${DateTime.now().microsecondsSinceEpoch}'});
        economy.setGems((result['gems'] as num?)?.toInt()??economy.gems); economy.addItem(item.id,1);
        if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('✅ ${item.name} اتصنع ودخل المخزون')));
      }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر التصنيع: $e'),backgroundColor:Colors.redAccent));}
      return;
    }
    if(!economy.spendGems(cost)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('❌ Gems غير كافية للتصنيع')));return;}
    economy.addItem(item.id,1); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('✅ ${item.name} اتصنع ودخل المخزون')));
  }
  @override Widget build(BuildContext context){
    final catalog=context.watch<NexoCatalogService>();
    return Scaffold(backgroundColor:NexoColors.background,body:SafeArea(child:Column(children:[
      const Padding(padding:EdgeInsets.fromLTRB(8,8,16,8),child:Row(children:[BackButton(color:Colors.white),Expanded(child:Text('Workshop / Craft',textAlign:TextAlign.center,style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.bold))),SizedBox(width:48)])),
      const Padding(padding:EdgeInsets.symmetric(horizontal:16,vertical:5),child:Text('العناصر المصنّعة تدخل المخزون من نفس Catalog وملكية السيرفر، ولا تباع مباشرة في Market.',style:TextStyle(color:NexoColors.textSecondary),textAlign:TextAlign.center)),
      Expanded(child:ListView.builder(padding:const EdgeInsets.all(16),itemCount:recipes.length,itemBuilder:(_,i){
        final recipe=recipes[i], item=catalog.getById(recipe['id']!.toString());
        if(item==null)return const SizedBox.shrink(); final cost=recipe['cost']! as int;
        return Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:item.rarity.color.withOpacity(.28))),child:Row(children:[
          NexoAssetArt(item:item,size:62),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(item.name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
            Text('${item.rarity.label} · تكلفة التصنيع ${cost} Gems',style:TextStyle(color:item.rarity.color,fontSize:11)),
            Text(item.description,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10))
          ])),
          ElevatedButton(onPressed:()=>_craft(context,item,cost),child:const Text('تصنيع'))
        ]));
      }))
    ])));
  }
}
