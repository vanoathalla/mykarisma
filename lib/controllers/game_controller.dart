import 'dart:math';
import '../helpers/database_helper.dart';
import '../models/game_session_model.dart';

class GameController {
  static const List<Map<String, String>> hijaiyahData = [
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

  static const int livesPerGame = 3;
  static const int questionsPerLevel = 10;

  final Random _random = Random();

  Map<String, String> getRandomLetter() {
    return hijaiyahData[_random.nextInt(hijaiyahData.length)];
  }

  List<String> generateChoices(String correctAnswer) {
    final allNames = hijaiyahData.map((h) => h['nama']!).toList();
    final wrongAnswers = allNames.where((n) => n != correctAnswer).toList()
      ..shuffle(_random);
    final choices = [correctAnswer, ...wrongAnswers.take(3)]..shuffle(_random);
    return choices;
  }

  int calculateLevel(int score) {
    return (score ~/ questionsPerLevel) + 1;
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
