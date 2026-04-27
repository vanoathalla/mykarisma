class DokumentasiModel {
  final String id;
  final String nama;
  final String url;
  final String tanggal;

  DokumentasiModel({
    required this.id,
    required this.nama,
    required this.url,
    required this.tanggal,
  });

  factory DokumentasiModel.fromJson(Map<String, dynamic> json) {
    return DokumentasiModel(
      id: json['id_dokumentasi']?.toString() ?? '',
      nama: json['nama'] ?? 'Tanpa Nama',
      url: json['url'] ?? '-',
      tanggal: json['tanggal'] ?? '',
    );
  }
}
