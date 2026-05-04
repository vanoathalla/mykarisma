import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status pejalan kaki
enum WalkingStatus { walking, stopped, unknown }

/// Deteksi langkah berbasis accelerometer (sensors_plus).
///
/// Algoritma Peak Detection:
/// - Hitung magnitude vektor akselerasi: √(x²+y²+z²)
/// - Kurangi gravitasi (low-pass filter) → dapat sinyal gerakan bersih
/// - Deteksi "puncak" (peak) saat magnitude melewati threshold naik lalu turun
/// - Setiap peak = 1 langkah
/// - Cooldown 250ms antar langkah agar tidak double-count
///
/// Keunggulan vs package pedometer:
/// - Bekerja di semua HP tanpa hardware step-counter chip
/// - Tidak butuh permission ACTIVITY_RECOGNITION
/// - Responsif — update real-time dari accelerometer stream
class PedometerController {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final PedometerController _instance = PedometerController._internal();
  factory PedometerController() => _instance;
  PedometerController._internal();

  // ── User ID untuk isolasi langkah per-user ────────────────────────────────
  String _userId = 'guest';

  String get _keyDay => 'pedometer_day_$_userId';
  String get _keySteps => 'pedometer_steps_today_$_userId';

  // ── Konstanta algoritma ────────────────────────────────────────────────────
  /// Threshold magnitude di atas gravitasi untuk dihitung sebagai langkah.
  /// Nilai lebih kecil = lebih sensitif. Range yang baik: 1.2 – 2.5
  static const double _stepThreshold = 1.5;

  /// Gravitasi standar (m/s²)
  static const double _gravity = 9.81;

  /// Cooldown minimum antar langkah (ms) — cegah double-count
  static const int _cooldownMs = 250;

  /// Window low-pass filter (0–1). Makin kecil = makin smooth
  static const double _lpAlpha = 0.1;

  // ── Target harian ──────────────────────────────────────────────────────────
  static const int dailyTarget = 1000;

  // ── State internal ─────────────────────────────────────────────────────────
  int _stepsToday = 0;
  WalkingStatus _status = WalkingStatus.unknown;
  bool _initialized = false;

  // Low-pass filtered gravity component
  double _lpX = 0, _lpY = 0, _lpZ = _gravity;

  // Peak detection state
  bool _rising = false;
  DateTime _lastStep = DateTime.fromMillisecondsSinceEpoch(0);

  // Walking detection: hitung berapa event berturut-turut ada gerakan
  int _activeCount = 0;
  static const int _walkingThreshold = 4;

  // ── Stream controllers ─────────────────────────────────────────────────────
  final _stepsCtrl = StreamController<int>.broadcast();
  final _statusCtrl = StreamController<WalkingStatus>.broadcast();

  Stream<int> get stepsStream => _stepsCtrl.stream;
  Stream<WalkingStatus> get statusStream => _statusCtrl.stream;

  int get stepsToday => _stepsToday;
  WalkingStatus get walkingStatus => _status;

  // ── Subscription ──────────────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accSub;
  Timer? _walkingTimer;

  // ── Init ───────────────────────────────────────────────────────────────────
  /// Inisialisasi dengan userId agar langkah tiap user terpisah.
  /// Panggil ini setelah login berhasil.
  Future<void> initForUser(String userId) async {
    if (_userId == userId && _initialized) return;
    // Jika user berbeda, reset state dan reinit
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
      samplingPeriod: const Duration(milliseconds: 20), // 50 Hz
    ).listen(
      _onAccelerometer,
      onError: (e) {
        debugPrint('[PedometerController] accelerometer error: $e');
      },
    );
  }

  void _onAccelerometer(AccelerometerEvent e) {
    // ── 1. Low-pass filter untuk isolasi gravitasi ──────────────────────────
    _lpX = _lpAlpha * e.x + (1 - _lpAlpha) * _lpX;
    _lpY = _lpAlpha * e.y + (1 - _lpAlpha) * _lpY;
    _lpZ = _lpAlpha * e.z + (1 - _lpAlpha) * _lpZ;

    // ── 2. High-pass: sinyal gerakan bersih (tanpa gravitasi) ───────────────
    final hpX = e.x - _lpX;
    final hpY = e.y - _lpY;
    final hpZ = e.z - _lpZ;

    // ── 3. Magnitude sinyal gerakan ─────────────────────────────────────────
    final mag = math.sqrt(hpX * hpX + hpY * hpY + hpZ * hpZ);

    // ── 4. Peak detection ───────────────────────────────────────────────────
    if (mag > _stepThreshold) {
      if (!_rising) {
        // Mulai naik — catat sebagai kandidat langkah
        _rising = true;
      }
      _activeCount = (_activeCount + 1).clamp(0, _walkingThreshold + 2);
    } else {
      if (_rising) {
        // Turun setelah naik = satu peak = satu langkah
        _rising = false;
        _tryCountStep();
      }
      _activeCount = (_activeCount - 1).clamp(0, _walkingThreshold + 2);
    }

    // ── 5. Update walking status ────────────────────────────────────────────
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
    if (elapsed < _cooldownMs) return; // terlalu cepat, abaikan

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

  /// Baca langkah hari ini dari cache — untuk widget beranda (tanpa stream).
  /// Perlu userId agar baca data user yang benar.
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

  /// Reset manual
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
