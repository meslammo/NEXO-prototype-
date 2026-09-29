import 'package:flutter/material.dart';
import '../models/frame_model.dart';
import 'frame_asset.dart';

class FrameAvatar extends StatelessWidget {
  final Widget child;
  final NexoFrame? frame;
  final double size;
  const FrameAvatar({super.key,required this.child,required this.frame,this.size=96});

  @override
  Widget build(BuildContext context)=>SizedBox(
    width:size,height:size,
    child:Stack(alignment:Alignment.center,children:[
      ClipOval(child:SizedBox(width:size*.60,height:size*.60,child:child)),
      if(frame!=null) Positioned.fill(child:IgnorePointer(child:FrameAsset(frame:frame!,size:size))),
    ]),
  );
}