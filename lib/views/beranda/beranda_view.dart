import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/auth_helper.dart';
import '../../theme/app_theme.dart';
import '../../controllers/keuangan_controller.dart';
import '../../controllers/acara_controller.dart';
import '../../controllers/catatan_controller.dart';
import '../../controllers/pedometer_controller.dart';
import '../../models/acara_model.dart';
import '../../models/catatan_model.dart';
import '../tambah_acara_view.dart';
import '../acara_list_view.dart';
import '../peta/peta_view.dart';
import '../ai/chatbot_view.dart';
import '../member_view.dart';
import '../dokumentasi_view.dart';
import '../konversi/konversi_view.dart';
import '../sensor/kiblat_view.dart';
import '../sensor/langkah_ibadah_view.dart';
import '../keuangan_view.dart';
import '../catatan_view.dart';
import '../saran/saran_view.dart';
import '../game/hijaiyah_game_view.dart';
import '../home/home_view.dart';
import '../notifikasi/notifikasi_view.dart';

class BerandaView extends StatefulWidget {
  const BerandaView({super.key});
  @override
  State<BerandaView> createState() => _BerandaViewState();
}

class _BerandaViewState extends State<BerandaView> {
  final KeuanganController _keuanganCtrl = KeuanganController();
  final AcaraController _acaraCtrl = AcaraController();
  final CatatanController _catatanCtrl = CatatanController();

  String _namaUser = 'Tamu Karisma';
  String _roleUser = 'tamu';
  bool _isLoading = true;
  int _totalSaldo = 0;
  List<AcaraModel> _acaraMendatang = [];
  List<CatatanModel> _catatanTerbaru = [];
  int _stepsToday = 0;
  String? _fotoPath; // foto profil user

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSteps();
    _loadFotoProfil();
  }

  Future<void> _loadFotoProfil() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _fotoPath = prefs.getString('foto_path'));
    }
  }

  Future<void> _loadSteps() async {
    final session = await AuthHelper.getActiveSession();
    final userId = session?['id_member']?.toString() ?? 'guest';
    final steps = await PedometerController.readStepsTodayCached(userId: userId);
    if (mounted) setState(() => _stepsToday = steps);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final session = await AuthHelper.getActiveSession();
    if (session != null) {
      _namaUser = session['nama'] ?? 'Tamu Karisma';
      _roleUser = session['role'] ?? 'tamu';
    }
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final keuangan = await _keuanganCtrl.fetchKeuangan();
    final acara = await _acaraCtrl.fetchAcara();
    final catatan = await _catatanCtrl.fetchCatatan();
    final mendatang = acara
        .where((a) {
          final tanggalOnly = a.tanggal.split(' ').first.trim();
          return tanggalOnly.compareTo(todayStr) >= 0;
        })
        .toList()
      ..sort((a, b) {
        final aDate = a.tanggal.split(' ').first.trim();
        final bDate = b.tanggal.split(' ').first.trim();
        return aDate.compareTo(bDate);
      });
    if (!mounted) return;
    setState(() {
      _totalSaldo = (keuangan['saldo'] as int?) ?? 0;
      _acaraMendatang = mendatang.take(1).toList();
      _catatanTerbaru = catatan.take(1).toList();
      _isLoading = false;
    });
  }

  String _formatRupiah(int n) {
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $s';
  }

  String _dateLabel() {
    final now = DateTime.now();
    const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${now.day} ${m[now.month - 1]} ${now.year}';
  }

  Color _acaraColor(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'kajian': return AppTheme.secondaryContainer;
      case 'ibadah': return AppTheme.primary;
      case 'sosial': return AppTheme.tertiary;
      default: return AppTheme.primaryContainer;
    }
  }

  String _monthName(int m) {
    const months = ['JAN','FEB','MAR','APR','MEI','JUN','JUL','AGU','SEP','OKT','NOV','DES'];
    return months[m - 1];
  }

  void _go(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1C1C) : const Color(0xFFF9F9F9);
    // Ambil tinggi status bar sekali di sini, teruskan ke delegate
    final statusBarH = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: CustomScrollView(
          // ClampingScrollPhysics: tidak ada overscroll bounce di bawah,
          // RefreshIndicator tetap aktif untuk pull-to-refresh dari atas
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _GlassAppBarDelegate(
                isDark: isDark,
                child: _buildTopBar(isDark),
                statusBarHeight: statusBarH,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildGreeting(isDark),
                  const SizedBox(height: 24),
                  _buildAiCard(),
                  const SizedBox(height: 24),
                  _buildQuickGrid(isDark),
                  const SizedBox(height: 12),
                  _buildFinancial(isDark),
                  const SizedBox(height: 24),
                  _buildEvents(isDark),
                  const SizedBox(height: 24),
                  _buildNotulensi(isDark),
                  const SizedBox(height: 24),
                  _buildMap(isDark),
                  const SizedBox(height: 24),
                  _buildLangkahCard(isDark),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: null, // FAB + dihapus dari beranda — ada di dalam masing-masing fitur
    );
  }

  //  TOP BAR 
  Widget _buildTopBar(bool isDark) {
    return Row(
      children: [
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => homeTabNotifier.switchTo(2), // Switch ke tab Profil
          child: Stack(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.20), width: 2),
                ),
                child: ClipOval(
                  child: _fotoPath != null && File(_fotoPath!).existsSync()
                      ? Image.file(File(_fotoPath!), fit: BoxFit.cover, width: 40, height: 40)
                      : const Icon(Icons.person_rounded, color: AppTheme.primary, size: 22),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF1A1C1C) : Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'MyKarisma',
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF84D5C5) : AppTheme.primary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.notifications_outlined,
              color: isDark ? const Color(0xFF84D5C5) : AppTheme.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotifikasiView()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  //  1. GREETING GLASS CARD 
  Widget _buildGreeting(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.40),
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Haii Selamat Datang,',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF84D5C5) : AppTheme.primaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _namaUser,
                                style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_roleUser == 'admin') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.20)),
                                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 10)],
                                ),
                                child: const Text('ADMIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 0.8)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? const Color(0xFF889390) : AppTheme.outline),
                  const SizedBox(width: 6),
                  Text(_dateLabel(), style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF889390) : AppTheme.outline)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  2. AI MESH GRADIENT CARD 
  Widget _buildAiCard() {
    return GestureDetector(
      onTap: () => _go(const ChatbotView()),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF00695C), Color(0xFF283B9F)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Icon(Icons.psychology_rounded, size: 90, color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Karisma AI Assistant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.80))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '"Tanya jadwal kajian atau laporan keuangan bulan ini..."',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _BouncingDots(),
                        const SizedBox(width: 8),
                        Text('Karisma AI sedang mengetik...', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.70))),
                      ],
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

  //  3. QUICK ACTION GRID 
  Widget _buildQuickGrid(bool isDark) {
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEEEEE);
    final labelColor = isDark ? const Color(0xFF889390) : AppTheme.onSurfaceVariant;

    // Semua fitur tersusun langsung di grid — tidak ada menu "Lainnya"
    final items = [
      _QAItem(Icons.calendar_month_rounded, 'Acara', () => _go(const AcaraListView())),
      _QAItem(Icons.account_balance_wallet_rounded, 'Keuangan', () => _go(const KeuanganView())),
      _QAItem(Icons.sticky_note_2_rounded, 'Catatan', () => _go(const CatatanView())),
      _QAItem(Icons.group_rounded, 'Member', () => _go(const MemberView())),
      _QAItem(Icons.folder_open_rounded, 'Dokumentasi', () => _go(const DokumentasiView())),
      _QAItem(Icons.location_on_rounded, 'Lokasi', () => _go(const PetaView())),
      _QAItem(Icons.explore_rounded, 'Kiblat', () => _go(const KiblatView())),
      _QAItem(Icons.directions_walk_rounded, 'Langkah', () => _go(const LangkahIbadahView())),
      _QAItem(Icons.currency_exchange_rounded, 'Konversi', () => _go(const KonversiView())),
      _QAItem(Icons.games_rounded, 'Mini Game', () => _go(const HijaiyahGameView())),
      _QAItem(Icons.feedback_outlined, 'Saran', () => _go(const SaranView())),
      _QAItem(Icons.smart_toy_rounded, 'AI Chat', () => _go(const ChatbotView())),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 16, childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return GestureDetector(
          onTap: item.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Icon(item.icon, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(height: 6),
              Text(item.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: labelColor, height: 1.2)),
            ],
          ),
        );
      },
    );
  }

  //  4. FINANCIAL SNAPSHOT 
  Widget _buildFinancial(bool isDark) {
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEEEEE);
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF889390) : AppTheme.onSurfaceVariant;
    const barHeights = [0.4, 0.6, 0.5, 0.8, 1.0];

    return GestureDetector(
      onTap: () => _go(const KeuanganView()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cardBorder),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kas Karisma', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSub)),
                Icon(Icons.trending_up_rounded, color: AppTheme.secondaryContainer, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isLoading
                        ? Container(width: 140, height: 28, decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(6)))
                        : Text(_formatRupiah(_totalSaldo), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward_rounded, size: 13, color: Colors.green),
                        const SizedBox(width: 3),
                        const Text('Saldo aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  width: 80, height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: barHeights.map((h) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          height: 40 * h,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2 + h * 0.8),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //  5. UPCOMING EVENTS 
  Widget _buildEvents(bool isDark) {
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF889390) : AppTheme.outline;
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEEEEE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Agenda Terdekat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
            GestureDetector(
              onTap: () => _go(const AcaraListView()),
              child: const Text('Lihat Semua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          Column(children: List.generate(2, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(height: 80, decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(18))),
          )))
        else if (_acaraMendatang.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            child: Center(child: Column(children: [
              Icon(Icons.event_busy_rounded, size: 40, color: textSub),
              const SizedBox(height: 8),
              Text('Tidak ada agenda mendatang', style: TextStyle(color: textSub, fontSize: 13)),
            ])),
          )
        else
          Column(
            children: _acaraMendatang.map((item) {
              final color = _acaraColor(item.tipe);
              // Parse tanggal dan waktu
              final parts = item.tanggal.split(' ');
              final dateParts = parts[0].split('-');
              final day   = dateParts.length >= 3 ? dateParts[2] : '--';
              final month = dateParts.length >= 2 ? _monthName(int.tryParse(dateParts[1]) ?? 1) : '---';
              final year  = dateParts.isNotEmpty ? dateParts[0] : '----';
              // Ambil jam jika ada
              String? waktu;
              if (parts.length > 1) {
                final tp = parts[1].split(':');
                if (tp.length >= 2) waktu = '${tp[0]}:${tp[1]}';
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Accent bar kiri
                          Container(width: 4, color: color),
                          // Konten
                          Expanded(
                            child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Date box — tanggal, bulan, tahun, jam
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(day, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1.0)),
                              const SizedBox(height: 2),
                              Text(month, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                              Text(year, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.6))),
                              if (waktu != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(waktu, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.nama, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF1F1F1) : Colors.black87)),
                              const SizedBox(height: 6),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                                  child: Text(item.kategori.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                                ),
                                if (item.lokasi != null && item.lokasi!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.location_on_outlined, size: 11, color: textSub),
                                  const SizedBox(width: 2),
                                  Flexible(child: Text(item.lokasi!, style: TextStyle(fontSize: 11, color: textSub), overflow: TextOverflow.ellipsis)),
                                ],
                              ]),
                            ],
                          ),
                        ),
                        if (_roleUser == 'admin')
                          GestureDetector(
                            onTap: () async {
                              final r = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => TambahAcaraView(acaraEdit: item)));
                              if (r == true) _loadData();
                            },
                            child: Icon(Icons.edit_outlined, size: 18, color: textSub),
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
            }).toList(),
          ),
      ],
    );
  }

  //  6. NOTULENSI — 1 CARD TERBARU 
  Widget _buildNotulensi(bool isDark) {
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF889390) : AppTheme.outline;
    final textSubtle = isDark ? const Color(0xFF889390) : AppTheme.onSurfaceVariant;
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEEEEE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Notulensi Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
            GestureDetector(
              onTap: () => _go(const CatatanView()),
              child: const Text('Lihat Semua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(24),
            ),
          )
        else if (_catatanTerbaru.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: cardBorder)),
            child: Center(child: Text('Belum ada notulensi', style: TextStyle(color: textSub, fontSize: 13))),
          )
        else
          GestureDetector(
            onTap: () => _go(const CatatanView()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_edu_rounded, color: AppTheme.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _catatanTerbaru.first.acara.isNotEmpty
                              ? _catatanTerbaru.first.acara.toUpperCase()
                              : 'NOTULENSI',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textSub, letterSpacing: 0.8),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _catatanTerbaru.first.judul,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _catatanTerbaru.first.isi,
                    style: TextStyle(fontSize: 12, color: textSubtle, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _catatanTerbaru.first.tanggal,
                    style: TextStyle(fontSize: 10, color: textSub, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  //  7. MAP WIDGET 
  Widget _buildMap(bool isDark) {
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEEEEE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lokasi Strategis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _go(const PetaView()),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cardBorder),
              color: isDark ? const Color(0xFF252828) : const Color(0xFFE8E8E8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Map placeholder background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1A2A28), const Color(0xFF1A1C2A)]
                          : [const Color(0xFFD4E8E4), const Color(0xFFD4D8E8)],
                    ),
                  ),
                ),
                // Grid lines (map-like)
                CustomPaint(size: const Size(double.infinity, 180), painter: _MapGridPainter(isDark: isDark)),
                // Center pin
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 40),
                    ],
                  ),
                ),
                // Bottom overlay
                Positioned(
                  bottom: 12, left: 12, right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Wilayah Karisma', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                              child: const Text('NAVIGASI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
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
    );
  }

  // ── 8. LANGKAH IBADAH CARD ────────────────────────────────────────────────
  Widget _buildLangkahCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEEEEEE);
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF889390) : AppTheme.outline;

    final progress = (_stepsToday / PedometerController.dailyTarget).clamp(0.0, 1.0);
    final targetReached = _stepsToday >= PedometerController.dailyTarget;

    return GestureDetector(
      onTap: () => _go(const LangkahIbadahView()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cardBorder),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_walk_rounded,
                          color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Langkah Ibadah',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Target: ${PedometerController.dailyTarget} langkah/hari',
                          style: TextStyle(fontSize: 11, color: textSub),
                        ),
                      ],
                    ),
                  ],
                ),
                if (targetReached)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            color: Colors.amber, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'TERCAPAI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Langkah count + progress bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_stepsToday',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: targetReached ? Colors.amber : textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ ${PedometerController.dailyTarget} langkah',
                    style: TextStyle(fontSize: 12, color: textSub),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Linear progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.primary.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  targetReached ? Colors.amber : AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Teks dinamis
            Text(
              _stepsToday == 0
                  ? 'Mulai berjalan untuk menghitung langkah Anda 🚶'
                  : targetReached
                      ? '🎉 Selamat! Target harian tercapai!'
                      : 'Langkah Anda hari ini: $_stepsToday',
              style: TextStyle(
                fontSize: 12,
                color: targetReached ? Colors.amber : textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MORE SHEET ────────────────────────────────────────────────────────────
}

//  Helper Classes 

class _QAItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QAItem(this.icon, this.label, this.onTap);
}

// ─── Sticky Glass App Bar ─────────────────────────────────────────────────────
class _GlassAppBarDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final Widget child;
  // statusBarHeight diteruskan dari build() agar delegate tahu tinggi status bar
  final double statusBarHeight;

  const _GlassAppBarDelegate({
    required this.isDark,
    required this.child,
    required this.statusBarHeight,
  });

  // Tinggi total = status bar + konten bar (56px)
  double get _total => statusBarHeight + 56;

  @override
  double get minExtent => _total;
  @override
  double get maxExtent => _total;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: _total,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1C1C).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.75),
            border: Border(
              bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.08)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // Padding manual = status bar, bukan SafeArea,
          // supaya tinggi delegate tidak berubah-ubah
          child: Padding(
            padding: EdgeInsets.only(top: statusBarHeight),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GlassAppBarDelegate old) =>
      old.isDark != isDark || old.statusBarHeight != statusBarHeight;
}

//  Bouncing Dots (AI typing indicator) 
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)));
    _anims = _ctrls.map((c) => Tween<double>(begin: 0, end: -6).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _anims[i].value),
          child: Container(
            width: 6, height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.65), shape: BoxShape.circle),
          ),
        ),
      )),
    );
  }
}

//  Map Grid Painter 
class _MapGridPainter extends CustomPainter {
  final bool isDark;
  const _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : AppTheme.primary).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Road-like lines
    final roadPaint = Paint()
      ..color = (isDark ? Colors.white : AppTheme.primary).withValues(alpha: 0.12)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), roadPaint);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter old) => old.isDark != isDark;
}
