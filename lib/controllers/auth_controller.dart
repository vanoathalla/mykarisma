import 'package:local_auth/local_auth.dart';
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

      return {"success": true, "message": "Login berhasil"};
    } catch (e) {
      return {"success": false, "message": "Gagal mengakses database"};
    }
  }

  Future<bool> loginWithBiometric() async {
    final localAuth = LocalAuthentication();
    try {
      final canCheck = await localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Login ke MyKarisma menggunakan biometrik',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated) {
        // Ambil data admin dari DB dan buat session
        final members = await DatabaseHelper.instance.getAllMembers();
        if (members.isNotEmpty) {
          final admin = members.firstWhere(
            (m) => m['role'] == 'admin',
            orElse: () => members.first,
          );
          await AuthHelper.saveSession(
            idMember: admin['id_member'].toString(),
            nama: admin['nama'] ?? '',
            role: admin['role'] ?? '',
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    final localAuth = LocalAuthentication();
    return await localAuth.canCheckBiometrics;
  }

  Future<void> logout() async {
    await AuthHelper.clearSession();
  }
}
