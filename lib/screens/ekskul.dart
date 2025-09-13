// File: ekskul_payment_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:mmkv/mmkv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class EkskulPaymentScreen extends StatefulWidget {
  final String nisn;

  const EkskulPaymentScreen({super.key, required this.nisn})
    : assert(nisn.length > 0, 'NISN tidak boleh kosong');

  // Method untuk validasi NISN
  static bool isValidNISN(String nisn) {
    return nisn.isNotEmpty &&
        nisn.length >= 8 &&
        nisn.length <= 12 &&
        RegExp(r'^\d+$').hasMatch(nisn);
  }

  @override
  State<EkskulPaymentScreen> createState() => _EkskulPaymentScreenState();
}

class _EkskulPaymentScreenState extends State<EkskulPaymentScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shimmerAnimation;

  // Data states
  Map<String, dynamic> _paymentData = {};
  bool _isLoading = true;
  String _errorMessage = '';

  // CSV URLs
  static const List<String> _csvUrls = [
    'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv&gid=1521495544',
    'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv',
  ];

  MMKV? _mmkv;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeMMKV();
    _fetchPaymentData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _shimmerController.repeat();
  }

  Future<void> _initializeMMKV() async {
    try {
      MMKV.initialize();
      _mmkv = MMKV.defaultMMKV();
    } catch (e) {
      _debugLog('Error initializing MMKV: $e');
    }
  }

  // Method untuk log debugging
  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[EkskulPayment] $message');
    }
  }

  Future<void> _fetchPaymentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check internet connectivity
      await InternetAddress.lookup('google.com').timeout(Duration(seconds: 5));

      for (int urlIndex = 0; urlIndex < _csvUrls.length; urlIndex++) {
        final csvUrl = _csvUrls[urlIndex];
        _debugLog('Trying CSV URL ${urlIndex + 1}: $csvUrl');

        try {
          final response = await http
              .get(
                Uri.parse(csvUrl),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                  'Accept': 'text/csv,application/csv,text/plain,*/*',
                  'Cache-Control': 'no-cache',
                },
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200 && response.body.isNotEmpty) {
            final csvData = const CsvToListConverter().convert(response.body);

            if (csvData.isNotEmpty) {
              final paymentData = _parsePaymentCSV(csvData);

              if (paymentData.isNotEmpty) {
                await _processPaymentData(paymentData);
                return;
              }
            }
          }
        } catch (e) {
          _debugLog('Error with URL ${urlIndex + 1}: $e');
        }
      }

      throw Exception('Data NISN ${widget.nisn} tidak ditemukan');
    } catch (e) {
      _handleError('Gagal memuat data pembayaran ekskul: $e');
    }
  }

  Map<String, dynamic> _parsePaymentCSV(List<List<dynamic>> csvData) {
    try {
      if (csvData.length < 5) {
        _debugLog('CSV data tidak memiliki cukup baris: ${csvData.length}');
        return {};
      }

      _debugLog('Mencari data untuk NISN: ${widget.nisn}');
      _debugLog('Total baris CSV: ${csvData.length}');

      // Print sample data untuk debugging
      if (csvData.length > 2) {
        _debugLog('Header: ${csvData[0]}');
        _debugLog('Sample data row: ${csvData[2]}');
      }

      // Start from row 3 (index 2) based on your CSV structure
      for (int i = 2; i < csvData.length; i++) {
        final row = csvData[i];

        // Skip rows that are too short
        if (row.length < 11) {
          _debugLog(
            'Row ${i + 1} terlalu pendek: ${row.length} kolom, data: $row',
          );
          continue;
        }

        final nisn = row[1]?.toString().trim() ?? '';
        final nama = row[2]?.toString().trim() ?? '';

        // Debug setiap baris yang diproses
        _debugLog('Row ${i + 1}: NISN="$nisn", NAMA="$nama"');

        // Skip rows with empty NISN or invalid data
        if (nisn.isEmpty) {
          _debugLog('Baris ${i + 1}: NISN kosong, skip');
          continue;
        }

        // Skip summary/total rows
        if (nisn.toUpperCase().contains('TOTAL') ||
            nisn.toUpperCase().contains('PENGELUARAN') ||
            nama.toUpperCase().contains('TOTAL') ||
            nama.toUpperCase().contains('PENGELUARAN')) {
          _debugLog(
            'Baris ${i + 1}: Skip summary row - NISN: $nisn, NAMA: $nama',
          );
          continue;
        }

        // Skip rows with empty nama
        if (nama.isEmpty) {
          _debugLog('Baris ${i + 1}: Nama kosong untuk NISN: $nisn, skip');
          continue;
        }

        _debugLog(
          'Baris ${i + 1}: Checking NISN: "$nisn" vs Target: "${widget.nisn}"',
        );

        // Check if NISN matches
        if (_isMatchingNISN(widget.nisn, nisn)) {
          _debugLog('Data ditemukan untuk NISN: $nisn di baris ${i + 1}');

          // Parse numeric values with better error handling
          final iuranPerBulan = _parseNumberFromCell(row[5]);
          final iuranTahunan = _parseNumberFromCell(row[6]);
          final nominalDibayar = _parseNumberFromCell(row[7]);
          final sisaPembayaran = _parseNumberFromCell(row[8]);
          final lunasMonths = _parseNumberFromCell(row[9]);
          final sisaTunggakan = _parseNumberFromCell(row[10]);

          final paymentData = {
            'nisn': nisn,
            'nama': nama,
            'status': row[3]?.toString().trim() ?? '',
            'ekskul': row[4]?.toString().trim() ?? '',
            'iuran_per_bulan': iuranPerBulan,
            'iuran_tahunan': iuranTahunan,
            'nominal_dibayar': nominalDibayar,
            'sisa_pembayaran': sisaPembayaran,
            'lunas_bulan_ke': lunasMonths,
            'sisa_tunggakan': sisaTunggakan,
          };

          _debugLog('Data pembayaran berhasil diparse: ${paymentData['nama']}');
          _debugLog('Detail lengkap: $paymentData');
          return paymentData;
        }
      }

      _debugLog(
        'NISN ${widget.nisn} tidak ditemukan dalam ${csvData.length - 2} baris data',
      );

      // Debug: Print semua NISN yang ditemukan untuk membantu troubleshooting
      _debugLog('NISN yang tersedia dalam CSV:');
      for (int i = 2; i < min(csvData.length, 12); i++) {
        final row = csvData[i];
        if (row.length > 1) {
          final foundNisn = row[1]?.toString().trim() ?? '';
          if (foundNisn.isNotEmpty) {
            _debugLog('  - Baris ${i + 1}: "$foundNisn"');
          }
        }
      }

      return {};
    } catch (e, stackTrace) {
      _debugLog('Error parsing payment CSV: $e');
      _debugLog('Stack trace: $stackTrace');
      return {};
    }
  }

  // Improved number parsing method
  int _parseNumberFromCell(dynamic cellValue) {
    if (cellValue == null) {
      _debugLog('parseNumber: null value -> 0');
      return 0;
    }

    String valueStr = cellValue.toString().trim();
    if (valueStr.isEmpty) {
      _debugLog('parseNumber: empty string -> 0');
      return 0;
    }

    // Store original for debugging
    final originalValue = valueStr;

    // Remove common formatting characters
    valueStr = valueStr
        .replaceAll(',', '') // Remove comma thousands separator
        .replaceAll(' ', '') // Remove spaces
        .replaceAll('Rp', '') // Remove currency symbol
        .replaceAll('rp', '') // Remove currency symbol (lowercase)
        .trim();

    // Handle dots - bisa jadi thousands separator atau decimal
    if (valueStr.contains('.')) {
      if (valueStr.contains(',')) {
        valueStr = valueStr.replaceAll('.', '');
        if (valueStr.contains(',')) {
          valueStr = valueStr.split(',')[0];
        }
      } else {
        final parts = valueStr.split('.');
        if (parts.length > 1 && parts.last.length == 3 && parts.length > 2) {
          valueStr = valueStr.replaceAll('.', '');
        } else if (parts.length == 2 && parts.last.length <= 2) {
          valueStr = parts.first;
        } else {
          valueStr = valueStr.replaceAll('.', '');
        }
      }
    }

    // Extract only digits
    final digitsOnly = valueStr.replaceAll(RegExp(r'[^\d]'), '');

    final result = int.tryParse(digitsOnly) ?? 0;
    _debugLog(
      'parseNumber: "$originalValue" -> "$valueStr" -> "$digitsOnly" -> $result',
    );

    return result;
  }

  // Improved NISN matching with more detailed logging
  bool _isMatchingNISN(String targetNISN, String csvNisn) {
    if (targetNISN.isEmpty || csvNisn.isEmpty) {
      _debugLog(
        'NISN matching failed - empty values: target="$targetNISN", csv="$csvNisn"',
      );
      return false;
    }

    final cleanTarget = targetNISN.trim();
    final cleanCsv = csvNisn.trim();

    _debugLog('Comparing NISN: target="$cleanTarget" vs csv="$cleanCsv"');

    // Try exact match first
    if (cleanTarget == cleanCsv) {
      _debugLog('Exact match found!');
      return true;
    }

    // Try case insensitive match
    if (cleanTarget.toLowerCase() == cleanCsv.toLowerCase()) {
      _debugLog('Case insensitive match found!');
      return true;
    }

    // Try numeric comparison (remove leading zeros)
    final targetNumeric = cleanTarget.replaceAll(RegExp(r'^0+'), '');
    final csvNumeric = cleanCsv.replaceAll(RegExp(r'^0+'), '');

    if (targetNumeric.isNotEmpty &&
        csvNumeric.isNotEmpty &&
        targetNumeric == csvNumeric) {
      _debugLog('Numeric match found (ignoring leading zeros)!');
      return true;
    }

    _debugLog('No match found');
    return false;
  }

  Future<void> _processPaymentData(Map<String, dynamic> data) async {
    _shimmerController.stop();

    setState(() {
      _paymentData = data;
      _isLoading = false;
    });

    _animationController.forward();
    await _savePaymentData(data);
  }

  Future<void> _savePaymentData(Map<String, dynamic> data) async {
    if (_mmkv == null) return;

    try {
      final key = 'payment_ekskul_${widget.nisn}';
      _mmkv!.encodeString(key, json.encode(data));
      _debugLog('Data disimpan dengan key: $key');
    } catch (e) {
      _debugLog('Error saving payment data: $e');
    }
  }

  void _handleError(String message) {
    _shimmerController.stop();

    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  // Method untuk navigasi ke halaman invoice
  void _navigateToInvoice(int monthIndex, String monthName) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EkskulInvoiceScreen(
          paymentData: _paymentData,
          monthIndex: monthIndex,
          monthName: monthName,
        ),
      ),
    );
  }

  // Method untuk mendapatkan status pembayaran
  Map<String, dynamic> _getPaymentStatus() {
    final iuranTahunan = _paymentData['iuran_tahunan'] ?? 0;
    final nominalDibayar = _paymentData['nominal_dibayar'] ?? 0;
    final sisaPembayaran = _paymentData['sisa_pembayaran'] ?? 0;
    final lunasMonths = _paymentData['lunas_bulan_ke'] ?? 0;

    String status = 'Belum Lunas';
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending;

    if (sisaPembayaran <= 0 || lunasMonths >= 12) {
      status = 'Lunas';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (nominalDibayar > 0) {
      status = 'Sebagian';
      statusColor = Colors.blue;
      statusIcon = Icons.payment_rounded;
    }

    return {
      'status': status,
      'color': statusColor,
      'icon': statusIcon,
      'progress': iuranTahunan > 0 ? (nominalDibayar / iuranTahunan) : 0.0,
    };
  }

  String _getMonthName(int monthIndex) {
    const months = [
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
    ];
    return monthIndex < months.length
        ? months[monthIndex]
        : 'Bulan ${monthIndex + 1}';
  }

  List<String> _getPaidMonths() {
    final lunasMonths = _paymentData['lunas_bulan_ke'] ?? 0;
    List<String> months = [];

    for (int i = 0; i < lunasMonths; i++) {
      months.add(_getMonthName(i));
    }

    return months;
  }

  String _formatCurrency(int amount) {
    if (amount == 0) return 'Rp 0';

    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return 'Rp $formatted';
  }

  // Method untuk ekspor data ke format yang bisa dibagikan

  // Method untuk handle sharing

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Pembayaran Ekskul',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _paymentData.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchPaymentData,
              tooltip: 'Refresh data',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        color: Colors.red[400],
        onRefresh: _fetchPaymentData,
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStudentInfoShimmer(),
            SizedBox(height: 16),
            _buildPaymentSummaryShimmer(),
            SizedBox(height: 16),
            _buildChartShimmer(),
            SizedBox(height: 16),
            _buildPaymentHistoryShimmer(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage.isNotEmpty && _paymentData.isEmpty) {
      return _buildErrorState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage.isNotEmpty) ...[
                  _buildErrorBanner(),
                  SizedBox(height: 16),
                ],
                _buildStudentInfo(),
                SizedBox(height: 16),
                _buildPaymentSummary(),
                SizedBox(height: 16),
                _buildPaymentChart(),
                SizedBox(height: 16),
                _buildPaymentHistory(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Data tidak ditemukan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'NISN ${widget.nisn} tidak ditemukan dalam sistem',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchPaymentData,
                  icon: Icon(Icons.refresh),
                  label: Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Kembali'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.amber[700], size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.amber[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    final status = _getPaymentStatus();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[400]!, Colors.red[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _paymentData['nama'] ?? 'Nama tidak ditemukan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'NISN: ${_paymentData['nisn'] ?? widget.nisn}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                if (_paymentData['status'] != null &&
                    _paymentData['status'].toString().isNotEmpty) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _paymentData['status'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: status['status'] == "BELUM LUNAS"
                              ? const Color(0xFFF59E0B).withOpacity(0.2)
                              : status['status'] == "LUNAS"
                              ? const Color(0xFF059669).withOpacity(0.2)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: status['status'] == "BELUM LUNAS"
                                ? const Color(0xFFFBBF24).withOpacity(0.3)
                                : status['status'] == "LUNAS"
                                ? const Color(0xFF10B981).withOpacity(0.3)
                                : Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          status['status'],
                          style: TextStyle(
                            color: status['status'] == "BELUM LUNAS"
                                ? const Color(0xFFF59E0B)
                                : status['status'] == "LUNAS"
                                ? const Color(0xFF10B981)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final ekskulText = _paymentData['ekskul']?.toString() ?? '';
    final ekskulCount = ekskulText.toLowerCase().contains('ekskul2')
        ? 2
        : ekskulText.toLowerCase().contains('ekskul1')
        ? 1
        : 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports, color: Colors.red[600], size: 24),
              SizedBox(width: 8),
              Text(
                'Ringkasan Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Tampilkan nama ekstrakurikuler jika ada
          if (ekskulText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_kabaddi, color: Colors.blue[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ekskulText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Ekstrakurikuler',
                  '$ekskulCount Kegiatan',
                  Icons.celebration,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Bulan Lunas',
                  '${_paymentData['lunas_bulan_ke'] ?? 0}/12',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Dibayar',
                  _formatCurrency(_paymentData['nominal_dibayar'] ?? 0),
                  Icons.account_balance_wallet,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Sisa Pembayaran',
                  _formatCurrency(_paymentData['sisa_pembayaran'] ?? 0),
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChart() {
    final iuranTahunan = _paymentData['iuran_tahunan'] ?? 0;
    final nominalDibayar = _paymentData['nominal_dibayar'] ?? 0;
    final sisaPembayaran = _paymentData['sisa_pembayaran'] ?? 0;

    // Calculate progress percentage
    final progressPercentage = iuranTahunan > 0
        ? (nominalDibayar / iuranTahunan)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.red[600], size: 24),
              SizedBox(width: 8),
              Text(
                'Progress Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Progress Bar Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[50]!, Colors.blue[100]!],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!, width: 1),
            ),
            child: Column(
              children: [
                // Progress percentage text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '${(progressPercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Progress Bar
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        height: 12,
                        width:
                            MediaQuery.of(context).size.width *
                            0.7 *
                            progressPercentage,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: progressPercentage >= 1.0
                                ? [Colors.green[400]!, Colors.green[600]!]
                                : progressPercentage >= 0.5
                                ? [Colors.blue[400]!, Colors.blue[600]!]
                                : [Colors.orange[400]!, Colors.red[500]!],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Amount details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sudah Dibayar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatCurrency(nominalDibayar),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Iuran',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatCurrency(iuranTahunan),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Status indicators
          Row(
            children: [
              Expanded(
                child: _buildProgressIndicator(
                  'Terbayar',
                  _formatCurrency(nominalDibayar),
                  progressPercentage >= 1.0
                      ? Colors.green[400]!
                      : Colors.blue[400]!,
                  Icons.check_circle_outline,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildProgressIndicator(
                  'Sisa Bayar',
                  _formatCurrency(sisaPembayaran),
                  sisaPembayaran > 0 ? Colors.orange[400]! : Colors.green[400]!,
                  sisaPembayaran > 0
                      ? Icons.pending_actions
                      : Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final paidMonths = _getPaidMonths();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.red[600], size: 24),
              SizedBox(width: 8),
              Text(
                'Riwayat Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (paidMonths.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada pembayaran',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Data pembayaran akan muncul setelah melakukan pembayaran',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            // Monthly payment details
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments, color: Colors.green[600], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Iuran per bulan: ${_formatCurrency(_paymentData['iuran_per_bulan'] ?? 0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),

            // List of paid months - CLICKABLE untuk invoice
            Column(
              children: paidMonths.asMap().entries.map((entry) {
                final index = entry.key;
                final month = entry.value;
                final isLast = index == paidMonths.length - 1;

                return Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _navigateToInvoice(index, month),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        month,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Text(
                                        'Pembayaran bulan ke-${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (_paymentData['iuran_per_bulan'] !=
                                              null &&
                                          _paymentData['iuran_per_bulan'] >
                                              0) ...[
                                        SizedBox(height: 2),
                                        Text(
                                          _formatCurrency(
                                            _paymentData['iuran_per_bulan'],
                                          ),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[400],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'LUNAS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.receipt_long,
                                      color: Colors.green[600],
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Shimmer components
  Widget _buildStudentInfoShimmer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildShimmerContainer(width: 48, height: 48, borderRadius: 12),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(width: 150, height: 16, borderRadius: 8),
                SizedBox(height: 8),
                _buildShimmerContainer(width: 120, height: 12, borderRadius: 6),
                SizedBox(height: 8),
                _buildShimmerContainer(width: 80, height: 12, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryShimmer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerContainer(width: 180, height: 20, borderRadius: 10),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildShimmerContainer(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildShimmerContainer(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShimmerContainer(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildShimmerContainer(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartShimmer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerContainer(width: 150, height: 20, borderRadius: 10),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerContainer(
                      width: 100,
                      height: 16,
                      borderRadius: 8,
                    ),
                    _buildShimmerContainer(
                      width: 60,
                      height: 16,
                      borderRadius: 8,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildShimmerContainer(
                  width: double.infinity,
                  height: 12,
                  borderRadius: 6,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerContainer(
                      width: 80,
                      height: 14,
                      borderRadius: 7,
                    ),
                    _buildShimmerContainer(
                      width: 80,
                      height: 14,
                      borderRadius: 7,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildShimmerContainer(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildShimmerContainer(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryShimmer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerContainer(width: 160, height: 20, borderRadius: 10),
          SizedBox(height: 20),
          ...List.generate(
            3,
            (index) => Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _buildShimmerContainer(
                    width: 40,
                    height: 40,
                    borderRadius: 20,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildShimmerContainer(
                      width: double.infinity,
                      height: 60,
                      borderRadius: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[100]!,
                    Colors.grey[300]!,
                  ],
                  stops: [0.0, 0.5, 1.0],
                  transform: GradientRotation(_shimmerAnimation.value * 0.3),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// KELAS INVOICE SCREEN TERPISAH
class EkskulInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final int monthIndex;
  final String monthName;

  const EkskulInvoiceScreen({
    super.key,
    required this.paymentData,
    required this.monthIndex,
    required this.monthName,
  });

  @override
  State<EkskulInvoiceScreen> createState() => _EkskulInvoiceScreenState();
}

class _EkskulInvoiceScreenState extends State<EkskulInvoiceScreen>
    with TickerProviderStateMixin {
  final GlobalKey _invoiceKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  String _generateInvoiceNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'INV-${timestamp.toString().substring(6)}-${random.toString().padLeft(4, '0')}';
  }

  String _formatCurrency(int amount) {
    if (amount == 0) return 'Rp 0';
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _downloadInvoice() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Haptic feedback
      HapticFeedback.lightImpact();

      // Capture widget as image
      RenderRepaintBoundary boundary =
          _invoiceKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Higher resolution for better quality
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to device
      await _saveImageToDevice(pngBytes);
    } catch (e) {
      _showErrorSnackBar('Gagal mengunduh invoice: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _copyInvoiceSummary() async {
    try {
      HapticFeedback.lightImpact();

      final summary = _generateTextSummary();
      await Clipboard.setData(ClipboardData(text: summary));

      _showSuccessSnackBar('Ringkasan invoice disalin ke clipboard');
    } catch (e) {
      _showErrorSnackBar('Gagal menyalin ringkasan: $e');
    }
  }

  Future<void> _saveImageToDevice(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Invoice_Ekskul_${widget.paymentData['nisn']}_${widget.monthName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes);

      _showSuccessSnackBar('Invoice berhasil disimpan: $fileName');
    } catch (e) {
      _showErrorSnackBar('Gagal menyimpan file: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _shareInvoice() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      HapticFeedback.lightImpact();

      // Ambil widget sebagai image
      RenderRepaintBoundary boundary =
          _invoiceKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Simpan ke file sementara
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/invoice.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Share file menggunakan share_plus
      await Share.shareXFiles([XFile(filePath)], text: 'Invoice Anda');

      _showSuccessSnackBar('Invoice berhasil dibagikan');
    } catch (e) {
      _showErrorSnackBar('Gagal membagikan invoice: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _generateTextSummary() {
    final invoiceNumber = _generateInvoiceNumber();
    final currentDate = _formatDate(DateTime.now());
    final iuranPerBulan = widget.paymentData['iuran_per_bulan'] ?? 0;

    return '''
🧾 BUKTI PEMBAYARAN EKSTRAKURIKULER

No. Invoice: $invoiceNumber
Tanggal: $currentDate

👤 INFORMASI SISWA:
Nama: ${widget.paymentData['nama']}
NISN: ${widget.paymentData['nisn']}
Ekstrakurikuler: ${widget.paymentData['ekskul']}

💰 DETAIL PEMBAYARAN:
Periode: ${widget.monthName} (Bulan ke-${widget.monthIndex + 1})
Jumlah: ${_formatCurrency(iuranPerBulan)}
Status: LUNAS ✅

📍 Pesantren Islam Zaid bin Tsabit
Sistem Pembayaran Ekstrakurikuler
$currentDate
    ''';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Invoice Pembayaran',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.copy_all_rounded, size: isSmallScreen ? 20 : 24),
            onPressed: _isGenerating ? null : _downloadInvoice,
            tooltip: 'Download',
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                // Invoice Widget
                RepaintBoundary(
                  key: _invoiceKey,
                  child: _buildInvoiceWidget(screenSize, isSmallScreen),
                ),

                SizedBox(height: 20),

                // Action Buttons
                _buildActionButtons(isSmallScreen),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceWidget(Size screenSize, bool isSmallScreen) {
    final invoiceNumber = _generateInvoiceNumber();
    final currentDate = DateTime.now();
    final iuranPerBulan = widget.paymentData['iuran_per_bulan'] ?? 0;

    // Calculate responsive sizes
    final invoiceWidth = screenSize.width - (isSmallScreen ? 24 : 32);
    final headerFontSize = isSmallScreen ? 16.0 : 18.0;
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final bodyFontSize = isSmallScreen ? 12.0 : 14.0;
    final smallFontSize = isSmallScreen ? 10.0 : 12.0;

    return Container(
      width: invoiceWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green[600]!, Colors.green[600]!],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesantren Islam Zaid bin Tsabit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sistem Pembayaran Ekstrakurikuler',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: smallFontSize,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'BUKTI PEMBAYARAN EKSKUL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Invoice Details
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No. Invoice',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          invoiceNumber,
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tanggal',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatDate(currentDate),
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Divider(height: 32, thickness: 1, color: Colors.grey[300]),

                // Student Information
                _buildInfoSection(
                  'INFORMASI SISWA',
                  [
                    _buildInfoRow(
                      'Nama',
                      widget.paymentData['nama'] ?? '-',
                      bodyFontSize,
                      smallFontSize,
                    ),
                    _buildInfoRow(
                      'NISN',
                      widget.paymentData['nisn'] ?? '-',
                      bodyFontSize,
                      smallFontSize,
                    ),
                    _buildInfoRow(
                      'Ekstrakurikuler',
                      widget.paymentData['ekskul'] ?? '-',
                      bodyFontSize,
                      smallFontSize,
                    ),
                    _buildInfoRow(
                      'Status',
                      widget.paymentData['status'] ?? '-',
                      bodyFontSize,
                      smallFontSize,
                    ),
                  ],
                  titleFontSize,
                  isSmallScreen,
                ),

                SizedBox(height: 20),

                // Payment Details
                _buildInfoSection(
                  'DETAIL PEMBAYARAN',
                  [
                    _buildInfoRow(
                      'Periode',
                      '${widget.monthName} (Bulan ke-${widget.monthIndex + 1})',
                      bodyFontSize,
                      smallFontSize,
                    ),
                    _buildInfoRow(
                      'Iuran per Bulan',
                      _formatCurrency(iuranPerBulan),
                      bodyFontSize,
                      smallFontSize,
                    ),
                  ],
                  titleFontSize,
                  isSmallScreen,
                ),

                SizedBox(height: 20),

                // Payment Amount - Highlighted
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green[50]!, Colors.green[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL PEMBAYARAN',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 10,
                              vertical: isSmallScreen ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LUNAS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: smallFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatCurrency(iuranPerBulan),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Payment Method (Simulated)
                _buildInfoSection(
                  'METODE PEMBAYARAN',
                  [
                    _buildInfoRow(
                      'Via',
                      'Transfer Bank / Tunai',
                      bodyFontSize,
                      smallFontSize,
                    ),
                    _buildInfoRow(
                      'Waktu Pembayaran',
                      _formatDate(currentDate),
                      bodyFontSize,
                      smallFontSize,
                    ),
                  ],
                  titleFontSize,
                  isSmallScreen,
                ),

                SizedBox(height: 24),

                // Footer
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green[600],
                            size: isSmallScreen ? 16 : 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'PEMBAYARAN TERVERIFIKASI',
                            style: TextStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Invoice ini adalah bukti sah pembayaran ekstrakurikuler',
                        style: TextStyle(
                          fontSize: smallFontSize,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Simpan bukti ini untuk keperluan administrasi',
                        style: TextStyle(
                          fontSize: smallFontSize - 1,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<Widget> children,
    double titleFontSize,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    double bodyFontSize,
    double smallFontSize,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: smallFontSize,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: smallFontSize, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: bodyFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Perbaiki widget _buildActionButtons
  Widget _buildActionButtons(bool isSmallScreen) {
    return Column(
      children: [
        // Baris pertama - tombol utama
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _shareInvoice,
                icon: _isGenerating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.share, size: isSmallScreen ? 18 : 20),
                label: Text(
                  _isGenerating ? 'Proses...' : 'Share Invoice',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  elevation: 0, // <-- hilangkan shadow
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _copyInvoiceSummary,
                icon: Icon(
                  Icons.copy_all_rounded,
                  size: isSmallScreen ? 18 : 20,
                ),
                label: Text(
                  'Salin Invoice',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
