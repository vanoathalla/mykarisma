import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/member_model.dart';

class MemberController {
  final String apiUrl = "http://localhost/api_karisma/api_member.php";

  Future<List<MemberModel>> fetchMember() async {
    try {
      var response = await http.get(Uri.parse(apiUrl));
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        List jsonList = data['data'];
        return jsonList.map((e) => MemberModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching member: $e");
      return [];
    }
  }
}
