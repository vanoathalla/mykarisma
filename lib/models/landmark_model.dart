class LandmarkModel {
  final int? idLandmark;
  final String nama;
  final double latitude;
  final double longitude;
  final String? deskripsi;
  final int? idAcara;

  LandmarkModel({
    this.idLandmark,
    required this.nama,
    required this.latitude,
    required this.longitude,
    this.deskripsi,
    this.idAcara,
  });

  factory LandmarkModel.fromJson(Map<String, dynamic> json) => LandmarkModel(
    idLandmark: json['id_landmark'] as int?,
    nama: json['nama'] ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    deskripsi: json['deskripsi'] as String?,
    idAcara: json['id_acara'] as int?,
  );

  Map<String, dynamic> toMap() => {
    if (idLandmark != null) 'id_landmark': idLandmark,
    'nama': nama,
    'latitude': latitude,
    'longitude': longitude,
    'deskripsi': deskripsi,
    'id_acara': idAcara,
  };
}
