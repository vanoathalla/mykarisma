import 'package:flutter/foundation.dart';
import '../helpers/database_helper.dart';
import '../models/member_model.dart';

class MemberController {
  Future<List<MemberModel>> fetchMember() async {
    try {
      final rows = await DatabaseHelper.instance.getAllMembers();
      return rows.map((row) => MemberModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[MemberController] Error: $e');
      return [];
    }
  }
}
