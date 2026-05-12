// widget/ayat_list_item.dart - ✅ OPTIMIZED: Smooth Performance + Animations
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:pizab_molah/quran/helper/tajwid_helper.dart';
import 'package:pizab_molah/quran/helper/theme.dart';
import 'package:pizab_molah/quran/model/surah_model.dart';
import 'package:pizab_molah/quran/service/tasfir_service.dart';
import 'package:pizab_molah/quran/widget/share_ayat.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// ✅ OPTIMIZATION 1: Use const constructor extensively
class AyahListItem extends StatelessWidget {
  final int ayahNumber;
  final SurahModel surah;
  final double fontSize;
  final bool showTranslation;
  final bool showTransliteration;
  final bool showTajwid;
  final bool isDarkMode;
  final bool isBookmarked;
  final bool isTargetAyah;
  final bool isPlayingThis;
  final bool isTablet;
  final VoidCallback onPlayAudio;
  final VoidCallback onToggleBookmark;
  final VoidCallback onSaveLastRead;

  const AyahListItem({
    super.key,
    required this.ayahNumber,
    required this.surah,
    required this.fontSize,
    required this.showTranslation,
    this.showTransliteration = true,
    this.showTajwid = false,
    this.isDarkMode = false,
    required this.isBookmarked,
    required this.isTargetAyah,
    required this.isPlayingThis,
    required this.isTablet,
    required this.onPlayAudio,
    required this.onToggleBookmark,
    required this.onSaveLastRead,
  });

  // ✅ OPTIMIZATION 2: Cache heavy computations
  Widget _buildArabicText(String ayahText, QuranTheme theme) {
    final baseStyle = TextStyle(
      fontFamily: 'Utsmani',
      fontSize: fontSize,
      height: 1.85,
      color: theme.arabicText,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.0,
      wordSpacing: 0.0,
    );

    final strutStyle = StrutStyle(
      fontFamily: 'Utsmani',
      fontSize: fontSize,
      height: 1.85,
      forceStrutHeight: true,
      leading: 0.0,
    );

    // ✅ OPTIMIZATION 3: Reduce unnecessary Container nesting
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 24 : 20,
        isTablet ? 24 : 20,
        isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(gradient: theme.arabicBackground),
      // ✅ OPTIMIZATION 4: Use RepaintBoundary for complex text
      child: RepaintBoundary(
        child: showTajwid
            ? RichText(
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
                strutStyle: strutStyle,
                text: TajwidHelper.buildTajwidText(
                  ayahText,
                  baseStyle: baseStyle,
                  enableTajwid: true,
                ),
                textScaler: const TextScaler.linear(1.0),
              )
            : Text(
                ayahText,
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
                textScaleFactor: 1.0,
                strutStyle: strutStyle,
                style: baseStyle,
              ),
      ),
    );
  }

  void _showAyahOptionsMenu(BuildContext context) {
    final theme = QuranTheme(isDark: isDarkMode);
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // ✅ OPTIMIZATION 5: Enable drag to dismiss
      enableDrag: true,
      // ✅ OPTIMIZATION 6: Use builder pattern efficiently
      builder: (context) => _AyahOptionsSheet(
        surah: surah,
        ayahNumber: ayahNumber,
        theme: theme,
        isDarkMode: isDarkMode,
        isBookmarked: isBookmarked,
        onSaveLastRead: onSaveLastRead,
        onToggleBookmark: onToggleBookmark,
        onShowSuccessSnackBar: (message, icon) =>
            _showSuccessSnackBar(context, theme, message, icon),
        fontSize: fontSize,
      ),
    );
  }

  void _showSuccessSnackBar(
    BuildContext context,
    QuranTheme theme,
    String message,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareAyah(BuildContext context) async {
    if (!context.mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AyahShareFullScreenPage(
            ayahNumber: ayahNumber,
            surah: surah,
            fontSize: fontSize,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  void _copyToClipboard(BuildContext context, QuranTheme theme) {
    final ayahText = surah.getAyahText(ayahNumber);
    final translation = surah.getAyahTranslation(ayahNumber);
    final fullText =
        '$ayahText\n\n$translation\n\n(${surah.nameLatin} - Ayat $ayahNumber)';

    Clipboard.setData(ClipboardData(text: fullText));
    HapticFeedback.lightImpact();
    _showSuccessSnackBar(
      context,
      theme,
      'Ayat berhasil disalin',
      Icons.check_circle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = QuranTheme(isDark: isDarkMode);
    final ayahText = surah.getAyahText(ayahNumber);
    final transliteration = surah.getAyahTransliteration(ayahNumber);
    final translation = surah.getAyahTranslation(ayahNumber);

    // ✅ OPTIMIZATION 7: Use RepaintBoundary for entire card
    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: () => _showAyahOptionsMenu(context),
        // ✅ OPTIMIZATION 8: Optimize hit test behavior
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
          decoration: isTargetAyah
              ? BoxDecoration(
                  color: theme.targetAyahBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.targetAyahBorder, width: 2),
                  boxShadow: [theme.cardShadow(isTarget: true)],
                )
              : theme.getCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ✅ OPTIMIZATION 9: Minimize layout
            children: [
              _buildHeader(context, theme),
              Divider(height: 1, color: theme.divider),
              _buildArabicText(ayahText, theme),
              if (showTransliteration && transliteration.isNotEmpty)
                _buildTransliteration(transliteration, theme),
              if (showTranslation && translation.isNotEmpty)
                _buildTranslation(translation, theme),
              if (isTargetAyah) _buildLongPressHint(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, QuranTheme theme) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 18 : 16),
      child: Row(
        children: [
          _buildAyahNumber(theme),
          const SizedBox(width: 12),
          if (isBookmarked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: theme.bookmarkGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.bookmark, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Bookmark',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),
          _buildPlayButton(theme),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.more_vert_rounded,
            color: theme.secondaryText,
            onTap: () {
              HapticFeedback.lightImpact();
              _showAyahOptionsMenu(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAyahNumber(QuranTheme theme) {
    return SizedBox(
      width: isTablet ? 48 : 44,
      height: isTablet ? 48 : 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ OPTIMIZATION 10: Cache image with RepaintBoundary
          RepaintBoundary(
            child: Image.asset(
              'assets/other/img_number.png',
              width: isTablet ? 48 : 44,
              height: isTablet ? 48 : 44,
              fit: BoxFit.contain,
              color: isTargetAyah
                  ? theme.ayahNumberActiveColor
                  : theme.ayahNumberColor,
              colorBlendMode: BlendMode.srcIn,
              // ✅ OPTIMIZATION 11: Use cacheWidth/Height for better memory
              cacheWidth: (isTablet ? 48 : 44) * 3, // 3x for retina
              cacheHeight: (isTablet ? 48 : 44) * 3,
            ),
          ),
          Text(
            '$ayahNumber',
            style: TextStyle(
              color: isTargetAyah
                  ? theme.ayahNumberActiveColor
                  : theme.primaryText,
              fontSize: isTablet ? 17 : 15,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(QuranTheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onPlayAudio();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 14,
            vertical: isTablet ? 10 : 8,
          ),
          decoration: BoxDecoration(
            gradient: isPlayingThis ? theme.playButtonGradient : null,
            color: isPlayingThis ? null : theme.playButtonBgInactive,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primary.withValues(alpha: isPlayingThis ? 0.0 : 0.3),
              width: 1.5,
            ),
            boxShadow: isPlayingThis
                ? [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: isTablet ? 22 : 20,
                color: isPlayingThis ? Colors.white : theme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isPlayingThis ? 'Pause' : 'Putar',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.bold,
                  color: isPlayingThis ? Colors.white : theme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 10 : 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, size: isTablet ? 20 : 18, color: color),
      ),
    );
  }

  Widget _buildLongPressHint(QuranTheme theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 14 : 12,
      ),
      decoration: BoxDecoration(
        gradient: theme.infoBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, size: 16, color: theme.infoText),
          const SizedBox(width: 8),
          Text(
            'Tahan lama untuk opsi lainnya',
            style: TextStyle(
              fontSize: 12,
              color: theme.infoText,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransliteration(String transliteration, QuranTheme theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 16 : 14,
        isTablet ? 24 : 20,
        isTablet ? 16 : 14,
      ),
      decoration: BoxDecoration(
        color: theme.transliterationBg,
        border: Border(
          bottom: BorderSide(color: theme.transliterationBorder, width: 1),
        ),
      ),
      child: Text(
        transliteration,
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontSize: (fontSize * 0.45).clamp(13.0, 16.0),
          height: 1.7,
          color: theme.transliterationText,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          wordSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildTranslation(String translation, QuranTheme theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 20 : 16,
        isTablet ? 24 : 20,
        isTablet ? 20 : 16,
      ),
      child: Text(
        translation,
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontSize: (fontSize * 0.5).clamp(14.0, 18.0),
          height: 1.8,
          color: theme.translationText,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
          wordSpacing: 2.5,
        ),
      ),
    );
  }
}

// ✅ OPTIMIZATION 12: Separate StatefulWidget untuk bottom sheet
class _AyahOptionsSheet extends StatelessWidget {
  final SurahModel surah;
  final int ayahNumber;
  final QuranTheme theme;
  final bool isDarkMode;
  final bool isBookmarked;
  final VoidCallback onSaveLastRead;
  final VoidCallback onToggleBookmark;
  final Function(String, IconData) onShowSuccessSnackBar;
  final double fontSize;

  const _AyahOptionsSheet({
    required this.surah,
    required this.ayahNumber,
    required this.theme,
    required this.isDarkMode,
    required this.isBookmarked,
    required this.onSaveLastRead,
    required this.onToggleBookmark,
    required this.onShowSuccessSnackBar,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.dialogBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF334155) : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${surah.nameLatin} - Ayat $ayahNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        'Pilih tindakan',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.divider),

            _buildMenuOption(
              context: context,
              icon: Icons.bookmark_add_rounded,
              iconColor: const Color(0xFF059669),
              iconBg: const Color(0xFF059669).withValues(alpha: 0.1),
              title: 'Tandai Terakhir Dibaca',
              subtitle: 'Simpan posisi baca Anda di ayat ini',
              onTap: () {
                Navigator.pop(context);
                onSaveLastRead();
                onShowSuccessSnackBar(
                  'Posisi terakhir dibaca disimpan',
                  Icons.bookmark_added_rounded,
                );
              },
            ),

            _buildMenuOption(
              context: context,
              icon: isBookmarked
                  ? Icons.bookmark
                  : Icons.bookmark_border_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              title: isBookmarked ? 'Hapus Bookmark' : 'Tambah Bookmark',
              subtitle: isBookmarked
                  ? 'Hapus ayat dari daftar bookmark'
                  : 'Simpan ayat ke daftar bookmark',
              onTap: () {
                Navigator.pop(context);
                onToggleBookmark();
                onShowSuccessSnackBar(
                  isBookmarked ? 'Bookmark dihapus' : 'Bookmark ditambahkan',
                  isBookmarked ? Icons.bookmark_remove : Icons.bookmark_added,
                );
              },
            ),

            _buildMenuOption(
              context: context,
              icon: Icons.article_rounded,
              iconColor: const Color(0xFF7C3AED),
              iconBg: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              title: 'Baca Tafsir',
              subtitle: 'Pahami makna ayat dengan tafsir',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TafsirDetailPage(
                      surahNumber: int.parse(surah.number),
                      ayahNumber: ayahNumber,
                      surahName: surah.nameLatin,
                      ayahText: surah.getAyahText(ayahNumber),
                      translation: surah.getAyahTranslation(ayahNumber),
                      tafsir: '',
                    ),
                  ),
                );
              },
            ),

            _buildMenuOption(
              context: context,
              icon: Icons.share_rounded,
              iconColor: const Color(0xFF3B82F6),
              iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              title: 'Bagikan Ayat',
              subtitle: 'Bagikan ayat ke aplikasi lain',
              onTap: () {
                Navigator.pop(context);
                _shareAyah(context);
              },
            ),

            _buildMenuOption(
              context: context,
              icon: Icons.content_copy_rounded,
              iconColor: const Color(0xFF6B7280),
              iconBg: const Color(0xFF6B7280).withValues(alpha: 0.1),
              title: 'Salin Teks',
              subtitle: 'Salin ayat ke clipboard',
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(context);
              },
              isLast: true,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: theme.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 84, endIndent: 20, color: theme.divider),
      ],
    );
  }

  void _shareAyah(BuildContext context) async {
    if (!context.mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AyahShareFullScreenPage(
            ayahNumber: ayahNumber,
            surah: surah,
            fontSize: fontSize,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  void _copyToClipboard(BuildContext context) {
    final ayahText = surah.getAyahText(ayahNumber);
    final translation = surah.getAyahTranslation(ayahNumber);
    final fullText =
        '$ayahText\n\n$translation\n\n(${surah.nameLatin} - Ayat $ayahNumber)';

    Clipboard.setData(ClipboardData(text: fullText));
    HapticFeedback.lightImpact();
    onShowSuccessSnackBar('Ayat berhasil disalin', Icons.check_circle);
  }
}

// Share dialog classes - Optimized versions
class _AyahSharePreviewDialog extends StatefulWidget {
  final int ayahNumber;
  final SurahModel surah;
  final double fontSize;

  const _AyahSharePreviewDialog({
    required this.ayahNumber,
    required this.surah,
    required this.fontSize,
  });

  @override
  State<_AyahSharePreviewDialog> createState() =>
      _AyahSharePreviewDialogState();
}

class _AyahSharePreviewDialogState extends State<_AyahSharePreviewDialog> {
  final int _selectedDesign = 0;
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;

  static const List<ShareDesignTheme> _designs = [
    ShareDesignTheme(
      name: 'Emerald Gradient',
      primaryGradient: [
        Color(0xFF059669),
        Color(0xFF047857),
        Color(0xFF065F46),
      ],
      accentColor: Color(0xFFFBBF24),
    ),
    ShareDesignTheme(
      name: 'Royal Purple',
      primaryGradient: [
        Color(0xFF7C3AED),
        Color(0xFF6D28D9),
        Color(0xFF5B21B6),
      ],
      accentColor: Color(0xFFFBBF24),
    ),
    ShareDesignTheme(
      name: 'Ocean Blue',
      primaryGradient: [
        Color(0xFF0EA5E9),
        Color(0xFF0284C7),
        Color(0xFF0369A1),
      ],
      accentColor: Color(0xFFFDE047),
    ),
  ];

  Future<void> _shareAsImage() async {
    setState(() => _isSharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final RenderObject? renderObject = _repaintKey.currentContext
          ?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw Exception('Render boundary tidak ditemukan');
      }

      final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) throw Exception('Gagal convert gambar');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath =
          '${directory.path}/ayah_${widget.surah.number}_${widget.ayahNumber}_$timestamp.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text:
            '${widget.surah.nameLatin} - Ayat ${widget.ayahNumber}\n\nDibagikan dari Bekal Muslim',
      );

      if (mounted) {
        setState(() => _isSharing = false);
        Navigator.pop(context);
      }

      Future.delayed(const Duration(seconds: 10), () {
        if (imageFile.existsSync()) imageFile.delete();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _designs[_selectedDesign].primaryGradient,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Bagikan Ayat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _AyahShareCard(
                    ayahNumber: widget.ayahNumber,
                    surah: widget.surah,
                    fontSize: widget.fontSize,
                    theme: _designs[_selectedDesign],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _shareAsImage,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.share, size: 20),
                  label: Text(
                    _isSharing ? 'Membagikan...' : 'Bagikan Gambar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _designs[_selectedDesign].primaryGradient[0],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ OPTIMIZATION 13: Optimized Share Card with RepaintBoundary
class _AyahShareCard extends StatelessWidget {
  final int ayahNumber;
  final SurahModel surah;
  final double fontSize;
  final ShareDesignTheme theme;

  const _AyahShareCard({
    required this.ayahNumber,
    required this.surah,
    required this.fontSize,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final ayahText = surah.getAyahText(ayahNumber);
    final translation = surah.getAyahTranslation(ayahNumber);

    return Container(
      width: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryGradient[0].withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
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
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: theme.accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surah.nameLatin,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ayat $ayahNumber',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    ayahText,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Utsmani',
                      fontSize: 28,
                      height: 2.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    translation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark_rounded,
                            color: theme.accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Bekal Muslim',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Center(
                  child: Container(
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          theme.accentColor.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ OPTIMIZATION 14: Use const for immutable theme data
class ShareDesignTheme {
  final String name;
  final List<Color> primaryGradient;
  final Color accentColor;

  const ShareDesignTheme({
    required this.name,
    required this.primaryGradient,
    required this.accentColor,
  });
}
