import 'package:flutter/material.dart';

/// Widget logo KARISMA menggunakan file PNG asli.
/// Gunakan sebagai pengganti ikon masjid di seluruh aplikasi.
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

    // Jika ada override color, pakai ColorFiltered untuk tint
    if (color != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: img,
      );
    }

    return img;
  }
}
