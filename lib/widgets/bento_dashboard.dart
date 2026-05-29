import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import '../screens/perizinan_detail.dart';
import '../models/izin_model.dart';
import '../utils/izin_fetcher.dart';

class BentoDashboard extends StatefulWidget {
  final Map<String, dynamic> santriData;
  final String nisn;

  const BentoDashboard({super.key, required this.santriData, required this.nisn});

  @override
  State<BentoDashboard> createState() => _BentoDashboardState();
}

class _BentoDashboardState extends State<BentoDashboard> {
  IzinModel? _izinAktif;

  @override
  void initState() {
    super.initState();
    _loadIzinAktif();
  }

  Future<void> _loadIzinAktif() async {
    final izin = await IzinFetcher.getIzinAktif(widget.nisn);
    if (mounted) {
      setState(() {
        _izinAktif = izin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        // Hafalan & Perizinan Row
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: _buildHafalanCard(),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: _buildPerizinanCard(context),
        ),

        // Absensi (Lebar Penuh)
        StaggeredGridTile.count(
          crossAxisCellCount: 4,
          mainAxisCellCount: 1.2,
          child: _buildInfoCard(
            title: 'ABSENSI',
            value: widget.santriData['absensi'] ?? 'KBM Belum dimulai',
            icon: Icons.calendar_today_rounded,
            colors: [Colors.blue[400]!, Colors.blue[600]!],
            bgColor: Colors.blue[50]!,
          ),
        ),

        // Akademik Row (Kelas & Asrama)
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1.5,
          child: _buildInfoCard(
            title: 'KELAS',
            value: widget.santriData['kelas'] ?? '-',
            icon: Icons.class_rounded,
            colors: [Colors.purple[400]!, Colors.purple[600]!],
            bgColor: Colors.purple[50]!,
            isSmall: true,
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1.5,
          child: _buildInfoCard(
            title: 'ASRAMA',
            value: _getCleanedAsramaName(widget.santriData['asrama']),
            icon: Icons.home_rounded,
            colors: [Colors.teal[400]!, Colors.teal[600]!],
            bgColor: Colors.teal[50]!,
            isSmall: true,
          ),
        ),

        // Pelanggaran & Reward Row
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1.5,
          child: _buildInfoCard(
            title: 'PELANGGARAN',
            value: '${widget.santriData['poin_pelanggaran'] ?? '0'} Poin',
            icon: Icons.warning_rounded,
            colors: [Colors.red[400]!, Colors.red[600]!],
            bgColor: Colors.red[50]!,
            isSmall: true,
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1.5,
          child: _buildInfoCard(
            title: 'REWARD',
            value: '${widget.santriData['reward'] ?? '0'} Poin',
            icon: Icons.stars_rounded,
            colors: [Colors.amber[400]!, Colors.amber[600]!],
            bgColor: Colors.amber[50]!,
            isSmall: true,
          ),
        ),
      ],
    );
  }

  Widget _buildHafalanCard() {
    String hafalanStr = widget.santriData['jumlah_hafalan']?.toString() ?? '0';
    // Ganti koma menjadi titik untuk keperluan parsing double
    String normalizedStr = hafalanStr.replaceAll(',', '.');
    // Hapus semua karakter kecuali angka dan titik
    normalizedStr = normalizedStr.replaceAll(RegExp(r'[^0-9.]'), '');
    double hafalanVal = double.tryParse(normalizedStr) ?? 0;
    
    // Siapkan teks untuk ditampilkan (menggunakan koma untuk desimal)
    String displayHafalan = hafalanVal.toString();
    if (displayHafalan.endsWith('.0')) {
      displayHafalan = displayHafalan.replaceAll('.0', '');
    } else {
      displayHafalan = displayHafalan.replaceAll('.', ',');
    }

    double progress = (hafalanVal / 30) * 100;
    if (progress > 100) progress = 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(
                        color: Colors.green[500],
                        value: progress,
                        title: '',
                        radius: 8,
                      ),
                      PieChartSectionData(
                        color: Colors.green[100],
                        value: 100 - progress,
                        title: '',
                        radius: 8,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Icon(Icons.menu_book_rounded, color: Colors.green[600], size: 24),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'HAFALAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8E8E8E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            '$displayHafalan Juz',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            minFontSize: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildPerizinanCard(BuildContext context) {
    bool isIzin = _izinAktif != null;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PerizinanDetailScreen(nisn: widget.nisn)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isIzin 
              ? [Colors.orange[400]!, Colors.orange[600]!]
              : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isIzin ? Colors.white.withValues(alpha: 0.2) : Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIzin ? Icons.directions_run_rounded : Icons.assignment_turned_in_rounded,
                color: isIzin ? Colors.white : Colors.orange[600],
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'PERIZINAN',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isIzin ? Colors.orange[100] : const Color(0xFF8E8E8E),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            AutoSizeText(
              isIzin ? 'Sedang Izin' : 'Di Pondok',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isIzin ? Colors.white : const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              minFontSize: 11,
            ),
            if (isIzin) ...[
              const SizedBox(height: 4),
              Text(
                'Lihat QR →',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
    required Color bgColor,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: isSmall ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: isSmall ? 20 : 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8E8E8E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AutoSizeText(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
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

  String _getCleanedAsramaName(String? asrama) {
    if (asrama == null || asrama.isEmpty) return '-';
    final normalized = asrama.trim().toUpperCase();
    final binIndex = normalized.indexOf(' BIN ');
    if (binIndex != -1) return normalized.substring(0, binIndex).trim();
    return normalized;
  }
}
