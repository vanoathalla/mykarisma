import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static const String _keyIdMember = 'session_id_member';
  static const String _keyNama = 'session_nama';
  static const String _keyRole = 'session_role';

  /// Menghasilkan SHA-256 hash dari password plaintext.
  static String hashPassword(String plaintext) {
    final bytes = utf8.encode(plaintext);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Menyimpan sesi ke SharedPreferences.
  static Future<void> saveSession({
    required String idMember,
    required String nama,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIdMember, idMember);
    await prefs.setString(_keyNama, nama);
    await prefs.setString(_keyRole, role);
  }

  /// Mengambil sesi aktif; null jika tidak ada atau tidak lengkap.
  static Future<Map<String, String>?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyIdMember);
    final nama = prefs.getString(_keyNama);
    final role = prefs.getString(_keyRole);
    if (id == null || nama == null || role == null) return null;
    return {'id_member': id, 'nama': nama, 'role': role};
  }

  /// Menghapus semua data sesi dari SharedPreferences.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIdMember);
    await prefs.remove(_keyNama);
    await prefs.remove(_keyRole);
  }

  /// Mengecek apakah sesi aktif valid (semua key tersedia).
  static Future<bool> isSessionValid() async {
    final session = await getActiveSession();
    return session != null;
  }
}
