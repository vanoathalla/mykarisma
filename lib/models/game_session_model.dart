class GameSessionModel {
  final int? idSesi;
  final int skor;
  final int level;
  final String tanggal;

  GameSessionModel({
    this.idSesi,
    required this.skor,
    required this.level,
    required this.tanggal,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) =>
      GameSessionModel(
        idSesi: json['id_sesi'] as int?,
        skor: json['skor'] as int,
        level: json['level'] as int,
        tanggal: json['tanggal'] ?? '',
      );

  Map<String, dynamic> toMap() => {
    if (idSesi != null) 'id_sesi': idSesi,
    'skor': skor,
    'level': level,
    'tanggal': tanggal,
  };
}
