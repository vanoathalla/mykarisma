import 'package:flutter/foundation.dart';
import '../helpers/database_helper.dart';
import '../models/catatan_model.dart';

class CatatanController {
  Future<List<CatatanModel>> fetchCatatan() async {
    try {
      final rows = await DatabaseHelper.instance.getAllCatatan();
      return rows.map((row) => CatatanModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[CatatanController] Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> insertCatatan(
    String judul,
    String acara,
    String isi,
    String tanggal,
  ) async {
    if (judul.trim().isEmpty || tanggal.isEmpty) {
      return {'success': false, 'message': 'Judul dan tanggal wajib diisi'};
    }
    try {
      await DatabaseHelper.instance.insertCatatan({
        'judul': judul.trim(),
        'acara': acara.trim(),
        'isi': isi.trim(),
        'tanggal': tanggal,
      });
      return {'success': true, 'message': 'Catatan berhasil disimpan'};
    } catch (e) {
      debugPrint('[CatatanController] insertCatatan error: $e');
      return {'success': false, 'message': 'Gagal menyimpan catatan'};
    }
  }

  Future<Map<String, dynamic>> updateCatatan(
    String id,
    String judul,
    String acara,
    String isi,
    String tanggal,
  ) async {
    if (judul.trim().isEmpty || tanggal.isEmpty) {
      return {'success': false, 'message': 'Judul dan tanggal wajib diisi'};
    }
    try {
      await DatabaseHelper.instance.updateCatatan(id, {
        'judul': judul.trim(),
        'acara': acara.trim(),
        'isi': isi.trim(),
        'tanggal': tanggal,
      });
      return {'success': true, 'message': 'Catatan berhasil diperbarui'};
    } catch (e) {
      debugPrint('[CatatanController] updateCatatan error: $e');
      return {'success': false, 'message': 'Gagal memperbarui catatan'};
    }
  }

  Future<Map<String, dynamic>> deleteCatatan(String id) async {
    try {
      await DatabaseHelper.instance.deleteCatatan(id);
      return {'success': true, 'message': 'Catatan berhasil dihapus'};
    } catch (e) {
      debugPrint('[CatatanController] deleteCatatan error: $e');
      return {'success': false, 'message': 'Gagal menghapus catatan'};
    }
  }
}
