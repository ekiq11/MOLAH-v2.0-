// screens/doa_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizab_molah/doa/model/model_doa_sehari.dart';
import 'package:pizab_molah/doa/screens/share_doa.dart';

class DoaDetailPage extends StatefulWidget {
  final List<Doa> doas;
  final int initialIndex;

  const DoaDetailPage({
    super.key,
    required this.doas,
    required this.initialIndex,
  });

  @override
  State<DoaDetailPage> createState() => _DoaDetailPageState();
}

class _DoaDetailPageState extends State<DoaDetailPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = _getResponsiveFontSize(screenWidth, base: 14);

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF059669),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.doas.length}',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          // ✅ TOMBOL SHARE
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              _openSharePage();
            },
          ),
          // ✅ TOMBOL COPY
          IconButton(
            icon: Icon(Icons.copy, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              _copyDoa();
            },
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
              itemCount: widget.doas.length,
              itemBuilder: (context, index) {
                return _buildDoaContent(widget.doas[index], screenWidth);
              },
            ),
          ),
          _buildNavigationBar(screenWidth),
        ],
      ),
    );
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

  Widget _buildDoaContent(Doa doa, double screenWidth) {
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
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'DOA ${doa.idDoa}',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  doa.nama,
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
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              doa.lafal,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Arabic',
                fontSize: arabicFontSize,

                height: 1.85, // ✅ Line height lebih lega untuk readability
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,

                letterSpacing: 0,
                fontFeatures: [
                  FontFeature.enable('kern'),
                  FontFeature.enable('liga'),
                ],
              ),
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
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transliterasi
                _buildTextSection(
                  label: 'TRANSLITERASI',
                  content: doa.transliterasi,
                  isItalic: true,
                  labelSize: labelFontSize,
                  contentSize: bodyFontSize,
                ),

                SizedBox(height: screenWidth < 360 ? 20 : 24),

                // Arti
                _buildTextSection(
                  label: 'ARTINYA',
                  content: doa.arti,
                  labelSize: labelFontSize,
                  contentSize: bodyFontSize,
                ),

                SizedBox(height: screenWidth < 360 ? 20 : 24),

                // Divider
                Container(height: 1, color: Color(0xFFF3F4F6)),

                SizedBox(height: screenWidth < 360 ? 16 : 20),

                // Riwayat
                _buildInfoRow(
                  label: 'Riwayat',
                  value: doa.riwayat,
                  icon: Icons.book_outlined,
                  fontSize: infoFontSize,
                ),

                // Keterangan
                if (doa.keterangan != null && doa.keterangan!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildInfoRow(
                    label: 'Keterangan',
                    value: doa.keterangan!,
                    icon: Icons.info_outline,
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
            color: Color(0xFF059669),
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
        Icon(icon, size: fontSize + 3, color: Color(0xFF059669)),
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
    final buttonFontSize = _getResponsiveFontSize(screenWidth, base: 13);
    final indicatorFontSize = _getResponsiveFontSize(screenWidth, base: 14);
    final buttonPadding = screenWidth < 360 ? 12.0 : 14.0;
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous Button - Icon Only
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

            // Page Indicator - Expanded
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF059669).withValues(alpha: 0.08),
                      Color(0xFF059669).withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF059669).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_currentIndex + 1} / ${widget.doas.length}',
                    style: TextStyle(
                      fontSize: indicatorFontSize,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Next Button - Icon Only
            _buildNavIconButton(
              icon: Icons.chevron_right,
              isEnabled: _currentIndex < widget.doas.length - 1,
              onPressed: _currentIndex < widget.doas.length - 1
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
        color: isEnabled ? Color(0xFF059669) : Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: Color(0xFF059669).withValues(alpha: 0.3),
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

  // ✅ FUNGSI UNTUK MEMBUKA HALAMAN SHARE
  void _openSharePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DoaShareFullScreenPage(doa: widget.doas[_currentIndex]),
      ),
    );
  }

  // ✅ FUNGSI COPY DOA (RENAME dari _shareDoa)
  void _copyDoa() {
    final doa = widget.doas[_currentIndex];
    final text =
        '''
${doa.nama}

${doa.lafal}

${doa.transliterasi}

Artinya: ${doa.arti}

Riwayat: ${doa.riwayat}
${doa.keterangan != null && doa.keterangan!.isNotEmpty ? '\n\nKeterangan: ${doa.keterangan}' : ''}
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('Doa berhasil disalin ke clipboard')),
          ],
        ),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
