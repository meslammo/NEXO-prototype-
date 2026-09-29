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

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override State<MarketScreen> createState()=>_MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  static const _labels=['Featured','Frames','Font Color','Entrance','Rooms'];
  static const _types=[
    null,
    NexoItemType.frame,
    NexoItemType.nameColor,
    NexoItemType.entranceEffect,
    NexoItemType.roomBackground,
  ];

  @override void initState(){
    super.initState();
    _tabs=TabController(length:_labels.length,vsync:this);
  }

  @override void dispose(){
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _buy(NexoCatalogItem item) async {
    final economy=context.read<EconomyService>();
    final auth=context.read<AuthService>();
    if(item.gems<=0||!item.marketVisible)return;
    if(NexoApiConfig.configured&&auth.online){
      try{
        final result=await context.read<ApiClient>().postJson('/gifts/buy',{
          'itemId':item.id,
          'idempotencyKey':'market-${item.id}-${DateTime.now().microsecondsSinceEpoch}'
        });
        economy.setGems((result['gems'] as num?)?.toInt()??economy.gems);
        economy.addItem(item.id,1);
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content:Text('✅ ${item.name} اتضاف للكولكشن'))
          );
        }
        return;
      }catch(e){
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content:Text('تعذر الشراء: $e'),backgroundColor:Colors.redAccent)
          );
        }
        return;
      }
    }
    if(economy.spendGems(item.gems)){
      economy.addItem(item.id,1);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('✅ ${item.name} اتضاف للكولكشن'))
      );
    }else if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('❌ Gems غير كافية'))
      );
    }
  }

  Widget _preview(NexoCatalogItem item,double size){
    if(item.image.startsWith('color:')){
      final c=_hex(item.image.substring(6));
      return Container(
        width:size,height:size,
        decoration:BoxDecoration(shape:BoxShape.circle,color:c,boxShadow:[BoxShadow(color:c.withOpacity(.5),blurRadius:18,spreadRadius:2)]),
        alignment:Alignment.center,
        child:const Text('Aa',style:TextStyle(color:Colors.black,fontSize:20,fontWeight:FontWeight.w900))
      );
    }
    if(item.image.startsWith('gradient:')){
      return Container(
        width:size,height:size,
        decoration:BoxDecoration(
          borderRadius:BorderRadius.circular(size*.2),
          gradient:const LinearGradient(colors:[Color(0xFF54D6FF),Color(0xFFB44CFF),Color(0xFFFF6B9D),Color(0xFFFFD166)])
        ),
        alignment:Alignment.center,
        child:const Text('Aa',style:TextStyle(color:Colors.black,fontSize:20,fontWeight:FontWeight.w900))
      );
    }
    return NexoAssetArt(item:item,size:size);
  }

  Color _hex(String raw){
    var s=raw.replaceAll('#','').trim();
    if(s.length==6)s='FF$s';
    return Color(int.tryParse(s,radix:16)??0xFF54D6FF);
  }

  void _details(NexoCatalogItem item,int owned){
    showDialog(
      context:context,
      builder:(_)=>AlertDialog(
        backgroundColor:NexoColors.card,
        title:Text(item.name,style:TextStyle(color:item.rarity.color,fontWeight:FontWeight.bold)),
        content:Column(
          mainAxisSize:MainAxisSize.min,
          children:[
            _preview(item,120),
            const SizedBox(height:12),
            Text(item.tagline,style:const TextStyle(color:Colors.white70),textAlign:TextAlign.center),
            const SizedBox(height:8),
            Text('${item.gems} Gems',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.bold)),
            const SizedBox(height:4),
            Text(owned>0?'مملوك x$owned':'غير مملوك',style:const TextStyle(color:NexoColors.textSecondary)),
          ]
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إغلاق')),
          ElevatedButton.icon(
            onPressed:(){Navigator.pop(context);_buy(item);},
            icon:const Icon(Icons.shopping_bag_outlined),
            label:Text(owned>0?'شراء نسخة أخرى':'شراء')
          ),
        ],
      )
    );
  }

  Widget _itemCard(NexoCatalogItem item){
    final owned=context.watch<EconomyService>().inventory[item.id]??0;
    return InkWell(
      onTap:()=>_details(item,owned),
      borderRadius:BorderRadius.circular(18),
      child:Container(
        padding:const EdgeInsets.all(10),
        decoration:BoxDecoration(
          color:NexoColors.card,
          borderRadius:BorderRadius.circular(18),
          border:Border.all(color:item.rarity.color.withOpacity(.38))
        ),
        child:Column(
          children:[
            Expanded(child:_preview(item,82)),
            Text(item.name,maxLines:1,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:11)),
            const SizedBox(height:3),
            Text(item.rarity.label,style:TextStyle(color:item.rarity.color,fontSize:9)),
            Text(owned>0?'x$owned':'${item.gems} 💎',style:TextStyle(color:owned>0?NexoColors.success:NexoColors.primary,fontSize:10,fontWeight:FontWeight.bold)),
          ]
        ),
      )
    );
  }

  Widget _grid(List<NexoCatalogItem> items)=>RefreshIndicator(
    onRefresh:context.read<NexoCatalogService>().refresh,
    child:items.isEmpty
      ?ListView(children:[SizedBox(height:260,child:Center(child:Text('مفيش عناصر في القسم ده',style:const TextStyle(color:NexoColors.textSecondary))))])
      :GridView.builder(
        padding:const EdgeInsets.all(12),
        itemCount:items.length,
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:.78),
        itemBuilder:(_,i)=>_itemCard(items[i])
      )
  );

  @override Widget build(BuildContext context){
    final catalog=context.watch<NexoCatalogService>();
    final all=catalog.items.where((x)=>x.active&&x.marketVisible).toList();
    final allowed=all.where((x)=>_types.skip(1).contains(x.type)).toList();
    final gems=context.watch<EconomyService>().gems;

    return Scaffold(
      backgroundColor:NexoColors.background,
      appBar:AppBar(
        backgroundColor:NexoColors.background,
        title:const Text('NEXO Store'),
        centerTitle:true,
        actions:[Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Center(child:Text('💎 $gems',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.bold))))],
        bottom:TabBar(controller:_tabs,isScrollable:true,tabs:_labels.map((x)=>Tab(text:x)).toList())
      ),
      body:TabBarView(
        controller:_tabs,
        children:[
          _grid(allowed),
          _grid(all.where((x)=>x.type==NexoItemType.frame).toList()),
          _grid(all.where((x)=>x.type==NexoItemType.nameColor).toList()),
          _grid(all.where((x)=>x.type==NexoItemType.entranceEffect).toList()),
          _grid(all.where((x)=>x.type==NexoItemType.roomBackground).toList()),
        ]
      ),
    );
  }
}