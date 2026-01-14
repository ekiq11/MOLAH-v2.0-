// screens/dzikir_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizab_molah/dzikir/model/model_dzikir.dart';

class DzikirDetailPage extends StatefulWidget {
  final List<Dzikir> dzikirs;
  final int initialIndex;
  final String type;

  const DzikirDetailPage({
    super.key,
    required this.dzikirs,
    required this.initialIndex,
    required this.type,
  });

  @override
  State<DzikirDetailPage> createState() => _DzikirDetailPageState();
}

class _DzikirDetailPageState extends State<DzikirDetailPage> {
  late PageController _pageController;
  late int _currentIndex;
  Map<int, int> _counters = {};

  Color get _primaryColor {
    return widget.type == 'pagi' 
        ? Color(0xFF059669) // Hijau untuk pagi
        : Color(0xFF1E293B); // Abu gelap untuk sore
  }

  List<Color> get _gradientColors {
    return widget.type == 'pagi'
        ? [Color(0xFF10B981), Color(0xFF059669)] // Gradient hijau
        : [Color(0xFF334155), Color(0xFF1E293B)]; // Gradient abu gelap
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Initialize counters
    for (int i = 0; i < widget.dzikirs.length; i++) {
      _counters[i] = 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      final dzikir = widget.dzikirs[_currentIndex];
      final maxCount = int.tryParse(dzikir.repeat) ?? 1;
      
      if (_counters[_currentIndex]! < maxCount) {
        _counters[_currentIndex] = _counters[_currentIndex]! + 1;
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _resetCounter() {
    setState(() {
      _counters[_currentIndex] = 0;
    });
    HapticFeedback.lightImpact();
  }

  double _getResponsiveFontSize(double screenWidth, {required double base}) {
    if (screenWidth < 360) {
      return base * 0.9;
    } else if (screenWidth < 400) {
      return base;
    } else if (screenWidth < 600) {
      return base * 1.05;
    } else {
      return base * 1.1;
    }
  }

  double _getResponsivePadding(double screenWidth, {required double base}) {
    if (screenWidth < 360) {
      return base * 0.85;
    } else if (screenWidth < 600) {
      return base;
    } else {
      return base * 1.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = _getResponsiveFontSize(screenWidth, base: 14);
    
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          iconSize: screenWidth < 360 ? 22 : 24,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.dzikirs.length}',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.copy, color: Colors.white),
            iconSize: screenWidth < 360 ? 22 : 24,
            onPressed: _shareDzikir,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                HapticFeedback.selectionClick();
              },
              itemCount: widget.dzikirs.length,
              itemBuilder: (context, index) {
                return _buildDzikirContent(
                  widget.dzikirs[index],
                  screenWidth,
                );
              },
            ),
          ),
          _buildNavigationBar(screenWidth),
        ],
      ),
    );
  }

  Widget _buildDzikirContent(Dzikir dzikir, double screenWidth) {
    final maxCount = int.tryParse(dzikir.repeat) ?? 1;
    final currentCount = _counters[_currentIndex] ?? 0;
    final isCompleted = currentCount >= maxCount;

    final horizontalPadding = _getResponsivePadding(screenWidth, base: 16);
    final cardPadding = _getResponsivePadding(screenWidth, base: 20);
    final arabicFontSize = _getResponsiveFontSize(screenWidth, base: 28);
    final titleFontSize = _getResponsiveFontSize(screenWidth, base: 16);
    final bodyFontSize = _getResponsiveFontSize(screenWidth, base: 12);
    final labelFontSize = _getResponsiveFontSize(screenWidth, base: 9);
    final infoFontSize = _getResponsiveFontSize(screenWidth, base: 11);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'DZIKIR ${_currentIndex + 1}',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  dzikir.nama,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Arabic Text (Lafal)
          if (dzikir.lafal.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: screenWidth < 360 ? 24 : 32,
              horizontal: cardPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              dzikir.lafal,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: arabicFontSize,
                height: screenWidth < 360 ? 2.2 : 2.4,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111827),
                fontFamily: 'Utsmani',
                letterSpacing: 0,
              ),
            ),
          ),

          if (dzikir.lafal.isNotEmpty)
          SizedBox(height: 16),

          // Counter Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Hitungan',
                  style: TextStyle(
                    fontSize: bodyFontSize + 2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '$currentCount / $maxCount',
                  style: TextStyle(
                    fontSize: screenWidth < 360 ? 44 : 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                
                // Progress Bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: maxCount > 0 ? currentCount / maxCount : 0,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetCounter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth < 360 ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: screenWidth < 360 ? 18 : 20),
                            SizedBox(width: 8),
                            Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: bodyFontSize + 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isCompleted ? null : _incrementCounter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _primaryColor,
                          disabledBackgroundColor: Colors.white.withOpacity(0.5),
                          disabledForegroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth < 360 ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.add_circle,
                              size: screenWidth < 360 ? 18 : 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              isCompleted ? 'Selesai' : 'Hitung',
                              style: TextStyle(
                                fontSize: bodyFontSize + 2,
                                fontWeight: FontWeight.w600,
                              ),
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

          SizedBox(height: 16),

          // Content Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transliterasi
                if (dzikir.transliterasi.isNotEmpty) ...[
                  _buildTextSection(
                    label: 'TRANSLITERASI',
                    content: dzikir.transliterasi,
                    isItalic: true,
                    labelSize: labelFontSize,
                    contentSize: bodyFontSize,
                  ),
                  SizedBox(height: screenWidth < 360 ? 20 : 24),
                ],

                // Arti
                _buildTextSection(
                  label: 'ARTINYA',
                  content: dzikir.arti,
                  labelSize: labelFontSize,
                  contentSize: bodyFontSize,
                ),

                SizedBox(height: screenWidth < 360 ? 20 : 24),

                // Divider
                Container(
                  height: 1,
                  color: Color(0xFFF3F4F6),
                ),

                SizedBox(height: screenWidth < 360 ? 16 : 20),

                // Keterangan
                _buildInfoRow(
                  label: 'Keterangan',
                  value: dzikir.keterangan,
                  icon: Icons.info_outline,
                  fontSize: infoFontSize,
                ),

                SizedBox(height: 16),

                // Riwayat
                _buildInfoRow(
                  label: 'Riwayat',
                  value: dzikir.riwayat,
                  icon: Icons.book_outlined,
                  fontSize: infoFontSize,
                ),

                // Footnote
                if (dzikir.footnote != null && dzikir.footnote!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildInfoRow(
                    label: 'Catatan',
                    value: dzikir.footnote!,
                    icon: Icons.notes,
                    fontSize: infoFontSize,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTextSection({
    required String label,
    required String content,
    required double labelSize,
    required double contentSize,
    bool isItalic = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 10),
        Text(
          content,
          style: TextStyle(
            fontSize: contentSize,
            height: 1.8,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w400,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required double fontSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: fontSize + 3,
          color: _primaryColor,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize - 2,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(double screenWidth) {
    final indicatorFontSize = _getResponsiveFontSize(screenWidth, base: 14);
    final horizontalPadding = _getResponsivePadding(screenWidth, base: 16);
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous Button
            _buildNavIconButton(
              icon: Icons.chevron_left,
              isEnabled: _currentIndex > 0,
              onPressed: _currentIndex > 0
                  ? () {
                      HapticFeedback.lightImpact();
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
            ),

            SizedBox(width: 12),

            // Page Indicator
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor.withOpacity(0.08),
                      _primaryColor.withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_currentIndex + 1} / ${widget.dzikirs.length}',
                    style: TextStyle(
                      fontSize: indicatorFontSize,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Next Button
            _buildNavIconButton(
              icon: Icons.chevron_right,
              isEnabled: _currentIndex < widget.dzikirs.length - 1,
              onPressed: _currentIndex < widget.dzikirs.length - 1
                  ? () {
                      HapticFeedback.lightImpact();
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIconButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isEnabled ? _primaryColor : Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon),
        color: isEnabled ? Colors.white : Color(0xFF9CA3AF),
        iconSize: 24,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _shareDzikir() {
    final dzikir = widget.dzikirs[_currentIndex];
    final text = '''
${dzikir.nama}

${dzikir.lafal}

${dzikir.transliterasi}

Artinya: ${dzikir.arti}

${dzikir.keterangan}
Riwayat: ${dzikir.riwayat}
${dzikir.footnote != null && dzikir.footnote!.isNotEmpty ? '\n\nCatatan: ${dzikir.footnote}' : ''}
''';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Dzikir berhasil disalin ke clipboard'),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }
}