import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/dokumentasi_controller.dart';
import '../models/dokumentasi_model.dart';
import '../theme/app_theme.dart';

class DokumentasiView extends StatefulWidget {
  const DokumentasiView({super.key});

  @override
  State<DokumentasiView> createState() => _DokumentasiViewState();
}

class _DokumentasiViewState extends State<DokumentasiView> {
  final DokumentasiController _dokCtrl = DokumentasiController();

  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link berhasil disalin!')),
    );
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
                      height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<DokumentasiModel>>(
              future: _dokCtrl.fetchDokumentasi(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded,
                            size: 56, color: AppTheme.outline),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada data dokumentasi',
                          style: TextStyle(
                              color: AppTheme.outline, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, i) {
                    final item = snapshot.data![i];
                    return Container(
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
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SelectableText(
                                item.url,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _copyLink(item.url),
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text('Salin Link'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor:
                                      AppTheme.primary.withValues(alpha: 0.06),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
