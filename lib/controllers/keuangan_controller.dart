import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/keuangan_model.dart';

class KeuanganController {
  final String apiUrl = "http://localhost/api_karisma/api_keuangan.php";

  Future<Map<String, dynamic>> fetchKeuangan() async {
    try {
      print("Mencoba panggil API Keuangan..."); // CCTV 1
      var response = await http.get(Uri.parse(apiUrl));
      print("Status Code API: ${response.statusCode}"); // CCTV 2
      print("Isi Data API: ${response.body}"); // CCTV 3

      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        List jsonList = data['data'];
        List<KeuanganModel> listKeuangan = jsonList
            .map((e) => KeuanganModel.fromJson(e))
            .toList();
        print("Berhasil mengubah data jadi Model!"); // CCTV 4

        return {
          "success": true,
          "saldo": data['saldo'],
          "pemasukan": data['total_pemasukan'],
          "pengeluaran": data['total_pengeluaran'],
          "data": listKeuangan,
        };
      } else {
        print("API membalas dengan status: ${data['status']}");
        return {"success": false};
      }
    } catch (e) {
      print(
        "ERROR FATAL: $e",
      ); // CCTV 5 (Kalau ada yang salah mapping, akan muncul di sini)
      return {"success": false};
    }
  }
}
