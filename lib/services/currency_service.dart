import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class CurrencyService {
  static Map<String, double> _rates = {};
  static DateTime? _lastFetched;

  static Future<Map<String, double>> getRates() async {
    // Use cache if fetched within last hour
    if (_rates.isNotEmpty &&
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!).inHours < 1) {
      return _rates;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.openExchangeUrl}?app_id=${ApiConfig.openExchangeAppId}&symbols=KES,USD,EUR,GBP',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _rates = Map<String, double>.from(
          (data['rates'] as Map).map((k, v) => MapEntry(k, v.toDouble())),
        );
        _lastFetched = DateTime.now();
        print('✅ Rates fetched: $_rates');
        return _rates;
      } else {
        print('❌ API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Currency fetch error: $e');
    }

    // Fallback if offline
    return {'KES': 130.0, 'USD': 1.0, 'EUR': 0.92, 'GBP': 0.79};
  }

  static Future<String> convertFromKES(double kesAmount) async {
    final rates = await getRates();
    final usd = kesAmount / (rates['KES'] ?? 130.0);
    return 'KES ${kesAmount.toStringAsFixed(0)} (USD ${usd.toStringAsFixed(2)})';
  }

  static Future<double> kesToUSD(double kesAmount) async {
    final rates = await getRates();
    return kesAmount / (rates['KES'] ?? 130.0);
  }
}
