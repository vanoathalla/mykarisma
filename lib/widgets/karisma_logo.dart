import 'package:flutter/material.dart';

class KarismaLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const KarismaLogo({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/images/logo-karisma.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (color != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: img,
      );
    }

    return img;
  }
}
