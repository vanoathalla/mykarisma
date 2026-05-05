import 'dart:math';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/game_session_model.dart';

/// Konfigurasi level game Hijaiyah.
///
/// Level 1–3  : Huruf dasar 28, tebak nama, 4 pilihan
/// Level 4–6  : Huruf + harakat (fathah/kasrah/dhammah), tebak bacaan, 4 pilihan
/// Level 7–9  : Huruf mirip dikelompokkan, 6 pilihan
/// Level 10–12: Huruf + tanwin & mad, 6 pilihan — TAMAT di level 12
class GameController {
  static const int livesPerGame = 3;
  static const int questionsPerLevel = 8;
  static const int maxLevel = 12; // Level tamat

  // ── 28 huruf dasar ────────────────────────────────────────────────────────
  static const List<Map<String, String>> hijaiyahDasar = [
    {'huruf': 'ا', 'nama': 'Alif'},
    {'huruf': 'ب', 'nama': 'Ba'},
    {'huruf': 'ت', 'nama': 'Ta'},
    {'huruf': 'ث', 'nama': 'Tsa'},
    {'huruf': 'ج', 'nama': 'Jim'},
    {'huruf': 'ح', 'nama': 'Ha'},
    {'huruf': 'خ', 'nama': 'Kha'},
    {'huruf': 'د', 'nama': 'Dal'},
    {'huruf': 'ذ', 'nama': 'Dzal'},
    {'huruf': 'ر', 'nama': 'Ra'},
    {'huruf': 'ز', 'nama': 'Zai'},
    {'huruf': 'س', 'nama': 'Sin'},
    {'huruf': 'ش', 'nama': 'Syin'},
    {'huruf': 'ص', 'nama': 'Shad'},
    {'huruf': 'ض', 'nama': 'Dhad'},
    {'huruf': 'ط', 'nama': 'Tha'},
    {'huruf': 'ظ', 'nama': 'Zha'},
    {'huruf': 'ع', 'nama': 'Ain'},
    {'huruf': 'غ', 'nama': 'Ghain'},
    {'huruf': 'ف', 'nama': 'Fa'},
    {'huruf': 'ق', 'nama': 'Qaf'},
    {'huruf': 'ك', 'nama': 'Kaf'},
    {'huruf': 'ل', 'nama': 'Lam'},
    {'huruf': 'م', 'nama': 'Mim'},
    {'huruf': 'ن', 'nama': 'Nun'},
    {'huruf': 'و', 'nama': 'Waw'},
    {'huruf': 'ه', 'nama': 'Ha (akhir)'},
    {'huruf': 'ي', 'nama': 'Ya'},
  ];

  // ── Huruf + harakat (level 4–6) ───────────────────────────────────────────
  // Fathah (atas), Kasrah (bawah), Dhammah (depan)
  static const List<Map<String, String>> hijaiyahHarakat = [
    {'huruf': 'بَ', 'nama': 'Ba Fathah'},
    {'huruf': 'بِ', 'nama': 'Ba Kasrah'},
    {'huruf': 'بُ', 'nama': 'Ba Dhammah'},
    {'huruf': 'تَ', 'nama': 'Ta Fathah'},
    {'huruf': 'تِ', 'nama': 'Ta Kasrah'},
    {'huruf': 'تُ', 'nama': 'Ta Dhammah'},
    {'huruf': 'جَ', 'nama': 'Jim Fathah'},
    {'huruf': 'جِ', 'nama': 'Jim Kasrah'},
    {'huruf': 'جُ', 'nama': 'Jim Dhammah'},
    {'huruf': 'دَ', 'nama': 'Dal Fathah'},
    {'huruf': 'دِ', 'nama': 'Dal Kasrah'},
    {'huruf': 'دُ', 'nama': 'Dal Dhammah'},
    {'huruf': 'رَ', 'nama': 'Ra Fathah'},
    {'huruf': 'رِ', 'nama': 'Ra Kasrah'},
    {'huruf': 'رُ', 'nama': 'Ra Dhammah'},
    {'huruf': 'سَ', 'nama': 'Sin Fathah'},
    {'huruf': 'سِ', 'nama': 'Sin Kasrah'},
    {'huruf': 'سُ', 'nama': 'Sin Dhammah'},
    {'huruf': 'عَ', 'nama': 'Ain Fathah'},
    {'huruf': 'عِ', 'nama': 'Ain Kasrah'},
    {'huruf': 'عُ', 'nama': 'Ain Dhammah'},
    {'huruf': 'فَ', 'nama': 'Fa Fathah'},
    {'huruf': 'فِ', 'nama': 'Fa Kasrah'},
    {'huruf': 'فُ', 'nama': 'Fa Dhammah'},
    {'huruf': 'كَ', 'nama': 'Kaf Fathah'},
    {'huruf': 'كِ', 'nama': 'Kaf Kasrah'},
    {'huruf': 'كُ', 'nama': 'Kaf Dhammah'},
    {'huruf': 'لَ', 'nama': 'Lam Fathah'},
    {'huruf': 'لِ', 'nama': 'Lam Kasrah'},
    {'huruf': 'لُ', 'nama': 'Lam Dhammah'},
    {'huruf': 'مَ', 'nama': 'Mim Fathah'},
    {'huruf': 'مِ', 'nama': 'Mim Kasrah'},
    {'huruf': 'مُ', 'nama': 'Mim Dhammah'},
    {'huruf': 'نَ', 'nama': 'Nun Fathah'},
    {'huruf': 'نِ', 'nama': 'Nun Kasrah'},
    {'huruf': 'نُ', 'nama': 'Nun Dhammah'},
  ];

  // ── Huruf mirip dikelompokkan (level 7–9) ─────────────────────────────────
  // Kelompok huruf yang bentuknya mirip — lebih sulit dibedakan
  static const List<Map<String, String>> hijaiyahMirip = [
    // Kelompok titik bawah/atas
    {'huruf': 'ب', 'nama': 'Ba'},
    {'huruf': 'ت', 'nama': 'Ta'},
    {'huruf': 'ث', 'nama': 'Tsa'},
    {'huruf': 'ن', 'nama': 'Nun'},
    // Kelompok lengkung
    {'huruf': 'ج', 'nama': 'Jim'},
    {'huruf': 'ح', 'nama': 'Ha'},
    {'huruf': 'خ', 'nama': 'Kha'},
    // Kelompok garis
    {'huruf': 'د', 'nama': 'Dal'},
    {'huruf': 'ذ', 'nama': 'Dzal'},
    {'huruf': 'ر', 'nama': 'Ra'},
    {'huruf': 'ز', 'nama': 'Zai'},
    // Kelompok gigi
    {'huruf': 'س', 'nama': 'Sin'},
    {'huruf': 'ش', 'nama': 'Syin'},
    {'huruf': 'ص', 'nama': 'Shad'},
    {'huruf': 'ض', 'nama': 'Dhad'},
    // Kelompok tegak
    {'huruf': 'ط', 'nama': 'Tha'},
    {'huruf': 'ظ', 'nama': 'Zha'},
    {'huruf': 'ع', 'nama': 'Ain'},
    {'huruf': 'غ', 'nama': 'Ghain'},
    // Kelompok bulat
    {'huruf': 'ف', 'nama': 'Fa'},
    {'huruf': 'ق', 'nama': 'Qaf'},
    {'huruf': 'ك', 'nama': 'Kaf'},
  ];

  // ── Huruf + tanwin & mad (level 10+) ─────────────────────────────────────
  static const List<Map<String, String>> hijaiyahTanwinMad = [
    {'huruf': 'بً', 'nama': 'Ba Tanwin Fathah'},
    {'huruf': 'بٍ', 'nama': 'Ba Tanwin Kasrah'},
    {'huruf': 'بٌ', 'nama': 'Ba Tanwin Dhammah'},
    {'huruf': 'تً', 'nama': 'Ta Tanwin Fathah'},
    {'huruf': 'تٍ', 'nama': 'Ta Tanwin Kasrah'},
    {'huruf': 'تٌ', 'nama': 'Ta Tanwin Dhammah'},
    {'huruf': 'بْ', 'nama': 'Ba Sukun'},
    {'huruf': 'تْ', 'nama': 'Ta Sukun'},
    {'huruf': 'جْ', 'nama': 'Jim Sukun'},
    {'huruf': 'دْ', 'nama': 'Dal Sukun'},
    {'huruf': 'رْ', 'nama': 'Ra Sukun'},
    {'huruf': 'سْ', 'nama': 'Sin Sukun'},
    {'huruf': 'عْ', 'nama': 'Ain Sukun'},
    {'huruf': 'فْ', 'nama': 'Fa Sukun'},
    {'huruf': 'كْ', 'nama': 'Kaf Sukun'},
    {'huruf': 'لْ', 'nama': 'Lam Sukun'},
    {'huruf': 'مْ', 'nama': 'Mim Sukun'},
    {'huruf': 'نْ', 'nama': 'Nun Sukun'},
    {'huruf': 'بّ', 'nama': 'Ba Tasydid'},
    {'huruf': 'تّ', 'nama': 'Ta Tasydid'},
    {'huruf': 'سّ', 'nama': 'Sin Tasydid'},
    {'huruf': 'نّ', 'nama': 'Nun Tasydid'},
    {'huruf': 'مّ', 'nama': 'Mim Tasydid'},
    {'huruf': 'لّ', 'nama': 'Lam Tasydid'},
  ];

  final Random _random = Random();

  // Pool huruf yang belum dipakai di sesi ini (shuffle pool)
  List<Map<String, String>> _pool = [];
  int _currentLevel = 1;

  /// Ambil pool huruf sesuai level
  List<Map<String, String>> _getPoolForLevel(int level) {
    if (level >= 10) return [...hijaiyahTanwinMad];
    if (level >= 7) return [...hijaiyahMirip];
    if (level >= 4) return [...hijaiyahHarakat];
    return [...hijaiyahDasar];
  }

  /// Jumlah pilihan jawaban sesuai level (makin tinggi makin banyak)
  int getChoiceCount(int level) {
    if (level >= 7) return 6;
    return 4;
  }

  /// Ambil soal berikutnya — tidak mengulang huruf yang sudah dipakai
  Map<String, String> getNextLetter(int level) {
    // Jika level berubah atau pool habis, isi ulang pool
    if (level != _currentLevel || _pool.isEmpty) {
      _currentLevel = level;
      _pool = _getPoolForLevel(level)..shuffle(_random);
    }
    return _pool.removeLast();
  }

  /// Generate pilihan jawaban — makin tinggi level makin banyak pilihan
  List<String> generateChoices(String correctAnswer, int level) {
    final choiceCount = getChoiceCount(level);
    // Ambil semua nama dari pool level ini sebagai sumber pilihan salah
    final allNames = _getPoolForLevel(level).map((h) => h['nama']!).toList();
    final wrongAnswers = allNames.where((n) => n != correctAnswer).toList()
      ..shuffle(_random);
    final choices = [correctAnswer, ...wrongAnswers.take(choiceCount - 1)]
      ..shuffle(_random);
    return choices;
  }

  int calculateLevel(int score) {
    return (score ~/ questionsPerLevel) + 1;
  }

  /// Deskripsi level untuk ditampilkan di UI
  static String getLevelDescription(int level) {
    if (level >= 10) return 'Tanwin & Tasydid';
    if (level >= 7) return 'Huruf Mirip';
    if (level >= 4) return 'Harakat';
    return 'Huruf Dasar';
  }

  /// Warna level
  static Color getLevelColor(int level) {
    if (level >= 10) return const Color(0xFF6A1B9A); // ungu
    if (level >= 7) return const Color(0xFFE65100);  // oranye
    if (level >= 4) return const Color(0xFF1565C0);  // biru
    return const Color(0xFF2E7D32);                  // hijau
  }

  Future<void> saveGameSession(int score, int level) async {
    final session = GameSessionModel(
      skor: score,
      level: level,
      tanggal: DateTime.now().toIso8601String().split('T').first,
    );
    await DatabaseHelper.instance.insertGameSession(session.toMap());
  }

  Future<List<GameSessionModel>> getLeaderboard() async {
    final rows = await DatabaseHelper.instance.getAllGameSessions();
    return rows.map((r) => GameSessionModel.fromJson(r)).toList();
  }
}
