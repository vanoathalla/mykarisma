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

  Future<Map<String, dynamic>> insertDokumentasi(
    String nama,
    String url,
    String tanggal,
  ) async {
    if (nama.trim().isEmpty || url.trim().isEmpty || tanggal.isEmpty) {
      return {'success': false, 'message': 'Semua field wajib diisi'};
    }
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('dokumentasi', {
        'nama': nama.trim(),
        'url': url.trim(),
        'tanggal': tanggal,
      });
      return {'success': true, 'message': 'Dokumentasi berhasil ditambahkan'};
    } catch (e) {
      debugPrint('[DokumentasiController] insertDokumentasi error: $e');
      return {'success': false, 'message': 'Gagal menyimpan dokumentasi'};
    }
  }

  Future<Map<String, dynamic>> updateDokumentasi(
    String id,
    String nama,
    String url,
    String tanggal,
  ) async {
    if (nama.trim().isEmpty || url.trim().isEmpty || tanggal.isEmpty) {
      return {'success': false, 'message': 'Semua field wajib diisi'};
    }
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'dokumentasi',
        {'nama': nama.trim(), 'url': url.trim(), 'tanggal': tanggal},
        where: 'id_dokumentasi = ?',
        whereArgs: [int.tryParse(id) ?? 0],
      );
      return {'success': true, 'message': 'Dokumentasi berhasil diperbarui'};
    } catch (e) {
      debugPrint('[DokumentasiController] updateDokumentasi error: $e');
      return {'success': false, 'message': 'Gagal memperbarui dokumentasi'};
    }
  }

  Future<Map<String, dynamic>> deleteDokumentasi(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'dokumentasi',
        where: 'id_dokumentasi = ?',
        whereArgs: [int.tryParse(id) ?? 0],
      );
      return {'success': true, 'message': 'Dokumentasi berhasil dihapus'};
    } catch (e) {
      debugPrint('[DokumentasiController] deleteDokumentasi error: $e');
      return {'success': false, 'message': 'Gagal menghapus dokumentasi'};
    }
  }
}
