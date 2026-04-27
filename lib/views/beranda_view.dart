import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/acara_controller.dart';
import '../models/acara_model.dart';
import 'tambah_acara_view.dart'; // Import halaman form

class BerandaView extends StatefulWidget {
  const BerandaView({super.key});

  @override
  State<BerandaView> createState() => _BerandaViewState();
}

class _BerandaViewState extends State<BerandaView> {
  final AcaraController _acaraCtrl = AcaraController();

  // Nilai default untuk Tamu (belum login)
  String _namaUser = "Tamu Karisma";
  String _roleUser = "tamu";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaUser = prefs.getString('nama') ?? 'Tamu Karisma';
      _roleUser = prefs.getString('role') ?? 'tamu';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // LOGIKA TOMBOL (+): Hanya muncul kalau role adalah 'admin'
      floatingActionButton: _roleUser == 'admin'
          ? FloatingActionButton(
              onPressed: () async {
                // Buka halaman tambah acara dan tunggu proses kembalinya
                bool? refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TambahAcaraView(),
                  ),
                );

                // Jika kembali membawa status true (sukses), muat ulang tabel acara
                if (refresh == true) {
                  setState(() {});
                }
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ahlan wa Sahlan,",
                  style: TextStyle(color: Colors.teal.shade100, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  _namaUser.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Role: ${_roleUser.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Jadwal Acara Karisma",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // List Acara
          Expanded(
            child: FutureBuilder<List<AcaraModel>>(
              future: _acaraCtrl.fetchAcara(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada jadwal acara."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, i) {
                    var item = snapshot.data![i];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.event, color: Colors.white),
                        ),
                        title: Text(
                          item.nama,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${item.tanggal}\n${item.kategori} (${item.tipe})",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
