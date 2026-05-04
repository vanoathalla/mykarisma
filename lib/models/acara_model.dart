class AcaraModel {
  final String idAcara;
  final String nama;
  final String tanggal;
  final String kategori;
  final String tipe; // kept for DB backward-compat (not shown in UI)
  final String? lokasi;

  AcaraModel({
    required this.idAcara,
    required this.nama,
    required this.tanggal,
    required this.kategori,
    required this.tipe,
    this.lokasi,
  });

  // Fungsi untuk mengubah format JSON dari DB menjadi Object di Flutter
  factory AcaraModel.fromJson(Map<String, dynamic> json) {
    return AcaraModel(
      idAcara: json['id_acara']?.toString() ?? '0',
      nama: json['nama'] ?? '',
      tanggal: json['tanggal'] ?? '',
      kategori: json['kategori'] ?? '',
      tipe: json['tipe'] ?? '',
      lokasi: json['lokasi'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_acara': int.tryParse(idAcara) ?? 0,
      'nama': nama,
      'tanggal': tanggal,
      'kategori': kategori,
      'tipe': tipe,
      'lokasi': lokasi,
    };
  }
}
