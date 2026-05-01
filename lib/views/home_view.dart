import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Views (Halaman)
import 'beranda_view.dart';
import 'keuangan_view.dart';
import 'catatan_view.dart'; // Import halaman baru
import 'profil_view.dart';
import 'auth/login_view.dart';

// Import Controller
import '../controllers/auth_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final AuthController _authController = AuthController();
  bool _isLoggedIn = false;

  // Daftar halaman yang akan ditampilkan di body
  final List<Widget> _pages = [
    const BerandaView(), // Index 0
    const KeuanganView(), // Index 1
    const CatatanView(), // Index 2 (Halaman Baru)
    const ProfilView(), // Index 3
  ];

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  // Fungsi mengecek status login admin di memori HP
  Future<void> _loadSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getString('id_member') != null;
    });
  }

  // Fungsi saat tombol navigasi bawah diklik
  void _onTap(int index) async {
    // Tombol terakhir (Index 4) adalah Login/Logout
    if (index == 4) {
      if (_isLoggedIn) {
        _showLogoutDialog();
      } else {
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

  // Popup konfirmasi logout
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
              // Reset aplikasi ke mode User/Tamu
              // ignore: use_build_context_synchronously
              Navigator.pushAndRemoveUntil(
                // ignore: use_build_context_synchronously
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

      // Menampilkan halaman sesuai index aktif
      body: _pages[_currentIndex],

      // Menu Navigasi Bawah
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed, // Menampilkan lebih dari 3 menu
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
            icon: Icon(Icons.notes),
            activeIcon: Icon(Icons.notes),
            label: "Catatan",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profil",
          ),
          BottomNavigationBarItem(
            icon: Icon(_isLoggedIn ? Icons.logout : Icons.login),
            label: _isLoggedIn ? "Logout" : "Login Admin",
          ),
        ],
      ),
    );
  }
}
