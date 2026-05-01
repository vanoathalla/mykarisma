import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/dokumentasi_controller.dart';
import '../helpers/auth_helper.dart';
import '../models/dokumentasi_model.dart';
import '../theme/app_theme.dart';

class DokumentasiView extends StatefulWidget {
  const DokumentasiView({super.key});

  @override
  State<DokumentasiView> createState() => _DokumentasiViewState();
}

class _DokumentasiViewState extends State<DokumentasiView> {
  final DokumentasiController _dokCtrl = DokumentasiController();

  List<DokumentasiModel> _list = [];
  bool _isLoading = true;
  String _roleUser = 'tamu';

  bool get _isAdmin => _roleUser == 'admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final session = await AuthHelper.getActiveSession();
    if (mounted) {
      setState(() => _roleUser = session?['role'] ?? 'tamu');
    }
    final data = await _dokCtrl.fetchDokumentasi();
    if (mounted) {
      setState(() {
        _list = data;
        _isLoading = false;
      });
    }
  }

  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link berhasil disalin!')),
    );
  }

  String _formatTanggal(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _bukaForm({DokumentasiModel? item}) {
    final isEdit = item != null;
    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController(text: item?.nama ?? '');
    final urlCtrl = TextEditingController(text: item?.url ?? '');
    final tanggalCtrl = TextEditingController(
      text: item?.tanggal ?? _formatTanggal(DateTime.now()),
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit Dokumentasi' : 'Tambah Dokumentasi',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppTheme.outline),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nama Kegiatan
                      TextFormField(
                        controller: namaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Kegiatan',
                          hintText: 'Contoh: Kajian Rutin Maret 2025',
                          prefixIcon: Icon(Icons.folder_rounded,
                              color: AppTheme.primary),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama kegiatan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Tanggal
                      GestureDetector(
                        onTap: () async {
                          final initial =
                              DateTime.tryParse(tanggalCtrl.text) ??
                                  DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: initial,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() =>
                                tanggalCtrl.text = _formatTanggal(picked));
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: tanggalCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tanggal',
                              prefixIcon: Icon(Icons.calendar_today_outlined,
                                  color: AppTheme.primary),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Tanggal wajib dipilih'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Link Google Drive / Foto
                      TextFormField(
                        controller: urlCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Link Google Drive / Foto',
                          hintText: 'https://drive.google.com/...',
                          prefixIcon: Icon(Icons.link_rounded,
                              color: AppTheme.primary),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Link wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSaving = true);
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final Map<String, dynamic> res;
                                  if (isEdit) {
                                    res = await _dokCtrl.updateDokumentasi(
                                      item.id,
                                      namaCtrl.text,
                                      urlCtrl.text,
                                      tanggalCtrl.text,
                                    );
                                  } else {
                                    res = await _dokCtrl.insertDokumentasi(
                                      namaCtrl.text,
                                      urlCtrl.text,
                                      tanggalCtrl.text,
                                    );
                                  }
                                  setModalState(() => isSaving = false);
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  messenger.showSnackBar(SnackBar(
                                    content: Text(res['message']),
                                    backgroundColor: res['success']
                                        ? Colors.green
                                        : Colors.red,
                                  ));
                                  if (res['success']) _loadData();
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(isEdit
                                  ? 'SIMPAN PERUBAHAN'
                                  : 'SIMPAN DOKUMENTASI'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _hapus(DokumentasiModel item) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumentasi'),
        content: Text('Yakin ingin menghapus "${item.nama}"?'),
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
    if (konfirmasi != true) return;
    final res = await _dokCtrl.deleteDokumentasi(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']),
        backgroundColor: res['success'] ? Colors.green : Colors.red,
      ));
      if (res['success']) _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────
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
                            'Dokumentasi Kegiatan',
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
                  Container(
                    height: 1,
                    color: AppTheme.primary.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open_rounded,
                                size: 56, color: AppTheme.outline),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada data dokumentasi',
                              style: TextStyle(
                                  color: AppTheme.outline, fontSize: 14),
                            ),
                            if (_isAdmin) ...[
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => _bukaForm(),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Tambah Dokumentasi'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 100),
                          itemCount: _list.length,
                          itemBuilder: (context, i) {
                            final item = _list[i];
                            return _buildCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              onPressed: () => _bukaForm(),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }

  Widget _buildCard(DokumentasiModel item) {
    return Dismissible(
      key: Key('dok_${item.id}'),
      direction: _isAdmin
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Dokumentasi'),
            content: Text('Yakin ingin menghapus "${item.nama}"?'),
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
      },
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final res = await _dokCtrl.deleteDokumentasi(item.id);
        if (mounted) {
          messenger.showSnackBar(SnackBar(
            content: Text(res['message']),
            backgroundColor: res['success'] ? Colors.green : Colors.red,
          ));
          if (res['success']) _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ikon folder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          item.tanggal,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol admin
                  if (_isAdmin)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _bukaForm(item: item),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 16, color: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _hapus(item),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Link
              GestureDetector(
                onTap: () => _copyLink(item.url),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.url,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy_rounded,
                          size: 14, color: AppTheme.primary),
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
