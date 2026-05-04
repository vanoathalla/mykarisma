import 'package:flutter/material.dart';
import '../controllers/acara_controller.dart';
import '../controllers/notification_controller.dart';
import '../helpers/auth_helper.dart';
import '../models/acara_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'tambah_acara_view.dart';

/// Halaman daftar acara.
/// - Semua role (tamu & admin) bisa melihat daftar acara.
/// - Hanya admin yang bisa tambah, edit, dan hapus acara.
class AcaraListView extends StatefulWidget {
  const AcaraListView({super.key});

  @override
  State<AcaraListView> createState() => _AcaraListViewState();
}

class _AcaraListViewState extends State<AcaraListView> {
  final AcaraController _acaraCtrl = AcaraController();

  List<AcaraModel> _allAcara = [];
  List<AcaraModel> _filteredAcara = [];
  bool _loading = true;
  String _roleUser = 'tamu';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadAcara();
  }

  Future<void> _loadRole() async {
    final session = await AuthHelper.getActiveSession();
    if (mounted) {
      setState(() => _roleUser = session?['role'] ?? 'tamu');
    }
  }

  Future<void> _loadAcara() async {
    setState(() => _loading = true);
    final data = await _acaraCtrl.fetchAcara();
    // Urutkan: acara mendatang dulu, lalu yang sudah lewat
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    data.sort((a, b) {
      final aFuture = a.tanggal.compareTo(todayStr) >= 0;
      final bFuture = b.tanggal.compareTo(todayStr) >= 0;
      if (aFuture && !bFuture) return -1;
      if (!aFuture && bFuture) return 1;
      return a.tanggal.compareTo(b.tanggal);
    });
    if (mounted) {
      setState(() {
        _allAcara = data;
        _filteredAcara = data;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredAcara = _allAcara;
      } else {
        final q = query.toLowerCase();
        _filteredAcara = _allAcara.where((a) {
          return a.nama.toLowerCase().contains(q) ||
              a.kategori.toLowerCase().contains(q) ||
              (a.lokasi ?? '').toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _hapusAcara(AcaraModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Acara'),
        content: Text('Yakin ingin menghapus acara "${item.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await _acaraCtrl.hapusAcara(item.idAcara);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']),
          backgroundColor: res['success'] ? Colors.green : Colors.red,
        ),
      );
      if (res['success']) _loadAcara();
    }
  }

  Color _getAcaraColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'keagamaan':
        return AppTheme.secondary;
      case 'internal':
        return AppTheme.primary;
      case 'sosial':
        return AppTheme.tertiary;
      default:
        return AppTheme.primaryContainer;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  bool _isMendatang(String tanggal) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return tanggal.compareTo(todayStr) >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1C1C) : AppTheme.background;
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF889390) : AppTheme.outline;
    final cardBg = isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLowest;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // '"-'"- App Bar '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
          Container(
            color: isDark
                ? const Color(0xFF1A1C1C).withValues(alpha: 0.95)
                : AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: textPrimary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Jadwal Acara',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppTheme.primary),
                          onPressed: _loadAcara,
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: TextField(
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Cari acara...',
                        hintStyle: TextStyle(color: textSub),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppTheme.primary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded,
                                    size: 18, color: textSub),
                                onPressed: () => _onSearchChanged(''),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  Container(
                      height: 1,
                      color: AppTheme.primary.withValues(alpha: 0.08)),
                ],
              ),
            ),
          ),

          // '"-'"- Content '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _filteredAcara.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.event_busy_rounded,
                              size: 56,
                              color: textSub,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada acara yang cocok'
                                  : 'Belum ada acara',
                              style: TextStyle(color: textSub, fontSize: 14),
                            ),
                            if (_roleUser == 'admin' &&
                                _searchQuery.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final r = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const TambahAcaraView()),
                                  );
                                  if (r == true) _loadAcara();
                                },
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Tambah Acara Pertama'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAcara,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 100),
                          itemCount: _filteredAcara.length,
                          itemBuilder: (context, i) {
                            final item = _filteredAcara[i];
                            final color = _getAcaraColor(item.kategori);
                            final mendatang = _isMendatang(item.tanggal);
                            
                            // Parse tanggal dan waktu
                            final parts = item.tanggal.split(' ');
                            final dateParts = parts[0].split('-');
                            final day = dateParts.length >= 3 ? dateParts[2] : '--';
                            final month = dateParts.length >= 2
                                ? _getMonthName(int.tryParse(dateParts[1]) ?? 1)
                                : '---';
                            final year = dateParts.isNotEmpty ? dateParts[0] : '----';
                            
                            // Ambil waktu jika ada (format HH:MM)
                            String? waktu;
                            if (parts.length > 1) {
                              final timeParts = parts[1].split(':');
                              if (timeParts.length >= 2) {
                                waktu = '${timeParts[0]}:${timeParts[1]}';
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: mendatang
                                        ? color.withValues(alpha: 0.25)
                                        : cardBorder,
                                  ),
                                  boxShadow: mendatang
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.06),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // ── Accent bar kiri ──────────────────
                                        Container(
                                          width: 4,
                                          color: mendatang
                                              ? color
                                              : textSub.withValues(alpha: 0.3),
                                        ),

                                        // ── Konten utama ─────────────────────
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                // ── Date box ─────────────────
                                                Opacity(
                                                  opacity: mendatang ? 1.0 : 0.45,
                                                  child: Container(
                                                    width: 60,
                                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(alpha: mendatang ? 0.10 : 0.06),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        // Tanggal
                                                        Text(
                                                          day,
                                                          style: TextStyle(
                                                            fontSize: 22,
                                                            fontWeight: FontWeight.w800,
                                                            color: color,
                                                            height: 1.0,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        // Bulan
                                                        Text(
                                                          month.toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                            color: color,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                        // Tahun
                                                        Text(
                                                          year,
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w500,
                                                            color: color.withValues(alpha: 0.6),
                                                          ),
                                                        ),
                                                        // Jam (jika ada)
                                                        if (waktu != null) ...[
                                                          const SizedBox(height: 4),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: color.withValues(alpha: 0.15),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              waktu,
                                                              style: TextStyle(
                                                                fontSize: 9,
                                                                fontWeight: FontWeight.w700,
                                                                color: color,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 14),

                                                // ── Info acara ───────────────
                                                Expanded(
                                                  child: Opacity(
                                                    opacity:
                                                        mendatang ? 1.0 : 0.55,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        // Nama + badge selesai
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                item.nama,
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color:
                                                                      textPrimary,
                                                                  height: 1.3,
                                                                ),
                                                              ),
                                                            ),
                                                            if (!mendatang) ...[
                                                              const SizedBox(
                                                                  width: 6),
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            2),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: textSub
                                                                      .withValues(
                                                                          alpha:
                                                                              0.12),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4),
                                                                ),
                                                                child: Text(
                                                                  'SELESAI',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize: 8,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        textSub,
                                                                    letterSpacing:
                                                                        0.5,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                        const SizedBox(height: 6),
                                                        // Kategori + lokasi
                                                        Row(
                                                          children: [
                                                            CategoryBadge(
                                                              label: item.kategori,
                                                              color: color
                                                                  .withValues(
                                                                      alpha:
                                                                          0.12),
                                                              textColor: color,
                                                            ),
                                                            if (item.lokasi != null && item.lokasi!.isNotEmpty) ...[
                                                              const SizedBox(
                                                                  width: 6),
                                                              Flexible(
                                                                child: Row(
                                                                  children: [
                                                                    Icon(Icons.location_on_outlined, size: 11, color: textSub),
                                                                    const SizedBox(width: 2),
                                                                    Flexible(
                                                                      child: Text(
                                                                        item.lokasi!,
                                                                        style: TextStyle(
                                                                            fontSize: 11,
                                                                            color:
                                                                                textSub),
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                                // ── Tombol aksi ──────────────
                                                if (_roleUser == 'admin') ...[
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      _ActionBtn(
                                                        icon: Icons.edit_rounded,
                                                        color: AppTheme.primary,
                                                        onTap: () async {
                                                          final r =
                                                              await Navigator
                                                                  .push<bool>(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  TambahAcaraView(
                                                                      acaraEdit:
                                                                          item),
                                                            ),
                                                          );
                                                          if (r == true) {
                                                            _loadAcara();
                                                          }
                                                        },
                                                      ),
                                                      const SizedBox(height: 6),
                                                      _ActionBtn(
                                                        icon: Icons
                                                            .delete_outline_rounded,
                                                        color: Colors.red,
                                                        onTap: () =>
                                                            _hapusAcara(item),
                                                      ),
                                                    ],
                                                  ),
                                                ],
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
                          },
                        ),
                      ),
          ),
        ],
      ),

      // FAB hanya untuk admin
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _roleUser == 'admin'
          ? FloatingActionButton(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              onPressed: () async {
                final r = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TambahAcaraView()),
                );
                if (r == true) _loadAcara();
              },
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}

// ── Helper widget: tombol aksi kecil (edit / hapus) ──────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
