// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import 'package:pizab_molah/screens/HafalanHistoryPage.dart';

class HafalanProgressPage extends StatefulWidget {
  final String nisn;
  final String namaSantri;
  final List<HafalanData> hafalanList;

  const HafalanProgressPage({
    super.key,
    required this.nisn,
    required this.namaSantri,
    required this.hafalanList,
  });

  @override
  State<HafalanProgressPage> createState() => _HafalanProgressPageState();
}

class _HafalanProgressPageState extends State<HafalanProgressPage>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = '30';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();
    final stats = _calculateStats(filteredData);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar dengan Gradient
          _buildSliverAppBar(),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Quick Stats Cards - Hero Section
                  _buildHeroStats(stats),

                  const SizedBox(height: 16),

                  // Filter periode dengan animasi
                  _buildPeriodFilter(),

                  const SizedBox(height: 16),

                  // Progress Ring - Visualisasi utama
                  _buildProgressRing(stats),

                  const SizedBox(height: 16),

                  // Grafik tren dengan ilustrasi
                  _buildSetoranTrendChart(filteredData),

                  const SizedBox(height: 16),

                  // Distribusi nilai dengan icon
                  _buildNilaiDistributionChart(filteredData),

                  const SizedBox(height: 16),

                  // Aktivitas calendar dengan warna
                  _buildActivityCalendar(filteredData),

                  const SizedBox(height: 16),

                  // Progress per surah
                  _buildSurahProgress(filteredData),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFDC2626),
                Color(0xFFB91C1C),
                Color(0xFF991B1B),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Row(
                    children: [
                      // Avatar dengan border
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: Text(
                            widget.namaSantri[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.namaSantri,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.badge,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "NISN: ${widget.nisn}",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icon ilustrasi
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.auto_stories,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStats(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Jika layar kecil, gunakan grid 1 kolom
          if (constraints.maxWidth < 300) {
            return Column(
              children: [
                _buildHeroStatCard(
                  icon: Icons.book_rounded,
                  label: 'Total Setoran',
                  value: '${stats['total']}',
                  subtitle: 'hafalan',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                ),
                const SizedBox(height: 12),
                _buildHeroStatCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Per Minggu',
                  value: stats['avgPerWeek'].toStringAsFixed(1),
                  subtitle: 'rata-rata',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                ),
                const SizedBox(height: 12),
                _buildHeroStatCard(
                  icon: Icons.stars_rounded,
                  label: 'Nilai',
                  value: _getGradeLabel(stats['avgGrade']),
                  subtitle: 'rata-rata',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                ),
              ],
            );
          }
          
          // Layout normal untuk layar standar
          return Row(
            children: [
              Expanded(
                child: _buildHeroStatCard(
                  icon: Icons.book_rounded,
                  label: 'Total Setoran',
                  value: '${stats['total']}',
                  subtitle: 'hafalan',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeroStatCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Per Minggu',
                  value: stats['avgPerWeek'].toStringAsFixed(1),
                  subtitle: 'rata-rata',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeroStatCard(
                  icon: Icons.stars_rounded,
                  label: 'Nilai',
                  value: _getGradeLabel(stats['avgGrade']),
                  subtitle: 'rata-rata',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodButton('7 Hari', '7', Icons.today),
          _buildPeriodButton('30 Hari', '30', Icons.calendar_month),
          _buildPeriodButton('90 Hari', '90', Icons.date_range),
          _buildPeriodButton('Semua', 'all', Icons.all_inclusive),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value, IconData icon) {
    bool isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRing(Map<String, dynamic> stats) {
    int total = stats['total'];
    int nilaiA = stats['nilaiA'];
    int nilaiB = stats['nilaiB'];
    int nilaiC = stats['nilaiC'];
    int nilaiD = stats['nilaiD'];

    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.donut_large,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pencapaian Nilai',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Layout responsif untuk chart dan legend
          LayoutBuilder(
            builder: (context, constraints) {
              // Jika lebar layar kecil, gunakan layout vertikal
              if (constraints.maxWidth < 350) {
                return Column(
                  children: [
                    // Chart di atas
                    SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: [
                                if (nilaiA > 0)
                                  PieChartSectionData(
                                    value: nilaiA.toDouble(),
                                    title: '',
                                    color: const Color(0xFF10B981),
                                    radius: 50,
                                  ),
                                if (nilaiB > 0)
                                  PieChartSectionData(
                                    value: nilaiB.toDouble(),
                                    title: '',
                                    color: const Color(0xFF3B82F6),
                                    radius: 50,
                                  ),
                                if (nilaiC > 0)
                                  PieChartSectionData(
                                    value: nilaiC.toDouble(),
                                    title: '',
                                    color: const Color(0xFFF59E0B),
                                    radius: 50,
                                  ),
                                if (nilaiD > 0)
                                  PieChartSectionData(
                                    value: nilaiD.toDouble(),
                                    title: '',
                                    color: const Color(0xFFEF4444),
                                    radius: 50,
                                  ),
                              ],
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Legend di bawah
                    Column(
                      children: [
                        _buildNilaiLegendModern(
                          'Nilai A',
                          nilaiA,
                          const Color(0xFF10B981),
                          Icons.sentiment_very_satisfied,
                        ),
                        const SizedBox(height: 10),
                        _buildNilaiLegendModern(
                          'Nilai B',
                          nilaiB,
                          const Color(0xFF3B82F6),
                          Icons.sentiment_satisfied,
                        ),
                        const SizedBox(height: 10),
                        _buildNilaiLegendModern(
                          'Nilai C',
                          nilaiC,
                          const Color(0xFFF59E0B),
                          Icons.sentiment_neutral,
                        ),
                        const SizedBox(height: 10),
                        _buildNilaiLegendModern(
                          'Nilai D',
                          nilaiD,
                          const Color(0xFFEF4444),
                          Icons.sentiment_dissatisfied,
                        ),
                      ],
                    ),
                  ],
                );
              }
              
              // Layout horizontal untuk layar lebih lebar
              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: [
                                if (nilaiA > 0)
                                  PieChartSectionData(
                                    value: nilaiA.toDouble(),
                                    title: '',
                                    color: const Color(0xFF10B981),
                                    radius: 50,
                                  ),
                                if (nilaiB > 0)
                                  PieChartSectionData(
                                    value: nilaiB.toDouble(),
                                    title: '',
                                    color: const Color(0xFF3B82F6),
                                    radius: 50,
                                  ),
                                if (nilaiC > 0)
                                  PieChartSectionData(
                                    value: nilaiC.toDouble(),
                                    title: '',
                                    color: const Color(0xFFF59E0B),
                                    radius: 50,
                                  ),
                                if (nilaiD > 0)
                                  PieChartSectionData(
                                    value: nilaiD.toDouble(),
                                    title: '',
                                    color: const Color(0xFFEF4444),
                                    radius: 50,
                                  ),
                              ],
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        _buildNilaiLegendModern(
                          'Nilai A',
                          nilaiA,
                          const Color(0xFF10B981),
                          Icons.sentiment_very_satisfied,
                        ),
                        const SizedBox(height: 10),
                        _buildNilaiLegendModern(
                          'Nilai B',
                          nilaiB,
                          const Color(0xFF3B82F6),
                          Icons.sentiment_satisfied,
                        ),
                        const SizedBox(height: 10),
                        _buildNilaiLegendModern(
                          'Nilai C',
                          nilaiC,
                          const Color(0xFFF59E0B),
                          Icons.sentiment_neutral,
                        ),
                        const SizedBox(height: 10),
                        _buildNilaiLegendModern(
                          'Nilai D',
                          nilaiD,
                          const Color(0xFFEF4444),
                          Icons.sentiment_dissatisfied,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNilaiLegendModern(String label, int count, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 35),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetoranTrendChart(List<HafalanData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    Map<String, int> dailyCount = {};
    for (var item in data) {
      DateTime? date = _parseDateTime(item);
      if (date != null) {
        String dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyCount[dateKey] = (dailyCount[dateKey] ?? 0) + 1;
      }
    }

    List<FlSpot> spots = [];
    List<String> dates = dailyCount.keys.toList()..sort();

    for (int i = 0; i < dates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyCount[dates[i]]!.toDouble()));
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tren Setoran Harian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Grafik menunjukkan konsistensi setoran hafalan',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval:
                          math.max(1, (spots.length / 5).ceil().toDouble()),
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= dates.length) {
                          return const Text('');
                        }
                        List<String> parts = dates[index].split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${parts[2]}/${parts[1]}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                minX: 0,
                maxX: spots.length > 0 ? (spots.length - 1).toDouble() : 1,
                minY: 0,
                maxY: (dailyCount.values.reduce(math.max) + 1).toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: const Color(0xFF3B82F6),
                          strokeWidth: 3,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.3),
                          const Color(0xFF3B82F6).withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

  Widget _buildNilaiDistributionChart(List<HafalanData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    Map<String, int> nilaiCount = {'A': 0, 'B': 0, 'C': 0, 'D': 0};

    for (var item in data) {
      String nilai = item.nilai.toUpperCase();
      if (nilai.contains('A')) {
        nilaiCount['A'] = nilaiCount['A']! + 1;
      } else if (nilai.contains('B')) {
        nilaiCount['B'] = nilaiCount['B']! + 1;
      } else if (nilai.contains('C')) {
        nilaiCount['C'] = nilaiCount['C']! + 1;
      } else if (nilai.contains('D')) {
        nilaiCount['D'] = nilaiCount['D']! + 1;
      }
    }

    int total = nilaiCount.values.reduce((a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Distribusi Nilai',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Persentase perolehan nilai dari total setoran',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildNilaiBar('A', nilaiCount['A']!, total, const Color(0xFF10B981),
              Icons.sentiment_very_satisfied),
          const SizedBox(height: 12),
          _buildNilaiBar('B', nilaiCount['B']!, total, const Color(0xFF3B82F6),
              Icons.sentiment_satisfied),
          const SizedBox(height: 12),
          _buildNilaiBar('C', nilaiCount['C']!, total, const Color(0xFFF59E0B),
              Icons.sentiment_neutral),
          const SizedBox(height: 12),
          _buildNilaiBar('D', nilaiCount['D']!, total, const Color(0xFFEF4444),
              Icons.sentiment_dissatisfied),
        ],
      ),
    );
  }

  Widget _buildNilaiBar(
      String label, int count, int total, Color color, IconData icon) {
    double percentage = (count / total) * 100;
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
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
                        'Nilai $label',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage / 100,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color,
                                color.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCalendar(List<HafalanData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    Map<String, int> activityMap = {};
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(const Duration(days: 27)); // 4 weeks

    for (var item in data) {
      DateTime? date = _parseDateTime(item);
      if (date != null && date.isAfter(startDate)) {
        String dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        activityMap[dateKey] = (activityMap[dateKey] ?? 0) + 1;
      }
    }

    int maxActivity =
        activityMap.values.isEmpty ? 1 : activityMap.values.reduce(math.max);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Aktivitas 4 Minggu Terakhir',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kalender aktivitas setoran harian',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                .map((day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  DateTime date = startDate.add(
                    Duration(days: weekIndex * 7 + dayIndex),
                  );
                  String dateKey =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  int activity = activityMap[dateKey] ?? 0;

                  Color cellColor;
                  IconData? cellIcon;
                  if (activity == 0) {
                    cellColor = Colors.grey[100]!;
                  } else {
                    double intensity = activity / maxActivity;
                    cellColor = const Color(0xFFDC2626)
                        .withOpacity(0.2 + (intensity * 0.8));
                    if (activity >= 3) {
                      cellIcon = Icons.local_fire_department;
                    }
                  }

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 45,
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: activity > 0
                              ? const Color(0xFFDC2626).withOpacity(0.3)
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (cellIcon != null)
                            Icon(
                              cellIcon,
                              color: Colors.white,
                              size: 12,
                            ),
                          if (activity > 0)
                            Positioned(
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$activity',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: activity >= 3
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sedikit',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Colors.grey[100]
                        : const Color(0xFFDC2626)
                            .withOpacity(0.2 + (index * 0.2)),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: index == 0
                          ? Colors.grey[300]!
                          : const Color(0xFFDC2626).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              const Text(
                'Banyak',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurahProgress(List<HafalanData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    Map<String, int> surahCount = {};
    for (var item in data) {
      String surah = item.surahAwal.trim();
      if (surah.isNotEmpty) {
        surahCount[surah] = (surahCount[surah] ?? 0) + 1;
      }
    }

    if (surahCount.isEmpty) return const SizedBox.shrink();

    List<MapEntry<String, int>> sortedSurah = surahCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<MapEntry<String, int>> topSurah = sortedSurah.take(5).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Surah Favorit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Top ${topSurah.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Surah yang paling sering disetorkan',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ...topSurah.asMap().entries.map((entry) {
            int rank = entry.key;
            MapEntry<String, int> surahEntry = entry.value;
            double percentage = (surahEntry.value / data.length) * 100;

            List<Color> colors = [
              const Color(0xFFFFD700), // Gold
              const Color(0xFFC0C0C0), // Silver
              const Color(0xFFCD7F32), // Bronze
              const Color(0xFF8B5CF6), // Purple
              const Color(0xFF6366F1), // Indigo
            ];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors[rank].withOpacity(0.1),
                    colors[rank].withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors[rank].withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors[rank], colors[rank].withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${rank + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                surahEntry.key,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors[rank],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${surahEntry.value} kali',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percentage / 100,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colors[rank], colors[rank].withOpacity(0.7)],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(1)}% dari total setoran',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<HafalanData> _getFilteredData() {
    if (_selectedPeriod == 'all') {
      return widget.hafalanList;
    }

    int days = int.parse(_selectedPeriod);
    DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));

    return widget.hafalanList.where((data) {
      DateTime? date = _parseDateTime(data);
      return date != null && date.isAfter(cutoffDate);
    }).toList();
  }

  Map<String, dynamic> _calculateStats(List<HafalanData> data) {
    if (data.isEmpty) {
      return {
        'total': 0,
        'avgPerWeek': 0.0,
        'nilaiA': 0,
        'nilaiB': 0,
        'nilaiC': 0,
        'nilaiD': 0,
        'avgGrade': 0.0,
      };
    }

    int nilaiA = 0, nilaiB = 0, nilaiC = 0, nilaiD = 0;
    double totalGrade = 0;
    int gradeCount = 0;

    for (var item in data) {
      String nilai = item.nilai.toUpperCase();
      if (nilai.contains('A')) {
        nilaiA++;
        totalGrade += 4;
        gradeCount++;
      } else if (nilai.contains('B')) {
        nilaiB++;
        totalGrade += 3;
        gradeCount++;
      } else if (nilai.contains('C')) {
        nilaiC++;
        totalGrade += 2;
        gradeCount++;
      } else if (nilai.contains('D')) {
        nilaiD++;
        totalGrade += 1;
        gradeCount++;
      }
    }

    DateTime? firstDate = _parseDateTime(data.last);
    DateTime? lastDate = _parseDateTime(data.first);
    double avgPerWeek = 0.0;

    if (firstDate != null && lastDate != null) {
      int totalDays = lastDate.difference(firstDate).inDays + 1;
      double weeks = totalDays / 7.0;
      if (weeks > 0) {
        avgPerWeek = data.length / weeks;
      }
    }

    return {
      'total': data.length,
      'avgPerWeek': avgPerWeek,
      'nilaiA': nilaiA,
      'nilaiB': nilaiB,
      'nilaiC': nilaiC,
      'nilaiD': nilaiD,
      'avgGrade': gradeCount > 0 ? totalGrade / gradeCount : 0.0,
    };
  }

  String _getGradeLabel(double grade) {
    if (grade >= 3.5) return 'A';
    if (grade >= 2.5) return 'B';
    if (grade >= 1.5) return 'C';
    if (grade >= 0.5) return 'D';
    return '-';
  }

  DateTime? _parseDateTime(HafalanData data) {
    try {
      String dateStr = data.tanggal.trim();
      if (dateStr.isEmpty) return null;

      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        // Continue to manual parsing
      }

      List<String> parts;
      if (dateStr.contains('-')) {
        parts = dateStr.split('-');
      } else if (dateStr.contains('/')) {
        parts = dateStr.split('/');
      } else {
        return null;
      }

      if (parts.length != 3) return null;

      int year, month, day;

      day = int.tryParse(parts[0]) ?? 0;
      month = int.tryParse(parts[1]) ?? 0;
      year = int.tryParse(parts[2]) ?? 0;

      if (year < 100) {
        year += (year < 50) ? 2000 : 1900;
      }

      if (year < 1900 || year > 2100) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
}