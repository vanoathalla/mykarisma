import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../models/game_session_model.dart';
import '../../theme/app_theme.dart';

class HijaiyahGameView extends StatefulWidget {
  const HijaiyahGameView({super.key});

  @override
  State<HijaiyahGameView> createState() => _HijaiyahGameViewState();
}

class _HijaiyahGameViewState extends State<HijaiyahGameView> {
  final GameController _gameCtrl = GameController();
  late Map<String, String> _currentLetter;
  late List<String> _choices;
  int _score = 0;
  int _lives = GameController.livesPerGame;
  int _level = 1;
  bool _isGameOver = false;
  String? _feedback; // null / 'correct' / 'wrong'
  bool _showLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _currentLetter = {'huruf': '', 'nama': ''};
    _choices = [];
    _nextQuestion();
  }

  void _nextQuestion() {
    setState(() {
      _currentLetter = _gameCtrl.getRandomLetter();
      _choices = _gameCtrl.generateChoices(_currentLetter['nama']!);
      _feedback = null;
    });
  }

  Future<void> _jawab(String pilihan) async {
    if (_feedback != null) return;

    final benar = pilihan == _currentLetter['nama'];

    if (benar) {
      setState(() {
        _score++;
        _feedback = 'correct';
        _level = _gameCtrl.calculateLevel(_score);
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _nextQuestion();
    } else {
      setState(() {
        _lives--;
        _feedback = 'wrong';
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      if (_lives == 0) {
        _gameOver();
      } else {
        _nextQuestion();
      }
    }
  }

  void _gameOver() {
    setState(() => _isGameOver = true);
    _gameCtrl.saveGameSession(_score, _level);
  }

  void _restart() {
    setState(() {
      _score = 0;
      _lives = GameController.livesPerGame;
      _level = 1;
      _isGameOver = false;
      _showLeaderboard = false;
      _feedback = null;
    });
    _nextQuestion();
  }

  Widget _buildGameUI() {
    Color bgColor;
    if (_feedback == 'correct') {
      bgColor = Colors.green.shade100;
    } else if (_feedback == 'wrong') {
      bgColor = Colors.red.shade100;
    } else {
      bgColor = Colors.teal.shade50;
    }

    return Column(
      children: [
        // Header: skor, nyawa, level
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skor: $_score',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(
                  GameController.livesPerGame,
                  (i) => Icon(
                    i < _lives ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
              Text(
                'Level $_level',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Huruf hijaiyah besar
        Expanded(
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _currentLetter['huruf'] ?? '',
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 4 pilihan jawaban dalam GridView 2x2
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: _choices.map((c) {
              Color btnColor = AppTheme.primary;
              if (_feedback != null && c == _currentLetter['nama']) {
                btnColor = Colors.green;
              }
              return ElevatedButton(
                onPressed: _feedback == null ? () => _jawab(c) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: btnColor.withValues(alpha: 0.7),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGameOverUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 80, color: AppTheme.secondary),
          const SizedBox(height: 16),
          const Text(
            'Game Over!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Skor Akhir: $_score',
            style: const TextStyle(fontSize: 22),
          ),
          Text(
            'Level: $_level',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.replay),
            label: const Text('Main Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showLeaderboard = true),
            icon: const Icon(Icons.leaderboard),
            label: const Text('Leaderboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return FutureBuilder<List<GameSessionModel>>(
      future: _gameCtrl.getLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _showLeaderboard = false),
                  ),
                  const Text(
                    'Leaderboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada sesi game.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sessions.length,
                      itemBuilder: (ctx, i) {
                        final s = sessions[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: i == 0
                                  ? Colors.amber
                                  : i == 1
                                      ? Colors.grey.shade400
                                      : i == 2
                                          ? Colors.brown.shade300
                                          : AppTheme.primary
                                              .withValues(alpha: 0.2),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: i < 3 ? Colors.white : AppTheme.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              'Skor: ${s.skor}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Level ${s.level} · ${s.tanggal}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showLeaderboard
          ? null
          : AppBar(
              title: const Text('Tebak Huruf Hijaiyah'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
      body: _showLeaderboard
          ? _buildLeaderboard()
          : _isGameOver
              ? _buildGameOverUI()
              : _buildGameUI(),
    );
  }
}
