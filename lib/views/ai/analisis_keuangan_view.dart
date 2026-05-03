import 'package:flutter/material.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/keuangan_controller.dart';
import '../../models/keuangan_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AnalisisKeuanganView extends StatefulWidget {
  const AnalisisKeuanganView({super.key});

  @override
  State<AnalisisKeuanganView> createState() => _AnalisisKeuanganViewState();
}

class _AnalisisKeuanganViewState extends State<AnalisisKeuanganView> {
  String _analisis = '';
  bool _loading = false;
  final KeuanganController _keuanganCtrl = KeuanganController();

  @override
  void initState() {
    super.initState();
    _loadAnalisis();
  }

  Future<void> _loadAnalisis() async {
    setState(() => _loading = true);

    try {
      final result = await _keuanganCtrl.fetchKeuangan();
      final List<KeuanganModel> transactions =
          (result['data'] as List<KeuanganModel>?) ?? [];

      final analisis = await AIController().analyzeFinance(transactions);

      if (mounted) {
        setState(() {
          _analisis = analisis;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analisis = 'Gagal memuat analisis. Silakan coba lagi.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analisis Keuangan AI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: _loadAnalisis,
            tooltip: 'Refresh analisis',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'AI sedang menganalisis...',
                    style: TextStyle(color: AppTheme.outline),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AiMeshCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Insight',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Analisis keuangan berbasis AI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SurfaceCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(20),
                    child: Text(
                      _analisis.isEmpty ? 'Belum ada analisis' : _analisis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
