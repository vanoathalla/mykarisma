import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../helpers/auth_helper.dart';
import '../../theme/app_theme.dart';
import '../../controllers/member_controller.dart';
import '../../controllers/keuangan_controller.dart';
import '../../controllers/acara_controller.dart';
import '../../controllers/catatan_controller.dart';
import '../../models/acara_model.dart';
import '../tambah_acara_view.dart';
import '../peta/peta_view.dart';
import '../ai/chatbot_view.dart';

class BerandaView extends StatefulWidget {
  const BerandaView({super.key});

  @override
  State<BerandaView> createState() => _BerandaViewState();
}

class _BerandaViewState extends State<BerandaView> {
  final MemberController _memberCtrl = MemberController();
  final KeuanganController _keuanganCtrl = KeuanganController();
  final AcaraController _acaraCtrl = AcaraController();
  final CatatanController _catatanCtrl = CatatanController();

  String _namaUser = 'Tamu Karisma';
  String _roleUser = 'tamu';
  bool _isLoading = true;

  int _jumlahMember = 0;
  int _totalSaldo = 0;
  int _jumlahAcaraMendatang = 0;
  int _jumlahCatatan = 0;
  List<AcaraModel> _acaraMendatang = [];
  List<AcaraModel> _acaraFiltered = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _acaraFiltered = List.from(_acaraMendatang);
      } else {
        _acaraFiltered = _acaraMendatang
            .where(
              (a) =>
                  a.nama.toLowerCase().contains(q) ||
                  a.kategori.toLowerCase().contains(q),
            )
            .toList();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final session = await AuthHelper.getActiveSession();
    if (session != null) {
      _namaUser = session['nama'] ?? 'Tamu Karisma';
      _roleUser = session['role'] ?? 'tamu';
    }

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final members = await _memberCtrl.fetchMember();
    final keuangan = await _keuanganCtrl.fetchKeuangan();
    final acara = await _acaraCtrl.fetchAcara();
    final catatan = await _catatanCtrl.fetchCatatan();

    final acaraMendatang = acara
        .where((a) => a.tanggal.compareTo(todayStr) >= 0)
        .toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    if (!mounted) return;
    setState(() {
      _jumlahMember = members.length;
      _totalSaldo = (keuangan['saldo'] as int?) ?? 0;
      _jumlahAcaraMendatang = acaraMendatang.length;
      _jumlahCatatan = catatan.length;
      _acaraMendatang = acaraMendatang.take(5).toList();
      _acaraFiltered = List.from(_acaraMendatang);
      _isLoading = false;
    });
  }

  String _formatRupiah(int angka) {
    final str = angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              radius: 24,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: enabled
                ? AppTheme.primary.withValues(alpha: 0.12)
                : Colors.grey.shade200,
            child: Icon(
              icon,
              color: enabled ? AppTheme.primary : Colors.grey,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: enabled ? Colors.black87 : Colors.grey,
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
        title: const Text('MyKarisma'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: _roleUser == 'admin'
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () async {
                final refresh = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TambahAcaraView(),
                  ),
                );
                if (refresh == true) _loadData();
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting Header ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahlan wa Sahlan,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _namaUser.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleUser.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Stat Cards ───────────────────────────────────────────────
              const Text(
                'Ringkasan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _isLoading
                  ? GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: List.generate(4, (_) => _buildShimmerCard()),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildStatCard(
                          icon: Icons.people,
                          value: '$_jumlahMember',
                          label: 'Jumlah Member',
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          icon: Icons.account_balance_wallet,
                          value: _formatRupiah(_totalSaldo),
                          label: 'Total Saldo',
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          icon: Icons.event,
                          value: '$_jumlahAcaraMendatang',
                          label: 'Acara Mendatang',
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          icon: Icons.note,
                          value: '$_jumlahCatatan',
                          label: 'Jumlah Catatan',
                          color: Colors.purple,
                        ),
                      ],
                    ),

              const SizedBox(height: 20),

              // ── Quick Actions ────────────────────────────────────────────
              const Text(
                'Aksi Cepat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(
                    icon: Icons.event_note,
                    label: 'Tambah\nAcara',
                    enabled: _roleUser == 'admin',
                    onTap: () async {
                      final refresh = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TambahAcaraView(),
                        ),
                      );
                      if (refresh == true) _loadData();
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.map,
                    label: 'Lihat\nPeta',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PetaView()),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.smart_toy,
                    label: 'Chatbot\nAI',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatbotView(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.currency_exchange,
                    label: 'Konversi',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Konversi Mata Uang — Coming Soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Upcoming Events ──────────────────────────────────────────
              const Text(
                'Acara Mendatang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // ── Search Bar Acara ─────────────────────────────────────────
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari acara berdasarkan nama atau kategori...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _isLoading
                  ? Column(
                      children: List.generate(
                        3,
                        (_) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : _acaraFiltered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              _searchCtrl.text.isNotEmpty
                                  ? 'Tidak ada acara yang cocok dengan pencarian.'
                                  : 'Tidak ada acara mendatang.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _acaraFiltered.length,
                          itemBuilder: (context, i) {
                            final item = _acaraFiltered[i];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppTheme.primary.withValues(alpha: 0.15),
                                  child: Icon(
                                    Icons.event,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                title: Text(
                                  item.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.tanggal} · ${item.kategori}',
                                ),
                                trailing: _roleUser == 'admin'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.tipe,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () async {
                                              final refresh =
                                                  await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      TambahAcaraView(
                                                    acaraEdit: item,
                                                  ),
                                                ),
                                              );
                                              if (refresh == true) _loadData();
                                            },
                                            child: const Icon(
                                              Icons.edit,
                                              size: 20,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () async {
                                              final messenger =
                                                  ScaffoldMessenger.of(
                                                context,
                                              );
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                    'Hapus Acara',
                                                  ),
                                                  content: Text(
                                                    'Yakin ingin menghapus acara "${item.nama}"?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        ctx,
                                                        false,
                                                      ),
                                                      child:
                                                          const Text('Batal'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        ctx,
                                                        true,
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.red,
                                                      ),
                                                      child:
                                                          const Text('Hapus'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                final res =
                                                    await _acaraCtrl
                                                        .hapusAcara(
                                                  item.idAcara,
                                                );
                                                if (mounted) {
                                                  messenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        res['message'],
                                                      ),
                                                      backgroundColor:
                                                          res['success']
                                                              ? Colors.green
                                                              : Colors.red,
                                                    ),
                                                  );
                                                  if (res['success']) {
                                                    _loadData();
                                                  }
                                                }
                                              }
                                            },
                                            child: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.tipe,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
