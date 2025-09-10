// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final String username;
  final String studentName;

  const PaymentPage({
    super.key,
    required this.username,
    required this.studentName,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  String _selectedPaymentType = 'SPP';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _isProcessing = false;

  // Payment data
  Map<String, dynamic>? _sppData;
  Map<String, dynamic>? _ekskulData;
  double _sppAmount = 0;
  double _ekskulAmount = 0;
  String _sppStatus = '';
  String _ekskulStatus = '';

  final String _whatsappNumber = '081237804124';
  final String _bankAccount = '7269288153';
  final String _bankName = 'BSI';
  final String _accountName = 'Pesantren Islam Zaid bin Tsabit';

  // URLs for CSV data
  final String _sppCsvUrl =
      'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv&gid=290556271';
  final String _ekskulCsvUrl =
      'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv&gid=1521495544';

  // Colors - Modern DANA-like palette
  static const Color primaryRed = Color(0xFFE53E3E);
  static const Color lightRed = Color(0xFFFED7D7);
  static const Color darkRed = Color(0xFFDC2626);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPaymentData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  Future<void> _loadPaymentData() async {
    try {
      // Load SPP data
      final sppResponse = await http.get(Uri.parse(_sppCsvUrl));
      final ekskulResponse = await http.get(Uri.parse(_ekskulCsvUrl));

      if (sppResponse.statusCode == 200 && ekskulResponse.statusCode == 200) {
        _processSppData(sppResponse.body);
        _processEkskulData(ekskulResponse.body);
      }
    } catch (e) {
      debugPrint('Error loading payment data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
        _slideController.forward();
      }
    }
  }

  void _processSppData(String csvData) {
    final lines = csvData.split('\n');

    // Data dimulai dari baris ke-4 (index 3), jadi skip header dan mulai dari index 3
    for (int i = 3; i < lines.length; i++) {
      final row = lines[i];
      if (row.trim().isEmpty) continue;

      // Parse CSV row properly handling commas in quoted fields
      final columns = _parseCSVRow(row);

      // Pastikan ada cukup kolom dan NISN cocok
      if (columns.length > 7 && columns[1].trim() == widget.username) {
        // Column E (index 4) = Iuran YTD (Total pembayaran 1 tahun)
        final iuranYtd = _parseAmount(columns[4]);
        // Column H (index 7) = Lunas Bulan Ke
        final lunasMonth = int.tryParse(columns[7].trim()) ?? 0;

        // Calculate monthly amount: Iuran YTD ÷ 12
        _sppAmount = iuranYtd / 12;

        _sppData = {
          'iuranYtd': iuranYtd,
          'lunasMonth': lunasMonth,
          'monthlyAmount': _sppAmount,
          'nextMonth': _getNextSppMonth(lunasMonth),
        };

        // Status: Lunas if lunasMonth >= 12
        _sppStatus = lunasMonth >= 12 ? 'Lunas' : 'Belum Lunas';

        debugPrint('SPP Data Found - NISN: ${widget.username}');
        debugPrint(
          'Iuran YTD: $iuranYtd, Lunas Month: $lunasMonth, Monthly: $_sppAmount',
        );
        debugPrint('Next Month: ${_sppData?['nextMonth']}');
        break;
      }
    }
  }

  void _processEkskulData(String csvData) {
    final lines = csvData.split('\n');
    for (int i = 1; i < lines.length; i++) {
      final row = lines[i];
      if (row.trim().isEmpty) continue;

      // Parse CSV row properly handling commas in quoted fields
      final columns = _parseCSVRow(row);

      if (columns.length > 9 && columns[1].trim() == widget.username) {
        // Column G (index 6) = Iuran Tahunan
        final iuranTahunan = _parseAmount(columns[6]);
        // Column J (index 9) = Lunas Bulan Ke
        final lunasMonth = int.tryParse(columns[9].trim()) ?? 0;

        // Calculate monthly amount: Iuran Tahunan ÷ 11
        _ekskulAmount = iuranTahunan / 11;

        _ekskulData = {
          'iuranTahunan': iuranTahunan,
          'lunasMonth': lunasMonth,
          'monthlyAmount': _ekskulAmount,
          'nextMonth': _getNextEkskulMonth(lunasMonth),
        };

        // Status: Lunas if lunasMonth >= 11
        _ekskulStatus = lunasMonth >= 11 ? 'Lunas' : 'Belum Lunas';
        break;
      }
    }
  }

  // Helper method to parse CSV row handling quoted fields

  // Helper method to parse CSV row handling quoted fields
  List<String> _parseCSVRow(String row) {
    List<String> result = [];
    bool inQuotes = false;
    String currentField = '';

    for (int i = 0; i < row.length; i++) {
      String char = row[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }

    // Add the last field
    result.add(currentField.trim());
    return result;
  }

  // Helper method to parse amount from string (removing non-numeric characters except digits)
  double _parseAmount(String amountStr) {
    // Remove all non-numeric characters and spaces
    final cleanStr = amountStr.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleanStr) ?? 0;
  }

  String _getNextSppMonth(int lunasMonth) {
    // SPP Period: Juli (month 1) - Juni (month 12)
    // lunasMonth indicates how many months have been paid
    const sppMonths = [
      'Juli', // Month 1 - if lunasMonth=0, next is Juli
      'Agustus', // Month 2 - if lunasMonth=1, next is Agustus
      'September', // Month 3 - if lunasMonth=2, next is September
      'Oktober', // Month 4 - if lunasMonth=3, next is Oktober
      'November', // Month 5 - if lunasMonth=4, next is November
      'Desember', // Month 6 - if lunasMonth=5, next is Desember
      'Januari', // Month 7 - if lunasMonth=6, next is Januari
      'Februari', // Month 8 - if lunasMonth=7, next is Februari
      'Maret', // Month 9 - if lunasMonth=8, next is Maret
      'April', // Month 10 - if lunasMonth=9, next is April
      'Mei', // Month 11 - if lunasMonth=10, next is Mei
      'Juni', // Month 12 - if lunasMonth=11, next is Juni
    ];

    if (lunasMonth >= 12) return 'Lunas';

    // Next month to pay = sppMonths[lunasMonth]
    // Example:
    // - lunasMonth=0 means belum bayar, next month is Juli (index 0)
    // - lunasMonth=2 means sudah bayar Juli & Agustus, next month is September (index 2)
    // - lunasMonth=3 means sudah bayar Juli, Agustus, September, next month is Oktober (index 3)

    debugPrint(
      'SPP lunasMonth: $lunasMonth, next month: ${sppMonths[lunasMonth]}',
    );
    return sppMonths[lunasMonth];
  }

  String _getNextEkskulMonth(int lunasMonth) {
    // Ekskul Period: Agustus (month 1) - Juni (month 11)
    const ekskulMonths = [
      'Agustus', // Month 1
      'September', // Month 2
      'Oktober', // Month 3
      'November', // Month 4
      'Desember', // Month 5
      'Januari', // Month 6
      'Februari', // Month 7
      'Maret', // Month 8
      'April', // Month 9
      'Mei', // Month 10
      'Juni', // Month 11
    ];

    if (lunasMonth >= 11) return 'Lunas';

    // Next month to pay
    // If lunasMonth = 2 (paid Agustus & September), next is Oktober (index 2)
    return ekskulMonths[lunasMonth];
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _getSelectedMonth() {
    if (_selectedPaymentType == 'SPP') {
      return _sppData?['nextMonth'] ?? 'N/A';
    } else {
      return _ekskulData?['nextMonth'] ?? 'N/A';
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentGreen, Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Berhasil Dikirim!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Konfirmasi pembayaran telah dikirim via WhatsApp. Silakan tunggu verifikasi dari bendahara.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('$label berhasil disalin'),
            ],
          ),
          backgroundColor: accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendWhatsAppMessage() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final String message = _createFormattedMessage();
      await Clipboard.setData(ClipboardData(text: message));
      final bool launched = await _launchWhatsApp(message);

      if (mounted) {
        if (launched) {
          _showSuccessDialog();
        } else {
          _showFallbackDialog(message);
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) _showFallbackDialog(_createFormattedMessage());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _launchWhatsApp(String message) async {
    String cleanNumber = _whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Format nomor Indonesia
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }
    if (!cleanNumber.startsWith('62')) cleanNumber = '62$cleanNumber';

    final String encodedMessage = Uri.encodeComponent(message);

    // PERBAIKAN UTAMA: Prioritas URL yang benar untuk Android 11+
    final List<Map<String, dynamic>> urlConfigs = [
      {
        'uri': Uri.parse(
          'whatsapp://send?phone=$cleanNumber&text=$encodedMessage',
        ),
        'mode': LaunchMode.externalApplication,
        'description': 'WhatsApp App Direct',
      },
      {
        'uri': Uri.parse(
          'intent://send?phone=$cleanNumber&text=$encodedMessage#Intent;scheme=whatsapp;package=com.whatsapp;end',
        ),
        'mode': LaunchMode.externalApplication,
        'description': 'WhatsApp Intent',
      },
      {
        'uri': Uri.parse('https://wa.me/$cleanNumber?text=$encodedMessage'),
        'mode': LaunchMode.externalApplication,
        'description': 'WhatsApp Web Link',
      },
    ];

    // Coba setiap URL dengan pendekatan yang berbeda
    for (final config in urlConfigs) {
      try {
        debugPrint('Mencoba ${config['description']}: ${config['uri']}');

        // Untuk Android 11+, langsung coba launch tanpa canLaunchUrl
        // karena canLaunchUrl tidak selalu akurat untuk deep links
        final bool launched = await launchUrl(
          config['uri'],
          mode: config['mode'],
          webOnlyWindowName: '_blank',
        );

        if (launched) {
          debugPrint('Berhasil dengan ${config['description']}');
          return true;
        }
      } catch (e) {
        debugPrint('Gagal dengan ${config['description']}: $e');
        continue;
      }

      // Tambahkan delay kecil antar percobaan
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Fallback ke WhatsApp Web jika semua gagal
    try {
      debugPrint('Fallback ke WhatsApp Web');
      final Uri webUri = Uri.parse(
        'https://web.whatsapp.com/send?phone=$cleanNumber&text=$encodedMessage',
      );

      return await launchUrl(webUri, mode: LaunchMode.inAppWebView);
    } catch (e) {
      debugPrint('Fallback juga gagal: $e');
      return false;
    }
  }

  String _createFormattedMessage() {
    final amount = _selectedPaymentType == 'SPP' ? _sppAmount : _ekskulAmount;
    final nextMonth = _selectedPaymentType == 'SPP'
        ? (_sppData?['nextMonth'] ?? 'N/A')
        : (_ekskulData?['nextMonth'] ?? 'N/A');

    return "Assalamualaikum Warahmatullahi Wabarakatuh\n\n"
        "Saya sebagai wali santri ingin melakukan konfirmasi pembayaran dengan rincian sebagai berikut:\n\n"
        "📝 DETAIL SANTRI:\n"
        "• Nama Santri: ${widget.studentName}\n"
        "• NISN: ${widget.username}\n\n"
        "💰 DETAIL PEMBAYARAN:\n"
        "• Jenis Pembayaran: $_selectedPaymentType\n"
        "• Nominal: ${_formatCurrency(amount)}\n"
        "• Untuk Bulan: $nextMonth\n"
        "• Bank Tujuan: $_bankName\n"
        "• No. Rekening: $_bankAccount\n"
        "• Atas Nama: $_accountName\n\n"
        "📎 Bukti transfer akan saya kirimkan setelah pesan ini.\n\n"
        "Mohon untuk diverifikasi. Jazakumullahu khairan.\n\n"
        "Wassalamualaikum Warahmatullahi Wabarakatuh";
  }

  void _showFallbackDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Buka WhatsApp Manual',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: accentBlue, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Pesan sudah otomatis disalin ke clipboard',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Langkah manual:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildManualStep(
                '1',
                'Buka aplikasi WhatsApp',
                Icons.apps_rounded,
              ),
              _buildManualStep(
                '2',
                'Cari kontak: $_whatsappNumber',
                Icons.search_rounded,
              ),
              _buildManualStep(
                '3',
                'Paste pesan & kirim bukti transfer',
                Icons.send_rounded,
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () =>
                      _copyToClipboard(_whatsappNumber, 'Nomor WhatsApp'),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Nomor'),
                  style: TextButton.styleFrom(
                    foregroundColor: accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Mengerti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualStep(String number, String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: primaryRed,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: _buildModernAppBar(),
      body: _isLoading
          ? _buildLoadingScreen()
          : _buildMainContent(isSmallScreen),
      bottomNavigationBar: _isLoading
          ? null
          : _buildBottomButton(isSmallScreen),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: Text(
        'Tagihan Pembayaran',
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: cardWhite,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.grey[700]),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: primaryRed,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Memuat data pembayaran...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildStudentInfoCard(isSmallScreen),
              _buildPaymentSummaryCard(isSmallScreen),
              _buildPaymentTypeSection(isSmallScreen),
              _buildBankAccountCard(isSmallScreen),
              _buildInstructionsCard(isSmallScreen),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryRed, darkRed],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: isSmallScreen ? 24 : 28,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Row(
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: isSmallScreen ? 14 : 16,
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    Text(
                      'NISN: ${widget.username}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 12 : 14,
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 6),
                      Text(
                        'Siswa Aktif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: accentGreen,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                'Tagihan Pembayaran',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: _buildPaymentSummaryItem(
                  'SPP',
                  _formatCurrency(_sppAmount),
                  _sppData?['nextMonth'] ?? 'N/A',
                  _sppStatus,
                  Icons.school_rounded,
                  primaryRed,
                  isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: _buildPaymentSummaryItem(
                  'Ekskul',
                  _formatCurrency(_ekskulAmount),
                  _ekskulData?['nextMonth'] ?? 'N/A',
                  _ekskulStatus,
                  Icons.sports_soccer_rounded,
                  primaryRed,
                  isSmallScreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryItem(
    String type,
    String amount,
    String month,
    String status,
    IconData icon,
    Color color,
    bool isSmallScreen,
  ) {
    final isLunas = status == 'Lunas';

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isSmallScreen ? 16 : 18),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Expanded(
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          if (!isLunas) ...[
            Text(
              amount,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              'Bulan: $month',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10,
                vertical: isSmallScreen ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: accentGreen,
                    size: isSmallScreen ? 12 : 14,
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 6),
                  Text(
                    'Lunas',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSection(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: lightRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: primaryRed,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                'Pilih Jenis Pembayaran',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: _buildPaymentTypeChip(
                  'SPP',
                  Icons.school_rounded,
                  _formatCurrency(_sppAmount),
                  _sppData?['nextMonth'] ?? 'N/A',
                  _sppStatus == 'Lunas',
                  isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: _buildPaymentTypeChip(
                  'Ekskul',
                  Icons.sports_soccer_rounded,
                  _formatCurrency(_ekskulAmount),
                  _ekskulData?['nextMonth'] ?? 'N/A',
                  _ekskulStatus == 'Lunas',
                  isSmallScreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeChip(
    String type,
    IconData icon,
    String amount,
    String month,
    bool isLunas,
    bool isSmallScreen,
  ) {
    final bool isSelected = _selectedPaymentType == type;
    return GestureDetector(
      onTap: isLunas
          ? null
          : () {
              HapticFeedback.lightImpact();
              setState(() => _selectedPaymentType = type);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        decoration: BoxDecoration(
          color: isLunas
              ? Colors.grey[100]
              : isSelected
              ? primaryRed
              : cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLunas
                ? Colors.grey[300]!
                : isSelected
                ? primaryRed
                : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected && !isLunas
              ? [
                  BoxShadow(
                    color: primaryRed.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isLunas
                  ? Colors.grey[400]
                  : isSelected
                  ? Colors.white
                  : Colors.grey[600],
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              type,
              style: TextStyle(
                color: isLunas
                    ? Colors.grey[500]
                    : isSelected
                    ? Colors.white
                    : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            if (isLunas) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lunas',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              Text(
                amount,
                style: TextStyle(
                  color: isSelected ? Colors.white : primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12 : 13,
                ),
              ),
              Text(
                month,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey[600],
                  fontSize: isSmallScreen ? 10 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: accentGreen,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                'Informasi Rekening',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBankInfoRow('Bank', _bankName, false, isSmallScreen),
              Divider(height: 24, thickness: 1, color: Colors.grey.shade200),

              _buildBankInfoRow(
                'No. Rekening',
                _bankAccount,
                true,
                isSmallScreen,
              ),
              Divider(height: 24, thickness: 1, color: Colors.grey.shade200),

              _buildBankInfoRow(
                'Atas Nama',
                _accountName,
                false,
                isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(
    String label,
    String value,
    bool canCopy,
    bool isSmallScreen,
  ) {
    return Row(
      children: [
        SizedBox(
          width: isSmallScreen ? 80 : 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
        ),
        Text(
          ': ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
              ),
              if (canCopy)
                GestureDetector(
                  onTap: () => _copyToClipboard(value, label),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: isSmallScreen ? 14 : 16,
                      color: accentBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.list_alt_rounded,
                  color: accentGreen,
                  size: isSmallScreen ? 20 : 22,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                'Cara Pembayaran',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Steps
          _InstructionStep(
            1,
            'Transfer ke rekening BSI yang tertera di atas',
            Icons.account_balance_wallet_rounded,
            isSmallScreen,
          ),
          Divider(height: 28, thickness: 1, color: Colors.grey.shade200),

          _InstructionStep(
            2,
            'Screenshot atau simpan bukti transfer',
            Icons.screenshot_rounded,
            isSmallScreen,
          ),
          Divider(height: 28, thickness: 1, color: Colors.grey.shade200),

          _InstructionStep(
            3,
            'Klik tombol "Konfirmasi WhatsApp" di bawah',
            Icons.message_rounded,
            isSmallScreen,
          ),
          Divider(height: 28, thickness: 1, color: Colors.grey.shade200),

          _InstructionStep(
            4,
            'Kirim bukti transfer beserta data Santri',
            Icons.send_rounded,
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isSmallScreen) {
    final currentAmount = _selectedPaymentType == 'SPP'
        ? _sppAmount
        : _ekskulAmount;
    final isPaymentAvailable = currentAmount > 0;
    final isLunas = _selectedPaymentType == 'SPP'
        ? _sppStatus == 'Lunas'
        : _ekskulStatus == 'Lunas';

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPaymentAvailable && !isLunas) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: primaryRed,
                      size: isSmallScreen ? 16 : 18,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Tagihan $_selectedPaymentType: ${_formatCurrency(currentAmount)}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
            ],
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLunas || !isPaymentAvailable
                      ? [Colors.grey[400]!, Colors.grey[500]!]
                      : [accentGreen, const Color(0xFF059669)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isLunas || !isPaymentAvailable
                    ? null
                    : [
                        BoxShadow(
                          color: accentGreen.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: (isLunas || !isPaymentAvailable || _isProcessing)
                    ? null
                    : _sendWhatsAppMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 16 : 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? 18 : 20,
                            height: isSmallScreen ? 18 : 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Text(
                            'Membuka WhatsApp...',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLunas ? Icons.check_circle_rounded : Icons.phone,
                            size: isSmallScreen ? 20 : 24,
                            color: Colors.white,
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Text(
                            isLunas
                                ? 'Pembayaran Sudah Lunas'
                                : !isPaymentAvailable
                                ? 'Data Pembayaran Tidak Ditemukan'
                                : 'Konfirmasi via WhatsApp',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              isLunas
                  ? 'Terima kasih, pembayaran $_selectedPaymentType sudah lunas'
                  : 'Pastikan transfer sudah dilakukan sebelum konfirmasi',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int step;
  final String text;
  final IconData icon;
  final bool isSmallScreen;

  const _InstructionStep(
    this.step,
    this.text,
    this.icon,
    this.isSmallScreen, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.red[600],
            size: isSmallScreen ? 18 : 20,
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Text(
            "$step. $text",
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
