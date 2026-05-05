import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WalkingStatus { walking, stopped, unknown }

class PedometerController {
  static final PedometerController _instance = PedometerController._internal();
  factory PedometerController() => _instance;
  PedometerController._internal();

  String _userId = 'guest';

  String get _keyDay => 'pedometer_day_$_userId';
  String get _keySteps => 'pedometer_steps_today_$_userId';

  static const double _stepThreshold = 1.5;

  static const double _gravity = 9.81;

  static const int _cooldownMs = 250;

  static const double _lpAlpha = 0.1;

  static const int dailyTarget = 1000;

  int _stepsToday = 0;
  WalkingStatus _status = WalkingStatus.unknown;
  bool _initialized = false;

  double _lpX = 0, _lpY = 0, _lpZ = _gravity;

  bool _rising = false;
  DateTime _lastStep = DateTime.fromMillisecondsSinceEpoch(0);

  int _activeCount = 0;
  static const int _walkingThreshold = 4;

  final _stepsCtrl = StreamController<int>.broadcast();
  final _statusCtrl = StreamController<WalkingStatus>.broadcast();

  Stream<int> get stepsStream => _stepsCtrl.stream;
  Stream<WalkingStatus> get statusStream => _statusCtrl.stream;

  int get stepsToday => _stepsToday;
  WalkingStatus get walkingStatus => _status;

  StreamSubscription<AccelerometerEvent>? _accSub;
  Timer? _walkingTimer;

  Future<void> initForUser(String userId) async {
    if (_userId == userId && _initialized) return;
    if (_userId != userId) {
      _userId = userId;
      _stepsToday = 0;
      _initialized = false;
      _accSub?.cancel();
      _accSub = null;
    }
    await initialize();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadSteps();
    _startListening();
  }

  Future<void> _loadSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final savedDay = prefs.getString(_keyDay) ?? '';
    if (savedDay == today) {
      _stepsToday = prefs.getInt(_keySteps) ?? 0;
    } else {
      _stepsToday = 0;
      await prefs.setString(_keyDay, today);
      await prefs.setInt(_keySteps, 0);
    }
  }

  void _startListening() {
    _accSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(
      _onAccelerometer,
      onError: (e) {
        debugPrint('[PedometerController] accelerometer error: $e');
      },
    );
  }

  void _onAccelerometer(AccelerometerEvent e) {
    _lpX = _lpAlpha * e.x + (1 - _lpAlpha) * _lpX;
    _lpY = _lpAlpha * e.y + (1 - _lpAlpha) * _lpY;
    _lpZ = _lpAlpha * e.z + (1 - _lpAlpha) * _lpZ;

    final hpX = e.x - _lpX;
    final hpY = e.y - _lpY;
    final hpZ = e.z - _lpZ;

    final mag = math.sqrt(hpX * hpX + hpY * hpY + hpZ * hpZ);

    if (mag > _stepThreshold) {
      if (!_rising) {
        _rising = true;
      }
      _activeCount = (_activeCount + 1).clamp(0, _walkingThreshold + 2);
    } else {
      if (_rising) {
        _rising = false;
        _tryCountStep();
      }
      _activeCount = (_activeCount - 1).clamp(0, _walkingThreshold + 2);
    }

    final newStatus = _activeCount >= _walkingThreshold
        ? WalkingStatus.walking
        : WalkingStatus.stopped;

    if (newStatus != _status) {
      _status = newStatus;
      _statusCtrl.add(_status);
    }
  }

  void _tryCountStep() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastStep).inMilliseconds;
    if (elapsed < _cooldownMs) return;

    _lastStep = now;
    _stepsToday++;
    _stepsCtrl.add(_stepsToday);
    _saveSteps();
  }

  Future<void> _saveSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keySteps, _stepsToday);
      await prefs.setString(_keyDay, _todayKey());
    } catch (e) {
      debugPrint('[PedometerController] save error: $e');
    }
  }

  static Future<int> readStepsTodayCached({String userId = 'guest'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyDay = 'pedometer_day_$userId';
      final keySteps = 'pedometer_steps_today_$userId';
      final savedDay = prefs.getString(keyDay) ?? '';
      if (savedDay != _todayKey()) return 0;
      return prefs.getInt(keySteps) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> resetToday() async {
    _stepsToday = 0;
    _activeCount = 0;
    _rising = false;
    _status = WalkingStatus.stopped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySteps, 0);
    await prefs.setString(_keyDay, _todayKey());
    _stepsCtrl.add(0);
    _statusCtrl.add(_status);
  }

  void dispose() {
    _accSub?.cancel();
    _walkingTimer?.cancel();
    _stepsCtrl.close();
    _statusCtrl.close();
    _initialized = false;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
