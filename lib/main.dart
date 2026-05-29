// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // ✅ Wajib untuk SystemChrome
import 'package:mmkv/mmkv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'splashscreen.dart';
import 'dart:io' show Platform;
import 'dart:developer' as developer show log;
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'utils/analytics_service.dart';
import 'utils/fcm_service.dart';
import 'utils/offline_cache_service.dart';

// CATATAN: FlutterLocalNotificationsPlugin diinisialisasi di dalam FCMService
// dan GoogleSheetsMonitorService masing-masing. Tidak perlu instance global di sini.

/// ✅ FIX: Setup System UI yang kompatibel semua OEM Android
/// Menggantikan setStatusBarColor/setNavigationBarColor yang deprecated
/// dan menyebabkan bug di Samsung, OPPO, Xiaomi, Realme, Vivo, dll.
void _setupSystemUI() {
  // Mode: edge-to-edge — Flutter menggambar sampai tepi layar
  // MainActivity.kt sudah set WindowCompat.setDecorFitsSystemWindows(false)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Set overlay style: transparan agar tidak ada warna bawaan Android
  // yang menabrak warna tema Flutter app
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Status bar (atas)
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('🚀 App starting...');

  // Inisialisasi Firebase
  await Firebase.initializeApp();
  developer.log('✅ Firebase initialized');

  // Integrasi Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  developer.log('✅ Crashlytics initialized');

  // Setup system UI sebelum app launch
  _setupSystemUI();

  try {
    // Inisialisasi MMKV
    await MMKV.initialize();
    developer.log('✅ MMKV initialized successfully');

    // Test MMKV
    final mmkv = MMKV.defaultMMKV();
    mmkv.encodeBool('startup_test', true);
    final test = mmkv.decodeBool('startup_test', defaultValue: false);
    developer.log('🔍 MMKV startup test: $test');
  } catch (e) {
    developer.log('❌ MMKV init failed: $e');
  }

  // ✅ Inisialisasi Offline Cache Service
  await OfflineCacheService.initialize();
  developer.log('✅ OfflineCacheService initialized');

  // ✅ Inisialisasi FCM Push Notification
  await FCMService.initialize();
  developer.log('✅ FCMService initialized');

  // ✅ Notifikasi diinisialisasi di FCMService.initialize() — tidak perlu duplikat di sini
  // FCMService sudah handle: permission request, channel creation, dan plugin init

  developer.log('🚀 Running app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOLAH',
      theme: ThemeData(
        // ✅ FIX: Hindari primarySwatch (deprecated), gunakan colorScheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // ✅ Tipografi global: Inter (Instagram-style) dengan warna yang tajam dan kontras
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: const Color(0xFF1A1A1A), // Hitam pekat Instagram-style
          displayColor: const Color(0xFF1A1A1A),
        ),
        // ✅ FIX: AppBarTheme dengan SystemUiOverlayStyle eksplisit
        appBarTheme: AppBarTheme(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemStatusBarContrastEnforced: false,
          ),
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const AppWrapper(),
      navigatorObservers: [AnalyticsService.observer],
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
  bool _isCheckingUpdate = true; // Flag untuk mengecek apakah sedang cek update
  bool _canProceed =
      false; // Flag untuk mengizinkan lanjut ke halaman berikutnya

  @override
  void initState() {
    super.initState();
    // Log molah.png saat aplikasi dimulai
    developer.log('🖼️ Loading logo: assets/img/molah.png');

    // Cek update setelah app dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading atau splash screen sampai pengecekan update selesai
    if (_isCheckingUpdate || !_canProceed) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo dari assets - PERUBAHAN DI SINI
                Image.asset(
                  'assets/img/molah.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    developer.log('❌ Error loading molah.png: $error');
                    // Fallback ke icon jika gambar tidak ditemukan
                    return const Icon(
                      Icons.mobile_friendly,
                      size: 80,
                      color: Color(0xFF10B981),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'MOLAH',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Memeriksa pembaruan...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Jika sudah bisa lanjut, tampilkan SplashScreen
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
          // Jika update tersedia, tampilkan dialog dan jangan lanjut
          await _showUpdateDialog(updateInfo);
        } else {
          developer.log('✅ App is up to date');
          // App sudah terbaru, bisa lanjut
          _allowToProceed();
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
      // Jika error saat cek update, tetap lanjutkan app
      _allowToProceed();
    }
  }

  // Fungsi untuk mengizinkan lanjut ke halaman berikutnya
  void _allowToProceed() {
    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        _canProceed = true;
      });
    }
  }

  // Dialog untuk menampilkan opsi update (dengan await untuk blocking)
  Future<void> _showUpdateDialog(AppUpdateInfo updateInfo) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // User harus memilih
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Update Diperlukan'),
            content: const Text(
              'Versi terbaru aplikasi MOLAH sudah tersedia. '
              'Untuk mendapatkan fitur terbaru dan perbaikan bug, '
              'silakan update aplikasi Anda terlebih dahulu.',
            ),
            actions: [
              // Tombol "Update Sekarang" (mandatory)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performUpdate(updateInfo);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Sekarang'),
              ),
              // Tombol "Keluar" sebagai alternatif jika user tidak mau update
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _exitApp();
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk keluar dari aplikasi
  void _exitApp() {
    developer.log('📱 User chose to exit app instead of updating');
    // Di sini bisa tambahkan cleanup jika diperlukan
    // SystemNavigator.pop() untuk Android
    // exit(0) untuk force exit (import dart:io)
  }

  // Melakukan update
  Future<void> _performUpdate(AppUpdateInfo updateInfo) async {
    try {
      developer.log('🔄 Starting app update...');

      if (updateInfo.immediateUpdateAllowed) {
        // Update langsung (user akan diarahkan ke Play Store)
        await InAppUpdate.performImmediateUpdate();
        // Setelah update immediate, app akan restart otomatis
      } else if (updateInfo.flexibleUpdateAllowed) {
        // Tampilkan progress dialog untuk flexible update
        _showUpdateProgressDialog();

        // Update fleksibel (download di background)
        await InAppUpdate.startFlexibleUpdate();

        // Listen untuk status download
        InAppUpdate.completeFlexibleUpdate()
            .then((_) {
              developer.log('✅ Flexible update completed');
              if (mounted) Navigator.of(context).pop(); // Tutup progress dialog
              if (mounted) _showUpdateCompletedDialog();
            })
            .catchError((error) {
              developer.log('❌ Flexible update failed: $error');
              if (mounted) Navigator.of(context).pop(); // Tutup progress dialog
              if (mounted) _showUpdateFailedDialog();
            });
      } else {
        // Jika tidak ada opsi update yang tersedia, tampilkan error
        _showUpdateFailedDialog();
      }
    } catch (e) {
      developer.log('❌ Update failed: $e');
      _showUpdateFailedDialog();
    }
  }

  // Dialog progress update
  void _showUpdateProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Mengunduh update...'),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog untuk update berhasil
  void _showUpdateCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Update Berhasil'),
            content: const Text(
              'Update berhasil didownload. Aplikasi akan restart untuk menerapkan update.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Restart aplikasi atau tutup aplikasi
                  Navigator.of(context).pop();
                  // InAppUpdate.completeFlexibleUpdate() sudah dipanggil sebelumnya
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog untuk update gagal
  void _showUpdateFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Update Gagal'),
            content: const Text(
              'Update gagal diunduh. Anda bisa mencoba lagi nanti atau '
              'update manual melalui Play Store.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Coba update lagi
                  checkForUpdate();
                },
                child: const Text('Coba Lagi'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Lanjutkan tanpa update (tidak direkomendasikan)
                  _allowToProceed();
                },
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
        );
      },
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
      //   await _showIOSUpdateDialog();
      // } else {
      //   _allowToProceed();
      // }

      // Untuk sementara, langsung izinkan lanjut
      _allowToProceed();
    } catch (e) {
      developer.log('❌ iOS version check failed: $e');
      _allowToProceed();
    }
  }

  // Dialog update untuk iOS
  Future<void> _showIOSUpdateDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Update Tersedia'),
            content: const Text(
              'Versi terbaru aplikasi MOLAH sudah tersedia di App Store. '
              'Silakan update aplikasi untuk mendapatkan fitur terbaru.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _exitApp();
                },
                child: const Text('Keluar'),
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
          ),
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
