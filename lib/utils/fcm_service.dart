import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mmkv/mmkv.dart';

// ============================================================
// FCM Background Handler — HARUS top-level function
// ============================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [FCM Background] ${message.notification?.title}');
  await FCMService._showFCMNotification(message);
}

// ============================================================
// FCM Service — Push Notification Real-time
// Menggantikan sistem polling WorkManager yang boros baterai
// ============================================================
class FCMService {
  static FirebaseMessaging? _messaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static MMKV? _mmkv;
  static bool _initialized = false;

  // Notification channel untuk FCM
  static const String _fcmChannelId = 'channel_fcm_molah';
  static const String _fcmChannelName = 'Notifikasi Real-time MOLAH';

  // ──────────────────────────────────────────────
  // Inisialisasi FCM — panggil sekali di main.dart
  // ──────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _messaging = FirebaseMessaging.instance;
      _mmkv = MMKV.defaultMMKV();

      // Setup local notifications plugin untuk tampilkan notifikasi FCM
      await _initLocalNotifications();

      // Minta izin notifikasi dari user (iOS wajib, Android 13+ wajib)
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '✅ [FCM] Permission: ${settings.authorizationStatus.name}',
      );

      // Daftarkan background handler (harus sebelum listener lain)
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      // Handler: App FOREGROUND — tampilkan notifikasi manual (Android)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handler: User tap notifikasi saat app di background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Cek apakah app dibuka dari notifikasi (app terminated)
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Simpan FCM token ke MMKV
      await _refreshAndSaveToken();

      // Listener jika token berubah (misal HP baru / reinstall)
      _messaging!.onTokenRefresh.listen((token) {
        _mmkv?.encodeString('fcm_token', token);
        debugPrint('🔄 [FCM] Token refreshed: $token');
      });

      _initialized = true;
      debugPrint('✅ [FCM] Service initialized successfully');
    } catch (e) {
      debugPrint('❌ [FCM] Initialization error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Setup local notifications untuk tampilkan FCM
  // ──────────────────────────────────────────────
  static Future<void> _initLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    final androidPlugin = _localNotifications
        ?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Buat channel khusus FCM real-time
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _fcmChannelId,
        _fcmChannelName,
        description: 'Notifikasi real-time dari server MOLAH',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFDC2626),
        showBadge: true,
      ),
    );

    await _localNotifications!.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[FCM] Local notif tapped: ${response.payload}');
      },
    );
  }

  // ──────────────────────────────────────────────
  // Ambil & simpan FCM token
  // ──────────────────────────────────────────────
  static Future<String?> _refreshAndSaveToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token != null) {
        _mmkv?.encodeString('fcm_token', token);
        debugPrint('📱 [FCM] Token: $token');
      }
      return token;
    } catch (e) {
      debugPrint('❌ [FCM] Token error: $e');
      return null;
    }
  }

  // Akses token dari luar (untuk dikirim ke server jika diperlukan)
  static String? get fcmToken => _mmkv?.decodeString('fcm_token');

  // ──────────────────────────────────────────────
  // Handle pesan saat app FOREGROUND
  // ──────────────────────────────────────────────
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '🔔 [FCM Foreground] ${message.notification?.title}: '
      '${message.notification?.body}',
    );
    await _showFCMNotification(message);
  }

  // ──────────────────────────────────────────────
  // Handle tap notifikasi → navigasi ke halaman sesuai payload
  // ──────────────────────────────────────────────
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    debugPrint('[FCM] Notification tapped, type: $type, data: $data');

    // Simpan pending navigation ke MMKV
    // HomeScreen akan baca ini saat build dan navigate sesuai
    if (type.isNotEmpty) {
      _mmkv?.encodeString(
        'fcm_pending_navigation',
        jsonEncode({'type': type, 'data': data}),
      );
    }
  }

  // ──────────────────────────────────────────────
  // Tampilkan notifikasi sistem (BigText WhatsApp-style)
  // ──────────────────────────────────────────────
  static Future<void> _showFCMNotification(RemoteMessage message) async {
    if (_localNotifications == null) await _initLocalNotifications();

    final notification = message.notification;
    final title = notification?.title ?? 'MOLAH';
    final body = notification?.body ?? '';
    final data = message.data;
    final type = data['type'] ?? 'general';

    // Tentukan subText berdasarkan tipe
    String subText;
    switch (type) {
      case 'spp':
        subText = 'Pengingat Keuangan';
        break;
      case 'transaction':
        subText = 'Update Keuangan Santri';
        break;
      case 'hafalan':
        subText = 'Progress Hafalan';
        break;
      case 'pelanggaran':
        subText = 'Catatan Pelanggaran';
        break;
      case 'izin':
        subText = 'Status Perizinan';
        break;
      case 'pengumuman':
        subText = 'Pengumuman Pesantren';
        break;
      default:
        subText = 'MOLAH — Monitoring Santri';
    }

    final androidDetails = AndroidNotificationDetails(
      _fcmChannelId,
      _fcmChannelName,
      channelDescription: 'Notifikasi real-time dari server MOLAH',
      importance: Importance.high,
      priority: Priority.high,
      ticker: title,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFFDC2626),
      ledOnMs: 1000,
      ledOffMs: 500,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFDC2626),
      autoCancel: true,
      // BigTextStyle — expandable seperti WhatsApp
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: subText,
      ),
      groupKey: 'com.pizab.molah.notifications',
    );

    try {
      await _localNotifications?.show(
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('❌ [FCM] Show notification error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Subscribe ke topic (untuk pengumuman massal)
  // ──────────────────────────────────────────────
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      debugPrint('✅ [FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ [FCM] Subscribe error: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      debugPrint('✅ [FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ [FCM] Unsubscribe error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Subscribe berdasarkan data santri
  // Dipanggil setelah login berhasil
  // ──────────────────────────────────────────────
  static Future<void> subscribeForUser({
    required String username,
    String? kelas,
    String? asrama,
  }) async {
    // Topic global — semua santri
    await subscribeToTopic('all_santri');
    // Topic per user
    await subscribeToTopic('user_$username');
    // Topic per kelas jika tersedia
    if (kelas != null && kelas.isNotEmpty) {
      final safeKelas = kelas.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      await subscribeToTopic('kelas_$safeKelas');
    }
    // Topic per asrama jika tersedia
    if (asrama != null && asrama.isNotEmpty) {
      final safeAsrama = asrama.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      await subscribeToTopic('asrama_$safeAsrama');
    }
    debugPrint('✅ [FCM] Subscribed for user: $username');
  }

  // ──────────────────────────────────────────────
  // Cek pending navigation dari tap notifikasi
  // ──────────────────────────────────────────────
  static Map<String, dynamic>? consumePendingNavigation() {
    final json = _mmkv?.decodeString('fcm_pending_navigation');
    if (json != null && json.isNotEmpty) {
      _mmkv?.removeValue('fcm_pending_navigation');
      try {
        return jsonDecode(json) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }
}
