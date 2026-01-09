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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 16),
          _buildGrid(context, screenWidth),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Menu Cepat',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, double screenWidth) {
    final actions = _getActionItems(context);

    // Tentukan jumlah kolom berdasarkan lebar layar
    int columns = screenWidth < 360 ? 3 : (screenWidth < 600 ? 4 : 5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / columns;

        return Wrap(
          spacing: 0,
          runSpacing: 16,
          children: actions.map((action) {
            return SizedBox(
              width: itemWidth,
              child: _buildMenuItem(action),
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

  Widget _buildMenuItem(ActionItem action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon dengan background minimal
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 26,
              ),
            ),
            SizedBox(height: 6),
            
            // Label
            Text(
              action.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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