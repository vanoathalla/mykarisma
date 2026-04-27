import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/acara_model.dart';

class AcaraController {
  final String apiUrl = "http://localhost/api_karisma/api_acara.php";
  final String apiTambahUrl =
      "http://localhost/api_karisma/api_tambah_acara.php";

  // Fungsi untuk menampilkan data acara
  Future<List<AcaraModel>> fetchAcara() async {
    try {
      var response = await http.get(Uri.parse(apiUrl));
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        List jsonList = data['data'];
        return jsonList.map((e) => AcaraModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fungsi untuk mengirim data acara baru ke PHP
  Future<Map<String, dynamic>> tambahAcara(
    String nama,
    String tanggal,
    String kategori,
    String tipe,
  ) async {
    try {
      var response = await http.post(
        Uri.parse(apiTambahUrl),
        body: {
          "nama": nama,
          "tanggal": tanggal,
          "kategori": kategori,
          "tipe": tipe,
        },
      );

      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        return {"success": true, "message": data['message']};
      } else {
        return {"success": false, "message": data['message']};
      }
    } catch (e) {
      return {"success": false, "message": "Gagal terhubung ke server"};
    }
  }
}
