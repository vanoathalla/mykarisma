import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  static const LatLng _lokasiMasjid = LatLng(-7.7828, 110.3676);

  Set<Marker> _markers = {};
  bool _isAdmin = false;

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
    _namaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final session = await AuthHelper.getActiveSession();
    if (mounted) {
      setState(() {
        _isAdmin = session?['role'] == 'admin';
      });
    }
    await _loadLandmarks();
  }

  Future<void> _loadLandmarks() async {
    final rows = await DatabaseHelper.instance.getAllLandmarks();
    final landmarks = rows.map((r) => LandmarkModel.fromJson(r)).toList();

    final Set<Marker> markers = {
      const Marker(
        markerId: MarkerId('masjid_karisma'),
        position: _lokasiMasjid,
        infoWindow: InfoWindow(title: 'Masjid Karisma'),
      ),
    };

    for (final lm in landmarks) {
      markers.add(
        Marker(
          markerId: MarkerId('landmark_${lm.idLandmark ?? lm.nama}'),
          position: LatLng(lm.latitude, lm.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          onTap: () => _showLandmarkDetail(lm),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  void _showLandmarkDetail(LandmarkModel lm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.place, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lm.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (lm.deskripsi != null && lm.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                lm.deskripsi!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Koordinat: ${lm.latitude.toStringAsFixed(6)}, ${lm.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Petunjuk Arah'),
                onPressed: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=${lm.latitude},${lm.longitude}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Tidak dapat membuka Google Maps'),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
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
                    content: Text(
                      'Nama, latitude, dan longitude wajib diisi dengan benar',
                    ),
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
          'Peta Lokasi',
          style: TextStyle(
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
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _lokasiMasjid,
          zoom: 15,
        ),
        markers: _markers,
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              onPressed: _showAddLandmarkDialog,
              tooltip: 'Tambah Landmark',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}
