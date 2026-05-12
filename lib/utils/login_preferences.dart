import 'package:mmkv/mmkv.dart';
import 'dart:convert';

class LoginPreferences {
  // ✅ Buat instance MMKV yang lebih robust
  static MMKV? _getMMKV() {
    try {
      final mmkv = MMKV.defaultMMKV();
      return mmkv;
    } catch (e) {
      print('❌ Error getting MMKV instance: $e');
      return null;
    }
  }

  // ✅ Method untuk check health MMKV
  static Future<bool> checkHealth() async {
    try {
      final mmkv = _getMMKV();
      if (mmkv == null) return false;

      // Test write/read
      final testKey = 'health_check_${DateTime.now().millisecondsSinceEpoch}';
      mmkv.encodeBool(testKey, true);
      final result = mmkv.decodeBool(testKey, defaultValue: false);
      mmkv.removeValue(testKey); // Cleanup

      print('✅ MMKV Health Check: $result');
      return result;
    } catch (e) {
      print('❌ MMKV Health Check failed: $e');
      return false;
    }
  }

  // ✅ Improved isLoggedIn dengan lebih banyak validasi
  static Future<bool> isLoggedIn() async {
    try {
      final mmkv = _getMMKV();
      if (mmkv == null) {
        print('❌ MMKV null in isLoggedIn');
        return false;
      }

      // Check multiple indicators
      final hasLoginFlag = mmkv.decodeBool(
        'user_logged_in',
        defaultValue: false,
      );
      final hasUsername = (mmkv.decodeString('user_username') ?? '').isNotEmpty;
      final hasUserData =
          (mmkv.decodeString('user_data_json') ?? '').isNotEmpty;

      print(
        '🔍 Login Check - Flag: $hasLoginFlag, Username: $hasUsername, Data: $hasUserData',
      );

      // Harus semua ada untuk dianggap logged in
      final result = hasLoginFlag && hasUsername && hasUserData;
      print('🔍 Final login status: $result');

      return result;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  // ✅ Enhanced getUsername dengan fallback
  static Future<String?> getUsername() async {
    try {
      final mmkv = _getMMKV();
      if (mmkv == null) return null;

      final username = mmkv.decodeString('user_username');
      print('🔍 Retrieved username: "$username"');

      return username?.isNotEmpty == true ? username : null;
    } catch (e) {
      print('❌ Error getting username: $e');
      return null;
    }
  }

  // ✅ Get last successful username for biometric login
  static Future<String?> getLastSuccessfulUsername() async {
    try {
      final mmkv = _getMMKV();
      if (mmkv == null) return null;
      final username = mmkv.decodeString('last_successful_username');
      return username?.isNotEmpty == true ? username : null;
    } catch (e) {
      return null;
    }
  }

  // ✅ Robust saveLoginData dengan verifikasi
  static Future<bool> saveLoginData({
    required String username,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final mmkv = _getMMKV();
      if (mmkv == null) {
        print('❌ MMKV null in saveLoginData');
        return false;
      }

      // Simpan dengan key yang konsisten
      mmkv.encodeBool('user_logged_in', true);
      mmkv.encodeString('user_username', username);
      mmkv.encodeString('last_successful_username', username); // Save for biometric
      mmkv.encodeString('user_data_json', json.encode(userData));
      mmkv.encodeInt('user_login_time', DateTime.now().millisecondsSinceEpoch);

      // ✅ Force sync ke disk (penting untuk release)
      await Future.delayed(Duration(milliseconds: 50));

      // Verifikasi data tersimpan
      final savedUsername = mmkv.decodeString('user_username');
      final savedFlag = mmkv.decodeBool('user_logged_in', defaultValue: false);

      print(
        '✅ Save verification - Username: "$savedUsername", Flag: $savedFlag',
      );

      final success = savedUsername == username && savedFlag;
      print('✅ Save login data result: $success');

      return success;
    } catch (e) {
      print('❌ Error saving login data: $e');
      return false;
    }
  }

  // ✅ Enhanced clear method
  static Future<bool> clearAllUserData(String username) async {
    try {
      final mmkv = _getMMKV();
      if (mmkv == null) {
        print('❌ MMKV null in clearAllUserData');
        return false;
      }

      // List semua key yang harus dihapus
      final keysToRemove = [
        'user_logged_in',
        'user_username',
        'user_data_json',
        'user_login_time',
        'santri_$username',
        'notifications_$username',
        'last_update_$username',
        'notifications_enhanced_$username',
        // DO NOT remove 'last_successful_username' here so biometric still works
      ];

      for (final key in keysToRemove) {
        if (mmkv.containsKey(key)) {
          mmkv.removeValue(key);
          print('🗑️ Removed key: $key');
        }
      }

      // Force sync
      await Future.delayed(Duration(milliseconds: 50));

      // Verifikasi pembersihan
      final stillLoggedIn = mmkv.decodeBool(
        'user_logged_in',
        defaultValue: false,
      );
      final stillHasUsername =
          (mmkv.decodeString('user_username') ?? '').isNotEmpty;

      print(
        '🔍 Clear verification - Still logged: $stillLoggedIn, Still has username: $stillHasUsername',
      );

      return !stillLoggedIn && !stillHasUsername;
    } catch (e) {
      print('❌ Error clearing user data: $e');
      return false;
    }
  }
}
