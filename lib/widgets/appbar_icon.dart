import 'package:flutter/material.dart';

import '../constants/app_images.dart';

class AppBarIcon extends StatelessWidget {
  final bool visible; 
  final Color? color;
  final double size;
  final String? tooltip;

  const AppBarIcon({
    this.visible = true,
    super.key,
    this.color,
    this.size = 24.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
    visible: visible,
      child:  Image.asset(AppImages.lightMakoLogo,
            height: 150,
            width: 150,
            // color:
            //     color ?? Theme.of(context).iconTheme.color, // apply color overlay
            
      ),
    );
  }
}
