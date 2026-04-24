import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Views (Halaman)
import 'beranda_view.dart';
import 'keuangan_view.dart';
import 'login_view.dart';

// Import Controller
import '../controllers/auth_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // 1. Variabel untuk mengontrol navigasi
  int _currentIndex = 0;
  final AuthController _authController = AuthController();
  String _namaUser = "";

  // 2. Daftar halaman yang akan ditampilkan di body
  // Urutannya harus sama dengan urutan di BottomNavigationBar
  final List<Widget> _pages = [
    const BerandaView(), // Index 0
    const KeuanganView(), // Index 1
    const Center(
      child: Text("Halaman Profil", style: TextStyle(fontSize: 20)),
    ), // Index 2 (Placeholder)
  ];

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  // Fungsi untuk ambil nama user agar bisa muncul di AppBar (opsional)
  Future<void> _loadSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaUser = prefs.getString('nama') ?? 'User';
    });
  }

  // 3. Fungsi saat tombol navigasi diklik
  void _onTap(int index) async {
    // Jika yang diklik adalah tombol Logout (Index 3)
    if (index == 3) {
      _showLogoutDialog();
    } else {
      // Jika yang diklik menu biasa, ganti halaman
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Fungsi popup konfirmasi logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await _authController.logout();
              if (!mounted) return;
              // Pindah ke halaman login dan hapus semua tumpukan halaman sebelumnya
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar khas Karisma
      appBar: AppBar(
        title: const Text(
          "KARISMA MOBILE",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      // Body menampilkan halaman sesuai index yang aktif
      body: _pages[_currentIndex],

      // Bottom Navigation Bar (Menu Bawah)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType
            .fixed, // WAJIB: agar lebih dari 3 menu tidak putih/hilang
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: "Keuangan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profil",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }
}
