// quran/widget/quran_dialog.dart - ✅ DIALOG + STICKY FAB NAVIGATION
import 'package:flutter/material.dart';
import 'package:pizab_molah/quran/widget/tajwid_dialog.dart';

class QuranDialogs {
  // ==================== ✅ REALTIME SETTINGS DIALOG ====================
  static void showSettings({
    required BuildContext context,
    required double fontSize,
    required bool showTranslation,
    required bool showTransliteration,
    required bool showTajwid,
    required bool isDarkMode,
    required ValueChanged<double> onFontSizeChanged,
    required ValueChanged<bool> onTranslationToggled,
    required ValueChanged<bool> onTransliterationToggled,
    required ValueChanged<bool> onTajwidToggled,
    required ValueChanged<bool> onDarkModeToggled,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _RealtimeSettingsSheet(
        initialFontSize: fontSize,
        initialShowTranslation: showTranslation,
        initialShowTransliteration: showTransliteration,
        initialShowTajwid: showTajwid,
        initialIsDarkMode: isDarkMode,
        onFontSizeChanged: onFontSizeChanged,
        onTranslationToggled: onTranslationToggled,
        onTransliterationToggled: onTransliterationToggled,
        onTajwidToggled: onTajwidToggled,
        onDarkModeToggled: onDarkModeToggled,
      ),
    );
  }

  // ==================== ✅ COMPLETION DIALOG WITH FAB TRIGGER ====================
  static void showNextSurahDialog({
    required BuildContext context,
    required String currentSurahName,
    required int currentSurahNumber,
    required VoidCallback onContinue,
    required VoidCallback onLater, // ✅ ADDED - Trigger FAB
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF9FAFB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF059669).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.check_circle, color: Colors.white, size: 48),
              ),
              SizedBox(height: 20),
              Text(
                'Selesai Membaca',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Surah $currentSurahName',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories,
                      color: Color(0xFF059669),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lanjutkan ke surah berikutnya?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onLater(); // ✅ TRIGGER FAB
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Nanti',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onContinue();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Color(0xFF059669),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lanjutkan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ✅ MINIMAL ELEGANT FABs ====================
class SurahNavigationFABs extends StatefulWidget {
  final ScrollController scrollController;
  final bool isVisible; // Controlled by parent
  final String? nextSurahName;
  final String? previousSurahName;
  final VoidCallback? onNextSurah;
  final VoidCallback? onPreviousSurah;
  final bool isDarkMode;

  const SurahNavigationFABs({
    super.key,
    required this.scrollController,
    required this.isVisible,
    this.nextSurahName,
    this.previousSurahName,
    this.onNextSurah,
    this.onPreviousSurah,
    this.isDarkMode = false,
  });

  @override
  State<SurahNavigationFABs> createState() => _SurahNavigationFABsState();
}

class _SurahNavigationFABsState extends State<SurahNavigationFABs>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _shouldHideFABs = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    widget.scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients) return;

    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final currentScroll = widget.scrollController.position.pixels;

    final shouldHide = (maxScroll - currentScroll) > 200;

    if (shouldHide != _shouldHideFABs) {
      setState(() => _shouldHideFABs = shouldHide);
    }
  }

  @override
  void didUpdateWidget(SurahNavigationFABs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible && !_shouldHideFABs) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || _shouldHideFABs) {
      return SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Color(0xFF1E293B).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: widget.isDarkMode
                      ? Color(0xFF334155).withValues(alpha: 0.5)
                      : Color(0xFFE5E7EB).withValues(alpha: 0.8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onPreviousSurah != null &&
                      widget.previousSurahName != null)
                    _buildMinimalButton(
                      surahName: widget.previousSurahName!,
                      isNext: false,
                      onPressed: widget.onPreviousSurah!,
                    ),

                  if (widget.onPreviousSurah != null &&
                      widget.onNextSurah != null)
                    Container(
                      width: 1,
                      height: 32,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      color: widget.isDarkMode
                          ? Color(0xFF334155).withValues(alpha: 0.5)
                          : Color(0xFFE5E7EB).withValues(alpha: 0.8),
                    ),

                  if (widget.onNextSurah != null &&
                      widget.nextSurahName != null)
                    _buildMinimalButton(
                      surahName: widget.nextSurahName!,
                      isNext: true,
                      onPressed: widget.onNextSurah!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalButton({
    required String surahName,
    required bool isNext,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isNext) ...[
                Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: widget.isDarkMode
                      ? Color(0xFF94A3B8)
                      : Color(0xFF6B7280),
                ),
                SizedBox(width: 4),
              ],
              Text(
                surahName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkMode
                      ? Color(0xFFE2E8F0)
                      : Color(0xFF1F2937),
                  letterSpacing: 0.2,
                ),
              ),
              if (isNext) ...[
                SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: widget.isDarkMode
                      ? Color(0xFF94A3B8)
                      : Color(0xFF6B7280),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ✅ REALTIME SETTINGS SHEET ====================
class _RealtimeSettingsSheet extends StatefulWidget {
  final double initialFontSize;
  final bool initialShowTranslation;
  final bool initialShowTransliteration;
  final bool initialShowTajwid;
  final bool initialIsDarkMode;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onTranslationToggled;
  final ValueChanged<bool> onTransliterationToggled;
  final ValueChanged<bool> onTajwidToggled;
  final ValueChanged<bool> onDarkModeToggled;

  const _RealtimeSettingsSheet({
    required this.initialFontSize,
    required this.initialShowTranslation,
    required this.initialShowTransliteration,
    required this.initialShowTajwid,
    required this.initialIsDarkMode,
    required this.onFontSizeChanged,
    required this.onTranslationToggled,
    required this.onTransliterationToggled,
    required this.onTajwidToggled,
    required this.onDarkModeToggled,
  });

  @override
  State<_RealtimeSettingsSheet> createState() => _RealtimeSettingsSheetState();
}

class _RealtimeSettingsSheetState extends State<_RealtimeSettingsSheet> {
  late double _fontSize;
  late bool _showTranslation;
  late bool _showTransliteration;
  late bool _showTajwid;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.initialFontSize;
    _showTranslation = widget.initialShowTranslation;
    _showTransliteration = widget.initialShowTransliteration;
    _showTajwid = widget.initialShowTajwid;
    _isDarkMode = widget.initialIsDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _isDarkMode ? Color(0xFF334155) : Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.settings, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengaturan Tampilan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Perubahan langsung terlihat',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: _isDarkMode ? Color(0xFF334155) : Color(0xFFE5E7EB),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Ukuran Teks Arab', Icons.text_fields),
                    SizedBox(height: 12),
                    _buildFontSizeSlider(),
                    SizedBox(height: 24),

                    _buildSectionHeader('Opsi Tampilan', Icons.visibility),
                    SizedBox(height: 12),
                    _buildToggleOption(
                      icon: Icons.translate,
                      iconColor: Color(0xFF3B82F6),
                      iconBg: Color(0xFF3B82F6).withValues(alpha: 0.1),
                      title: 'Terjemahan Indonesia',
                      subtitle: 'Tampilkan arti ayat',
                      value: _showTranslation,
                      onChanged: (value) {
                        setState(() => _showTranslation = value);
                        widget.onTranslationToggled(value);
                      },
                    ),
                    SizedBox(height: 12),
                    _buildToggleOption(
                      icon: Icons.record_voice_over,
                      iconColor: Color(0xFF8B5CF6),
                      iconBg: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      title: 'Transliterasi Latin',
                      subtitle: 'Tampilkan bacaan latin',
                      value: _showTransliteration,
                      onChanged: (value) {
                        setState(() => _showTransliteration = value);
                        widget.onTransliterationToggled(value);
                      },
                    ),
                    SizedBox(height: 12),
                    _buildTajwidToggleOption(),

                    SizedBox(height: 24),

                    _buildSectionHeader('Tema Aplikasi', Icons.palette),
                    SizedBox(height: 12),
                    _buildToggleOption(
                      icon: Icons.dark_mode,
                      iconColor: Color(0xFF6366F1),
                      iconBg: Color(0xFF6366F1).withValues(alpha: 0.1),
                      title: 'Mode Gelap',
                      subtitle: 'Nyaman untuk membaca lama',
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() => _isDarkMode = value);
                        widget.onDarkModeToggled(value);
                      },
                    ),

                    SizedBox(height: 24),
                    _buildInfoFooter(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF059669)),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF0F172A) : Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode ? Color(0xFF334155) : Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'A',
                style: TextStyle(
                  fontFamily: 'Utsmani',
                  fontSize: 20,
                  color: _isDarkMode ? Color(0xFF64748B) : Color(0xFF6B7280),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_fontSize.round()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'A',
                style: TextStyle(
                  fontFamily: 'Utsmani',
                  fontSize: 36,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Color(0xFF059669),
              inactiveTrackColor: _isDarkMode
                  ? Color(0xFF334155)
                  : Color(0xFFD1D5DB),
              thumbColor: Color(0xFF059669),
              overlayColor: Color(0xFF059669).withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _fontSize,
              min: 20,
              max: 40,
              divisions: 20,
              onChanged: (value) {
                setState(() => _fontSize = value);
                widget.onFontSizeChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode ? Color(0xFF334155) : Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
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
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _isDarkMode
                              ? Color(0xFFF1F5F9)
                              : Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: _isDarkMode
                              ? Color(0xFF94A3B8)
                              : Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
                if (trailing == null)
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: Color(0xFF059669),
                    activeTrackColor: Color(0xFF059669).withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [
                  Color(0xFF064E3B).withValues(alpha: 0.5),
                  Color(0xFF065F46).withValues(alpha: 0.3),
                ]
              : [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode
              ? Color(0xFF059669).withValues(alpha: 0.5)
              : Color(0xFF86EFAC),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            color: _isDarkMode ? Color(0xFF86EFAC) : Color(0xFF059669),
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Perubahan langsung tersimpan & terlihat!',
              style: TextStyle(
                fontSize: 13,
                color: _isDarkMode ? Color(0xFF86EFAC) : Color(0xFF065F46),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTajwidToggleOption() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _showTajwid
              ? Color(0xFF7C3AED)
              : (_isDarkMode ? Color(0xFF334155) : Color(0xFFE5E7EB)),
          width: _showTajwid ? 2 : 1.5,
        ),
        gradient: _showTajwid
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isDarkMode
                    ? [
                        Color(0xFF7C3AED).withValues(alpha: 0.1),
                        Color(0xFF6D28D9).withValues(alpha: 0.05),
                      ]
                    : [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _showTajwid = !_showTajwid);
            widget.onTajwidToggled(_showTajwid);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _showTajwid
                        ? Color(0xFF7C3AED).withValues(alpha: 0.2)
                        : Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _showTajwid
                        ? [
                            BoxShadow(
                              color: Color(0xFF7C3AED).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _showTajwid ? Icons.palette : Icons.color_lens,
                    color: _showTajwid ? Color(0xFF7C3AED) : Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Warna Tajwid',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _isDarkMode
                              ? Color(0xFFF1F5F9)
                              : Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        _showTajwid
                            ? 'Garis bawah tajwid ditampilkan'
                            : 'Tampilkan garis bawah tajwid',
                        style: TextStyle(
                          fontSize: 13,
                          color: _showTajwid
                              ? Color(0xFF7C3AED)
                              : (_isDarkMode
                                    ? Color(0xFF94A3B8)
                                    : Color(0xFF6B7280)),
                          fontWeight: _showTajwid
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Color(0xFF059669),
                  ),
                  onPressed: () {
                    TajwidLegendDialog.show(context);
                  },
                  tooltip: 'Lihat panduan tajwid',
                ),
                Switch(
                  value: _showTajwid,
                  onChanged: (value) {
                    setState(() => _showTajwid = value);
                    widget.onTajwidToggled(value);
                  },
                  activeThumbColor: Color(0xFF7C3AED),
                  activeTrackColor: Color(0xFF7C3AED).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
