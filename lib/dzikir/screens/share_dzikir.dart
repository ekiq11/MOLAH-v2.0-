// ✅ DZIKIR FULL SCREEN SHARE PAGE - With Warning & Display Options
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pizab_molah/dzikir/model/model_dzikir.dart';
import 'package:share_plus/share_plus.dart';

class DzikirShareFullScreenPage extends StatefulWidget {
  final Dzikir dzikir;
  final String type; // 'pagi' atau 'petang'

  const DzikirShareFullScreenPage({
    super.key,
    required this.dzikir,
    required this.type,
  });

  @override
  State<DzikirShareFullScreenPage> createState() =>
      _DzikirShareFullScreenPageState();
}

class _DzikirShareFullScreenPageState extends State<DzikirShareFullScreenPage> {
  int _selectedDesign = 0;
  int _displayMode =
      0; // 0: Semua, 1: Arab+Transliterasi, 2: Arab+Arti, 3: Arab saja
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;
  bool _showWarning = false;

  final List<ShareDesignTheme> _designs = [
    ShareDesignTheme(
      name: 'Emerald Gradient',
      primaryGradient: [
        Color(0xFF059669),
        Color(0xFF047857),
        Color(0xFF065F46),
      ],
      secondaryGradient: [Color(0xFF10B981), Color(0xFF059669)],
      accentColor: Color(0xFFFBBF24),
      textColor: Colors.white,
    ),
    ShareDesignTheme(
      name: 'Royal Purple',
      primaryGradient: [
        Color(0xFF7C3AED),
        Color(0xFF6D28D9),
        Color(0xFF5B21B6),
      ],
      secondaryGradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      accentColor: Color(0xFFFBBF24),
      textColor: Colors.white,
    ),
    ShareDesignTheme(
      name: 'Ocean Blue',
      primaryGradient: [
        Color(0xFF0EA5E9),
        Color(0xFF0284C7),
        Color(0xFF0369A1),
      ],
      secondaryGradient: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
      accentColor: Color(0xFFFDE047),
      textColor: Colors.white,
    ),
    ShareDesignTheme(
      name: 'Sunset Orange',
      primaryGradient: [
        Color(0xFFF59E0B),
        Color(0xFFD97706),
        Color(0xFFB45309),
      ],
      secondaryGradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      accentColor: Color(0xFFFEF3C7),
      textColor: Colors.white,
    ),
    ShareDesignTheme(
      name: 'Dark Elegance',
      primaryGradient: [
        Color(0xFF1F2937),
        Color(0xFF111827),
        Color(0xFF030712),
      ],
      secondaryGradient: [Color(0xFF374151), Color(0xFF1F2937)],
      accentColor: Color(0xFF10B981),
      textColor: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkContentLength();
    // Auto select design based on dzikir type
    if (widget.type == 'petang') {
      _selectedDesign = 4; // Dark Elegance for petang
    }
  }

  // ✅ Deteksi dzikir panjang
  void _checkContentLength() {
    final totalLength =
        widget.dzikir.lafal.length +
        widget.dzikir.transliterasi.length +
        widget.dzikir.arti.length;

    setState(() {
      _showWarning = totalLength > 400;
    });
  }

  Future<void> _shareAsImage() async {
    if (!mounted) return;
    setState(() => _isSharing = true);

    try {
      await Future.delayed(Duration(milliseconds: 500));

      if (!mounted) return;

      final RenderObject? renderObject = _repaintKey.currentContext
          ?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        if (mounted) setState(() => _isSharing = false);
        throw Exception('Render boundary tidak ditemukan');
      }

      final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        if (mounted) setState(() => _isSharing = false);
        throw Exception('Gagal convert gambar');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath =
          '${directory.path}/dzikir_${widget.type}_$timestamp.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(imagePath)],
        text:
            '${widget.dzikir.nama}\nDzikir ${widget.type == 'pagi' ? 'Pagi' : 'Petang'}\n\nDibagikan dari Bekal Muslim',
      );

      if (mounted) {
        setState(() => _isSharing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Dzikir berhasil dibagikan!'),
              ],
            ),
            backgroundColor: widget.type == 'pagi'
                ? Color(0xFF059669)
                : Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }

      Future.delayed(Duration(seconds: 10), () {
        if (imageFile.existsSync()) imageFile.delete();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSharing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Gagal membagikan dzikir: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ MAIN CONTENT - Full Screen Preview
          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: DzikirShareStoryCard(
                dzikir: widget.dzikir,
                type: widget.type,
                theme: _designs[_selectedDesign],
                displayMode: _displayMode,
              ),
            ),
          ),

          // ✅ TOP BAR - Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Bagikan Dzikir',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _showWarning
                                    ? 'Pilih mode tampilan'
                                    : 'Pilih desain di bawah',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 48),
                      ],
                    ),

                    // ⚠️ WARNING BANNER
                    if (_showWarning) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFFFBBF24),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Dzikir panjang terdeteksi. Pilih mode tampilan:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      // 🎨 DISPLAY MODE SELECTOR
                      _buildDisplayModeSelector(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ✅ BOTTOM BAR - Design Selector & Share Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _designs.length,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        itemBuilder: (context, index) {
                          final isSelected = _selectedDesign == index;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedDesign = index);
                            },
                            child: Container(
                              width: 70,
                              margin: EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _designs[index].primaryGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 32,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isSharing ? null : _shareAsImage,
                        icon: _isSharing
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Icon(Icons.share_rounded, size: 24),
                        label: Text(
                          _isSharing ? 'Membagikan...' : 'Bagikan Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _designs[_selectedDesign].primaryGradient[0],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: _designs[_selectedDesign]
                              .primaryGradient[0]
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DISPLAY MODE SELECTOR
  Widget _buildDisplayModeSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          _buildDisplayModeButton(0, 'Semua', Icons.view_agenda_rounded),
          _buildDisplayModeButton(1, 'Arab+Latin', Icons.text_fields_rounded),
          _buildDisplayModeButton(2, 'Arab+Arti', Icons.translate_rounded),
          _buildDisplayModeButton(3, 'Arab', Icons.text_format_rounded),
        ],
      ),
    );
  }

  Widget _buildDisplayModeButton(int mode, String label, IconData icon) {
    final isSelected = _displayMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _displayMode = mode);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? _designs[_selectedDesign].primaryGradient[0]
                    : Colors.white70,
              ),
              SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? _designs[_selectedDesign].primaryGradient[0]
                      : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ DZIKIR STORY CARD - WITH DISPLAY MODE SUPPORT
class DzikirShareStoryCard extends StatelessWidget {
  final Dzikir dzikir;
  final String type;
  final ShareDesignTheme theme;
  final int
  displayMode; // 0: Semua, 1: Arab+Transliterasi, 2: Arab+Arti, 3: Arab saja

  const DzikirShareStoryCard({
    super.key,
    required this.dzikir,
    required this.type,
    required this.theme,
    this.displayMode = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 640,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // ✅ Minimal Decorative Elements
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ✅ MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 28),

                  // ✅ FLEXIBLE CONTENT
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ✅ ARAB TEXT (Semua mode)
                          if (dzikir.lafal.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                dzikir.lafal,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Arabic',
                                  fontSize: displayMode == 3
                                      ? 26
                                      : 22, // Lebih besar jika solo
                                  height: 1.9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Separator
                          if (displayMode != 3 && dzikir.lafal.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Container(
                                height: 2,
                                width: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.6),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                          // ✅ TRANSLITERASI (Mode 0 atau 1)
                          if ((displayMode == 0 || displayMode == 1) &&
                              dzikir.transliterasi.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                dzikir.transliterasi,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: displayMode == 1 ? 14 : 13,
                                  height: 1.7,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Separator antara transliterasi dan arti
                          if (displayMode == 0 &&
                              dzikir.transliterasi.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Container(
                                height: 1.5,
                                width: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.4),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                          // ✅ ARTI (Mode 0 atau 2)
                          if (displayMode == 0 || displayMode == 2)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                children: [
                                  if (displayMode == 0 || displayMode == 2)
                                    Text(
                                      'Artinya:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.accentColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  SizedBox(height: 8),
                                  Text(
                                    dzikir.arti,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: displayMode == 2 ? 14 : 13,
                                      height: 1.7,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          offset: Offset(0, 1),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              type == 'pagi' ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: theme.primaryGradient[2],
              size: 24,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dzikir.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Dzikir ${type == 'pagi' ? 'Pagi' : 'Petang'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // ✅ ELEGANT FOOTER - Centered & Balanced
        Column(
          children: [
            // ✅ App Branding
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/other/icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bekal Muslim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.4,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Dzikir & Doa Harian',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // ✅ Download CTA - Centered
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: theme.accentColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.download_rounded,
                    color: theme.primaryGradient[2],
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Download Gratis',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryGradient[2],
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        // ✅ Decorative Line
        Container(
          width: 100,
          height: 2.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.0),
                theme.accentColor.withValues(alpha: 0.7),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class ShareDesignTheme {
  final String name;
  final List<Color> primaryGradient;
  final List<Color> secondaryGradient;
  final Color accentColor;
  final Color textColor;

  ShareDesignTheme({
    required this.name,
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.accentColor,
    required this.textColor,
  });
}
