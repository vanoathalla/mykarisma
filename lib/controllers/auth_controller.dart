import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthController {
  // Gunakan localhost jika running di Chrome
  final String apiUrl = "http://localhost/api_karisma/api_login.php";

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        body: {"username": username, "password": password},
      );

      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        // Simpan ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'id_member',
          data['data']['id_member'].toString(),
        );
        await prefs.setString('nama', data['data']['nama']);
        await prefs.setString('role', data['data']['role']);

        return {"success": true, "message": data['message']};
      } else {
        return {"success": false, "message": data['message']};
      }
    } catch (e) {
      return {"success": false, "message": "Gagal terhubung ke server"};
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
