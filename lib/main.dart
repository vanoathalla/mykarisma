import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'helpers/database_helper.dart';
import 'helpers/auth_helper.dart';
import 'theme/app_theme.dart';
import 'views/home/home_view.dart';
import 'controllers/notification_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables dari .env
  await dotenv.load(fileName: '.env');

  // Inisialisasi database factory sesuai platform
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Inisialisasi notifikasi lokal (hanya di non-web)
  if (!kIsWeb) {
    await NotificationController.initialize();
  }

  // Seed data admin awal
  await DatabaseHelper.instance.seedData();

  // Cek session aktif
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
          // HomeView sudah menangani mode tamu vs login secara internal
          home: const HomeView(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
