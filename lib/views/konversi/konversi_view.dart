import 'package:flutter/material.dart';
import '../../controllers/currency_controller.dart';
import '../../models/currency_model.dart';
import '../../theme/app_theme.dart';

class KonversiView extends StatefulWidget {
  const KonversiView({super.key});

  @override
  State<KonversiView> createState() => _KonversiViewState();
}

class _KonversiViewState extends State<KonversiView> {
  final CurrencyController _currencyCtrl = CurrencyController();

  // ── Konversi Mata Uang ─────────────────────────────────────────────────────
  CurrencyModel? _rates;
  bool _loadingRates = true;

  final TextEditingController _nominalCtrl = TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _hasilKonversi = 0.0;

  // ── Konversi Zona Waktu ────────────────────────────────────────────────────
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

    // Konversi ke UTC lalu ke zona tujuan
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
      appBar: AppBar(
        title: const Text('Konversi'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SECTION 1: Konversi Mata Uang ──────────────────────────────
            _buildSectionHeader(
              icon: Icons.currency_exchange,
              title: 'Konversi Mata Uang',
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input nominal
                    TextFormField(
                      controller: _nominalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nominal',
                        hintText: 'Masukkan jumlah',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                      onChanged: (_) => _hitungKonversi(),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown dari + swap + ke
                    Row(
                      children: [
                        Expanded(
                          child: _buildCurrencyDropdown(
                            value: _fromCurrency,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _fromCurrency = val);
                                _hitungKonversi();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: _swapCurrency,
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: AppTheme.primary,
                          ),
                          tooltip: 'Tukar',
                        ),
                        Expanded(
                          child: _buildCurrencyDropdown(
                            value: _toCurrency,
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

                    // Hasil konversi
                    if (_loadingRates)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2,
                        ),
                      )
                    else if (_rates == null)
                      const Text(
                        'Kurs tidak tersedia, periksa koneksi internet',
                        style: TextStyle(color: Colors.red),
                      )
                    else ...[
                      Text(
                        _formatHasil(_hasilKonversi, _toCurrency),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kurs terakhir diperbarui: ${_formatTanggal(_rates!.lastUpdated)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── SECTION 2: Konversi Zona Waktu ─────────────────────────────
            _buildSectionHeader(
              icon: Icons.access_time,
              title: 'Konversi Zona Waktu',
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input waktu
                    TextFormField(
                      controller: _waktuCtrl,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: 'Waktu (HH:mm)',
                        hintText: 'Contoh: 14:30',
                        prefixIcon: const Icon(
                          Icons.access_time,
                          color: AppTheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                      onChanged: (_) => _hitungWaktu(),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown zona asal → zona tujuan
                    Row(
                      children: [
                        Expanded(
                          child: _buildZoneDropdown(
                            value: _fromZone,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _fromZone = val);
                                _hitungWaktu();
                              }
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            color: AppTheme.primary,
                          ),
                        ),
                        Expanded(
                          child: _buildZoneDropdown(
                            value: _toZone,
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

                    // Hasil konversi waktu
                    if (_hasilWaktu.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _hasilWaktu,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          if (_bedaHari.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _bedaHari.startsWith('+')
                                    ? Colors.orange.shade100
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _bedaHari,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _bedaHari.startsWith('+')
                                      ? Colors.orange.shade800
                                      : Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UTC${_zoneOffset[_fromZone]! >= 0 ? '+' : ''}${_zoneOffset[_fromZone]} → UTC${_zoneOffset[_toZone]! >= 0 ? '+' : ''}${_zoneOffset[_toZone]}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ] else
                      const Text(
                        'Masukkan waktu untuk melihat hasil konversi',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: CurrencyController.supportedCurrencies
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildZoneDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _zoneOffset.keys
          .map((z) => DropdownMenuItem(value: z, child: Text(z)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
