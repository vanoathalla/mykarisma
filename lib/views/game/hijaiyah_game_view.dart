import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../models/game_session_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

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
  String? _feedback;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (!_showLeaderboard)
            Container(
              color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppTheme.onSurface, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Tebak Huruf Hijaiyah',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        height: 1,
                        color: AppTheme.primary.withValues(alpha: 0.08)),
                  ],
                ),
              ),
            ),

          // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: _showLeaderboard
                ? _buildLeaderboard()
                : _isGameOver
                    ? _buildGameOverUI()
                    : _buildGameUI(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameUI() {
    Color bgColor;
    if (_feedback == 'correct') {
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else if (_feedback == 'wrong') {
      bgColor = Colors.red.withValues(alpha: 0.1);
    } else {
      bgColor = AppTheme.primary.withValues(alpha: 0.05);
    }

    return Column(
      children: [
        // Stats bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              // Score
              Expanded(
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.secondary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$_score',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Lives
              Expanded(
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      GameController.livesPerGame,
                      (i) => Icon(
                        i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Level
              Expanded(
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Lv.$_level',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Letter display
        Expanded(
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _feedback == 'correct'
                      ? Colors.green.withValues(alpha: 0.3)
                      : _feedback == 'wrong'
                          ? Colors.red.withValues(alpha: 0.3)
                          : AppTheme.outlineVariant.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _currentLetter['huruf'] ?? '',
                  style: const TextStyle(
                    fontSize: 110,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Answer choices
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: _choices.map((c) {
              final isCorrect = _feedback != null && c == _currentLetter['nama'];
              return ElevatedButton(
                onPressed: _feedback == null ? () => _jawab(c) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? Colors.green : AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isCorrect ? Colors.green : AppTheme.primary.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events_rounded,
                  size: 56, color: AppTheme.secondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Game Over!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Text(
                    'Skor Akhir',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CategoryBadge(
                    label: 'Level $_level',
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    textColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Main Lagi'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showLeaderboard = true),
                icon: const Icon(Icons.leaderboard_rounded, size: 18),
                label: const Text('Leaderboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return FutureBuilder<List<GameSessionModel>>(
      future: _gameCtrl.getLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final sessions = snapshot.data ?? [];

        return Column(
          children: [
            Container(
              color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppTheme.onSurface, size: 20),
                            onPressed: () =>
                                setState(() => _showLeaderboard = false),
                          ),
                          const Expanded(
                            child: Text(
                              'Leaderboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        height: 1,
                        color: AppTheme.primary.withValues(alpha: 0.08)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.leaderboard_outlined,
                              size: 56, color: AppTheme.outline),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada sesi game',
                            style: TextStyle(
                                color: AppTheme.outline, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      itemCount: sessions.length,
                      itemBuilder: (ctx, i) {
                        final s = sessions[i];
                        final medalColors = [
                          Colors.amber,
                          Colors.grey.shade400,
                          Colors.brown.shade300,
                        ];
                        final medalColor = i < 3
                            ? medalColors[i]
                            : AppTheme.primary.withValues(alpha: 0.15);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: medalColor,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: i < 3 ? Colors.white : AppTheme.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              'Skor: ${s.skor}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              'Level ${s.level} Â· ${s.tanggal}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
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
}
