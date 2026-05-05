import 'package:flutter/foundation.dart' show debugPrint;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/auth_helper.dart';
import '../helpers/database_helper.dart';

class AuthController {
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final member = await DatabaseHelper.instance.getMemberByUsername(username);

      if (member == null) {
        return {"success": false, "message": "Username atau password salah"};
      }

      final hashedInput = AuthHelper.hashPassword(password);
      if (hashedInput != member.passwordHash) {
        return {"success": false, "message": "Username atau password salah"};
      }

      await AuthHelper.saveSession(
        idMember: member.id,
        nama: member.nama,
        role: member.role,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_login_id', member.id);

      return {"success": true, "message": "Login berhasil"};
    } catch (e) {
      return {"success": false, "message": "Gagal mengakses database"};
    }
  }

  Future<bool> loginWithBiometric() async {
    final localAuth = LocalAuthentication();
    try {
      final isSupported = await localAuth.isDeviceSupported();
      if (!isSupported) return false;

      final authenticated = await localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari atau PIN untuk masuk ke KARISMA',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!authenticated) return false;

      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString('last_login_id');

      final members = await DatabaseHelper.instance.getAllMembers();
      if (members.isEmpty) return false;

      Map<String, dynamic> target;
      if (lastId != null) {
        target = members.firstWhere(
          (m) => m['id_member'].toString() == lastId,
          orElse: () => members.first,
        );
      } else {
        target = members.firstWhere(
          (m) => m['role'] == 'admin',
          orElse: () => members.first,
        );
      }

      await AuthHelper.saveSession(
        idMember: target['id_member'].toString(),
        nama: target['nama'] ?? '',
        role: target['role'] ?? '',
      );
      return true;
    } catch (e) {
      debugPrint('[AuthController] biometric error: $e');
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    final localAuth = LocalAuthentication();
    try {
      return await localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await AuthHelper.clearSession();
  }
}
