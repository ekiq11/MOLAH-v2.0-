import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('lib/screens/spp.dart');
  var content = file.readAsStringSync();

  // Replace _buildPaymentHistory
  final historyStart = '  Widget _buildPaymentHistory() {';
  final historyEnd = '  // KEEP semua widget build method lainnya seperti:';
  
  final historyStartIndex = content.indexOf(historyStart);
  final historyEndIndex = content.indexOf(historyEnd);
  
  if (historyStartIndex != -1 && historyEndIndex != -1) {
    content = content.substring(0, historyStartIndex) +
        '''  Widget _buildPaymentHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Riwayat Bulanan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 4;
              if (constraints.maxWidth > 400) crossAxisCount = 4;
              if (constraints.maxWidth > 500) crossAxisCount = 6;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: monthNames.length,
                itemBuilder: (context, index) {
                  String monthName = monthNames[index];
                  bool isPaid = index < santriData!.lunasBulanKe;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _navigateToInvoice(monthName, index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isPaid ? const Color(0xFF10B981) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPaid ? Colors.transparent : Colors.grey[200]!,
                            width: 1.5,
                          ),
                          boxShadow: isPaid
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isPaid ? Colors.white : Colors.grey[400],
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              monthName.length > 3 ? monthName.substring(0, 3).toUpperCase() : monthName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.white : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.grey[400], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ketuk bulan untuk melihat invoice. Pembayaran dimulai dari Juli.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

''' +
        content.substring(historyEndIndex);
  }

  // Replace _buildContent and everything until SPPInvoiceScreen class
  final contentStart = '  Widget _buildContent() {';
  final contentEnd = '// KELAS SPP INVOICE SCREEN TERPISAH';
  
  final contentStartIndex = content.indexOf(contentStart);
  final contentEndIndex = content.indexOf(contentEnd);
  
  if (contentStartIndex != -1 && contentEndIndex != -1) {
    content = content.substring(0, contentStartIndex) +
        '''  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: fetchData,
      color: const Color(0xFF10B981),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildPaymentSummary(),
            const SizedBox(height: 20),
            _buildUangPangkalProgress(),
            const SizedBox(height: 20),
            _buildPaymentHistory(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      santriData!.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: santriData!.lunasBulanKe >= 12 
                      ? Colors.white 
                      : const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  santriData!.lunasBulanKe >= 12 ? 'LUNAS' : 'BELUM LUNAS',
                  style: TextStyle(
                    color: santriData!.lunasBulanKe >= 12 ? const Color(0xFF059669) : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            santriData!.nama,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'NISN: \${santriData!.nisn}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Progress SPP',
                value: '\${santriData!.lunasBulanKe}/12',
                subtitle: 'Bulan',
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFF3B82F6),
                progress: santriData!.progressPercentage,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBentoCard(
                title: 'Total Dibayar',
                value: _formatCurrency(santriData!.nominalDibayar),
                subtitle: 'YTD SPP',
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Sisa SPP',
                value: _formatCurrency(santriData!.sisaPembayaran),
                subtitle: 'Tunggakan',
                icon: Icons.warning_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBentoCard(
                title: 'Iuran',
                value: _formatCurrency(santriData!.monthlyFee.toInt().toString()),
                subtitle: 'Per Bulan',
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUangPangkalProgress() {
    if (santriData!.besarUangPangkal == '0') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Uang Pangkal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: santriData!.progressUangPangkalPercentage >= 1.0 
                      ? const Color(0xFF10B981).withOpacity(0.1) 
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  santriData!.progressUangPangkalPercentage >= 1.0 ? 'LUNAS' : 'BELUM',
                  style: TextStyle(
                    color: santriData!.progressUangPangkalPercentage >= 1.0 
                        ? const Color(0xFF10B981) 
                        : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Pembayaran',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                '\${(santriData!.progressUangPangkalPercentage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: santriData!.progressUangPangkalPercentage,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(santriData!.besarUangPangkal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dibayar', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(santriData!.jumlahDibayarUangPangkal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              if (progress != null)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        strokeWidth: 4,
                      ),
                      Text(
                        '\${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
// KELAS SPP INVOICE SCREEN TERPISAH''' +
        content.substring(contentEndIndex + '// KELAS SPP INVOICE SCREEN TERPISAH'.length);
  }

  file.writeAsStringSync(content);
}
