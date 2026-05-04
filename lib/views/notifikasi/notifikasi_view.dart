import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

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
          if (_inbox.isNotEmpty)
            TextButton(
              onPressed: _hapusSemua,
              child: const Text(
                'Hapus Semua',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (ts.isNotEmpty)
                                        Text(
                                          ts,
                                          style: TextStyle(
                                              fontSize: 10, color: textSub),
                                        ),
                                    ],
                                  ),
                                  if (body.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      body,
                                      style:
                                          TextStyle(fontSize: 12, color: textSub),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 18, color: textSub),
                              onPressed: () => _hapusSatu(i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
