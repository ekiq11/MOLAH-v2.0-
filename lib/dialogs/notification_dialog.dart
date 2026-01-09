// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:mmkv/mmkv.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

// Background task callback function - harus di top level
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("Background task started: $task");
      final username = inputData?['username'] ?? '';
      if (username.isEmpty) {
        return Future.value(false);
      }
      // Initialize MMKV in background
      await MMKV.initialize();
      final mmkv = MMKV.defaultMMKV();
      // Initialize notifications in background
      final localNotifications = FlutterLocalNotificationsPlugin();
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'channel_sheets_monitor_bg',
        'Background Monitor',
        description: 'Background monitoring untuk perubahan data',
        importance: Importance.high,
      );
      await localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await localNotifications.initialize(
        const InitializationSettings(android: android),
      );
      // Check for updates in background
      await _backgroundCheckForUpdates(username, mmkv, localNotifications);
      debugPrint("Background task completed successfully");
      return Future.value(true);
    } catch (e) {
      debugPrint("Background task error: $e");
      return Future.value(false);
    }
  });
}

// Background update checker
Future<void> _backgroundCheckForUpdates(
  String username,
  MMKV mmkv,
  FlutterLocalNotificationsPlugin localNotifications,
) async {
  const sheetConfigs = [
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=1307491664',
      'name': 'Data Santri',
    },
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=2071598361',
      'name': 'Data Keuangan',
    },
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=2012044980',
      'name': 'Riwayat Transaksi',
    },
  ];
  for (var config in sheetConfigs) {
    try {
      final cacheKey = 'sheet_cache_${username}_${config['name']}';
      // Fetch new data
      final newData = await _backgroundFetchSheetData(config['url']!);
      if (newData.length < 2) continue;
      if (config['name'] == 'Riwayat Transaksi') {
        await _backgroundCheckTransactionUpdates(
          username: username,
          newData: newData,
          cacheKey: cacheKey,
          mmkv: mmkv,
          localNotifications: localNotifications,
        );
      } else {
        await _backgroundCheckRegularSheetUpdates(
          username: username,
          newData: newData,
          cacheKey: cacheKey,
          sheetName: config['name']!,
          mmkv: mmkv,
          localNotifications: localNotifications,
        );
      }
    } catch (e) {
      debugPrint('Background check error for ${config['name']}: $e');
    }
  }
  // Check SPP reminder
  await _backgroundCheckSPPReminder(username, mmkv, localNotifications);
}

Future<List<List<dynamic>>> _backgroundFetchSheetData(String url) async {
  try {
    final response = await http
        .get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp/1.0)',
            'Accept': 'text/csv,application/csv,text/plain,*/*',
            'Cache-Control': 'no-cache',
          },
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
      return const CsvToListConverter().convert(
        response.body,
        shouldParseNumbers: false,
      );
    }
  } catch (e) {
    debugPrint('Background fetch error: $e');
  }
  return [];
}

Future<void> _backgroundCheckTransactionUpdates({
  required String username,
  required List<List<dynamic>> newData,
  required String cacheKey,
  required MMKV mmkv,
  required FlutterLocalNotificationsPlugin localNotifications,
}) async {
  try {
    if (newData.length < 2) return;
    final headers = newData[0]
        .map((e) => e.toString().toLowerCase().trim())
        .toList();
    final nisnIndex = _backgroundFindColumnIndex(headers, ['nisn']);
    final kodeIndex = _backgroundFindColumnIndex(headers, [
      'kode transaksi',
      'kode_transaksi',
    ]);
    if (nisnIndex == -1 || kodeIndex == -1) return;
    // Get cached transaction IDs
    Set<String> knownTransactionIds = {};
    try {
      final cachedDataJson = mmkv.decodeString(cacheKey);
      if (cachedDataJson != null && cachedDataJson.isNotEmpty) {
        final cachedData = jsonDecode(cachedDataJson);
        final List<dynamic> cachedTransactions =
            cachedData['transactions'] ?? [];
        knownTransactionIds = cachedTransactions
            .map((e) => e.toString())
            .toSet();
      }
    } catch (e) {
      debugPrint('Error parsing cached transactions: $e');
    }
    // Find new transactions
    final newTransactions = <Map<String, String>>[];
    for (int i = 1; i < newData.length; i++) {
      final row = newData[i];
      if (row.length > nisnIndex &&
          _backgroundIsMatchingUser(
            username,
            row[nisnIndex]?.toString() ?? '',
          )) {
        final kode = row.length > kodeIndex ? row[kodeIndex]?.toString() : null;
        if (kode != null &&
            kode.isNotEmpty &&
            !knownTransactionIds.contains(kode)) {
          final saldoIndex = _backgroundFindColumnIndex(headers, [
            'sisa saldo',
            'sisa_saldo',
            'saldo',
          ]);
          final pemakaianIndex = _backgroundFindColumnIndex(headers, [
            'pemakaian',
            'jumlah',
            'nominal',
          ]);
          newTransactions.add({
            'kode': kode,
            'saldo': saldoIndex >= 0 && row.length > saldoIndex
                ? (row[saldoIndex]?.toString() ?? '0')
                : '0',
            'pemakaian': pemakaianIndex >= 0 && row.length > pemakaianIndex
                ? (row[pemakaianIndex]?.toString() ?? '0')
                : '0',
          });
        }
      }
    }
    // Send background notifications for new transactions
    for (var tx in newTransactions) {
      await _sendBackgroundNotification(
        localNotifications: localNotifications,
        title: 'Transaksi Baru',
        body:
            'Sisa Saldo: Rp${_backgroundFormatCurrency(tx['saldo']!)}\nPemakaian: Rp${_backgroundFormatCurrency(tx['pemakaian']!)}', // FIXED: Removed extra quote before closing parenthesis
        payload: 'transaction_${tx['kode']}',
      );
    }
    // Update cache if there are new transactions
    if (newTransactions.isNotEmpty) {
      final allTransactionIds = <String>[];
      for (int i = 1; i < newData.length; i++) {
        final row = newData[i];
        if (row.length > nisnIndex &&
            _backgroundIsMatchingUser(
              username,
              row[nisnIndex]?.toString() ?? '',
            )) {
          final kode = row.length > kodeIndex
              ? row[kodeIndex]?.toString()
              : null;
          if (kode != null && kode.isNotEmpty) {
            allTransactionIds.add(kode);
          }
        }
      }
      final updatedCacheData = {
        'url':
            'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=2012044980',
        'name': 'Riwayat Transaksi',
        'data': newData,
        'transactions': allTransactionIds,
        'lastUpdated': DateTime.now().toIso8601String(),
        'username': username,
      };
      mmkv.encodeString(cacheKey, jsonEncode(updatedCacheData));
    }
  } catch (e) {
    debugPrint('Background transaction check error: $e');
  }
}

Future<void> _backgroundCheckRegularSheetUpdates({
  required String username,
  required List<List<dynamic>> newData,
  required String cacheKey,
  required String sheetName,
  required MMKV mmkv,
  required FlutterLocalNotificationsPlugin localNotifications,
}) async {
  try {
    final cachedDataJson = mmkv.decodeString(cacheKey);
    if (cachedDataJson == null || cachedDataJson.isEmpty) {
      // Save initial cache
      final cacheData = {
        'name': sheetName,
        'data': newData,
        'lastUpdated': DateTime.now().toIso8601String(),
        'username': username,
      };
      mmkv.encodeString(cacheKey, jsonEncode(cacheData));
      return;
    }
    final cachedData = jsonDecode(cachedDataJson);
    final oldData = List<List<dynamic>>.from(cachedData['data']);
    final userOldData = _backgroundFindUserDataInSheet(oldData, username);
    final userNewData = _backgroundFindUserDataInSheet(newData, username);
    if (userOldData.isNotEmpty && userNewData.isNotEmpty) {
      final changes = _backgroundCompareUserData(userOldData, userNewData);
      if (changes.isNotEmpty) {
        await _sendBackgroundNotification(
          localNotifications: localNotifications,
          title: 'Perubahan $sheetName',
          body: _backgroundFormatChangesMessage(changes),
          payload: '${sheetName}_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    }
    // Update cache
    final updatedCacheData = {
      'name': sheetName,
      'data': newData,
      'lastUpdated': DateTime.now().toIso8601String(),
      'username': username,
    };
    mmkv.encodeString(cacheKey, jsonEncode(updatedCacheData));
  } catch (e) {
    debugPrint('Background regular sheet check error: $e');
  }
}

Future<void> _backgroundCheckSPPReminder(
  String username,
  MMKV mmkv,
  FlutterLocalNotificationsPlugin localNotifications,
) async {
  try {
    final now = DateTime.now();
    final day = now.day;
    // Check if in SPP reminder period (25-31 or 1-5)
    if (!((day >= 25) || (day <= 5))) return;
    // Check if already shown today
    final key = 'spp_notif_shown_$username';
    final lastShown = mmkv.decodeString(key);
    if (lastShown != null) {
      final lastDate = DateTime.tryParse(lastShown);
      if (lastDate?.year == now.year &&
          lastDate?.month == now.month &&
          lastDate?.day == now.day) {
        return; // Already shown today
      }
    }
    await _sendBackgroundNotification(
      localNotifications: localNotifications,
      title: 'Pengingat Pembayaran SPP',
      body:
          'Pemberitahuan Pembayaran SPP Pesantren Islam Zaid bin Tsabit paling lambat tanggal 5 setiap bulannya.',
      payload: 'spp_reminder',
    );
    // Mark as shown
    mmkv.encodeString(key, now.toIso8601String());
  } catch (e) {
    debugPrint('Background SPP reminder error: $e');
  }
}

Future<void> _sendBackgroundNotification({
  required FlutterLocalNotificationsPlugin localNotifications,
  required String title,
  required String body,
  String? payload,
}) async {
  try {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_sheets_monitor_bg',
          'Background Monitor',
          channelDescription: 'Background monitoring untuk perubahan data',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      2147483647,
    );
    await localNotifications.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  } catch (e) {
    debugPrint('Background notification error: $e');
  }
}

// Background helper functions
int _backgroundFindColumnIndex(
  List<String> headers,
  List<String> possibleNames,
) {
  for (final name in possibleNames) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      final searchName = name.toLowerCase().trim();
      if (header == searchName ||
          header.contains(searchName) ||
          searchName.contains(header)) {
        return i;
      }
    }
  }
  return -1;
}

bool _backgroundIsMatchingUser(String targetUsername, String csvValue) {
  if (targetUsername.isEmpty || csvValue.isEmpty) return false;
  final cleanTarget = targetUsername.toLowerCase().trim();
  final cleanCsv = csvValue.toLowerCase().trim();
  if (cleanTarget == cleanCsv) return true;
  final targetNumbers = cleanTarget.replaceAll(RegExp(r'[^0-9]'), '');
  final csvNumbers = cleanCsv.replaceAll(RegExp(r'[^0-9]'), '');
  return targetNumbers.isNotEmpty && targetNumbers == csvNumbers;
}

Map<String, dynamic> _backgroundFindUserDataInSheet(
  List<List<dynamic>> sheetData,
  String username,
) {
  if (sheetData.isEmpty || username.isEmpty) return {};
  try {
    final headers = sheetData[0]
        .map((e) => e.toString().toLowerCase().trim())
        .toList();
    final nisnIndex = _backgroundFindColumnIndex(headers, [
      'nisn',
      'username',
      'id',
      'student_id',
    ]);
    if (nisnIndex == -1) return {};
    for (int i = 1; i < sheetData.length; i++) {
      final row = sheetData[i];
      if (row.length > nisnIndex) {
        final csvNisn = row[nisnIndex]?.toString().trim() ?? '';
        if (_backgroundIsMatchingUser(username, csvNisn)) {
          return {
            'saldo': _backgroundGetFieldValue(row, headers, [
              'saldo',
              'balance',
            ], '0'),
            'status_izin': _backgroundGetFieldValue(row, headers, [
              'status_izin',
              'izin',
            ], ''),
            'jumlah_hafalan': _backgroundGetFieldValue(row, headers, [
              'hafalan',
              'memorization',
            ], ''),
            'absensi': _backgroundGetFieldValue(row, headers, [
              'absensi',
              'attendance',
            ], ''),
          };
        }
      }
    }
  } catch (e) {
    debugPrint('Background find user data error: $e');
  }
  return {};
}

String _backgroundGetFieldValue(
  List<dynamic> row,
  List<String> headers,
  List<String> fieldNames,
  String defaultValue,
) {
  final index = _backgroundFindColumnIndex(headers, fieldNames);
  if (index >= 0 && index < row.length) {
    final value = row[index]?.toString().trim() ?? '';
    return value.isNotEmpty ? value : defaultValue;
  }
  return defaultValue;
}

Map<String, dynamic> _backgroundCompareUserData(
  Map<String, dynamic> oldData,
  Map<String, dynamic> newData,
) {
  Map<String, dynamic> changes = {};
  List<Map<String, dynamic>> fieldChanges = [];
  const fieldNames = {
    'saldo': 'Saldo',
    'status_izin': 'Status Perizinan',
    'jumlah_hafalan': 'Jumlah Hafalan',
    'absensi': 'Absensi',
  };
  for (final entry in fieldNames.entries) {
    final fieldKey = entry.key;
    final fieldName = entry.value;
    final oldValue = oldData[fieldKey]?.toString().trim() ?? '';
    final newValue = newData[fieldKey]?.toString().trim() ?? '';
    if (oldValue != newValue && (oldValue.isNotEmpty || newValue.isNotEmpty)) {
      fieldChanges.add({
        'field': fieldKey,
        'fieldName': fieldName,
        'oldValue': oldValue,
        'newValue': newValue,
      });
    }
  }
  if (fieldChanges.isNotEmpty) {
    changes['fields'] = fieldChanges;
  }
  return changes;
}

String _backgroundFormatChangesMessage(Map<String, dynamic> changes) {
  List<String> messages = [];
  if (changes.containsKey('fields')) {
    final fieldChanges = changes['fields'] as List;
    for (var change in fieldChanges.take(2)) {
      final fieldName = change['fieldName'] ?? 'Field';
      final oldValue = change['oldValue'] ?? '';
      final newValue = change['newValue'] ?? '';
      if (oldValue.isEmpty) {
        messages.add('$fieldName: $newValue (ditambahkan)');
      } else if (newValue.isEmpty) {
        messages.add('$fieldName: dihapus');
      } else {
        messages.add('$fieldName: $oldValue → $newValue');
      }
    }
    if (fieldChanges.length > 2) {
      messages.add('dan ${fieldChanges.length - 2} perubahan lainnya');
    }
  }
  return messages.isNotEmpty ? messages.join('\n') : 'Data telah berubah';
}

String _backgroundFormatCurrency(String value) {
  if (value.isEmpty) return '0';
  try {
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    final number = int.tryParse(cleanValue) ?? 0;
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  } catch (e) {
    return value;
  }
}

// Model untuk notifikasi yang terintegrasi
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String sheetName;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> changes;
  final String username;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.sheetName,
    required this.timestamp,
    this.isRead = false,
    required this.changes,
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'sheetName': sheetName,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'changes': changes,
      'username': username,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      sheetName: json['sheetName'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      changes: Map<String, dynamic>.from(json['changes'] ?? {}),
      username: json['username'] ?? '',
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      sheetName: sheetName,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      changes: changes,
      username: username,
    );
  }
}

// Enhanced Google Sheets Monitor Service dengan background support
class GoogleSheetsMonitorService {
  static FlutterLocalNotificationsPlugin? _localNotificationPlugin;
  static MMKV? _mmkv;
  static Timer? _monitoringTimer;
  static final Map<String, ValueNotifier<List<NotificationItem>>>
  _userNotifications = {};
  static bool _isInitialized = false;
  static final Map<String, bool> _userInitialized = {};
  static const String _sppNotificationId = 'spp_reminder_notification';
  static const String _sppSheetName = 'Pemberitahuan SPP';

  // Initialize background tasks
  static Future<void> initializeBackgroundTasks() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      debugPrint('Background tasks initialized');
    } catch (e) {
      debugPrint('Background task initialization error: $e');
    }
  }

  // Start background monitoring for user
  static Future<void> startBackgroundMonitoring(String username) async {
    if (username.isEmpty) return;
    try {
      // Cancel any existing background tasks for this user
      await Workmanager().cancelByUniqueName('monitor_$username');
      // Register new periodic task
      await Workmanager().registerPeriodicTask(
        'monitor_$username',
        'checkUpdatesTask',
        inputData: {'username': username},
        frequency: const Duration(minutes: 15), // Android minimum is 15 minutes
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      debugPrint('Background monitoring started for user: $username');
    } catch (e) {
      debugPrint('Error starting background monitoring for $username: $e');
    }
  }

  // Stop background monitoring for user
  static Future<void> stopBackgroundMonitoring(String username) async {
    if (username.isEmpty) return;
    try {
      await Workmanager().cancelByUniqueName('monitor_$username');
      debugPrint('Background monitoring stopped for user: $username');
    } catch (e) {
      debugPrint('Error stopping background monitoring for $username: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    if (_localNotificationPlugin != null) return;
    _localNotificationPlugin = FlutterLocalNotificationsPlugin();
    // Create notification channels
    const AndroidNotificationChannel foregroundChannel =
        AndroidNotificationChannel(
          'channel_sheets_monitor',
          'Google Sheets Monitor',
          description: 'Notifikasi untuk perubahan data dan pengingat SPP',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );
    const AndroidNotificationChannel backgroundChannel =
        AndroidNotificationChannel(
          'channel_sheets_monitor_bg',
          'Background Monitor',
          description: 'Background monitoring untuk perubahan data',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );
    final androidPlugin = _localNotificationPlugin
        ?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(foregroundChannel);
    await androidPlugin?.createNotificationChannel(backgroundChannel);
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const DarwinInitializationSettings ios = DarwinInitializationSettings();
    await _localNotificationPlugin!.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        // Handle notification tap - you can add navigation logic here
      },
    );
  }

  // Check if in SPP reminder period
  static bool _isInSPPReminderPeriod() {
    final now = DateTime.now();
    final day = now.day;
    return (day >= 25) || (day <= 5);
  }

  // Check if SPP notification shown today
  static bool _hasShownSPPNotificationToday(String username) {
    if (_mmkv == null) return true;
    final key = 'spp_notif_shown_$username';
    final lastShown = _mmkv!.decodeString(key);
    if (lastShown == null) return false;
    try {
      final lastDate = DateTime.tryParse(lastShown);
      final now = DateTime.now();
      return lastDate?.year == now.year &&
          lastDate?.month == now.month &&
          lastDate?.day == now.day;
    } catch (e) {
      return false;
    }
  }

  static void _markSPPNotificationShown(String username) {
    if (_mmkv == null) return;
    final key = 'spp_notif_shown_$username';
    _mmkv!.encodeString(key, DateTime.now().toIso8601String());
  }

  static Future<void> _checkSPPReminderForUser(String username) async {
    if (username.isEmpty || _mmkv == null) return;
    if (!_isInSPPReminderPeriod()) {
      final key = 'spp_notif_shown_$username';
      if (_mmkv!.containsKey(key)) {
        _mmkv!.removeValue(key);
      }
      return;
    }
    if (_hasShownSPPNotificationToday(username)) {
      return;
    }
    final notification = NotificationItem(
      id: '${_sppNotificationId}_$username',
      title: 'Pengingat Pembayaran SPP',
      message:
          'Pemberitahuan Pembayaran SPP Pesantren Islam Zaid bin Tsabit paling lambat tanggal 5 setiap bulannya. Saat ini memasuki awal bulan, Wali santri dihimbau untuk segera melakukan pembayaran Kewajiban SPP.',
      sheetName: _sppSheetName,
      timestamp: DateTime.now(),
      changes: {'type': 'reminder', 'category': 'spp_payment'},
      username: username,
    );
    await _addNotificationForUser(username, notification);
    _markSPPNotificationShown(username);
    debugPrint('SPP reminder notification added for $username');
  }

  // Display local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _initializeLocalNotifications();
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'channel_sheets_monitor',
            'Google Sheets Monitor',
            channelDescription:
                'Notifikasi untuk perubahan data dan pengingat SPP',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        2147483647,
      );
      await _localNotificationPlugin?.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }

  // Sheet configurations
  static const List<Map<String, String>> _sheetConfigs = [
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=1307491664',
      'name': 'Data Santri',
    },
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=2071598361',
      'name': 'Data Keuangan',
    },
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=1620978739',
      'name': 'Data Akademik',
    },
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv&gid=290556271',
      'name': 'Data SPP',
    },
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv&gid=1521495544',
      'name': 'Data Ekskul',
    },
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv&gid=1122446293',
      'name': 'Data Uang Pangkal',
    },
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=2012044980',
      'name': 'Riwayat Transaksi',
    },
  ];

  // Field mapping
  static const Map<String, String> _fieldNames = {
    'saldo': 'Saldo',
    'status_izin': 'Status Perizinan',
    'jumlah_hafalan': 'Jumlah Hafalan',
    'absensi': 'Absensi',
    'poin_pelanggaran': 'Poin Pelanggaran',
    'reward': 'Reward',
    'lembaga': 'Lembaga',
    'izin_terakhir': 'Izin Terakhir',
    'nama': 'Nama',
    'kelas': 'Kelas',
    'asrama': 'Asrama',
  };

  // Initialize global MMKV
  static Future<void> _initializeMMKV() async {
    if (_mmkv != null) return;
    try {
      await MMKV.initialize();
      _mmkv = MMKV.defaultMMKV();
      _isInitialized = true;
      debugPrint('MMKV initialized');
    } catch (e) {
      debugPrint('MMKV init failed: $e');
      throw Exception('MMKV initialization failed');
    }
  }

  // Initialize for specific user
  static Future<void> initializeForUser(String username) async {
    if (username.isEmpty) {
      debugPrint('Username is empty, cannot initialize monitoring');
      return;
    }
    try {
      // Initialize background tasks first
      await initializeBackgroundTasks();
      // Initialize MMKV
      await _initializeMMKV();
      // Initialize notifications
      await _initializeLocalNotifications();
      // Skip if already initialized for this user
      if (_userInitialized[username] == true) {
        debugPrint('Already initialized for user: $username');
        return;
      }
      // Create notifier for this user if not exists
      if (!_userNotifications.containsKey(username)) {
        _userNotifications[username] = ValueNotifier<List<NotificationItem>>(
          [],
        );
      }
      // Load existing notifications first
      await _loadUserNotifications(username);
      // Load initial cache
      await _loadInitialCacheForUser(username);
      // Start foreground monitoring
      _startMonitoringForUser(username);
      // Start background monitoring
      await startBackgroundMonitoring(username);
      _userInitialized[username] = true;
      debugPrint('GoogleSheetsMonitorService initialized for user: $username');
    } catch (e) {
      debugPrint(
        'Error initializing GoogleSheetsMonitorService for $username: $e',
      );
      _userInitialized[username] = false;
    }
  }

  // Get notifier for specific user
  static ValueNotifier<List<NotificationItem>>? getNotificationsForUser(
    String username,
  ) {
    return _userNotifications[username];
  }

  // Load initial cache for specific user with better error handling
  static Future<void> _loadInitialCacheForUser(String username) async {
    if (_mmkv == null || username.isEmpty) return;
    for (var config in _sheetConfigs) {
      try {
        final cacheKey = 'sheet_cache_${username}_${config['name']}';
        final existingCache = _mmkv!.decodeString(cacheKey);
        if (existingCache == null || existingCache.isEmpty) {
          debugPrint('Loading initial cache for ${config['name']} - $username');
          final data = await _fetchSheetData(config['url']!, retryCount: 3);
          if (data.isEmpty) {
            debugPrint('No data received for ${config['name']}');
            continue;
          }
          List<List<dynamic>> userData = data;
          if (config['name'] == 'Riwayat Transaksi') {
            userData = data.where((row) {
              if (row.length <= 1) return false;
              final headers = data[0]
                  .map((e) => e.toString().toLowerCase())
                  .toList();
              final nisnIndex = _findColumnIndex(headers, ['nisn']);
              if (nisnIndex == -1 || row.length <= nisnIndex) return false;
              final csvNisn = row[nisnIndex]?.toString().trim() ?? '';
              return _isMatchingUser(username, csvNisn);
            }).toList();
          }
          final cacheData = <String, dynamic>{
            'url': config['url'],
            'name': config['name'],
            'data': userData,
            'lastUpdated': DateTime.now().toIso8601String(),
            'username': username,
          };
          if (config['name'] == 'Riwayat Transaksi') {
            final userTransactionIds = _extractUserTransactionIds(
              userData,
              username,
            );
            cacheData['transactions'] = userTransactionIds;
            debugPrint(
              'Found ${userTransactionIds.length} existing transactions for $username',
            );
          }
          final encoded = jsonEncode(cacheData);
          _mmkv!.encodeString(cacheKey, encoded);
          debugPrint('Initial cache saved for ${config['name']} - $username');
        } else {
          debugPrint('Cache already exists for ${config['name']} - $username');
        }
      } catch (e, stack) {
        debugPrint(
          'Error loading initial cache for ${config['name']}: $e\n$stack',
        );
      }
    }
  }

  // Helper function to extract user transaction IDs
  static List<String> _extractUserTransactionIds(
    List<List<dynamic>> data,
    String username,
  ) {
    if (data.length < 2) return [];
    try {
      final headers = data[0]
          .map((e) => e.toString().toLowerCase().trim())
          .toList();
      final nisnIndex = _findColumnIndex(headers, ['nisn']);
      final kodeIndex = _findColumnIndex(headers, [
        'kode transaksi',
        'kode_transaksi',
      ]);
      if (nisnIndex == -1 || kodeIndex == -1) return [];
      final userTransactionIds = <String>[];
      for (int i = 1; i < data.length; i++) {
        final row = data[i];
        if (row.length > nisnIndex &&
            _isMatchingUser(username, row[nisnIndex]?.toString() ?? '')) {
          final kode = row.length > kodeIndex
              ? row[kodeIndex]?.toString()
              : null;
          if (kode != null && kode.isNotEmpty) {
            userTransactionIds.add(kode);
          }
        }
      }
      return userTransactionIds;
    } catch (e) {
      debugPrint('Error extracting transaction IDs: $e');
      return [];
    }
  }

  // Fetch data from Google Sheets with retry mechanism
  static Future<List<List<dynamic>>> _fetchSheetData(
    String url, {
    int retryCount = 3,
  }) async {
    for (int attempt = 1; attempt <= retryCount; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp/1.0)',
                'Accept': 'text/csv,application/csv,text/plain,*/*',
                'Cache-Control': 'no-cache',
              },
            )
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          if (response.body.trim().isEmpty) {
            throw Exception('Empty response body');
          }
          final List<List<dynamic>> rows = const CsvToListConverter().convert(
            response.body,
            shouldParseNumbers: false,
          );
          if (rows.isEmpty) {
            throw Exception('No data rows found');
          }
          return rows;
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        debugPrint('Attempt $attempt failed to fetch data: $e');
        if (attempt == retryCount) {
          throw Exception(
            'Failed to fetch data after $retryCount attempts: $e',
          );
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return [];
  }

  // Start monitoring for specific user
  static void _startMonitoringForUser(
    String username, {
    Duration interval = const Duration(minutes: 3),
  }) {
    if (_monitoringTimer != null) return; // Avoid duplication
    void startTimer() {
      _monitoringTimer = Timer(interval, () async {
        try {
          final activeUsers = _userNotifications.keys.toList();
          for (var u in activeUsers) {
            if (_userInitialized[u] == true) {
              await _checkForUpdatesForUser(u);
            }
          }
        } catch (e) {
          debugPrint('Error in monitoring: $e');
        } finally {
          if (_userNotifications.isNotEmpty) {
            startTimer(); // Restart timer after completion
          }
        }
      });
    }

    startTimer();
  }

  // Check transaction updates with better handling
  static Future<void> _checkTransactionUpdates({
    required String username,
    required List<List<dynamic>> newData,
    required String cacheKey,
  }) async {
    try {
      if (newData.length < 2) {
        debugPrint('Insufficient transaction data for $username');
        return;
      }
      final headers = newData[0]
          .map((e) => e.toString().toLowerCase().trim())
          .toList();
      final nisnIndex = _findColumnIndex(headers, ['nisn']);
      final kodeIndex = _findColumnIndex(headers, [
        'kode transaksi',
        'kode_transaksi',
      ]);
      final namaIndex = _findColumnIndex(headers, [
        'nama santri',
        'nama_santri',
        'nama',
      ]);
      final saldoIndex = _findColumnIndex(headers, [
        'sisa saldo',
        'sisa_saldo',
        'saldo',
      ]);
      final pemakaianIndex = _findColumnIndex(headers, [
        'pemakaian',
        'jumlah',
        'nominal',
      ]);
      final waktuIndex = _findColumnIndex(headers, [
        'timestamp',
        'waktu',
        'tanggal',
      ]);
      if (nisnIndex == -1 || kodeIndex == -1) {
        debugPrint('Required columns not found for transaction monitoring');
        return;
      }
      // Filter user transactions
      final userTransactions = <Map<String, String>>[];
      for (int i = 1; i < newData.length; i++) {
        final row = newData[i];
        if (row.length > nisnIndex &&
            _isMatchingUser(username, row[nisnIndex]?.toString() ?? '')) {
          userTransactions.add({
            'kode': row.length > kodeIndex
                ? (row[kodeIndex]?.toString() ?? '')
                : '',
            'nama': namaIndex >= 0 && row.length > namaIndex
                ? (row[namaIndex]?.toString() ?? '')
                : username,
            'saldo': saldoIndex >= 0 && row.length > saldoIndex
                ? (row[saldoIndex]?.toString() ?? '0')
                : '0',
            'pemakaian': pemakaianIndex >= 0 && row.length > pemakaianIndex
                ? (row[pemakaianIndex]?.toString() ?? '0')
                : '0',
            'waktu': waktuIndex >= 0 && row.length > waktuIndex
                ? (row[waktuIndex]?.toString() ?? '')
                : (row.length > 0 ? row[0]?.toString() ?? '' : ''),
          });
        }
      }
      if (userTransactions.isEmpty) {
        debugPrint('No transactions found for user: $username');
        return;
      }
      // Get last transaction cache
      Set<String> knownTransactionIds = {};
      try {
        final cachedDataJson = _mmkv!.decodeString(cacheKey);
        if (cachedDataJson != null && cachedDataJson.isNotEmpty) {
          final cachedData = jsonDecode(cachedDataJson);
          final List<dynamic> cachedTransactions =
              cachedData['transactions'] ?? [];
          knownTransactionIds = cachedTransactions
              .map((e) => e.toString())
              .toSet();
        }
      } catch (e) {
        debugPrint('Failed to parse transaction cache: $e');
      }
      // Find new transactions
      final newTransactions = userTransactions
          .where(
            (tx) =>
                tx['kode']!.isNotEmpty &&
                !knownTransactionIds.contains(tx['kode']),
          )
          .toList();
      debugPrint(
        'Found ${newTransactions.length} new transactions for $username',
      );
      if (newTransactions.isNotEmpty) {
        for (var tx in newTransactions) {
          final kode = tx['kode']!;
          final nominalStr = tx['pemakaian']!; // Contoh: "Rp50.000"
          final saldoAwalStr = tx['saldo']!; // Contoh: "Rp150.000"
          final waktu = tx['waktu']!;

          // Bersihkan string dari 'Rp' dan titik ribuan, lalu ubah ke integer
          int cleanNominal =
              int.tryParse(nominalStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          int cleanSaldoAwal =
              int.tryParse(saldoAwalStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

          // Hitung sisa saldo
          int sisaSaldo = cleanSaldoAwal - cleanNominal;

          // Format kembali ke format mata uang
          String formattedSisaSaldo = _formatCurrency(sisaSaldo.toString());

          final notification = NotificationItem(
            id: 'trans_${kode}_${username}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Transaksi Baru',
            message:
                'Saldo Awal: Rp${_formatCurrency(cleanSaldoAwal.toString())}\n'
                'Pemakaian: Rp${_formatCurrency(cleanNominal.toString())}\n'
                'Sisa Saldo: $formattedSisaSaldo\n' // ✅ Baris baru yang ditambahkan
                'Waktu: $waktu',
            sheetName: 'Riwayat Transaksi',
            timestamp: DateTime.now(),
            changes: {
              'type': 'transaction',
              'amount': nominalStr,
              'balance': saldoAwalStr,
              'remaining_balance':
                  formattedSisaSaldo, // ✅ Tambahkan ke data perubahan
              'time': waktu,
              'code': kode,
            },
            username: username,
          );
          await _addNotificationForUser(username, notification);
        }
      }
      // Update cache with all transaction IDs
      final allTransactionIds = userTransactions
          .where((tx) => tx['kode']!.isNotEmpty)
          .map((tx) => tx['kode']!)
          .toSet()
          .toList();
      final updatedCacheData = {
        'url':
            'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=2012044980',
        'name': 'Riwayat Transaksi',
        'data': newData,
        'transactions': allTransactionIds,
        'lastUpdated': DateTime.now().toIso8601String(),
        'username': username,
      };
      _mmkv!.encodeString(cacheKey, jsonEncode(updatedCacheData));
      debugPrint('Transaction cache updated for $username');
    } catch (e) {
      debugPrint('Error checking transaction updates: $e');
    }
  }

  // Format currency with null safety handling
  static String _formatCurrency(String value) {
    if (value.isEmpty) return '0';
    try {
      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
      final number = int.tryParse(cleanValue) ?? 0;
      return number
          .toStringAsFixed(0)
          .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
    } catch (e) {
      return value;
    }
  }

  // Check changes for specific user with better error handling
  static Future<void> _checkForUpdatesForUser(String username) async {
    if (_mmkv == null || username.isEmpty) return;
    debugPrint('Checking updates for user: $username');
    for (var config in _sheetConfigs) {
      try {
        final cacheKey = 'sheet_cache_${username}_${config['name']}';
        // Fetch new data
        final newData = await _fetchSheetData(config['url']!);
        if (newData.length < 2) {
          debugPrint('Insufficient data for ${config['name']}');
          continue;
        }
        if (config['name'] == 'Riwayat Transaksi') {
          await _checkTransactionUpdates(
            username: username,
            newData: newData,
            cacheKey: cacheKey,
          );
        } else {
          // Handle other sheet types
          await _checkRegularSheetUpdates(
            username: username,
            newData: newData,
            cacheKey: cacheKey,
            sheetConfig: config,
          );
        }
      } catch (e) {
        debugPrint('Error checking updates for ${config['name']}: $e');
      }
    }
    await _checkSPPReminderForUser(username);
  }

  // Check regular sheet updates (non-transaction)
  static Future<void> _checkRegularSheetUpdates({
    required String username,
    required List<List<dynamic>> newData,
    required String cacheKey,
    required Map<String, String> sheetConfig,
  }) async {
    try {
      final cachedDataJson = _mmkv!.decodeString(cacheKey);
      if (cachedDataJson == null || cachedDataJson.isEmpty) {
        // No cache, save current data and return
        final cacheData = {
          'url': sheetConfig['url'],
          'name': sheetConfig['name'],
          'data': newData,
          'lastUpdated': DateTime.now().toIso8601String(),
          'username': username,
        };
        _mmkv!.encodeString(cacheKey, jsonEncode(cacheData));
        debugPrint(
          'Initial cache created for ${sheetConfig['name']} - $username',
        );
        return;
      }
      final cachedData = jsonDecode(cachedDataJson);
      final oldData = List<List<dynamic>>.from(cachedData['data']);
      final userOldData = _findUserDataInSheet(oldData, username);
      final userNewData = _findUserDataInSheet(newData, username);
      if (userOldData.isNotEmpty && userNewData.isNotEmpty) {
        final changes = _compareUserData(userOldData, userNewData);
        if (changes.isNotEmpty) {
          final notification = NotificationItem(
            id: '${sheetConfig['name']}_${DateTime.now().millisecondsSinceEpoch}_$username',
            title: 'Perubahan ${sheetConfig['name']}',
            message: _formatUserChangesMessage(changes),
            sheetName: sheetConfig['name']!,
            timestamp: DateTime.now(),
            changes: changes,
            username: username,
          );
          await _addNotificationForUser(username, notification);
          debugPrint('Added notification for ${sheetConfig['name']} changes');
        }
      }
      // Update cache
      final updatedCacheData = {
        'url': sheetConfig['url'],
        'name': sheetConfig['name'],
        'data': newData,
        'lastUpdated': DateTime.now().toIso8601String(),
        'username': username,
      };
      _mmkv!.encodeString(cacheKey, jsonEncode(updatedCacheData));
    } catch (e) {
      debugPrint('Error checking regular sheet updates: $e');
    }
  }

  // Find user data in sheet with error handling
  static Map<String, dynamic> _findUserDataInSheet(
    List<List<dynamic>> sheetData,
    String username,
  ) {
    if (sheetData.isEmpty || username.isEmpty) return {};
    try {
      final headers = sheetData[0]
          .map((e) => e.toString().toLowerCase().trim())
          .toList();
      final nisnIndex = _findColumnIndex(headers, [
        'nisn',
        'username',
        'id',
        'student_id',
      ]);
      if (nisnIndex == -1) {
        debugPrint('No NISN column found in sheet');
        return {};
      }
      for (int i = 1; i < sheetData.length; i++) {
        final row = sheetData[i];
        if (row.length > nisnIndex) {
          final csvNisn = row[nisnIndex]?.toString().trim() ?? '';
          if (_isMatchingUser(username, csvNisn)) {
            return _extractUserData(row, headers);
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding user data: $e');
    }
    return {};
  }

  // Helper functions
  static int _findColumnIndex(
    List<String> headers,
    List<String> possibleNames,
  ) {
    for (final name in possibleNames) {
      for (int i = 0; i < headers.length; i++) {
        final header = headers[i].toLowerCase().trim();
        final searchName = name.toLowerCase().trim();
        if (header == searchName ||
            header.contains(searchName) ||
            searchName.contains(header)) {
          return i;
        }
      }
    }
    return -1;
  }

  static bool _isMatchingUser(String targetUsername, String csvValue) {
    if (targetUsername.isEmpty || csvValue.isEmpty) return false;
    final cleanTarget = targetUsername.toLowerCase().trim();
    final cleanCsv = csvValue.toLowerCase().trim();
    if (cleanTarget == cleanCsv) return true;
    final targetNumbers = cleanTarget.replaceAll(RegExp(r'[^0-9]'), '');
    final csvNumbers = cleanCsv.replaceAll(RegExp(r'[^0-9]'), '');
    return targetNumbers.isNotEmpty && targetNumbers == csvNumbers;
  }

  static Map<String, dynamic> _extractUserData(
    List<dynamic> row,
    List<String> headers,
  ) {
    return {
      'nama': _getFieldValue(row, headers, ['nama', 'name'], ''),
      'saldo': _getFieldValue(row, headers, ['saldo', 'balance'], '0'),
      'kelas': _getFieldValue(row, headers, ['kelas', 'class'], ''),
      'asrama': _getFieldValue(row, headers, ['asrama', 'dormitory'], ''),
      'status_izin': _getFieldValue(row, headers, ['status_izin', 'izin'], ''),
      'jumlah_hafalan': _getFieldValue(row, headers, [
        'hafalan',
        'memorization',
      ], ''),
      'absensi': _getFieldValue(row, headers, ['absensi', 'attendance'], ''),
      'poin_pelanggaran': _getFieldValue(row, headers, [
        'poin',
        'penalty',
      ], '0'),
      'reward': _getFieldValue(row, headers, ['reward', 'bonus'], '0'),
      'lembaga': _getFieldValue(row, headers, ['lembaga', 'institution'], ''),
      'izin_terakhir': _getFieldValue(row, headers, [
        'izin_terakhir',
        'last_permission',
      ], ''),
    };
  }

  static String _getFieldValue(
    List<dynamic> row,
    List<String> headers,
    List<String> fieldNames,
    String defaultValue,
  ) {
    final index = _findColumnIndex(headers, fieldNames);
    if (index >= 0 && index < row.length) {
      final value = row[index]?.toString().trim() ?? '';
      return value.isNotEmpty ? value : defaultValue;
    }
    return defaultValue;
  }

  // Compare user data with better handling
  static Map<String, dynamic> _compareUserData(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    Map<String, dynamic> changes = {};
    List<Map<String, dynamic>> fieldChanges = [];
    for (final entry in _fieldNames.entries) {
      final fieldKey = entry.key;
      final fieldName = entry.value;
      final oldValue = oldData[fieldKey]?.toString().trim() ?? '';
      final newValue = newData[fieldKey]?.toString().trim() ?? '';
      if (oldValue == newValue) continue;
      if (oldValue.isNotEmpty || newValue.isNotEmpty) {
        fieldChanges.add({
          'field': fieldKey,
          'fieldName': fieldName,
          'oldValue': oldValue,
          'newValue': newValue,
          'changeType': oldValue.isEmpty
              ? 'added'
              : (newValue.isEmpty ? 'removed' : 'modified'),
        });
      }
    }
    if (fieldChanges.isNotEmpty) {
      changes['fields'] = fieldChanges;
    }
    return changes;
  }

  // Format change messages with better handling
  static String _formatUserChangesMessage(Map<String, dynamic> changes) {
    List<String> messages = [];
    if (changes.containsKey('fields')) {
      final fieldChanges = changes['fields'] as List;
      for (var change in fieldChanges.take(3)) {
        final fieldName = change['fieldName'] ?? 'Field';
        final oldValue = change['oldValue'] ?? '';
        final newValue = change['newValue'] ?? '';
        final changeType = change['changeType'] ?? 'modified';
        switch (changeType) {
          case 'added':
            messages.add('$fieldName: $newValue (ditambahkan)');
            break;
          case 'removed':
            messages.add('$fieldName: dihapus');
            break;
          default:
            messages.add('$fieldName: $oldValue → $newValue');
        }
      }
      if (fieldChanges.length > 3) {
        messages.add('dan ${fieldChanges.length - 3} perubahan lainnya');
      }
    } else if (changes.containsKey('type') &&
        changes['type'] == 'transaction') {
      final amount = changes['amount'] ?? '0';
      final balance = changes['balance'] ?? '0';
      return 'Pemakaian: Rp${_formatCurrency(amount)} • Sisa: Rp${_formatCurrency(balance)}';
    }
    return messages.isNotEmpty ? messages.join('\n') : 'Data telah berubah';
  }

  // Add notification for user with deduplication
  static Future<void> _addNotificationForUser(
    String username,
    NotificationItem notification,
  ) async {
    if (!_userNotifications.containsKey(username)) {
      debugPrint('No notification notifier found for user: $username');
      return;
    }
    try {
      final currentNotifications = List<NotificationItem>.from(
        _userNotifications[username]!.value,
      );
      // Check for duplicates
      final now = DateTime.now();
      final isDuplicate = currentNotifications.any((existing) {
        final timeDiff = now.difference(existing.timestamp).inMinutes;
        return timeDiff <= 1 &&
            existing.title == notification.title &&
            existing.message == notification.message;
      });
      if (!isDuplicate) {
        currentNotifications.insert(0, notification);
        if (currentNotifications.length > 100) {
          currentNotifications.removeRange(100, currentNotifications.length);
        }
        _userNotifications[username]!.value = currentNotifications;
        await _saveUserNotifications(username);
        debugPrint('Added notification for $username: ${notification.title}');
        // Send local notification
        await _showLocalNotification(
          title: notification.title,
          body: notification.message,
          payload: notification.id,
        );
      } else {
        debugPrint('Duplicate notification skipped for $username');
      }
    } catch (e) {
      debugPrint('Error adding notification for user $username: $e');
    }
  }

  // Load user notifications from MMKV with error handling
  static Future<void> _loadUserNotifications(String username) async {
    if (_mmkv == null || username.isEmpty) return;
    try {
      final notificationsKey = 'notifications_enhanced_$username';
      final notificationsJson = _mmkv!.decodeString(notificationsKey);
      if (notificationsJson != null && notificationsJson.isNotEmpty) {
        final notificationsList = jsonDecode(notificationsJson) as List;
        final notifications = notificationsList
            .map((n) {
              try {
                return NotificationItem.fromJson(Map<String, dynamic>.from(n));
              } catch (e) {
                debugPrint('Error parsing notification: $e');
                return null;
              }
            })
            .where((n) => n != null)
            .cast<NotificationItem>()
            .toList();
        if (_userNotifications.containsKey(username)) {
          _userNotifications[username]!.value = notifications;
          debugPrint(
            'Loaded ${notifications.length} notifications for $username',
          );
        }
      } else {
        debugPrint('No existing notifications found for $username');
      }
    } catch (e) {
      debugPrint('Error loading user notifications for $username: $e');
      if (_userNotifications.containsKey(username)) {
        _userNotifications[username]!.value = [];
      }
    }
  }

  // Save user notifications to MMKV with error handling
  static Future<void> _saveUserNotifications(String username) async {
    if (_mmkv == null ||
        !_userNotifications.containsKey(username) ||
        username.isEmpty)
      return;
    try {
      final notificationsKey = 'notifications_enhanced_$username';
      final notifications = _userNotifications[username]!.value;
      if (notifications.isNotEmpty) {
        final notificationsJson = notifications.map((n) => n.toJson()).toList();
        _mmkv!.encodeString(notificationsKey, jsonEncode(notificationsJson));
        debugPrint('Saved ${notifications.length} notifications for $username');
      } else {
        if (_mmkv!.containsKey(notificationsKey)) {
          _mmkv!.removeValue(notificationsKey);
        }
        debugPrint('Cleared empty notifications for $username');
      }
    } catch (e) {
      debugPrint('Error saving user notifications for $username: $e');
    }
  }

  // Mark notification as read
  static Future<void> markAsReadForUser(
    String username,
    String notificationId,
  ) async {
    if (!_userNotifications.containsKey(username) || username.isEmpty) return;
    try {
      final currentNotifications = List<NotificationItem>.from(
        _userNotifications[username]!.value,
      );
      final index = currentNotifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (index != -1) {
        currentNotifications[index] = currentNotifications[index].copyWith(
          isRead: true,
        );
        _userNotifications[username]!.value = currentNotifications;
        await _saveUserNotifications(username);
        debugPrint('Marked notification as read: $notificationId');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsReadForUser(String username) async {
    if (!_userNotifications.containsKey(username) || username.isEmpty) return;
    try {
      final currentNotifications = _userNotifications[username]!.value
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _userNotifications[username]!.value = currentNotifications;
      await _saveUserNotifications(username);
      debugPrint('Marked all notifications as read for $username');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Clear all notifications for user
  static Future<void> clearAllNotificationsForUser(String username) async {
    if (!_userNotifications.containsKey(username) || username.isEmpty) return;
    try {
      _userNotifications[username]!.value = [];
      await _saveUserNotifications(username);
      debugPrint('Cleared all notifications for $username');
    } catch (e) {
      debugPrint('Error clearing notifications for $username: $e');
    }
  }

  // Get unread count for user
  static int getUnreadCountForUser(String username) {
    if (!_userNotifications.containsKey(username) || username.isEmpty) return 0;
    return _userNotifications[username]!.value.where((n) => !n.isRead).length;
  }

  // Get total count for user
  static int getTotalCountForUser(String username) {
    if (!_userNotifications.containsKey(username) || username.isEmpty) return 0;
    return _userNotifications[username]!.value.length;
  }

  // Force check for specific user
  static Future<void> forceCheckForUser(
    String username, {
    VoidCallback? onComplete,
  }) async {
    if (username.isEmpty) return;
    debugPrint('Force checking updates for user: $username');
    try {
      await _checkForUpdatesForUser(username);
      debugPrint('Force check completed for $username');
    } catch (e) {
      debugPrint('Error in force check for $username: $e');
    }
    onComplete?.call();
  }

  // Stop monitoring for specific user
  static void stopMonitoringForUser(String username) {
    if (username.isEmpty) return;
    _userNotifications.remove(username);
    _userInitialized.remove(username);
    debugPrint('Stopped monitoring for user: $username');
    if (_userNotifications.isEmpty) {
      _monitoringTimer?.cancel();
      _monitoringTimer = null;
      debugPrint('Stopped monitoring timer - no active users');
    }
  }

  // Cleanup for specific user
  static Future<void> cleanupForUser(String username) async {
    if (username.isEmpty) return;
    try {
      stopMonitoringForUser(username);
      // Stop background monitoring
      await stopBackgroundMonitoring(username);
      // Remove cache sheets for this user
      if (_mmkv != null) {
        for (var config in _sheetConfigs) {
          final cacheKey = 'sheet_cache_${username}_${config['name']}';
          if (_mmkv!.containsKey(cacheKey)) {
            _mmkv!.removeValue(cacheKey);
          }
        }
        // Remove notifications
        final notificationsKey = 'notifications_enhanced_$username';
        if (_mmkv!.containsKey(notificationsKey)) {
          _mmkv!.removeValue(notificationsKey);
        }
        // Remove SPP notification tracking
        final sppKey = 'spp_notif_shown_$username';
        if (_mmkv!.containsKey(sppKey)) {
          _mmkv!.removeValue(sppKey);
        }
      }
      debugPrint('Cleanup completed for user: $username');
    } catch (e) {
      debugPrint('Error during cleanup for $username: $e');
    }
  }

  // Check if user is being monitored
  static bool isUserBeingMonitored(String username) {
    return _userInitialized[username] == true &&
        _userNotifications.containsKey(username);
  }

  // Get monitoring status
  static Map<String, dynamic> getMonitoringStatus() {
    return {
      'isInitialized': _isInitialized,
      'activeUsers': _userNotifications.keys.toList(),
      'timerActive': _monitoringTimer?.isActive ?? false,
      'userInitialized': Map<String, bool>.from(_userInitialized),
    };
  }

  // Dispose all resources
  static Future<void> dispose() async {
    try {
      _monitoringTimer?.cancel();
      _monitoringTimer = null;
      // Stop all background tasks
      await Workmanager().cancelAll();
      // Dispose all ValueNotifiers
      for (var notifier in _userNotifications.values) {
        notifier.dispose();
      }
      _userNotifications.clear();
      _userInitialized.clear();
      _isInitialized = false;
      debugPrint('GoogleSheetsMonitorService disposed');
    } catch (e) {
      debugPrint('Error disposing GoogleSheetsMonitorService: $e');
    }
  }
}

// Enhanced Notification Dialog
class EnhancedNotificationDialog {
  static void show({
    required BuildContext context,
    required String username,
    required VoidCallback onClearAll,
  }) async {
    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username tidak valid')));
      return;
    }
    final notificationsNotifier =
        GoogleSheetsMonitorService.getNotificationsForUser(username);
    if (notificationsNotifier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Layanan notifikasi belum diinisialisasi'),
        ),
      );
      return;
    }
    int visibleCount = 10;
    final ScrollController scrollController = ScrollController();
    await showDialog(
      context: context,
      builder: (context) {
       return StatefulBuilder(
  builder: (context, setState) {
    // ✅ TAMBAHAN: Responsive sizing saja
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 600 ? 450.0 : screenSize.width * 0.9;
    final dialogHeight = screenSize.height > 700 ? 650.0 : screenSize.height * 0.8;
    
   return Dialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
  ),
  elevation: 0,
  backgroundColor: Colors.transparent,
  child: ValueListenableBuilder<List<NotificationItem>>(
    valueListenable: notificationsNotifier,
    builder: (context, notifications, _) {
      final recentNotifications = notifications
          .where(
            (n) => n.timestamp.isAfter(
              DateTime.now().subtract(const Duration(days: 30)),
            ),
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      final displayed = recentNotifications.take(visibleCount).toList();
      
      scrollController.addListener(() {
        if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent) {
          if (visibleCount < 15 &&
              visibleCount < recentNotifications.length) {
            setState(() {
              visibleCount = 15;
            });
          }
        }
      });
      
      return Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFF991B1B).withOpacity(0.1),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFDC2626),
                    Color(0xFFB91C1C),
                    Color(0xFF991B1B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        if (notifications.isNotEmpty)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifikasi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (notifications.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${recentNotifications.length} notifikasi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (notifications.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.delete_sweep,
                                      color: Color(0xFFDC2626),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Hapus Semua?'),
                                ],
                              ),
                              content: const Text(
                                'Apakah Anda yakin ingin menghapus semua notifikasi?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await GoogleSheetsMonitorService
                                .clearAllNotificationsForUser(username);
                            onClearAll();
                          }
                        },
                        icon: const Icon(Icons.delete_sweep, color: Colors.white),
                        tooltip: 'Hapus Semua',
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: displayed.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFEE2E2),
                                  const Color(0xFFFEE2E2).withOpacity(0.5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDC2626).withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none,
                              size: 80,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada notifikasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Notifikasi Anda akan muncul di sini',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: displayed.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final notification = displayed[index];
                        return _buildNotificationTile(
                          context,
                          notification,
                          username,
                          notificationsNotifier,
                        );
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 350) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (notifications.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFEE2E2),
                                  Color(0xFFFECDD3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await GoogleSheetsMonitorService
                                    .markAllAsReadForUser(username);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: const Color(0xFFB91C1C),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Tandai Semua Dibaca'),
                            ),
                          ),
                        if (notifications.isNotEmpty) const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFDC2626),
                                Color(0xFFB91C1C),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Tutup'),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (notifications.isNotEmpty)
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFEE2E2),
                                  Color(0xFFFECDD3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await GoogleSheetsMonitorService
                                    .markAllAsReadForUser(username);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: const Color(0xFFB91C1C),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Tandai Dibaca'),
                            ),
                          ),
                        ),
                      if (notifications.isEmpty) const Spacer(),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFDC2626),
                              Color(0xFFB91C1C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Tutup'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  ),
);
  },
);
      },
    );
    scrollController.dispose();
  }

  static Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Notifikasi akan muncul ketika ada perubahan data',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildNotificationTile(
    BuildContext context,
    NotificationItem notification,
    String username,
    ValueNotifier<List<NotificationItem>> notificationsNotifier,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: _getSheetColor(notification.sheetName),
            width: 4,
          ),
        ),
        color: notification.isRead ? Colors.grey[50] : Colors.white,
      ),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: notification.isRead
                ? Colors.grey
                : _getSheetColor(notification.sheetName),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
            color: notification.isRead ? Colors.grey[600] : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: notification.isRead
                    ? Colors.grey[500]
                    : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${notification.sheetName} • ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        onTap: () async {
          if (!notification.isRead) {
            final updated = notification.copyWith(isRead: true);
            final list =
                List<NotificationItem>.from(notificationsNotifier.value)
                  ..removeWhere((e) => e.id == notification.id)
                  ..insert(
                    notificationsNotifier.value.indexOf(notification),
                    updated,
                  );
            notificationsNotifier.value = list;
            unawaited(
              GoogleSheetsMonitorService.markAsReadForUser(
                username,
                notification.id,
              ),
            );
          }
        },
      ),
    );
  }

  static Color _getSheetColor(String sheetName) {
    switch (sheetName) {
      case 'Riwayat Transaksi':
        return Colors.green[700] ?? Colors.green;
      case 'Data Keuangan':
        return Colors.orange[700] ?? Colors.orange;
      case 'Data Akademik':
        return Colors.purple[700] ?? Colors.purple;
      case 'Data Perizinan':
        return Colors.red[700] ?? Colors.red;
      case 'Data Absensi':
        return Colors.teal[700] ?? Colors.teal;
      case 'Pemberitahuan SPP':
        return Colors.amber[700] ?? Colors.amber;
      default:
        return Colors.blue[700] ?? Colors.blue;
    }
  }

  static String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}h lalu';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

// Helper untuk mengatasi unawaited
void unawaited(Future<void> future) {
  future.catchError((error) {
    debugPrint('Unawaited future error: $error');
  });
}
