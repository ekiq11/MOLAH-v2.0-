// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String nisn;
  final String studentName;

  const TransactionHistoryPage({
    super.key,
    required this.nisn,
    required this.studentName,
  });

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  // Data states
  Map<String, dynamic> _summaryData = {};
  List<TransactionItem> _allTransactions = [];
  List<TransactionItem> _displayedTransactions = [];
  List<TopUpItem> _allTopUps = [];
  List<TopUpItem> _displayedTopUps = [];
  bool _isLoadingSummary = true;
  bool _isLoadingTransactions = true;
  bool _isLoadingTopUps = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  // Tab states
  int _selectedTabIndex = 0; // 0 = Aktivitas Transaksi, 1 = Riwayat Top Up

  // Pagination
  final int _itemsPerPage = 10;
  int _currentTransactionPage = 0;
  int _currentTopUpPage = 0;
  bool _hasMoreTransactionData = true;
  bool _hasMoreTopUpData = true;
  final ScrollController _scrollController = ScrollController();

  // CSV URLs
  static const String _summaryUrl =
      'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=2094342731';
  static const String _transactionUrl =
      'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=2012044980';
  static const String _topUpUrl =
      'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=919906307';
  static const String _topUpHistoryUrl =
      'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=995828092';

  // Tambahkan variabel untuk menyimpan top-up
  Map<String, int> _topUpData = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _shimmerController.repeat();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore) {
          if (_selectedTabIndex == 0 && _hasMoreTransactionData) {
            _loadMoreTransactions();
          } else if (_selectedTabIndex == 1 && _hasMoreTopUpData) {
            _loadMoreTopUps();
          }
        }
      }
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSummaryData(),
      _loadTransactionData(),
      _loadTopUpData(),
      _loadTopUpHistoryData(),
    ]);
  }

  Future<void> _loadTopUpHistoryData() async {
    try {
      print('🔍 Loading top-up history data...');

      final response = await http
          .get(
            Uri.parse(_topUpHistoryUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'text/csv,application/csv,text/plain,*/*',
            },
          )
          .timeout(const Duration(seconds: 20));

      print('📡 Top-up history response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final csvData = const CsvToListConverter().convert(response.body);
        print('📊 Top-up history CSV parsed: ${csvData.length} rows');

        if (csvData.isNotEmpty) {
          final topUps = _parseTopUpHistoryData(csvData);

          if (mounted) {
            setState(() {
              _allTopUps = topUps;
              _displayedTopUps = topUps.take(_itemsPerPage).toList();
              _hasMoreTopUpData = topUps.length > _itemsPerPage;
              _isLoadingTopUps = false;
            });
          }
        }
      }
    } catch (e) {
      print('❌ Top-up history load error: $e');
      if (mounted) {
        setState(() {
          _isLoadingTopUps = false;
        });
      }
    }
  }

  List<TopUpItem> _parseTopUpHistoryData(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) {
      print('❌ Top-up history CSV is empty');
      return [];
    }
    List<TopUpItem> topUps = [];
    // Get headers
    final headers = csvData[0]
        .map((e) => e.toString().toLowerCase().trim())
        .toList();
    print('📊 Top-up history headers: $headers');

    // Find column indices (KOLOM A = index 0, KOLOM B = index 1, KOLOM D = index 3, KOLOM E = index 4, KOLOM I = index 8)
    int waktuIndex = 0; // KOLOM A
    int tanggalIndex = 1; // KOLOM B
    int kodeTransaksiIndex = 3; // KOLOM D ← ✅ SUDAH DITAMBAHKAN!
    int nisnIndex = 4; // KOLOM E
    int topUpIndex = 8; // KOLOM I

    print(
      '📍 Top-up history column indices: Waktu=$waktuIndex, Tanggal=$tanggalIndex, KodeTransaksi=$kodeTransaksiIndex, NISN=$nisnIndex, TopUp=$topUpIndex',
    );

    // Parse top-ups
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.length < 9) {
        print('⚠️ Top-up row $i has insufficient columns: ${row.length}');
        continue;
      }
      final csvNisn = row[nisnIndex].toString().trim();
      if (csvNisn.isEmpty) {
        print('⚠️ Top-up row $i has empty NISN');
        continue;
      }
      print('🔍 Top-up row $i: NISN="$csvNisn", Target="${widget.nisn}"');
      if (_isMatchingNisn(widget.nisn, csvNisn)) {
        print('✅ Top-up match found at row $i');
        try {
          final waktu = row[waktuIndex].toString().trim();
          final tanggal = row[tanggalIndex].toString().trim();
          final topUpStr = row[topUpIndex].toString().trim();
          final topUpValue =
              int.tryParse(topUpStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

          if (topUpValue > 0) {
            // ✅ KODE TRANSAKSI DIAMBIL DARI KOLOM D (index 3)
            final topUp = TopUpItem(
              waktu: waktu,
              tanggal: tanggal,
              kodeTransaksi: row[kodeTransaksiIndex]
                  .toString()
                  .trim(), // ✅ INI YANG DIUBAH!
              nisn: csvNisn,
              nama: widget.studentName,
              topUpAmount: _formatCurrency(topUpValue.toString()),
            );
            topUps.add(topUp);
            print(
              '💚 Added top-up: ${topUp.tanggal} ${topUp.waktu} - ${topUp.topUpAmount} (Kode: ${topUp.kodeTransaksi})',
            );
          }
        } catch (e) {
          print('❌ Error parsing top-up row $i: $e');
        }
      }
    }

    print('💚 Total top-ups found: ${topUps.length}');
    // Sort by date/time descending
    topUps.sort((a, b) {
      try {
        final aDate = _parseDateTime(a.tanggal, a.waktu);
        final bDate = _parseDateTime(b.tanggal, b.waktu);
        return bDate.compareTo(aDate);
      } catch (e) {
        print('❌ Error sorting top-ups: $e');
        final aDateTimeStr = '${a.tanggal} ${a.waktu}';
        final bDateTimeStr = '${b.tanggal} ${b.waktu}';
        return bDateTimeStr.compareTo(aDateTimeStr);
      }
    });
    return topUps;
  }

  Future<void> _loadMoreTopUps() async {
    if (_isLoadingMore || !_hasMoreTopUpData) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final startIndex = (_currentTopUpPage + 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex < _allTopUps.length) {
      final newTopUps = _allTopUps.sublist(
        startIndex,
        endIndex > _allTopUps.length ? _allTopUps.length : endIndex,
      );

      if (mounted) {
        setState(() {
          _displayedTopUps.addAll(newTopUps);
          _currentTopUpPage++;
          _hasMoreTopUpData = endIndex < _allTopUps.length;
          _isLoadingMore = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasMoreTopUpData = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadTopUpData() async {
    try {
      print('🔍 Loading top-up data...');

      final response = await http
          .get(
            Uri.parse(_topUpUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'text/csv,application/csv,text/plain,*/*',
            },
          )
          .timeout(const Duration(seconds: 20));

      print('📡 Top-up response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final csvData = const CsvToListConverter().convert(response.body);
        print('📊 Top-up CSV parsed: ${csvData.length} rows');

        if (csvData.isNotEmpty) {
          _parseTopUpData(csvData);
        }
      }
    } catch (e) {
      print('❌ Top-up load error: $e');
      // Tetap lanjutkan, karena ini opsional
    }
  }

  void _parseTopUpData(List<List<dynamic>> csvData) {
    if (csvData.length < 2) {
      print('⚠️ Top-up CSV is empty or invalid');
      return;
    }

    final headers = csvData[0]
        .map((e) => e.toString().toLowerCase().trim().replaceAll(' ', '_'))
        .toList();

    int nisnIndex = -1;
    int topUpIndex = -1;

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (h.contains('nisn')) nisnIndex = i;
      if (h.contains('jumlah_top_up') || h.contains('top_up')) topUpIndex = i;
    }

    if (nisnIndex == -1 || topUpIndex == -1) {
      print('❌ Top-up columns not found: nisn=$nisnIndex, topUp=$topUpIndex');
      return;
    }

    _topUpData.clear();

    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.length <= nisnIndex || row.length <= topUpIndex) continue;

      final nisn = row[nisnIndex].toString().trim();
      final topUpStr = row[topUpIndex].toString().trim();
      final topUpValue = int.tryParse(topUpStr) ?? 0;

      if (nisn.isNotEmpty) {
        _topUpData[nisn] = topUpValue;
        print('📥 Top-up data: $nisn -> Rp$topUpValue');
      }
    }
  }

  Future<void> _loadSummaryData() async {
    try {
      print('🔍 Loading summary data for NISN: ${widget.nisn}');

      final response = await http
          .get(
            Uri.parse(_summaryUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'text/csv,application/csv,text/plain,*/*',
            },
          )
          .timeout(const Duration(seconds: 20));

      print('📡 Summary response status: ${response.statusCode}');
      print('📄 Summary response length: ${response.body.length}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final csvData = const CsvToListConverter().convert(response.body);
        print('📊 Summary CSV parsed: ${csvData.length} rows');

        if (csvData.isNotEmpty) {
          print('📊 Summary headers: ${csvData[0]}');
          final summary = _parseSummaryData(csvData);

          if (mounted) {
            setState(() {
              _summaryData = summary;
              _isLoadingSummary = false;
            });
          }
        }
      }
    } catch (e) {
      print('❌ Summary load error: $e');
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
          _errorMessage = 'Gagal memuat data ringkasan: $e';
        });
      }
    }
  }

  Future<void> _loadTransactionData() async {
    try {
      print('🔍 Loading transaction data for NISN: ${widget.nisn}');

      final response = await http
          .get(
            Uri.parse(_transactionUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'text/csv,application/csv,text/plain,*/*',
            },
          )
          .timeout(const Duration(seconds: 20));

      print('📡 Transaction response status: ${response.statusCode}');
      print('📄 Transaction response length: ${response.body.length}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final csvData = const CsvToListConverter().convert(response.body);
        print('📊 Transaction CSV parsed: ${csvData.length} rows');

        if (csvData.isNotEmpty) {
          print('📊 Transaction headers: ${csvData[0]}');
          final transactions = _parseTransactionData(csvData);
          print(
            '📋 Found ${transactions.length} transactions for NISN: ${widget.nisn}',
          );

          if (mounted) {
            setState(() {
              _allTransactions = transactions;
              _displayedTransactions = transactions
                  .take(_itemsPerPage)
                  .toList();
              _hasMoreTransactionData = transactions.length > _itemsPerPage;
              _isLoadingTransactions = false;
            });

            if (!_isLoadingSummary) {
              _shimmerController.stop();
            }
          }
        }
      }
    } catch (e) {
      print('❌ Transaction load error: $e');
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
          _errorMessage = 'Gagal memuat data transaksi: $e';
        });
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreTransactionData) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final startIndex = (_currentTransactionPage + 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex < _allTransactions.length) {
      final newTransactions = _allTransactions.sublist(
        startIndex,
        endIndex > _allTransactions.length ? _allTransactions.length : endIndex,
      );

      if (mounted) {
        setState(() {
          _displayedTransactions.addAll(newTransactions);
          _currentTransactionPage++;
          _hasMoreTransactionData = endIndex < _allTransactions.length;
          _isLoadingMore = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasMoreTransactionData = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Map<String, dynamic> _parseSummaryData(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) {
      print('❌ Summary CSV is empty');
      return _getDefaultSummary();
    }

    final headers = csvData[0]
        .map((e) => e.toString().toLowerCase().trim().replaceAll(' ', '_'))
        .toList();
    print('📊 Summary headers processed: $headers');

    int nisnIndex = -1;
    int namaIndex = -1;
    int totalMasukIndex = -1;
    int totalKeluarIndex = -1;

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (header.contains('nisn') || header.contains('no_induk')) nisnIndex = i;
      if (header.contains('nama')) namaIndex = i;
      if (header.contains('total_masuk') || header.contains('masuk'))
        totalMasukIndex = i;
      if (header.contains('total_keluar') || header.contains('keluar'))
        totalKeluarIndex = i;
    }

    if (nisnIndex == -1) nisnIndex = 0;
    if (namaIndex == -1) namaIndex = 1;
    if (totalMasukIndex == -1) totalMasukIndex = 2;
    if (totalKeluarIndex == -1) totalKeluarIndex = 3;

    print(
      '📍 Summary indices: NISN=$nisnIndex, Nama=$namaIndex, Masuk=$totalMasukIndex, Keluar=$totalKeluarIndex',
    );

    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.length <= nisnIndex) continue;

      final csvNisn = row[nisnIndex].toString().trim();
      print('🔍 Checking summary row $i: "$csvNisn" vs "${widget.nisn}"');

      if (_isMatchingNisn(widget.nisn, csvNisn)) {
        print('✅ Match found in summary data at row $i');

        final nama = row.length > namaIndex
            ? row[namaIndex].toString().trim()
            : widget.studentName;

        // Ambil total masuk dari CSV (tanpa Rp)
        String masukStr = row.length > totalMasukIndex
            ? row[totalMasukIndex].toString().replaceAll(RegExp(r'[^\d]'), '')
            : '0';
        int totalMasuk = int.tryParse(masukStr) ?? 0;

        // Ambil top-up dari sheet top-up
        int topUp = _topUpData[csvNisn] ?? 0;
        int finalMasuk = totalMasuk + topUp;

        // Ambil total keluar
        String keluarStr = row.length > totalKeluarIndex
            ? row[totalKeluarIndex].toString().replaceAll(RegExp(r'[^\d]'), '')
            : '0';
        int totalKeluar = int.tryParse(keluarStr) ?? 0;

        print('💰 Total Masuk: $totalMasuk + Top-up: $topUp = $finalMasuk');
        print('💸 Total Keluar: $totalKeluar');

        return {
          'nisn': csvNisn,
          'nama': nama,
          'total_masuk': _formatCurrency(finalMasuk.toString()),
          'total_keluar': _formatCurrency(totalKeluar.toString()),
        };
      }
    }

    print('❌ No matching NISN found in summary data');
    return _getDefaultSummary();
  }

  Map<String, dynamic> _getDefaultSummary() {
    final topUp = _topUpData[widget.nisn] ?? 0;
    return {
      'nisn': widget.nisn,
      'nama': widget.studentName,
      'total_masuk': _formatCurrency(
        topUp.toString(),
      ), // Jika tidak ditemukan, minimal top-up
      'total_keluar': 'Rp0',
    };
  }

  List<TransactionItem> _parseTransactionData(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) {
      print('❌ Transaction CSV is empty');
      return [];
    }

    List<TransactionItem> transactions = [];

    // Get headers
    final headers = csvData[0]
        .map((e) => e.toString().toLowerCase().trim())
        .toList();
    print('📊 Transaction headers: $headers');

    // Find NISN column index - it should be column 3 based on your example
    int nisnIndex = -1;
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (header.contains('nisn') || i == 3) {
        // Column 3 based on your example
        nisnIndex = i;
        break;
      }
    }

    if (nisnIndex == -1) {
      nisnIndex = 3; // Default to column 3 as per your example
    }

    print('📍 Transaction NISN column index: $nisnIndex');

    // Parse transactions
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.length < 6) {
        print('⚠️ Row $i has insufficient columns: ${row.length}');
        continue;
      }

      final csvNisn = row.length > nisnIndex
          ? row[nisnIndex].toString().trim()
          : '';

      if (csvNisn.isEmpty) {
        print('⚠️ Row $i has empty NISN');
        continue;
      }

      print('🔍 Transaction row $i: NISN="$csvNisn", Target="${widget.nisn}"');

      if (_isMatchingNisn(widget.nisn, csvNisn)) {
        print('✅ Transaction match found at row $i');

        try {
          final transaction = TransactionItem(
            waktu: row.length > 0 ? row[0].toString().trim() : '',
            tanggal: row.length > 1 ? row[1].toString().trim() : '',
            kodeTransaksi: row.length > 2 ? row[2].toString().trim() : '',
            nisn: csvNisn,
            uidKartu: row.length > 4 ? row[4].toString().trim() : '',
            nama: row.length > 5
                ? row[5].toString().trim()
                : widget.studentName,
            sisaSaldo: row.length > 6
                ? _formatCurrency(row[6].toString())
                : 'Rp0',
            pemakaian: row.length > 7
                ? _formatCurrency(row[7].toString())
                : 'Rp0',
          );

          transactions.add(transaction);
          print(
            '📋 Added transaction: ${transaction.tanggal} ${transaction.waktu}',
          );
        } catch (e) {
          print('❌ Error parsing transaction row $i: $e');
        }
      }
    }

    print('📋 Total transactions found: ${transactions.length}');

    // Sort by date/time descending (most recent first)
    transactions.sort((a, b) {
      try {
        final aDate = _parseDateTime(a.tanggal, a.waktu);
        final bDate = _parseDateTime(b.tanggal, b.waktu);

        // Sort descending (newest first) - bDate dibandingkan dengan aDate
        final comparison = bDate.compareTo(aDate);

        print(
          '🔄 Comparing: ${a.tanggal} ${a.waktu} (${aDate.toString()}) vs ${b.tanggal} ${b.waktu} (${bDate.toString()}) = $comparison',
        );

        return comparison;
      } catch (e) {
        print('❌ Error sorting transactions: $e');
        // Fallback: try to sort by string comparison of date/time
        final aDateTimeStr = '${a.tanggal} ${a.waktu}';
        final bDateTimeStr = '${b.tanggal} ${b.waktu}';
        return bDateTimeStr.compareTo(aDateTimeStr);
      }
    });

    print('🔄 Transactions sorted by datetime (newest first)');

    return transactions;
  }

  // Perbaiki fungsi _parseDateTime untuk parsing yang lebih akurat
  DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      // Bersihkan string
      final cleanDate = dateStr.trim();
      final cleanTime = timeStr.trim();

      // Asumsikan format tanggal adalah dd/MM/yyyy
      List<String> dateParts = cleanDate.split('/');
      if (dateParts.length != 3) {
        // Jika bukan dd/MM/yyyy, coba dd-MM-yyyy
        dateParts = cleanDate.split('-');
      }
      if (dateParts.length != 3) {
        throw FormatException('Invalid date format');
      }

      final day = int.tryParse(dateParts[0]) ?? 1;
      final month = int.tryParse(dateParts[1]) ?? 1;
      int year = int.tryParse(dateParts[2]) ?? DateTime.now().year;

      // Handle 2-digit year (misal, 24 -> 2024)
      if (year < 100) {
        year = 2000 + year; // Asumsikan tahun 2000-an
      }

      // Asumsikan format waktu adalah HH.MM.SS atau HH:MM:SS
      List<String> timeParts = cleanTime.split('.');
      if (timeParts.length != 3) {
        timeParts = cleanTime.split(':');
      }
      if (timeParts.length < 2) {
        throw FormatException('Invalid time format');
      }

      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      final second = timeParts.length > 2 ? int.tryParse(timeParts[2]) ?? 0 : 0;

      final result = DateTime(year, month, day, hour, minute, second);
      print('🔧 Parsed: "$dateStr $timeStr" -> ${result.toString()}');
      return result;
    } catch (e) {
      print('❌ Error parsing datetime: $dateStr $timeStr - $e');
      // Jika parsing gagal, kembalikan tanggal jauh di masa lalu agar transaksi yang error muncul di paling bawah.
      return DateTime(1970);
    }
  }

  bool _isMatchingNisn(String targetNisn, String csvNisn) {
    if (targetNisn.isEmpty || csvNisn.isEmpty) return false;

    final cleanTarget = targetNisn.toLowerCase().trim();
    final cleanCsv = csvNisn.toLowerCase().trim();

    print('🔍 Matching: "$cleanTarget" vs "$cleanCsv"');

    // Exact match
    if (cleanTarget == cleanCsv) {
      print('✅ Exact match found');
      return true;
    }

    // Remove all non-numeric characters and compare
    final numericTarget = cleanTarget.replaceAll(RegExp(r'[^0-9]'), '');
    final numericCsv = cleanCsv.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericTarget.isNotEmpty && numericCsv.isNotEmpty) {
      if (numericTarget == numericCsv) {
        print('✅ Numeric match found');
        return true;
      }

      // Try removing leading zeros
      final normalizedTarget = numericTarget.replaceAll(RegExp(r'^0+'), '');
      final normalizedCsv = numericCsv.replaceAll(RegExp(r'^0+'), '');

      if (normalizedTarget.isNotEmpty &&
          normalizedCsv.isNotEmpty &&
          normalizedTarget == normalizedCsv) {
        print('✅ Normalized numeric match found');
        return true;
      }
    }

    // Contains check for longer strings
    if (cleanTarget.length > 3 && cleanCsv.length > 3) {
      if (cleanTarget.contains(cleanCsv) || cleanCsv.contains(cleanTarget)) {
        print('✅ Contains match found');
        return true;
      }
    }

    print('❌ No match found');
    return false;
  }

  String _formatCurrency(String value) {
    if (value.isEmpty || value == '0') return 'Rp0';
    if (value.startsWith('Rp')) return value;

    final clean = value.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return 'Rp0';

    final number = int.tryParse(clean) ?? 0;
    if (number == 0) return 'Rp0';

    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Riwayat Transaksi',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: RefreshIndicator(
        color: Colors.red[400],
        onRefresh: () async {
          setState(() {
            _isLoadingSummary = true;
            _isLoadingTransactions = true;
            _isLoadingTopUps = true;
            _currentTransactionPage = 0;
            _currentTopUpPage = 0;
            _displayedTransactions.clear();
            _displayedTopUps.clear();
            _allTransactions.clear();
            _allTopUps.clear();
            _hasMoreTransactionData = true;
            _hasMoreTopUpData = true;
            _errorMessage = '';
          });
          _shimmerController.repeat();
          await _loadData();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Summary Section
              _isLoadingSummary ? _buildSummaryShimmer() : _buildSummaryCard(),
              const SizedBox(height: 20),

              // Tab Selection
              _buildTabSelector(),
              const SizedBox(height: 12),

              // Content based on selected tab
              if (_selectedTabIndex == 0) ...[
                // Transaction List Header
                Text(
                  'Aktivitas Transaksi (${_allTransactions.length} transaksi)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // Transaction List
                _isLoadingTransactions
                    ? _buildTransactionListShimmer()
                    : _buildTransactionList(),
              ] else ...[
                // Top Up List Header
                Text(
                  'Riwayat Top Up (${_allTopUps.length} top up)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // Top Up List
                _isLoadingTopUps
                    ? _buildTransactionListShimmer()
                    : _buildTopUpList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? Colors.red[400]
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: _selectedTabIndex == 0
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Aktivitas Transaksi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _selectedTabIndex == 0
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? Colors.green[400]
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle,
                      size: 18,
                      color: _selectedTabIndex == 1
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Riwayat Top Up',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _selectedTabIndex == 1
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _summaryData['nama'] ?? widget.studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'NISN: ${_summaryData['nisn'] ?? widget.nisn}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Masuk',
                  _summaryData['total_masuk'] ?? 'Rp0',
                  Icons.arrow_downward,
                  Colors.green[400]!,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Total Keluar',
                  _summaryData['total_keluar'] ?? 'Rp0',
                  Icons.arrow_upward,
                  Colors.orange[400]!,
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
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_displayedTransactions.isEmpty && _allTransactions.isEmpty) {
      return _buildEmptyState('Belum ada transaksi', Icons.receipt_long);
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _displayedTransactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildTransactionItem(_displayedTransactions[index]);
          },
        ),
        if (_isLoadingMore && _selectedTabIndex == 0) ...[
          const SizedBox(height: 16),
          _buildLoadMoreShimmer(),
        ],
        if (!_hasMoreTransactionData && _displayedTransactions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Semua transaksi telah ditampilkan',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopUpList() {
    if (_displayedTopUps.isEmpty && _allTopUps.isEmpty) {
      return _buildEmptyState('Belum ada riwayat top up', Icons.add_circle);
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _displayedTopUps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildTopUpItem(_displayedTopUps[index]);
          },
        ),
        if (_isLoadingMore && _selectedTabIndex == 1) ...[
          const SizedBox(height: 16),
          _buildLoadMoreShimmer(),
        ],
        if (!_hasMoreTopUpData && _displayedTopUps.isNotEmpty) ...[
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Semua riwayat top up telah ditampilkan',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionItem(TransactionItem transaction) {
    final pemakaianValue = transaction.pemakaian.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final isExpense =
        pemakaianValue.isNotEmpty &&
        int.tryParse(pemakaianValue) != null &&
        int.parse(pemakaianValue) > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isExpense ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: isExpense ? Colors.red[600] : Colors.green[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isExpense ? 'Pengeluaran' : 'Pemasukan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      isExpense ? transaction.pemakaian : transaction.sisaSaldo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isExpense ? Colors.red[600] : Colors.green[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.waktu}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (transaction.kodeTransaksi.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Kode: ${transaction.kodeTransaksi}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpItem(TopUpItem topUp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: Colors.green[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.add_circle, color: Colors.green[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Up Saldo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      topUp.topUpAmount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${topUp.waktu}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Kode: ${topUp.kodeTransaksi}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${message == 'Belum ada transaksi' ? 'Riwayat transaksi' : 'Riwayat top up'} akan muncul di sini\nNISN: ${widget.nisn}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Shimmer Effects
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
                  stops: const [0.0, 0.5, 1.0],
                  transform: GradientRotation(_shimmerAnimation.value * 0.3),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryShimmer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerContainer(width: 24, height: 24, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerContainer(width: 200, height: 18),
                    const SizedBox(height: 4),
                    _buildShimmerContainer(width: 120, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildShimmerContainer(
                  width: double.infinity,
                  height: 70,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildShimmerContainer(
                  width: double.infinity,
                  height: 70,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionListShimmer() {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildShimmerContainer(width: 40, height: 40, borderRadius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildShimmerContainer(width: 100, height: 14),
                          _buildShimmerContainer(width: 80, height: 16),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildShimmerContainer(width: 120, height: 12),
                      const SizedBox(height: 4),
                      _buildShimmerContainer(width: 150, height: 11),
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

  Widget _buildLoadMoreShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildShimmerContainer(width: 40, height: 40, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                _buildShimmerContainer(width: 120, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Transaction data model
class TransactionItem {
  final String waktu;
  final String tanggal;
  final String kodeTransaksi;
  final String nisn;
  final String uidKartu;
  final String nama;
  final String sisaSaldo;
  final String pemakaian;

  TransactionItem({
    required this.waktu,
    required this.tanggal,
    required this.kodeTransaksi,
    required this.nisn,
    required this.uidKartu,
    required this.nama,
    required this.sisaSaldo,
    required this.pemakaian,
  });

  @override
  String toString() {
    return 'TransactionItem(waktu: $waktu, tanggal: $tanggal, kodeTransaksi: $kodeTransaksi, nisn: $nisn, nama: $nama, sisaSaldo: $sisaSaldo, pemakaian: $pemakaian)';
  }

  // Helper method to check if this is an expense transaction
  bool get isExpense {
    final pemakaianValue = pemakaian.replaceAll(RegExp(r'[^\d]'), '');
    return pemakaianValue.isNotEmpty &&
        int.tryParse(pemakaianValue) != null &&
        int.parse(pemakaianValue) > 0;
  }

  // Helper method to get the transaction amount
  String get transactionAmount {
    return isExpense ? pemakaian : sisaSaldo;
  }

  // Helper method to get formatted transaction type
  String get transactionType {
    return isExpense ? 'Pengeluaran' : 'Pemasukan';
  }

  // Helper method to get formatted date time
  String get formattedDateTime {
    return '$tanggal $waktu';
  }

  // Convert to Map for easy JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'waktu': waktu,
      'tanggal': tanggal,
      'kodeTransaksi': kodeTransaksi,
      'nisn': nisn,
      'uidKartu': uidKartu,
      'nama': nama,
      'sisaSaldo': sisaSaldo,
      'pemakaian': pemakaian,
    };
  }

  // Create from Map for easy JSON deserialization
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      waktu: map['waktu']?.toString() ?? '',
      tanggal: map['tanggal']?.toString() ?? '',
      kodeTransaksi: map['kodeTransaksi']?.toString() ?? '',
      nisn: map['nisn']?.toString() ?? '',
      uidKartu: map['uidKartu']?.toString() ?? '',
      nama: map['nama']?.toString() ?? '',
      sisaSaldo: map['sisaSaldo']?.toString() ?? '',
      pemakaian: map['pemakaian']?.toString() ?? '',
    );
  }
}

// Top Up data model
// Top Up data model
class TopUpItem {
  final String waktu;
  final String tanggal;
  final String kodeTransaksi; // 👈 TAMBAHKAN INI
  final String nisn;
  final String nama;
  final String topUpAmount;

  TopUpItem({
    required this.waktu,
    required this.tanggal,
    required this.kodeTransaksi, // 👈 TAMBAHKAN INI
    required this.nisn,
    required this.nama,
    required this.topUpAmount,
  });

  @override
  String toString() {
    return 'TopUpItem(waktu: $waktu, tanggal: $tanggal, nisn: $nisn, nama: $nama, topUpAmount: $topUpAmount)';
  }

  // Helper method to get formatted date time
  String get formattedDateTime {
    return '$tanggal $waktu';
  }

  // Convert to Map for easy JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'waktu': waktu,
      'tanggal': tanggal,
      'kodeTransaksi': kodeTransaksi,
      'nisn': nisn,
      'nama': nama,
      'topUpAmount': topUpAmount,
    };
  }

  // Create from Map for easy JSON deserialization
  factory TopUpItem.fromMap(Map<String, dynamic> map) {
    return TopUpItem(
      waktu: map['waktu']?.toString() ?? '',
      tanggal: map['tanggal']?.toString() ?? '',
      kodeTransaksi: map['kodeTransaksi']?.toString() ?? '',
      nisn: map['nisn']?.toString() ?? '',
      nama: map['nama']?.toString() ?? '',
      topUpAmount: map['topUpAmount']?.toString() ?? '',
    );
  }
}
