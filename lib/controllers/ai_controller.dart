import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/keuangan_model.dart';

class AIController {
  // PENTING: Ganti dengan API key Gemini yang valid
  // Untuk production, gunakan environment variable atau secure storage
  static const String _apiKey = 'AIzaSyDS3sDMimc952U7Uv4CMpYGvgornMWisB0';

  static const String _systemPrompt = '''
Kamu adalah asisten digital untuk organisasi karang taruna / remaja masjid bernama KARISMA.
Tugasmu adalah membantu anggota dengan informasi kegiatan, keuangan, dan keislaman.
Jawab dalam Bahasa Indonesia yang sopan, ramah, dan informatif.
Jika ditanya tentang hal di luar konteks organisasi, tetap jawab dengan sopan.
''';

  late final GenerativeModel _model;
  final List<Content> _chatHistory = [];

  AIController() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
  }

  Future<String> sendMessage(String userMessage, {String? context}) async {
    try {
      final messageWithContext = context != null
          ? '$userMessage\n\nKonteks: $context'
          : userMessage;

      _chatHistory.add(Content.text(messageWithContext));

      final chat = _model.startChat(history: _chatHistory);
      final response = await chat.sendMessage(
        Content.text(messageWithContext),
      );

      final responseText = response.text ?? 'Maaf, tidak ada respons.';
      _chatHistory.add(Content.model([TextPart(responseText)]));

      return responseText;
    } on GenerativeAIException catch (e) {
      debugPrint('[AIController] Gemini error: $e');
      return 'Maaf, terjadi kesalahan pada layanan AI. Silakan coba lagi.';
    } catch (e) {
      debugPrint('[AIController] Error: $e');
      return 'Asisten AI tidak tersedia, periksa koneksi internet.';
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

    final context = '''
Data keuangan organisasi KARISMA:
- Total pemasukan: Rp ${totalPemasukan.toString()}
- Total pengeluaran: Rp ${totalPengeluaran.toString()}
- Saldo saat ini: Rp ${saldo.toString()}
- Jumlah transaksi: ${transactions.length}
- Transaksi terbaru: ${transactions.take(5).map((t) => '${t.jenis} ${t.keterangan} Rp${t.nominal}').join(', ')}
''';

    return await sendMessage(
      'Analisis kondisi keuangan organisasi ini dan berikan rekomendasi pengelolaan keuangan yang baik.',
      context: context,
    );
  }

  void clearHistory() {
    _chatHistory.clear();
  }
}
