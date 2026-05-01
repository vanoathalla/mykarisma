import 'package:flutter/foundation.dart';
import '../helpers/database_helper.dart';
import '../models/dokumentasi_model.dart';

class DokumentasiController {
  Future<List<DokumentasiModel>> fetchDokumentasi() async {
    try {
      final rows = await DatabaseHelper.instance.getAllDokumentasi();
      return rows.map((row) => DokumentasiModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[DokumentasiController] Error: $e');
      return [];
    }
  }
}
