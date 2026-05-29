import 'dart:io';

void main() {
  patchSplashScreen();
  patchLoginScreen();
  print('Patched splash screen and login screen.');
}

void patchSplashScreen() {
  final file = File('lib/splashscreen.dart');
  var content = file.readAsStringSync();

  // Replace red gradient with Emerald Green
  content = content.replaceAll(
    'colors: [Color(0xFFE53E3E), Color(0xFFD53F8C)],',
    'colors: [Color(0xFF10B981), Color(0xFF059669)],',
  );

  file.writeAsStringSync(content);
}

void patchLoginScreen() {
  final file = File('lib/login.dart');
  var content = file.readAsStringSync();

  // Background gradient
  content = content.replaceAll(
    'colors: [Color(0xFFFF6B6B), Color(0xFFE53E3E), Color(0xFFD53F8C)],',
    'colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],',
  );

  // Button gradient
  content = content.replaceAll(
    'colors: [\n                                      Color(0xFFE53E3E),\n                                      Color(0xFFD53F8C),\n                                    ],',
    'colors: [\n                                      Color(0xFF10B981),\n                                      Color(0xFF059669),\n                                    ],',
  );

  // Focus and icon colors
  content = content.replaceAll('Color(0xFFE53E3E)', 'Color(0xFF10B981)');

  file.writeAsStringSync(content);
}
