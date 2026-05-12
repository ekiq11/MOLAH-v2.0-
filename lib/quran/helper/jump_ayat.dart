// helper/jump_ayah_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Helper untuk mengelola fitur smart jump ayah
class JumpAyahHelper {
  static const String _recentJumpsKey = 'recent_ayah_jumps';
  static const int _maxRecentJumps = 3;

  /// Simpan riwayat jump terbaru
  static Future<void> saveRecentJump(int surahNumber, int ayahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJumps = await getRecentJumps(surahNumber);

      recentJumps.removeWhere((ayah) => ayah == ayahNumber);
      recentJumps.insert(0, ayahNumber);

      if (recentJumps.length > _maxRecentJumps) {
        recentJumps.removeRange(_maxRecentJumps, recentJumps.length);
      }

      await prefs.setString(
        '${_recentJumpsKey}_$surahNumber',
        jsonEncode(recentJumps),
      );
    } catch (e) {
      debugPrint('Error saving recent jump: $e');
    }
  }

  /// Ambil riwayat jump untuk surah tertentu
  static Future<List<int>> getRecentJumps(int surahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('${_recentJumpsKey}_$surahNumber');

      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e as int).toList();
    } catch (e) {
      debugPrint('Error loading recent jumps: $e');
      return [];
    }
  }

  /// Generate smart suggestions dengan angka yang mudah dibaca
  static List<SmartJumpSuggestion> getSmartSuggestions(
    int currentAyah,
    int totalAyahs,
  ) {
    final suggestions = <SmartJumpSuggestion>[];

    // Awal
    if (currentAyah > 5) {
      suggestions.add(
        SmartJumpSuggestion(
          ayah: 1,
          label: 'Beginning',
          icon: Icons.first_page,
          color: const Color(0xFF3B82F6),
        ),
      );
    }

    // Generate angka bulat yang mudah dibaca
    final milestones = _generateMilestones(totalAyahs);

    for (final milestone in milestones) {
      // Skip jika terlalu dekat dengan posisi sekarang
      if ((currentAyah - milestone).abs() > 5) {
        suggestions.add(
          SmartJumpSuggestion(
            ayah: milestone,
            label: 'Ayah $milestone',
            icon: Icons.bookmark_outline,
            color: _getMilestoneColor(milestone, totalAyahs),
          ),
        );
      }
    }

    // Akhir
    if (currentAyah < totalAyahs - 5) {
      suggestions.add(
        SmartJumpSuggestion(
          ayah: totalAyahs,
          label: 'End',
          icon: Icons.last_page,
          color: const Color(0xFFEF4444),
        ),
      );
    }

    return suggestions;
  }

  /// Generate milestone numbers yang mudah dibaca
  static List<int> _generateMilestones(int totalAyahs) {
    final milestones = <int>[];

    if (totalAyahs <= 10) return milestones;

    // Untuk surah pendek (10-50 ayat): kelipatan 10
    if (totalAyahs <= 50) {
      for (int i = 10; i < totalAyahs; i += 10) {
        milestones.add(i);
      }
    }
    // Untuk surah sedang (51-100 ayat): kelipatan 20
    else if (totalAyahs <= 100) {
      for (int i = 20; i < totalAyahs; i += 20) {
        milestones.add(i);
      }
    }
    // Untuk surah panjang (>100 ayat): kelipatan 50
    else {
      for (int i = 50; i < totalAyahs; i += 50) {
        milestones.add(i);
      }
    }

    return milestones;
  }

  /// Tentukan warna milestone berdasarkan posisi
  static Color _getMilestoneColor(int milestone, int totalAyahs) {
    final percentage = milestone / totalAyahs;

    if (percentage < 0.33) return const Color(0xFF8B5CF6);
    if (percentage < 0.66) return const Color(0xFFF59E0B);
    return const Color(0xFFEC4899);
  }
}

/// Model untuk smart jump suggestion
class SmartJumpSuggestion {
  final int ayah;
  final String label;
  final IconData icon;
  final Color color;

  SmartJumpSuggestion({
    required this.ayah,
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ============================================================================
// DIALOG COMPONENT
// ============================================================================

class JumpAyahDialog extends StatefulWidget {
  final int currentAyah;
  final int totalAyahs;
  final int surahNumber;
  final String surahName;
  final Function(int) onJump;
  final bool isDarkMode;

  const JumpAyahDialog({
    super.key,
    required this.currentAyah,
    required this.totalAyahs,
    required this.surahNumber,
    required this.surahName,
    required this.onJump,
    this.isDarkMode = false,
  });

  @override
  State<JumpAyahDialog> createState() => _JumpAyahDialogState();
}

class _JumpAyahDialogState extends State<JumpAyahDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  List<int> _recentJumps = [];
  List<SmartJumpSuggestion> _smartSuggestions = [];
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _loadData();
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _loadData() {
    _loadRecentJumps();
    _smartSuggestions = JumpAyahHelper.getSmartSuggestions(
      widget.currentAyah,
      widget.totalAyahs,
    );
  }

  Future<void> _loadRecentJumps() async {
    final jumps = await JumpAyahHelper.getRecentJumps(widget.surahNumber);
    if (mounted) {
      setState(() => _recentJumps = jumps);
    }
  }

  void _validateAndJump(int targetAyah) {
    if (_isLoading) return;

    if (targetAyah < 1 || targetAyah > widget.totalAyahs) {
      setState(() => _errorMessage = 'Valid range: 1-${widget.totalAyahs}');
      HapticFeedback.heavyImpact();
      return;
    }

    if (targetAyah == widget.currentAyah) {
      setState(() => _errorMessage = 'Already at ayah $targetAyah');
      HapticFeedback.lightImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    JumpAyahHelper.saveRecentJump(widget.surahNumber, targetAyah);
    Navigator.of(context).pop();
    widget.onJump(targetAyah);
  }

  // Theme colors
  Color get _primaryColor =>
      widget.isDarkMode ? const Color(0xFF10B981) : const Color(0xFF059669);

  Color get _gradientStart =>
      widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA);

  Color get _gradientEnd =>
      widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);

  Color get _surfaceColor => widget.isDarkMode
      ? const Color(0xFF1E293B).withValues(alpha: 0.6)
      : Colors.white.withValues(alpha: 0.6);

  Color get _textColor =>
      widget.isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  Color get _mutedColor =>
      widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final screenHeight = MediaQuery.of(context).size.height;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 420 : 360,
              maxHeight: screenHeight * 0.85,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_gradientStart, _gradientEnd],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 
                    widget.isDarkMode ? 0.5 : 0.1,
                  ),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.1),
                  blurRadius: 60,
                  offset: const Offset(0, 30),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isTablet),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildBody(isTablet),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 24 : 20,
        isTablet ? 24 : 20,
        isTablet ? 20 : 16,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: isTablet ? 24 : 22,
            ),
          ),

          SizedBox(width: isTablet ? 16 : 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Jump',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.surahName,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    color: _mutedColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: _mutedColor,
                  size: isTablet ? 22 : 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isTablet) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        0,
        isTablet ? 24 : 20,
        isTablet ? 24 : 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentPosition(isTablet),
          SizedBox(height: isTablet ? 20 : 18),
          _buildInput(isTablet),
          if (_smartSuggestions.isNotEmpty) ...[
            SizedBox(height: isTablet ? 20 : 18),
            _buildSmartSuggestions(isTablet),
          ],
          // if (_recentJumps.isNotEmpty) ...[
          //   SizedBox(height: isTablet ? 20 : 18),
          //   _buildRecentJumps(isTablet),
          // ],
        ],
      ),
    );
  }

  Widget _buildCurrentPosition(bool isTablet) {
    final percentage = ((widget.currentAyah / widget.totalAyahs) * 100).toInt();

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: isTablet ? 44 : 40,
            height: isTablet ? 44 : 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: widget.currentAyah / widget.totalAyahs,
                  backgroundColor: _mutedColor.withValues(alpha: 0.1),
                  color: _primaryColor,
                  strokeWidth: 3,
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: isTablet ? 14 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Position',
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 10,
                    color: _mutedColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ayah ${widget.currentAyah} of ${widget.totalAyahs}',
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(bool isTablet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
            border: Border.all(
              color: _errorMessage != null
                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                  : _primaryColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w600,
              color: _textColor,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '•••',
              hintStyle: TextStyle(
                color: _mutedColor.withValues(alpha: 0.3),
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: isTablet ? 18 : 16,
              ),
            ),
            onChanged: (value) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _validateAndJump(int.parse(value));
              }
            },
          ),
        ),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: isTablet ? 12 : 11,
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        SizedBox(height: isTablet ? 12 : 10),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    final text = _controller.text.trim();
                    if (text.isEmpty) {
                      setState(() => _errorMessage = 'Enter ayah number');
                      HapticFeedback.heavyImpact();
                    } else {
                      _validateAndJump(int.parse(text));
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLoading ? _mutedColor : _primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.navigation, size: isTablet ? 20 : 18),
                const SizedBox(width: 8),
                Text(
                  _isLoading ? 'Jumping...' : 'Jump',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartSuggestions(bool isTablet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb,
              size: isTablet ? 16 : 14,
              color: _primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              'QUICK JUMP',
              style: TextStyle(
                fontSize: isTablet ? 11 : 10,
                fontWeight: FontWeight.w700,
                color: _mutedColor,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 10),
        Wrap(
          spacing: isTablet ? 8 : 6,
          runSpacing: isTablet ? 8 : 6,
          children: _smartSuggestions.map((suggestion) {
            return _buildSmartChip(suggestion, isTablet);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSmartChip(SmartJumpSuggestion suggestion, bool isTablet) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _validateAndJump(suggestion.ayah),
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14 : 12,
            vertical: isTablet ? 10 : 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                suggestion.color.withValues(alpha: 0.15),
                suggestion.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
            border: Border.all(
              color: suggestion.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                suggestion.icon,
                size: isTablet ? 18 : 16,
                color: suggestion.color,
              ),
              SizedBox(width: isTablet ? 6 : 5),
              Text(
                suggestion.label == 'Beginning' || suggestion.label == 'End'
                    ? '${suggestion.label} · ${suggestion.ayah}'
                    : '${suggestion.ayah}',
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildRecentJumps(bool isTablet) {
  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(
  //             Icons.history,
  //             size: isTablet ? 16 : 14,
  //             color: _mutedColor,
  //           ),
  //           const SizedBox(width: 6),
  //           Text(
  //             'RECENT',
  //             style: TextStyle(
  //               fontSize: isTablet ? 11 : 10,
  //               fontWeight: FontWeight.w700,
  //               color: _mutedColor,
  //               letterSpacing: 0.8,
  //             ),
  //           ),
  //         ],
  //       ),
  //       SizedBox(height: isTablet ? 12 : 10),
  //       Wrap(
  //         spacing: isTablet ? 8 : 6,
  //         runSpacing: isTablet ? 8 : 6,
  //         children: _recentJumps.map((ayah) {
  //           return Material(
  //             color: Colors.transparent,
  //             child: InkWell(
  //               onTap: () => _validateAndJump(ayah),
  //               borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
  //               child: Container(
  //                 padding: EdgeInsets.symmetric(
  //                   horizontal: isTablet ? 16 : 14,
  //                   vertical: isTablet ? 10 : 8,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: _surfaceColor,
  //                   borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
  //                   border: Border.all(
  //                     color: _primaryColor.withValues(alpha: 0.15),
  //                     width: 1,
  //                   ),
  //                 ),
  //                 child: Text(
  //                   '$ayah',
  //                   style: TextStyle(
  //                     fontSize: isTablet ? 14 : 13,
  //                     fontWeight: FontWeight.w600,
  //                     color: _textColor,
  //                     letterSpacing: -0.2,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     ],
  //   );
  // }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }
}

// ============================================================================
// FAB COMPONENT
// ============================================================================

class JumpAyahFAB extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onTap;
  final bool isDarkMode;

  const JumpAyahFAB({
    super.key,
    required this.scrollController,
    required this.onTap,
    this.isDarkMode = false,
  });

  @override
  State<JumpAyahFAB> createState() => _JumpAyahFABState();
}

class _JumpAyahFABState extends State<JumpAyahFAB>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  double _lastScrollPosition = 0;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    );

    widget.scrollController.addListener(_handleScroll);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isVisible = true);
        _scaleController.forward();
      }
    });
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients) return;

    final currentPosition = widget.scrollController.position.pixels;
    final delta = (currentPosition - _lastScrollPosition).abs();

    if (delta > 15) {
      if (_isVisible && _scaleController.isCompleted) {
        _scaleController.reverse();
        setState(() => _isVisible = false);
      }
    }

    _lastScrollPosition = currentPosition;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted &&
          widget.scrollController.hasClients &&
          widget.scrollController.position.pixels == _lastScrollPosition &&
          !_isVisible) {
        _scaleController.forward();
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final primaryColor = widget.isDarkMode
        ? const Color(0xFF10B981)
        : const Color(0xFF059669);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            customBorder: const CircleBorder(),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 16 : 14),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: isTablet ? 26 : 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    _scaleController.dispose();
    super.dispose();
  }
}
