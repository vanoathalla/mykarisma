class MemberModel {
  final String id;
  final String nama;
  final String panggilan;
  final String noHp;
  final String role;
  final String rt;

  MemberModel({
    required this.id,
    required this.nama,
    required this.panggilan,
    required this.noHp,
    required this.role,
    required this.rt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id_member']?.toString() ?? '',
      nama: json['nama'] ?? 'Tanpa Nama',
      panggilan: json['nama_panggilan'] ?? '',
      noHp: json['no_hp'] ?? '-',
      role: json['role'] ?? 'member',
      rt: json['rt'] ?? '-',
    );
  }
}
