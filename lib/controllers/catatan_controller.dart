import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/catatan_model.dart';

class CatatanController {
  final String apiUrl = "http://localhost/api_karisma/api_catatan.php";

  Future<List<CatatanModel>> fetchCatatan() async {
    try {
      var response = await http.get(Uri.parse(apiUrl));
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        List jsonList = data['data'];
        return jsonList.map((e) => CatatanModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching catatan: $e");
      return [];
    }
  }
}
