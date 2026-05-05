import 'package:flutter/foundation.dart';
import '../helpers/database_helper.dart';
import '../models/acara_model.dart';
import 'notification_controller.dart';

class AcaraController {
  Future<List<AcaraModel>> fetchAcara() async {
    try {
      final rows = await DatabaseHelper.instance.getAllAcara();
      return rows.map((row) => AcaraModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[AcaraController] Error fetchAcara: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> tambahAcara(
    String nama,
    String tanggal,
    String kategori,
    String lokasi,
  ) async {
    if (nama.isEmpty || tanggal.isEmpty || kategori.isEmpty) {
      return {"success": false, "message": "Data tidak boleh kosong"};
    }

    try {
      final newId = await DatabaseHelper.instance.insertAcara({
        'nama': nama,
        'tanggal': tanggal,
        'kategori': kategori,
        'tipe': '',
        'lokasi': lokasi,
      });

      final tanggalDate = DateTime.tryParse(tanggal.split(' ').first);
      if (tanggalDate != null && tanggalDate.isAfter(DateTime.now())) {
        final acara = AcaraModel(
          idAcara: newId.toString(),
          nama: nama,
          tanggal: tanggal,
          kategori: kategori,
          tipe: '',
          lokasi: lokasi,
        );
        await NotificationController.scheduleAcaraNotification(acara);
      }

      await NotificationController.showUpdateNotif(
        judul: '📅 Acara Baru Ditambahkan',
        isi: '$nama — $tanggal',
        id: newId % 100000,
      );

      return {"success": true, "message": "Acara berhasil ditambahkan"};
    } catch (e) {
      return {"success": false, "message": "Gagal menyimpan data"};
    }
  }
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

  Future<Map<String, dynamic>> updateAcara(
    String id,
    String nama,
    String tanggal,
    String kategori,
    String lokasi,
  ) async {
    if (nama.isEmpty || tanggal.isEmpty || kategori.isEmpty) {
      return {"success": false, "message": "Data tidak boleh kosong"};
    }
    try {
      await DatabaseHelper.instance.updateAcara(id, {
        'nama': nama,
        'tanggal': tanggal,
        'kategori': kategori,
        'tipe': '',
        'lokasi': lokasi,
      });

      await NotificationController.cancelNotification(int.tryParse(id) ?? 0);
      final tanggalDate = DateTime.tryParse(tanggal.split(' ').first);
      if (tanggalDate != null && tanggalDate.isAfter(DateTime.now())) {
        final acara = AcaraModel(
          idAcara: id,
          nama: nama,
          tanggal: tanggal,
          kategori: kategori,
          tipe: '',
          lokasi: lokasi,
        );
        await NotificationController.scheduleAcaraNotification(acara);
      }

      await NotificationController.showUpdateNotif(
        judul: '📅 Acara Diperbarui',
        isi: '$nama — $tanggal',
        id: (int.tryParse(id) ?? 0) + 30000,
      );

      return {"success": true, "message": "Acara berhasil diperbarui"};
    } catch (e) {
      return {"success": false, "message": "Gagal memperbarui acara"};
    }
  }

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
