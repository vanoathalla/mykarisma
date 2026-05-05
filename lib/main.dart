import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'helpers/database_helper.dart';
import 'helpers/auth_helper.dart';
import 'theme/app_theme.dart';
import 'views/home/home_view.dart';
import 'views/splash_screen.dart';
import 'controllers/notification_controller.dart';
import 'services/overlay_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[main] dotenv load error (ignored): $e');
  }

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  if (!kIsWeb) {
    try {
      await NotificationController.initialize();
    } catch (e) {
      debugPrint('[main] NotificationController init error (ignored): $e');
    }
  }

  await DatabaseHelper.instance.seedData();

  final sessionValid = await AuthHelper.isSessionValid();

  runApp(MyKarismaApp(sessionValid: sessionValid));
}

class MyKarismaApp extends StatelessWidget {
  final bool sessionValid;

  const MyKarismaApp({super.key, required this.sessionValid});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'MyKarisma',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: mode,
          navigatorKey: OverlayNotificationService().navigatorKey,
          home: kIsWeb ? const HomeView() : const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}