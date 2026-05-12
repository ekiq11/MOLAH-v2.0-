// screens/tafsir_detail_page.dart - ORIGINAL DESIGN (Tidak diubah)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class TafsirDetailPage extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String ayahText;
  final String translation;
  final String tafsir;

  const TafsirDetailPage({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahText,
    required this.translation,
    required this.tafsir,
  });

  @override
  State<TafsirDetailPage> createState() => _TafsirDetailPageState();
}

class _TafsirDetailPageState extends State<TafsirDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _isLoadingTafsir = true;
  String _tafsirText = '';
  String _errorMessage = '';
  TafsirLoadStatus _tafsirStatus = TafsirLoadStatus.loading;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTafsir();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 200 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  Future<void> _loadTafsir() async {
    setState(() {
      _isLoadingTafsir = true;
      _errorMessage = '';
      _tafsirStatus = TafsirLoadStatus.loading;
    });

    try {
      // API equran.id - Tafsir Kemenag
      final url = 'https://equran.id/api/v2/tafsir/${widget.surahNumber}';

      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cek apakah response sukses
        if (data['code'] == 200 && data['data'] != null) {
          final tafsirList = data['data']['tafsir'] as List?;

          if (tafsirList != null && tafsirList.isNotEmpty) {
            // Cari tafsir untuk ayat yang spesifik
            final ayahTafsir = tafsirList.firstWhere(
              (item) => item['ayat'] == widget.ayahNumber,
              orElse: () => null,
            );

            if (ayahTafsir != null && ayahTafsir['teks'] != null) {
              setState(() {
                _tafsirText = _cleanHtmlTags(ayahTafsir['teks']);
                _tafsirStatus = TafsirLoadStatus.success;
                _isLoadingTafsir = false;
              });
            } else {
              setState(() {
                _tafsirText = 'Tafsir tidak tersedia untuk ayat ini.';
                _tafsirStatus = TafsirLoadStatus.success;
                _isLoadingTafsir = false;
              });
            }
          } else {
            setState(() {
              _errorMessage = 'Data tafsir tidak ditemukan';
              _tafsirStatus = TafsirLoadStatus.error;
              _isLoadingTafsir = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Format respons tidak valid';
            _tafsirStatus = TafsirLoadStatus.error;
            _isLoadingTafsir = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server tidak merespons (${response.statusCode})';
          _tafsirStatus = TafsirLoadStatus.error;
          _isLoadingTafsir = false;
        });
      }
    } on SocketException {
      setState(() {
        _errorMessage = 'Tidak ada koneksi internet';
        _tafsirStatus = TafsirLoadStatus.offline;
        _isLoadingTafsir = false;
      });
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Waktu permintaan habis. Koneksi terlalu lambat';
        _tafsirStatus = TafsirLoadStatus.timeout;
        _isLoadingTafsir = false;
      });
    } on FormatException {
      setState(() {
        _errorMessage = 'Format data tidak valid';
        _tafsirStatus = TafsirLoadStatus.error;
        _isLoadingTafsir = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat tafsir: ${e.toString()}';
        _tafsirStatus = TafsirLoadStatus.error;
        _isLoadingTafsir = false;
      });
    }
  }

  String _cleanHtmlTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final screenFactor = width / 375;

    final arabicSize = (24.0 * screenFactor).clamp(20.0, 34.0);
    final titleSize = (14.0 * screenFactor).clamp(14.0, 20.0);
    final subtitleSize = (12.0 * screenFactor).clamp(10.0, 14.0);
    final bodySize = (12.0 * screenFactor).clamp(12.0, 17.0);
    final labelSize = (12.0 * screenFactor).clamp(11.0, 16.0);

    final horizontalPadding = (20.0 * screenFactor).clamp(16.0, 28.0);
    final verticalPadding = (24.0 * screenFactor).clamp(20.0, 36.0);
    final sectionPadding = (20.0 * screenFactor).clamp(16.0, 26.0);
    final cardSpacing = (12.0 * screenFactor).clamp(8.0, 16.0);

    final iconSize = (20.0 * screenFactor).clamp(18.0, 24.0);

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 56 + (8 * screenFactor).clamp(0, 12),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          iconSize: iconSize,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.surahName,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Ayat ${widget.ayahNumber}',
              style: TextStyle(
                fontSize: subtitleSize,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy_all_outlined, color: Color(0xFF6B7280)),
            iconSize: iconSize,
            onPressed: () {
              HapticFeedback.lightImpact();
              _shareTafsir();
            },
            tooltip: 'Bagikan',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF6B7280)),
            iconSize: iconSize,
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadTafsir();
            },
            tooltip: 'Muat Ulang',
          ),
          SizedBox(width: 4),
        ],
      ),
      body: _isLoadingTafsir
          ? _buildLoadingState()
          : SingleChildScrollView(
              controller: _scrollController,
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Arabic Text
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding * 1.2,
                      horizontal: horizontalPadding,
                    ),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${widget.ayahNumber}',
                            style: TextStyle(
                              fontSize: subtitleSize,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                        SizedBox(height: cardSpacing * 1.5),
                        Text(
                          widget.ayahText,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Utsmani',
                            fontSize: arabicSize,
                            height: 1.85,
                            letterSpacing: 0,
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 1),

                  // Translation
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(sectionPadding),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(0xFF059669),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Terjemahan',
                              style: TextStyle(
                                fontSize: labelSize,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: cardSpacing),
                        Text(
                          widget.translation,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: bodySize,
                            height: 1.75,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  // Tafsir Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(sectionPadding),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(0xFF7C3AED),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Tafsir',
                              style: TextStyle(
                                fontSize: labelSize,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: cardSpacing),

                        // Error/Status Message
                        if (_tafsirStatus != TafsirLoadStatus.success)
                          _buildStatusMessage(),

                        // Tafsir Text
                        if (_tafsirStatus == TafsirLoadStatus.success)
                          Text(
                            _tafsirText,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: bodySize,
                              height: 1.75,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.15,
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 80),
                ],
              ),
            ),

      floatingActionButton: _showScrollToTop && !_isLoadingTafsir
          ? FloatingActionButton(
              mini: true,
              onPressed: () {
                HapticFeedback.lightImpact();
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Color(0xFF059669),
              child: Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            )
          : null,
    );
  }

  Widget _buildStatusMessage() {
    IconData icon;
    Color color;
    String title;

    switch (_tafsirStatus) {
      case TafsirLoadStatus.offline:
        icon = Icons.wifi_off;
        color = Color(0xFFEF4444);
        title = 'Tidak ada koneksi internet';
        break;
      case TafsirLoadStatus.timeout:
        icon = Icons.access_time;
        color = Color(0xFFF59E0B);
        title = 'Waktu permintaan habis';
        break;
      default:
        icon = Icons.error_outline;
        color = Color(0xFFEF4444);
        title = 'Terjadi kesalahan';
    }

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: color, size: 20),
            onPressed: _loadTafsir,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Memuat tafsir...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _shareTafsir() {
    final text =
        '''
${widget.surahName} - Ayat ${widget.ayahNumber}

${widget.ayahText}

Terjemahan:
${widget.translation}

Tafsir:
${_tafsirText.isNotEmpty ? _tafsirText : 'Tafsir tidak tersedia'}

Dibagikan dari MyQuran
''';

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Tafsir berhasil disalin'),
          ],
        ),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

enum TafsirLoadStatus { loading, success, offline, timeout, error }
