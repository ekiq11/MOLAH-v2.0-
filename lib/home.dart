import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/home_shimmer.dart';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:mmkv/mmkv.dart';
import 'package:pizab_molah/helper/loading_timer.dart';
import 'dart:async';
import 'dart:convert';

// --- TAMBAHKAN IMPOR INI UNTUK connectivity_plus 7.0.0 ---
import 'package:connectivity_plus/connectivity_plus.dart';

// Import custom components
import 'dialogs/topup_dialog.dart';
import 'dialogs/notification_dialog.dart';
import 'utils/fcm_service.dart';
import 'utils/offline_cache_service.dart';
import 'screens/pembayaran.dart';
import 'utils/fetcher_data.dart';
import 'login.dart';
import 'utils/login_preferences.dart';
import 'widgets/quick_actions.dart';
import 'widgets/header_widget.dart';
import 'widgets/bento_dashboard.dart';
import 'package:pizab_molah/widgets/profile.dart';
import 'package:pizab_molah/screens/HafalanHistoryPage.dart';
import 'package:pizab_molah/screens/history_transaction.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  // Core state variables
  bool _isSaldoVisible = false;
  int _currentIndex = 0;
  Map<String, dynamic> _santriData = {};
  Map<String, dynamic> _previousData = {};
  bool _isLoading = true;
  String _errorMessage = '';
  List<String> _notifications = [];

  // Controllers
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Timers and utilities
  Timer? _dataTimer;
  Timer? _debounceTimer;
  MMKV? _mmkv;
  final _httpClient = http.Client();

  // --- TAMBAHAN BARU UNTUK connectivity_plus ^7.0.0 ---
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isNetworkAvailable =
      false; // True jika ada setidaknya satu koneksi selain none

  // Constants - Optimized for better performance
  static const Duration _pollingInterval = Duration(
    minutes: 5,
  ); // Increased from 3 minutes
  static const Duration _requestTimeout = Duration(
    seconds: 12,
  ); // Reduced from 20 seconds
  static const Duration _headRequestTimeout = Duration(
    seconds: 5,
  ); // <-- Baru: Timeout cepat untuk cek aksesibilitas
  static const Duration _cacheValidDuration = Duration(
    minutes: 2,
  ); // Cache validity

  // Optimized CSV URLs with better error handling
  static const List<Map<String, String>> _csvSources = [
    {
      'url':
          'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=1307491664',
      'name': 'Primary Data Source',
    },
  ];

  static const Map<String, String> _fieldNames = {
    'saldo': 'Saldo',
    'status_izin': 'Status Perizinan',
    'jumlah_hafalan': 'Jumlah Hafalan',
    'absensi': 'Absensi',
    'poin_pelanggaran': 'Poin Pelanggaran',
    'reward': 'Reward',
    'lembaga': 'Lembaga',
    'izin_terakhir': 'Izin Terakhir',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimation();
    _initializeApp();

    // --- TAMBAHAN BARU: Inisialisasi Connectivity Plus v7.0.0 ---
    initConnectivity(); // Cek status awal
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  @override
  void dispose() {
    debugPrint('🧹 _HomeScreenState.dispose: Cleaning up...');
    _dataTimer?.cancel();
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _httpClient.close();
    LoadingTimeoutDialog.cancelTimeout();
    GoogleSheetsMonitorService.stopMonitoringForUser(widget.username);
    GoogleSheetsMonitorService.cleanupForUser(widget.username);

    // --- TAMBAHAN BARU: Batalkan subscription connectivity ---
    _connectivitySubscription?.cancel();

    super.dispose();
    debugPrint('✅ _HomeScreenState disposed successfully');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkCacheAndRefresh();
    } else if (state == AppLifecycleState.paused) {
      _dataTimer?.cancel();
    }
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Reduced from 600ms
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, 0.2), // Reduced from 0.3
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart, // Changed from easeOutCubic
          ),
        );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _initializeApp() async {
    try {
      await _initializeMMKV();
      // Mulai timeout dialog sebelum loading data
      if (mounted) {
        LoadingTimeoutDialog.startTimeout(context, _handleRetryLoading);
      }
      // Load cached data first for immediate display
      await _loadCachedData();
      // Initialize enhanced notifications service
      unawaited(
        _initializeNotifications().catchError((e) {
          debugPrint('Error in unawaited _initializeNotifications: $e');
        }),
      );
      // Check if cache is still valid, if not fetch new data
      await _checkCacheAndRefresh();
      _startPolling();
      // Subscribe ke FCM untuk notifikasi real-time
      await FCMService.subscribeForUser(
        username: widget.username,
        kelas: _santriData['kelas'],
        asrama: _santriData['asrama'],
      );

      // Setup auto-sync saat online
      OfflineCacheService.setOnBackOnlineCallback(() {
        if (mounted) {
          _fetchSantriData(silent: true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koneksi pulih. Sinkronisasi data...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });

      // Cancel timeout jika berhasil load
      LoadingTimeoutDialog.cancelTimeout();
    } catch (e) {
      debugPrint('Error initializing app: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data';
        });
      }
    }
  }

  /// Handler untuk retry dari timeout dialog
  void _handleRetryLoading() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      LoadingTimeoutDialog.startTimeout(context, _handleRetryLoading);
      _initializeApp(); // ✅ Tambahkan ini
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await GoogleSheetsMonitorService.initializeForUser(widget.username);
      debugPrint(
        '✅ Enhanced notifications service initialized for user: ${widget.username}',
      );
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _initializeMMKV() async {
    try {
      MMKV.initialize();
      _mmkv = MMKV.defaultMMKV();
      debugPrint('✅ MMKV initialized in HomeScreen');
    } catch (e) {
      debugPrint('❌ Error initializing MMKV in HomeScreen: $e');
      _mmkv = null;
    }
  }

  Future<void> _loadCachedData() async {
    if (_mmkv == null) return;
    try {
      final cachedDataKey = 'santri_${widget.username}';
      final timestampKey = 'last_update_${widget.username}';
      final cachedData = _mmkv!.decodeString(cachedDataKey) ?? '';
      final lastUpdate = _mmkv!.decodeInt(timestampKey, defaultValue: 0);
      if (cachedData.isNotEmpty) {
        final decodedData = json.decode(cachedData) as Map<String, dynamic>;
        _previousData = Map<String, dynamic>.from(decodedData);
        if (mounted) {
          setState(() {
            _santriData = Map<String, dynamic>.from(_previousData);
            _isLoading = false;
          });
        }
        _animationController.forward();
        // Check cache age
        final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
        debugPrint(
          'Cache age: ${Duration(milliseconds: cacheAge).inMinutes} minutes',
        );
      }
      // Load notifications
      final notificationsKey = 'notifications_${widget.username}';
      final cachedNotificationsStr =
          _mmkv!.decodeString(notificationsKey) ?? '';
      if (cachedNotificationsStr.isNotEmpty) {
        try {
          final cachedNotifications =
              json.decode(cachedNotificationsStr) as List<dynamic>;
          _notifications = cachedNotifications
              .map((e) => e.toString())
              .toList();
        } catch (e) {
          debugPrint('Error parsing cached notifications: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached data from MMKV: $e');
    }
  }

  Future<void> _checkCacheAndRefresh() async {
    if (_mmkv == null) return;
    final timestampKey = 'last_update_${widget.username}';
    final lastUpdate = _mmkv!.decodeInt(timestampKey, defaultValue: 0);
    final now = DateTime.now().millisecondsSinceEpoch;
    // If cache is older than valid duration, fetch new data
    if (now - lastUpdate > _cacheValidDuration.inMilliseconds) {
      await _fetchSantriData(silent: _santriData.isNotEmpty);
    }
  }

  void _startPolling() {
    _dataTimer?.cancel();
    _dataTimer = Timer.periodic(_pollingInterval, (_) {
      if (mounted) {
        _fetchSantriData(silent: true);
      }
    });
  }

  Future<void> _fetchSantriData({bool silent = false}) async {
    // Debounce rapid requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _performDataFetch(silent: silent);
    });
  }

  Future<void> _performDataFetch({bool silent = false}) async {
    // --- Cek koneksi sebelum mulai fetch ---
    if (!_isNetworkAvailable || !OfflineCacheService.isOnline) {
      if (!silent && mounted) {
        LoadingTimeoutDialog.cancelTimeout();

        // Coba baca dari cache offline
        final cachedData = OfflineCacheService.getSantriData(widget.username);
        if (cachedData != null) {
          await _processNewData(cachedData, fromCache: true);
          _showNoInternetNotification();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Tidak ada koneksi internet dan belum ada data tersimpan.';
          });
        }
      }
      return;
    }

    // Start timeout untuk operasi fetch data jika tidak silent
    if (!silent && mounted) {
      LoadingTimeoutDialog.startTimeout(context, _handleRetryDataFetch);
      setState(() => _isLoading = true);
    }

    debugPrint(
      '🌐 Starting optimized data fetch for username: ${widget.username}',
    );

    // --- TAMBAHAN BARU: Validasi aksesibilitas setiap sumber CSV sebelum GET ---
    bool anySourceAccessible = false;
    for (final source in _csvSources) {
      final url = source['url']!;
      debugPrint('🔗 Checking accessibility of: $url');
      try {
        // Gunakan HEAD request untuk mengecek apakah URL bisa diakses (tidak download isi)
        final headResponse = await _httpClient
            .head(Uri.parse(url))
            .timeout(
              _headRequestTimeout,
            ); // Timeout sangat cepat untuk cek akses
        if (headResponse.statusCode >= 200 && headResponse.statusCode < 400) {
          debugPrint(
            '✅ URL accessible: $url (Status: ${headResponse.statusCode})',
          );
          anySourceAccessible = true;
          break; // Jika satu bisa, kita lanjutkan ke proses GET
        } else {
          debugPrint(
            '⚠️ URL not accessible: $url (Status: ${headResponse.statusCode})',
          );
        }
      } catch (e) {
        debugPrint('❌ Head request failed for $url: $e');
        // Jika gagal, lanjut ke sumber berikutnya
      }
    }

    if (!anySourceAccessible) {
      // Semua sumber tidak bisa diakses
      if (!silent && mounted) {
        LoadingTimeoutDialog.cancelTimeout();
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Gagal mengakses sumber data. Silakan cek kembali koneksi atau hubungi admin.';
        });
      }
      return;
    }

    // Jika sumber bisa diakses, lanjutkan dengan GET request
    for (int sourceIndex = 0; sourceIndex < _csvSources.length; sourceIndex++) {
      final source = _csvSources[sourceIndex];
      debugPrint('🔗 Trying ${source['name']}: ${source['url']}');
      try {
        final response = await _httpClient
            .get(Uri.parse(source['url']!), headers: _getOptimizedHeaders())
            .timeout(_requestTimeout);
        debugPrint('📡 Response Status: ${response.statusCode}');
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          // Quick validation
          if (_isValidCSVContent(response.body)) {
            final newData = await _processCSVResponse(response.body);
            if (newData.isNotEmpty) {
              debugPrint(
                '✅ Data parsing successful for user: ${widget.username}',
              );
              // Cancel timeout karena berhasil
              LoadingTimeoutDialog.cancelTimeout();
              await _processNewData(newData);
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error with ${source['name']}: $e');
        if (e.toString().contains('400')) {
          // Skip other sources if getting 400 errors
          debugPrint('⚠️ HTTP 400 detected, trying fallback methods directly');
          break;
        }
      }
    }

    debugPrint('⚠️ All CSV sources failed, trying fallback methods...');
    await _tryFallbackMethods(silent);
  }

  // Handler untuk retry fetch data dari timeout dialog
  void _handleRetryDataFetch() {
    _fetchSantriData(silent: false);
  }

  Future<void> _tryFallbackMethods(bool silent) async {
    try {
      debugPrint('🔄 Trying DataFetcher fallback...');
      final dataFetcher = DataFetcher();
      final fallbackData = await dataFetcher
          .fetchSantriData(widget.username)
          .timeout(const Duration(seconds: 10));
      if (fallbackData.isNotEmpty) {
        debugPrint('✅ Fallback data fetcher successful');
        // Cancel timeout karena berhasil
        LoadingTimeoutDialog.cancelTimeout();
        await _processNewData(fallbackData);
        return;
      }
    } catch (fallbackError) {
      debugPrint('❌ Fallback fetch error: $fallbackError');
    }
    // Cancel timeout sebelum handle error
    LoadingTimeoutDialog.cancelTimeout();

    // Fallback terakhir: Coba ambil dari cache offline
    final cachedData = OfflineCacheService.getSantriData(widget.username);
    if (cachedData != null) {
      debugPrint('⚠️ Fetch gagal. Membaca data dari Offline Cache');
      await _processNewData(cachedData, fromCache: true);
    } else {
      await _handleFetchError('Semua sumber data gagal diakses', silent);
    }
  }

  Future<void> _handleFetchError(dynamic error, bool silent) async {
    debugPrint('❌ Fetch error: $error');
    String errorMessage = 'Gagal memuat data';
    if (error.toString().contains('internet') ||
        error.toString().contains('connection')) {
      errorMessage = 'Tidak ada koneksi internet';
    } else if (error.toString().contains('timeout')) {
      errorMessage = 'Koneksi lambat atau timeout, coba lagi nanti';
      // --- TAMBAHAN BARU: Tampilkan notifikasi koneksi lambat ---
      if (!silent && mounted) {
        _showSlowConnectionNotification();
      }
    } else if (error.toString().contains('400')) {
      errorMessage = 'Server sedang bermasalah';
    }

    if (mounted) {
      if (_santriData.isEmpty) {
        setState(() {
          _santriData = _getDefaultData();
          _isLoading = false;
          _errorMessage = silent ? '' : errorMessage;
        });
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = silent
              ? ''
              : 'Menggunakan data tersimpan - $errorMessage';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, String> _getOptimizedHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Android 12; Mobile; rv:109.0) Gecko/109.0 Firefox/109.0',
      'Accept': 'text/csv,text/plain,*/*;q=0.8',
      'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'DNT': '1',
    };
  }

  bool _isValidCSVContent(String content) {
    if (content.length < 10) return false;
    if (content.toLowerCase().contains('<html>')) return false;
    if (content.toLowerCase().contains('error')) return false;
    if (!content.contains(',') && !content.contains(';')) return false;
    return true;
  }

  Future<Map<String, dynamic>> _processCSVResponse(String csvContent) async {
    try {
      // Process CSV in isolate for better performance with large data
      final csvData = const CsvToListConverter().convert(csvContent);
      if (csvData.isEmpty) {
        debugPrint('❌ CSV data is empty');
        return {};
      }
      return _parseCSVData(csvData);
    } catch (e) {
      debugPrint('❌ CSV processing error: $e');
      return {};
    }
  }

  Map<String, dynamic> _parseCSVData(List<List<dynamic>> csvData) {
    try {
      final headers = csvData[0]
          .map((e) => e.toString().toLowerCase().trim().replaceAll(' ', '_'))
          .toList();
      debugPrint('📊 Processed headers: $headers');
      final nisnIndex = _findColumnIndex(headers, [
        'nisn',
        'no_induk',
        'id',
        'student_id',
        'nomor_induk',
        'kode_santri',
        'username',
        'user_id',
        'santri_id',
      ]);
      if (nisnIndex == -1) {
        debugPrint('❌ NISN column not found in headers: $headers');
        return {};
      }
      // Optimize search by checking rows more efficiently
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length > nisnIndex) {
          final csvNisn = row[nisnIndex]?.toString().trim() ?? '';
          if (_isMatchingUser(widget.username, csvNisn)) {
            debugPrint('✅ Match found for user: ${widget.username} at row $i');
            return _extractUserData(row, headers);
          }
        }
      }
      debugPrint('❌ No matching user found for: ${widget.username}');
      return {};
    } catch (e) {
      debugPrint('❌ CSV parse error: $e');
      return {};
    }
  }

  bool _isMatchingUser(String targetUsername, String csvValue) {
    if (targetUsername.isEmpty || csvValue.isEmpty) return false;
    final cleanTarget = targetUsername.toLowerCase().trim();
    final cleanCsv = csvValue.toLowerCase().trim();
    if (cleanTarget == cleanCsv) return true;
    final numericTarget = cleanTarget.replaceAll(RegExp(r'[^0-9]'), '');
    final numericCsv = cleanCsv.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericTarget.isNotEmpty && numericCsv.isNotEmpty) {
      final normalizedTarget = numericTarget.replaceAll(RegExp(r'^0+'), '');
      final normalizedCsv = numericCsv.replaceAll(RegExp(r'^0+'), '');
      if (normalizedTarget.isNotEmpty && normalizedCsv.isNotEmpty) {
        return normalizedTarget == normalizedCsv;
      }
    }
    if (cleanTarget.length > 3 && cleanCsv.length > 3) {
      return cleanTarget.contains(cleanCsv) || cleanCsv.contains(cleanTarget);
    }
    return false;
  }

  Map<String, dynamic> _extractUserData(
    List<dynamic> row,
    List<String> headers,
  ) {
    return {
      'nisn': widget.username,
      'nama': _getFieldValue(row, headers, [
        'nama',
        'name',
        'student_name',
        'nama_santri',
      ], 'Santri'),
      'saldo': _formatSaldo(
        _getFieldValue(row, headers, [
          'saldo',
          'balance',
          'uang',
          'money',
        ], '0'),
      ),
      'kelas': _getFieldValue(row, headers, [
        'kelas',
        'class',
        'tingkat',
        'level',
      ], '-'),
      'asrama': _getFieldValue(row, headers, [
        'asrama',
        'dormitory',
        'dorm',
        'kamar',
      ], '-'),
      'status_izin': _getFieldValue(row, headers, [
        'status_izin',
        'izin',
        'permission',
      ], 'Sedang Dipondok'),
      'jumlah_hafalan': _getFieldValue(row, headers, [
        'hafalan',
        'memorization',
        'jumlah_hafalan',
      ], '0'),
      'absensi': _getFieldValue(row, headers, [
        'absensi',
        'attendance',
        'kehadiran',
      ], 'Belum dimulai'),
      'poin_pelanggaran': _getFieldValue(row, headers, [
        'poin',
        'penalty',
        'pelanggaran',
      ], '0'),
      'reward': _getFieldValue(row, headers, [
        'reward',
        'bonus',
        'hadiah',
      ], '0'),
      'lembaga': _getFieldValue(row, headers, [
        'lembaga',
        'institution',
        'sekolah',
      ], '-'),
      'izin_terakhir': _getFieldValue(row, headers, [
        'izin_terakhir',
        'last_permission',
      ], '-'),
    };
  }

  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (final name in possibleNames) {
      for (int i = 0; i < headers.length; i++) {
        if (headers[i].contains(name) || name.contains(headers[i])) {
          return i;
        }
      }
    }
    return -1;
  }

  String _getFieldValue(
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

  String _formatSaldo(String saldo) {
    if (saldo.startsWith('Rp')) return saldo;
    final clean = saldo.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return '0';
    final number = int.tryParse(clean) ?? 0;
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return formatted;
  }

  Future<void> _processNewData(
    Map<String, dynamic> newData, {
    bool fromCache = false,
  }) async {
    final hasChanges = _checkChanges(newData);
    if (mounted) {
      setState(() {
        _santriData = Map<String, dynamic>.from(newData);
        _isLoading = false;
        _errorMessage = '';
      });
      if (!_animationController.isCompleted) {
        _animationController.forward();
      }
    }

    if (!fromCache) {
      // Simpan ke offline cache jika data ini berasal dari internet
      OfflineCacheService.saveSantriData(widget.username, newData);
      await _saveData(newData);
    }

    if (hasChanges && mounted && !fromCache) {
      _showUpdateSnackBar();
    }
  }

  bool _checkChanges(Map<String, dynamic> newData) {
    if (_previousData.isEmpty) {
      _previousData = Map<String, dynamic>.from(newData);
      return false;
    }
    List<String> changes = [];
    for (final entry in _fieldNames.entries) {
      final oldValue = _previousData[entry.key]?.toString() ?? '';
      final newValue = newData[entry.key]?.toString() ?? '';
      if (oldValue != newValue && oldValue.isNotEmpty) {
        changes.add('${entry.value}: $oldValue → $newValue');
      }
    }
    if (changes.isNotEmpty) {
      _notifications.addAll(changes);
      if (_notifications.length > 20) {
        _notifications = _notifications.sublist(_notifications.length - 20);
      }
      _previousData = Map<String, dynamic>.from(newData);
      return true;
    }
    return false;
  }

  void _showUpdateSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data berhasil diperbarui'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: Colors.white,
          onPressed: () => setState(() => _currentIndex = 1),
        ),
      ),
    );
  }

  Future<void> _saveData(Map<String, dynamic> data) async {
    if (_mmkv == null) return;
    try {
      final dataKey = 'santri_${widget.username}';
      final notificationsKey = 'notifications_${widget.username}';
      final timestampKey = 'last_update_${widget.username}';
      await Future.wait([
        Future(() => _mmkv!.encodeString(dataKey, json.encode(data))),
        Future(
          () => _mmkv!.encodeString(
            notificationsKey,
            json.encode(_notifications),
          ),
        ),
        Future(
          () => _mmkv!.encodeInt(
            timestampKey,
            DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      ]);
      debugPrint('✅ Data saved to MMKV successfully');
    } catch (e) {
      debugPrint('❌ Error saving data to MMKV: $e');
    }
  }

  Map<String, dynamic> _getDefaultData() {
    return {
      'nisn': widget.username,
      'nama': 'Data tidak ditemukan',
      'saldo': '0',
      'status_izin': 'Sedang Dipondok',
      'jumlah_hafalan': '0',
      'absensi': 'Belum dimulai',
      'kelas': '-',
      'asrama': '-',
      'poin_pelanggaran': '0',
      'reward': '0',
      'lembaga': '-',
      'izin_terakhir': '-',
    };
  }

  void _toggleSaldoVisibility() {
    setState(() {
      _isSaldoVisible = !_isSaldoVisible;
    });
  }

  Future<void> _handleLogout() async {
    try {
      debugPrint('🚪 Starting optimized logout process...');
      _dataTimer?.cancel();
      _debounceTimer?.cancel();
      // Bersihkan service khusus
      await GoogleSheetsMonitorService.cleanupForUser(widget.username);
      // Bersihkan preferensi login
      await LoginPreferences.clearAllUserData(widget.username);
      if (_mmkv != null) {
        final keysToRemove = [
          'user_logged_in',
          'user_username',
          'user_data_json',
          'user_login_time',
          'santri_${widget.username}',
          'notifications_${widget.username}',
          'last_update_${widget.username}',
          'notifications_enhanced_${widget.username}',
          // Tambahkan jika ada
          'last_poll_time_${widget.username}',
          'cache_absensi_${widget.username}',
          'cache_perizinan_${widget.username}',
          'cache_transaksi_${widget.username}',
        ];
        // Hapus kunci yang sudah diketahui
        for (final key in keysToRemove) {
          if (_mmkv!.containsKey(key)) {
            if (_mmkv?.containsKey(key) == true) {
              _mmkv?.removeValue(key);
            }
            debugPrint('🗑️ Removed MMKV key: $key');
          }
        }
        // 🔥 Hapus semua kunci yang mengandung username (opsional, lebih aman)
        if (_mmkv == null) return;
        final allKeys = _mmkv!.allKeys;
        for (final key in allKeys) {
          if (key.contains(widget.username)) {
            if (_mmkv?.containsKey(key) == true) {
              _mmkv?.removeValue(key);
            }
            debugPrint('🧹 Removed MMKV key: $key');
          }
        }
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      }
      debugPrint('✅ Optimized logout process completed');
    } catch (e) {
      debugPrint('💥 Logout error: $e');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final screenSize = MediaQuery.of(context).size;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: max(20, screenSize.width * 0.1),
            vertical: max(20, screenSize.height * 0.15),
          ),
          child: Container(
            padding: EdgeInsets.all(screenSize.width * 0.06),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(screenSize.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    size: screenSize.width * 0.1,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.025),
                Text(
                  "Keluar Aplikasi",
                  style: TextStyle(
                    fontSize: screenSize.width * 0.04,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: screenSize.height * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: screenSize.height * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.grey),
                        ),
                        child: Text(
                          "Batal",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: screenSize.width * 0.035,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenSize.width * 0.04),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            vertical: screenSize.height * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Keluar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.035,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTopUpDialog() {
    TopUpDialog.show(
      context: context,
      currentBalance: _santriData['saldo'] ?? '0',
      nisn: widget.username,
      namaSantri: _santriData['nama'] ?? 'Nama Santri',
    );
  }

  void _showEnhancedNotificationDialog() {
    EnhancedNotificationDialog.show(
      context: context,
      username: widget.username,
      onClearAll: () {
        // Dihapus: setState(() {});
        // Karena UI sekarang reaktif, tidak perlu setState manual.
        // Dialog akan menutup dan ikon notifikasi akan otomatis update.
      },
    );
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      LoadingTimeoutDialog.startTimeout(context, _handleRetryDataFetch);
    }
    await _fetchSantriData();
    // Force check untuk memastikan sinkronisasi
    unawaited(GoogleSheetsMonitorService.forceCheckForUser(widget.username));
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBody: true, // Untuk floating nav bar
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Banner Offline
              if (!_isNetworkAvailable || !OfflineCacheService.isOnline)
                OfflineBanner(
                  lastUpdated: OfflineCacheService.getLastCacheLabel(
                    widget.username,
                  ),
                ),

              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _isLoading && _santriData.isEmpty
                        ? HomeShimmerLoading(screenSize: screenSize)
                        : _buildMainContent(screenSize),
                    PaymentPage(
                      username: widget.username,
                      studentName: _santriData['nama'] ?? 'Santri',
                    ),
                    HafalanHistoryPage(
                      nisn: widget.username,
                      namaSantri: _santriData['nama'] ?? 'Santri',
                    ),
                    TransactionHistoryPage(
                      nisn: widget.username,
                      studentName: _santriData['nama'] ?? 'Santri',
                    ),
                    ProfilePage(
                      nisn: widget.username,
                      santriData: _santriData,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(screenSize),
      ),
    );
  }

  Widget _buildBottomNavigationBar(Size screenSize) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.receipt_long_rounded, 'Tagihan'),
                    const SizedBox(width: 60), // Perfect center gap
                    _buildNavItem(3, Icons.history_rounded, 'Riwayat'),
                    _buildNavItem(4, Icons.person_rounded, 'Profil'),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 45, // Perfectly centered above the navbar gap
          child: GestureDetector(
            onTap: () => _onBottomNavTap(2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _currentIndex == 2
                      ? [const Color(0xFF059669), const Color(0xFF047857)]
                      : [const Color(0xFF10B981), const Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: _currentIndex == 2 ? 16 : 10,
                    offset: Offset(0, _currentIndex == 2 ? 8 : 5),
                    spreadRadius: _currentIndex == 2 ? 2 : 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onBottomNavTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF10B981) : Colors.grey[400],
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF10B981) : Colors.grey[400],
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


  // DIPERBAIKI: Fungsi ini sekarang menerima parameter `unreadCount`
  Widget _buildNotificationIcon({bool active = false, int unreadCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(active ? Icons.notifications_active : Icons.notifications),
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainContent(Size screenSize) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          color: const Color(0xFF10B981),
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: screenSize.width * 0.02),
                CombinedHeader(
                  santriData: _santriData,
                  // DIPERBAIKI: Gunakan ValueListenableBuilder untuk mengambil jumlah notifikasi
                  notificationCount:
                      GoogleSheetsMonitorService.getUnreadCountForUser(
                        widget.username,
                      ),
                  onNotificationTap: _showEnhancedNotificationDialog,
                  onLogoutTap: _showLogoutDialog,
                  saldo: _santriData['saldo'] ?? '0',
                  onTopUpTap: _showTopUpDialog,
                  isSaldoVisible: _isSaldoVisible,
                  onToggleSaldoVisibility: _toggleSaldoVisibility,
                ),
                Padding(
                  padding: EdgeInsets.all(screenSize.width * 0.05),
                  child: Column(
                    children: [
                      if (_errorMessage.isNotEmpty) ...[
                        _buildErrorBanner(screenSize),
                        SizedBox(height: screenSize.height * 0.02),
                      ],
                      QuickActions(nisn: widget.username),
                      SizedBox(height: screenSize.height * 0.03),
                      BentoDashboard(santriData: _santriData, nisn: widget.username),
                      SizedBox(height: 120), // Memberi ruang agar tidak tertutup bottom navbar
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAMBAHAN BARU: Method untuk pemberitahuan ---
  Future<void> initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to check connectivity status: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      // Jika ada setidaknya satu koneksi yang bukan "none", maka kita anggap tersambung
      _isNetworkAvailable = results.any(
        (result) => result != ConnectivityResult.none,
      );
    });

    if (!_isNetworkAvailable && _isLoading) {
      _showNoInternetNotification();
    }
  }

  void _showNoInternetNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tidak ada koneksi internet. Mohon periksa kembali koneksi Anda.',
                style: TextStyle(color: Colors.orange[800]),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[100],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildErrorBanner(Size screenSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.03),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          SizedBox(width: screenSize.width * 0.02),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red[800],
                fontSize: screenSize.width * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSlowConnectionNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_empty_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Koneksi lambat. Sedang mencoba mengambil data... Harap tunggu beberapa detik.',
                style: TextStyle(color: Colors.blue[800]),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[100],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}
