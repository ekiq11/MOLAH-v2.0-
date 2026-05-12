// widget/quran_app_bar.dart - UPDATED (tetap gunakan struktur asli Anda)
import 'package:flutter/material.dart';
import 'package:pizab_molah/quran/helper/constants.dart';
import 'package:pizab_molah/quran/helper/theme.dart';

import 'dart:math' as math;

import 'package:pizab_molah/quran/model/surah_model.dart';
import 'package:pizab_molah/quran/service/audio_service.dart';

class QuranAppBar extends StatelessWidget {
  final SurahModel? surah;
  final bool showTranslation;
  final bool showTransliteration;
  final bool isTablet;
  final bool isDarkMode; // ✅ ADDED
  final VoidCallback onBackPressed;
  final VoidCallback onSettingsPressed;

  const QuranAppBar({
    super.key,
    required this.surah,
    required this.showTranslation,
    required this.showTransliteration,
    required this.isTablet,
    this.isDarkMode = false, // ✅ ADDED
    required this.onBackPressed,
    required this.onSettingsPressed,
    required Null Function() onTranslationToggled,
    required Null Function() onTransliterationToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = QuranTheme(isDark: isDarkMode);
    final bool isTaubah = surah?.nameLatin == 'At-Taubah';
    final bool isFatihah = surah?.nameLatin == 'Al-Fatihah';

    double expandedHeight;
    if (isFatihah) {
      expandedHeight = isTablet ? 380 : 340;
    } else {
      expandedHeight = isTablet ? 500 : 450;
    }

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      backgroundColor: isDarkMode ? Color(0xFF0F172A) : AppColors.primary,
      elevation: 0,
      leading: _buildIconButton(
        icon: Icons.arrow_back_ios_new,
        onPressed: onBackPressed,
      ),
      actions: [
        _buildIconButton(
          icon: Icons.tune,
          onPressed: onSettingsPressed,
          isLast: true,
          tooltip: 'Pengaturan',
        ),
      ],
      title: surah != null
          ? AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 200),
              child: Column(
                children: [
                  Text(
                    surah!.nameLatin,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        size: 10,
                        color: Color(0xFFFFD700),
                      ),
                      SizedBox(width: 4),
                      Text(
                        QuranAudioService.qariName,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.zero,
        background: _buildBackground(context, theme),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    bool isLast = false,
    bool isActive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(
        right: isLast ? 8 : 0,
        left: 8,
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.25)]
              : [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.15),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.2),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildBackground(BuildContext context, QuranTheme theme) {
    return Stack(
      children: [
        // ✅ Gradient disesuaikan dengan dark mode
        Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 14, 136, 97),
                      Color.fromARGB(255, 2, 97, 70),
                    ],
                  ),
          ),
        ),

        // Islamic Pattern Overlay
        Positioned.fill(
          child: Opacity(
            opacity: 0.08,
            child: CustomPaint(painter: IslamicPatternPainter()),
          ),
        ),

        // Decorative Circles
        Positioned(
          right: -60,
          top: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFFD700).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: -40,
          top: 100,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
              ),
            ),
          ),
        ),

        // Content
        if (surah != null)
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: isTablet ? 80 : 70,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOrnamentalDivider(),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildSurahInfoCard(context),
                    SizedBox(height: isTablet ? 20 : 16),
                    if (surah!.nameLatin != 'Al-Fatihah')
                      _buildBismillahSection(),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrnamentalDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOrnament(),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12),
          width: isTablet ? 50 : 40,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFFFFD700).withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        _buildOrnament(),
      ],
    );
  }

  Widget _buildOrnament() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFE55C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFD700).withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSurahInfoCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 24,
        vertical: isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: isTablet ? 60 : 50,
            child: Image.asset(
              'assets/image/sname_${surah!.number}.png',
              color: Color(0xFFFFD700),
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  surah!.name,
                  style: TextStyle(
                    fontFamily: 'Utsmani',
                    fontSize: isTablet ? 36 : 30,
                    color: Color(0xFFFFD700),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            surah!.nameLatin,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            surah!.translation,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Colors.white.withValues(alpha: 0.85),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isTablet ? 14 : 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.circle, size: 6, color: Color(0xFFFFD700)),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                icon: Icons.location_on,
                text: surah!.revelationPlace,
              ),
              SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.menu_book_rounded,
                text: '${surah!.numberOfAyah} Ayat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFD700).withValues(alpha: 0.25),
            Color(0xFFFFD700).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Color(0xFFFFD700), size: isTablet ? 16 : 14),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: isTablet ? 13 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillahSection() {
    final isTaubah = surah!.nameLatin == 'At-Taubah';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallOrnament(),
              SizedBox(width: 8),
              _buildSmallOrnament(),
              SizedBox(width: 8),
              _buildSmallOrnament(),
            ],
          ),
          SizedBox(height: isTablet ? 14 : 10),
          SizedBox(
            height: isTaubah ? (isTablet ? 55 : 45) : (isTablet ? 48 : 40),
            child: isTaubah
                ? Image.asset(
                    'assets/image/taawuz.png',
                    color: Color(0xFFFFD700),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
                        style: TextStyle(
                          fontFamily: 'Utsmani',
                          fontSize: isTablet ? 22 : 18,
                          color: Color(0xFFFFD700),
                          height: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  )
                : Image.asset(
                    'assets/image/img_bismillah.png',
                    color: Color(0xFFFFD700),
                    fit: BoxFit.contain,
                  ),
          ),
          SizedBox(height: isTablet ? 12 : 10),
          Text(
            isTaubah
                ? 'Aku berlindung kepada Allah dari setan yang terkutuk'
                : 'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang',
            style: TextStyle(
              fontSize: isTablet ? 13 : 11,
              color: Colors.white.withValues(alpha: 0.85),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallOrnament(),
              SizedBox(width: 8),
              _buildSmallOrnament(),
              SizedBox(width: 8),
              _buildSmallOrnament(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallOrnament() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFD700),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFD700).withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// Islamic Pattern Painter - tetap sama
class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        _drawStar(canvas, Offset(x, y), 15, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;
    const angle = (2 * math.pi) / points;

    for (int i = 0; i < points; i++) {
      final currentAngle = i * angle;
      final currentRadius = radius * 0.5 * (i.isEven ? 1 : 0.5);

      final x = center.dx + currentRadius * math.cos(currentAngle);
      final y = center.dy + currentRadius * math.sin(currentAngle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
