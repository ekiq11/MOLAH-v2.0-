// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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

  bool _isLoading = true;
  bool _isProcessing = false;

  final String _whatsappNumber = '081237804124';
  final String _bankAccount = '7269288153';
  final String _bankName = 'BSI';
  final String _accountName = 'Yayasan Pesantren Zaid bin Tsabit';

  // Colors
  static const Color primaryRed = Color(0xFFE53E3E);
  static const Color lightRed = Color(0xFFFED7D7);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _simulateLoading();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  void _simulateLoading() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
      }
    });
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
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ✅ FIXED: WhatsApp launcher yang lebih robust untuk release APK
  Future<void> _sendWhatsAppMessage() async {
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final String message = _createFormattedMessage();
      await Clipboard.setData(ClipboardData(text: message)); // Backup

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
    // Normalisasi nomor
    String cleanNumber = _whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.startsWith('0'))
      cleanNumber = '62${cleanNumber.substring(1)}';
    if (!cleanNumber.startsWith('62')) cleanNumber = '62$cleanNumber';

    final String encodedMessage = Uri.encodeComponent(message);

    // Daftar URL untuk dicoba
    final List<Uri> urls = [
      Uri.parse(
        'whatsapp://send?phone=$cleanNumber&text=$encodedMessage',
      ), // Aplikasi WhatsApp
      Uri.parse('https://wa.me/$cleanNumber?text=$encodedMessage'), // wa.me
      Uri.parse(
        'https://api.whatsapp.com/send?phone=$cleanNumber&text=$encodedMessage',
      ), // API
    ];

    // Coba setiap URL
    for (final uri in urls) {
      try {
        final bool canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          final bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
          if (launched) return true;
        }
      } catch (e) {
        debugPrint('Gagal dengan $uri: $e');
        continue;
      }
    }

    // Jika semua gagal, coba di WebView (fallback terakhir)
    try {
      final Uri webUri = Uri.parse(
        'https://web.whatsapp.com/send?phone=$cleanNumber&text=$encodedMessage',
      );
      return await launchUrl(webUri, mode: LaunchMode.inAppWebView);
    } catch (e) {
      return false;
    }
  }

  // ✅ IMPROVED: Metode launching yang lebih reliable untuk release APK

  String _createFormattedMessage() {
    return "Assalamualaikum Warahmatullahi Wabarakatuh\n\n"
        "Saya sebagai wali santri ingin melakukan konfirmasi pembayaran dengan rincian sebagai berikut:\n\n"
        "📝 DETAIL SANTRI:\n"
        "• Nama Santri: ${widget.studentName}\n"
        "• NISN: ${widget.username}\n\n"
        "💰 DETAIL PEMBAYARAN:\n"
        "• Jenis Pembayaran: $_selectedPaymentType\n"
        "• Bank Tujuan: $_bankName\n"
        "• No. Rekening: $_bankAccount\n"
        "• Atas Nama: $_accountName\n\n"
        "📎 Bukti transfer akan saya kirimkan setelah pesan ini.\n\n"
        "Mohon untuk diverifikasi. Jazakumullahu khairan.\n\n"
        "Wassalamualaikum Warahmatullahi Wabarakatuh";
  }

  // ✅ IMPROVED: Dialog fallback yang lebih user-friendly
  void _showFallbackDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Pesan sudah otomatis disalin ke clipboard',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Langkah manual:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              _buildManualStep('1', 'Buka aplikasi WhatsApp', Icons.apps),
              _buildManualStep(
                '2',
                'Cari kontak: $_whatsappNumber',
                Icons.search,
              ),
              _buildManualStep(
                '3',
                'Paste pesan & kirim bukti transfer',
                Icons.send,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pesan pembayaran siap dikirim',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    _copyToClipboard(_whatsappNumber, 'Nomor WhatsApp');
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Nomor'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Mengerti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
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
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryRed))
          : _buildMainContent(),
      bottomNavigationBar: _isLoading ? null : _buildBottomButton(),
    );
  }

  // --- UI Sections (unchanged) ---

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildStudentInfoCard(),
            _buildPaymentTypeSection(),
            _buildBankAccountCard(),
            _buildInstructionsCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryRed,
            Color(0xFFDC2626),
          ], // Using primaryRed from your existing code
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.3),
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
            child: Icon(Icons.person_outline, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'NISN: ${widget.username}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      Icon(Icons.verified_user, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Siswa Aktif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school_outlined, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category, color: primaryRed, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Jenis Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPaymentTypeChip('SPP', Icons.school)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentTypeChip('Ekskul', Icons.sports_soccer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeChip(String type, IconData icon) {
    final bool isSelected = _selectedPaymentType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPaymentType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryRed : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Rekening',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                _buildBankInfoRow('Bank', _bankName, false),
                const Divider(height: 20),
                _buildBankInfoRow('No. Rekening', _bankAccount, true),
                const Divider(height: 20),
                _buildBankInfoRow('Atas Nama', _accountName, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value, bool canCopy) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (canCopy)
                GestureDetector(
                  onTap: () => _copyToClipboard(value, label),
                  child: Icon(Icons.copy, size: 16, color: Colors.blue[700]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.list_alt, color: Colors.green[600], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cara Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _InstructionStep(
            1,
            'Transfer ke rekening BSI yang tertera di atas',
            Icons.account_balance_wallet,
          ),
          const _InstructionStep(
            2,
            'Screenshot atau simpan bukti transfer',
            Icons.screenshot,
          ),
          const _InstructionStep(
            3,
            'Klik tombol "Konfirmasi WhatsApp" di bawah',
            Icons.message,
          ),
          const _InstructionStep(
            4,
            'Kirim bukti transfer beserta data Santri',
            Icons.send,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF10B981)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _sendWhatsAppMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Membuka WhatsApp...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call, size: 24, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Konfirmasi via WhatsApp',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan transfer sudah dilakukan sebelum konfirmasi',
              style: TextStyle(
                fontSize: 12,
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
  final int number;
  final String text;
  final IconData icon;

  const _InstructionStep(this.number, this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFE53E3E),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
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
}
