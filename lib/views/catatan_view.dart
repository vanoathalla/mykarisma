import 'package:flutter/material.dart';
import '../controllers/catatan_controller.dart';
import '../controllers/acara_controller.dart';
import '../models/catatan_model.dart';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCatatan();
    _loadDaftarAcara();
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
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            catatan == null
                                ? 'Tambah Notulensi'
                                : 'Edit Notulensi',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Judul notulensi
                      TextFormField(
                        controller: judulCtrl,
                        decoration: InputDecoration(
                          labelText: 'Judul Notulensi',
                          hintText: 'Notulensi Rapat Bulanan Maret 2025',
                          prefixIcon: const Icon(
                            Icons.title,
                            color: AppTheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Judul wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Nama acara terkait
                      Autocomplete<String>(
                        initialValue:
                            TextEditingValue(text: catatan?.acara ?? ''),
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _daftarAcara;
                          }
                          return _daftarAcara.where(
                            (a) => a.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                ),
                          );
                        },
                        onSelected: (val) => acaraCtrl.text = val,
                        fieldViewBuilder: (
                          context,
                          fieldController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          // Sync controller
                          if (acaraCtrl.text.isNotEmpty &&
                              fieldController.text.isEmpty) {
                            fieldController.text = acaraCtrl.text;
                          }
                          fieldController.addListener(() {
                            acaraCtrl.text = fieldController.text;
                          });
                          return TextFormField(
                            controller: fieldController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Nama Acara Terkait',
                              hintText: 'Pilih atau ketik nama acara',
                              prefixIcon: const Icon(
                                Icons.event,
                                color: AppTheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppTheme.primary),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Isi notulensi
                      TextFormField(
                        controller: isiCtrl,
                        maxLines: null,
                        minLines: 5,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: 'Isi Notulensi',
                          hintText: 'Tulis isi notulensi rapat di sini...',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(
                              Icons.notes,
                              color: AppTheme.primary,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Isi notulensi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Tanggal
                      GestureDetector(
                        onTap: () async {
                          final initial = DateTime.tryParse(tanggalCtrl.text) ??
                              DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: initial,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primary,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModalState(() {
                              tanggalCtrl.text = _formatTanggal(picked);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: tanggalCtrl,
                            decoration: InputDecoration(
                              labelText: 'Tanggal',
                              prefixIcon: const Icon(
                                Icons.calendar_today,
                                color: AppTheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Tanggal wajib dipilih'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tombol simpan
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSaving = true);

                                  // Capture messenger before async gap
                                  final messenger =
                                      ScaffoldMessenger.of(context);

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

                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(res['message']),
                                      backgroundColor: res['success']
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );

                                  if (res['success']) _loadCatatan();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  catatan == null
                                      ? 'SIMPAN NOTULENSI'
                                      : 'PERBARUI NOTULENSI',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
        content: Text(
          'Yakin ingin menghapus notulensi "${catatan.judul}"?',
        ),
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
        messenger.showSnackBar(
          SnackBar(
            content: Text(res['message']),
            backgroundColor: res['success'] ? Colors.green : Colors.red,
          ),
        );
        if (res['success']) _loadCatatan();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catatan & Notulensi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _bukaFormCatatan(),
        tooltip: 'Tambah Notulensi',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari catatan...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // ── KONTEN ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _filteredCatatan.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'Tidak ada catatan yang cocok'
                              : 'Belum ada catatan.\nTap + untuk menambah notulensi.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 80),
                        itemCount: _filteredCatatan.length,
                        itemBuilder: (context, i) {
                          final item = _filteredCatatan[i];
                          return Dismissible(
                            key: Key('catatan_${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Catatan'),
                                  content: Text(
                                    'Yakin ingin menghapus notulensi "${item.judul}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              return confirm ?? false;
                            },
                            onDismissed: (_) async {
                              final messenger = ScaffoldMessenger.of(context);
                              final res =
                                  await _catatanCtrl.deleteCatatan(item.id);
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message']),
                                    backgroundColor: res['success']
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                                _loadCatatan();
                              }
                            },
                            child: GestureDetector(
                              onTap: () => _bukaFormCatatan(catatan: item),
                              child: Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.judul,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item.tanggal,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () =>
                                                    _bukaFormCatatan(
                                                      catatan: item,
                                                    ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () =>
                                                    _konfirmasiHapus(item),
                                                child: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Acara: ${item.acara}',
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Divider(),
                                      Text(
                                        item.isi,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
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
    );
  }
}
