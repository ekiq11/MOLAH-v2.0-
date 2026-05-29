import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

void main() async {
  String clientId = 'doku_key_0a493736d26b4da8aa7f94d30b771ab3';
  String secretKey = 'SK-ESQmgVKvd8bbOTceQ3EJ';
  String baseUrl = 'https://api-sandbox.doku.com';
  String targetPath = '/checkout/v1/payment';
  
  String requestId = const Uuid().v4();
  String timestamp = DateTime.now().toUtc().toIso8601String();
  
  Map<String, dynamic> body = {
    "order": {
      "amount": 10000,
      "invoice_number": "INV-123456",
      "callback_url": "https://example.com",
      "line_items": [
        {
          "name": "Top Up",
          "price": 10000,
          "quantity": 1
        }
      ]
    },
    "payment": {
      "payment_due_date": 60
    },
    "customer": {
      "id": "CUST-001",
      "name": "Test User",
      "email": "test@example.com"
    }
  };
  
  String minifiedBody = jsonEncode(body);
  List<int> bodyBytes = utf8.encode(minifiedBody);
  Digest digestSha256 = sha256.convert(bodyBytes);
  String digestBase64 = base64Encode(digestSha256.bytes);
  
  String stringToSign = "Client-Id:$clientId\n"
      "Request-Id:$requestId\n"
      "Request-Timestamp:$timestamp\n"
      "Request-Target:$targetPath\n"
      "Digest:$digestBase64";
      
  List<int> secretKeyBytes = utf8.encode(secretKey);
  List<int> messageBytes = utf8.encode(stringToSign);
  Hmac hmacSha256 = Hmac(sha256, secretKeyBytes);
  Digest signatureDigest = hmacSha256.convert(messageBytes);
  String signature = base64Encode(signatureDigest.bytes);
  
  var response = await http.post(
    Uri.parse('$baseUrl$targetPath'),
    headers: {
      'Client-Id': clientId,
      'Request-Id': requestId,
      'Request-Timestamp': timestamp,
      'Signature': 'HMACSHA256=$signature',
      'Content-Type': 'application/json',
    },
    body: minifiedBody,
  );
  
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
