import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class LoadingTimeoutDialog {
  static Timer? _timeoutTimer;
  static bool _isDialogShowing = false;

  /// Memulai timer untuk menampilkan dialog setelah 30 detik
  static void startTimeout(BuildContext context, VoidCallback onRetry) {
    _timeoutTimer?.cancel();
    _isDialogShowing = false;

    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!_isDialogShowing && context.mounted) {
        _showTimeoutDialog(context, onRetry);
      }
    });
  }

  /// Membatalkan timer timeout
  static void cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Menampilkan dialog timeout dengan analisis penyebab
  static Future<void> _showTimeoutDialog(
    BuildContext context,
    VoidCallback onRetry,
  ) async {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    final screenSize = MediaQuery.of(context).size;
    final deviceInfo = await _getDeviceInfo();
    final diagnostics = await _getDiagnostics();

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.05,
            vertical: screenSize.height * 0.08,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.85,
              maxWidth: screenSize.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(screenSize.width * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header dengan animasi loading
                    _buildHeader(screenSize),

                    SizedBox(height: screenSize.height * 0.025),

                    // Judul
                    Text(
                      'Aplikasi Membutuhkan Waktu Lebih Lama',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.048,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: screenSize.height * 0.015),

                    Text(
                      'Kami sedang menganalisis kemungkinan penyebabnya',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.035,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: screenSize.height * 0.03),

                    // Diagnostics Section
                    _buildDiagnosticsSection(
                      diagnostics,
                      deviceInfo,
                      screenSize,
                    ),

                    SizedBox(height: screenSize.height * 0.03),

                    // Rekomendasi
                    _buildRecommendations(diagnostics, screenSize),

                    SizedBox(height: screenSize.height * 0.035),

                    // Action Buttons
                    _buildActionButtons(dialogContext, onRetry, screenSize),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  static Widget _buildHeader(Size screenSize) {
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: screenSize.width * 0.12,
            height: screenSize.width * 0.12,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[400]!),
            ),
          ),
          Icon(
            Icons.access_time,
            size: screenSize.width * 0.06,
            color: Colors.orange[600],
          ),
        ],
      ),
    );
  }

  static Widget _buildDiagnosticsSection(
    Map<String, dynamic> diagnostics,
    Map<String, dynamic> deviceInfo,
    Size screenSize,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: screenSize.width * 0.05,
                color: Colors.blue[600],
              ),
              SizedBox(width: screenSize.width * 0.03),
              Text(
                'Analisis Sistem',
                style: TextStyle(
                  fontSize: screenSize.width * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),

          SizedBox(height: screenSize.height * 0.02),

          ...diagnostics.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: screenSize.height * 0.01),
              child: _buildDiagnosticItem(entry.key, entry.value, screenSize),
            );
          }),

          SizedBox(height: screenSize.height * 0.015),

          // Device Info
          Container(
            padding: EdgeInsets.all(screenSize.width * 0.03),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Info Perangkat:',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.032,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: screenSize.height * 0.005),
                Text(
                  '${deviceInfo['model']} - Android ${deviceInfo['version']}',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.03,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  'RAM: ${deviceInfo['memory']} - SDK: ${deviceInfo['sdk']}',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.03,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDiagnosticItem(
    String title,
    Map<String, dynamic> data,
    Size screenSize,
  ) {
    final status = data['status'] as String;
    final message = data['message'] as String;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'good':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Row(
      children: [
        Icon(statusIcon, size: screenSize.width * 0.04, color: statusColor),
        SizedBox(width: screenSize.width * 0.025),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: screenSize.width * 0.032,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                message,
                style: TextStyle(
                  fontSize: screenSize.width * 0.028,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildRecommendations(
    Map<String, dynamic> diagnostics,
    Size screenSize,
  ) {
    final recommendations = _getRecommendations(diagnostics);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: screenSize.width * 0.05,
                color: Colors.blue[600],
              ),
              SizedBox(width: screenSize.width * 0.03),
              Text(
                'Saran Perbaikan',
                style: TextStyle(
                  fontSize: screenSize.width * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),

          SizedBox(height: screenSize.height * 0.015),

          ...recommendations.map((recommendation) {
            return Padding(
              padding: EdgeInsets.only(bottom: screenSize.height * 0.008),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: screenSize.width * 0.015,
                    height: screenSize.width * 0.015,
                    margin: EdgeInsets.only(
                      top: screenSize.height * 0.005,
                      right: screenSize.width * 0.025,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        fontSize: screenSize.width * 0.032,
                        color: Colors.blue[700],
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildActionButtons(
    BuildContext context,
    VoidCallback onRetry,
    Size screenSize,
  ) {
    return Column(
      children: [
        // Retry Button
        SizedBox(
          width: double.infinity,
          height: screenSize.height * 0.06,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: screenSize.width * 0.05),
                SizedBox(width: screenSize.width * 0.02),
                Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: screenSize.height * 0.015),

        // Continue Waiting Button
        SizedBox(
          width: double.infinity,
          height: screenSize.height * 0.05,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              // Restart timeout untuk menunggu lebih lama
              startTimeout(context, onRetry);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Tunggu Lebih Lama (30 detik lagi)',
              style: TextStyle(
                fontSize: screenSize.width * 0.034,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Melakukan diagnostik sistem
  static Future<Map<String, dynamic>> _getDiagnostics() async {
    final diagnostics = <String, dynamic>{};

    // Test koneksi internet
    try {
      final result = await InternetAddress.lookup(
        'dns.google',
      ).timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        diagnostics['Koneksi Internet'] = {
          'status': 'good',
          'message': 'Koneksi internet tersedia',
        };
      } else {
        diagnostics['Koneksi Internet'] = {
          'status': 'error',
          'message': 'Tidak dapat terhubung ke internet',
        };
      }
    } catch (e) {
      diagnostics['Koneksi Internet'] = {
        'status': 'error',
        'message': 'Koneksi internet lambat atau tidak stabil',
      };
    }

    // Test kecepatan respon server
    try {
      final stopwatch = Stopwatch()..start();
      await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      stopwatch.stop();

      final responseTime = stopwatch.elapsedMilliseconds;
      if (responseTime < 1000) {
        diagnostics['Kecepatan Server'] = {
          'status': 'good',
          'message': 'Respon server normal (${responseTime}ms)',
        };
      } else if (responseTime < 3000) {
        diagnostics['Kecepatan Server'] = {
          'status': 'warning',
          'message': 'Respon server agak lambat (${responseTime}ms)',
        };
      } else {
        diagnostics['Kecepatan Server'] = {
          'status': 'error',
          'message': 'Respon server sangat lambat (${responseTime}ms)',
        };
      }
    } catch (e) {
      diagnostics['Kecepatan Server'] = {
        'status': 'error',
        'message': 'Tidak dapat mengukur kecepatan server',
      };
    }

    return diagnostics;
  }

  /// Mendapatkan informasi perangkat
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Estimasi RAM berdasarkan SDK dan model
      String memoryEstimate = 'Tidak diketahui';
      if (androidInfo.version.sdkInt >= 30) {
        memoryEstimate = '4GB+';
      } else if (androidInfo.version.sdkInt >= 28) {
        memoryEstimate = '2-4GB';
      } else if (androidInfo.version.sdkInt >= 24) {
        memoryEstimate = '1-2GB';
      } else {
        memoryEstimate = '<1GB';
      }

      return {
        'model': '${androidInfo.manufacturer} ${androidInfo.model}',
        'version': androidInfo.version.release,
        'sdk': androidInfo.version.sdkInt.toString(),
        'memory': memoryEstimate,
      };
    } catch (e) {
      return {
        'model': 'Tidak diketahui',
        'version': 'Tidak diketahui',
        'sdk': 'Tidak diketahui',
        'memory': 'Tidak diketahui',
      };
    }
  }

  /// Mendapatkan rekomendasi berdasarkan hasil diagnostik
  static List<String> _getRecommendations(Map<String, dynamic> diagnostics) {
    final recommendations = <String>[];

    // Cek koneksi internet
    final internetStatus = diagnostics['Koneksi Internet']?['status'];
    if (internetStatus == 'error') {
      recommendations.addAll([
        'Periksa koneksi WiFi atau data seluler',
        'Coba pindah ke lokasi dengan sinyal yang lebih kuat',
        'Restart router WiFi jika menggunakan WiFi',
      ]);
    }

    // Cek kecepatan server
    final serverStatus = diagnostics['Kecepatan Server']?['status'];
    if (serverStatus == 'warning' || serverStatus == 'error') {
      recommendations.addAll([
        'Server sedang mengalami beban tinggi',
        'Tunggu beberapa menit dan coba lagi',
        'Gunakan koneksi internet yang lebih stabil',
      ]);
    }

    // Rekomendasi umum
    recommendations.addAll([
      'Tutup aplikasi lain yang tidak perlu',
      'Restart aplikasi jika masalah berlanjut',
      'Update aplikasi ke versi terbaru',
    ]);

    return recommendations;
  }
}
