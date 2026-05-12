// lib/utils/analytics_service.dart
// Centralized Firebase Analytics service for MOLAH app

import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:developer' as developer show log;

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ──────────────────────────────────────────────────────────
  // AUTH EVENTS
  // ──────────────────────────────────────────────────────────

  /// Log ketika user berhasil login
  static Future<void> logLogin(String username) async {
    try {
      await _analytics.logLogin(loginMethod: 'csv_spreadsheet');
      await _analytics.setUserId(id: username);
      developer.log('📊 Analytics: login logged for $username');
    } catch (e) {
      developer.log('⚠️ Analytics logLogin error: $e');
    }
  }

  /// Log ketika user logout
  static Future<void> logLogout() async {
    try {
      await _analytics.logEvent(name: 'logout');
      await _analytics.setUserId(id: null);
      developer.log('📊 Analytics: logout logged');
    } catch (e) {
      developer.log('⚠️ Analytics logLogout error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // SCREEN VIEWS
  // ──────────────────────────────────────────────────────────

  /// Log perpindahan layar
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      developer.log('📊 Analytics: screen_view → $screenName');
    } catch (e) {
      developer.log('⚠️ Analytics logScreenView error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // HOME / DATA EVENTS
  // ──────────────────────────────────────────────────────────

  /// Log ketika data santri berhasil dimuat
  static Future<void> logDataLoaded({required String source}) async {
    try {
      await _analytics.logEvent(
        name: 'data_loaded',
        parameters: {'source': source},
      );
    } catch (e) {
      developer.log('⚠️ Analytics logDataLoaded error: $e');
    }
  }

  /// Log ketika user refresh data
  static Future<void> logDataRefresh() async {
    try {
      await _analytics.logEvent(name: 'data_refresh');
    } catch (e) {
      developer.log('⚠️ Analytics logDataRefresh error: $e');
    }
  }

  /// Log ketika user toggle visibilitas saldo
  static Future<void> logSaldoToggle(bool isVisible) async {
    try {
      await _analytics.logEvent(
        name: 'saldo_toggle',
        parameters: {'visible': isVisible ? 'show' : 'hide'},
      );
    } catch (e) {
      developer.log('⚠️ Analytics logSaldoToggle error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // NAVIGATION / FEATURE EVENTS
  // ──────────────────────────────────────────────────────────

  /// Log ketika user membuka fitur tertentu (Quran, Dzikir, Doa, dll)
  static Future<void> logFeatureOpen(String featureName) async {
    try {
      await _analytics.logEvent(
        name: 'feature_open',
        parameters: {'feature': featureName},
      );
      developer.log('📊 Analytics: feature_open → $featureName');
    } catch (e) {
      developer.log('⚠️ Analytics logFeatureOpen error: $e');
    }
  }

  /// Log tab navigation di bottom nav bar
  static Future<void> logTabChange(int tabIndex, String tabName) async {
    try {
      await _analytics.logEvent(
        name: 'tab_change',
        parameters: {'tab_index': tabIndex, 'tab_name': tabName},
      );
    } catch (e) {
      developer.log('⚠️ Analytics logTabChange error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // PAYMENT EVENTS
  // ──────────────────────────────────────────────────────────

  /// Log ketika user membuka halaman pembayaran
  static Future<void> logPaymentPageOpen(String paymentType) async {
    try {
      await _analytics.logEvent(
        name: 'payment_page_open',
        parameters: {'payment_type': paymentType},
      );
    } catch (e) {
      developer.log('⚠️ Analytics logPaymentPageOpen error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // UPDATE EVENTS
  // ──────────────────────────────────────────────────────────

  /// Log ketika update tersedia
  static Future<void> logUpdateAvailable() async {
    try {
      await _analytics.logEvent(name: 'update_available');
    } catch (e) {
      developer.log('⚠️ Analytics logUpdateAvailable error: $e');
    }
  }

  /// Log ketika user memilih untuk update atau skip
  static Future<void> logUpdateDecision(String decision) async {
    try {
      await _analytics.logEvent(
        name: 'update_decision',
        parameters: {'decision': decision}, // 'update' or 'skip'
      );
    } catch (e) {
      developer.log('⚠️ Analytics logUpdateDecision error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // ERROR EVENTS
  // ──────────────────────────────────────────────────────────

  /// Log error untuk monitoring
  static Future<void> logError(String errorType, String message) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'message': message.length > 100 ? message.substring(0, 100) : message,
        },
      );
    } catch (e) {
      developer.log('⚠️ Analytics logError error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // USER PROPERTIES
  // ──────────────────────────────────────────────────────────

  /// Set lembaga santri sebagai user property untuk segmentasi
  static Future<void> setUserLembaga(String lembaga) async {
    try {
      await _analytics.setUserProperty(name: 'lembaga', value: lembaga);
    } catch (e) {
      developer.log('⚠️ Analytics setUserLembaga error: $e');
    }
  }
}
