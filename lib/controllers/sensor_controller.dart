import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class SensorController {
  static const double _kaabahLat = 21.4225;
  static const double _kaabahLon = 39.8262;

  /// Hitung bearing dari posisi user ke Ka'bah, hasil dalam [0, 360)
  static double calculateQiblaDirection(double userLat, double userLon) {
    final lat1 = userLat * math.pi / 180;
    final lat2 = _kaabahLat * math.pi / 180;
    final dLon = (_kaabahLon - userLon) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  Stream<MagnetometerEvent> get magnetometerStream =>
      magnetometerEventStream();
  Stream<AccelerometerEvent> get accelerometerStream =>
      accelerometerEventStream();

  bool isShake(AccelerometerEvent event, {double threshold = 15.0}) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    return magnitude > threshold;
  }
}
