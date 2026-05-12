// screens/search_ayat_page.dart - SMART SEARCH UI
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizab_molah/quran/screens/read_page.dart';
import 'package:pizab_molah/quran/service/search_service.dart';

class SearchAyatPage extends StatefulWidget {
  const SearchAyatPage({super.key});

  @override
  State<SearchAyatPage> createState() => _SearchAyatPageState();
}

class _SearchAyatPageState extends State<SearchAyatPage>
    with SingleTickerProviderStateMixin {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<SearchResult> _searchResults = [];
  List<SurahSuggestion> _surahSuggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  String _searchMode = 'all'; // all, arabic, translation
  String _errorMessage = '';
  Timer? _debounce;
  bool _isDirectSearch = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  late double _scaleFactor;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocus.addListener(_onFocusChanged);

    _animController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _calculateResponsiveSizes(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      _scaleFactor = 0.85;
    } else if (width < 400) {
      _scaleFactor = 0.9;
    } else if (width < 600) {
      _scaleFactor = 1.0;
    } else if (width < 800) {
      _scaleFactor = 1.1;
    } else {
      _scaleFactor = 1.2;
    }
  }

  double _fontSize(double size) => size * _scaleFactor;
  double _spacing(double size) => size * _scaleFactor;

  void _onFocusChanged() {
    if (_searchFocus.hasFocus && _searchController.text.isNotEmpty) {
      _updateSuggestions(_searchController.text);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = _searchController.text.trim();

    // Update suggestions immediately for quick feedback
    if (query.isNotEmpty && !RegExp(r'^\d+:\d+$').hasMatch(query)) {
      _updateSuggestions(query);
    } else {
      setState(() {
        _showSuggestions = false;
        _surahSuggestions = [];
      });
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch();
    });
  }

  void _updateSuggestions(String query) {
    // Only show suggestions for surah name searches
    if (query.length >= 2 && !RegExp(r'\d').hasMatch(query)) {
      final suggestions = _searchService.findSurahSuggestions(query);
      setState(() {
        _surahSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });

      if (suggestions.isNotEmpty) {
        _animController.forward();
      }
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = '';
        _isDirectSearch = false;
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
      _showSuggestions = false;
    });

    try {
      List<SearchResult> results = await _searchService.searchAll(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _isDirectSearch =
              results.isNotEmpty &&
              results.first.type == SearchResultType.direct;

          if (results.isEmpty && query.length >= 3) {
            _errorMessage = 'Tidak ditemukan hasil untuk "$query"';
          } else if (results.isEmpty && query.length < 3) {
            _errorMessage = 'Minimal 3 karakter untuk pencarian';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan saat mencari';
          _isSearching = false;
        });
      }
    }
  }

  void _openDirectResult(SearchResult result) {
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuranReadPage(
              surahNumber: int.parse(result.surahNumber),
              initialAyah: result.ayatNumber,
            ),
          ),
        );
      }
    });
  }

  void _selectSuggestion(SurahSuggestion suggestion) {
    HapticFeedback.selectionClick();
    _searchController.text = suggestion.name.toLowerCase();
    setState(() {
      _showSuggestions = false;
    });
    _searchFocus.unfocus();
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    _calculateResponsiveSizes(context);

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          _searchFocus.unfocus();
          setState(() => _showSuggestions = false);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF059669), Color(0xFF047857)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSmartSearchBar(),
                                  if (!_isDirectSearch && !_showSuggestions)
                                    _buildQuickFilters(),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                color: Colors.white,
                                child: _buildSearchResults(context),
                              ),
                            ),
                          ],
                        ),
                        if (_showSuggestions) _buildSuggestions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xFF059669).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _spacing(16),
          vertical: _spacing(14),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                iconSize: _fontSize(24),
                padding: EdgeInsets.all(_spacing(8)),
                constraints: BoxConstraints(),
              ),
            ),
            SizedBox(width: _spacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: _fontSize(20),
                      ),
                      SizedBox(width: _spacing(8)),
                      Text(
                        'Smart Search',
                        style: TextStyle(
                          fontSize: _fontSize(20),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cari dengan mudah, toleran typo',
                    style: TextStyle(
                      fontSize: _fontSize(12),
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSearchBar() {
    return Padding(
      padding: EdgeInsets.all(_spacing(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: _spacing(48),
                  height: _spacing(56),
                  alignment: Alignment.center,
                  child: Container(
                    width: _spacing(36),
                    height: _spacing(36),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: _fontSize(18),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Coba: "baqoroh 255", "fatihah", "9:10"',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: _fontSize(13),
                        height: 1.2,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: _spacing(18),
                      ),
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: _fontSize(14),
                      height: 1.2,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Container(
                  width: _spacing(48),
                  height: _spacing(56),
                  alignment: Alignment.center,
                  child: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: _fontSize(20),
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _errorMessage = '';
                              _isDirectSearch = false;
                              _showSuggestions = false;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: _spacing(40),
                            minHeight: _spacing(40),
                          ),
                        )
                      : _isSearching
                      ? SizedBox(
                          width: _spacing(20),
                          height: _spacing(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF059669),
                          ),
                        )
                      : SizedBox(width: _spacing(40)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Padding(
      padding: EdgeInsets.fromLTRB(_spacing(16), 0, _spacing(16), _spacing(16)),
      child: Row(
        children: [
          _buildQuickFilterChip(
            'Semua',
            Icons.grid_view_rounded,
            _searchMode == 'all',
            () => setState(() => _searchMode = 'all'),
          ),
          SizedBox(width: _spacing(8)),
          _buildQuickFilterChip(
            'Arab',
            Icons.text_fields_rounded,
            _searchMode == 'arabic',
            () => setState(() => _searchMode = 'arabic'),
          ),
          SizedBox(width: _spacing(8)),
          _buildQuickFilterChip(
            'Terjemahan',
            Icons.translate_rounded,
            _searchMode == 'translation',
            () => setState(() => _searchMode = 'translation'),
          ),
          if (_searchResults.isNotEmpty) ...[
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _spacing(10),
                vertical: _spacing(6),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: _fontSize(14),
                    color: Colors.white,
                  ),
                  SizedBox(width: _spacing(5)),
                  Text(
                    '${_searchResults.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _fontSize(13),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: _spacing(10)),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)])
                : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: _fontSize(16),
                color: isSelected ? Colors.white : Color(0xFF6B7280),
              ),
              SizedBox(width: _spacing(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: _fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Positioned(
      top: _spacing(90),
      left: _spacing(16),
      right: _spacing(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: BoxConstraints(maxHeight: _spacing(300)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF059669).withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(_spacing(12)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF059669).withValues(alpha: 0.1),
                        Color(0xFF047857).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_fix_high_rounded,
                        size: _fontSize(16),
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: _spacing(8)),
                      Text(
                        'Saran Surah',
                        style: TextStyle(
                          fontSize: _fontSize(13),
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${_surahSuggestions.length}',
                        style: TextStyle(
                          fontSize: _fontSize(12),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: _spacing(4)),
                    itemCount: _surahSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _surahSuggestions[index];
                      return InkWell(
                        onTap: () => _selectSuggestion(suggestion),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _spacing(16),
                            vertical: _spacing(12),
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: index < _surahSuggestions.length - 1
                                    ? Colors.grey[200]!
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: _spacing(36),
                                height: _spacing(36),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF059669).withValues(alpha: 0.2),
                                      Color(0xFF047857).withValues(alpha: 0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${suggestion.number}',
                                    style: TextStyle(
                                      fontSize: _fontSize(14),
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: _spacing(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion.name,
                                      style: TextStyle(
                                        fontSize: _fontSize(14),
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: _spacing(6),
                                            vertical: _spacing(2),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF059669,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${(suggestion.matchScore * 100).toInt()}% match',
                                            style: TextStyle(
                                              fontSize: _fontSize(10),
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: _fontSize(14),
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isSearching) return _buildLoadingState();
    if (_errorMessage.isNotEmpty) return _buildErrorState();
    if (_searchController.text.isEmpty) return _buildEmptyInputState();
    if (_searchResults.isEmpty) return _buildNoResultsState();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        _spacing(16),
        _spacing(12),
        _spacing(16),
        _spacing(80),
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) =>
          _buildResultItem(context, _searchResults[index], index),
    );
  }

  Widget _buildDirectSearchState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_spacing(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_spacing(24)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF059669).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: _fontSize(60),
                color: Colors.white,
              ),
            ),
            SizedBox(height: _spacing(20)),
            Text(
              'Ayat Ditemukan!',
              style: TextStyle(
                fontSize: _fontSize(20),
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: _spacing(10)),
            Text(
              '${_searchResults.first.surahName}\nAyat ${_searchResults.first.ayatNumber}',
              style: TextStyle(
                fontSize: _fontSize(14),
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _spacing(20)),
            CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 3),
          SizedBox(height: _spacing(16)),
          Text(
            'Mencari ayat...',
            style: TextStyle(
              fontSize: _fontSize(13),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_spacing(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_spacing(20)),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: _fontSize(50),
                color: Colors.orange[400],
              ),
            ),
            SizedBox(height: _spacing(16)),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: _fontSize(14),
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _spacing(8)),
            Text(
              'Coba kata kunci lain atau periksa ejaan',
              style: TextStyle(
                fontSize: _fontSize(12),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInputState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_spacing(20)),
      child: Column(
        children: [
          SizedBox(height: _spacing(30)),
          Container(
            padding: EdgeInsets.all(_spacing(24)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF059669).withValues(alpha: 0.1),
                  Color(0xFF047857).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: _fontSize(60),
              color: Color(0xFF059669),
            ),
          ),
          SizedBox(height: _spacing(20)),
          Text(
            'Smart Search Al-Qur\'an',
            style: TextStyle(
              fontSize: _fontSize(20),
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: _spacing(8)),
          Text(
            'Pencarian pintar dengan toleransi typo\nTemukan ayat dengan mudah dan cepat',
            style: TextStyle(
              fontSize: _fontSize(13),
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _spacing(28)),
          Container(
            padding: EdgeInsets.all(_spacing(16)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF059669).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(_spacing(8)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tips_and_updates_rounded,
                        size: _fontSize(18),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: _spacing(10)),
                    Text(
                      'Cara Pencarian',
                      style: TextStyle(
                        fontSize: _fontSize(15),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _spacing(14)),
                _buildSearchExample(
                  'Langsung ke ayat',
                  '"9:10" atau "surat 2 ayat 255"',
                ),
                _buildSearchExample(
                  'Nama surah (toleran typo)',
                  '"baqoroh", "fatihah", "yasin"',
                ),
                _buildSearchExample(
                  'Surah + ayat',
                  '"al-baqarah 255", "fatihah 1"',
                ),
                _buildSearchExample(
                  'Cari teks Arab/Indonesia',
                  'Minimal 3 karakter',
                ),
              ],
            ),
          ),
          SizedBox(height: _spacing(20)),
          _buildQuickAccessButtons(),
        ],
      ),
    );
  }

  Widget _buildSearchExample(String title, String example) {
    return Padding(
      padding: EdgeInsets.only(bottom: _spacing(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: _spacing(2)),
            padding: EdgeInsets.all(_spacing(4)),
            decoration: BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: _fontSize(12), color: Colors.white),
          ),
          SizedBox(width: _spacing(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _fontSize(12),
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF064E3B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  example,
                  style: TextStyle(
                    fontSize: _fontSize(11),
                    color: Color(0xFF059669),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButtons() {
    return Column(
      children: [
        Text(
          'Akses Cepat',
          style: TextStyle(
            fontSize: _fontSize(13),
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: _spacing(12)),
        Wrap(
          spacing: _spacing(8),
          runSpacing: _spacing(8),
          alignment: WrapAlignment.center,
          children: [
            _buildQuickChip('Al-Fatihah', '1'),
            _buildQuickChip('Al-Baqarah:255', '2:255'),
            _buildQuickChip('Yasin', '36'),
            _buildQuickChip('Ar-Rahman', '55'),
            _buildQuickChip('Al-Kahf', '18'),
            _buildQuickChip('Al-Mulk', '67'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, String query) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _searchController.text = query;
        _performSearch();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _spacing(12),
          vertical: _spacing(8),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xFF059669).withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: _fontSize(12),
            fontWeight: FontWeight.w600,
            color: Color(0xFF059669),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_spacing(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_spacing(24)),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: _fontSize(60),
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: _spacing(20)),
            Text(
              'Tidak Ditemukan',
              style: TextStyle(
                fontSize: _fontSize(18),
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: _spacing(10)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _spacing(14),
                vertical: _spacing(8),
              ),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${_searchController.text}"',
                style: TextStyle(
                  fontSize: _fontSize(13),
                  color: Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: _spacing(14)),
            Text(
              'Coba kata kunci berbeda atau\ngunakan Smart Search dengan typo',
              style: TextStyle(
                fontSize: _fontSize(12),
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context,
    SearchResult result,
    int index,
  ) {
    bool isDirect = result.type == SearchResultType.direct;

    return Container(
      margin: EdgeInsets.only(bottom: _spacing(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDirect
            ? Border.all(color: Color(0xFF059669), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDirect
                ? Color(0xFF059669).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isDirect ? 16 : 12,
            offset: Offset(0, isDirect ? 4 : 3),
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
                builder: (context) => QuranReadPage(
                  surahNumber: int.parse(result.surahNumber),
                  initialAyah: result.ayatNumber,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(_spacing(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Direct Match Badge
                if (isDirect)
                  Container(
                    margin: EdgeInsets.only(bottom: _spacing(12)),
                    padding: EdgeInsets.symmetric(
                      horizontal: _spacing(10),
                      vertical: _spacing(6),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: _fontSize(16),
                          color: Colors.white,
                        ),
                        SizedBox(width: _spacing(6)),
                        Text(
                          'Hasil Langsung',
                          style: TextStyle(
                            fontSize: _fontSize(11),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      width: _spacing(44),
                      height: _spacing(44),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF059669).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          result.surahNumber,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _fontSize(15),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: _spacing(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            result.surahName,
                            style: TextStyle(
                              fontSize: _fontSize(15),
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _spacing(6),
                              vertical: _spacing(3),
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF059669).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Ayat ${result.ayatNumber}',
                              style: TextStyle(
                                fontSize: _fontSize(10),
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isDirect)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _spacing(10),
                          vertical: _spacing(6),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF059669).withValues(alpha: 0.15),
                              Color(0xFF047857).withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFF059669).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: _fontSize(12),
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: _spacing(14)),
                Divider(height: 1, color: Colors.grey[200]),
                SizedBox(height: _spacing(14)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(_spacing(14)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.arabicText,
                    style: TextStyle(
                      fontSize: _fontSize(25),
                      fontFamily: 'Utsmani',
                      height: 1.85,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF78350F),
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                SizedBox(height: _spacing(12)),
                Text(
                  result.translation,
                  style: TextStyle(
                    fontSize: _fontSize(12),
                    height: 1.6,
                    color: Color(0xFF374151),
                  ),
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: _spacing(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _spacing(14),
                        vertical: _spacing(9),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF059669).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: _fontSize(16),
                            color: Colors.white,
                          ),
                          SizedBox(width: _spacing(6)),
                          Text(
                            'Buka Ayat',
                            style: TextStyle(
                              fontSize: _fontSize(12),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: _spacing(4)),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: _fontSize(14),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
