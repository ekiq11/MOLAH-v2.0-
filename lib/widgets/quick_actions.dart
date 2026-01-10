import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/HafalanHistoryPage.dart';
import '../screens/ekskul.dart';
import '../screens/history_transaction.dart';
import '../screens/reward.dart';
import '../screens/spp.dart';

class QuickActions extends StatelessWidget {
  final String nisn;

  const QuickActions({super.key, required this.nisn});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Color(0xFFF3F4F6),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Dekorasi background
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3B82F6).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF10B981).withOpacity(0.04),
              ),
            ),
          ),
          
          // Konten utama
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 16),
                _buildGrid(context, screenWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.dashboard_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu Cepat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              'Akses layanan dengan mudah',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, double screenWidth) {
    final actions = _getActionItems(context);

    // Lebih user-friendly: maksimal 4 kolom untuk smartphone
    // Prioritaskan kemudahan tap dan keterbacaan
    int columns;
    double spacing;
    
    if (screenWidth < 360) {
      // Layar kecil: 3 kolom (icon besar, mudah di-tap)
      columns = 3;
      spacing = 12.0;
    } else if (screenWidth < 600) {
      // Layar medium: 4 kolom (balanced)
      columns = 4;
      spacing = 16.0;
    } else if (screenWidth < 900) {
      // Tablet kecil: 5 kolom
      columns = 5;
      spacing = 20.0;
    } else {
      // Tablet besar: 6 kolom
      columns = 6;
      spacing: 24.0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / columns;

        return Wrap(
          spacing: 0,
          runSpacing: 20, // Lebih lega untuk vertical spacing
          children: actions.map((action) {
            return SizedBox(
              width: itemWidth,
              child: _buildMenuItem(action, itemWidth, screenWidth),
            );
          }).toList(),
        );
      },
    );
  }

  List<ActionItem> _getActionItems(BuildContext context) {
    return [
      ActionItem(
        icon: Icons.auto_stories_rounded,
        title: 'Hafalan',
        color: Color(0xFF3B82F6),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HafalanHistoryPage(nisn: nisn),
            ),
          );
        },
      ),
      ActionItem(
        icon: Icons.stars_rounded,
        title: 'Reward',
        color: Color(0xFFF59E0B),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RewardPelanggaranPage(nisn: nisn),
            ),
          );
        },
      ),
      ActionItem(
        icon: Icons.school_rounded,
        title: 'SPP',
        color: Color(0xFF10B981),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SPPPaymentPage(nisn: nisn),
            ),
          );
        },
      ),
      ActionItem(
        icon: Icons.sports_soccer_rounded,
        title: 'Ekskul',
        color: Color(0xFF8B5CF6),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EkskulPaymentScreen(nisn: nisn),
            ),
          );
        },
      ),
      ActionItem(
        icon: Icons.receipt_long_rounded,
        title: 'Riwayat',
        color: Color(0xFFEF4444),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionHistoryPage(
                nisn: nisn,
                studentName: 'Santri',
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildMenuItem(ActionItem action, double itemWidth, double screenWidth) {
    // Ukuran minimum yang nyaman untuk di-tap: 56x56 (Material Design guideline)
    // Tapi disesuaikan dengan ruang yang ada
    final double containerSize = itemWidth < 70 
        ? 52.0  // Minimum 52px untuk tap target yang nyaman
        : itemWidth < 90 
            ? 56.0 
            : itemWidth < 110 
                ? 60.0 
                : 64.0;
    
    final double iconSize = containerSize * 0.5; // 50% dari container (lebih besar)
    
    // Font size yang lebih mudah dibaca
    final double titleFontSize = screenWidth < 360 
        ? 11.0 
        : screenWidth < 600 
            ? 12.0 
            : 13.0;
    
    final double borderRadius = 14.0; // Fixed radius yang nyaman
    
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon dengan gradient dan shadow
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    action.color.withOpacity(0.8),
                    action.color,
                  ],
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Icon(
                action.icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            SizedBox(height: 8), // Lebih lega
            
            // Label dengan ukuran yang mudah dibaca
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                action.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model class untuk action items
class ActionItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  ActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}