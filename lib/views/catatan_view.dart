import 'package:flutter/material.dart';
import '../controllers/catatan_controller.dart';
import '../controllers/acara_controller.dart';
import '../helpers/auth_helper.dart';
import '../models/catatan_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class CatatanView extends StatefulWidget {
  const CatatanView({super.key});

  @override
  State<CatatanView> createState() => _CatatanViewState();
}

class _CatatanViewState extends State<CatatanView> {
  final CatatanController _catatanCtrl = CatatanController();
  final AcaraController _acaraCtrl = AcaraController();

  List<CatatanModel> _allCatatan = [];
  List<CatatanModel> _filteredCatatan = [];
  List<String> _daftarAcara = [];
  String _searchQuery = '';
  bool _loading = true;
  String _roleUser = 'tamu';

  @override
  void initState() {
    super.initState();
    _loadCatatan();
    _loadDaftarAcara();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final session = await AuthHelper.getActiveSession();
    if (mounted) {
      setState(() => _roleUser = session?['role'] ?? 'tamu');
    }
  }

  Future<void> _loadCatatan() async {
    setState(() => _loading = true);
    final data = await _catatanCtrl.fetchCatatan();
    if (mounted) {
      setState(() {
        _allCatatan = data;
        _filteredCatatan = _searchQuery.isEmpty
            ? data
            : data.where((c) {
                final q = _searchQuery.toLowerCase();
                return c.judul.toLowerCase().contains(q) ||
                    c.isi.toLowerCase().contains(q);
              }).toList();
        _loading = false;
      });
    }
  }

  Future<void> _loadDaftarAcara() async {
    final acara = await _acaraCtrl.fetchAcara();
    if (mounted) {
      setState(() {
        _daftarAcara = acara.map((a) => a.nama).toList();
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCatatan = _allCatatan;
      } else {
        final q = query.toLowerCase();
        _filteredCatatan = _allCatatan.where((c) {
          return c.judul.toLowerCase().contains(q) ||
              c.isi.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  String _formatTanggal(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _bukaFormCatatan({CatatanModel? catatan}) {
    final formKey = GlobalKey<FormState>();
    final judulCtrl = TextEditingController(text: catatan?.judul ?? '');
    final acaraCtrl = TextEditingController(text: catatan?.acara ?? '');
    final isiCtrl = TextEditingController(text: catatan?.isi ?? '');
    final tanggalCtrl = TextEditingController(
      text: catatan?.tanggal ?? _formatTanggal(DateTime.now()),
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
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                            catatan == null ? 'Tambah Notulensi' : 'Edit Notulensi',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppTheme.outline),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: judulCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Judul Notulensi',
                          hintText: 'Notulensi Rapat Bulanan',
                          prefixIcon: Icon(Icons.title_rounded, color: AppTheme.primary),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: catatan?.acara ?? ''),
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return _daftarAcara;
                          return _daftarAcara.where(
                            (a) => a.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                ),
                          );
                        },
                        onSelected: (val) => acaraCtrl.text = val,
                        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                          if (acaraCtrl.text.isNotEmpty && fieldController.text.isEmpty) {
                            fieldController.text = acaraCtrl.text;
                          }
                          fieldController.addListener(() {
                            acaraCtrl.text = fieldController.text;
                          });
                          return TextFormField(
                            controller: fieldController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Nama Acara Terkait',
                              hintText: 'Pilih atau ketik nama acara',
                              prefixIcon: Icon(Icons.event_rounded, color: AppTheme.primary),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: isiCtrl,
                        maxLines: null,
                        minLines: 5,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'Isi Notulensi',
                          hintText: 'Tulis isi notulensi rapat di sini...',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.notes_rounded, color: AppTheme.primary),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Isi notulensi wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () async {
                          final initial =
                              DateTime.tryParse(tanggalCtrl.text) ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: initial,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() => tanggalCtrl.text = _formatTanggal(picked));
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: tanggalCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tanggal',
                              prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primary),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Tanggal wajib dipilih' : null,
                          ),
                        ),
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
                                  final messenger = ScaffoldMessenger.of(context);
                                  Map<String, dynamic> res;
                                  if (catatan == null) {
                                    res = await _catatanCtrl.insertCatatan(
                                      judulCtrl.text,
                                      acaraCtrl.text,
                                      isiCtrl.text,
                                      tanggalCtrl.text,
                                    );
                                  } else {
                                    res = await _catatanCtrl.updateCatatan(
                                      catatan.id,
                                      judulCtrl.text,
                                      acaraCtrl.text,
                                      isiCtrl.text,
                                      tanggalCtrl.text,
                                    );
                                  }
                                  setModalState(() => isSaving = false);
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  messenger.showSnackBar(SnackBar(
                                    content: Text(res['message']),
                                    backgroundColor:
                                        res['success'] ? Colors.green : Colors.red,
                                  ));
                                  if (res['success']) _loadCatatan();
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
                              : Text(catatan == null ? 'SIMPAN NOTULENSI' : 'PERBARUI NOTULENSI'),
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

  Future<void> _konfirmasiHapus(CatatanModel catatan) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Yakin ingin menghapus notulensi "${catatan.judul}"?'),
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

    if (confirm == true) {
      final res = await _catatanCtrl.deleteCatatan(catatan.id);
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(res['message']),
          backgroundColor: res['success'] ? Colors.green : Colors.red,
        ));
        if (res['success']) _loadCatatan();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── App Bar ────────────────────────────────────────────────────
          Container(
            color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      children: [
                        // Back button
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppTheme.onSurface, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Catatan & Notulensi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                          onPressed: _loadCatatan,
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: TextField(
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari catatan...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _filteredCatatan.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.sticky_note_2_outlined,
                              size: 56,
                              color: AppTheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada catatan yang cocok'
                                  : 'Belum ada catatan',
                              style: const TextStyle(
                                color: AppTheme.outline,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                        itemCount: _filteredCatatan.length,
                        itemBuilder: (context, i) {
                          final item = _filteredCatatan[i];
                          return Dismissible(
                            key: Key('catatan_${item.id}'),
                            direction: _roleUser == 'admin'
                                ? DismissDirection.endToStart
                                : DismissDirection.none,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Catatan'),
                                  content: Text(
                                      'Yakin ingin menghapus "${item.judul}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) async {
                              final messenger = ScaffoldMessenger.of(context);
                              final res = await _catatanCtrl.deleteCatatan(item.id);
                              if (mounted) {
                                messenger.showSnackBar(SnackBar(
                                  content: Text(res['message']),
                                  backgroundColor:
                                      res['success'] ? Colors.green : Colors.red,
                                ));
                                _loadCatatan();
                              }
                            },
                            child: GestureDetector(
                              // Tamu hanya bisa lihat, tidak bisa edit
                              onTap: _roleUser == 'admin'
                                  ? () => _bukaFormCatatan(catatan: item)
                                  : null,
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
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryContainer
                                                  .withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.history_edu_rounded,
                                              color: AppTheme.primaryContainer,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item.judul,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_roleUser == 'admin') ...[
                                                GestureDetector(
                                                  onTap: () => _bukaFormCatatan(catatan: item),
                                                  child: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                    color: AppTheme.outline,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () => _konfirmasiHapus(item),
                                                  child: const Icon(
                                                    Icons.delete_outline_rounded,
                                                    size: 18,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (item.acara.isNotEmpty)
                                        CategoryBadge(
                                          label: item.acara,
                                          color: AppTheme.secondary.withValues(alpha: 0.1),
                                          textColor: AppTheme.secondary,
                                        ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.isi,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.onSurfaceVariant,
                                          height: 1.5,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            item.tanggal,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.outline,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
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
        ],
      ),
      floatingActionButton: _roleUser == 'admin'
          ? FloatingActionButton(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onPressed: () => _bukaFormCatatan(),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}
