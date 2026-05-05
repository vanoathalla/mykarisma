import 'dart:math';
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

class _HijaiyahGameViewState extends State<HijaiyahGameView>
    with TickerProviderStateMixin {
  final GameController _gameCtrl = GameController();
  late Map<String, String> _currentLetter;
  late List<String> _choices;
  int _score = 0;
  int _lives = GameController.livesPerGame;
  int _level = 1;
  bool _isGameOver = false;
  bool _isGameWin = false;
  String? _feedback;
  bool _showLeaderboard = false;
  // Soal ke berapa di level ini
  int _soalDiLevel = 0;

  // Animasi getar HP saat salah
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Animasi bintang berputar saat menang
  late AnimationController _winCtrl;

  @override
  void initState() {
    super.initState();
    _currentLetter = {'huruf': '', 'nama': ''};
    _choices = [];

    // Shake animation
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    // Win star rotation animation
    _winCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _nextQuestion();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _winCtrl.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    setState(() {
      _currentLetter = _gameCtrl.getNextLetter(_level);
      _choices = _gameCtrl.generateChoices(_currentLetter['nama']!, _level);
      _feedback = null;
    });
  }

  Future<void> _jawab(String pilihan) async {
    if (_feedback != null) return;

    final benar = pilihan == _currentLetter['nama'];

    if (benar) {
      _soalDiLevel++;
      final newLevel = _gameCtrl.calculateLevel(_score + 1);
      setState(() {
        _score++;
        _feedback = 'correct';
        // Jika naik level, reset soalDiLevel
        if (newLevel > _level) {
          _soalDiLevel = 0;
          _level = newLevel;
        }
      });

      // Cek apakah sudah tamat (level 12 dan soal di level selesai)
      if (_level >= GameController.maxLevel &&
          _soalDiLevel >= GameController.questionsPerLevel) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _gameWin();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _nextQuestion();
    } else {
      setState(() {
        _lives--;
        _feedback = 'wrong';
      });
      _shakeCtrl.forward(from: 0);
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

  void _gameWin() {
    setState(() => _isGameWin = true);
    _gameCtrl.saveGameSession(_score, _level);
  }

  void _restart() {
    setState(() {
      _score = 0;
      _lives = GameController.livesPerGame;
      _level = 1;
      _soalDiLevel = 0;
      _isGameOver = false;
      _isGameWin = false;
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
                    Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _showLeaderboard
                ? _buildLeaderboard()
                : _isGameWin
                    ? _buildGameWinUI()
                    : _isGameOver
                        ? _buildGameOverUI()
                        : _buildGameUI(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameUI() {
    final levelColor = GameController.getLevelColor(_level);
    final levelDesc = GameController.getLevelDescription(_level);
    final choiceCount = _gameCtrl.getChoiceCount(_level);

    Color bgColor;
    if (_feedback == 'correct') {
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else if (_feedback == 'wrong') {
      bgColor = Colors.red.withValues(alpha: 0.1);
    } else {
      bgColor = levelColor.withValues(alpha: 0.05);
    }

    // Progress soal di level ini
    final progress = (_soalDiLevel % GameController.questionsPerLevel) /
        GameController.questionsPerLevel;

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
                      const Icon(Icons.star_rounded, color: AppTheme.secondary, size: 18),
                      const SizedBox(width: 6),
                      Text('$_score',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface)),
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
                        color: Colors.red, size: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Level dengan warna sesuai tier
              Expanded(
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trending_up_rounded, color: levelColor, size: 16),
                          const SizedBox(width: 4),
                          Text('Lv.$_level',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                              color: levelColor)),
                        ],
                      ),
                      Text(levelDesc,
                        style: TextStyle(fontSize: 9, color: levelColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress bar level
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress Level $_level',
                    style: TextStyle(fontSize: 11, color: levelColor, fontWeight: FontWeight.w600)),
                  Text('${_soalDiLevel % GameController.questionsPerLevel}/${GameController.questionsPerLevel}',
                    style: TextStyle(fontSize: 11, color: levelColor.withValues(alpha: 0.7))),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: levelColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Letter display
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final offset = sin(_shakeAnim.value * pi * 6) * 12;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _feedback == 'correct'
                        ? Colors.green.withValues(alpha: 0.4)
                        : _feedback == 'wrong'
                            ? Colors.red.withValues(alpha: 0.4)
                            : levelColor.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _currentLetter['huruf'] ?? '',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: _feedback == 'correct'
                          ? Colors.green
                          : _feedback == 'wrong'
                              ? Colors.red
                              : levelColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Hint level
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getLevelIcon(_level), color: levelColor, size: 14),
                const SizedBox(width: 6),
                Text(_getLevelHint(_level),
                  style: TextStyle(fontSize: 12, color: levelColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),

        // Answer choices — grid 2 kolom (4 pilihan) atau 3 kolom (6 pilihan)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: GridView.count(
            crossAxisCount: choiceCount == 6 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: choiceCount == 6 ? 2.2 : 2.8,
            children: _choices.map((c) {
              final isCorrect = _feedback != null && c == _currentLetter['nama'];
              final isWrong = _feedback == 'wrong' && c != _currentLetter['nama'];
              return ElevatedButton(
                onPressed: _feedback == null ? () => _jawab(c) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect
                      ? Colors.green
                      : isWrong
                          ? Colors.red.withValues(alpha: 0.7)
                          : levelColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isCorrect
                      ? Colors.green
                      : levelColor.withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(c,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getLevelIcon(int level) {
    if (level >= 10) return Icons.workspace_premium_rounded;
    if (level >= 7) return Icons.psychology_rounded;
    if (level >= 4) return Icons.auto_fix_high_rounded;
    return Icons.school_rounded;
  }

  String _getLevelHint(int level) {
    if (level >= 10) return 'Tebak huruf dengan tanwin & tasydid';
    if (level >= 7) return 'Hati-hati! Huruf mirip, ${_gameCtrl.getChoiceCount(level)} pilihan';
    if (level >= 4) return 'Tebak huruf beserta harakatnya';
    return 'Tebak nama huruf hijaiyah';
  }

  Widget _buildGameOverUI() {
    final levelColor = GameController.getLevelColor(_level);
    final levelDesc = GameController.getLevelDescription(_level);

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.heart_broken_rounded,
                    size: 56, color: Colors.red),
              ),
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: const Text('Game Over!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                    color: Colors.red)),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    Text('$_score',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800,
                        color: levelColor)),
                    const Text('Skor Akhir',
                      style: TextStyle(fontSize: 13, color: AppTheme.outline)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CategoryBadge(
                          label: 'Level $_level',
                          color: levelColor.withValues(alpha: 0.1),
                          textColor: levelColor,
                        ),
                        const SizedBox(width: 8),
                        CategoryBadge(
                          label: levelDesc,
                          color: levelColor.withValues(alpha: 0.08),
                          textColor: levelColor.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Main Lagi'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showLeaderboard = true),
                  icon: const Icon(Icons.leaderboard_rounded, size: 18),
                  label: const Text('Leaderboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameWinUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3), Color(0xFFFFF9C4)],
        ),
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bintang berputar
                AnimatedBuilder(
                  animation: _winCtrl,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _winCtrl.value * 2 * pi,
                      child: child,
                    );
                  },
                  child: const Icon(Icons.star_rounded,
                      size: 72, color: Color(0xFFFFC107)),
                ),
                const SizedBox(height: 12),
                // Trofi
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.5),
                        width: 2),
                  ),
                  child: const Center(
                    child: Text('🏆',
                        style: TextStyle(fontSize: 56)),
                  ),
                ),
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, opacity, child) =>
                      Opacity(opacity: opacity, child: child),
                  child: const Text('TAMAT!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE65100),
                      letterSpacing: 4,
                    )),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selamat! Kamu telah menyelesaikan semua level!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF795548),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('$_score',
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE65100),
                        )),
                      const Text('Skor Akhir',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF795548),
                        )),
                      const SizedBox(height: 8),
                      CategoryBadge(
                        label: 'Level ${GameController.maxLevel} — Tamat!',
                        color: const Color(0xFFFFC107).withValues(alpha: 0.2),
                        textColor: const Color(0xFFE65100),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _restart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Main Lagi',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showLeaderboard = true),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFC107)),
                      foregroundColor: const Color(0xFFE65100),
                    ),
                    icon: const Icon(Icons.leaderboard_rounded, size: 18),
                    label: const Text('Leaderboard',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return FutureBuilder<List<GameSessionModel>>(
      future: _gameCtrl.getLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
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
                            onPressed: () => setState(() => _showLeaderboard = false),
                          ),
                          const Expanded(
                            child: Text('Leaderboard',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface)),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
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
                          Icon(Icons.leaderboard_outlined, size: 56, color: AppTheme.outline),
                          SizedBox(height: 12),
                          Text('Belum ada sesi game',
                            style: TextStyle(color: AppTheme.outline, fontSize: 14)),
                        ],
                      ))
                  : ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      itemCount: sessions.length,
                      itemBuilder: (ctx, i) {
                        final s = sessions[i];
                        final levelColor = GameController.getLevelColor(s.level);
                        final medalColors = [Colors.amber, Colors.grey.shade400, Colors.brown.shade300];
                        final medalColor = i < 3 ? medalColors[i] : AppTheme.primary.withValues(alpha: 0.15);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: medalColor,
                              child: Text('${i + 1}',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                                  color: i < 3 ? Colors.white : AppTheme.primary)),
                            ),
                            title: Text('Skor: ${s.skor}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                                color: AppTheme.onSurface)),
                            subtitle: Text(s.tanggal,
                              style: const TextStyle(fontSize: 12, color: AppTheme.outline)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: levelColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Lv.${s.level}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                                      color: levelColor)),
                                  Text(GameController.getLevelDescription(s.level),
                                    style: TextStyle(fontSize: 9, color: levelColor.withValues(alpha: 0.7))),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
            ),
          ],
        );
      },
    );
  }
}
