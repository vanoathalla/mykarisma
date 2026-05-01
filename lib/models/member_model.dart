class MemberModel {
  final String id;
  final String nama;
  final String panggilan;
  final String noHp;
  final String role;
  final String rt;
  final String? passwordHash;
  final String? fotoPath;

  MemberModel({
    required this.id,
    required this.nama,
    required this.panggilan,
    required this.noHp,
    required this.role,
    required this.rt,
    this.passwordHash,
    this.fotoPath,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id_member']?.toString() ?? '',
      nama: json['nama'] ?? 'Tanpa Nama',
      panggilan: json['nama_panggilan'] ?? '',
      noHp: json['no_hp'] ?? '-',
      role: json['role'] ?? 'member',
      rt: json['rt'] ?? '-',
      passwordHash: json['password_hash'] as String?,
      fotoPath: json['foto_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_member': int.tryParse(id) ?? 0,
      'nama': nama,
      'nama_panggilan': panggilan,
      'no_hp': noHp,
      'role': role,
      'rt': rt,
      'password_hash': passwordHash,
      'foto_path': fotoPath,
    };
  }
}
