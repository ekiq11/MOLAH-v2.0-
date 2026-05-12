// ✅ DOA SHARE - Simple, Minimal, Elegant (Polished Version)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pizab_molah/doa/model/model_doa_sehari.dart';
import 'package:share_plus/share_plus.dart';

class DoaShareFullScreenPage extends StatefulWidget {
  final Doa doa;

  const DoaShareFullScreenPage({super.key, required this.doa});

  @override
  State<DoaShareFullScreenPage> createState() => _DoaShareFullScreenPageState();
}

class _DoaShareFullScreenPageState extends State<DoaShareFullScreenPage> {
  int _selectedDesign = 0;
  int _displayMode = 0;
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;
  bool _showWarning = false;

  final List<SimpleShareTheme> _designs = [
    SimpleShareTheme(
      name: 'Emerald',
      primaryColor: Color(0xFF059669),
      secondaryColor: Color(0xFF10B981),
      accentColor: Color(0xFFFBBF24),
    ),
    SimpleShareTheme(
      name: 'Purple',
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFF8B5CF6),
      accentColor: Color(0xFFFBBF24),
    ),
    SimpleShareTheme(
      name: 'Blue',
      primaryColor: Color(0xFF0EA5E9),
      secondaryColor: Color(0xFF06B6D4),
      accentColor: Color(0xFFFDE047),
    ),
    SimpleShareTheme(
      name: 'Orange',
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFFBBF24),
      accentColor: Color(0xFFDC2626),
    ),
    SimpleShareTheme(
      name: 'Dark',
      primaryColor: Color(0xFF1E293B),
      secondaryColor: Color(0xFF334155),
      accentColor: Color(0xFF10B981),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkContentLength();
  }

  void _checkContentLength() {
    final totalLength =
        widget.doa.lafal.length +
        widget.doa.transliterasi.length +
        widget.doa.arti.length;

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
          '${directory.path}/doa_${widget.doa.idDoa}_$timestamp.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      if (!mounted) return;

      await Share.shareXFiles([
        XFile(imagePath),
      ], text: '${widget.doa.nama}\n\nDibagikan dari Bekal Muslim');

      if (mounted) {
        setState(() => _isSharing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Doa berhasil dibagikan!'),
              ],
            ),
            backgroundColor: Color(0xFF059669),
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
                Expanded(child: Text('Gagal membagikan doa: ${e.toString()}')),
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
          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: SimpleDoaCard(
                doa: widget.doa,
                theme: _designs[_selectedDesign],
                displayMode: _displayMode,
              ),
            ),
          ),

          // TOP BAR
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
                            children: [
                              Text(
                                'Bagikan Doa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _showWarning
                                    ? 'Pilih mode tampilan'
                                    : 'Pilih tema di bawah',
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
                                'Doa panjang terdeteksi. Pilih mode tampilan:',
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
                      _buildDisplayModeSelector(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // BOTTOM BAR
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
                          final theme = _designs[index];
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
                                  colors: [
                                    theme.primaryColor,
                                    theme.secondaryColor,
                                  ],
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
                              _designs[_selectedDesign].primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: _designs[_selectedDesign].primaryColor
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
                    ? _designs[_selectedDesign].primaryColor
                    : Colors.white70,
              ),
              SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? _designs[_selectedDesign].primaryColor
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

// ✅ SIMPLE DOA CARD - Clean & Elegant
class SimpleDoaCard extends StatelessWidget {
  final Doa doa;
  final SimpleShareTheme theme;
  final int displayMode;

  const SimpleDoaCard({
    super.key,
    required this.doa,
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
          colors: [theme.primaryColor, theme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Simple decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // ARAB TEXT
                          Text(
                            doa.lafal,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Arabic',
                              fontSize: displayMode == 3 ? 28 : 25,
                              height: 2.0,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),

                          // ISLAMIC DIVIDER
                          if (displayMode != 3) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: theme.accentColor.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    width: 60,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: theme.accentColor.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: theme.accentColor,
                                  ),
                                  SizedBox(width: 6),
                                  Container(
                                    width: 60,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: theme.accentColor.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: theme.accentColor.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // TRANSLITERASI
                          if ((displayMode == 0 || displayMode == 1) &&
                              doa.transliterasi.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                doa.transliterasi,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: displayMode == 1 ? 15 : 14,
                                  height: 1.8,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      offset: Offset(0, 1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (displayMode == 0 &&
                              doa.transliterasi.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: theme.accentColor.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Container(
                                  width: 30,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    color: theme.accentColor.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.circle,
                                  size: 4,
                                  color: theme.accentColor,
                                ),
                                SizedBox(width: 4),
                                Container(
                                  width: 30,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    color: theme.accentColor.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: theme.accentColor.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],

                          // ARTI
                          if (displayMode == 0 || displayMode == 2)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: [
                                  Text(
                                    'ARTINYA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: theme.accentColor,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    doa.arti,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: displayMode == 2 ? 15 : 14,
                                      height: 1.8,
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          offset: Offset(0, 1),
                                          blurRadius: 4,
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
    return Column(
      children: [
        // ICON & DOA NUMBER - Centered
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                color: theme.accentColor,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Doa ${doa.idDoa}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // TITLE - Centered
        Text(
          doa.nama,
          textAlign: TextAlign.center,
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
        SizedBox(height: 16),
        // ISLAMIC DIVIDER
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.white.withValues(alpha: 0.4)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.circle, size: 6, color: theme.accentColor),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.4), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // RIWAYAT (jika ada)
        if (doa.riwayat.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.book_outlined, size: 16, color: theme.accentColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doa.riwayat,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
        ],

        // APP BRANDING
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
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
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/other/icon.png', fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bekal Muslim',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Al-Qur\'an & Doa Harian',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DOWNLOAD GRATIS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SimpleShareTheme {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  SimpleShareTheme({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });
}
