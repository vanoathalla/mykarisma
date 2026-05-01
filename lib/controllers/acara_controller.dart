import 'package:flutter/foundation.dart';
import '../helpers/database_helper.dart';
import '../models/acara_model.dart';
import 'notification_controller.dart';

class AcaraController {
  // Fungsi untuk menampilkan data acara dari SQLite
  Future<List<AcaraModel>> fetchAcara() async {
    try {
      final rows = await DatabaseHelper.instance.getAllAcara();
      return rows.map((row) => AcaraModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[AcaraController] Error fetchAcara: $e');
      return [];
    }
  }

  // Fungsi untuk menyimpan data acara baru ke SQLite
  Future<Map<String, dynamic>> tambahAcara(
    String nama,
    String tanggal,
    String kategori,
    String tipe,
  ) async {
    if (nama.isEmpty || tanggal.isEmpty || kategori.isEmpty || tipe.isEmpty) {
      return {"success": false, "message": "Data tidak boleh kosong"};
    }

    try {
      final newId = await DatabaseHelper.instance.insertAcara({
        'nama': nama,
        'tanggal': tanggal,
        'kategori': kategori,
        'tipe': tipe,
      });

      // Jadwalkan notifikasi jika tanggal di masa depan
      final tanggalDate = DateTime.tryParse(tanggal);
      if (tanggalDate != null && tanggalDate.isAfter(DateTime.now())) {
        final acara = AcaraModel(
          idAcara: newId.toString(),
          nama: nama,
          tanggal: tanggal,
          kategori: kategori,
          tipe: tipe,
        );
        await NotificationController.scheduleAcaraNotification(acara);
      }

      return {"success": true, "message": "Acara berhasil ditambahkan"};
    } catch (e) {
      return {"success": false, "message": "Gagal menyimpan data"};
    }
  }

  // Fungsi untuk menghapus acara dari SQLite dan membatalkan notifikasi
  Future<Map<String, dynamic>> hapusAcara(String idAcara) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'acara',
        where: 'id_acara = ?',
        whereArgs: [int.tryParse(idAcara) ?? 0],
      );
      await NotificationController.cancelNotification(
        int.tryParse(idAcara) ?? 0,
      );
      return {"success": true, "message": "Acara berhasil dihapus"};
    } catch (e) {
      return {"success": false, "message": "Gagal menghapus acara"};
    }
  }

  // Fungsi untuk memperbarui data acara di SQLite
  Future<Map<String, dynamic>> updateAcara(
    String id,
    String nama,
    String tanggal,
    String kategori,
    String tipe,
  ) async {
    if (nama.isEmpty || tanggal.isEmpty || kategori.isEmpty || tipe.isEmpty) {
      return {"success": false, "message": "Data tidak boleh kosong"};
    }
    try {
      await DatabaseHelper.instance.updateAcara(id, {
        'nama': nama,
        'tanggal': tanggal,
        'kategori': kategori,
        'tipe': tipe,
      });

      // Batalkan notifikasi lama dan jadwalkan ulang
      await NotificationController.cancelNotification(int.tryParse(id) ?? 0);
      final tanggalDate = DateTime.tryParse(tanggal);
      if (tanggalDate != null && tanggalDate.isAfter(DateTime.now())) {
        final acara = AcaraModel(
          idAcara: id,
          nama: nama,
          tanggal: tanggal,
          kategori: kategori,
          tipe: tipe,
        );
        await NotificationController.scheduleAcaraNotification(acara);
      }

      return {"success": true, "message": "Acara berhasil diperbarui"};
    } catch (e) {
      return {"success": false, "message": "Gagal memperbarui acara"};
    }
  }

  // Fungsi untuk mencari acara berdasarkan nama atau kategori
  Future<List<AcaraModel>> searchAcara(String query) async {
    try {
      final all = await fetchAcara();
      if (query.isEmpty) return all;
      final q = query.toLowerCase();
      return all
          .where(
            (a) =>
                a.nama.toLowerCase().contains(q) ||
                a.kategori.toLowerCase().contains(q),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}
