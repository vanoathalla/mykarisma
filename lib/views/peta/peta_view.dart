import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
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
  // Koordinat default — wilayah Karisma (bisa disesuaikan)
  static const LatLng _lokasiDefault = LatLng(-7.7828, 110.3676);

  final MapController _mapController = MapController();
  List<LandmarkModel> _landmarks = [];
  bool _isAdmin = false;
  bool _loading = true;

  // Controllers for add-landmark dialog
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
    if (mounted) {
      setState(() => _isAdmin = session?['role'] == 'admin');
    }
    await _loadLandmarks();
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

  void _showLandmarkDetail(LandmarkModel lm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252828) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final textSub = isDark ? const Color(0xFF889390) : AppTheme.outline;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  child: const Icon(Icons.place_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lm.nama,
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (lm.deskripsi != null && lm.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(lm.deskripsi!, style: TextStyle(fontSize: 14, color: textSub, height: 1.5)),
            ],
            const SizedBox(height: 8),
            Text(
              'Koordinat: ${lm.latitude.toStringAsFixed(6)}, ${lm.longitude.toStringAsFixed(6)}',
              style: TextStyle(fontSize: 12, color: textSub),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Petunjuk Arah'),
                onPressed: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=${lm.latitude},${lm.longitude}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Tidak dapat membuka aplikasi peta')),
                    );
                  }
                },
              ),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  label: const Text('Hapus Landmark', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (lm.idLandmark != null) {
                      final db = await DatabaseHelper.instance.database;
                      await db.delete('landmarks',
                          where: 'id_landmark = ?', whereArgs: [lm.idLandmark]);
                      await _loadLandmarks();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Landmark dihapus'),
                            backgroundColor: Colors.green,
                          ),
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
    _namaCtrl.clear();
    _deskripsiCtrl.clear();
    _latCtrl.clear();
    _lonCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Landmark'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Landmark',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deskripsiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _latCtrl,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final nama = _namaCtrl.text.trim();
              final lat = double.tryParse(_latCtrl.text.trim());
              final lon = double.tryParse(_lonCtrl.text.trim());

              if (nama.isEmpty || lat == null || lon == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama, latitude, dan longitude wajib diisi dengan benar'),
                  ),
                );
                return;
              }

              final lm = LandmarkModel(
                nama: nama,
                latitude: lat,
                longitude: lon,
                deskripsi: _deskripsiCtrl.text.trim().isEmpty
                    ? null
                    : _deskripsiCtrl.text.trim(),
              );

              await DatabaseHelper.instance.insertLandmark(lm.toMap());
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadLandmarks();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Landmark berhasil ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
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

    // Semua marker: default + landmarks dari DB
    final markers = <Marker>[
      // Marker utama (lokasi Karisma)
      Marker(
        point: _lokasiDefault,
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: isDark ? const Color(0xFF252828) : Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (ctx) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const Row(
                      children: [
                        Icon(Icons.home_rounded, color: AppTheme.primary, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Lokasi Karisma',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Koordinat: ${_lokasiDefault.latitude.toStringAsFixed(6)}, ${_lokasiDefault.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.outline),
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 48),
        ),
      ),
      // Landmark dari database
      ..._landmarks.map((lm) => Marker(
        point: LatLng(lm.latitude, lm.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showLandmarkDetail(lm),
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
        title: Text(
          'Peta Lokasi',
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _lokasiDefault,
          initialZoom: 15,
          minZoom: 3,
          maxZoom: 19,
          // Aktifkan semua interaksi: zoom, pan, rotate, tap
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // OpenStreetMap tile layer (gratis, tidak perlu API key)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.project',
            maxZoom: 19,
            // Fallback tile saat offline
            fallbackUrl: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          // Markers
          MarkerLayer(
            markers: markers,
            rotate: false,
          ),
          // Attribution OSM
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
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
