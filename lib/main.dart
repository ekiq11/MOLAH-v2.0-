import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mmkv/mmkv.dart';
import 'package:permission_handler/permission_handler.dart';
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
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
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
