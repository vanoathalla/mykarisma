import 'package:flutter/material.dart';
import '../controllers/keuangan_controller.dart';
import '../models/keuangan_model.dart';

class KeuanganView extends StatefulWidget {
  const KeuanganView({super.key});

  @override
  State<KeuanganView> createState() => _KeuanganViewState();
}

class _KeuanganViewState extends State<KeuanganView> {
  final KeuanganController _keuanganCtrl = KeuanganController();

  // Fungsi untuk memformat angka jadi Rupiah (Rp 1.000.000)
  String formatRupiah(int angka) {
    String hasil = angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return "Rp $hasil";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _keuanganCtrl.fetchKeuangan(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }
        if (!snapshot.hasData || snapshot.data!['success'] == false) {
          return const Center(child: Text("Gagal memuat data keuangan."));
        }

        var data = snapshot.data!;
        List<KeuanganModel> riwayat = data['data'];

        return Column(
          children: [
            // KARTU SALDO UTAMA
            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Total Saldo Kas Masjid",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatRupiah(data['saldo']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Pemasukan",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            formatRupiah(data['pemasukan']),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Pengeluaran",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            formatRupiah(data['pengeluaran']),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // JUDUL RIWAYAT TRANSAKSI
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Riwayat Transaksi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // LIST TRANSAKSI
            Expanded(
              child: ListView.builder(
                itemCount: riwayat.length,
                itemBuilder: (context, index) {
                  var item = riwayat[index];
                  bool isPemasukan = item.jenis.toLowerCase() == 'pemasukan';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPemasukan
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          isPemasukan
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isPemasukan ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        item.keterangan,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item.tanggal),
                      trailing: Text(
                        (isPemasukan ? "+ " : "- ") +
                            formatRupiah(item.nominal),
                        style: TextStyle(
                          color: isPemasukan ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
