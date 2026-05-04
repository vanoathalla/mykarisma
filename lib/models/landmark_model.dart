class LandmarkModel {
  final int? idLandmark;
  final String nama;
  final double latitude;
  final double longitude;
  final String? deskripsi;

  LandmarkModel({
    this.idLandmark,
    required this.nama,
    required this.latitude,
    required this.longitude,
    this.deskripsi,
  });

  factory LandmarkModel.fromJson(Map<String, dynamic> json) => LandmarkModel(
    idLandmark: json['id_landmark'] as int?,
    nama: json['nama'] ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    deskripsi: json['deskripsi'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (idLandmark != null) 'id_landmark': idLandmark,
    'nama': nama,
    'latitude': latitude,
    'longitude': longitude,
    'deskripsi': deskripsi,
  };
}
