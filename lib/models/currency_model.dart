class CurrencyModel {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime lastUpdated;

  CurrencyModel({
    required this.baseCurrency,
    required this.rates,
    required this.lastUpdated,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    final ratesRaw = json['rates'] as Map<String, dynamic>;
    final rates = ratesRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    return CurrencyModel(
      baseCurrency: json['base_code'] ?? 'IDR',
      rates: rates,
      lastUpdated:
          DateTime.tryParse(json['time_last_update_utc'] ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'base_code': baseCurrency,
    'rates': rates,
    'time_last_update_utc': lastUpdated.toIso8601String(),
  };
}
