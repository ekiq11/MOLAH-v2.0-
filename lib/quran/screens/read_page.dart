// screens/quran_read_page.dart - FIXED: Highlight when marking as last read
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pizab_molah/quran/helper/jump_ayat.dart';
import 'package:pizab_molah/quran/helper/overlay.dart';
import 'package:pizab_molah/quran/helper/scroll_helper.dart';
import 'package:pizab_molah/quran/helper/theme.dart';
import 'package:pizab_molah/quran/model/surah_model.dart';
import 'package:pizab_molah/quran/service/audio_service.dart';
import 'package:pizab_molah/quran/service/quran_service.dart';
import 'package:pizab_molah/quran/widget/ayat_list_item.dart';
import 'package:pizab_molah/quran/widget/quran_app_bar.dart';
import 'package:pizab_molah/quran/widget/quran_dialog.dart';

class QuranReadPage extends StatefulWidget {
  final int surahNumber;
  final int? initialAyah;
  final bool autoScrollToLastRead;

  const QuranReadPage({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.autoScrollToLastRead = true,
  });

  @override
  State<QuranReadPage> createState() => _QuranReadPageState();
}

class _QuranReadPageState extends State<QuranReadPage> {
  final QuranService _quranService = QuranService();
  final QuranAudioService _audioService = QuranAudioService();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};

  SurahModel? _surah;
  bool _isLoading = true;
  double _fontSize = 28.0;
  bool _showTranslation = true;
  bool _showTransliteration = true;
  bool _showTajwid = false;
  bool _isDarkMode = false;
  Set<int> _bookmarkedAyahs = {};
  bool _hasReachedEnd = false;
  bool _showLastReadBanner = true;
  bool _hasShownDialog = false;
  bool _showNavigationFABs = false;
  String? _nextSurahName;
  String? _previousSurahName;

  int? _lastReadAyah;
  int? _targetAyah;
  bool _isFromLastRead = false;
  bool _hasScrolledToTarget = false;
  bool _isScrolling = false;

  bool _isAudioPlaying = false;
  String? _currentPlayingAyah;

  int? _currentVisibleAyah;
  DateTime? _lastVisibleTime;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() {
    _loadData();
    _scrollController.addListener(_onScroll);
    _setupAudioListener();
  }

  void _setupAudioListener() {
    _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed || state == PlayerState.stopped) {
            _currentPlayingAyah = null;
          }
        });
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _surah == null) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const threshold = 100.0;

    if (currentScroll >= (maxScroll - threshold) && !_hasReachedEnd) {
      setState(() => _hasReachedEnd = true);
      _showCompletionDialog();
    }

    if (currentScroll < (maxScroll - 300) && _hasReachedEnd) {
      setState(() => _hasReachedEnd = false);
    }

    _detectVisibleAyahAndSave();
  }

  void _showCompletionDialog() {
    if (!mounted ||
        _surah == null ||
        _hasShownDialog ||
        widget.surahNumber >= 114) {
      return;
    }

    setState(() => _hasShownDialog = true);

    QuranDialogs.showNextSurahDialog(
      context: context,
      currentSurahName: _surah!.nameLatin,
      currentSurahNumber: widget.surahNumber,
      onContinue: _goToNextSurah,
      onLater: () {
        setState(() => _showNavigationFABs = true);
      },
    );
  }

  void _detectVisibleAyahAndSave() {
    if (_surah == null || !_scrollController.hasClients) return;

    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    int? visibleAyah;

    for (var ayahNum = 1; ayahNum <= _surah!.len; ayahNum++) {
      final key = _ayahKeys[ayahNum];
      final context = key?.currentContext;

      if (context != null) {
        try {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final position = box.localToGlobal(Offset.zero);
            final ayahTop = position.dy;

            if (ayahTop >= 0 && ayahTop <= viewportHeight * 0.4) {
              visibleAyah = ayahNum;
              break;
            }
          }
        } catch (e) {
          // Ignore render errors
        }
      }
    }

    if (visibleAyah != null && visibleAyah != _currentVisibleAyah) {
      _currentVisibleAyah = visibleAyah;
      _lastVisibleTime = DateTime.now();
    } else if (visibleAyah != null &&
        _currentVisibleAyah == visibleAyah &&
        _lastVisibleTime != null) {
      final duration = DateTime.now().difference(_lastVisibleTime!);

      if (duration.inSeconds >= 2 && !_hasScrolledToTarget) {
        _autoSaveLastRead(visibleAyah);
        _lastVisibleTime = null;
      }
    }
  }

  Future<void> _autoSaveLastRead(int ayahNumber) async {
    if (_surah == null || ayahNumber == _lastReadAyah) return;

    try {
      final bookmark = BookmarkModel(
        surahNumber: widget.surahNumber,
        ayahNumber: ayahNumber,
        surahName: _surah!.nameLatin,
        lastRead: DateTime.now(),
      );
      await _quranService.saveLastRead(bookmark);

      setState(() {
        _lastReadAyah = ayahNumber;
      });

      debugPrint('💾 Auto-saved: Ayat $ayahNumber');
    } catch (e) {
      debugPrint('❌ Error auto-saving: $e');
    }
  }

  void _goToNextSurah() {
    if (widget.surahNumber >= 114) {
      _showErrorSnackbar('Ini sudah surah terakhir');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReadPage(
          surahNumber: widget.surahNumber + 1,
          initialAyah: 1,
          autoScrollToLastRead: false,
        ),
      ),
    );
  }

  void _goToPreviousSurah() {
    if (widget.surahNumber <= 1) {
      _showErrorSnackbar('Ini sudah surah pertama');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReadPage(
          surahNumber: widget.surahNumber - 1,
          autoScrollToLastRead: false,
        ),
      ),
    );
  }

  void _showJumpToAyahDialog() {
    if (_surah == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => JumpAyahDialog(
        currentAyah: _currentVisibleAyah ?? 1,
        totalAyahs: _surah!.len,
        surahNumber: widget.surahNumber,
        surahName: _surah!.nameLatin,
        isDarkMode: _isDarkMode,
        onJump: (ayahNumber) {
          setState(() {
            _targetAyah = ayahNumber;
            _isFromLastRead = false;
            _showLastReadBanner = false;
          });
          _performAutoScroll();
        },
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        _quranService.loadSurah(widget.surahNumber),
        _quranService.getFontSize(),
        _quranService.getShowTranslation(),
        _quranService.getShowTransliteration(),
        _quranService.getBookmarks(),
        _quranService.getLastRead(),
        _quranService.getShowTajwid(),
        _quranService.getDarkMode(),
        if (widget.surahNumber < 114)
          _quranService.loadSurah(widget.surahNumber + 1),
        if (widget.surahNumber > 1)
          _quranService.loadSurah(widget.surahNumber - 1),
      ]);

      final surah = results[0] as SurahModel?;
      final fontSize = results[1] as double;
      final showTranslation = results[2] as bool;
      final showTransliteration = results[3] as bool;
      final bookmarks = results[4] as List<BookmarkModel>;
      final lastReadBookmark = results[5] as BookmarkModel?;
      final showTajwid = results[6] as bool;
      final isDarkMode = results[7] as bool;

      SurahModel? nextSurah;
      SurahModel? prevSurah;
      if (widget.surahNumber < 114 && results.length > 8) {
        nextSurah = results[8] as SurahModel?;
      }
      if (widget.surahNumber > 1 && results.length > 9) {
        prevSurah = results[9] as SurahModel?;
      }

      final bookmarkedAyahs = bookmarks
          .where((b) => b.surahNumber == widget.surahNumber)
          .map((b) => b.ayahNumber)
          .toSet();

      int? targetAyah;
      bool isFromLastRead = false;

      if (widget.initialAyah != null) {
        targetAyah = widget.initialAyah;
        isFromLastRead = false;
      } else if (widget.autoScrollToLastRead &&
          lastReadBookmark != null &&
          lastReadBookmark.surahNumber == widget.surahNumber &&
          lastReadBookmark.ayahNumber > 1) {
        targetAyah = lastReadBookmark.ayahNumber;
        isFromLastRead = true;
      }

      if (surah != null) {
        _ayahKeys.clear();
        for (var i = 1; i <= surah.len; i++) {
          _ayahKeys[i] = GlobalKey();
        }
      }

      if (mounted) {
        setState(() {
          _surah = surah;
          _fontSize = fontSize;
          _showTranslation = showTranslation;
          _showTransliteration = showTransliteration;
          _showTajwid = showTajwid;
          _isDarkMode = isDarkMode;
          _bookmarkedAyahs = bookmarkedAyahs;
          _targetAyah = targetAyah;
          _isFromLastRead = isFromLastRead;
          _lastReadAyah = lastReadBookmark?.surahNumber == widget.surahNumber
              ? lastReadBookmark?.ayahNumber
              : null;
          _nextSurahName = nextSurah?.nameLatin;
          _previousSurahName = prevSurah?.nameLatin;
          _isLoading = false;
        });

        if (targetAyah != null && targetAyah > 1) {
          _performAutoScroll();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Gagal memuat data surah');
      }
    }
  }

  void _performAutoScroll() {
    if (!mounted || _targetAyah == null || _surah == null) return;

    debugPrint(
      '🚀 Auto scroll ke ayat $_targetAyah (isFromLastRead: $_isFromLastRead)',
    );

    setState(() {
      _hasScrolledToTarget = true;
      _isScrolling = true;
    });

    ScrollHelper.scrollToAyah(
      scrollController: _scrollController,
      ayahKeys: _ayahKeys,
      targetAyah: _targetAyah!,
      showTranslation: _showTranslation,
      onComplete: () {
        if (mounted) {
          setState(() {
            _isScrolling = false;
            _showLastReadBanner = false;
          });

          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              _hasScrolledToTarget = false;
            }
          });
        }
      },
    );
  }

  // ✅ FIXED: Highlight ayah immediately when marked as last read
  Future<void> _saveLastRead(int ayahNumber) async {
    if (_surah == null) return;

    try {
      final bookmark = BookmarkModel(
        surahNumber: widget.surahNumber,
        ayahNumber: ayahNumber,
        surahName: _surah!.nameLatin,
        lastRead: DateTime.now(),
      );
      await _quranService.saveLastRead(bookmark);

      // ✅ FIX: Update state dan set sebagai target untuk trigger highlight
      setState(() {
        _lastReadAyah = ayahNumber;
        _targetAyah =
            ayahNumber; // ✅ Set sebagai target ayah (ini yang bikin highlight!)
        _isFromLastRead = true; // ✅ Mark sebagai dari last read (warna hijau)
        _showLastReadBanner = false; // Hide banner karena sudah di posisi
      });

      if (mounted) {
        _showSuccessSnackbar('Tersimpan sebagai terakhir dibaca');
      }

      debugPrint('✅ Last read saved: Ayat $ayahNumber (highlighted)');
    } catch (e) {
      debugPrint('❌ Error saving last read: $e');
      if (mounted) {
        _showErrorSnackbar('Gagal menyimpan posisi terakhir');
      }
    }
  }

  Future<void> _toggleBookmark(int ayahNumber) async {
    if (_surah == null) return;

    try {
      if (_bookmarkedAyahs.contains(ayahNumber)) {
        await _quranService.removeBookmark(widget.surahNumber, ayahNumber);
        setState(() => _bookmarkedAyahs.remove(ayahNumber));
        if (mounted) _showErrorSnackbar('Bookmark dihapus');
      } else {
        final bookmark = BookmarkModel(
          surahNumber: widget.surahNumber,
          ayahNumber: ayahNumber,
          surahName: _surah!.nameLatin,
          lastRead: DateTime.now(),
        );
        await _quranService.addBookmark(bookmark);
        setState(() => _bookmarkedAyahs.add(ayahNumber));
        if (mounted) _showSuccessSnackbar('Bookmark ditambahkan');
      }
    } catch (e) {
      debugPrint('❌ Error toggling bookmark: $e');
      if (mounted) _showErrorSnackbar('Gagal mengubah bookmark');
    }
  }

  Future<void> _playAyahAudio(int ayahNumber) async {
    try {
      if (_audioService.isAyahPlaying(widget.surahNumber, ayahNumber)) {
        await _audioService.pause();
        setState(() {
          _currentPlayingAyah = null;
          _isAudioPlaying = false;
        });
        return;
      }

      if (_audioService.isPlaying && _currentPlayingAyah != null) {
        await _audioService.stop();
        await Future.delayed(Duration(milliseconds: 200));
      }

      setState(() {
        _currentPlayingAyah = '$ayahNumber';
        _isAudioPlaying = true;
      });

      await _audioService.playAyah(
        surahNumber: widget.surahNumber,
        ayahNumber: ayahNumber,
      );

      if (mounted) {
        _showSuccessSnackbar('Memutar ayat $ayahNumber');
      }
    } catch (e) {
      debugPrint('❌ Error playing audio: $e');

      setState(() {
        _currentPlayingAyah = null;
        _isAudioPlaying = false;
      });

      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () => _playAyahAudio(ayahNumber),
            ),
          ),
        );
      }
    }
  }

  void _showSettings() {
    QuranDialogs.showSettings(
      context: context,
      fontSize: _fontSize,
      showTranslation: _showTranslation,
      showTransliteration: _showTransliteration,
      showTajwid: _showTajwid,
      isDarkMode: _isDarkMode,
      onFontSizeChanged: (value) {
        setState(() => _fontSize = value);
        _quranService.saveFontSize(value);
      },
      onTranslationToggled: (value) {
        setState(() => _showTranslation = value);
        _quranService.saveShowTranslation(value);
      },
      onTransliterationToggled: (value) {
        setState(() => _showTransliteration = value);
        _quranService.saveShowTransliteration(value);
      },
      onTajwidToggled: (value) {
        setState(() => _showTajwid = value);
        _quranService.saveShowTajwid(value);
      },
      onDarkModeToggled: (value) {
        setState(() => _isDarkMode = value);
        _quranService.saveDarkMode(value);
      },
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final theme = QuranTheme(isDark: _isDarkMode);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: _isLoading
          ? _buildLoadingState(theme)
          : _buildContent(isTablet, theme),
      floatingActionButton: !_isLoading && _surah != null
          ? JumpAyahFAB(
              scrollController: _scrollController,
              onTap: _showJumpToAyahDialog,
              isDarkMode: _isDarkMode,
            )
          : null,
    );
  }

  void _performManualJump() {
    if (_targetAyah == null) return;

    setState(() {
      _showLastReadBanner = false;
      _isScrolling = true;
    });

    _hasScrolledToTarget = true;

    ScrollHelper.scrollToAyah(
      scrollController: _scrollController,
      ayahKeys: _ayahKeys,
      targetAyah: _targetAyah!,
      showTranslation: _showTranslation,
      onComplete: () {
        if (mounted) {
          setState(() {
            _isScrolling = false;
            _showLastReadBanner = false;
          });

          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              _hasScrolledToTarget = false;
            }
          });
        }
      },
    );
  }

  Widget _buildLoadingState(QuranTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF059669)),
          SizedBox(height: 16),
          Text(
            'Memuat surah...',
            style: TextStyle(color: theme.secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isTablet, QuranTheme theme) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          cacheExtent: 3000,
          slivers: [
            QuranAppBar(
              surah: _surah,
              showTranslation: _showTranslation,
              showTransliteration: _showTransliteration,
              isTablet: isTablet,
              isDarkMode: _isDarkMode,
              onBackPressed: () {
                _audioService.stop();
                Navigator.pop(context);
              },
              onSettingsPressed: _showSettings,
              onTranslationToggled: () {},
              onTransliterationToggled: () {},
            ),
            _buildAyahList(isTablet, theme),
          ],
        ),

        if (_targetAyah != null && _targetAyah! > 3 && _showLastReadBanner)
          _buildLastReadBanner(isTablet),

        SimpleScrollLoading(
          targetAyah: _targetAyah ?? 1,
          isVisible: _isScrolling,
        ),

        SurahNavigationFABs(
          scrollController: _scrollController,
          isVisible: _showNavigationFABs,
          isDarkMode: _isDarkMode,
          nextSurahName: _nextSurahName,
          previousSurahName: _previousSurahName,
          onNextSurah: widget.surahNumber < 114 ? _goToNextSurah : null,
          onPreviousSurah: widget.surahNumber > 1 ? _goToPreviousSurah : null,
        ),
      ],
    );
  }

  Widget _buildLastReadBanner(bool isTablet) {
    return Positioned(
      top: kToolbarHeight + 60,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isFromLastRead
                  ? [Color(0xFF059669), Color(0xFF047857)]
                  : [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (_isFromLastRead ? Color(0xFF059669) : Color(0xFF3B82F6))
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              InkWell(
                onTap: _performManualJump,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 16 : 14),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _isFromLastRead ? Icons.bookmark : Icons.location_on,
                          color: Colors.white,
                          size: isTablet ? 22 : 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isFromLastRead
                                  ? 'Terakhir Dibaca'
                                  : 'Target Ayat',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isTablet ? 12 : 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ayat $_targetAyah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 16 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Ketuk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 13 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showLastReadBanner = false),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAyahList(bool isTablet, QuranTheme theme) {
    if (_surah == null) return SliverToBoxAdapter(child: SizedBox());

    final topPadding =
        _targetAyah != null && _targetAyah! > 3 && _showLastReadBanner
        ? (isTablet ? 100.0 : 90.0)
        : (isTablet ? 24.0 : 20.0);

    return SliverPadding(
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 16,
        right: isTablet ? 24 : 16,
        top: topPadding,
        bottom: 100,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ayahNumber = index + 1;
            return AyahListItem(
              key: _ayahKeys[ayahNumber],
              ayahNumber: ayahNumber,
              surah: _surah!,
              fontSize: _fontSize,
              showTranslation: _showTranslation,
              showTransliteration: _showTransliteration,
              showTajwid: _showTajwid,
              isDarkMode: _isDarkMode,
              isBookmarked: _bookmarkedAyahs.contains(ayahNumber),
              isTargetAyah:
                  _targetAyah == ayahNumber, // ✅ Ini yang trigger highlight!
              isPlayingThis: _audioService.isAyahPlaying(
                widget.surahNumber,
                ayahNumber,
              ),
              isTablet: isTablet,
              onPlayAudio: () => _playAyahAudio(ayahNumber),
              onToggleBookmark: () => _toggleBookmark(ayahNumber),
              onSaveLastRead: () => _saveLastRead(ayahNumber),
            );
          },
          childCount: _surah!.len,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('🗑️  Disposing QuranReadPage...');

    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _audioService
        .stop()
        .then((_) {
          debugPrint('✅ Audio stopped on page dispose');
        })
        .catchError((e) {
          debugPrint('⚠️ Audio stop error on dispose (ignored): $e');
        });

    debugPrint('✅ QuranReadPage disposed');

    super.dispose();
  }
}
