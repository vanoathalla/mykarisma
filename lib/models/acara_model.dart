class AcaraModel {
  final String idAcara;
  final String nama;
  final String tanggal;
  final String kategori;
  final String tipe;

  AcaraModel({
    required this.idAcara,
    required this.nama,
    required this.tanggal,
    required this.kategori,
    required this.tipe,
  });

  // Fungsi untuk mengubah format JSON dari PHP menjadi Object di Flutter
  factory AcaraModel.fromJson(Map<String, dynamic> json) {
    return AcaraModel(
      idAcara: json['id_acara'].toString(),
      nama: json['nama'],
      tanggal: json['tanggal'],
      kategori: json['kategori'],
      tipe: json['tipe'],
    );
  }
}
