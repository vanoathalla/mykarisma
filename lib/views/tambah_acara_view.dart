import 'package:flutter/material.dart';
import '../controllers/acara_controller.dart';
import '../models/acara_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

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
  final _lokasiCtrl = TextEditingController();

  String? _selectedKategori;
  TimeOfDay? _selectedTime;

  String _wib = '';
  String _wita = '';
  String _wit = '';
  String _london = '';

  final List<String> _kategoriOptions = ['Umum', 'Internal', 'Sosial', 'Keagamaan'];

  final AcaraController _acaraCtrl = AcaraController();
  bool _isLoading = false;

  bool get _isEditMode => widget.acaraEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final a = widget.acaraEdit!;
      _namaCtrl.text = a.nama;
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
      _lokasiCtrl.text = a.lokasi ?? '';
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _tanggalCtrl.dispose();
    _waktuCtrl.dispose();
    _lokasiCtrl.dispose();
    super.dispose();
  }

  void _hitungKonversiWaktu(TimeOfDay time) {
    final wibHour = time.hour;
    final witaHour = (time.hour + 1) % 24;
    final witHour = (time.hour + 2) % 24;
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
        _lokasiCtrl.text.trim(),
      );
    } else {
      res = await _acaraCtrl.tambahAcara(
        _namaCtrl.text.trim(),
        tanggalFinal,
        _selectedKategori ?? '',
        _lokasiCtrl.text.trim(),
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
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
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
            title: Text(
              _isEditMode ? 'Edit Acara' : 'Tambah Acara',
              style: const TextStyle(
                fontSize: 18,
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Acara
                      TextFormField(
                        controller: _namaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Acara',
                          prefixIcon: Icon(Icons.event_rounded, color: AppTheme.primary),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nama acara wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Tanggal
                      GestureDetector(
                        onTap: () async {
                          final initial =
                              DateTime.tryParse(_tanggalCtrl.text) ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
                            decoration: const InputDecoration(
                              labelText: 'Tanggal',
                              prefixIcon: Icon(Icons.calendar_today_outlined,
                                  color: AppTheme.primary),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Tanggal wajib dipilih' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Waktu
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
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
                            decoration: const InputDecoration(
                              labelText: 'Waktu Acara (opsional)',
                              hintText: 'Pilih waktu',
                              prefixIcon: Icon(Icons.access_time_rounded,
                                  color: AppTheme.primary),
                            ),
                          ),
                        ),
                      ),

                      // Konversi zona waktu
                      if (_selectedTime != null) ...[
                        const SizedBox(height: 10),
                        SurfaceCard(
                          padding: const EdgeInsets.all(14),
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primary.withValues(alpha: 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Konversi Zona Waktu',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildZoneChip('WIB', _wib),
                                  const SizedBox(width: 8),
                                  _buildZoneChip('WITA', _wita),
                                  const SizedBox(width: 8),
                                  _buildZoneChip('WIT', _wit),
                                  const SizedBox(width: 8),
                                  _buildZoneChip('LDN', _london),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Kategori
                      DropdownButtonFormField<String>(
                        initialValue: _selectedKategori,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primary),
                        ),
                        items: _kategoriOptions
                            .map((k) => DropdownMenuItem<String>(value: k, child: Text(k)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedKategori = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Kategori wajib dipilih' : null,
                      ),
                      const SizedBox(height: 14),

                      // Lokasi
                      TextFormField(
                        controller: _lokasiCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi Acara (opsional)',
                          hintText: 'Contoh: Masjid Al-Ikhlas, Balai Desa',
                          prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _simpanData,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isEditMode ? 'PERBARUI ACARA' : 'SIMPAN ACARA',
                                ),
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

  Widget _buildZoneChip(String zone, String time) {
    return Expanded(
      child: Column(
        children: [
          Text(
            zone,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.outline,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
