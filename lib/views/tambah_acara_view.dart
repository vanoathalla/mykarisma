import 'package:flutter/material.dart';
import '../controllers/acara_controller.dart';
import '../models/acara_model.dart';
import '../theme/app_theme.dart';

class TambahAcaraView extends StatefulWidget {
  final AcaraModel? acaraEdit;

  const TambahAcaraView({super.key, this.acaraEdit});

  @override
  State<TambahAcaraView> createState() => _TambahAcaraViewState();
}

class _TambahAcaraViewState extends State<TambahAcaraView> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();
  final _waktuCtrl = TextEditingController();

  String? _selectedKategori;
  String? _selectedTipe;
  TimeOfDay? _selectedTime;

  // Konversi zona waktu
  String _wib = '';
  String _wita = '';
  String _wit = '';
  String _london = '';

  final List<String> _kategoriOptions = ['Umum', 'Internal', 'Sosial', 'Keagamaan'];
  final List<String> _tipeOptions = ['Wajib', 'Sunnah', 'Opsional'];

  final AcaraController _acaraCtrl = AcaraController();
  bool _isLoading = false;

  bool get _isEditMode => widget.acaraEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final a = widget.acaraEdit!;
      _namaCtrl.text = a.nama;
      // Pisahkan tanggal dan waktu jika ada
      if (a.tanggal.contains(' ')) {
        final parts = a.tanggal.split(' ');
        _tanggalCtrl.text = parts[0];
        _waktuCtrl.text = parts[1];
        final timeParts = parts[1].split(':');
        if (timeParts.length >= 2) {
          _selectedTime = TimeOfDay(
            hour: int.tryParse(timeParts[0]) ?? 0,
            minute: int.tryParse(timeParts[1]) ?? 0,
          );
          _hitungKonversiWaktu(_selectedTime!);
        }
      } else {
        _tanggalCtrl.text = a.tanggal;
      }
      _selectedKategori = a.kategori;
      _selectedTipe = a.tipe;
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _tanggalCtrl.dispose();
    _waktuCtrl.dispose();
    super.dispose();
  }

  void _hitungKonversiWaktu(TimeOfDay time) {
    // WIB = UTC+7, WITA = UTC+8, WIT = UTC+9, London = UTC+0 (atau UTC+1 BST)
    final wibHour = time.hour;
    final witaHour = (time.hour + 1) % 24;
    final witHour = (time.hour + 2) % 24;
    // London = WIB - 7 jam
    final londonHour = (time.hour - 7 + 24) % 24;

    String fmt(int h, int m) =>
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

    setState(() {
      _wib = fmt(wibHour, time.minute);
      _wita = fmt(witaHour, time.minute);
      _wit = fmt(witHour, time.minute);
      _london = fmt(londonHour, time.minute);
    });
  }

  String _formatTanggalWaktu() {
    if (_waktuCtrl.text.isNotEmpty) {
      return '${_tanggalCtrl.text} ${_waktuCtrl.text}';
    }
    return _tanggalCtrl.text;
  }

  void _simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final tanggalFinal = _formatTanggalWaktu();

    Map<String, dynamic> res;
    if (_isEditMode) {
      res = await _acaraCtrl.updateAcara(
        widget.acaraEdit!.idAcara,
        _namaCtrl.text.trim(),
        tanggalFinal,
        _selectedKategori ?? '',
        _selectedTipe ?? '',
      );
    } else {
      res = await _acaraCtrl.tambahAcara(
        _namaCtrl.text.trim(),
        tanggalFinal,
        _selectedKategori ?? '',
        _selectedTipe ?? '',
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']),
        backgroundColor: res['success'] ? Colors.green : Colors.red,
      ),
    );

    if (res['success']) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Acara' : 'Tambah Acara Baru'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Nama Acara ──────────────────────────────────────────
                TextFormField(
                  controller: _namaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Acara',
                    prefixIcon: const Icon(Icons.event, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama acara wajib diisi' : null,
                ),
                const SizedBox(height: 15),

                // ── Tanggal (DatePicker) ────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final initial = DateTime.tryParse(_tanggalCtrl.text) ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _tanggalCtrl.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _tanggalCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Tanggal wajib dipilih' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // ── Waktu Acara (TimePicker) ────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime ?? TimeOfDay.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedTime = picked;
                        _waktuCtrl.text =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        _hitungKonversiWaktu(picked);
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _waktuCtrl,
                      decoration: InputDecoration(
                        labelText: 'Waktu Acara (opsional)',
                        hintText: 'Pilih waktu',
                        prefixIcon: const Icon(Icons.access_time, color: AppTheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Konversi Zona Waktu ─────────────────────────────────
                if (_selectedTime != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Konversi Zona Waktu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'WIB: $_wib  |  WITA: $_wita  |  WIT: $_wit  |  London: $_london',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 15),

                // ── Kategori (Dropdown) ─────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _selectedKategori,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: const Icon(Icons.category, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                  items: _kategoriOptions
                      .map((k) => DropdownMenuItem<String>(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedKategori = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Kategori wajib dipilih' : null,
                ),
                const SizedBox(height: 15),

                // ── Tipe (Dropdown) ─────────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _selectedTipe,
                  decoration: InputDecoration(
                    labelText: 'Tipe',
                    prefixIcon: const Icon(Icons.label, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                  items: _tipeOptions
                      .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTipe = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Tipe wajib dipilih' : null,
                ),
                const SizedBox(height: 30),

                // ── Tombol Simpan ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _simpanData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isEditMode ? 'PERBARUI ACARA' : 'SIMPAN ACARA',
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
      ),
    );
  }
}

