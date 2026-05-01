class FeedbackModel {
  final int? idFeedback;
  final String? nama;
  final int rating;
  final String kategori;
  final String isi;
  final String tanggal;

  FeedbackModel({
    this.idFeedback,
    this.nama,
    required this.rating,
    required this.kategori,
    required this.isi,
    required this.tanggal,
  });

  String? validate() {
    if (rating < 1 || rating > 5) return 'Silakan pilih rating terlebih dahulu';
    if (isi.trim().length < 10) return 'Saran minimal 10 karakter';
    return null;
  }

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel(
    idFeedback: json['id_feedback'] as int?,
    nama: json['nama'] as String?,
    rating: json['rating'] as int,
    kategori: json['kategori'] ?? '',
    isi: json['isi'] ?? '',
    tanggal: json['tanggal'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    if (idFeedback != null) 'id_feedback': idFeedback,
    'nama': nama,
    'rating': rating,
    'kategori': kategori,
    'isi': isi,
    'tanggal': tanggal,
  };
}
