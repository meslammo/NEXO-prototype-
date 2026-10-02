import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nexo_catalog.dart';
import '../services/catalog_service.dart';
import '../services/economy_service.dart';
import '../services/api_client.dart';
import '../services/power_service.dart';
import '../config/api_config.dart';
import '../theme/nexo_theme.dart';

class FontColorScreen extends StatefulWidget{
  const FontColorScreen({super.key});
  @override State<FontColorScreen> createState()=>_FontColorScreenState();
}
class _FontColorScreenState extends State<FontColorScreen>{
  Color _parse(String raw){
    var s=raw.replaceAll('#','');
    if(s.length==6)s='FF'+s;
    return Color(int.tryParse(s,radix:16)??0xFF54D6FF);
  }
  Future<void> _equip(NexoCatalogItem x) async{
    try{
      if(x.type==NexoItemType.power){
        context.read<PowerService>().setActivePower(x.id);
        if(NexoApiConfig.configured){
          await context.read<ApiClient>().postJson('/profile/equipped',{'slot':'power','itemId':x.id});
        }
      }else{
        if(NexoApiConfig.configured){
          await context.read<ApiClient>().postJson('/profile/equipped',{'slot':'name_color','itemId':x.id});
        }
      }
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('✅ تم تفعيل Font Color')));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر التفعيل: '+e.toString()),backgroundColor:Colors.redAccent));
    }
  }
  @override Widget build(BuildContext context){
    final colors=context.watch<NexoCatalogService>().marketItems.where((x)=>x.type==NexoItemType.nameColor||x.type==NexoItemType.power).toList();
    final inv=context.watch<EconomyService>().inventory;
    return Scaffold(
      backgroundColor:NexoColors.background,
      appBar:AppBar(backgroundColor:NexoColors.background,title:const Text('Font Color • Name Style'),centerTitle:true,leading:const BackButton(color:Colors.white)),
      body:GridView.builder(
        padding:const EdgeInsets.all(14),
        itemCount:colors.length,
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.35),
        itemBuilder:(_,i){
          final x=colors[i]; final owned=inv[x.id]??0;
          final c=x.image.startsWith('color:')?_parse(x.image.substring(6)):NexoColors.primary;
          return InkWell(
            onTap:owned>0?()=>_equip(x):null,
            borderRadius:BorderRadius.circular(16),
            child:Container(
              padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:c.withOpacity(.45))),
              child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                Text('Aa',style:TextStyle(color:c,fontSize:30,fontWeight:FontWeight.w900,shadows:[Shadow(color:c.withOpacity(.5),blurRadius:12)])),
                const SizedBox(height:6),
                Text(x.name,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:11)),
                const SizedBox(height:3),
                Text(owned>0?'مملوك x'+owned.toString():'روح السوق للشراء',style:TextStyle(color:owned>0?NexoColors.success:NexoColors.textSecondary,fontSize:9)),
              ])
            )
          );
        }
      )
    );
  }
}