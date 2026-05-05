import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static const String _keyIdMember = 'session_id_member';
  static const String _keyNama = 'session_nama';
  static const String _keyRole = 'session_role';

  static String hashPassword(String plaintext) {
    final bytes = utf8.encode(plaintext);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

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

  static Future<Map<String, String>?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyIdMember);
    final nama = prefs.getString(_keyNama);
    final role = prefs.getString(_keyRole);
    if (id == null || nama == null || role == null) return null;
    return {'id_member': id, 'nama': nama, 'role': role};
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIdMember);
    await prefs.remove(_keyNama);
    await prefs.remove(_keyRole);
  }

  static Future<bool> isSessionValid() async {
    final session = await getActiveSession();
    return session != null;
  }
}
