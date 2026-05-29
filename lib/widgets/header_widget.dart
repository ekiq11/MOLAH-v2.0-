import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CombinedHeader extends StatelessWidget {
  final Map<String, dynamic> santriData;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback onLogoutTap;
  final String saldo;
  final VoidCallback onTopUpTap;
  final bool isSaldoVisible;
  final VoidCallback onToggleSaldoVisibility;

  const CombinedHeader({
    super.key,
    required this.santriData,
    required this.notificationCount,
    this.onNotificationTap,
    required this.onLogoutTap,
    required this.saldo,
    required this.onTopUpTap,
    required this.isSaldoVisible,
    required this.onToggleSaldoVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;

    return Column(
      children: [
        // 1. Profil Area (Transparent, dark text)
        Container(
          padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16 : 24, 
              isSmallScreen ? 20 : 28, 
              isSmallScreen ? 16 : 24, 
              isSmallScreen ? 16 : 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: isSmallScreen ? 50 : 60,
                height: isSmallScreen ? 50 : 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.school_rounded,
                    color: const Color(0xFF10B981),
                    size: isSmallScreen ? 26 : 30,
                  ),
                ),
              ),

              SizedBox(width: isSmallScreen ? 12 : 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          color: Colors.amber[500],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Selamat Datang,',
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 11 : 13,
                            color: const Color(0xFF8E8E8E),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AutoSizeText(
                      santriData['nama'] ?? 'Memuat data...',
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 16 : 18,
                        color: const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      minFontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    AutoSizeText(
                      'NISN: ${santriData['nisn'] ?? '-'}',
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: const Color(0xFF8E8E8E),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Notification Bell
              if (onNotificationTap != null)
                GestureDetector(
                  onTap: onNotificationTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF1A1A1A),
                          size: 24,
                        ),
                        if (notificationCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444), // Merah untuk notifikasi
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  notificationCount > 9 ? '9+' : notificationCount.toString(),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 2. Saldo Card (Deep Emerald Green Gradient)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Premium Dark Slate
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label Saldo & Visibility
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Total Saldo',
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: onToggleSaldoVisibility,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.transparent,
                        child: Icon(
                          isSaldoVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Saldo Amount
                AutoSizeText(
                  isSaldoVisible ? saldo : 'Rp ••••••••',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 28 : 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  minFontSize: 18,
                ),
                
                const SizedBox(height: 24),
                
                // Top Up Button
                GestureDetector(
                  onTap: onTopUpTap,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_rounded,
                          color: Color(0xFF10B981), // Emerald Green
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Isi Saldo',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981), // Emerald Green
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w700,
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
      ],
    );
  }
}
