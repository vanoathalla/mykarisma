import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur Copy to Clipboard
import '../controllers/dokumentasi_controller.dart';
import '../models/dokumentasi_model.dart';

class DokumentasiView extends StatefulWidget {
  const DokumentasiView({super.key});

  @override
  State<DokumentasiView> createState() => _DokumentasiViewState();
}

class _DokumentasiViewState extends State<DokumentasiView> {
  final DokumentasiController _dokCtrl = DokumentasiController();

  // Fungsi untuk menyalin link ke clipboard HP
  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Link berhasil disalin!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dokumentasi Kegiatan",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<DokumentasiModel>>(
        future: _dokCtrl.fetchDokumentasi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data dokumentasi."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              var item = snapshot.data![i];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.teal,
                            ),
                          ),
                          Text(
                            item.tanggal,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // SelectableText agar user bisa nge-blok tulisannya
                        child: SelectableText(
                          item.url,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _copyLink(item.url),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text("Salin Link"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade50,
                            foregroundColor: Colors.teal.shade800,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
