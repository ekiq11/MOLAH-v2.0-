// quran/helper/quran_theme.dart - COMPLETE Dark Mode Support
import 'package:flutter/material.dart';

class QuranTheme {
  final bool isDark;

  QuranTheme({required this.isDark});

  // ==================== BACKGROUND COLORS ====================
  Color get scaffoldBackground =>
      isDark ? Color(0xFF0F172A) : Color(0xFFF8F9FA);
  Color get cardBackground => isDark ? Color(0xFF1E293B) : Colors.white;
  Color get cardBorder => isDark ? Color(0xFF334155) : Color(0xFFE5E7EB);

  // ==================== TEXT COLORS ====================
  Color get primaryText => isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937);
  Color get secondaryText => isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280);

  // ✅ FIXED: Warna Arabic text yang konsisten dan mudah dibaca
  Color get arabicText => isDark ? Color(0xFFFEFCE8) : Color(0xFF1F2937);

  // ==================== ARABIC BACKGROUND ====================
  LinearGradient get arabicBackground => isDark
      ? LinearGradient(
          colors: [
            Color(0xFF1E293B).withValues(alpha: 0.6),
            Color(0xFF334155).withValues(alpha: 0.4),
          ],
        )
      : LinearGradient(
          colors: [
            Color(0xFFFFF7ED).withValues(alpha: 0.5),
            Color(0xFFFEF3C7).withValues(alpha: 0.3),
          ],
        );

  // ==================== TRANSLITERATION SECTION ====================
  Color get transliterationBg => isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC);
  Color get transliterationBorder =>
      isDark ? Color(0xFF334155) : Color(0xFFE5E7EB);
  Color get transliterationText =>
      isDark ? Color(0xFF94A3B8) : Color(0xFF64748B);

  // ==================== TRANSLATION SECTION ====================
  Color get translationBg => isDark ? Color(0xFF1E293B) : Colors.white;
  Color get translationText => isDark ? Color(0xFFE2E8F0) : Color(0xFF374151);

  // ==================== TARGET AYAH COLORS ====================
  Color get targetAyahBg => isDark ? Color(0xFF064E3B) : Color(0xFFF0FDF4);
  Color get targetAyahBorder => Color(0xFF059669); // Sama untuk dark/light

  LinearGradient get targetAyahGradient => isDark
      ? LinearGradient(
          colors: [
            Color(0xFF064E3B).withValues(alpha: 0.8),
            Color(0xFF065F46).withValues(alpha: 0.6),
          ],
        )
      : LinearGradient(colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]);

  // ==================== SHADOWS ====================
  BoxShadow cardShadow({bool isTarget = false}) {
    if (isDark) {
      return BoxShadow(
        color: Colors.black.withValues(alpha: isTarget ? 0.5 : 0.3),
        blurRadius: isTarget ? 20 : 12,
        offset: Offset(0, isTarget ? 6 : 3),
      );
    } else {
      return BoxShadow(
        color: (isTarget ? Color(0xFF059669) : Colors.black).withValues(alpha: 
          isTarget ? 0.15 : 0.05,
        ),
        blurRadius: isTarget ? 16 : 12,
        offset: Offset(0, isTarget ? 4 : 2),
      );
    }
  }

  // ==================== ACCENT COLORS ====================
  // Tetap sama di dark/light mode untuk konsistensi branding
  Color get primary => Color(0xFF059669);
  Color get primaryDark => Color(0xFF047857);
  Color get amber => Color(0xFFF59E0B);
  Color get blue => Color(0xFF3B82F6);
  Color get purple => Color(0xFF7C3AED);
  Color get gold => Color(0xFFFFD700);

  // ==================== DIVIDERS ====================
  Color get divider => isDark ? Color(0xFF334155) : Color(0xFFE5E7EB);
  Color get dividerLight => isDark ? Color(0xFF1E293B) : Color(0xFFF3F4F6);

  // ==================== INFO BOX ====================
  LinearGradient get infoBg => isDark
      ? LinearGradient(
          colors: [
            Color(0xFF064E3B).withValues(alpha: 0.5),
            Color(0xFF065F46).withValues(alpha: 0.3),
          ],
        )
      : LinearGradient(colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]);

  Color get infoBorder =>
      isDark ? Color(0xFF059669).withValues(alpha: 0.5) : Color(0xFF86EFAC);
  Color get infoText => isDark ? Color(0xFF86EFAC) : Color(0xFF065F46);

  // ==================== APP BAR ====================
  LinearGradient get appBarGradient => isDark
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        )
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        );

  // ==================== BUTTON STYLES ====================
  LinearGradient get primaryButtonGradient =>
      LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]);

  LinearGradient get playButtonGradient =>
      LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]);

  Color get playButtonBgInactive => isDark
      ? Color(0xFF059669).withValues(alpha: 0.15)
      : Color(0xFF059669).withValues(alpha: 0.1);

  // ==================== AYAH NUMBER ====================
  Color get ayahNumberColor => isDark ? Color(0xFF64748B) : Color(0xFF6B7280);
  Color get ayahNumberActiveColor => Color(0xFF059669);

  // ==================== BOOKMARK ====================
  LinearGradient get bookmarkGradient =>
      LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]);

  // ==================== LAST READ BANNER ====================
  LinearGradient get lastReadBanner =>
      LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]);

  LinearGradient get targetBanner =>
      LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]);

  // ==================== SETTINGS DIALOG ====================
  Color get dialogBg => isDark ? Color(0xFF1E293B) : Colors.white;
  Color get dialogHeaderBg => isDark ? Color(0xFF0F172A) : Color(0xFF059669);
  Color get sectionHeaderColor =>
      isDark ? Color(0xFFE2E8F0) : Color(0xFF1F2937);
  Color get settingsItemBg => isDark ? Color(0xFF0F172A) : Colors.white;
  Color get settingsItemBorder =>
      isDark ? Color(0xFF334155) : Color(0xFFE5E7EB);

  // ==================== ICON BACKGROUNDS ====================
  Color getIconBg(Color baseColor) {
    return isDark ? baseColor.withValues(alpha: 0.2) : baseColor.withValues(alpha: 0.1);
  }

  // ==================== SLIDER ====================
  Color get sliderActiveColor => Color(0xFF059669);
  Color get sliderInactiveColor =>
      isDark ? Color(0xFF334155) : Color(0xFFD1D5DB);
  Color get sliderThumbColor => Color(0xFF059669);

  // ==================== SEARCH BAR ====================
  Color get searchBg => isDark ? Color(0xFF1E293B) : Colors.white;
  Color get searchBorder => isDark ? Color(0xFF334155) : Color(0xFFE5E7EB);
  Color get searchIconColor => Color(0xFF059669);
  Color get searchHintColor => isDark ? Color(0xFF64748B) : Color(0xFF9CA3AF);

  // ==================== ORNAMENTS ====================
  LinearGradient get ornamentGradient =>
      LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFE55C)]);

  BoxShadow get ornamentShadow => BoxShadow(
    color: Color(0xFFFFD700).withValues(alpha: 0.5),
    blurRadius: 8,
    spreadRadius: 1,
  );

  // ==================== QUICK ACCESS CARDS ====================
  LinearGradient get quickAccessGradient => LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get bookmarksCardGradient => LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== SNACKBAR ====================
  Color get snackbarSuccess => Color(0xFF059669);
  Color get snackbarError => Color(0xFFEF4444);

  // ==================== LOADING ====================
  Color get loadingIndicator => Color(0xFF059669);

  // ==================== HELPER METHODS ====================

  /// Get contrast text color based on background
  Color getContrastText(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Color(0xFF1F2937)
        : Color(0xFFF1F5F9);
  }

  /// Get dimmed color for disabled states
  Color getDimmedColor(Color baseColor, {double opacity = 0.5}) {
    return baseColor.withValues(alpha: opacity);
  }

  /// Get elevated card decoration
  BoxDecoration getCardDecoration({bool isTarget = false}) {
    return BoxDecoration(
      color: isTarget ? targetAyahBg : cardBackground,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isTarget ? targetAyahBorder : cardBorder,
        width: isTarget ? 2 : 1,
      ),
      boxShadow: [cardShadow(isTarget: isTarget)],
    );
  }

  /// Get glassmorphism effect
  BoxDecoration getGlassDecoration({double opacity = 0.1, double blur = 10}) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: opacity)
          : Colors.white.withValues(alpha: opacity * 1.5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: opacity * 2)
            : Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }
}
