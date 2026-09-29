import 'package:flutter/material.dart';
import '../models/frame_model.dart';
import '../services/frame_service.dart';
import '../widgets/frame_asset.dart';
import '../theme/nexo_theme.dart';

class FramesScreen extends StatefulWidget {
  const FramesScreen({super.key});
  @override State<FramesScreen> createState() => _FramesScreenState();
}
class _FramesScreenState extends State<FramesScreen> {
  final FrameService service = FrameService();
  @override void initState(){super.initState();service.load();}
  @override void dispose(){service.dispose();super.dispose();}
  Color rarityColor(FrameRarity r)=>switch(r){
    FrameRarity.common=>const Color(0xFF9E9E9E),FrameRarity.uncommon=>const Color(0xFF4CAF50),
    FrameRarity.rare=>const Color(0xFF42A5F5),FrameRarity.epic=>const Color(0xFFAB47BC),
    FrameRarity.legendary=>const Color(0xFFFFC107),FrameRarity.mythic=>const Color(0xFFE040FB)};
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:NexoColors.background,appBar:AppBar(title:const Text('الإطارات • Frames')),
    body:AnimatedBuilder(animation:service,builder:(context,_)=>ListView(padding:const EdgeInsets.all(14),children:[
      _current(),const SizedBox(height:18),for(final r in FrameRarity.values)_section(r)])));
  Widget _current(){final f=service.selectedFrame;return Container(padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(18)),
    child:Row(children:[if(f!=null)FrameAsset(frame:f,size:96)else const SizedBox(width:96,height:96),
      const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('الإطار الحالي',style:TextStyle(color:NexoColors.textSecondary)),const SizedBox(height:4),
        Text(f?.name??'بدون إطار',style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)),
        if(f!=null)Text(f.rarity.label,style:TextStyle(color:rarityColor(f.rarity),fontWeight:FontWeight.w700))]))]));}
  Widget _section(FrameRarity rarity){final fs=nexoFrames.where((f)=>f.rarity==rarity).toList();final color=rarityColor(rarity);
    return Padding(padding:const EdgeInsets.only(bottom:20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Container(width:9,height:9,decoration:BoxDecoration(color:color,shape:BoxShape.circle)),const SizedBox(width:8),
        Text(rarity.label,style:TextStyle(color:color,fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(width:7),
        Text('('+fs.length.toString()+')',style:const TextStyle(color:NexoColors.textSecondary))]),const SizedBox(height:9),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:fs.length,
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:.78),
        itemBuilder:(context,i){final f=fs[i],active=service.selectedFrameId==f.id;return InkWell(borderRadius:BorderRadius.circular(14),
          onTap:()async{await service.equip(f.id);},child:Container(padding:const EdgeInsets.all(6),
            decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(14),border:Border.all(color:active?color:color.withOpacity(.25),width:active?2:1)),
            child:Column(children:[Expanded(child:FrameAsset(frame:f,size:86)),
              Text(f.name,maxLines:2,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700)),
              if(f.requirement!=null)Text(f.requirement!,style:TextStyle(color:color,fontSize:9))])));})])]);}
}