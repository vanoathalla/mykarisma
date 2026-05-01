class CatatanModel {
  final String id;
  final String judul;
  final String acara;
  final String isi;
  final String tanggal;

  CatatanModel({
    required this.id,
    required this.judul,
    required this.acara,
    required this.isi,
    required this.tanggal,
  });

  factory CatatanModel.fromJson(Map<String, dynamic> json) {
    return CatatanModel(
      id: json['id_catatan']?.toString() ?? '',
      judul: json['judul'] ?? 'Tanpa Judul',
      acara: json['acara'] ?? '-',
      isi: json['isi'] ?? '',
      tanggal: json['tanggal'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_catatan': int.tryParse(id) ?? 0,
      'judul': judul,
      'acara': acara,
      'isi': isi,
      'tanggal': tanggal,
    };
  }
}
