import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../helpers/database_helper.dart';
import '../../models/feedback_model.dart';
import '../../theme/app_theme.dart';

class SaranView extends StatefulWidget {
  const SaranView({super.key});

  @override
  State<SaranView> createState() => _SaranViewState();
}

class _SaranViewState extends State<SaranView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaCtrl = TextEditingController();
  final TextEditingController _isiCtrl = TextEditingController();

  double _rating = 0;
  String? _kategori;
  bool _loading = false;

  static const List<String> _kategoriList = [
    'Materi',
    'Pengajar',
    'Tugas',
    'Lainnya',
  ];

  @override
  void dispose() {
    _namaCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  Future<void> _kirimSaran() async {
    // Validasi form Flutter
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Buat model sementara untuk validasi domain
    final model = FeedbackModel(
      nama: _namaCtrl.text.trim().isEmpty ? null : _namaCtrl.text.trim(),
      rating: _rating.round(),
      kategori: _kategori ?? '',
      isi: _isiCtrl.text.trim(),
      tanggal: DateTime.now().toIso8601String().split('T').first,
    );

    final errorMsg = model.validate();
    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await DatabaseHelper.instance.insertFeedback(model.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saran berhasil dikirim. Terima kasih!'),
            backgroundColor: AppTheme.primary,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan saran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _namaCtrl.clear();
    _isiCtrl.clear();
    setState(() {
      _rating = 0;
      _kategori = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saran & Kesan'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Berikan Saran & Kesan Anda',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masukan Anda sangat berarti untuk kemajuan KARISMA.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // ── Nama (opsional) ──────────────────────────────────────────
              TextFormField(
                controller: _namaCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama (opsional)',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppTheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Rating ───────────────────────────────────────────────────
              const Text(
                'Rating',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: AppTheme.secondary,
                ),
                onRatingUpdate: (rating) {
                  setState(() => _rating = rating);
                },
              ),
              const SizedBox(height: 20),

              // ── Kategori ─────────────────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _kategori,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(
                    Icons.category_outlined,
                    color: AppTheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
                hint: const Text('Pilih kategori'),
                items: _kategoriList
                    .map(
                      (k) => DropdownMenuItem(value: k, child: Text(k)),
                    )
                    .toList(),
                validator: (val) =>
                    val == null ? 'Silakan pilih kategori' : null,
                onChanged: (val) => setState(() => _kategori = val),
              ),
              const SizedBox(height: 20),

              // ── Isi Saran ────────────────────────────────────────────────
              TextFormField(
                controller: _isiCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Isi Saran',
                  hintText: 'Tuliskan saran atau kesan Anda...',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(
                      Icons.edit_note,
                      color: AppTheme.primary,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Isi saran tidak boleh kosong';
                  }
                  if (val.trim().length < 10) {
                    return 'Saran minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // ── Tombol Kirim ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _kirimSaran,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _loading ? 'Mengirim...' : 'Kirim Saran',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
