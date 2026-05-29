import 'dart:io';

void main() {
  final file = File('lib/screens/perizinan_detail.dart');
  var content = file.readAsStringSync();

  // Patch "Sedang Dipondok" state inside _buildIzinAktifSection
  final dipondokStartIndex = content.indexOf('        if (izinAktif == null) {');
  final dipondokEndIndex = content.indexOf('        // Tampilan sedang izin aktif');

  if (dipondokStartIndex != -1 && dipondokEndIndex != -1) {
    final newDipondok = '''        if (izinAktif == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sedang Dipondok',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Santri saat ini aktif dan tidak dalam masa perizinan.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

''';
    content = content.substring(0, dipondokStartIndex) + newDipondok + content.substring(dipondokEndIndex);
  }

  // Patch the build method of IzinCard
  final buildIzinCardIndex = content.indexOf('  Widget _buildIzinCard(IzinModel izin) {');
  if (buildIzinCardIndex != -1) {
    // Keep it simple, just replace everything from _buildIzinCard to the end of the class.
    final endClassIndex = content.lastIndexOf('}');
    if (endClassIndex != -1) {
      final newIzinCard = '''  Widget _buildIzinCard(IzinModel izin) {
    final bool isLate = izin.status == "Terlambat" || izin.terlambatHari > 0 || izin.terlambatJam > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLate ? const Color(0xFFEF4444).withOpacity(0.1) : const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isLate ? Icons.warning_rounded : Icons.directions_walk_rounded,
                  color: isLate ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      izin.keterangan,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(izin.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        izin.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(izin.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai Izin',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\${izin.waktuMulai}\\n\${izin.tanggalMulai}",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[200],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Kembali',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\${izin.waktuSelesai}\\n\${izin.tanggalSelesai}",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (izin.tanggalKembali.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Aktual Kembali: \${izin.waktuKembali} (\${izin.tanggalKembali})',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return const Color(0xFF3B82F6);
      case 'kembali':
        return const Color(0xFF10B981);
      case 'terlambat':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }
}
''';
      
      content = content.substring(0, buildIzinCardIndex) + newIzinCard;
    }
  }

  file.writeAsStringSync(content);
  print('Patched perizinan_detail.dart');
}
