import 'package:flutter/material.dart';
import '../models/frame_model.dart';

class FrameAsset extends StatelessWidget {
  final NexoFrame frame;
  final double size;
  const FrameAsset({super.key,required this.frame,this.size=96});

  @override
  Widget build(BuildContext context) {
    const cols=6.0, rows=6.0;
    final w=size*cols, h=size*rows;
    return SizedBox(width:size,height:size,child:ClipRect(
      child: Transform.translate(
        offset:Offset(-frame.column*size,-frame.row*size),
        child:SizedBox(width:w,height:h,child:Image.asset(frame.assetPath,fit:BoxFit.fill,filterQuality:FilterQuality.high)),
      ),
    ));
  }
}