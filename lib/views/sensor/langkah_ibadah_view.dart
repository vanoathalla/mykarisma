import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controllers/pedometer_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../theme/app_theme.dart';

class LangkahIbadahView extends StatefulWidget {
  const LangkahIbadahView({super.key});

  @override
  State<LangkahIbadahView> createState() => _LangkahIbadahViewState();
}

class _LangkahIbadahViewState extends State<LangkahIbadahView>
    with TickerProviderStateMixin {
  final PedometerController _ctrl = PedometerController();

  int _steps = 0;
  WalkingStatus _status = WalkingStatus.unknown;
  bool _targetReached = false;
  bool _notifSent = false;

  StreamSubscription<int>? _stepSub;
  StreamSubscription<WalkingStatus>? _statusSub;

  // Animasi lingkaran progress
  late AnimationController _progressAnim;
  late Animation<double> _progressValue;
  double _prevProgress = 0;

  // Animasi badge muncul
  late AnimationController _badgeAnim;

  static const int _target = PedometerController.dailyTarget;

  @override
  void initState() {
    super.initState();

    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressValue = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressAnim, curve: Curves.easeOutCubic),
    );

    _badgeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _initPedometer();
  }

  Future<void> _initPedometer() async {
    await _ctrl.initialize();

    // Baca nilai awal
    final cached = await PedometerController.readStepsTodayCached();
    _updateSteps(cached);

    // Subscribe stream
    _stepSub = _ctrl.stepsStream.listen(_updateSteps);
    _statusSub = _ctrl.statusStream.listen((s) {
      if (mounted) setState(() => _status = s);
    });
  }

  void _updateSteps(int steps) {
    if (!mounted) return;
    final newProgress = (steps / _target).clamp(0.0, 1.0);

    // Animasi progress
    _progressValue = Tween<double>(
      begin: _prevProgress,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _progressAnim, curve: Curves.easeOutCubic));
    _progressAnim.forward(from: 0);
    _prevProgress = newProgress;

    setState(() {
      _steps = steps;
      _targetReached = steps >= _target;
    });

    // Gamifikasi: kirim notifikasi & animasi badge saat target tercapai
    if (steps >= _target && !_notifSent) {
      _notifSent = true;
      _badgeAnim.forward();
      _sendAchievementNotif();
    }
  }

  Future<void> _sendAchievementNotif() async {
    try {
      await NotificationController.showStepAchievement(_target);
    } catch (_) {
      // Notifikasi opsional '-" tidak crash jika gagal
    }
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _progressAnim.dispose();
    _badgeAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1C1C) : const Color(0xFFF9F9F9);
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF889390) : AppTheme.outline;
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEEEEEE);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bg,
      body: Column(
        children: [
          // '"-'"- App Bar '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
          _buildAppBar(isDark, textPrimary),

          // '"-'"- Content '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                children: [
                  // '"-'"- Circular Progress '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                  _buildCircularProgress(isDark, textPrimary, textSub),

                  const SizedBox(height: 28),

                  // '"-'"- Status Badge '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                  _buildStatusBadge(isDark),

                  const SizedBox(height: 28),

                  // '"-'"- Achievement Badge '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                  if (_targetReached) _buildAchievementBadge(isDark),
                  if (_targetReached) const SizedBox(height: 28),

                  // '"-'"- Stats Row '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                  _buildStatsRow(isDark, cardBg, cardBorder, textPrimary, textSub),

                  const SizedBox(height: 28),

                  // '"-'"- Motivasi Card '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                  _buildMotivasiCard(isDark, textPrimary, textSub),

                  const SizedBox(height: 28),

                  // '"-'"- Milestone List '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                  _buildMilestones(isDark, cardBg, cardBorder, textPrimary, textSub),

                  const SizedBox(height: 20),

                  // '"-'"- Reset Button '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                  _buildResetButton(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // '"-'"- App Bar '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
  Widget _buildAppBar(bool isDark, Color textPrimary) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: isDark
              ? const Color(0xFF1A1C1C).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.80),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: textPrimary, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Langkah Ibadah',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Target harian: ${_formatSteps(_target)} langkah',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Live indicator
                      Row(
                        children: [
                          _PulsingDot(
                            color: _status == WalkingStatus.walking
                                ? Colors.green
                                : AppTheme.outline,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _status == WalkingStatus.walking
                                ? 'BERJALAN'
                                : 'BERHENTI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _status == WalkingStatus.walking
                                  ? Colors.green
                                  : AppTheme.outline,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
      ),
    );
  }

  // '"-'"- Circular Progress '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
  Widget _buildCircularProgress(
      bool isDark, Color textPrimary, Color textSub) {
    return AnimatedBuilder(
      animation: _progressValue,
      builder: (context, _) {
        final progress = _progressValue.value;
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track
              CustomPaint(
                size: const Size(240, 240),
                painter: _CircleTrackPainter(
                  progress: progress,
                  isDark: isDark,
                  targetReached: _targetReached,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatSteps(_steps),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'langkah',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}% dari target',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // '"-'"- Status Badge '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
  Widget _buildStatusBadge(bool isDark) {
    final isWalking = _status == WalkingStatus.walking;
    final color = isWalking ? Colors.green : AppTheme.outline;
    final label = isWalking
        ? 'Anda sedang aktif bergerak ðŸ•Œ'
        : _status == WalkingStatus.stopped
            ? 'Anda sedang berhenti'
            : 'Mendeteksi aktivitas...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWalking
                ? Icons.directions_walk_rounded
                : Icons.accessibility_new_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // '"-'"- Achievement Badge '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
  Widget _buildAchievementBadge(bool isDark) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _badgeAnim, curve: Curves.elasticOut),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00695C), Color(0xFF283B9F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ðŸŽ‰ Target Tercapai!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Anda telah mencapai ${_formatSteps(_target)} langkah hari ini. Luar biasa!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // '"-'"- Stats Row '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
  Widget _buildStatsRow(bool isDark, Color cardBg, Color cardBorder,
      Color textPrimary, Color textSub) {
    final remaining = (_target - _steps).clamp(0, _target);
    final km = (_steps * 0.0008).toStringAsFixed(2); // ~0.8m per langkah

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.flag_rounded,
            iconColor: AppTheme.secondaryContainer,
            label: 'Sisa Target',
            value: _formatSteps(remaining),
            unit: 'langkah',
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSub: textSub,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.route_rounded,
            iconColor: AppTheme.tertiary,
            label: 'Jarak Tempuh',
            value: km,
            unit: 'km',
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSub: textSub,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.orange,
            label: 'Kalori',
            value: (_steps * 0.04).toStringAsFixed(0),
            unit: 'kkal',
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSub: textSub,
          ),
        ),
      ],
    );
  }

  // '"-'"- Motivasi Card '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
  Widget _buildMotivasiCard(bool isDark, Color textPrimary, Color textSub) {
    final quotes = [
      '"Bergerak aktif adalah tanda semangat pemuda." - KARISMA',
      '"Pemuda yang aktif adalah aset kampung yang berharga." - KARISMA',
      '"Setiap langkah menuju kebaikan adalah ibadah." - KARISMA',
    ];
    final quote = quotes[_steps % quotes.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              color: AppTheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quote,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // '"-'"- Milestone List '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
  Widget _buildMilestones(bool isDark, Color cardBg, Color cardBorder,
      Color textPrimary, Color textSub) {
    final milestones = [
      _Milestone(100, Icons.star_outline_rounded, 'Langkah Pertama'),
      _Milestone(250, Icons.directions_walk_rounded, 'Pejalan Aktif'),
      _Milestone(500, Icons.local_activity_rounded, 'Setengah Jalan'),
      _Milestone(750, Icons.trending_up_rounded, 'Hampir Sampai'),
      _Milestone(1000, Icons.emoji_events_rounded, 'Target Harian'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pencapaian',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: milestones.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              final reached = _steps >= m.steps;
              return Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: reached
                            ? AppTheme.primary.withValues(alpha: 0.12)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF3F3F3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        m.icon,
                        color: reached ? AppTheme.primary : AppTheme.outline,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      m.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: reached ? textPrimary : textSub,
                      ),
                    ),
                    subtitle: Text(
                      '${_formatSteps(m.steps)} langkah',
                      style: TextStyle(fontSize: 11, color: textSub),
                    ),
                    trailing: reached
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppTheme.primary, size: 20)
                        : Text(
                            '${_formatSteps(m.steps - _steps.clamp(0, m.steps))} lagi',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                  if (i < milestones.length - 1)
                    Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                      color: cardBorder,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // '"-'"- Reset Button '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
  Widget _buildResetButton(bool isDark) {
    return TextButton.icon(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reset Langkah'),
            content: const Text(
                'Reset hitungan langkah hari ini? Data tidak bisa dikembalikan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _ctrl.resetToday();
          _notifSent = false;
          _badgeAnim.reset();
        }
      },
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: const Text('Reset Hari Ini'),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.outline,
      ),
    );
  }

  String _formatSteps(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

// '"-'"-'"- Circular Track Painter '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
class _CircleTrackPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final bool targetReached;

  const _CircleTrackPainter({
    required this.progress,
    required this.isDark,
    required this.targetReached,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 14.0;
    const startAngle = -math.pi / 2; // mulai dari atas

    // Track background
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = (isDark ? Colors.white : AppTheme.primary)
            .withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress arc
    final sweepAngle = 2 * math.pi * progress;
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: targetReached
          ? [const Color(0xFF00695C), Colors.amber]
          : [AppTheme.primary, const Color(0xFF84D5C5)],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // Dot di ujung progress
    final dotAngle = startAngle + sweepAngle;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    canvas.drawCircle(
      Offset(dotX, dotY),
      strokeWidth / 2 + 2,
      Paint()
        ..color = targetReached ? Colors.amber : AppTheme.primaryFixed
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(dotX, dotY),
      strokeWidth / 2 + 2,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleTrackPainter old) =>
      old.progress != progress ||
      old.isDark != isDark ||
      old.targetReached != targetReached;
}

// '"-'"-'"- Stat Card '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSub;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 10, color: textSub),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// '"-'"-'"- Milestone Model '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
class _Milestone {
  final int steps;
  final IconData icon;
  final String label;
  const _Milestone(this.steps, this.icon, this.label);
}

// '"-'"-'"- Pulsing Dot '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
