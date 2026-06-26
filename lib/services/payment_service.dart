import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wraps IntaSend's Collection API to trigger an M-Pesa STK push and poll
/// for the result. Only needs the publishable key — IntaSend's collection
/// and status endpoints are designed for direct client-side calls, unlike
/// Safaricom's Daraja API, so no backend server is required here.
///
/// Sandbox mode: no real money moves, even though the STK prompt will hit
/// a real phone.
class PaymentService {
  PaymentService._();

  static const String _publicKey =
      'ISPubKey_test_ca57c6c3-9f7e-4711-a6f0-fd05e1413a08';
  static const String _baseUrl = 'https://sandbox.intasend.com/api/v1';

  /// Triggers an M-Pesa STK push to [phoneNumber] (format: 2547XXXXXXXX)
  /// for [amount] KES. Returns the invoice_id needed to check status.
  static Future<String> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String customerEmail,
    required String apiRef,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payment/collection/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'public_key': _publicKey,
        'currency': 'KES',
        'method': 'M-PESA',
        'amount': amount,
        'phone_number': phoneNumber,
        'email': customerEmail,
        'api_ref': apiRef,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to initiate payment: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['invoice']['invoice_id'] as String;
  }

  /// Polls the payment status every [interval] until it leaves PENDING,
  /// or [timeout] is reached. Returns the final state, e.g. "COMPLETE",
  /// "FAILED", or "TIMEOUT" if it never resolved in time.
  static Future<String> pollPaymentStatus({
    required String invoiceId,
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final stopAt = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(stopAt)) {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment/status/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'public_key': _publicKey, 'invoice_id': invoiceId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final state = data['invoice']['state'] as String;
        if (state != 'PENDING') return state;
      }

      await Future.delayed(interval);
    }

    return 'TIMEOUT';
  }
}
