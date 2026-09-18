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

class InventoryScreen extends StatefulWidget{const InventoryScreen({super.key});@override State<InventoryScreen> createState()=>_InventoryScreenState();}
class _InventoryScreenState extends State<InventoryScreen>{
  final _labels=['Gifts','Frames','Assets','Emoji','Crafted'];
  final Map<String,String?> equipped={};
  Future<void> _equip(BuildContext context,NexoCatalogItem item,String slot) async {
    final auth=context.read<AuthService>();
    if(!(NexoApiConfig.configured&&auth.online)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('التجهيز يحتاج اتصال بالسيرفر.')));return;}
    try{
      await context.read<ApiClient>().postJson('/profile/equipped',{'slot':slot,'itemId':item.id});
      setState(()=>equipped[slot]=item.id);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('✅ ${item.name} اتطبق على الـProfile')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر التجهيز: $e'),backgroundColor:Colors.redAccent));}
  }
  Future<void> _openDetails(NexoCatalogItem item,int qty) async {
    final canEquip=item.type==NexoItemType.frame||item.type==NexoItemType.asset;
    final slot=item.type==NexoItemType.frame?'frame':'profile_asset';
    await showDialog(context:context,builder:(_)=>AlertDialog(
      backgroundColor:NexoColors.card,title:Text(item.name,style:TextStyle(color:item.rarity.color,fontWeight:FontWeight.bold)),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        NexoAssetArt(item:item,size:130),
        Text(item.rarity.label,style:TextStyle(color:item.rarity.color,fontWeight:FontWeight.bold)),
        const SizedBox(height:6),Text(item.description,style:const TextStyle(color:Colors.white70),textAlign:TextAlign.center),
        const SizedBox(height:6),Text('الكمية: ${qty}',style:const TextStyle(color:NexoColors.textSecondary)),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إغلاق')),
        if(canEquip&&qty>0)ElevatedButton(onPressed:()=>{Navigator.pop(context),_equip(context,item,slot)},child:Text(item.type==NexoItemType.frame?'تجهيز الإطار':'تجهيز الـAsset'))
      ],
    ));
  }
  Widget _tab(NexoItemType type,NexoCatalogService catalog,EconomyService economy){
    final items=catalog.byType(type);
    return GridView.builder(
      padding:const EdgeInsets.all(12),itemCount:items.length,
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:.78),
      itemBuilder:(_,i){
        final item=items[i], qty=economy.inventory[item.id]??0;
        return InkWell(onTap:()=>_openDetails(item,qty),borderRadius:BorderRadius.circular(18),child:Container(
          padding:const EdgeInsets.all(10),
          decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(18),border:Border.all(color:item.rarity.color.withOpacity(qty>0?.45:.18))),
          child:Column(children:[
            Expanded(child:NexoAssetArt(item:item,size:94)),
            Text(item.name,maxLines:1,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:11)),
            Text(item.rarity.label,style:TextStyle(color:item.rarity.color,fontSize:9)),
            Text(qty>0?'x$qty':'غير مملوك',style:TextStyle(color:qty>0?NexoColors.success:NexoColors.textSecondary,fontWeight:FontWeight.bold,fontSize:10)),
            if((item.type==NexoItemType.frame||item.type==NexoItemType.asset)&&qty>0)
              TextButton(onPressed:()=>_equip(context,item,item.type==NexoItemType.frame?'frame':'profile_asset'),child:const Text('تجهيز',style:TextStyle(fontSize:10))),
          ]),
        ));
      },
    );
  }
  @override Widget build(BuildContext context){
    return DefaultTabController(length:5,child:Scaffold(
      backgroundColor:NexoColors.background,
      appBar:AppBar(backgroundColor:NexoColors.background,title:const Text('Collection / Inventory'),centerTitle:true,leading:const BackButton(color:Colors.white),bottom:TabBar(isScrollable:true,tabs:_labels.map((x)=>Tab(text:x)).toList())),
      body:Consumer2<NexoCatalogService,EconomyService>(builder:(_,catalog,economy,__){
        final types=[NexoItemType.gift,NexoItemType.frame,NexoItemType.asset,NexoItemType.emoji,NexoItemType.crafted];
        return TabBarView(children:types.map((t)=>_tab(t,catalog,economy)).toList());
      }),
    ));
  }
}
