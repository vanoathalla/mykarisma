import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/acara_model.dart';

class NotificationController {
  static const String _channelId = 'karisma_acara';
  static const String _channelName = 'Pengingat Acara KARISMA';
  static const String _channelDesc =
      'Notifikasi pengingat acara organisasi KARISMA';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Buat notification channel untuk Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  static Future<void> scheduleAcaraNotification(AcaraModel acara) async {
    try {
      final tanggal = DateTime.tryParse(acara.tanggal);
      if (tanggal == null) return;

      // Jadwalkan 1 hari sebelum acara jam 08:00
      final notifTime = DateTime(
        tanggal.year,
        tanggal.month,
        tanggal.day - 1,
        8,
        0,
      );

      if (notifTime.isBefore(DateTime.now())) return;

      final tzNotifTime = tz.TZDateTime.from(notifTime, tz.local);
      final notifId = int.tryParse(acara.idAcara) ?? acara.nama.hashCode;

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notifDetails = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        notifId,
        'Pengingat Acara KARISMA',
        'Acara besok: ${acara.nama} (${acara.tanggal})',
        tzNotifTime,
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('[NotificationController] Error schedule: $e');
    }
  }

  static Future<void> cancelNotification(int idAcara) async {
    try {
      await _plugin.cancel(idAcara);
    } catch (e) {
      debugPrint('[NotificationController] Error cancel: $e');
    }
  }
}
