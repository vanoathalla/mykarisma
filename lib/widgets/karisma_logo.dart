import 'package:flutter/material.dart';

/// Widget logo KARISMA — menggambar ulang logo berdasarkan desain asli.
/// Terdiri dari ikon daun/orang berwarna biru gradien + teks "KARISMA".
/// Gunakan [KarismaLogo] sebagai pengganti ikon masjid di seluruh aplikasi.
class KarismaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const KarismaLogo({
    super.key,
    this.size = 40,
    this.showText = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    return SizedBox(
      width: showText ? size * 3.2 : size,
      height: size,
      child: CustomPaint(
        painter: _KarismaLogoPainter(iconSize: size, showText: showText, overrideColor: c),
      ),
    );
  }
}

class _KarismaLogoPainter extends CustomPainter {
  final double iconSize;
  final bool showText;
  final Color? overrideColor;

  _KarismaLogoPainter({
    required this.iconSize,
    required this.showText,
    this.overrideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = iconSize;

    // Warna gradien biru (sesuai logo KARISMA)
    final Color accentColor = overrideColor ?? const Color(0xFF42A5F5); // biru muda

    // ── Daun kiri (besar) ──────────────────────────────────────────────────
    final leftLeafPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: overrideColor != null
            ? [overrideColor!, overrideColor!.withValues(alpha: 0.7)]
            : [const Color(0xFF1A237E), const Color(0xFF3949AB)],
      ).createShader(Rect.fromLTWH(0, 0, s * 0.45, s))
      ..style = PaintingStyle.fill;

    final leftLeafPath = Path();
    leftLeafPath.moveTo(s * 0.05, s * 0.55);
    leftLeafPath.cubicTo(
      s * 0.05, s * 0.20,
      s * 0.30, s * 0.05,
      s * 0.42, s * 0.30,
    );
    leftLeafPath.cubicTo(
      s * 0.50, s * 0.50,
      s * 0.35, s * 0.75,
      s * 0.05, s * 0.55,
    );
    canvas.drawPath(leftLeafPath, leftLeafPaint);

    // ── Daun kanan (lebih kecil, lebih terang) ─────────────────────────────
    final rightLeafPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: overrideColor != null
            ? [overrideColor!.withValues(alpha: 0.8), overrideColor!.withValues(alpha: 0.5)]
            : [const Color(0xFF3F51B5), const Color(0xFF7986CB)],
      ).createShader(Rect.fromLTWH(s * 0.20, 0, s * 0.45, s))
      ..style = PaintingStyle.fill;

    final rightLeafPath = Path();
    rightLeafPath.moveTo(s * 0.45, s * 0.55);
    rightLeafPath.cubicTo(
      s * 0.45, s * 0.25,
      s * 0.65, s * 0.10,
      s * 0.72, s * 0.35,
    );
    rightLeafPath.cubicTo(
      s * 0.78, s * 0.55,
      s * 0.65, s * 0.75,
      s * 0.45, s * 0.55,
    );
    canvas.drawPath(rightLeafPath, rightLeafPaint);

    // ── Lingkaran kepala (orang) ───────────────────────────────────────────
    final headPaint = Paint()
      ..color = overrideColor ?? accentColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(s * 0.42, s * 0.18),
      s * 0.10,
      headPaint,
    );

    // ── Titik aksen kecil ──────────────────────────────────────────────────
    final dotPaint = Paint()
      ..color = overrideColor ?? accentColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(s * 0.60, s * 0.12),
      s * 0.04,
      dotPaint,
    );

    // ── Teks "KARISMA" (opsional) ──────────────────────────────────────────
    if (showText) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'KARISMA',
          style: TextStyle(
            fontSize: s * 0.38,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: overrideColor != null
                    ? [overrideColor!, overrideColor!]
                    : [const Color(0xFF1565C0), const Color(0xFF283593)],
              ).createShader(Rect.fromLTWH(s * 1.0, 0, s * 2.2, s * 0.4)),
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(s * 1.05, s * 0.30));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
