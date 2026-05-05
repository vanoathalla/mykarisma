import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../acara_list_view.dart';
import '../keuangan_view.dart';
import '../catatan_view.dart';
import '../member_view.dart';

/// Halaman inbox notifikasi — menampilkan semua notifikasi yang sudah dikirim.
/// Notifikasi disimpan di SharedPreferences key 'notif_inbox' sebagai JSON list.
class NotifikasiView extends StatefulWidget {
  const NotifikasiView({super.key});

  @override
  State<NotifikasiView> createState() => _NotifikasiViewState();
}

class _NotifikasiViewState extends State<NotifikasiView> {
  List<Map<String, dynamic>> _inbox = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInbox();
    // Badge TIDAK langsung di-reset — hanya berkurang saat notif di-tap
  }

  /// Tandai satu notif sebagai sudah dibaca
  Future<void> _tandaiSudahDibaca(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('notif_inbox') ?? [];
      if (index >= raw.length) return;

      final notif = jsonDecode(raw[index]) as Map<String, dynamic>;
      if (notif['read'] == true) return; // sudah dibaca, skip

      notif['read'] = true;
      raw[index] = jsonEncode(notif);
      await prefs.setStringList('notif_inbox', raw);

      // Tambah seen_count sebesar 1
      final seen = prefs.getInt('notif_seen_count') ?? 0;
      await prefs.setInt('notif_seen_count', seen + 1);

      if (mounted) setState(() => _inbox[index] = notif);
    } catch (_) {}
  }

  /// Tandai semua sebagai sudah dibaca (tombol "Baca Semua")
  Future<void> _tandaiSemuaDibaca() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('notif_inbox') ?? [];
      final updated = raw.map((s) {
        try {
          final m = jsonDecode(s) as Map<String, dynamic>;
          m['read'] = true;
          return jsonEncode(m);
        } catch (_) { return s; }
      }).toList();
      await prefs.setStringList('notif_inbox', updated);
      await prefs.setInt('notif_seen_count', updated.length);
      _loadInbox();
    } catch (_) {}
  }

  Future<void> _loadInbox() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('notif_inbox') ?? [];
      final parsed = raw.map((s) {
        try {
          return jsonDecode(s) as Map<String, dynamic>;
        } catch (_) {
          return <String, dynamic>{};
        }
      }).where((m) => m.isNotEmpty).toList();
      if (mounted) {
        setState(() {
          _inbox = parsed;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hapusSemua() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notif_inbox');
    if (mounted) setState(() => _inbox = []);
  }

  Future<void> _hapusSatu(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('notif_inbox') ?? [];
    if (index < raw.length) {
      raw.removeAt(index);
      await prefs.setStringList('notif_inbox', raw);
    }
    if (mounted) {
      setState(() => _inbox.removeAt(index));
    }
  }

  void _navigasiDariNotif(Map<String, dynamic> notif) {
    final title = (notif['title'] as String? ?? '').toLowerCase();
    final body = (notif['body'] as String? ?? '').toLowerCase();
    final combined = '$title $body';

    if (combined.contains('acara')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AcaraListView()));
    } else if (combined.contains('keuangan') || combined.contains('kas') ||
        combined.contains('pemasukan') || combined.contains('pengeluaran') ||
        combined.contains('saldo') || combined.contains('transaksi')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const KeuanganView()));
    } else if (combined.contains('catatan') || combined.contains('notulensi')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CatatanView()));
    } else if (combined.contains('member') || combined.contains('anggota') ||
        combined.contains('pengurus')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberView()));
    }
    // Jika tidak cocok, tidak navigasi (tetap di halaman notifikasi)
  }

  String _formatTimestamp(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1C1C) : AppTheme.background;
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
            : AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        actions: [
          if (_inbox.isNotEmpty) ...[
            // Tandai semua dibaca
            TextButton(
              onPressed: _tandaiSemuaDibaca,
              child: const Text('Baca Semua',
                style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: _hapusSemua,
              child: const Text('Hapus Semua',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _inbox.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 64, color: textSub),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada notifikasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Notifikasi akan muncul saat admin\nmenambahkan data atau acara baru',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 13, color: textSub, height: 1.5),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInbox,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    itemCount: _inbox.length,
                    itemBuilder: (context, i) {
                      final notif = _inbox[i];
                      final title = notif['title'] as String? ?? 'Notifikasi';
                      final body = notif['body'] as String? ?? '';
                      final ts = _formatTimestamp(notif['timestamp'] as String?);
                      final isRead = notif['read'] == true;

                      return GestureDetector(
                        onTap: () {
                          _tandaiSudahDibaca(i);
                          _navigasiDariNotif(notif);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            // Belum dibaca: sedikit lebih terang/berwarna
                            color: isRead
                                ? cardBg
                                : (isDark
                                    ? AppTheme.primary.withValues(alpha: 0.08)
                                    : AppTheme.primary.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? cardBorder
                                  : AppTheme.primary.withValues(alpha: 0.25),
                              width: isRead ? 1 : 1.5,
                            ),
                            boxShadow: isDark || isRead
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon — biru jika belum dibaca, abu jika sudah
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : const Color(0xFFEEEEEE))
                                      : AppTheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isRead
                                      ? Icons.notifications_outlined
                                      : Icons.notifications_active_rounded,
                                  color: isRead
                                      ? (isDark ? const Color(0xFF889390) : AppTheme.outline)
                                      : AppTheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              // Bold jika belum dibaca
                                              fontWeight: isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            if (ts.isNotEmpty)
                                              Text(ts,
                                                style: TextStyle(fontSize: 10, color: textSub)),
                                            // Dot biru jika belum dibaca
                                            if (!isRead) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                width: 8, height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (body.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(body,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isRead ? textSub : textPrimary.withValues(alpha: 0.75),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close_rounded, size: 18, color: textSub),
                                onPressed: () => _hapusSatu(i),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
