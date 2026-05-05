import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../helpers/auth_helper.dart';
import '../../helpers/database_helper.dart';
import '../../models/feedback_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../home/home_view.dart';
import '../../controllers/notification_controller.dart';
import '../../services/overlay_notification_service.dart';

class SaranView extends StatefulWidget {
  const SaranView({super.key});

  @override
  State<SaranView> createState() => _SaranViewState();
}

class _SaranViewState extends State<SaranView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isAdmin = false;

  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();
  double _rating = 0;
  bool _loadingKirim = false;

  List<FeedbackModel> _inbox = [];
  bool _loadingInbox = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadRole();
  }

  Future<void> _loadRole() async {
    final s = await AuthHelper.getActiveSession();
    if (mounted) {
      setState(() => _isAdmin = s?['role'] == 'admin');
      if (_isAdmin) _loadInbox();
    }
  }

  Future<void> _loadInbox() async {
    setState(() => _loadingInbox = true);
    try {
      final rows = await DatabaseHelper.instance.getAllFeedback();
      if (mounted) {
        setState(() {
          _inbox = rows.map((r) => FeedbackModel.fromJson(r)).toList();
          _loadingInbox = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInbox = false);
    }
  }

  Future<void> _hapusFeedback(FeedbackModel fb) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Saran'),
        content: const Text('Yakin ingin menghapus saran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || fb.idFeedback == null) return;
    await DatabaseHelper.instance.deleteFeedback(fb.idFeedback!);
    _loadInbox();
  }

  Future<void> _kirimSaran() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final model = FeedbackModel(
      nama: _namaCtrl.text.trim().isEmpty ? null : _namaCtrl.text.trim(),
      rating: _rating.round(),
      kategori: 'Umum',
      isi: _isiCtrl.text.trim(),
      tanggal: DateTime.now().toIso8601String().split('T').first,
    );
    final err = model.validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red));
      return;
    }
    setState(() => _loadingKirim = true);
    try {
      await DatabaseHelper.instance.insertFeedback(model.toMap());

      final pengirim = model.nama ?? 'Anonim';
      final bintang = '★' * model.rating + '☆' * (5 - model.rating);
      await NotificationController.showUpdateNotif(
        judul: '💬 Saran Baru dari $pengirim',
        isi: '$bintang  ${model.isi.length > 60 ? '${model.isi.substring(0, 60)}...' : model.isi}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saran berhasil dikirim. Terima kasih!'),
            backgroundColor: Colors.green));
        _resetForm();
        if (_isAdmin) _loadInbox();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loadingKirim = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _namaCtrl.clear();
    _isiCtrl.clear();
    setState(() => _rating = 0);
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Sangat Kurang';
      case 2: return 'Kurang';
      case 3: return 'Cukup';
      case 4: return 'Baik';
      case 5: return 'Sangat Baik';
      default: return '';
    }
  }

  Color _ratingColor(int r) {
    if (r <= 2) return Colors.red;
    if (r == 3) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _namaCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1C1C) : AppTheme.background;
    final tp = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1A1C1C).withValues(alpha: 0.95)
            : AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tp, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              homeTabNotifier.switchTo(1);
            }
          },
        ),
        title: Text('Saran & Kesan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: tp)),
        bottom: _isAdmin
            ? TabBar(
                controller: _tabCtrl,
                labelColor: AppTheme.primary,
                unselectedLabelColor: isDark ? const Color(0xFF889390) : AppTheme.outline,
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(icon: Icon(Icons.inbox_rounded, size: 18), text: 'Kotak Masuk'),
                  Tab(icon: Icon(Icons.send_rounded, size: 18), text: 'Kirim Saran'),
                ],
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
              ),
      ),
      body: _isAdmin
          ? TabBarView(
              controller: _tabCtrl,
              children: [
                _buildInboxTab(isDark, tp),
                _buildFormTab(isDark),
              ],
            )
          : _buildFormTab(isDark),
    );
  }

  Widget _buildInboxTab(bool isDark, Color tp) {
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;
    final bdr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.outlineVariant.withValues(alpha: 0.5);
    final sub = isDark ? const Color(0xFF889390) : AppTheme.outline;

    if (_loadingInbox) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_inbox.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_rounded, size: 64, color: sub),
          const SizedBox(height: 16),
          Text('Belum ada saran masuk',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp)),
          const SizedBox(height: 8),
          Text('Saran dari member akan muncul di sini',
            style: TextStyle(fontSize: 13, color: sub)),
        ]),
      );
    }

    final avgRating = _inbox.isEmpty ? 0.0
        : _inbox.map((f) => f.rating).reduce((a, b) => a + b) / _inbox.length;

    return RefreshIndicator(
      onRefresh: _loadInbox,
      color: AppTheme.primary,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF283593)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total Saran Masuk',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('${_inbox.length} saran',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Rata-rata Rating',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  ]),
                ]),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final fb = _inbox[i];
                  final rc = _ratingColor(fb.rating);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: bdr),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                          child: Text(
                            fb.nama != null && fb.nama!.isNotEmpty
                                ? fb.nama![0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(fb.nama ?? 'Anonim',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tp)),
                          Text(fb.tanggal,
                            style: TextStyle(fontSize: 11, color: sub)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: rc.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.star_rounded, color: rc, size: 14),
                            const SizedBox(width: 3),
                            Text('${fb.rating}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: rc)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _hapusFeedback(fb),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.red),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: List.generate(5, (j) => Icon(
                        j < fb.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber, size: 16))),
                      const SizedBox(height: 6),
                      Text(_ratingLabel(fb.rating),
                        style: TextStyle(fontSize: 11, color: rc, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppTheme.primary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(fb.isi,
                          style: TextStyle(fontSize: 13, color: tp, height: 1.5)),
                      ),
                    ]),
                  );
                },
                childCount: _inbox.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormTab(bool isDark) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AiMeshCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.feedback_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Berikan Saran & Kesan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Masukan Anda sangat berarti untuk kemajuan KARISMA.',
                          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextFormField(
                    controller: _namaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama (opsional)',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primary)),
                  ),
                  const SizedBox(height: 20),

                  SurfaceCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Rating',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                      const SizedBox(height: 12),
                      RatingBar.builder(
                        initialRating: _rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 36,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                        itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppTheme.secondary),
                        onRatingUpdate: (r) => setState(() => _rating = r),
                      ),
                      if (_rating > 0) ...[
                        const SizedBox(height: 8),
                        Text(_ratingLabel(_rating.round()),
                          style: const TextStyle(fontSize: 12, color: AppTheme.outline, fontStyle: FontStyle.italic)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _isiCtrl,
                    minLines: 4, maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Isi Saran',
                      hintText: 'Tuliskan saran atau kesan Anda...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.edit_note_rounded, color: AppTheme.primary)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Isi saran tidak boleh kosong';
                      if (v.trim().length < 10) return 'Saran minimal 10 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _loadingKirim ? null : _kirimSaran,
                      icon: _loadingKirim
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_loadingKirim ? 'Mengirim...' : 'Kirim Saran'),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
