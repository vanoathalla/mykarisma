import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dokumentasi_model.dart';

class DokumentasiController {
  final String apiUrl = "http://localhost/api_karisma/api_dokumentasi.php";

  Future<List<DokumentasiModel>> fetchDokumentasi() async {
    try {
      var response = await http.get(Uri.parse(apiUrl));
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        List jsonList = data['data'];
        return jsonList.map((e) => DokumentasiModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching dokumentasi: $e");
      return [];
    }
  }
}
