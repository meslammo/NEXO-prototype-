import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/nexo_catalog.dart';

class NexoAssetArt extends StatefulWidget{
  final NexoCatalogItem item;
  final double size;
  final bool showGlow;
  const NexoAssetArt({super.key,required this.item,this.size=72,this.showGlow=true});
  @override State<NexoAssetArt> createState()=>_NexoAssetArtState();
}
class _NexoAssetArtState extends State<NexoAssetArt> with SingleTickerProviderStateMixin{
  late final AnimationController _controller;
  @override void initState(){super.initState();_controller=AnimationController(vsync:this,duration:const Duration(milliseconds:2200))..repeat();}
  @override void dispose(){_controller.dispose();super.dispose();}
  Widget _image(){
    final p=widget.item.image;
    if(p.startsWith('emoji:')) return Center(child: Text(p.substring(6),textAlign:TextAlign.center,style:TextStyle(fontSize:widget.size*.62,height:1)));
    if(p.toLowerCase().endsWith('.svg')) return p.startsWith('http')?SvgPicture.network(p,width:widget.size,height:widget.size,fit:BoxFit.contain):SvgPicture.asset(p,width:widget.size,height:widget.size,fit:BoxFit.contain);
    return p.startsWith('http')?Image.network(p,width:widget.size,height:widget.size,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Icon(Icons.broken_image_rounded,color:widget.item.rarity.color,size:widget.size*.5)):Image.asset(p,width:widget.size,height:widget.size,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Icon(Icons.broken_image_rounded,color:widget.item.rarity.color,size:widget.size*.5));
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:_controller,builder:(_,child){
    final t=_controller.value*math.pi*2;
    var scale=1.0,angle=0.0,opacity=1.0;
    switch(widget.item.animation){case 'pulse':scale=1+.035*math.sin(t);break;case 'float':scale=1+.018*math.sin(t);break;case 'orbit':angle=.025*math.sin(t);break;case 'shine':opacity=.8+.2*(.5+.5*math.sin(t));break;case 'rainbow':angle=.018*math.sin(t);scale=1+.02*math.sin(t*2);break;}
    return Transform.rotate(angle:angle,child:Transform.scale(scale:scale,child:Opacity(opacity:opacity,child:Container(width:widget.size,height:widget.size,decoration:widget.showGlow?BoxDecoration(boxShadow:[BoxShadow(color:widget.item.rarity.color.withOpacity(.18),blurRadius:18,spreadRadius:2)]):null,child:child))));
  },child:_image());
}
