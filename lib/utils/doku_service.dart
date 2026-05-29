import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class DokuService {
  // TODO: Ganti dengan Client ID dan Secret Key dari Dashboard DOKU Sandbox
  static const String clientId = 'BRN-0227-1780039122759';
  static const String secretKey = 'SK-scN1EvDtBUOlQmR3i4sa';
  static const String baseUrl = 'https://api-sandbox.doku.com';

  /// Membuat signature HMAC-SHA256 sesuai standar DOKU Jokul
  static String generateSignature(String clientId, String requestId, String timestamp, String targetPath, String secretKey, Map<String, dynamic> body) {
    // 1. Minify JSON Body
    String minifiedBody = jsonEncode(body);
    
    // 2. Hash body dengan SHA256 lalu encode Base64
    List<int> bodyBytes = utf8.encode(minifiedBody);
    Digest digestSha256 = sha256.convert(bodyBytes);
    String digestBase64 = base64Encode(digestSha256.bytes);

    // 3. Susun String to Sign
    String stringToSign = "Client-Id:$clientId\n"
        "Request-Id:$requestId\n"
        "Request-Timestamp:$timestamp\n"
        "Request-Target:$targetPath\n"
        "Digest:$digestBase64";

    // 4. Generate HMAC-SHA256
    List<int> keyBytes = utf8.encode(secretKey);
    List<int> signBytes = utf8.encode(stringToSign);
    
    Hmac hmacSha256 = Hmac(sha256, keyBytes);
    Digest signatureDigest = hmacSha256.convert(signBytes);
    String signatureBase64 = base64Encode(signatureDigest.bytes);

    return "HMACSHA256=$signatureBase64";
  }

  /// Meminta Checkout URL dari DOKU
  static Future<String?> createCheckoutUrl({
    required double amount,
    required String invoiceNumber,
    required String itemName,
    required String customerName,
    required String customerEmail,
  }) async {
    final targetPath = '/checkout/v1/payment';
    final url = Uri.parse('$baseUrl$targetPath');
    final requestId = const Uuid().v4();
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'\.\d+Z$'), 'Z');

    final body = {
      "order": {
        "amount": amount.toInt(),
        "invoice_number": invoiceNumber,
        "currency": "IDR",
        "callback_url": "https://doku.com/",
        "line_items": [
          {
            "name": itemName,
            "price": amount.toInt(),
            "quantity": 1
          }
        ]
      },
      "payment": {
        "payment_due_date": 60 // Expire dalam 60 menit
      },
      "customer": {
        "name": customerName,
        "email": customerEmail
      }
    };

    final signature = generateSignature(clientId, requestId, timestamp, targetPath, secretKey, body);

    try {
      final response = await http.post(
        url,
        headers: {
          'Client-Id': clientId,
          'Request-Id': requestId,
          'Request-Timestamp': timestamp,
          'Signature': signature,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['response']['payment']['url'];
      } else {
        print('DOKU Error [${response.statusCode}]: ${response.body}');
        return null;
      }
    } catch (e) {
      print('DOKU Exception: $e');
      return null;
    }
  }
}
