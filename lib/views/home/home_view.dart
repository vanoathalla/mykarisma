import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/auth_helper.dart';
import '../../theme/app_theme.dart';
import '../../controllers/keuangan_controller.dart';
import '../../controllers/dokumentasi_controller.dart';
import '../../controllers/pedometer_controller.dart';
import '../../models/dokumentasi_model.dart';
import '../beranda/beranda_view.dart';
import '../profil/profil_view.dart';
import '../saran/saran_view.dart';
import '../auth/login_view.dart';
import '../peta/peta_view.dart';

// ─── Global tab notifier ──────────────────────────────────────────────────────
class _HomeTabController extends ValueNotifier<int> {
  _HomeTabController(super.value);

  void switchTo(int index) {
    if (value == index) {
      value = -1;
      value = index;
    } else {
      value = index;
    }
  }
}

final homeTabNotifier = _HomeTabController(1);

// ─── HomeView ─────────────────────────────────────────────────────────────────
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // 0 = Saran, 1 = Beranda (center/FAB), 2 = Profil
  int _currentIndex = 1;
  bool _isLoggedIn = false;
  bool _sessionChecked = false;

  // Step counter untuk navbar
  int _stepsToday = 0;
  StreamSubscription<int>? _stepSub;

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
    _initStepCounter();
  }

  @override
  void dispose() {
    homeTabNotifier.removeListener(_onTabChange);
    _stepSub?.cancel();
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

  Future<void> _initStepCounter() async {
    // Baca userId dari session untuk isolasi langkah per-user
    final session = await AuthHelper.getActiveSession();
    final userId = session?['id_member']?.toString() ?? 'guest';

    // Baca cache dulu (cepat, tanpa stream)
    final cached = await PedometerController.readStepsTodayCached(userId: userId);
    if (mounted) setState(() => _stepsToday = cached);

    // Init controller dengan userId agar langkah terpisah per-user
    final ctrl = PedometerController();
    await ctrl.initForUser(userId);
    _stepSub = ctrl.stepsStream.listen((steps) {
      if (mounted) setState(() => _stepsToday = steps);
    });
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true, // body mengalir di bawah navbar
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // ── Floating Action Button (center docked, lebih besar) ────────
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: () => _onTap(1),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _currentIndex == 1
                  ? Icons.grid_view_rounded
                  : Icons.grid_view_outlined,
              key: ValueKey(_currentIndex == 1),
              size: 30,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // ── Bottom App Bar ──────────────────────────────────────────────
      bottomNavigationBar: _NotchedBottomBar(
        currentIndex: _currentIndex,
        stepsToday: _stepsToday,
        isDark: isDark,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Notched Bottom Bar ───────────────────────────────────────────────────────
class _NotchedBottomBar extends StatelessWidget {
  final int currentIndex;
  final int stepsToday;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _NotchedBottomBar({
    required this.currentIndex,
    required this.stepsToday,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF1A1C1C).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);
    final activeColor = AppTheme.primary;
    final inactiveColor =
        isDark ? const Color(0xFF889390) : AppTheme.outline;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: BottomAppBar(
          color: bg,
          elevation: 0,
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                // ── Slot Kiri: Saran + step counter ──────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(0),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          currentIndex == 0
                              ? Icons.rate_review_rounded
                              : Icons.rate_review_outlined,
                          size: 22,
                          color: currentIndex == 0 ? activeColor : inactiveColor,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Saran',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: currentIndex == 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: currentIndex == 0 ? activeColor : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Ruang untuk FAB notch ─────────────────────────────
                const SizedBox(width: 80),

                // ── Slot Kanan: Profil ────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(2),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          currentIndex == 2
                              ? Icons.person_rounded
                              : Icons.person_outline_rounded,
                          size: 22,
                          color: currentIndex == 2 ? activeColor : inactiveColor,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Profil',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: currentIndex == 2
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: currentIndex == 2 ? activeColor : inactiveColor,
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
      ),
    );
  }
}

// ─── Guest View — SacredHub Landing Page ─────────────────────────────────────
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
  // Animasi counter saldo
  int _displaySaldo = 0;

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
      _animateCounter();
    }
  }

  void _animateCounter() {
    final target = _saldo;
    const steps = 30;
    final stepVal = (target / steps).ceil();
    int current = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return false;
      current = (current + stepVal).clamp(0, target);
      setState(() => _displaySaldo = current);
      return current < target;
    });
  }

  String _formatRupiah(int n) {
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $s';
  }

  Future<void> _goToLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
    if (result == true && mounted) {
      widget.onLoginSuccess();
    } else {
      final valid = await AuthHelper.isSessionValid();
      if (valid && mounted) widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0D1A) : const Color(0xFFF8F9FF);
    final textPrimary = isDark ? const Color(0xFFEEF0FF) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF8B90B8) : AppTheme.outline;
    final cardBg = isDark ? const Color(0xFF1C2038) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.outlineVariant.withValues(alpha: 0.4);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  // ── App Bar ──────────────────────────────────────────
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: isDark
                        ? const Color(0xFF0A0D1A).withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.92),
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    titleSpacing: 20,
                    title: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text('MyKarisma',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF90CAF9) : AppTheme.primary,
                                letterSpacing: -0.3)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: _goToLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Masuk',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(1),
                      child: Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        //  Badge 
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.20)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('', style: TextStyle(fontSize: 13)),
                                SizedBox(width: 6),
                                Text('PORTAL DIGITAL KARISMA',
                                    style: TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w700,
                                        color: AppTheme.primary, letterSpacing: 0.8)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        //  Headline 
                        Text(
                          'Keunggulan Spiritual,\nTerpadu dalam Genggaman.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: textPrimary, height: 1.25, letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'Kelola komunitas dan organisasi Islam dengan pusat dinamika modern yang dirancang untuk kejelasan tujuan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: textSub, height: 1.6),
                        ),

                        const SizedBox(height: 28),

                        //  CTA Button 
                        Center(
                          child: GestureDetector(
                            onTap: _goToLogin,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryContainer, // Amber #F89C00
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                                    blurRadius: 20, offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Daftar Sekarang',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15,
                                          fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        //  Financial Card 
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [Color(0xFF1A237E), Color(0xFF0277BD)],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                                blurRadius: 30, offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Kas KARISMA',
                                      style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('Transparansi Keuangan Terkini',
                                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _formatRupiah(_displaySaldo),
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.w800,
                                    color: Colors.white, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.lock_outline_rounded, size: 12, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text('Login untuk melihat detail transaksi',
                                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                              ]),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        //  Location Card 
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: cardBorder),
                            boxShadow: isDark ? [] : [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 30, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.mosque_rounded, color: AppTheme.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Lokasi KARISMA',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                                    Text('Kemiri Sewu, Sidorejo, Kec. Godean, Sleman, DIY',
                                        style: TextStyle(fontSize: 11, color: textSub, height: 1.4)),
                                  ]),
                                ),
                              ]),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const PetaView())),
                                  icon: const Text('', style: TextStyle(fontSize: 16)),
                                  label: const Text('Petunjuk Arah'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        //  Dokumentasi Carousel 
                        if (_dokumentasi.isNotEmpty) ...[
                          Text('Dokumentasi Kegiatan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              itemCount: _dokumentasi.length,
                              itemBuilder: (ctx, i) {
                                final item = _dokumentasi[i];
                                return Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.folder_rounded, color: AppTheme.primary, size: 18),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(item.nama,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(item.tanggal,
                                          style: TextStyle(fontSize: 10, color: textSub)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        //  Footer 
                        Center(
                          child: Text(
                            ' 2024 MyKarisma  Karang Taruna Pemuda Desa',
                            style: TextStyle(fontSize: 11, color: textSub),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}