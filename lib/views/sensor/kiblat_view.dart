import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../controllers/sensor_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class KiblatView extends StatefulWidget {
  const KiblatView({super.key});

  @override
  State<KiblatView> createState() => _KiblatViewState();
}

class _KiblatViewState extends State<KiblatView>
    with SingleTickerProviderStateMixin {
  double _qiblaDirection = 0;
  double _compassHeading = 0;
  bool _loading = true;
  String? _errorMsg;
  StreamSubscription<MagnetometerEvent>? _magnetSub;
  late AnimationController _rotAnim;
  double _targetAngle = 0;

  @override
  void initState() {
    super.initState();
    _rotAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initKiblat();
  }

  Future<void> _initKiblat() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Izin lokasi diperlukan untuk menampilkan arah kiblat';
          _loading = false;
        });
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Rumus great-circle bearing (haversine-based) yang akurat
      _qiblaDirection = SensorController.calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );

      final sensorCtrl = SensorController();
      _magnetSub = sensorCtrl.magnetometerStream.listen((event) {
        // Hitung azimuth dari magnetometer menggunakan atan2
        // event.x = East, event.y = North pada orientasi landscape
        // Untuk portrait: heading = atan2(-event.x, event.y)
        final heading = math.atan2(-event.x, event.y) * 180 / math.pi;
        final normalizedHeading = (heading + 360) % 360;

        if (mounted) {
          setState(() {
            _compassHeading = normalizedHeading;
            // Sudut rotasi jarum = arah kiblat - heading perangkat
            _targetAngle = (_qiblaDirection - normalizedHeading) * math.pi / 180;
          });
        }
      });

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Sensor kompas tidak tersedia di perangkat ini';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _magnetSub?.cancel();
    _rotAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1C1C) : AppTheme.background;
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF889390) : AppTheme.outline;
    final cardBg = isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLowest;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────
          Container(
            color: isDark
                ? const Color(0xFF1A1C1C).withValues(alpha: 0.95)
                : AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: textPrimary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Kompas Kiblat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppTheme.primary),
                          onPressed: _initKiblat,
                        ),
                      ],
                    ),
                  ),
                  Container(
                      height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _errorMsg != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off_rounded,
                                  size: 56, color: textSub),
                              const SizedBox(height: 16),
                              Text(
                                _errorMsg!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14, color: textSub, height: 1.5),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _initKiblat,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.explore_rounded,
                                        color: AppTheme.primary, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Arah Kiblat',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${_qiblaDirection.toStringAsFixed(1)}° dari Utara Magnetik',
                                          style: TextStyle(
                                              fontSize: 12, color: textSub),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      PulsingDot(color: AppTheme.primary),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Compass
                            Transform.rotate(
                              angle: _targetAngle,
                              child: CustomPaint(
                                size: const Size(280, 280),
                                painter: _CompassPainter(isDark: isDark),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Heading info
                            Text(
                              'Heading: ${_compassHeading.toStringAsFixed(0)}°',
                              style: TextStyle(fontSize: 13, color: textSub),
                            ),

                            const SizedBox(height: 32),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 16, color: textSub),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hadapkan jarum merah ke arah Ka\'bah',
                                    style: TextStyle(
                                        fontSize: 12, color: textSub),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final bool isDark;
  const _CompassPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.primary.withValues(alpha: isDark ? 0.08 : 0.05)
        ..style = PaintingStyle.fill,
    );

    // Outer border
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Inner ring
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()
        ..color = AppTheme.outlineVariant.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Cardinal direction ticks
    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180;
      final isMajor = i % 9 == 0;
      final tickLen = isMajor ? 16.0 : 8.0;
      final outer = Offset(
        center.dx + (radius - 6) * math.sin(angle),
        center.dy - (radius - 6) * math.cos(angle),
      );
      final inner = Offset(
        center.dx + (radius - 6 - tickLen) * math.sin(angle),
        center.dy - (radius - 6 - tickLen) * math.cos(angle),
      );
      canvas.drawLine(
        outer,
        inner,
        Paint()
          ..color = AppTheme.outline.withValues(alpha: isMajor ? 0.6 : 0.25)
          ..strokeWidth = isMajor ? 2 : 1,
      );
    }

    // Red needle (Ka'bah direction — north of compass)
    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - radius * 0.75);
    needlePath.lineTo(center.dx - 10, center.dy + 10);
    needlePath.lineTo(center.dx, center.dy + 4);
    needlePath.lineTo(center.dx + 10, center.dy + 10);
    needlePath.close();
    canvas.drawPath(needlePath, Paint()..color = Colors.red.shade600);

    // White needle (south)
    final southPath = Path();
    southPath.moveTo(center.dx, center.dy + radius * 0.75);
    southPath.lineTo(center.dx - 10, center.dy - 10);
    southPath.lineTo(center.dx, center.dy - 4);
    southPath.lineTo(center.dx + 10, center.dy - 10);
    southPath.close();
    canvas.drawPath(
      southPath,
      Paint()
        ..color = isDark ? Colors.white54 : Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      southPath,
      Paint()
        ..color = AppTheme.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Center dot
    canvas.drawCircle(
        center, 12, Paint()..color = isDark ? const Color(0xFF252828) : Colors.white);
    canvas.drawCircle(
        center, 12, Paint()..color = AppTheme.outline.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(center, 5, Paint()..color = Colors.red.shade600);

    // Ka'bah label
    final tp = TextPainter(
      text: TextSpan(
        text: "Ka'bah ▲",
        style: TextStyle(
          color: Colors.red.shade600,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(
        center.dx - tp.width / 2,
        center.dy - radius * 0.75 - tp.height - 8,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.isDark != isDark;
}
