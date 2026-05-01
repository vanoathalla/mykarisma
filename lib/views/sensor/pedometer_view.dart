import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../controllers/sensor_controller.dart';
import '../../theme/app_theme.dart';

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
      appBar: AppBar(
        title: const Text('Pedometer'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_walk, size: 80, color: AppTheme.primary),
            const SizedBox(height: 20),
            Text(
              '$_langkah',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const Text(
              'langkah',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            const Text(
              'Goyangkan perangkat untuk reset',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleAktif,
                  icon: Icon(_aktif ? Icons.stop : Icons.play_arrow),
                  label: Text(_aktif ? 'Stop' : 'Mulai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
