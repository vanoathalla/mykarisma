import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/acara_model.dart';

class AcaraController {
  // PENTING: Ganti URL sesuai device kamu (localhost untuk web/Chrome)
  final String _baseUrl = "http://localhost/api_karisma/api_acara.php";

  Future<List<AcaraModel>> fetchAcara() async {
    try {
      var response = await http.get(Uri.parse(_baseUrl));
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        List<dynamic> jsonList = data['data'];
        // Mengubah list JSON menjadi list Model Acara
        return jsonList.map((json) => AcaraModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error mengambil data: $e");
      return [];
    }
  }
}
