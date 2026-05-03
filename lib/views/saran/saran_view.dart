import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../helpers/database_helper.dart';
import '../../models/feedback_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../home/home_view.dart';

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
  bool _loading = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
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

    final errorMsg = model.validate();
    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
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
            backgroundColor: Colors.green,
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 20,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.onSurface, size: 20),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  // Dari navbar â€” kembali ke Beranda
                  homeTabNotifier.switchTo(1);
                }
              },
            ),
            title: const Text(
              'Saran & Kesan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // â”€â”€ Header Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                AiMeshCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.feedback_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Berikan Saran & Kesan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Masukan Anda sangat berarti untuk kemajuan KARISMA.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // â”€â”€ Form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama
                      TextFormField(
                        controller: _namaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama (opsional)',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Rating
                      SizedBox(
                        width: double.infinity,
                        child: SurfaceCard(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rating',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              RatingBar.builder(
                                initialRating: _rating,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: false,
                                itemCount: 5,
                                itemSize: 36,
                                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                                itemBuilder: (context, _) => const Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.secondary,
                                ),
                                onRatingUpdate: (rating) {
                                  setState(() => _rating = rating);
                                },
                              ),
                              if (_rating > 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _getRatingLabel(_rating.round()),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.outline,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Isi Saran
                      TextFormField(
                        controller: _isiCtrl,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Isi Saran',
                          hintText: 'Tuliskan saran atau kesan Anda...',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.edit_note_rounded, color: AppTheme.primary),
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
                      const SizedBox(height: 28),

                      // Tombol Kirim
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _kirimSaran,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(_loading ? 'Mengirim...' : 'Kirim Saran'),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Kurang';
      case 2:
        return 'Kurang';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return '';
    }
  }
}
