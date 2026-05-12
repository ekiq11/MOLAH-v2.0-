import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mmkv/mmkv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ============================================================
// Offline Cache Service
// Menyimpan data terakhir agar app tetap bisa digunakan
// meski tidak ada koneksi internet
// ============================================================
class OfflineCacheService {
  static MMKV? _mmkv;
  static bool _isOnline = true;

  static const String _prefixSantri = 'offline_santri_';
  static const String _prefixTimestamp = 'offline_ts_';
  static const String _prefixIzin = 'offline_izin_';

  // ──────────────────────────────────────────────
  // Inisialisasi
  // ──────────────────────────────────────────────
  static Future<void> initialize() async {
    _mmkv = MMKV.defaultMMKV();
    await _listenConnectivity();
    debugPrint('✅ [OfflineCache] Initialized');
  }

  static bool get isOnline => _isOnline;

  // ──────────────────────────────────────────────
  // Monitor koneksi internet secara real-time
  // ──────────────────────────────────────────────
  static Future<void> _listenConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _isOnline = result.any((r) => r != ConnectivityResult.none);

    connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!wasOnline && _isOnline) {
        debugPrint('🌐 [OfflineCache] Kembali online — trigger sync');
        _onBackOnline?.call();
      } else if (wasOnline && !_isOnline) {
        debugPrint('📴 [OfflineCache] Offline mode aktif');
      }
    });
  }

  // Callback dipanggil saat koneksi kembali
  static VoidCallback? _onBackOnline;
  static void setOnBackOnlineCallback(VoidCallback callback) {
    _onBackOnline = callback;
  }

  // ──────────────────────────────────────────────
  // SIMPAN data santri ke cache
  // ──────────────────────────────────────────────
  static void saveSantriData(String username, Map<String, dynamic> data) {
    if (_mmkv == null || data.isEmpty) return;
    try {
      _mmkv!.encodeString(
        '$_prefixSantri$username',
        jsonEncode(data),
      );
      _mmkv!.encodeString(
        '$_prefixTimestamp$username',
        DateTime.now().toIso8601String(),
      );
      debugPrint('💾 [OfflineCache] Data santri $username tersimpan');
    } catch (e) {
      debugPrint('❌ [OfflineCache] Save error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // BACA data santri dari cache
  // ──────────────────────────────────────────────
  static Map<String, dynamic>? getSantriData(String username) {
    if (_mmkv == null) return null;
    try {
      final json = _mmkv!.decodeString('$_prefixSantri$username');
      if (json == null || json.isEmpty) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [OfflineCache] Read error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // Waktu terakhir data di-cache
  // ──────────────────────────────────────────────
  static DateTime? getLastCacheTime(String username) {
    final ts = _mmkv?.decodeString('$_prefixTimestamp$username');
    return ts != null ? DateTime.tryParse(ts) : null;
  }

  // Teks user-friendly kapan data terakhir diperbarui
  static String getLastCacheLabel(String username) {
    final lastTime = getLastCacheTime(username);
    if (lastTime == null) return 'Belum pernah diperbarui';
    final diff = DateTime.now().difference(lastTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  // ──────────────────────────────────────────────
  // SIMPAN antrian aksi offline (untuk sync nanti)
  // ──────────────────────────────────────────────
  static void queueOfflineAction(String action, Map<String, dynamic> data) {
    if (_mmkv == null) return;
    try {
      final queueJson = _mmkv!.decodeString('offline_action_queue') ?? '[]';
      final queue = jsonDecode(queueJson) as List<dynamic>;
      queue.add({
        'action': action,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _mmkv!.encodeString('offline_action_queue', jsonEncode(queue));
      debugPrint('📋 [OfflineCache] Action queued: $action');
    } catch (e) {
      debugPrint('❌ [OfflineCache] Queue error: $e');
    }
  }

  // Ambil semua antrian aksi offline
  static List<Map<String, dynamic>> getQueuedActions() {
    if (_mmkv == null) return [];
    try {
      final queueJson = _mmkv!.decodeString('offline_action_queue') ?? '[]';
      final queue = jsonDecode(queueJson) as List<dynamic>;
      return queue.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // Hapus antrian setelah berhasil sync
  static void clearQueue() {
    _mmkv?.encodeString('offline_action_queue', '[]');
    debugPrint('🗑️ [OfflineCache] Queue cleared');
  }

  // ──────────────────────────────────────────────
  // Apakah cache masih valid (belum lebih dari N menit)
  // ──────────────────────────────────────────────
  static bool isCacheValid(String username, {int maxAgeMinutes = 30}) {
    final lastTime = getLastCacheTime(username);
    if (lastTime == null) return false;
    return DateTime.now().difference(lastTime).inMinutes < maxAgeMinutes;
  }

  // ──────────────────────────────────────────────
  // SIMPAN list perizinan ke cache
  // ──────────────────────────────────────────────
  static void saveIzinList(String username, List<Map<String, dynamic>> list) {
    if (_mmkv == null) return;
    try {
      _mmkv!.encodeString('$_prefixIzin$username', jsonEncode(list));
      debugPrint('💾 [OfflineCache] Izin list saved for $username');
    } catch (e) {
      debugPrint('❌ [OfflineCache] Save izin error: $e');
    }
  }

  static List<Map<String, dynamic>> getIzinList(String username) {
    if (_mmkv == null) return [];
    try {
      final json = _mmkv!.decodeString('$_prefixIzin$username');
      if (json == null || json.isEmpty) return [];
      return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

// ──────────────────────────────────────────────
// Widget Banner Offline — tampilkan di atas app
// saat tidak ada koneksi internet
// ──────────────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  final String lastUpdated;
  const OfflineBanner({super.key, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF374151), Color(0xFF1F2937)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode Offline — Data terakhir: $lastUpdated',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'OFFLINE',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
