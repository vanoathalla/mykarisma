import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PetaView extends StatefulWidget {
  const PetaView({super.key});

  @override
  State<PetaView> createState() => _PetaViewState();
}

class _PetaViewState extends State<PetaView> {
  // Koordinat Masjid Karisma (Ganti koordinat sesuai lokasi asli)
  static const LatLng _lokasiMasjid = LatLng(-7.7828, 110.3676);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lokasi Masjid Karisma"),
        backgroundColor: Colors.teal,
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _lokasiMasjid,
          zoom: 15,
        ),
        markers: {
          const Marker(
            markerId: MarkerId('masjid_karisma'),
            position: _lokasiMasjid,
            infoWindow: InfoWindow(title: 'Masjid Karisma'),
          ),
        },
      ),
    );
  }
}
