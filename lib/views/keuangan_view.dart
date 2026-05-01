import 'package:flutter/material.dart';
import '../controllers/keuangan_controller.dart';
import '../controllers/currency_controller.dart';
import '../helpers/auth_helper.dart';
import '../models/keuangan_model.dart';
import '../models/currency_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'konversi/konversi_view.dart';

class KeuanganView extends StatefulWidget {
  const KeuanganView({super.key});

  @override
  State<KeuanganView> createState() => _KeuanganViewState();
}

class _KeuanganViewState extends State<KeuanganView> {
  final KeuanganController _keuanganCtrl = KeuanganController();
  final CurrencyController _currencyCtrl = CurrencyController();

  CurrencyModel? _currencyRates;
  bool _loadingRates = true;

  final TextEditingController _nominalCtrl = TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _hasilKonversi = 0.0;

  int _refreshKey = 0;
  String _roleUser = 'tamu'; // default tamu

  @override
  void initState() {
    super.initState();
    _fetchRates();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final session = await AuthHelper.getActiveSession();
    if (mounted) {
      setState(() => _roleUser = session?['role'] ?? 'tamu');
    }
  }

  Future<void> _fetchRates() async {
    setState(() => _loadingRates = true);
    final rates = await _currencyCtrl.fetchRates();
    if (mounted) {
      setState(() {
        _currencyRates = rates;
        _loadingRates = false;
      });
    }
  }

  void _hitungKonversi() {
    if (_currencyRates == null) return;
    final nominal = double.tryParse(_nominalCtrl.text) ?? 0.0;
    final hasil = _currencyCtrl.convert(nominal, _fromCurrency, _toCurrency, _currencyRates!);
    setState(() => _hasilKonversi = hasil);
  }

  void _refreshData() => setState(() => _refreshKey++);

  String formatRupiah(int angka) {
    final str = angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  String _formatHasil(double nilai, String currency) {
    if (currency == 'IDR') {
      return 'Rp ${nilai.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    }
    return '${nilai.toStringAsFixed(2)} $currency';
  }

  String _formatTanggal(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _bukaFormTransaksi() {
    final formKey = GlobalKey<FormState>();
    String selectedTipe = 'pemasukan';
    final namaCtrl = TextEditingController();
    final nominalFormCtrl = TextEditingController();
    final tanggalCtrl = TextEditingController(text: _formatTanggal(DateTime.now()));
    bool isSaving = false;

    double usdVal = 0, sarVal = 0, eurVal = 0;

    void hitungKonversiForm(String val, StateSetter setModalState) {
      if (_currencyRates == null) return;
      final nominal = double.tryParse(val) ?? 0.0;
      setModalState(() {
        usdVal = _currencyCtrl.convert(nominal, 'IDR', 'USD', _currencyRates!);
        sarVal = _currencyCtrl.convert(nominal, 'IDR', 'SAR', _currencyRates!);
        eurVal = _currencyCtrl.convert(nominal, 'IDR', 'EUR', _currencyRates!);
      });
    }

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
                          const Text(
                            'Tambah Transaksi',
                            style: TextStyle(
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

                      // Jenis transaksi toggle
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedTipe = 'pemasukan'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedTipe == 'pemasukan'
                                      ? Colors.green
                                      : AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      color: selectedTipe == 'pemasukan'
                                          ? Colors.white
                                          : AppTheme.outline,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pemasukan',
                                      style: TextStyle(
                                        color: selectedTipe == 'pemasukan'
                                            ? Colors.white
                                            : AppTheme.outline,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedTipe = 'pengeluaran'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedTipe == 'pengeluaran'
                                      ? Colors.red
                                      : AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      color: selectedTipe == 'pengeluaran'
                                          ? Colors.white
                                          : AppTheme.outline,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pengeluaran',
                                      style: TextStyle(
                                        color: selectedTipe == 'pengeluaran'
                                            ? Colors.white
                                            : AppTheme.outline,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: namaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                          hintText: 'Iuran bulanan anggota',
                          prefixIcon: Icon(Icons.description_outlined, color: AppTheme.primary),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Keterangan wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: nominalFormCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nominal (Rp)',
                          hintText: '0',
                          prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.primary),
                        ),
                        onChanged: (val) => hitungKonversiForm(val, setModalState),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                          final n = int.tryParse(v);
                          if (n == null || n <= 0) return 'Nominal harus lebih dari 0';
                          return null;
                        },
                      ),

                      if (_currencyRates != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '≈ ${usdVal.toStringAsFixed(2)} USD  ·  ${sarVal.toStringAsFixed(2)} SAR  ·  ${eurVal.toStringAsFixed(2)} EUR',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () async {
                          final initial = DateTime.tryParse(tanggalCtrl.text) ?? DateTime.now();
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
                                  final res = await _keuanganCtrl.insertKeuangan(
                                    selectedTipe,
                                    namaCtrl.text,
                                    tanggalCtrl.text,
                                    int.tryParse(nominalFormCtrl.text) ?? 0,
                                  );
                                  setModalState(() => isSaving = false);
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(res['message']),
                                      backgroundColor:
                                          res['success'] ? Colors.green : Colors.red,
                                    ),
                                  );
                                  if (res['success']) _refreshData();
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
                              : const Text('SIMPAN TRANSAKSI'),
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

  @override
  void dispose() {
    _nominalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_refreshKey),
        future: _keuanganCtrl.fetchKeuangan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          if (!snapshot.hasData || snapshot.data!['success'] == false) {
            return const Center(child: Text('Gagal memuat data keuangan.'));
          }

          final data = snapshot.data!;
          final List<KeuanganModel> riwayat = data['data'];

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                titleSpacing: 20,
                title: const Text(
                  'Keuangan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                    onPressed: () {
                      _fetchRates();
                      _refreshData();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Saldo Card ──────────────────────────────────────
                    AiMeshCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Saldo Kas',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatRupiah(data['saldo']),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSaldoItem(
                                    label: 'Pemasukan',
                                    value: formatRupiah(data['pemasukan']),
                                    icon: Icons.arrow_downward_rounded,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                Expanded(
                                  child: _buildSaldoItem(
                                    label: 'Pengeluaran',
                                    value: formatRupiah(data['pengeluaran']),
                                    icon: Icons.arrow_upward_rounded,
                                    color: Colors.redAccent.shade100,
                                    align: CrossAxisAlignment.end,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Konversi Card ───────────────────────────────────
                    SurfaceCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.currency_exchange_rounded,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Konversi Mata Uang',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nominalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Nominal',
                              hintText: 'Masukkan jumlah',
                            ),
                            onChanged: (_) => _hitungKonversi(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _fromCurrency,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded,
                                    color: AppTheme.primary, size: 20),
                              ),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _toCurrency,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          const SizedBox(height: 12),
                          if (_loadingRates)
                            const Text('Memuat kurs...', style: TextStyle(color: AppTheme.outline))
                          else if (_currencyRates == null)
                            const Text('Kurs tidak tersedia', style: TextStyle(color: Colors.red))
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Hasil: ${_formatHasil(_hasilKonversi, _toCurrency)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const KonversiView()),
                              ),
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: const Text('Konversi Lengkap'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Riwayat Transaksi ───────────────────────────────
                    SectionHeader(title: 'Riwayat Transaksi'),
                    const SizedBox(height: 14),

                    if (riwayat.isEmpty)
                      SurfaceCard(
                        padding: const EdgeInsets.all(32),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 48, color: AppTheme.outline),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada transaksi',
                                style: TextStyle(
                                  color: AppTheme.outline,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...riwayat.map((item) {
                        final isPemasukan = item.jenis.toLowerCase() == 'pemasukan';
                        return Dismissible(
                          key: Key('keuangan_${item.id}'),
                          // Hanya admin yang bisa swipe hapus
                          direction: _roleUser == 'admin'
                              ? DismissDirection.endToStart
                              : DismissDirection.none,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 10),
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
                                title: const Text('Hapus Transaksi'),
                                content: Text(
                                    'Yakin ingin menghapus "${item.keterangan}"?'),
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
                            final res = await _keuanganCtrl.deleteKeuangan(item.id);
                            if (mounted) {
                              messenger.showSnackBar(SnackBar(
                                content: Text(res['message']),
                                backgroundColor:
                                    res['success'] ? Colors.green : Colors.red,
                              ));
                              _refreshData();
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isPemasukan
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isPemasukan
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: isPemasukan ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item.keterangan,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                item.tanggal,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.outline,
                                ),
                              ),
                              trailing: Text(
                                formatRupiah(item.nominal),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isPemasukan ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _roleUser == 'admin'
          ? FloatingActionButton(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onPressed: _bukaFormTransaksi,
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }

  Widget _buildSaldoItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: align == CrossAxisAlignment.end
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
