import 'dart:io';

void main() {
  final file = File('lib/screens/pembayaran.dart');
  String content = file.readAsStringSync();

  // We will replace the whole _buildMainContent and related UI methods
  
  final startString = '  Widget _buildMainContent(bool isSmallScreen) {';
  final endString = '  void _copyToClipboard(String text, String label) {';
  
  final startIndex = content.indexOf(startString);
  final endIndex = content.indexOf(endString);
  
  if (startIndex == -1 || endIndex == -1) {
    print('Failed to find bounds');
    return;
  }
  
  final newUiCode = '''  Widget _buildMainContent(bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: _slideAnimation ?? AlwaysStoppedAnimation(Offset.zero),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildStudentInfoCard(isSmallScreen),
                const SizedBox(height: 16),
                _buildPaymentSummaryCard(isSmallScreen),
                const SizedBox(height: 16),
                _buildPaymentTypeSection(isSmallScreen),
                const SizedBox(height: 16),
                _buildBankAccountCard(isSmallScreen),
                const SizedBox(height: 16),
                _buildInstructionsCard(isSmallScreen),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // Bold Dark theme for Student Info
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: isSmallScreen ? 28 : 32,
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
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Text(
                  'NISN: \${widget.username}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w500,
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
    return Row(
      children: [
        Expanded(
          child: _buildBentoPaymentSummaryItem(
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
          child: _buildBentoPaymentSummaryItem(
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
    );
  }

  Widget _buildBentoPaymentSummaryItem(
    String label,
    String amount,
    String month,
    String status,
    IconData icon,
    Color color,
    bool isSmallScreen,
  ) {
    final bool isLunas = status == 'Lunas';
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLunas ? accentGreen.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isLunas ? accentGreen : color,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLunas ? 'Lunas' : amount,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: isLunas ? accentGreen : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Bulan: \$month',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Jenis Pembayaran',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: Colors.grey[800],
              letterSpacing: -0.5,
            ),
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
                    color: primaryRed.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
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
                    : Colors.grey[800],
                fontWeight: FontWeight.w700,
                fontSize: isSmallScreen ? 13 : 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: accentBlue,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                'Informasi Rekening',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBankInfoRow('Bank', _bankName, false, isSmallScreen),
                const SizedBox(height: 12),
                _buildBankInfoRow(
                  'No. Rekening',
                  _bankAccount,
                  true,
                  isSmallScreen,
                ),
                const SizedBox(height: 12),
                _buildBankInfoRow(
                  'Atas Nama',
                  _accountName,
                  false,
                  isSmallScreen,
                ),
              ],
            ),
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
              color: Colors.grey[500],
              fontSize: isSmallScreen ? 12 : 13,
            ),
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
                    fontSize: isSmallScreen ? 13 : 15,
                  ),
                ),
              ),
              if (canCopy)
                GestureDetector(
                  onTap: () => _copyToClipboard(value, label),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      color: primaryRed,
                      size: isSmallScreen ? 14 : 16,
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
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: primaryRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cara Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Transfer sesuai nominal tagihan ke rekening di atas.\n'
            '2. Klik tombol "Konfirmasi Pembayaran" di bawah ini.\n'
            '3. Anda akan diarahkan ke WhatsApp untuk mengirim bukti transfer.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handlePaymentConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: primaryRed.withValues(alpha: 0.4),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Konfirmasi Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

''';
  
  content = content.substring(0, startIndex) + newUiCode + content.substring(endIndex);
  
  file.writeAsStringSync(content);
  print('Patched pembayaran.dart successfully');
}
