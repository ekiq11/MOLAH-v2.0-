// screens/quran_list_page.dart - FIXED WITH JUZ SEARCH
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:math' as math;

import 'package:pizab_molah/quran/helper/constants.dart';
import 'package:pizab_molah/quran/model/bookmark_model.dart';
import 'package:pizab_molah/quran/model/juz_model.dart';
import 'package:pizab_molah/quran/model/surah_model.dart';
import 'package:pizab_molah/quran/screens/read_page.dart';
import 'package:pizab_molah/quran/screens/search_ayat.dart';
import 'package:pizab_molah/quran/service/quran_service.dart';
import 'package:pizab_molah/quran/widget/quran_app_bar.dart';

class QuranListPage extends StatefulWidget {
  const QuranListPage({super.key});

  @override
  State<QuranListPage> createState() => _QuranListPageState();
}

class _QuranListPageState extends State<QuranListPage> {
  final QuranService _quranService = QuranService();

  List<SurahListModel> _surahList = [];
  List<SurahListModel> _filteredList = [];

  BookmarkModel? _lastRead;
  int _bookmarkCount = 0;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // ✅ TAMBAHAN: State untuk filter info
  String _filterInfo = '';
  bool _isJuzFilter = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final surahList = await _quranService.loadSurahList();
    final lastRead = await _quranService.getLastRead();
    final bookmarks = await _quranService.getBookmarks();

    setState(() {
      _surahList = surahList.cast<SurahListModel>();
      _filteredList = surahList.cast<SurahListModel>();
      _lastRead = lastRead;
      _bookmarkCount = bookmarks.length;
      _isLoading = false;
    });
  }

  // ✅ SMART FILTER: Deteksi Juz, Surah, atau Nama
  void _filterSurah(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _surahList;
        _filterInfo = '';
        _isJuzFilter = false;
        return;
      }

      final searchLower = query.toLowerCase().trim();
      List<SurahListModel> result = [];

      // ✅ PRIORITAS 1: Deteksi "SURAT KE-XX" atau "SURAH KE-XX"
      final surahNumberMatch = _detectSurahNumberQuery(searchLower);
      if (surahNumberMatch != null) {
        result = _surahList
            .where((surah) => surah.id == surahNumberMatch)
            .toList();
        if (result.isNotEmpty) {
          _filterInfo = 'Menampilkan Surah ke-$surahNumberMatch';
          _isJuzFilter = false;
          _filteredList = result;
          return;
        }
      }

      // ✅ PRIORITAS 2: Deteksi JUZ
      final juzMatch = _detectJuzQuery(searchLower);
      if (juzMatch != null) {
        final juzSurahs = JuzData.getSurahIdsByJuz(juzMatch);
        result = _surahList
            .where((surah) => juzSurahs.contains(surah.id))
            .toList();

        _filterInfo = 'Menampilkan ${JuzData.getJuzName(juzMatch)}';
        _isJuzFilter = true;
        _filteredList = result;
        return;
      }

      // ✅ PRIORITAS 3: Pencarian nama surah
      result = _surahList.where((surah) {
        final nameLatin = surah.nameLatin.toLowerCase();
        final nameArabic = surah.name.toLowerCase();
        final number = surah.number;

        return nameLatin.contains(searchLower) ||
            nameArabic.contains(searchLower) ||
            number.contains(searchLower);
      }).toList();

      _filterInfo = '';
      _isJuzFilter = false;
      _filteredList = result;
    });
  }

  // ✅ DETEKSI: "surat ke 12", "surah ke 4", "surat 36", dll
  int? _detectSurahNumberQuery(String query) {
    // Pattern 1: "surat ke 12", "surah ke 36", "surat ke-4"
    final suratKePattern = RegExp(r'^su(?:ra[th]|rat)\s*ke[-\s]*(\d+)$');
    final match = suratKePattern.firstMatch(query);
    if (match != null) {
      final number = int.tryParse(match.group(1)!);
      if (number != null && number >= 1 && number <= 114) {
        return number;
      }
    }

    // Pattern 2: "surat 12", "surah 36" (tanpa 'ke')
    final suratPattern = RegExp(r'^su(?:ra[th]|rat)\s+(\d+)$');
    final match2 = suratPattern.firstMatch(query);
    if (match2 != null) {
      final number = int.tryParse(match2.group(1)!);
      if (number != null && number >= 1 && number <= 114) {
        return number;
      }
    }

    // Pattern 3: "ke 12", "ke-36", "ke 4" (shorthand)
    final kePattern = RegExp(r'^ke[-\s]*(\d+)$');
    final match3 = kePattern.firstMatch(query);
    if (match3 != null) {
      final number = int.tryParse(match3.group(1)!);
      if (number != null && number >= 1 && number <= 114) {
        return number;
      }
    }

    return null;
  }

  // ✅ DETEKSI JUZ: Prioritas untuk angka 1-30
  int? _detectJuzQuery(String query) {
    // Pattern 1: "juz 1", "juz 30", "juz amma"
    if (query.startsWith('juz')) {
      String juzPart = query.substring(3).trim();

      // Handle "juz amma" atau "juz ama"
      if (juzPart == 'amma' || juzPart == 'ama') {
        return 30;
      }

      // Handle "juz 1" - "juz 30"
      final juzNumber = int.tryParse(juzPart);
      if (juzNumber != null && juzNumber >= 1 && juzNumber <= 30) {
        return juzNumber;
      }
    }

    // Pattern 2: "amma" atau "ama" (standalone)
    if (query == 'amma' || query == 'ama') {
      return 30;
    }

    // Pattern 3: ✅ ANGKA MURNI 1-30 = JUZ
    final number = int.tryParse(query);
    if (number != null && number >= 1 && number <= 30) {
      return number;
    }

    return null;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isTablet),

          if (_lastRead != null || _bookmarkCount > 0)
            SliverToBoxAdapter(
              child: _buildQuickAccessCards(context, isTablet),
            ),

          SliverToBoxAdapter(child: _buildSearchBar(isTablet)),

          // ✅ TAMBAHAN: Filter info badge
          if (_filterInfo.isNotEmpty)
            SliverToBoxAdapter(child: _buildFilterInfoBadge(isTablet)),

          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_filteredList.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(isTablet))
          else
            _buildSurahList(context, isTablet),
        ],
      ),
    );
  }

  // ✅ WIDGET BARU: Filter Info Badge
  Widget _buildFilterInfoBadge(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 8 : 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 14,
                vertical: isTablet ? 12 : 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF059669).withValues(alpha: 0.1),
                    Color(0xFF047857).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Color(0xFF059669).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 8 : 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF059669),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.filter_alt_rounded,
                      color: Colors.white,
                      size: isTablet ? 18 : 16,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _filterInfo,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${_filteredList.length} surah ditemukan',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 11,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _filterSurah('');
                    },
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 6 : 5),
                      decoration: BoxDecoration(
                        color: Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFF059669),
                        size: isTablet ? 18 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET BARU: Empty State
  // ✅ WIDGET BARU: Empty State - COMPACT VERSION
  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isTablet ? 100 : 80,
              height: isTablet ? 100 : 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: isTablet ? 50 : 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              _isJuzFilter
                  ? 'Tidak ada surah di Juz ini'
                  : 'Surah tidak ditemukan',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 10 : 8),
            Text(
              'Coba kata kunci lain atau cari berdasarkan Juz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            _buildSearchSuggestions(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF59E0B),
                size: isTablet ? 18 : 16,
              ),
              SizedBox(width: 8),
              Text(
                'Tips Pencarian:',
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 10 : 8),
          _buildSuggestionItem(
            'Cari nama surah',
            'Yasin, Baqarah, Kahf',
            isTablet,
          ),
          _buildSuggestionItem(
            'Cari surah ke-X',
            'Surat ke 4, Surah 12',
            isTablet,
          ),
          _buildSuggestionItem('Cari Juz (angka 1-30)', '4, 15, 30', isTablet),
          _buildSuggestionItem(
            'Cari Juz dengan kata',
            'Juz 1, Juz Amma',
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String title, String example, bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 6 : 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4),
            width: isTablet ? 5 : 4,
            height: isTablet ? 5 : 4,
            decoration: BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isTablet ? 8 : 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  'Contoh: $example',
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 220 : 200,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchAyatPage()),
              );
            },
            icon: Icon(Icons.search_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double top = constraints.biggest.height;
          final double expandedHeight = isTablet ? 220.0 : 200.0;
          final double collapsedHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          final double scrollProgress =
              ((expandedHeight - top) / (expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);
          final double titleTop =
              MediaQuery.of(context).padding.top + (kToolbarHeight - 24) / 2;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                ),
              ),

              Positioned.fill(
                child: Opacity(
                  opacity: 0.08,
                  child: CustomPaint(painter: IslamicPatternPainter()),
                ),
              ),

              Positioned(
                right: -50,
                top: -50,
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
                left: -30,
                bottom: 30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              if (scrollProgress < 0.8)
                Positioned.fill(
                  child: Opacity(
                    opacity: (1.0 - scrollProgress).clamp(0.0, 1.0),
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildOrnamentalDivider(isTablet),
                              SizedBox(height: isTablet ? 12 : 10),
                              Image.asset(
                                'assets/other/iconquran.png',
                                width: isTablet ? 70 : 60,
                                height: isTablet ? 70 : 60,
                                color: Color(0xFFFFD700),
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: isTablet ? 10 : 8),
                              Text(
                                'Al-Qur\'an',
                                style: TextStyle(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isTablet ? 12 : 10),
                              _buildOrnamentalDivider(isTablet),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: scrollProgress,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/other/iconquran.png',
                          width: 24,
                          height: 24,
                          color: Color(0xFFFFD700),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Al-Qur\'an',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrnamentalDivider(bool isTablet) {
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

  Widget _buildQuickAccessCards(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          if (_lastRead != null) _buildLastReadCard(context, isTablet),

          if (_bookmarkCount > 0)
            Container(
              margin: EdgeInsets.only(top: isTablet ? 14 : 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF059669).withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuranBookmarksPage(),
                      ),
                    );
                    _loadData();
                  },
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLarge,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Row(
                      children: [
                        Container(
                          width: isTablet ? 64 : 56,
                          height: isTablet ? 64 : 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bookmarks_rounded,
                            color: Colors.white,
                            size: isTablet ? 32 : 28,
                          ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bookmark Saya',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$_bookmarkCount ayat tersimpan',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: isTablet ? 14 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: isTablet ? 24 : 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLastReadCard(BuildContext context, bool isTablet) {
    final isOverdue = _isMoreThanOneDayNotRead(_lastRead);

    final primaryColor = isOverdue ? Color(0xFFDC2626) : Color(0xFF059669);
    final lightBg = isOverdue ? Color(0xFFFEF2F2) : Color(0xFFF0FDF4);
    final accentColor = isOverdue ? Color(0xFFFEE2E2) : Color(0xFFD1FAE5);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue
              ? Color(0xFFFECACA).withValues(alpha: 0.6)
              : Color(0xFF6EE7B7).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.mediumImpact();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuranReadPage(
                  surahNumber: _lastRead!.surahNumber,
                  initialAyah: _lastRead!.ayahNumber,
                ),
              ),
            );
            _loadData();
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              _buildCardBackground(isOverdue, lightBg, accentColor, isTablet),

              // ✅ MAIN CONTENT
              Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        // Icon Container
                        _buildIconContainer(primaryColor, isOverdue, isTablet),

                        SizedBox(width: isTablet ? 16 : 12),

                        // Title & Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Lanjutkan Membaca',
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  if (isOverdue) ...[
                                    SizedBox(width: 8),
                                    _buildOverdueBadge(isTablet),
                                  ],
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                _getTimeAgo(_lastRead!.lastRead),
                                style: TextStyle(
                                  fontSize: isTablet ? 13 : 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Arrow Icon
                        Container(
                          width: isTablet ? 40 : 36,
                          height: isTablet ? 40 : 36,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: primaryColor,
                            size: isTablet ? 20 : 18,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isTablet ? 16 : 14),

                    // Divider
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.0),
                            primaryColor.withValues(alpha: 0.15),
                            primaryColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isTablet ? 16 : 14),

                    // Surah Info
                    Row(
                      children: [
                        // Surah Number Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 12 : 10,
                            vertical: isTablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_lastRead!.surahNumber}',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),

                        SizedBox(width: isTablet ? 12 : 10),

                        // Surah Name & Ayah
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lastRead!.surahName,
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ayat ${_lastRead!.ayahNumber}',
                                style: TextStyle(
                                  fontSize: isTablet ? 13 : 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Motivational Message (if overdue)
                    if (isOverdue) ...[
                      SizedBox(height: isTablet ? 14 : 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 14 : 12,
                          vertical: isTablet ? 10 : 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFEF3C7).withValues(alpha: 0.6),
                              Color(0xFFFDE68A).withValues(alpha: 0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Color(0xFFFBBF24).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: isTablet ? 18 : 16,
                              color: Color(0xFFD97706),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ayo lanjutkan bacaanmu hari ini! 📖',
                                style: TextStyle(
                                  fontSize: isTablet ? 13 : 12,
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ CARD BACKGROUND DECORATION
  Widget _buildCardBackground(
    bool isOverdue,
    Color lightBg,
    Color accentColor,
    bool isTablet,
  ) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    lightBg.withValues(alpha: 0.4),
                    Colors.white,
                    accentColor.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),

            // Decorative Circle Top Right
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.3),
                      accentColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Decorative Circle Bottom Left
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.2),
                      accentColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Islamic Pattern Overlay
            Positioned(
              right: 20,
              bottom: 20,
              child: Opacity(
                opacity: 0.04,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: isTablet ? 100 : 80,
                  color: isOverdue ? Color(0xFFDC2626) : Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ICON CONTAINER WITH BREATHING ANIMATION
  Widget _buildIconContainer(
    Color primaryColor,
    bool isOverdue,
    bool isTablet,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final scale = 0.95 + (math.sin(value * math.pi * 2) * 0.05);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: isTablet ? 56 : 50,
            height: isTablet ? 56 : 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3 + (value * 0.1)),
                  blurRadius: 16 + (value * 4),
                  offset: Offset(0, 6),
                  spreadRadius: value * 2,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 4,
                  offset: Offset(-2, -2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: isTablet ? 28 : 24,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // ✅ OVERDUE BADGE
  Widget _buildOverdueBadge(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 6,
        vertical: isTablet ? 4 : 3,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF59E0B).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            color: Colors.white,
            size: isTablet ? 12 : 11,
          ),
          SizedBox(width: 3),
          Text(
            'Belum dibaca',
            style: TextStyle(
              fontSize: isTablet ? 10 : 9,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ HELPER METHOD
  bool _isMoreThanOneDayNotRead(BookmarkModel? lastRead) {
    if (lastRead == null) return true;

    final now = DateTime.now();
    final lastReadTime = lastRead.lastRead;
    final difference = now.difference(lastReadTime);

    return difference.inHours >= 24;
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSurah,
        decoration: InputDecoration(
          hintText: 'Cari surah...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.primary,
            size: isTablet ? 26 : 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: isTablet ? 24 : 20),
                  onPressed: () {
                    _searchController.clear();
                    _filterSurah('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 18 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahList(BuildContext context, bool isTablet) {
    return SliverPadding(
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 16,
        right: isTablet ? 24 : 16,
        bottom: isTablet ? 24 : 16,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final surah = _filteredList[index];
          return _buildSurahCard(context, surah, isTablet, index);
        }, childCount: _filteredList.length),
      ),
    );
  }

  Widget _buildSurahCard(
    BuildContext context,
    SurahListModel surah,
    bool isTablet,
    int index,
  ) {
    final bool isMakki = surah.type.toLowerCase().contains('mak');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 20)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            margin: EdgeInsets.only(bottom: isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: Color(0xFFE5E7EB), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          QuranReadPage(surahNumber: surah.id),
                    ),
                  );
                  _loadData();
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                splashColor: Color(0xFF059669).withValues(alpha: 0.05),
                highlightColor: Color(0xFF059669).withValues(alpha: 0.02),
                child: Stack(
                  children: [
                    _buildSurahBackground(isMakki, isTablet),

                    Padding(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      child: Row(
                        children: [
                          _buildNumberBadge(surah, isTablet),
                          SizedBox(width: isTablet ? 16 : 14),
                          Expanded(
                            child: _buildSurahInfo(surah, isMakki, isTablet),
                          ),
                          SizedBox(width: isTablet ? 12 : 10),
                          _buildArabicName(surah, isTablet),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF059669),
                            size: isTablet ? 20 : 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurahBackground(bool isMakki, bool isTablet) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF059669).withValues(alpha: 0.3),
                      Color(0xFF059669).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusLarge),
                    bottomLeft: Radius.circular(AppDimensions.radiusLarge),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Opacity(
                opacity: 0.06,
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: isTablet ? 28 : 24,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberBadge(SurahListModel surah, bool isTablet) {
    return Container(
      width: isTablet ? 48 : 44,
      height: isTablet ? 48 : 44,
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE5E7EB), width: 1),
      ),
      child: Center(
        child: Text(
          surah.number,
          style: TextStyle(
            color: Color(0xFF059669),
            fontSize: isTablet ? 17 : 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahInfo(SurahListModel surah, bool isMakki, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          surah.nameLatin,
          style: TextStyle(
            fontSize: isTablet ? 16 : 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.2,
            height: 1.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 8 : 7,
                vertical: isTablet ? 4 : 3,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMakki
                      ? [Color(0xFFFEF3C7), Color(0xFFFDE68A)]
                      : [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isMakki
                      ? Color(0xFFF59E0B).withValues(alpha: 0.3)
                      : Color(0xFF059669).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                isMakki ? 'Makkah' : 'Madinah',
                style: TextStyle(
                  fontSize: isTablet ? 10 : 9,
                  fontWeight: FontWeight.w600,
                  color: isMakki ? Color(0xFFD97706) : Color(0xFF059669),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${surah.numberOfAyah} Ayat',
              style: TextStyle(
                fontSize: isTablet ? 13 : 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArabicName(SurahListModel surah, bool isTablet) {
    return Image.asset(
      'assets/image/sname_${surah.id}.png',
      width: isTablet ? 70 : 64,
      height: isTablet ? 32 : 28,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 10 : 8,
            vertical: isTablet ? 6 : 5,
          ),
          decoration: BoxDecoration(
            color: Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(0xFF059669).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            surah.name,
            style: TextStyle(
              fontFamily: 'Utsmani',
              fontSize: isTablet ? 20 : 18,
              color: Color(0xFF059669),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
