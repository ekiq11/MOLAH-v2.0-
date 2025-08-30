import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final String amount;
  final String nisn;
  final String namaSantri;

  const PaymentConfirmationScreen({
    super.key,
    required this.amount,
    required this.nisn,
    required this.namaSantri,
  });

  @override
  _PaymentConfirmationScreenState createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isProcessing = false;
  bool _isLoading = true;
  String _transactionCode = '';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _generateTransactionCode();
    _startAnimations();
  }

  void _generateTransactionCode() {
    final now = DateTime.now();
    _transactionCode = now.millisecondsSinceEpoch.toString().substring(7);
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  String _formatCurrency(String amount) {
    try {
      final cleanAmount = amount.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanAmount.isEmpty) return '0';

      final number = int.tryParse(cleanAmount) ?? 0;
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    } catch (e) {
      return amount;
    }
  }

  String get _nisnCode {
    if (widget.nisn.length >= 3) {
      return widget.nisn.substring(widget.nisn.length - 3);
    }
    return widget.nisn.padLeft(3, '0');
  }

  int get _totalAmount {
    try {
      final baseAmount = int.parse(
        widget.amount.replaceAll(RegExp(r'[^\d]'), ''),
      );
      final codeAmount = int.parse(_nisnCode);
      return baseAmount + codeAmount;
    } catch (e) {
      return 0;
    }
  }

  void _copyToClipboard(String text, String label) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$label berhasil disalin',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
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

  // METHOD UTAMA - Perbaikan untuk url_launcher 6.1.7
  Future<void> _openWhatsApp() async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      const String phone = "089693652230";
      final String message = _buildWhatsAppMessage();

      // Normalisasi nomor: konversi ke format internasional (62...)
      String cleanNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanNumber.startsWith('0')) {
        cleanNumber = '62${cleanNumber.substring(1)}';
      } else if (!cleanNumber.startsWith('62')) {
        cleanNumber = '62$cleanNumber';
      }

      // Encode pesan untuk URL
      final String encodedMessage = Uri.encodeComponent(message);

      // Daftar URL untuk dicoba (urutan penting: aplikasi dulu, lalu web)
      final List<Uri> urls = [
        // 1. Coba buka aplikasi WhatsApp langsung
        Uri.parse('whatsapp://send?phone=$cleanNumber&text=$encodedMessage'),
        // 2. wa.me — lebih modern dan direkomendasikan
        Uri.parse('https://wa.me/$cleanNumber?text=$encodedMessage'),
        // 3. API WhatsApp sebagai fallback
        Uri.parse(
          'https://api.whatsapp.com/send?phone=$cleanNumber&text=$encodedMessage',
        ),
      ];

      bool launched = false;

      // Coba setiap URL hingga salah satu berhasil
      for (final uri in urls) {
        try {
          final bool canLaunch = await canLaunchUrl(uri);
          if (canLaunch) {
            launched = await launchUrl(
              uri,
              mode: LaunchMode
                  .externalApplication, // Prioritaskan aplikasi eksternal
              webOnlyWindowName: '_blank',
            );
            if (launched) break;
          }
        } catch (e) {
          debugPrint('Gagal membuka $uri: $e');
          continue;
        }
      }

      // Jika semua gagal, coba fallback ke WebView
      if (!launched) {
        final Uri webUri = Uri.parse(
          'https://web.whatsapp.com/send?phone=$cleanNumber&text=$encodedMessage',
        );
        try {
          launched = await launchUrl(webUri, mode: LaunchMode.inAppWebView);
        } catch (e) {
          debugPrint('Fallback ke web.whatsapp.com juga gagal: $e');
        }
      }

      if (launched) {
        _showSuccessDialog();
      } else {
        _showManualFallbackDialog();
      }
    } catch (e) {
      debugPrint('Error umum saat membuka WhatsApp: $e');
      _showManualFallbackDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _buildWhatsAppMessage() {
    return "Halo, saya sudah melakukan transfer untuk top up saldo.\n\n"
        "📋 *Detail Transfer:*\n"
        "• NISN: ${widget.nisn}\n"
        "• Nama Santri: ${widget.namaSantri}\n"
        "• Jumlah Top Up: Rp ${_formatCurrency(widget.amount)}\n"
        "• Kode Unik: $_nisnCode\n"
        "• Total Transfer: Rp ${_formatCurrency(_totalAmount.toString())}\n"
        "• Kode Transaksi: $_transactionCode\n\n"
        "💰 *Detail Rekening Tujuan:*\n"
        "• Bank: BSI (Bank Syariah Indonesia)\n"
        "• No. Rekening: 7269288153\n"
        "• Atas Nama: PESANTREN ISLAM ZAID BIN TSABIT\n\n"
        "Tolong verifikasi pembayaran saya. Terima kasih.";
  }

  void _showManualFallbackDialog() {
    final message = _buildWhatsAppMessage();
    Clipboard.setData(ClipboardData(text: message));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Buka WhatsApp Manual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesan sudah disalin ke clipboard. Silakan buka WhatsApp secara manual.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Langkah manual:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text('1. Buka WhatsApp'),
                  Text('2. Cari: 089693652230'),
                  Text('3. Paste pesan (sudah disalin)'),
                  Text('4. Kirim pesan'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openWhatsApp(); // Coba lagi
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Container(
          padding: const EdgeInsets.all(16),
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
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Konfirmasi pembayaran telah dikirim via WhatsApp. Silakan tunggu verifikasi dari bendahara.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withOpacity(0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 18,
                        color: Color(0xFF374151),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Konfirmasi Pembayaran',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF10B981),
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildUserCard(),
                            const SizedBox(height: 20),
                            _buildAmountCard(),
                            const SizedBox(height: 24),
                            _buildPaymentInstructionsCard(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),

            // Bottom Action
            if (!_isLoading) _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.04),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NISN',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.nisn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.3),
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.payment_rounded,
            color: const Color(0xFF9CA3AF).withOpacity(0.7),
            size: 28,
          ),
          const SizedBox(height: 16),
          const Text(
            'TOTAL PEMBAYARAN',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Rp ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatCurrency(_totalAmount.toString()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937).withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formatCurrency(widget.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(
                    text: ' + ',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  ),
                  TextSpan(
                    text: _nisnCode,
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: ' (kode unik)',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.04),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'MENUNGGU PEMBAYARAN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Transfer ke rekening berikut:',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: const Center(
                        child: Text(
                          'BSI',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'BANK SYARIAH INDONESIA',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nomor Rekening',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '7269288153',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _copyToClipboard('7269288153', 'Nomor rekening'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEF7EC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'PESANTREN ISLAM ZAID BIN TSABIT',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Transfer sesuai jumlah total yang tertera untuk memudahkan verifikasi',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _openWhatsApp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            disabledBackgroundColor: const Color(0xFF9CA3AF),
          ),
          child: _isProcessing
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Mengirim...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Saya Sudah Transfer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
