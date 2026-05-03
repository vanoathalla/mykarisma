import 'package:flutter/material.dart';
import '../controllers/acara_controller.dart';
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
              a.tipe.toLowerCase().contains(q);
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

  Color _getAcaraColor(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'kajian':
        return AppTheme.secondary;
      case 'ibadah':
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
          // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadwal Acara',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              // Badge role
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _roleUser == 'admin'
                                          ? AppTheme.primary.withValues(alpha: 0.12)
                                          : AppTheme.outline.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _roleUser == 'admin'
                                          ? 'Mode Admin â€” Bisa tambah/edit/hapus'
                                          : 'Mode Tamu â€” Hanya lihat',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _roleUser == 'admin'
                                            ? AppTheme.primary
                                            : textSub,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

          // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                              const EdgeInsets.fromLTRB(20, 16, 20, 120),
                          itemCount: _filteredAcara.length,
                          itemBuilder: (context, i) {
                            final item = _filteredAcara[i];
                            final color = _getAcaraColor(item.tipe);
                            final mendatang = _isMendatang(item.tanggal);
                            final parts = item.tanggal.split('-');
                            final day =
                                parts.length >= 3 ? parts[2] : '--';
                            final month = parts.length >= 2
                                ? _getMonthName(
                                    int.tryParse(parts[1]) ?? 1)
                                : '---';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: cardBorder),
                                  boxShadow: mendatang
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
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
                                        // Accent bar kiri
                                        Container(
                                          width: 4,
                                          color: mendatang
                                              ? color
                                              : textSub.withValues(alpha: 0.4),
                                        ),
                                        // Konten
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Row(
                                              children: [
                                                // Tanggal
                                                Opacity(
                                                  opacity: mendatang ? 1.0 : 0.5,
                                                  child: Container(
                                                    width: 52,
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(alpha: 0.10),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          day,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.w800,
                                                            color: color,
                                                          ),
                                                        ),
                                                        Text(
                                                          month.toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w700,
                                                            color: color.withValues(alpha: 0.7),
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                // Info
                                                Expanded(
                                                  child: Opacity(
                                                    opacity: mendatang ? 1.0 : 0.6,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                item.nama,
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: textPrimary,
                                                                ),
                                                              ),
                                                            ),
                                                            if (!mendatang)
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: textSub.withValues(alpha: 0.12),
                                                                  borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: Text(
                                                                  'SELESAI',
                                                                  style: TextStyle(
                                                                    fontSize: 9,
                                                                    fontWeight: FontWeight.w700,
                                                                    color: textSub,
                                                                    letterSpacing: 0.5,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            CategoryBadge(
                                                              label: item.tipe,
                                                              color: color.withValues(alpha: 0.12),
                                                              textColor: color,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Flexible(
                                                              child: Text(
                                                                item.kategori,
                                                                style: TextStyle(fontSize: 11, color: textSub),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                // Tombol admin
                                                if (_roleUser == 'admin') ...[
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () async {
                                                          final r = await Navigator.push<bool>(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) => TambahAcaraView(acaraEdit: item),
                                                            ),
                                                          );
                                                          if (r == true) _loadAcara();
                                                        },
                                                        child: Container(
                                                          width: 32,
                                                          height: 32,
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.primary.withValues(alpha: 0.10),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      GestureDetector(
                                                        onTap: () => _hapusAcara(item),
                                                        child: Container(
                                                          width: 32,
                                                          height: 32,
                                                          decoration: BoxDecoration(
                                                            color: Colors.red.withValues(alpha: 0.10),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                                        ),
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
