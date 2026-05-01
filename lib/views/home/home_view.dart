import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/auth_helper.dart';
import '../../theme/app_theme.dart';
import '../../controllers/keuangan_controller.dart';
import '../../controllers/dokumentasi_controller.dart';
import '../../models/dokumentasi_model.dart';
import '../beranda/beranda_view.dart';
import '../profil/profil_view.dart';
import '../saran/saran_view.dart';
import '../auth/login_view.dart';
import '../peta/peta_view.dart';

// Notifier global untuk switch tab dari mana saja
// Menggunakan _HomeTabController agar bisa force-notify meski value sama
class _HomeTabController extends ValueNotifier<int> {
  _HomeTabController(super.value);

  void switchTo(int index) {
    if (value == index) {
      // Force notify dengan trick: set ke -1 dulu lalu ke target
      value = -1;
      value = index;
    } else {
      value = index;
    }
  }
}

final homeTabNotifier = _HomeTabController(1);

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 1; // Beranda di tengah sebagai default
  bool _isLoggedIn = false;
  bool _sessionChecked = false;

  final List<Widget> _pages = const [
    SaranView(),
    BerandaView(),
    ProfilView(),
  ];

  @override
  void initState() {
    super.initState();
    _checkSession();
    homeTabNotifier.addListener(_onTabChange);
  }

  @override
  void dispose() {
    homeTabNotifier.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (mounted && homeTabNotifier.value >= 0) {
      setState(() => _currentIndex = homeTabNotifier.value);
    }
  }

  Future<void> _checkSession() async {
    final valid = await AuthHelper.isSessionValid();
    if (mounted) {
      setState(() {
        _isLoggedIn = valid;
        _sessionChecked = true;
      });
    }
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLoggedIn) {
      return _GuestView(onLoginSuccess: () {
        setState(() {
          _isLoggedIn = true;
          _currentIndex = 1;
        });
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: _GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Guest View ───────────────────────────────────────────────────────────────
class _GuestView extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const _GuestView({required this.onLoginSuccess});

  @override
  State<_GuestView> createState() => _GuestViewState();
}

class _GuestViewState extends State<_GuestView> {
  final KeuanganController _keuanganCtrl = KeuanganController();
  final DokumentasiController _dokCtrl = DokumentasiController();

  int _saldo = 0;
  List<DokumentasiModel> _dokumentasi = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final keuangan = await _keuanganCtrl.fetchKeuangan();
    final dok = await _dokCtrl.fetchDokumentasi();
    if (mounted) {
      setState(() {
        _saldo = (keuangan['saldo'] as int?) ?? 0;
        _dokumentasi = dok;
        _loading = false;
      });
    }
  }

  String _formatRupiah(int n) {
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $s';
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
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1A1C1C).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          'MyKarisma',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF84D5C5) : AppTheme.primary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
              if (result == true && mounted) {
                widget.onLoginSuccess();
              } else {
                // Cek ulang session setelah kembali dari login
                final valid = await AuthHelper.isSessionValid();
                if (valid && mounted) {
                  widget.onLoginSuccess();
                }
              }
            },
            icon: const Icon(Icons.login_rounded, size: 18, color: AppTheme.primary),
            label: const Text(
              'Masuk / Daftar',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Welcome Banner ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF004F45), Color(0xFF283B9F)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Anda sedang melihat sebagai tamu. Masuk untuk akses penuh.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.80),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                            onPressed: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginView()),
                              );
                              if (result == true && mounted) {
                                widget.onLoginSuccess();
                              } else {
                                final valid = await AuthHelper.isSessionValid();
                                if (valid && mounted) widget.onLoginSuccess();
                              }
                            },
                            icon: const Icon(Icons.login_rounded, size: 16),
                            label: const Text(
                              'Masuk Sekarang',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Saldo Terkini ───────────────────────────────────
                    Text(
                      'Saldo Terkini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00695C), Color(0xFF004F45)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kas Karisma',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatRupiah(_saldo),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                'Hanya tampilan — login untuk detail',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Dokumentasi ─────────────────────────────────────
                    Text(
                      'Dokumentasi Kegiatan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_dokumentasi.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada dokumentasi',
                            style: TextStyle(color: textSub, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...(_dokumentasi.take(5).map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.folder_rounded,
                                      color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nama,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        item.tanggal,
                                        style: TextStyle(
                                            fontSize: 11, color: textSub),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ))),

                    const SizedBox(height: 24),

                    // ── Lokasi Karisma ──────────────────────────────────
                    Text(
                      'Lokasi Karisma',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PetaView()),
                      ),
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder),
                          color: isDark
                              ? const Color(0xFF252828)
                              : const Color(0xFFE8E8E8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          const Color(0xFF1A2A28),
                                          const Color(0xFF1A1C2A)
                                        ]
                                      : [
                                          const Color(0xFFD4E8E4),
                                          const Color(0xFFD4D8E8)
                                        ],
                                ),
                              ),
                            ),
                            const Center(
                              child: Icon(
                                Icons.location_on_rounded,
                                color: AppTheme.primary,
                                size: 48,
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.5)
                                          : Colors.white.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Wilayah Karisma',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'BUKA PETA',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Glassmorphism Bottom Navigation ─────────────────────────────────────────
class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(
      icon: Icons.feedback_outlined,
      activeIcon: Icons.feedback_rounded,
      label: 'Saran',
    ),
    _NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Beranda',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1C1C).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.80),
            border: Border(
              top: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final isActive = i == currentIndex;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 20 : 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 22,
                            color: isActive
                                ? AppTheme.primary
                                : (isDark
                                    ? const Color(0xFF889390)
                                    : AppTheme.outline),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
