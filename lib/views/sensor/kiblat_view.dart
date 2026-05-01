import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../controllers/sensor_controller.dart';
import '../../theme/app_theme.dart';

class KiblatView extends StatefulWidget {
  const KiblatView({super.key});

  @override
  State<KiblatView> createState() => _KiblatViewState();
}

class _KiblatViewState extends State<KiblatView> {
  double _qiblaDirection = 0;
  double _compassHeading = 0;
  bool _loading = true;
  String? _errorMsg;
  StreamSubscription<MagnetometerEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _initKiblat();
  }

  Future<void> _initKiblat() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    // Minta izin lokasi
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _qiblaDirection = SensorController.calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );

      // Subscribe ke magnetometer stream
      final sensorCtrl = SensorController();
      _sub = sensorCtrl.magnetometerStream.listen((event) {
        // Hitung heading dari magnetometer (azimuth sederhana)
        final heading = math.atan2(event.y, event.x) * 180 / math.pi;
        if (mounted) {
          setState(() {
            _compassHeading = (heading + 360) % 360;
          });
        }
      });

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kompas Kiblat'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _errorMsg != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMsg!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Arah Kiblat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_qiblaDirection.toStringAsFixed(1)}° dari Utara',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Transform.rotate(
                        angle: (_qiblaDirection - _compassHeading) *
                            math.pi /
                            180,
                        child: CustomPaint(
                          size: const Size(250, 250),
                          painter: _CompassPainter(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Hadapkan perangkat ke arah jarum',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Gambar lingkaran kompas
    final circlePaint = Paint()
      ..color = Colors.teal.shade50
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    final borderPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, borderPaint);

    // Gambar jarum merah (utara / arah Ka'bah)
    final redPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final northPath = Path();
    northPath.moveTo(center.dx, center.dy - radius * 0.75);
    northPath.lineTo(center.dx - 10, center.dy);
    northPath.lineTo(center.dx + 10, center.dy);
    northPath.close();
    canvas.drawPath(northPath, redPaint);

    // Gambar jarum putih (selatan)
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final southPath = Path();
    southPath.moveTo(center.dx, center.dy + radius * 0.75);
    southPath.lineTo(center.dx - 10, center.dy);
    southPath.lineTo(center.dx + 10, center.dy);
    southPath.close();
    canvas.drawPath(southPath, whitePaint);

    // Border jarum putih
    final whiteBorderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(southPath, whiteBorderPaint);

    // Gambar titik tengah
    final centerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerPaint);

    final centerInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerInnerPaint);

    // Gambar teks "Ka'bah" di ujung jarum merah
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "Ka'bah",
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - radius * 0.75 - textPainter.height - 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
