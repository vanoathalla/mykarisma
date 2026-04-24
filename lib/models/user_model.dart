class UserModel {
  final String idMember;
  final String nama;
  final String namaPanggilan;
  final String role;

  UserModel({
    required this.idMember,
    required this.nama,
    required this.namaPanggilan,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idMember: json['id_member'].toString(),
      nama: json['nama'] ?? '',
      namaPanggilan: json['nama_panggilan'] ?? '',
      role: json['role'] ?? '',
    );
  }
}
