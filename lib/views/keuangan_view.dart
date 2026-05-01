import 'package:flutter/material.dart';
import '../controllers/keuangan_controller.dart';
import '../controllers/currency_controller.dart';
import '../models/keuangan_model.dart';
import '../models/currency_model.dart';
import '../theme/app_theme.dart';
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

  // Konversi state (card manual)
  final TextEditingController _nominalCtrl = TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _hasilKonversi = 0.0;

  // Refresh key
  int _refreshKey = 0;

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

  void _refreshData() {
    setState(() => _refreshKey++);
  }

  String formatRupiah(int angka) {
    String hasil = angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return "Rp $hasil";
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

    // Konversi otomatis di form
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tambah Transaksi',
                            style: TextStyle(
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

                      // Jenis transaksi toggle
                      const Text(
                        'Jenis Transaksi',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedTipe = 'pemasukan'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedTipe == 'pemasukan'
                                      ? Colors.green
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      color: selectedTipe == 'pemasukan'
                                          ? Colors.white
                                          : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pemasukan',
                                      style: TextStyle(
                                        color: selectedTipe == 'pemasukan'
                                            ? Colors.white
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedTipe == 'pengeluaran'
                                      ? Colors.red
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      color: selectedTipe == 'pengeluaran'
                                          ? Colors.white
                                          : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pengeluaran',
                                      style: TextStyle(
                                        color: selectedTipe == 'pengeluaran'
                                            ? Colors.white
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Keterangan
                      TextFormField(
                        controller: namaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Keterangan',
                          hintText: 'Iuran bulanan anggota',
                          prefixIcon: const Icon(Icons.description, color: AppTheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Keterangan wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Nominal
                      TextFormField(
                        controller: nominalFormCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Nominal (Rp)',
                          hintText: '0',
                          prefixIcon: const Icon(Icons.money, color: AppTheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                        onChanged: (val) => hitungKonversiForm(val, setModalState),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                          final n = int.tryParse(v);
                          if (n == null || n <= 0) return 'Nominal harus lebih dari 0';
                          return null;
                        },
                      ),

                      // Konversi otomatis
                      if (_currencyRates != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '≈ ${usdVal.toStringAsFixed(2)} USD  |  ${sarVal.toStringAsFixed(2)} SAR  |  ${eurVal.toStringAsFixed(2)} EUR',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Tanggal
                      GestureDetector(
                        onTap: () async {
                          final initial = DateTime.tryParse(tanggalCtrl.text) ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: initial,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: AppTheme.primary),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModalState(() => tanggalCtrl.text = _formatTanggal(picked));
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: tanggalCtrl,
                            decoration: InputDecoration(
                              labelText: 'Tanggal',
                              prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Tanggal wajib dipilih' : null,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'SIMPAN TRANSAKSI',
                                  style: TextStyle(
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

  Future<void> _konfirmasiHapus(KeuanganModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: Text('Yakin ingin menghapus transaksi "${item.keterangan}"?'),
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
      final res = await _keuanganCtrl.deleteKeuangan(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']),
            backgroundColor: res['success'] ? Colors.green : Colors.red,
          ),
        );
        if (res['success']) _refreshData();
      }
    }
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _bukaFormTransaksi,
        tooltip: 'Tambah Transaksi',
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
            return const Center(child: Text("Gagal memuat data keuangan."));
          }

          var data = snapshot.data!;
          List<KeuanganModel> riwayat = data['data'];

          return ListView(
            children: [
              // ── KARTU SALDO UTAMA ──────────────────────────────────
              Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withAlpha(230),
                      AppTheme.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Total Saldo Kas Masjid",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatRupiah(data['saldo']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pemasukan",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              formatRupiah(data['pemasukan']),
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Pengeluaran",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              formatRupiah(data['pengeluaran']),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── WIDGET KONVERSI MATA UANG (dipertahankan) ─────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.currency_exchange, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Konversi Mata Uang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (_) => _hitungKonversi(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                value: _fromCurrency,
                                isExpanded: true,
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
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward, color: AppTheme.primary),
                            ),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _toCurrency,
                                isExpanded: true,
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
                        const SizedBox(height: 10),
                        if (_loadingRates)
                          const Text('Memuat kurs...', style: TextStyle(color: Colors.grey))
                        else if (_currencyRates == null)
                          const Text('Kurs tidak tersedia', style: TextStyle(color: Colors.red))
                        else
                          Text(
                            'Hasil: ${_formatHasil(_hasilKonversi, _toCurrency)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const KonversiView()),
                              );
                            },
                            icon: const Icon(Icons.open_in_new, color: AppTheme.primary),
                            label: const Text(
                              'Konversi Lengkap',
                              style: TextStyle(color: AppTheme.primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── JUDUL RIWAYAT TRANSAKSI ────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Riwayat Transaksi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // ── LIST TRANSAKSI ─────────────────────────────────────
              if (riwayat.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'Belum ada transaksi.\nTap + untuk menambah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...riwayat.map((item) {
                  bool isPemasukan = item.jenis.toLowerCase() == 'pemasukan';
                  return Dismissible(
                    key: Key('keuangan_${item.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white, size: 28),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus Transaksi'),
                          content: Text(
                            'Yakin ingin menghapus transaksi "${item.keterangan}"?',
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
                    },
                    onDismissed: (_) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final res = await _keuanganCtrl.deleteKeuangan(item.id);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(res['message']),
                            backgroundColor: res['success'] ? Colors.green : Colors.red,
                          ),
                        );
                        _refreshData();
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPemasukan
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isPemasukan ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          item.keterangan,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(item.tanggal),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (isPemasukan ? "+ " : "- ") + formatRupiah(item.nominal),
                              style: TextStyle(
                                color: isPemasukan ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _konfirmasiHapus(item),
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}


