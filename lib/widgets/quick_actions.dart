import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:pizab_molah/doa/screens/doa_list_page.dart';
import 'package:pizab_molah/dzikir/screens/main_dzikir.dart';
import 'package:pizab_molah/quran/screens/quran_main.dart';

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
    return Container(
      // Padding horizontal dihapus karena sudah di-handle oleh padding di home.dart
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8), 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1), // Biru pastel
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.grid_view_rounded, color: Color(0xFF3B82F6), size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoSizeText(
              'Akses Cepat',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            AutoSizeText(
              'Menu utama layanan santri',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final actions = _getActionItems(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Kita paksa 4 item per baris di layar kecil, 5 di layar besar
        final bool isSmallScreen = MediaQuery.of(context).size.width < 360;
        final int columns = isSmallScreen ? 3 : 4;
        final double spacing = 12.0;
        
        final double itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 20, // Jarak antar baris lebih besar
          children: actions.map((action) {
            return SizedBox(
              width: itemWidth,
              child: _buildMenuItem(action, itemWidth),
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
        color: const Color(0xFF3B82F6), // Blue
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
        color: const Color(0xFFF59E0B), // Amber
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
        color: const Color(0xFF10B981), // Emerald
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SPPPaymentPage(nisn: nisn)),
          );
        },
      ),
      ActionItem(
        icon: Icons.sports_soccer_rounded,
        title: 'Ekskul',
        color: const Color(0xFF8B5CF6), // Violet
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
        color: const Color(0xFFEF4444), // Red
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransactionHistoryPage(nisn: nisn, studentName: 'Santri'),
            ),
          );
        },
      ),
      ActionItem(
        title: 'Al-Quran',
        color: const Color(0xFF059669), // Dark Emerald
        customImage: 'assets/other/iconquran.png',
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuranMainPage()),
          );
        },
      ),
      ActionItem(
        icon: Icons.mosque_rounded,
        title: 'Doa-Doa',
        color: const Color(0xFF14B8A6), // Teal
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DoaListPage()),
          );
        },
      ),
      ActionItem(
        icon: Icons.wb_sunny_rounded,
        title: 'Dzikir',
        color: const Color(0xFFEAB308), // Yellow
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DzikirMainPage()),
          );
        },
      ),
    ];
  }

  Widget _buildMenuItem(ActionItem action, double itemWidth) {
    // Ukuran proporsional, dibatasi maksimal 56
    final double containerSize = (itemWidth * 0.8).clamp(48.0, 56.0);
    final double iconSize = containerSize * 0.45;

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: action.color.withValues(alpha: 0.1),
      highlightColor: action.color.withValues(alpha: 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.1),
              shape: BoxShape.circle, // Berubah dari kotak melengkung menjadi lingkaran penuh (Instagram style)
            ),
            child: Center(
              child: action.customImage != null
                  ? Image.asset(
                      action.customImage!,
                      width: iconSize * 1.2,
                      height: iconSize * 1.2,
                      fit: BoxFit.contain,
                      color: action.color,
                    )
                  : Icon(action.icon, color: action.color, size: iconSize),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AutoSizeText(
              action.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155), // Slate 700
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              minFontSize: 9,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionItem {
  final IconData? icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? customImage;

  ActionItem({
    this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.customImage,
  });
}
