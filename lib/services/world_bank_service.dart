import 'dart:convert';
import 'package:http/http.dart' as http;

class WorldBankData {
  final double inflationRate;
  final double gdpGrowth;

  WorldBankData({required this.inflationRate, required this.gdpGrowth});
}

class WorldBankService {
  static WorldBankData? _cached;
  static DateTime? _lastFetched;

  static Future<WorldBankData> getKenyaData() async {
    // Cache for 24 hours (this data changes slowly)
    if (_cached != null &&
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!).inHours < 24) {
      return _cached!;
    }

    try {
      // Fetch inflation and GDP growth in parallel
      final results = await Future.wait([
        _fetchIndicator('FP.CPI.TOTL.ZG'), // Inflation rate
        _fetchIndicator('NY.GDP.MKTP.KD.ZG'), // GDP growth
      ]);

      _cached = WorldBankData(inflationRate: results[0], gdpGrowth: results[1]);
      _lastFetched = DateTime.now();
      return _cached!;
    } catch (e) {
      // Fallback to recent Kenya averages if offline
      return WorldBankData(inflationRate: 6.8, gdpGrowth: 5.1);
    }
  }

  static Future<double> _fetchIndicator(String indicator) async {
    final url =
        'https://api.worldbank.org/v2/country/KE/indicator/$indicator?format=json&mrv=1';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final value = data[1][0]['value'];
      return (value as num).toDouble();
    }
    throw Exception('Failed to fetch $indicator');
  }
}
