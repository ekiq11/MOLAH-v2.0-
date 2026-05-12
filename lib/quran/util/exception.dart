// quran/utils/exceptions.dart
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

class AdhanAssetNotFoundException implements Exception {
  final String message;
  AdhanAssetNotFoundException(this.message);

  @override
  String toString() => 'AdhanAssetNotFoundException: $message';
}
