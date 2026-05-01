import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_model.dart';

class CurrencyController {
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/IDR';
  static const String _cacheKey = 'cached_currency_rates';
  static const List<String> supportedCurrencies = ['IDR', 'USD', 'SAR', 'EUR'];

  Future<CurrencyModel?> fetchRates() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final model = CurrencyModel.fromJson(json);
        await _cacheRates(model);
        return model;
      }
      return await _getCachedRates();
    } catch (e) {
      debugPrint('[CurrencyController] Error: $e');
      return await _getCachedRates();
    }
  }

  /// Konversi [amount] dari mata uang [from] ke [to].
  /// [rates] adalah CurrencyModel dengan base IDR (rates[IDR] = 1.0).
  double convert(
    double amount,
    String from,
    String to,
    CurrencyModel rates,
  ) {
    if (from == to) return amount;
    final fromRate = rates.rates[from] ?? 1.0;
    final toRate = rates.rates[to] ?? 1.0;
    // from → IDR → to
    if (from == 'IDR') return amount * toRate;
    if (to == 'IDR') return amount / fromRate;
    return (amount / fromRate) * toRate;
  }

  Future<void> _cacheRates(CurrencyModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(model.toMap()));
  }

  Future<CurrencyModel?> _getCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached == null) return null;
      final json = jsonDecode(cached) as Map<String, dynamic>;
      final ratesRaw = json['rates'] as Map<String, dynamic>;
      final rates = ratesRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));
      return CurrencyModel(
        baseCurrency: json['base_code'] ?? 'IDR',
        rates: rates,
        lastUpdated:
            DateTime.tryParse(json['time_last_update_utc'] ?? '') ??
            DateTime.now(),
      );
    } catch (e) {
      debugPrint('[CurrencyController] Cache error: $e');
      return null;
    }
  }
}
