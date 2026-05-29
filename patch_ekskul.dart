import 'dart:io';

void main() {
  final file = File('lib/screens/ekskul.dart');
  var content = file.readAsStringSync();

  // Patch _buildStudentInfo
  final buildStudentInfoIndex = content.indexOf('  Widget _buildStudentInfo() {');
  final buildPaymentSummaryIndex = content.indexOf('  Widget _buildPaymentSummary() {');
  
  if (buildStudentInfoIndex != -1 && buildPaymentSummaryIndex != -1) {
    final newStudentInfo = '''  Widget _buildStudentInfo() {
    final status = _getPaymentStatus();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _paymentData['nama'] ?? 'Nama tidak ditemukan',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'NISN: \${_paymentData['nisn'] ?? widget.nisn}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_paymentData['status'] != null &&
                    _paymentData['status'].toString().isNotEmpty) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _paymentData['status'],
                          style: TextStyle(
                            color: const Color(0xFF3B82F6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status['status'] == "BELUM LUNAS"
                              ? const Color(0xFFEF4444).withOpacity(0.1)
                              : status['status'] == "LUNAS"
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status['status'],
                          style: TextStyle(
                            color: status['status'] == "BELUM LUNAS"
                                ? const Color(0xFFEF4444)
                                : status['status'] == "LUNAS"
                                ? const Color(0xFF10B981)
                                : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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

''';
    content = content.substring(0, buildStudentInfoIndex) + newStudentInfo + content.substring(buildPaymentSummaryIndex);
  }

  // Patch _buildPaymentSummary
  final paymentSummaryIndex = content.indexOf('  Widget _buildPaymentSummary() {');
  final summaryItemIndex = content.indexOf('  Widget _buildSummaryItem(');

  if (paymentSummaryIndex != -1 && summaryItemIndex != -1) {
    final newPaymentSummary = '''  Widget _buildPaymentSummary() {
    final ekskulText = _paymentData['ekskul']?.toString() ?? '';
    final ekskulCount = ekskulText.toLowerCase().contains('ekskul2')
        ? 2
        : ekskulText.toLowerCase().contains('ekskul1')
        ? 1
        : 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.sports_basketball_rounded, color: const Color(0xFF10B981), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Ringkasan Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
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
                color: const Color(0xFF3B82F6).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_kabaddi_rounded, color: const Color(0xFF3B82F6), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ekskulText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
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
                  '\$ekskulCount Kegiatan',
                  Icons.celebration_rounded,
                  const Color(0xFF3B82F6),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Bulan Lunas',
                  '\${_paymentData['lunas_bulan_ke'] ?? 0}/12',
                  Icons.check_circle_rounded,
                  const Color(0xFF10B981),
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
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Sisa Pembayaran',
                  _formatCurrency(_paymentData['sisa_pembayaran'] ?? 0),
                  Icons.pending_actions_rounded,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

''';
    content = content.substring(0, paymentSummaryIndex) + newPaymentSummary + content.substring(summaryItemIndex);
  }

  // Patch _buildSummaryItem
  final sItemIndex = content.indexOf('  Widget _buildSummaryItem(');
  final paymentChartIndex = content.indexOf('  Widget _buildPaymentChart() {');

  if (sItemIndex != -1 && paymentChartIndex != -1) {
    final newSummaryItem = '''  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

''';
    content = content.substring(0, sItemIndex) + newSummaryItem + content.substring(paymentChartIndex);
  }

  file.writeAsStringSync(content);
  print('Patched ekskul.dart');
}
