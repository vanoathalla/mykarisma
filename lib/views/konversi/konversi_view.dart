import 'package:flutter/material.dart';
import '../../controllers/currency_controller.dart';
import '../../models/currency_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class KonversiView extends StatefulWidget {
  const KonversiView({super.key});

  @override
  State<KonversiView> createState() => _KonversiViewState();
}

class _KonversiViewState extends State<KonversiView> {
  final CurrencyController _currencyCtrl = CurrencyController();

  CurrencyModel? _rates;
  bool _loadingRates = true;

  final TextEditingController _nominalCtrl = TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _hasilKonversi = 0.0;

  final TextEditingController _waktuCtrl = TextEditingController();
  String _fromZone = 'WIB';
  String _toZone = 'London';
  String _hasilWaktu = '';
  String _bedaHari = '';

  static const Map<String, int> _zoneOffset = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() => _loadingRates = true);
    final rates = await _currencyCtrl.fetchRates();
    if (mounted) {
      setState(() {
        _rates = rates;
        _loadingRates = false;
      });
    }
  }

  void _hitungKonversi() {
    if (_rates == null) return;
    final nominal = double.tryParse(_nominalCtrl.text) ?? 0.0;
    final hasil = _currencyCtrl.convert(nominal, _fromCurrency, _toCurrency, _rates!);
    setState(() => _hasilKonversi = hasil);
  }

  void _swapCurrency() {
    setState(() {
      final tmp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = tmp;
    });
    _hitungKonversi();
  }

  void _hitungWaktu() {
    final input = _waktuCtrl.text.trim();
    if (input.isEmpty) {
      setState(() {
        _hasilWaktu = '';
        _bedaHari = '';
      });
      return;
    }

    final parts = input.split(':');
    if (parts.length != 2) {
      setState(() {
        _hasilWaktu = 'Format tidak valid (HH:mm)';
        _bedaHari = '';
      });
      return;
    }

    final jam = int.tryParse(parts[0]);
    final menit = int.tryParse(parts[1]);

    if (jam == null || menit == null || jam < 0 || jam > 23 || menit < 0 || menit > 59) {
      setState(() {
        _hasilWaktu = 'Waktu tidak valid';
        _bedaHari = '';
      });
      return;
    }

    final fromOffset = _zoneOffset[_fromZone] ?? 0;
    final toOffset = _zoneOffset[_toZone] ?? 0;

    int totalMenitUTC = jam * 60 + menit - fromOffset * 60;
    int totalMenitTujuan = totalMenitUTC + toOffset * 60;

    int bedaHari = 0;
    if (totalMenitTujuan < 0) {
      bedaHari = -1;
      totalMenitTujuan += 24 * 60;
    } else if (totalMenitTujuan >= 24 * 60) {
      bedaHari = 1;
      totalMenitTujuan -= 24 * 60;
    }

    final jamHasil = totalMenitTujuan ~/ 60;
    final menitHasil = totalMenitTujuan % 60;

    setState(() {
      _hasilWaktu =
          '${jamHasil.toString().padLeft(2, '0')}:${menitHasil.toString().padLeft(2, '0')} $_toZone';
      _bedaHari = bedaHari == 1
          ? '+1 hari'
          : bedaHari == -1
              ? '-1 hari'
              : '';
    });
  }

  String _formatHasil(double nilai, String currency) {
    if (currency == 'IDR') {
      return 'Rp ${nilai.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    }
    return '${nilai.toStringAsFixed(4)} $currency';
  }

  String _formatTanggal(DateTime dt) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _waktuCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // '"-'"- App Bar '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.onSurface, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Konversi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                onPressed: _fetchRates,
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // '"-'"- Mata Uang '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                SectionHeader(title: 'Konversi Mata Uang'),
                const SizedBox(height: 14),
                SurfaceCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nominalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nominal',
                          hintText: 'Masukkan jumlah',
                          prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.primary),
                        ),
                        onChanged: (_) => _hitungKonversi(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _fromCurrency,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: CurrencyController.supportedCurrencies
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _fromCurrency = val);
                                  _hitungKonversi();
                                }
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: _swapCurrency,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.swap_horiz_rounded,
                                  color: AppTheme.primary, size: 20),
                            ),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _toCurrency,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: CurrencyController.supportedCurrencies
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _toCurrency = val);
                                  _hitungKonversi();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_loadingRates)
                        const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primary, strokeWidth: 2),
                        )
                      else if (_rates == null)
                        const Text(
                          'Kurs tidak tersedia, periksa koneksi internet',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatHasil(_hasilKonversi, _toCurrency),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kurs: ${_formatTanggal(_rates!.lastUpdated)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // '"-'"- Zona Waktu '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                SectionHeader(title: 'Konversi Zona Waktu'),
                const SizedBox(height: 14),
                SurfaceCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _waktuCtrl,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Waktu (HH:mm)',
                          hintText: 'Contoh: 14:30',
                          prefixIcon: Icon(Icons.access_time_rounded,
                              color: AppTheme.primary),
                        ),
                        onChanged: (_) => _hitungWaktu(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _fromZone,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: _zoneOffset.keys
                                  .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _fromZone = val);
                                  _hitungWaktu();
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: AppTheme.primary, size: 20),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _toZone,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: _zoneOffset.keys
                                  .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _toZone = val);
                                  _hitungWaktu();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_hasilWaktu.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _hasilWaktu,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  if (_bedaHari.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    CategoryBadge(
                                      label: _bedaHari,
                                      color: _bedaHari.startsWith('+')
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.blue.withValues(alpha: 0.1),
                                      textColor: _bedaHari.startsWith('+')
                                          ? Colors.orange.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'UTC${_zoneOffset[_fromZone]! >= 0 ? '+' : ''}${_zoneOffset[_fromZone]} -> UTC${_zoneOffset[_toZone]! >= 0 ? '+' : ''}${_zoneOffset[_toZone]}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'Masukkan waktu untuk melihat hasil konversi',
                          style: const TextStyle(
                            color: AppTheme.outline,
                            fontSize: 13,
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
}
