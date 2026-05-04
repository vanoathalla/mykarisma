import 'dart:convert';
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
  // ID baru (v3) agar Android membuat ulang channel dengan Importance.max
  // Channel lama 'karisma_hariH' dan 'karisma_hariH_v2' sudah terlanjur dibuat dengan importance rendah
  static const String _chHariH = 'karisma_hariH_v3';
  static const String _chLangkah = 'karisma_langkah';

  // ── Prefs keys ─────────────────────────────────────────────────────────────
  static const String _prefNotifUpdate = 'notif_update_aktif';
  static const String _prefNotifAcara = 'notif_acara_aktif';
  static const String _prefNotifHariH = 'notif_hariH_aktif';

  // ── Initialize ─────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Set timezone ke WIB agar jadwal notifikasi tepat waktu di Indonesia
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Update channel — karisma_update & karisma_acara pakai defaultImportance
    // karisma_hariH pakai Importance.max agar muncul sebagai heads-up (pop-up)
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

    // MAX importance = heads-up notification (pop-up di atas layar)
    // Ini adalah level tertinggi untuk memastikan notifikasi muncul sebagai pop-up
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _chHariH,
      'Pengingat Hari-H Acara',
      description: 'Pengingat tepat pada hari dan jam acara berlangsung',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
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
      // Save to local inbox so NotifikasiView can display it
      await _saveToInbox(judul: judul, isi: isi);
    } catch (e) {
      debugPrint('[NotificationController] showUpdateNotif error: $e');
    }
  }

  /// Saves a notification entry to SharedPreferences inbox.
  static Future<void> _saveToInbox({required String judul, required String isi}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('notif_inbox') ?? [];
      final entry = jsonEncode({
        'title': judul,
        'body': isi,
        'timestamp': DateTime.now().toIso8601String(),
      });
      raw.insert(0, entry); // newest first
      // Keep max 50
      if (raw.length > 50) raw.removeRange(50, raw.length);
      await prefs.setStringList('notif_inbox', raw);
    } catch (_) {}
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

  // ── 3. Batalkan notif H-1 ─────────────────────────────────────────────────
  static Future<void> cancelNotification(int idAcara) async {
    await _plugin.cancel(idAcara + 10000); // H-1
  }

  // ── 4. Pencapaian langkah ─────────────────────────────────────────────────
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
