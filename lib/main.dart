import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mmkv/mmkv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'splashscreen.dart';
import 'dart:io' show Platform;
import 'dart:developer' as developer show log;

// Inisialisasi global plugin notifikasi
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('🚀 App starting...');

  try {
    // Inisialisasi MMKV
    await MMKV.initialize();
    developer.log('✅ MMKV initialized successfully');

    // Test MMKV
    final mmkv = MMKV.defaultMMKV();
    mmkv?.encodeBool('startup_test', true);
    final test = mmkv?.decodeBool('startup_test', defaultValue: false);
    developer.log('🔍 MMKV startup test: $test');
  } catch (e) {
    developer.log('❌ MMKV init failed: $e');
  }

  // Inisialisasi notifikasi lokal
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (payload) {
      // Bisa digunakan untuk deep link nanti
      developer.log('🔔 Notification tapped! Payload: $payload');
    },
  );

  developer.log('🚀 Running app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOLAH',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Wrapper untuk handle update checker
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Cek update setelah app dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen();
  }

  // 🔄 Fungsi untuk cek update dari Play Store
  Future<void> checkForUpdate() async {
    try {
      developer.log('🔍 Checking for app updates...');

      if (Platform.isAndroid) {
        // Cek apakah ada update tersedia
        final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

        developer.log('📱 Update available: ${updateInfo.updateAvailability}');
        developer.log(
          '📱 Immediate update allowed: ${updateInfo.immediateUpdateAllowed}',
        );
        developer.log(
          '📱 Flexible update allowed: ${updateInfo.flexibleUpdateAllowed}',
        );

        if (updateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          // Jika update tersedia, tampilkan dialog
          _showUpdateDialog(updateInfo);
        } else {
          developer.log('✅ App is up to date');
        }
      } else if (Platform.isIOS) {
        // Untuk iOS, bisa gunakan alternatif seperti cek versi dari server
        developer.log(
          'ℹ️ iOS update check not implemented (App Store handles this automatically)',
        );
        await _checkIOSUpdate();
      }
    } catch (e) {
      developer.log('❌ Error checking for updates: $e');
    }
  }

  // Dialog untuk menampilkan opsi update
  void _showUpdateDialog(AppUpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false, // User harus memilih
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Tersedia'),
          content: const Text(
            'Versi terbaru aplikasi MOLAH sudah tersedia. '
            'Untuk mendapatkan fitur terbaru dan perbaikan bug, '
            'silakan update aplikasi Anda.',
          ),
          actions: [
            // Tombol "Nanti"
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                developer.log('📱 User chose to update later');
              },
              child: const Text('Nanti'),
            ),
            // Tombol "Update Sekarang"
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performUpdate(updateInfo);
              },
              child: const Text('Update Sekarang'),
            ),
          ],
        );
      },
    );
  }

  // Melakukan update
  Future<void> _performUpdate(AppUpdateInfo updateInfo) async {
    try {
      developer.log('🔄 Starting app update...');

      if (updateInfo.immediateUpdateAllowed) {
        // Update langsung (user akan diarahkan ke Play Store)
        await InAppUpdate.performImmediateUpdate();
      } else if (updateInfo.flexibleUpdateAllowed) {
        // Update fleksibel (download di background)
        await InAppUpdate.startFlexibleUpdate();

        // Listen untuk status download
        InAppUpdate.completeFlexibleUpdate()
            .then((_) {
              developer.log('✅ Flexible update completed');
              _showUpdateCompletedSnackbar();
            })
            .catchError((error) {
              developer.log('❌ Flexible update failed: $error');
            });
      }
    } catch (e) {
      developer.log('❌ Update failed: $e');
      _showUpdateFailedSnackbar();
    }
  }

  // Snackbar untuk update berhasil
  void _showUpdateCompletedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Update berhasil didownload. Restart aplikasi untuk menerapkan update.',
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
  }

  // Snackbar untuk update gagal
  void _showUpdateFailedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Update gagal. Silakan coba lagi nanti.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Alternatif untuk iOS - cek versi dari server/API
  Future<void> _checkIOSUpdate() async {
    try {
      // Dapatkan info versi app saat ini
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;

      developer.log('📱 Current app version: $currentVersion ($buildNumber)');

      // TODO: Implementasikan pengecekan ke server/API untuk mendapatkan versi terbaru
      // Contoh:
      // final response = await http.get(Uri.parse('https://your-api.com/app-version'));
      // final latestVersion = json.decode(response.body)['latest_version'];

      // if (isVersionNewer(currentVersion, latestVersion)) {
      //   _showIOSUpdateDialog();
      // }
    } catch (e) {
      developer.log('❌ iOS version check failed: $e');
    }
  }

  // Dialog update untuk iOS
  void _showIOSUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Tersedia'),
          content: const Text(
            'Versi terbaru aplikasi MOLAH sudah tersedia di App Store. '
            'Silakan update aplikasi untuk mendapatkan fitur terbaru.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Buka App Store
                // launch('https://apps.apple.com/app/your-app-id');
              },
              child: const Text('Buka App Store'),
            ),
          ],
        );
      },
    );
  }
}

// 🔔 Fungsi untuk meminta izin notifikasi
// Panggil ini setelah user login
Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    // Untuk Android 13+, minta izin POST_NOTIFICATIONS
    final PermissionStatus status = await Permission.notification.request();

    if (status == PermissionStatus.granted) {
      developer.log('✅ Izin notifikasi diberikan');
    } else if (status == PermissionStatus.denied) {
      developer.log('❌ Izin notifikasi ditolak. Bisa coba lagi nanti.');
    } else if (status == PermissionStatus.permanentlyDenied) {
      developer.log('❌ Izin permanen ditolak. Arahkan ke pengaturan.');
      await openAppSettings();
    }
  } else if (Platform.isIOS) {
    developer.log('ℹ️ Izin notifikasi iOS sudah dihandle saat inisialisasi');
  }
}
