import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/acara_model.dart';

/// NotificationController — mengelola semua notifikasi lokal aplikasi KARISMA.
///
/// Channel yang tersedia:
/// 1. karisma_update  — notif saat admin tambah/update data (acara, keuangan, catatan)
/// 2. karisma_acara   — pengingat H-1 otomatis saat admin tambah acara
/// 3. karisma_hariH   — pengingat hari-H sesuai jam acara (diset oleh member)
/// 4. karisma_langkah — pencapaian langkah ibadah
///
/// Semua notif mengikuti pengaturan suara/getar HP pengguna secara otomatis
/// karena menggunakan Importance.defaultImportance (tidak override sistem).
class NotificationController {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Channel IDs ────────────────────────────────────────────────────────────
  static const String _chUpdate = 'karisma_update';
  static const String _chAcara = 'karisma_acara';
  static const String _chHariH = 'karisma_hariH';
  static const String _chLangkah = 'karisma_langkah';

  // ── Prefs keys ─────────────────────────────────────────────────────────────
  static const String _prefNotifUpdate = 'notif_update_aktif';
  static const String _prefNotifAcara = 'notif_acara_aktif';
  static const String _prefNotifHariH = 'notif_hariH_aktif';

  // ── Initialize ─────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Buat semua channel sekaligus
    // Importance.defaultImportance = ikuti pengaturan HP (suara/getar/diam)
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _chUpdate,
      'Update Data KARISMA',
      description: 'Notifikasi saat admin menambah atau memperbarui data',
      importance: Importance.defaultImportance,
    ));

    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _chAcara,
      'Pengingat Acara H-1',
      description: 'Pengingat otomatis sehari sebelum acara',
      importance: Importance.defaultImportance,
    ));

    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _chHariH,
      'Pengingat Hari-H Acara',
      description: 'Pengingat tepat pada hari dan jam acara berlangsung',
      importance: Importance.defaultImportance,
    ));

    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _chLangkah,
      'Langkah Ibadah',
      description: 'Notifikasi pencapaian langkah harian',
      importance: Importance.defaultImportance,
    ));

    _initialized = true;
  }

  // ── Permission ─────────────────────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── Baca preferensi notifikasi ─────────────────────────────────────────────
  static Future<bool> isNotifUpdateAktif() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefNotifUpdate) ?? true;
  }

  static Future<bool> isNotifAcaraAktif() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefNotifAcara) ?? true;
  }

  static Future<bool> isNotifHariHAktif() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefNotifHariH) ?? true;
  }

  // ── Simpan preferensi notifikasi ───────────────────────────────────────────
  static Future<void> setNotifUpdate(bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotifUpdate, aktif);
  }

  static Future<void> setNotifAcara(bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotifAcara, aktif);
    // Jika dimatikan, batalkan semua notif H-1 yang terjadwal
    if (!aktif) await _plugin.cancelAll();
  }

  static Future<void> setNotifHariH(bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotifHariH, aktif);
  }

  // ── 1. Notif update data (admin tambah/edit) ───────────────────────────────
  /// Dipanggil dari controller saat admin berhasil tambah/update data.
  /// Hanya tampil jika member mengaktifkan notif update.
  static Future<void> showUpdateNotif({
    required String judul,
    required String isi,
    int? id,
  }) async {
    if (!_initialized) return;
    if (!await isNotifUpdateAktif()) return;

    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _chUpdate,
          'Update Data KARISMA',
          channelDescription: 'Notifikasi saat admin menambah atau memperbarui data',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      );
      await _plugin.show(
        id ?? DateTime.now().millisecondsSinceEpoch % 100000,
        judul,
        isi,
        details,
      );
    } catch (e) {
      debugPrint('[NotificationController] showUpdateNotif error: $e');
    }
  }

  // ── 2. Pengingat H-1 otomatis ─────────────────────────────────────────────
  /// Dijadwalkan otomatis saat admin tambah acara.
  /// Muncul jam 08:00 sehari sebelum acara.
  static Future<void> scheduleAcaraNotification(AcaraModel acara) async {
    if (!_initialized) return;
    if (!await isNotifAcaraAktif()) return;

    try {
      final tanggal = DateTime.tryParse(acara.tanggal.split(' ').first);
      if (tanggal == null) return;

      final notifTime = DateTime(
        tanggal.year, tanggal.month, tanggal.day - 1, 8, 0,
      );
      if (notifTime.isBefore(DateTime.now())) return;

      final tzTime = tz.TZDateTime.from(notifTime, tz.local);
      final notifId = (int.tryParse(acara.idAcara) ?? acara.nama.hashCode) + 10000;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _chAcara,
          'Pengingat Acara H-1',
          channelDescription: 'Pengingat otomatis sehari sebelum acara',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      );

      await _plugin.zonedSchedule(
        notifId,
        '📅 Pengingat: Acara Besok!',
        '${acara.nama} — ${acara.tanggal}',
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[NotificationController] H-1 scheduled: ${acara.nama} at $notifTime');
    } catch (e) {
      debugPrint('[NotificationController] scheduleAcaraNotification error: $e');
    }
  }

  // ── 3. Pengingat Hari-H (diset oleh member) ───────────────────────────────
  /// Member bisa set pengingat tepat pada hari & jam acara.
  /// Jika acara punya waktu (format "2025-06-10 16:30"), pakai jam tersebut.
  /// Jika tidak ada jam, default jam 07:00 hari-H.
  static Future<bool> scheduleHariHNotification(AcaraModel acara) async {
    if (!_initialized) return false;
    if (!await isNotifHariHAktif()) return false;

    try {
      DateTime? waktuAcara;

      // Coba parse tanggal + waktu (format: "2025-06-10 16:30")
      if (acara.tanggal.contains(' ')) {
        waktuAcara = DateTime.tryParse(acara.tanggal);
      } else {
        // Hanya tanggal — default jam 07:00
        final tgl = DateTime.tryParse(acara.tanggal);
        if (tgl != null) {
          waktuAcara = DateTime(tgl.year, tgl.month, tgl.day, 7, 0);
        }
      }

      if (waktuAcara == null || waktuAcara.isBefore(DateTime.now())) {
        return false; // Waktu sudah lewat
      }

      final tzTime = tz.TZDateTime.from(waktuAcara, tz.local);
      // ID unik: id acara + 20000 (beda dari H-1)
      final notifId = (int.tryParse(acara.idAcara) ?? acara.nama.hashCode) + 20000;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _chHariH,
          'Pengingat Hari-H Acara',
          channelDescription: 'Pengingat tepat pada hari dan jam acara berlangsung',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      );

      await _plugin.zonedSchedule(
        notifId,
        '🕌 Acara Sekarang: ${acara.nama}',
        'Acara "${acara.nama}" sedang berlangsung. Jangan sampai terlewat!',
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[NotificationController] Hari-H scheduled: ${acara.nama} at $waktuAcara');
      return true;
    } catch (e) {
      debugPrint('[NotificationController] scheduleHariHNotification error: $e');
      return false;
    }
  }

  /// Batalkan pengingat hari-H untuk acara tertentu
  static Future<void> cancelHariHNotification(String idAcara) async {
    final notifId = (int.tryParse(idAcara) ?? 0) + 20000;
    await _plugin.cancel(notifId);
  }

  /// Cek apakah pengingat hari-H sudah diset untuk acara ini
  static Future<bool> isHariHScheduled(String idAcara) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final notifId = (int.tryParse(idAcara) ?? 0) + 20000;
      return pending.any((n) => n.id == notifId);
    } catch (_) {
      return false;
    }
  }

  // ── 4. Batalkan notif H-1 ─────────────────────────────────────────────────
  static Future<void> cancelNotification(int idAcara) async {
    await _plugin.cancel(idAcara + 10000); // H-1
    await _plugin.cancel(idAcara + 20000); // Hari-H
  }

  // ── 5. Pencapaian langkah ─────────────────────────────────────────────────
  static Future<void> showStepAchievement(int targetSteps) async {
    if (!_initialized) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _chLangkah,
          'Langkah Ibadah',
          channelDescription: 'Notifikasi pencapaian langkah harian',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      );
      await _plugin.show(
        99901,
        '🎉 Target Langkah Tercapai!',
        'Selamat! Anda telah mencapai $targetSteps langkah hari ini.',
        details,
      );
    } catch (e) {
      debugPrint('[NotificationController] showStepAchievement error: $e');
    }
  }
}
