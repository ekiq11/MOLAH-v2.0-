import 'package:flutter/material.dart';

class StudentInfo extends StatelessWidget {
  final Map<String, dynamic> santriData;

  const StudentInfo({super.key, required this.santriData});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final bool isLargeScreen = screenSize.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section dengan Design Modern
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[50]!,
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green[100]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green[600]!,
                      Colors.green[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Akademik',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 17 : (isLargeScreen ? 21 : 19),
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[800],
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Data pendidikan santri',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Flexible Layout dengan Wrap
        _buildFlexibleInfoCards(isSmallScreen, isLargeScreen),
      ],
    );
  }

  Widget _buildFlexibleInfoCards(bool isSmallScreen, bool isLargeScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Hitung lebar item dengan spacing
        final spacing = isSmallScreen ? 12.0 : 16.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        final cards = [
          _InfoCardData(
            title: 'KELAS',
            value: santriData['kelas'] ?? '7A',
            icon: Icons.class_rounded,
            gradientColors: [Colors.blue[400]!, Colors.blue[600]!],
            bgColor: Colors.blue[50]!,
          ),
          _InfoCardData(
            title: 'LEMBAGA',
            value: _getLembagaShortName(santriData['lembaga']),
            icon: Icons.account_balance_rounded,
            gradientColors: [Colors.green[400]!, Colors.green[600]!],
            bgColor: Colors.green[50]!,
          ),
          _InfoCardData(
            title: 'ASRAMA',
            value: _getCleanedAsramaName(santriData['asrama']),
            icon: Icons.home_rounded,
            gradientColors: [Colors.orange[400]!, Colors.orange[600]!],
            bgColor: Colors.orange[50]!,
          ),
          _InfoCardData(
            title: 'STATUS',
            value: santriData['status'] ?? 'Aktif',
            icon: Icons.verified_user_rounded,
            gradientColors: [Colors.purple[400]!, Colors.purple[600]!],
            bgColor: Colors.purple[50]!,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((cardData) {
            return SizedBox(
              width: itemWidth,
              child: _buildFlexibleCard(
                cardData: cardData,
                itemWidth: itemWidth,
                isSmallScreen: isSmallScreen,
                isLargeScreen: isLargeScreen,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _getLembagaShortName(String? lembaga) {
    if (lembaga == null || lembaga.isEmpty) {
      return 'Belum Ada';
    }
    return lembaga.length >= 3
        ? lembaga.substring(0, 3).toUpperCase()
        : lembaga.toUpperCase();
  }

  String _getCleanedAsramaName(String? asrama) {
    if (asrama == null || asrama.isEmpty) {
      return 'Belum Ada';
    }

    final String normalized = asrama.trim().toUpperCase();
    final int binIndex = normalized.indexOf(' BIN ');

    if (binIndex != -1) {
      return normalized.substring(0, binIndex).trim();
    }

    return asrama.trim();
  }

  Widget _buildFlexibleCard({
    required _InfoCardData cardData,
    required double itemWidth,
    required bool isSmallScreen,
    required bool isLargeScreen,
  }) {
    // Responsive sizing berdasarkan lebar item
    final double paddingValue = itemWidth < 160 ? 12 : (itemWidth < 200 ? 14 : 16);
    final double iconSize = itemWidth < 160 ? 20 : (itemWidth < 200 ? 22 : 24);
    final double titleFontSize = itemWidth < 160 ? 10 : (itemWidth < 200 ? 10.5 : 11);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardData.gradientColors[1].withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardData.bgColor.withOpacity(0.3),
              ),
            ),
          ),
          
          // Content dengan Padding yang Fleksibel
          Padding(
            padding: EdgeInsets.all(paddingValue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon dengan Gradient
                Container(
                  padding: EdgeInsets.all(itemWidth < 160 ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: cardData.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cardData.gradientColors[1].withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    cardData.icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                
                SizedBox(height: 10),
                
                // Title
                Text(
                  cardData.title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 6),
                
                // Value - Menggunakan fontSize yang fleksibel
                Text(
                  cardData.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                
                // Spacing tambahan untuk memastikan konten tidak terlalu padat
                SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class untuk data card
class _InfoCardData {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final Color bgColor;

  _InfoCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.bgColor,
  });
}