import 'package:flutter/foundation.dart';
import '../helpers/auth_helper.dart';
import '../helpers/database_helper.dart';
import '../models/member_model.dart';

class MemberController {
  Future<List<MemberModel>> fetchMember() async {
    try {
      final rows = await DatabaseHelper.instance.getAllMembers();
      return rows.map((row) => MemberModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[MemberController] fetchMember error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> tambahMember({
    required String nama,
    required String panggilan,
    required String noHp,
    required String role,
    required String rt,
    required String password,
  }) async {
    try {
      if (nama.isEmpty || panggilan.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'Nama, username, dan password wajib diisi'};
      }
      final existing = await DatabaseHelper.instance.getMemberByUsername(panggilan);
      if (existing != null) {
        return {'success': false, 'message': 'Username sudah digunakan'};
      }
      final passwordHash = AuthHelper.hashPassword(password);
      final member = MemberModel(
        id: '',
        nama: nama,
        panggilan: panggilan,
        noHp: noHp,
        role: role,
        rt: rt,
        passwordHash: passwordHash,
      );
      await DatabaseHelper.instance.insertMember(member);
      return {'success': true, 'message': 'Member berhasil ditambahkan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menambah member: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMember({
    required String id,
    required String nama,
    required String panggilan,
    required String noHp,
    required String role,
    required String rt,
    String? passwordBaru,
  }) async {
    try {
      if (nama.isEmpty || panggilan.isEmpty) {
        return {'success': false, 'message': 'Nama dan username wajib diisi'};
      }
      final data = <String, dynamic>{
        'nama': nama,
        'nama_panggilan': panggilan,
        'no_hp': noHp,
        'role': role,
        'rt': rt,
      };
      if (passwordBaru != null && passwordBaru.isNotEmpty) {
        data['password_hash'] = AuthHelper.hashPassword(passwordBaru);
      }
      await DatabaseHelper.instance.updateMember(id, data);
      return {'success': true, 'message': 'Member berhasil diperbarui'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui member: $e'};
    }
  }

  Future<Map<String, dynamic>> hapusMember(String id) async {
    try {
      await DatabaseHelper.instance.deleteMember(id);
      return {'success': true, 'message': 'Member berhasil dihapus'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus member: $e'};
    }
  }
}
