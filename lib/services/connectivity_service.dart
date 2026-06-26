import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Lightweight wrapper around connectivity_plus that exposes a simple
/// online/offline boolean instead of raw ConnectivityResult lists.
///
/// NOTE: this reflects whether a network interface is active (WiFi/
/// cellular), not whether that network actually reaches the internet.
/// Always guard real network calls (currency_service, world_bank_service)
/// with their own try/catch regardless of this status.
class ConnectivityService {
  ConnectivityService._internal() {
    _init();
  }

  static final ConnectivityService instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Stream<bool> get onStatusChange => _statusController.stream;

  Future<void> _init() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _isOnline = _resultIndicatesOnline(initial);
    } catch (_) {
      _isOnline = true;
    }
    _statusController.add(_isOnline);

    _connectivity.onConnectivityChanged.listen((results) {
      final nowOnline = _resultIndicatesOnline(results);
      if (nowOnline != _isOnline) {
        _isOnline = nowOnline;
        _statusController.add(_isOnline);
      }
    });
  }

  bool _resultIndicatesOnline(List<ConnectivityResult> results) {
    return results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
  }

  void dispose() {
    _statusController.close();
  }
}
