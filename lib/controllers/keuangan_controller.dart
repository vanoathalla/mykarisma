import 'package:flutter/foundation.dart';
import '../helpers/database_helper.dart';
import '../models/keuangan_model.dart';
import 'notification_controller.dart';

class KeuanganController {
  Future<Map<String, dynamic>> fetchKeuangan() async {
    try {
      final rows = await DatabaseHelper.instance.getAllKeuangan();

      if (rows.isEmpty) {
        return {
          "success": true,
          "data": <KeuanganModel>[],
          "saldo": 0,
          "pemasukan": 0,
          "pengeluaran": 0,
        };
      }

      final List<KeuanganModel> listKeuangan =
          rows.map((row) => KeuanganModel.fromJson(row)).toList();

      int totalPemasukan = 0;
      int totalPengeluaran = 0;

      for (final item in listKeuangan) {
        if (item.jenis == 'pemasukan') {
          totalPemasukan += item.nominal;
        } else if (item.jenis == 'pengeluaran') {
          totalPengeluaran += item.nominal;
        }
      }

      final int saldo = totalPemasukan - totalPengeluaran;

      return {
        "success": true,
        "data": listKeuangan,
        "saldo": saldo,
        "pemasukan": totalPemasukan,
        "pengeluaran": totalPengeluaran,
      };
    } catch (e) {
      debugPrint('[KeuanganController] Error: $e');
      return {"success": false};
    }
  }

  Future<Map<String, dynamic>> insertKeuangan(
    String tipe,
    String nama,
    String tanggal,
    int jumlah,
  ) async {
    if (tipe.isEmpty || nama.trim().isEmpty || tanggal.isEmpty || jumlah <= 0) {
      return {'success': false, 'message': 'Semua field wajib diisi dengan benar'};
    }
    try {
      await DatabaseHelper.instance.insertKeuangan({
        'tipe': tipe,
        'nama': nama.trim(),
        'tanggal': tanggal,
        'jumlah': jumlah,
      });

      // Notif update ke semua member
      final tipeLbl = tipe == 'pemasukan' ? '💰 Pemasukan Baru' : '💸 Pengeluaran Baru';
      await NotificationController.showUpdateNotif(
        judul: tipeLbl,
        isi: '${nama.trim()} — Rp ${jumlah.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
        id: DateTime.now().millisecondsSinceEpoch % 100000,
      );

      return {'success': true, 'message': 'Transaksi berhasil disimpan'};
    } catch (e) {
      debugPrint('[KeuanganController] insertKeuangan error: $e');
      return {'success': false, 'message': 'Gagal menyimpan transaksi'};
    }
  }

  Future<Map<String, dynamic>> deleteKeuangan(String id) async {
    try {
      await DatabaseHelper.instance.deleteKeuangan(id);
      return {'success': true, 'message': 'Transaksi berhasil dihapus'};
    } catch (e) {
      debugPrint('[KeuanganController] deleteKeuangan error: $e');
      return {'success': false, 'message': 'Gagal menghapus transaksi'};
    }
  }

  Future<Map<String, dynamic>> updateKeuangan(
    String id,
    String tipe,
    String nama,
    String tanggal,
    int jumlah,
  ) async {
    if (tipe.isEmpty || nama.trim().isEmpty || tanggal.isEmpty || jumlah <= 0) {
      return {'success': false, 'message': 'Semua field wajib diisi dengan benar'};
    }
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'keuangan',
        {
          'tipe': tipe,
          'nama': nama.trim(),
          'tanggal': tanggal,
          'jumlah': jumlah,
        },
        where: 'id_keuangan = ?',
        whereArgs: [int.tryParse(id) ?? 0],
      );
      return {'success': true, 'message': 'Transaksi berhasil diperbarui'};
    } catch (e) {
      debugPrint('[KeuanganController] updateKeuangan error: $e');
      return {'success': false, 'message': 'Gagal memperbarui transaksi'};
    }
  }
}
