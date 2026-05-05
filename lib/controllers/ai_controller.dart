import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/acara_model.dart';
import '../models/catatan_model.dart';
import '../models/keuangan_model.dart';
import '../models/member_model.dart';

class AIController {
  static String get _groqApiKey =>
      dotenv.env['GROQ_API_KEY'] ?? '';

  static String get _groqEndpoint =>
      dotenv.env['GROQ_ENDPOINT'] ??
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.3-70b-versatile';

  static const String _baseSystemPrompt =
      'Kamu adalah asisten digital bernama "Karisma AI" untuk organisasi '
      'karang taruna / remaja masjid bernama KARISMA. '
      'Tugasmu adalah membantu anggota dengan informasi kegiatan, keuangan, '
      'catatan rapat, dan keislaman. '
      'Jawab dalam Bahasa Indonesia yang sopan, ramah, dan informatif. '
      'PENTING: Jika ada pertanyaan tentang agenda, keuangan, catatan, atau '
      'anggota, SELALU gunakan data yang ada di bagian "DATA APLIKASI" di bawah. '
      'Jangan mengarang data yang tidak ada. '
      'Jika data tidak tersedia, katakan dengan jujur bahwa belum ada data.';

  final List<Map<String, String>> _history = [];

  AIController() {
    _history.add({'role': 'system', 'content': _baseSystemPrompt});
  }

  void injectAppContext({
    required List<AcaraModel> acara,
    required List<KeuanganModel> keuangan,
    required List<CatatanModel> catatan,
    required List<MemberModel> members,
    required int saldo,
  }) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final mendatang = acara
        .where((a) => a.tanggal.compareTo(todayStr) >= 0)
        .toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
    final sudahLewat = acara
        .where((a) => a.tanggal.compareTo(todayStr) < 0)
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    final acaraMendatangStr = mendatang.isEmpty
        ? '  - (Belum ada agenda mendatang)'
        : mendatang
            .take(10)
            .map((a) =>
                '  - ${a.nama} | Tanggal: ${a.tanggal} | '
                'Kategori: ${a.kategori} | Tipe: ${a.tipe}')
            .join('\n');

    final acaraLewatStr = sudahLewat.isEmpty
        ? '  - (Tidak ada)'
        : sudahLewat
            .take(5)
            .map((a) => '  - ${a.nama} | ${a.tanggal}')
            .join('\n');

    final transaksiStr = keuangan.isEmpty
        ? '  - (Belum ada transaksi)'
        : keuangan
            .take(10)
            .map((k) =>
                '  - [${k.jenis.toUpperCase()}] ${k.keterangan} | '
                'Rp ${_formatRupiah(k.nominal)} | ${k.tanggal}')
            .join('\n');

    final catatanStr = catatan.isEmpty
        ? '  - (Belum ada catatan)'
        : catatan
            .take(5)
            .map((c) =>
                '  - "${c.judul}" | Acara: ${c.acara} | ${c.tanggal}\n'
                '    Ringkasan: ${c.isi.length > 100 ? '${c.isi.substring(0, 100)}...' : c.isi}')
            .join('\n');

    final memberStr = members.isEmpty
        ? '  - (Belum ada data anggota)'
        : members
            .map((m) => '  - ${m.nama} (${m.role})')
            .join('\n');

    final fullSystemPrompt = '''
$_baseSystemPrompt

=== DATA APLIKASI KARISMA (diperbarui: $todayStr) ===

≡ƒôà AGENDA MENDATANG (${mendatang.length} acara):
$acaraMendatangStr

≡ƒôà AGENDA SUDAH LEWAT (5 terbaru):
$acaraLewatStr

≡ƒÆ░ KEUANGAN:
  - Saldo kas saat ini: Rp ${_formatRupiah(saldo)}
  - 10 Transaksi terbaru:
$transaksiStr

≡ƒô¥ CATATAN & NOTULENSI (5 terbaru):
$catatanStr

≡ƒæÑ ANGGOTA ORGANISASI (${members.length} orang):
$memberStr

=== AKHIR DATA APLIKASI ===

Gunakan data di atas untuk menjawab pertanyaan pengguna secara akurat.
Tanggal hari ini adalah $todayStr.
''';

    if (_history.isNotEmpty && _history.first['role'] == 'system') {
      _history[0] = {'role': 'system', 'content': fullSystemPrompt};
    } else {
      _history.insert(0, {'role': 'system', 'content': fullSystemPrompt});
    }

    debugPrint('[AIController] Context injected: '
        '${mendatang.length} acara, ${keuangan.length} transaksi, '
        '${catatan.length} catatan, ${members.length} member');
  }

  Future<String> sendMessage(String userMessage, {String? context}) async {
    final content =
        context != null ? '$userMessage\n\nKonteks: $context' : userMessage;

    _history.add({'role': 'user', 'content': content});

    try {
      final response = await http
          .post(
            Uri.parse(_groqEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_groqApiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': _history,
              'max_tokens': 1024,
              'temperature': 0.5,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply =
            (data['choices'] as List).first['message']['content'] as String;
        _history.add({'role': 'assistant', 'content': reply});
        return reply;
      }

      final errData = jsonDecode(response.body) as Map<String, dynamic>;
      final errMsg = errData['error']?['message'] ?? 'Unknown error';
      debugPrint('[AIController] Groq error ${response.statusCode}: $errMsg');
      _history.removeLast();

      if (response.statusCode == 401) {
        return 'API key tidak valid. Silakan periksa konfigurasi Groq API key.';
      }
      if (response.statusCode == 429) {
        return 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.';
      }
      return 'Maaf, terjadi kesalahan (${response.statusCode}). Coba lagi.';
    } catch (e) {
      debugPrint('[AIController] Error: $e');
      if (_history.isNotEmpty && _history.last['role'] == 'user') {
        _history.removeLast();
      }
      return 'Asisten AI tidak tersedia. Periksa koneksi internet.';
    }
  }

  Future<String> analyzeFinance(List<KeuanganModel> transactions) async {
    if (transactions.isEmpty) {
      return 'Belum ada data transaksi untuk dianalisis.';
    }

    final totalPemasukan = transactions
        .where((t) => t.jenis == 'pemasukan')
        .fold(0, (sum, t) => sum + t.nominal);
    final totalPengeluaran = transactions
        .where((t) => t.jenis == 'pengeluaran')
        .fold(0, (sum, t) => sum + t.nominal);
    final saldo = totalPemasukan - totalPengeluaran;

    final ctx = '''
Data keuangan organisasi KARISMA:
- Total pemasukan: Rp ${_formatRupiah(totalPemasukan)}
- Total pengeluaran: Rp ${_formatRupiah(totalPengeluaran)}
- Saldo saat ini: Rp ${_formatRupiah(saldo)}
- Jumlah transaksi: ${transactions.length}
- Transaksi terbaru: ${transactions.take(5).map((t) => '${t.jenis} ${t.keterangan} Rp${t.nominal}').join(', ')}
''';

    return await sendMessage(
      'Analisis kondisi keuangan organisasi ini dan berikan rekomendasi '
      'pengelolaan keuangan yang baik.',
      context: ctx,
    );
  }

  void clearHistory() {
    _history.clear();
    _history.add({'role': 'system', 'content': _baseSystemPrompt});
  }

  void clearChatOnly() {
    if (_history.isEmpty) return;
    final systemMsg = _history.first;
    _history.clear();
    _history.add(systemMsg);
  }

  static String _formatRupiah(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

