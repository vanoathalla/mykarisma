import 'package:flutter/material.dart';
import '../controllers/acara_controller.dart';

class TambahAcaraView extends StatefulWidget {
  const TambahAcaraView({super.key});

  @override
  State<TambahAcaraView> createState() => _TambahAcaraViewState();
}

class _TambahAcaraViewState extends State<TambahAcaraView> {
  final _namaCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();
  final _kategoriCtrl = TextEditingController();
  final _tipeCtrl = TextEditingController();

  final AcaraController _acaraCtrl = AcaraController();
  bool _isLoading = false;

  void _simpanData() async {
    if (_namaCtrl.text.isEmpty || _tanggalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama dan Tanggal wajib diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Memanggil Controller untuk proses ke API
    var res = await _acaraCtrl.tambahAcara(
      _namaCtrl.text,
      _tanggalCtrl.text,
      _kategoriCtrl.text,
      _tipeCtrl.text,
    );

    setState(() => _isLoading = false);

    if (res['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.green),
      );
      Navigator.pop(
        context,
        true,
      ); // Kembali ke beranda setelah sukses, membawa kode 'true'
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tambah Acara Baru",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: "Nama Acara (Misal: Rapat Rutin)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _tanggalCtrl,
                decoration: const InputDecoration(
                  labelText: "Tanggal (YYYY-MM-DD)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _kategoriCtrl,
                decoration: const InputDecoration(
                  labelText: "Kategori (Misal: Umum/Internal)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _tipeCtrl,
                decoration: const InputDecoration(
                  labelText: "Tipe (Misal: Wajib/Sunnah)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanData,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SIMPAN ACARA",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
