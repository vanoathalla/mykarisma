class KeuanganModel {
  final String id;
  final String jenis;
  final String keterangan;
  final String tanggal;
  final int nominal;

  KeuanganModel({
    required this.id,
    required this.jenis,
    required this.keterangan,
    required this.tanggal,
    required this.nominal,
  });

  factory KeuanganModel.fromJson(Map<String, dynamic> json) {
    return KeuanganModel(
      id: json['id_keuangan']?.toString() ?? '',

      // PERUBAHAN: Menyesuaikan dengan nama kolom di JSON/Database
      jenis: json['tipe'] ?? '',
      keterangan: json['nama'] ?? '',
      tanggal: json['tanggal'] ?? '',
      nominal: int.tryParse(json['jumlah'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_keuangan': int.tryParse(id) ?? 0,
      'tipe': jenis,
      'nama': keterangan,
      'tanggal': tanggal,
      'jumlah': nominal,
    };
  }
}
