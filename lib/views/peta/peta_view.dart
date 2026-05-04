import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';
import '../../helpers/database_helper.dart';
import '../../models/landmark_model.dart';
import '../../theme/app_theme.dart';

class PetaView extends StatefulWidget {
  const PetaView({super.key});

  @override
  State<PetaView> createState() => _PetaViewState();
}

class _PetaViewState extends State<PetaView> {
  // Koordinat tujuan  Kemiri Sewu, Sidorejo, Godean, Sleman
  static const LatLng _lokasiTujuan = LatLng(-7.7473727, 110.2731459);
  static const String _namaTujuan = 'Sekretariat KARISMA';
  static const String _deskripsiTujuan = 'Sidorejo, Kec. Godean, Sleman, Yogyakarta';

  final MapController _mapController = MapController();
  List<LandmarkModel> _landmarks = [];
  bool _isAdmin = false;
  bool _loading = true;

  LatLng? _lokasiUser;
  bool _loadingLokasi = false;

  // Rute navigasi
  List<LatLng> _rutePoints = [];
  bool _loadingRute = false;
  bool _ruteAktif = false;
  String _infoRute = '';

  final _namaCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _namaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final session = await AuthHelper.getActiveSession();
    if (mounted) setState(() => _isAdmin = session?['role'] == 'admin');
    await Future.wait([_loadLandmarks(), _getLokasiUser()]);
  }

  Future<void> _loadLandmarks() async {
    final rows = await DatabaseHelper.instance.getAllLandmarks();
    if (mounted) {
      setState(() {
        _landmarks = rows.map((r) => LandmarkModel.fromJson(r)).toList();
        _loading = false;
      });
    }
  }

  Future<void> _getLokasiUser() async {
    if (mounted) setState(() => _loadingLokasi = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingLokasi = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _lokasiUser = userLatLng;
        _loadingLokasi = false;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _mapController.move(userLatLng, 15);
    } catch (e) {
      if (mounted) setState(() => _loadingLokasi = false);
    }
  }

  //  Ambil rute dari OSRM (gratis, tanpa API key) 
  // OSRM adalah routing engine open-source yang dipakai OpenStreetMap.
  // Endpoint publik: router.project-osrm.org  tidak butuh key, tidak butuh kartu kredit.
  Future<void> _tampilkanRute(LatLng tujuan) async {
    if (_lokasiUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi Anda belum terdeteksi. Tap ikon lokasi dulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Jika rute sudah aktif ke tujuan yang sama, matikan
    if (_ruteAktif) {
      setState(() {
        _rutePoints = [];
        _ruteAktif = false;
        _infoRute = '';
      });
      return;
    }

    setState(() => _loadingRute = true);

    try {
      // Format: /route/v1/driving/{lon1},{lat1};{lon2},{lat2}
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_lokasiUser!.longitude},${_lokasiUser!.latitude};'
        '${tujuan.longitude},${tujuan.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List;

          // OSRM mengembalikan [lon, lat]  kita balik ke LatLng(lat, lon)
          final points = coords
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();

          // Info jarak & durasi
          final distanceM = (route['distance'] as num).toDouble();
          final durationS = (route['duration'] as num).toDouble();
          final distStr = distanceM < 1000
              ? '${distanceM.toStringAsFixed(0)} m'
              : '${(distanceM / 1000).toStringAsFixed(1)} km';
          final durStr = durationS < 60
              ? '${durationS.toStringAsFixed(0)} detik'
              : '${(durationS / 60).toStringAsFixed(0)} menit';

          if (mounted) {
            setState(() {
              _rutePoints = points;
              _ruteAktif = true;
              _infoRute = '$distStr  $durStr berkendara';
              _loadingRute = false;
            });

            // Fit kamera agar seluruh rute terlihat
            if (points.isNotEmpty) {
              final bounds = LatLngBounds.fromPoints(points);
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(60),
                ),
              );
            }
          }
          return;
        }
      }

      // Gagal ambil rute
      if (mounted) {
        setState(() => _loadingRute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengambil rute. Periksa koneksi internet.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _hitungJarak(LatLng tujuan) {
    if (_lokasiUser == null) return '';
    final dist = Geolocator.distanceBetween(
      _lokasiUser!.latitude, _lokasiUser!.longitude,
      tujuan.latitude, tujuan.longitude,
    );
    return dist < 1000
        ? '${dist.toStringAsFixed(0)} m'
        : '${(dist / 1000).toStringAsFixed(1)} km';
  }

  void _showLokasiDetail({
    required String nama,
    required String deskripsi,
    required LatLng lokasi,
    bool isMain = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF889390) : AppTheme.outline;
    final jarak = _hitungJarak(lokasi);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isMain ? Icons.mosque_rounded : Icons.place_rounded,
                    color: AppTheme.primary, size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary)),
                      if (deskripsi.isNotEmpty)
                        Text(deskripsi, style: TextStyle(fontSize: 12, color: textSub)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.my_location_rounded, size: 14, color: textSub),
                const SizedBox(width: 6),
                Text(
                  '${lokasi.latitude.toStringAsFixed(6)}, ${lokasi.longitude.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 12, color: textSub),
                ),
                if (jarak.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(jarak, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                icon: Icon(
                  _ruteAktif ? Icons.close_rounded : Icons.directions_rounded,
                  size: 18,
                ),
                label: Text(_ruteAktif ? 'Sembunyikan Rute' : 'Tampilkan Rute di Peta'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _tampilkanRute(lokasi);
                },
              ),
            ),
            if (_isAdmin && !isMain) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  label: const Text('Hapus Landmark', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final lm = _landmarks.firstWhere(
                      (l) => l.latitude == lokasi.latitude && l.longitude == lokasi.longitude,
                      orElse: () => LandmarkModel(nama: '', latitude: 0, longitude: 0),
                    );
                    if (lm.idLandmark != null) {
                      final db = await DatabaseHelper.instance.database;
                      await db.delete('landmark', where: 'id_landmark = ?', whereArgs: [lm.idLandmark]);
                      await _loadLandmarks();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Landmark dihapus'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddLandmarkDialog() {
    _namaCtrl.clear(); _deskripsiCtrl.clear(); _latCtrl.clear(); _lonCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Landmark'),
        content: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama Landmark', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _deskripsiCtrl, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              // Latitude dengan tombol +/-
              _CoordField(
                controller: _latCtrl,
                label: 'Latitude',
                hint: '-7.747372',
              ),
              const SizedBox(height: 12),
              // Longitude dengan tombol +/-
              _CoordField(
                controller: _lonCtrl,
                label: 'Longitude',
                hint: '110.273145',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final nama = _namaCtrl.text.trim();
              final lat = double.tryParse(_latCtrl.text.trim());
              final lon = double.tryParse(_lonCtrl.text.trim());
              if (nama.isEmpty || lat == null || lon == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama, latitude, dan longitude wajib diisi')),
                );
                return;
              }
              final lm = LandmarkModel(
                nama: nama, latitude: lat, longitude: lon,
                deskripsi: _deskripsiCtrl.text.trim().isEmpty ? null : _deskripsiCtrl.text.trim(),
              );
              await DatabaseHelper.instance.insertLandmark(lm.toMap());
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadLandmarks();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Landmark berhasil ditambahkan'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;

    final markers = <Marker>[
      // Marker tujuan (masjid)
      Marker(
        point: _lokasiTujuan,
        width: 60, height: 60,
        child: GestureDetector(
          onTap: () => _showLokasiDetail(
            nama: _namaTujuan, deskripsi: _deskripsiTujuan,
            lokasi: _lokasiTujuan, isMain: true,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                child: const Text('KARISMA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
              ),
              const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 36),
            ],
          ),
        ),
      ),
      // Marker user
      if (_lokasiUser != null)
        Marker(
          point: _lokasiUser!,
          width: 44, height: 44,
          child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(' Lokasi Anda saat ini'), duration: Duration(seconds: 2)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.25), shape: BoxShape.circle),
                ),
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: Colors.blue, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 6)],
                  ),
                ),
              ],
            ),
          ),
        ),
      // Landmarks dari DB
      ..._landmarks.map((lm) => Marker(
        point: LatLng(lm.latitude, lm.longitude),
        width: 40, height: 40,
        child: GestureDetector(
          onTap: () => _showLokasiDetail(
            nama: lm.nama, deskripsi: lm.deskripsi ?? '',
            lokasi: LatLng(lm.latitude, lm.longitude),
          ),
          child: const Icon(Icons.place_rounded, color: Colors.orange, size: 40),
        ),
      )),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1C1C) : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1A1C1C).withValues(alpha: 0.95)
            : AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Peta Lokasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
        actions: [
          IconButton(
            icon: _loadingLokasi
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                : const Icon(Icons.my_location_rounded, color: AppTheme.primary),
            onPressed: _loadingLokasi ? null : _getLokasiUser,
            tooltip: 'Ke lokasi saya',
          ),
          IconButton(
            icon: const Icon(Icons.mosque_rounded, color: AppTheme.primary),
            onPressed: () => _mapController.move(_lokasiTujuan, 16),
            tooltip: 'Ke Sekretariat',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
        ),
      ),
      body: Stack(
        children: [
          //  Peta 
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _lokasiTujuan,
                    initialZoom: 15,
                    minZoom: 3,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.project',
                      maxZoom: 19,
                      fallbackUrl: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    // Garis rute
                    if (_rutePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _rutePoints,
                            strokeWidth: 5,
                            color: AppTheme.primary,
                            borderStrokeWidth: 2,
                            borderColor: Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    MarkerLayer(markers: markers, rotate: false),
                    const RichAttributionWidget(
                      attributions: [TextSourceAttribution(' OpenStreetMap contributors')],
                    ),
                  ],
                ),

          //  Info rute (muncul saat rute aktif) 
          if (_ruteAktif && _infoRute.isNotEmpty)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _infoRute,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() { _rutePoints = []; _ruteAktif = false; _infoRute = ''; }),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),

          //  Bottom card 
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.mosque_rounded, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_namaTujuan, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                        Text(
                          _lokasiUser != null
                              ? 'Jarak: ${_hitungJarak(_lokasiTujuan)}'
                              : _deskripsiTujuan,
                          style: TextStyle(
                            fontSize: 11,
                            color: _lokasiUser != null ? AppTheme.primary : (isDark ? const Color(0xFF889390) : AppTheme.outline),
                            fontWeight: _lokasiUser != null ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol navigasi  tampilkan rute di peta
                  GestureDetector(
                    onTap: _loadingRute ? null : () => _tampilkanRute(_lokasiTujuan),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _ruteAktif ? Colors.orange : AppTheme.primary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: _loadingRute
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_ruteAktif ? Icons.close_rounded : Icons.directions_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _ruteAktif ? 'Tutup' : 'Rute',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          //  Loading lokasi indicator 
          if (_loadingLokasi)
            Positioned(
              top: 12, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                      SizedBox(width: 8),
                      Text('Mencari lokasi Anda...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onPressed: _showAddLandmarkDialog,
              tooltip: 'Tambah Landmark',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}

//  Coordinate Input Field dengan tombol +/- 
/// Keyboard tipe angka mengikuti pengaturan HP (decimal/signed otomatis).
/// Tombol + dan - untuk increment/decrement nilai koordinat.
class _CoordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _CoordField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  void _adjust(double delta) {
    final current = double.tryParse(controller.text) ?? 0.0;
    final newVal = (current + delta);
    controller.text = newVal.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Tombol minus
        _AdjustBtn(
          icon: Icons.remove_rounded,
          onTap: () => _adjust(-0.001),
        ),
        const SizedBox(width: 8),
        // Input field
        Expanded(
          child: TextField(
            controller: controller,
            // Keyboard tipe angka  tampilan keyboard tergantung HP
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Tombol plus
        _AdjustBtn(
          icon: Icons.add_rounded,
          onTap: () => _adjust(0.001),
        ),
      ],
    );
  }
}

class _AdjustBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AdjustBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.20),
          ),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
    );
  }
}

//  Coordinate Input Field dengan tombol +/- 
// Keyboard tipe angka mengikuti pengaturan HP (decimal/signed otomatis)
