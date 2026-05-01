import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../controllers/sensor_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class PedometerView extends StatefulWidget {
  const PedometerView({super.key});

  @override
  State<PedometerView> createState() => _PedometerViewState();
}

class _PedometerViewState extends State<PedometerView> {
  int _langkah = 0;
  bool _aktif = false;
  StreamSubscription<AccelerometerEvent>? _sub;
  double _prevMagnitude = 0;

  void _toggleAktif() {
    if (_aktif) {
      _sub?.cancel();
      _sub = null;
      setState(() => _aktif = false);
    } else {
      final sensorCtrl = SensorController();
      _sub = sensorCtrl.accelerometerStream.listen((event) {
        final magnitude = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        // Deteksi shake: reset langkah
        if (magnitude > 20) {
          if (mounted) {
            setState(() => _langkah = 0);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Langkah direset!'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
        // Deteksi langkah: threshold crossing
        else if (magnitude > 12 && _prevMagnitude <= 12) {
          if (mounted) {
            setState(() => _langkah++);
          }
        }

        _prevMagnitude = magnitude;
      });
      setState(() => _aktif = true);
    }
  }

  void _reset() {
    setState(() => _langkah = 0);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppTheme.onSurface, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Pedometer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
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
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_walk_rounded,
                        size: 60,
                        color: _aktif ? AppTheme.primary : AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '$_langkah',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Text(
                      'langkah',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_aktif)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PulsingDot(color: AppTheme.primary),
                          const SizedBox(width: 6),
                          const Text(
                            'AKTIF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 40),
                    const Text(
                      'Goyangkan perangkat untuk reset',
                      style: TextStyle(fontSize: 12, color: AppTheme.outline),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _toggleAktif,
                            icon: Icon(
                              _aktif ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: Text(_aktif ? 'Stop' : 'Mulai'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
