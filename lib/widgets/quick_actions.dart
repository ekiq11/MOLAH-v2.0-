import 'package:flutter/material.dart';
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
    // Mendapatkan ukuran layar
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final bool isLargeScreen = screenSize.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Semua Riwayat',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : (isLargeScreen ? 20 : 18),
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        LayoutBuilder(
          builder: (context, constraints) {
            // Menentukan tinggi card berdasarkan ukuran layar
            final cardHeight = isSmallScreen
                ? 105.0
                : (isLargeScreen ? 140.0 : 120.0);
            final cardWidth = isSmallScreen
                ? 90.0
                : (isLargeScreen ? 125.0 : 105.0);
            final iconSize = isSmallScreen
                ? 20.0
                : (isLargeScreen ? 28.0 : 24.0);
            final iconContainerSize = isSmallScreen
                ? 40.0
                : (isLargeScreen ? 54.0 : 46.0);

            return SizedBox(
              height: cardHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                children: [
                  SizedBox(width: 6), // Spasi awal
                  _buildActionCard(
                    context: context,
                    icon: Icons.history_rounded,
                    title: 'RIWAYAT\nSETORAN',
                    color: Colors.blue[600]!,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    iconSize: iconSize,
                    iconContainerSize: iconContainerSize,
                    isSmallScreen: isSmallScreen,
                    isLargeScreen: isLargeScreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HafalanHistoryPage(nisn: nisn),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context: context,
                    icon: Icons.star_outline_rounded,
                    title: 'RIWAYAT\nPOIN',
                    color: Colors.orange[600]!,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    iconSize: iconSize,
                    iconContainerSize: iconContainerSize,
                    isSmallScreen: isSmallScreen,
                    isLargeScreen: isLargeScreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RewardPelanggaranPage(nisn: nisn),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    title: 'SPP\nSANTRI',
                    color: Colors.green[600]!,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    iconSize: iconSize,
                    iconContainerSize: iconContainerSize,
                    isSmallScreen: isSmallScreen,
                    isLargeScreen: isLargeScreen,
                    onTap: () {
                      // Navigasi ke halaman SPP dengan passing NISN
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SPPPaymentPage(nisn: nisn),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context: context,
                    icon: Icons.sports_rounded,
                    title: 'EKSKUL\nSANTRI',
                    color: Colors.purple[600]!,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    iconSize: iconSize,
                    iconContainerSize: iconContainerSize,
                    isSmallScreen: isSmallScreen,
                    isLargeScreen: isLargeScreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EkskulPaymentScreen(nisn: nisn),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context: context,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'RIWAYAT\nTRANSAKSI',
                    color: Colors.red[600]!,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    iconSize: iconSize,
                    iconContainerSize: iconContainerSize,
                    isSmallScreen: isSmallScreen,
                    isLargeScreen: isLargeScreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionHistoryPage(
                            nisn: nisn,
                            studentName:
                                'Santri', // Atau bisa diambil dari data santri jika ada
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 6), // Spasi akhir
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required double cardWidth,
    required double cardHeight,
    required double iconSize,
    required double iconContainerSize,
    required bool isSmallScreen,
    required bool isLargeScreen,
    required VoidCallback onTap,
  }) {
    // Menentukan ukuran font berdasarkan ukuran layar
    final fontSize = isSmallScreen ? 10.0 : (isLargeScreen ? 14.0 : 12.0);

    return Container(
      width: cardWidth,
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    height: 1.1,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
