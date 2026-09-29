import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/frame_model.dart';

class FrameAsset extends StatelessWidget {
  final NexoFrame frame;
  final double size;
  const FrameAsset({super.key, required this.frame, this.size = 96});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: ClipRect(child: Transform.translate(
      offset: Offset(-frame.column * size, -frame.row * size),
      child: SizedBox(width: size * 6, height: size * 6, child: SvgPicture.asset(frame.assetPath, width: size * 6, height: size * 6, fit: BoxFit.fill)),
    )));
  }
}
