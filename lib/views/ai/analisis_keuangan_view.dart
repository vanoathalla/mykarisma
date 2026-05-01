import 'package:flutter/material.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/keuangan_controller.dart';
import '../../models/keuangan_model.dart';
import '../../theme/app_theme.dart';

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
      appBar: AppBar(
        title: const Text('Analisis Keuangan AI'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalisis,
            tooltip: 'Refresh analisis',
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'AI sedang menganalisis...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.secondary),
                      const SizedBox(width: 8),
                      const Text(
                        'Insight AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _analisis.isEmpty ? 'Belum ada analisis' : _analisis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
