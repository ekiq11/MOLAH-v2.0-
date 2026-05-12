// screens/dzikir_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizab_molah/dzikir/model/model_dzikir.dart';
import 'package:pizab_molah/dzikir/screens/detail_dizkir.dart';

class DzikirListPage extends StatefulWidget {
  final String type; // 'pagi' or 'petang'

  const DzikirListPage({super.key, required this.type});

  @override
  State<DzikirListPage> createState() => _DzikirListPageState();
}

class _DzikirListPageState extends State<DzikirListPage> {
  List<Dzikir> _dzikirs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDzikirs();
  }

  Future<void> _loadDzikirs() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json/dzikir.json',
      );
      final List<dynamic> data = json.decode(response);

      setState(() {
        _dzikirs = data.map((json) => Dzikir.fromJson(json)).where((dzikir) {
          // Filter berdasarkan type
          if (widget.type == 'pagi') {
            return dzikir.isForMorning;
          } else if (widget.type == 'petang') {
            return dzikir.isForEvening;
          }
          return true;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data dzikir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color get _primaryColor {
    return widget.type == 'pagi'
        ? Color(0xFF059669) // Hijau untuk pagi
        : Color(0xFF1E293B); // Abu gelap untuk sore
  }

  IconData get _iconType {
    return widget.type == 'pagi' ? Icons.wb_sunny : Icons.nights_stay;
  }

  String get _title {
    return widget.type == 'pagi' ? 'Dzikir Pagi' : 'Dzikir Petang';
  }

  double _getResponsiveFontSize(double screenWidth, {required double base}) {
    if (screenWidth < 360) {
      return base * 0.9;
    } else if (screenWidth < 400) {
      return base;
    } else if (screenWidth < 600) {
      return base * 1.05;
    } else {
      return base * 1.1;
    }
  }

  double _getResponsivePadding(double screenWidth, {required double base}) {
    if (screenWidth < 360) {
      return base * 0.85;
    } else if (screenWidth < 600) {
      return base;
    } else {
      return base * 1.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(screenWidth),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Memuat dzikir...',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(screenWidth, base: 14),
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_dzikirs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: screenWidth < 360 ? 56 : 64,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tidak ada dzikir tersedia',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(screenWidth, base: 16),
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(
                _getResponsivePadding(screenWidth, base: 16),
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildDzikirCard(_dzikirs[index], index, screenWidth);
                }, childCount: _dzikirs.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(double screenWidth) {
    final titleFontSize = _getResponsiveFontSize(screenWidth, base: 18);
    final iconSize = screenWidth < 360 ? 100.0 : 120.0;
    final expandedHeight = screenWidth < 360 ? 110.0 : 120.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      backgroundColor: _primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.type == 'pagi'
                  ? [Color(0xFF10B981), Color(0xFF059669)] // Gradient hijau
                  : [
                      Color(0xFF334155),
                      Color(0xFF1E293B),
                    ], // Gradient abu gelap
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  _iconType,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        iconSize: screenWidth < 360 ? 22 : 24,
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildDzikirCard(Dzikir dzikir, int index, double screenWidth) {
    final cardPadding = _getResponsivePadding(screenWidth, base: 16);
    final iconSize = screenWidth < 360 ? 44.0 : 48.0;
    final idFontSize = _getResponsiveFontSize(screenWidth, base: 16);
    final titleFontSize = _getResponsiveFontSize(screenWidth, base: 14);
    final subtitleFontSize = _getResponsiveFontSize(screenWidth, base: 12);
    final spacing = screenWidth < 360 ? 12.0 : 16.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DzikirDetailPage(
                dzikirs: _dzikirs,
                initialIndex: index,
                type: widget.type,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.type == 'pagi'
                        ? [
                            Color(0xFF10B981),
                            Color(0xFF059669),
                          ] // Gradient hijau
                        : [
                            Color(0xFF334155),
                            Color(0xFF1E293B),
                          ], // Gradient abu gelap
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}', // Nomor urut berdasarkan index
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: idFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dzikir.nama,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${dzikir.repeat}x',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dzikir.keterangan,
                            style: TextStyle(
                              fontSize: subtitleFontSize - 1,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: screenWidth < 360 ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
