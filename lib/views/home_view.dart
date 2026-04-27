import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Views
import 'beranda_view.dart';
import 'keuangan_view.dart';
import 'profil_view.dart';
import 'login_view.dart';

import '../controllers/auth_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final AuthController _authController = AuthController();

  // Variabel untuk mendeteksi status login
  bool _isLoggedIn = false;

  final List<Widget> _pages = [
    const BerandaView(),
    const KeuanganView(),
    const ProfilView(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  // Fungsi mengecek apakah di memori HP ada data login admin
  Future<void> _loadSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Jika id_member tidak null, berarti ada admin yang sedang login
      _isLoggedIn = prefs.getString('id_member') != null;
    });
  }

  void _onTap(int index) async {
    // JIKA TOMBOL KE-4 (INDEX 3) DI-KLIK:
    if (index == 3) {
      if (_isLoggedIn) {
        // Kalau sudah login, tombol ini fungsinya Logout
        _showLogoutDialog();
      } else {
        // Kalau belum login (User biasa), tombol ini fungsinya mengarahkan ke halaman Login Admin
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari mode Admin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await _authController.logout();
              if (!mounted) return;
              // Setelah logout, refresh halaman Home ini jadi mode User biasa
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeView()),
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
      appBar: AppBar(
        title: const Text(
          "KARISMA MOBILE",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Beranda",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: "Keuangan",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profil",
          ),

          // TOMBOL KE-4 BERUBAH SECARA DINAMIS
          BottomNavigationBarItem(
            icon: Icon(
              _isLoggedIn ? Icons.logout : Icons.login,
            ), // Ikon berubah
            label: _isLoggedIn ? "Logout" : "Login Admin", // Teks berubah
          ),
        ],
      ),
    );
  }
}
