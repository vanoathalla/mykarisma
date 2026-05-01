import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORT HALAMAN BARU
import 'member_view.dart';
import 'peta_view.dart';
// import 'dokumentasi_view.dart'; // Nanti di-uncomment kalau file dokumentasi sudah kamu buat

class ProfilView extends StatefulWidget {
  const ProfilView({super.key});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  String _namaLengkap = "Memuat...";
  String _role = "Memuat...";
  String _idMember = "-";

  @override
  void initState() {
    super.initState();
    _loadDataProfil();
  }

  Future<void> _loadDataProfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaLengkap = prefs.getString('nama') ?? 'Tamu Karisma';
      _role = prefs.getString('role') ?? 'Tamu';
      _idMember = prefs.getString('id_member') ?? '-';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // HEADER PROFIL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, bottom: 30),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 60, color: Colors.teal),
                ),
                const SizedBox(height: 15),
                Text(
                  _namaLengkap.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Role: ${_role.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // MENU APLIKASI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Menu Utama",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge, color: Colors.teal),
                        title: const Text("ID Member Anda"),
                        trailing: Text(
                          "#$_idMember",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(height: 0),

                      // TOMBOL MEMBER
                      ListTile(
                        leading: const Icon(
                          Icons.people_alt,
                          color: Colors.teal,
                        ),
                        title: const Text("Daftar Pengurus & Member"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MemberView(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 0),

                      // TOMBOL DOKUMENTASI (Pastikan file dokumentasi_view.dart sudah ada)
                      ListTile(
                        leading: const Icon(
                          Icons.photo_library,
                          color: Colors.teal,
                        ),
                        title: const Text("Dokumentasi Kegiatan"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => const DokumentasiView()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Fitur Dokumentasi menyusul"),
                            ),
                          );
                        },
                      ),

                      // TOMBOL PETA
                      ListTile(
                        leading: const Icon(Icons.map, color: Colors.teal),
                        title: const Text("Lokasi Masjid"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PetaView(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  "Lainnya",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(
                          Icons.settings_outlined,
                          color: Colors.teal,
                        ),
                        title: Text("Pengaturan Akun"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                      const Divider(height: 0),
                      const ListTile(
                        leading: Icon(Icons.help_outline, color: Colors.teal),
                        title: Text("Bantuan & Dukungan"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
