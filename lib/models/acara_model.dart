class AcaraModel {
  final String idAcara;
  final String nama;
  final String tanggal;
  final String kategori;
  final String tipe;
  final String? lokasi;

  AcaraModel({
    required this.idAcara,
    required this.nama,
    required this.tanggal,
    required this.kategori,
    required this.tipe,
    this.lokasi,
  });

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
