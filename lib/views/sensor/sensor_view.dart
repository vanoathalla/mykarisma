import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../controllers/sensor_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class SensorView extends StatefulWidget {
  const SensorView({super.key});

  @override
  State<SensorView> createState() => _SensorViewState();
}

class _SensorViewState extends State<SensorView> {
  final SensorController _sensorCtrl = SensorController();

  // Accelerometer
  double _accX = 0, _accY = 0, _accZ = 9.81;
  final Queue<double> _accHistory = Queue();

  // Gyroscope
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;
  final Queue<double> _gyroHistory = Queue();

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  static const int _historyLen = 40;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _accSub = _sensorCtrl.accelerometerStream.listen((event) {
      if (!mounted) return;
      setState(() {
        _accX = event.x;
        _accY = event.y;
        _accZ = event.z;
        final mag = (_accX * _accX + _accY * _accY + _accZ * _accZ);
        _accHistory.addLast(mag.clamp(0, 400).toDouble());
        if (_accHistory.length > _historyLen) _accHistory.removeFirst();
      });
    });

    _gyroSub = gyroscopeEventStream().listen((event) {
      if (!mounted) return;
      setState(() {
        _gyroX = event.x;
        _gyroY = event.y;
        _gyroZ = event.z;
        final mag = (_gyroX * _gyroX + _gyroY * _gyroY + _gyroZ * _gyroZ);
        _gyroHistory.addLast(mag.clamp(0, 50).toDouble());
        if (_gyroHistory.length > _historyLen) _gyroHistory.removeFirst();
      });
    });
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _gyroSub?.cancel();
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
                            'Live Telemetry',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            PulsingDot(color: AppTheme.primary),
                            const SizedBox(width: 6),
                            const Text(
                              'REAL-TIME',
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
                  Container(
                      height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Accelerometer Card ──────────────────────────────
                  _SensorCard(
                    title: 'Accelerometer',
                    subtitle: 'Percepatan linear (m/s²)',
                    icon: Icons.vibration_rounded,
                    iconColor: AppTheme.primary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSub: textSub,
                    waveData: _accHistory.toList(),
                    waveColor: AppTheme.primary,
                    maxVal: 400,
                    values: [
                      _SensorValue(label: 'X', value: _accX, unit: 'm/s²', color: Colors.red),
                      _SensorValue(label: 'Y', value: _accY, unit: 'm/s²', color: Colors.green),
                      _SensorValue(label: 'Z', value: _accZ, unit: 'm/s²', color: Colors.blue),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Gyroscope Card ──────────────────────────────────
                  _SensorCard(
                    title: 'Gyroscope',
                    subtitle: 'Kecepatan rotasi (rad/s)',
                    icon: Icons.screen_rotation_rounded,
                    iconColor: AppTheme.tertiary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSub: textSub,
                    waveData: _gyroHistory.toList(),
                    waveColor: AppTheme.tertiary,
                    maxVal: 50,
                    values: [
                      _SensorValue(label: 'X', value: _gyroX, unit: 'rad/s', color: Colors.red),
                      _SensorValue(label: 'Y', value: _gyroY, unit: 'rad/s', color: Colors.green),
                      _SensorValue(label: 'Z', value: _gyroZ, unit: 'rad/s', color: Colors.blue),
                    ],
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

// ─── Sensor Card ──────────────────────────────────────────────────────────────
class _SensorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSub;
  final List<double> waveData;
  final Color waveColor;
  final double maxVal;
  final List<_SensorValue> values;

  const _SensorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSub,
    required this.waveData,
    required this.waveColor,
    required this.maxVal,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: textSub),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Waveform
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _WaveformPainter(
                data: waveData,
                color: waveColor,
                maxVal: maxVal,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Values
          Row(
            children: values.map((v) => Expanded(
              child: Column(
                children: [
                  Text(
                    v.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: v.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v.value.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    v.unit,
                    style: TextStyle(fontSize: 10, color: textSub),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _SensorValue {
  final String label;
  final double value;
  final String unit;
  final Color color;
  const _SensorValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });
}

// ─── Waveform Painter ─────────────────────────────────────────────────────────
class _WaveformPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double maxVal;

  const _WaveformPainter({
    required this.data,
    required this.color,
    required this.maxVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barWidth = size.width / 40;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth * 0.6;

    for (int i = 0; i < data.length; i++) {
      final normalized = (data[i] / maxVal).clamp(0.05, 1.0);
      final barHeight = normalized * size.height;
      final x = i * barWidth + barWidth / 2;
      final centerY = size.height / 2;

      // Gradient opacity based on recency
      final opacity = 0.2 + (i / data.length) * 0.8;
      paint.color = color.withValues(alpha: opacity);

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.data != data || old.color != color;
}
