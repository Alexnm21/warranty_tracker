import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SvgIcon extends StatelessWidget {
  final String iconName;
  final Color? color;
  final double? size;
  const SvgIcon({super.key, required this.iconName, this.color, this.size});

  String get iconRoute => 'assets/svg/$iconName.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      iconRoute,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
