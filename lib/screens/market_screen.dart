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
import 'trade_screen.dart';

class MarketScreen extends StatefulWidget { const MarketScreen({super.key}); @override State<MarketScreen> createState()=>_MarketScreenState(); }
class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _labels=['Gifts','Frames','Assets','Emoji','Crafted','Trade Hub'];
  @override void initState(){super.initState();_tabs=TabController(length:_labels.length,vsync:this);}
  @override void dispose(){_tabs.dispose();super.dispose();}
  Future<void> _buy(NexoCatalogItem item) async {
    if(!item.marketVisible){return;}
    final economy=context.read<EconomyService>(); final auth=context.read<AuthService>();
    if(NexoApiConfig.configured&&auth.online){
      try{
        final result=await context.read<ApiClient>().postJson('/gifts/buy',{'giftId':item.id,'idempotencyKey':'buy-${item.id}-${DateTime.now().microsecondsSinceEpoch}'});
        economy.setGems((result['gems'] as num?)?.toInt()??economy.gems); economy.addItem(item.id,1);
      }catch(e){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الشراء: $e'),backgroundColor:Colors.redAccent));
      }
      return;
    }
    if(economy.spendGems(item.gems)){economy.addItem(item.id,1);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('✅ ${item.name} دخل المخزون')));}
    else if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('❌ Gems غير كافية')));
  }
  void _details(NexoCatalogItem item,int owned){
    showDialog(context:context,builder:(_)=>AlertDialog(
      backgroundColor:NexoColors.card,
      title:Text(item.name,style:TextStyle(color:item.rarity.color,fontWeight:FontWeight.bold)),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        NexoAssetArt(item:item,size:130),
        Text(item.rarity.label,style:TextStyle(color:item.rarity.color,fontWeight:FontWeight.bold)),
        const SizedBox(height:6),
        Text(item.description,style:const TextStyle(color:Colors.white70),textAlign:TextAlign.center),
        const SizedBox(height:8),
        Text(item.tradeable?'Tradeable':'Non-tradeable',style:const TextStyle(color:NexoColors.textSecondary,fontSize:12)),
        if(item.gems>0)...[const SizedBox(height:5),Text('${item.gems} Gems',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.bold))],
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إغلاق')),
        if(item.marketVisible&&item.gems>0)ElevatedButton.icon(onPressed:(){ Navigator.pop(context); _buy(item); },icon:const Icon(Icons.shopping_bag_outlined),label:Text(owned>0?'شراء نسخة أخرى':'شراء')),
      ],
    ));
  }
  Widget _itemCard(NexoCatalogItem item){
    final owned=context.watch<EconomyService>().inventory[item.id]??0;
    return InkWell(
      onTap:()=>_details(item,owned),
      borderRadius:BorderRadius.circular(18),
      child:Container(
        padding:const EdgeInsets.all(10),
        decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(18),border:Border.all(color:item.rarity.color.withOpacity(.32))),
        child:Column(children:[
          Expanded(child:NexoAssetArt(item:item,size:86)),
          Text(item.name,maxLines:1,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:11)),
          const SizedBox(height:3),
          Text(item.rarity.label,maxLines:1,style:TextStyle(color:item.rarity.color,fontSize:9)),
          Text('x$owned',style:TextStyle(color:owned>0?NexoColors.success:NexoColors.textSecondary,fontSize:9,fontWeight:FontWeight.bold)),
          const SizedBox(height:5),
          if(item.type==NexoItemType.crafted)
            const Text('Workshop',style:TextStyle(color:NexoColors.textSecondary,fontSize:10))
          else if(item.gems>0)
            Text('${item.gems} 💎',style:const TextStyle(color:NexoColors.primary,fontSize:10,fontWeight:FontWeight.bold)),
        ]),
      ),
    );
  }
  @override Widget build(BuildContext context){
    final catalog=context.watch<NexoCatalogService>();
    final all=catalog.items.where((x)=>x.active).toList();
    final typeFor=(i)=>[NexoItemType.gift,NexoItemType.frame,NexoItemType.asset,NexoItemType.emoji,NexoItemType.crafted][i];
    final gems=context.watch<EconomyService>().gems;
    return Scaffold(
      backgroundColor:NexoColors.background,
      appBar:AppBar(
        backgroundColor:NexoColors.background,title:const Text('Market'),centerTitle:true,
        actions:[Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Center(child:Text('💎 $gems',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.bold))))],
        bottom:TabBar(controller:_tabs,isScrollable:true,tabs:_labels.map((x)=>Tab(text:x)).toList()),
      ),
      body:TabBarView(controller:_tabs,children:[
        ...List.generate(5,(i){
          final items=all.where((x)=>x.type==typeFor(i)).toList();
          return RefreshIndicator(
            onRefresh:catalog.refresh,
            child:items.isEmpty?ListView(children:[SizedBox(height:260,child:Center(child:Text('مفيش عناصر في القسم ده',style:const TextStyle(color:NexoColors.textSecondary))))]):
              GridView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:.78),itemBuilder:(_,j)=>_itemCard(items[j])),
          );
        }),
        ListView(padding:const EdgeInsets.all(16),children:[
          Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(18),border:Border.all(color:NexoColors.primary.withOpacity(.28))),
            child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Trade Hub',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),
              SizedBox(height:8),Text('4 slots + Gems + Escrow + 5% Treasury fee + cancellation/dispute. العناصر غير القابلة للتداول مرفوضة من السيرفر.',style:TextStyle(color:NexoColors.textSecondary,height:1.5))
            ])),
          const SizedBox(height:14),
          ElevatedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const TradeScreen())),icon:const Icon(Icons.swap_horiz_rounded),label:const Text('فتح صفقة 1-to-1')),
        ]),
      ]),
    );
  }
}
