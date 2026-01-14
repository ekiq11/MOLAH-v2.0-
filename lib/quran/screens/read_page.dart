// screens/quran_read_page.dart - FIXED AUTO SCROLL VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizab_molah/quran/model/surah_model.dart';
import 'package:pizab_molah/quran/service/quran_service.dart';

class QuranReadPage extends StatefulWidget {
  final int surahNumber;
  final int? initialAyah;

  const QuranReadPage({
    Key? key,
    required this.surahNumber,
    this.initialAyah,
  }) : super(key: key);

  @override
  State<QuranReadPage> createState() => _QuranReadPageState();
}

class _QuranReadPageState extends State<QuranReadPage> {
  final QuranService _quranService = QuranService();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  
  SurahModel? _surah;
  bool _isLoading = true;
  double _fontSize = 28.0;
  bool _showTranslation = true;
  Set<int> _bookmarkedAyahs = {};
  bool _hasScrolledToInitial = false;
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _surah == null) return;
    
    // Cek apakah sudah scroll sampai bawah (dengan threshold)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 100.0; // 100px dari bawah
    
    if (currentScroll >= (maxScroll - threshold) && !_hasReachedEnd) {
      _hasReachedEnd = true;
      _showNextSurahDialog();
    }
  }

  void _showNextSurahDialog() {
    if (!mounted || _surah == null) return;
    
    final currentSurahNumber = widget.surahNumber;
    final nextSurahNumber = currentSurahNumber + 1;
    
    // Cek apakah ada surah berikutnya (total 114 surah)
    if (nextSurahNumber > 114) {
      // Sudah surah terakhir (An-Nas)
      _showCompletionDialog();
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle,
                color: Color(0xFF059669),
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Selesai!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda telah menyelesaikan ${_surah!.nameLatin}.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF059669).withOpacity(0.1),
                    Color(0xFF047857).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF059669).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF059669),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lanjut ke surah berikutnya?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke list
            },
            child: Text(
              'Kembali',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              // Navigate ke surah berikutnya
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QuranReadPage(
                    surahNumber: nextSurahNumber,
                    initialAyah: 1, // Mulai dari ayat pertama
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lanjutkan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Alhamdulillah!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda telah menyelesaikan Al-Qur\'an surah An-Nas, surah terakhir dalam Al-Qur\'an.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF4B5563),
                height: 1.6,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFBBF24).withOpacity(0.1),
                    Color(0xFFF59E0B).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Semoga bacaan Al-Qur\'an menjadi cahaya dan petunjuk dalam hidup Anda. 🤲',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF92400E),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Kembali ke Daftar Surah',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final surah = await _quranService.loadSurah(widget.surahNumber);
      final fontSize = await _quranService.getFontSize();
      final showTranslation = await _quranService.getShowTranslation();
      final bookmarks = await _quranService.getBookmarks();
      
      // Filter bookmarks untuk surah ini
      final bookmarkedAyahs = bookmarks
          .where((b) => b.surahNumber == widget.surahNumber)
          .map((b) => b.ayahNumber)
          .toSet();
      
      // Generate keys untuk setiap ayat
      if (surah != null) {
        _ayahKeys.clear();
        for (var i = 1; i <= int.parse(surah.numberOfAyah); i++) {
          _ayahKeys[i] = GlobalKey();
        }
      }
      
      if (mounted) {
        setState(() {
          _surah = surah;
          _fontSize = fontSize;
          _showTranslation = showTranslation;
          _bookmarkedAyahs = bookmarkedAyahs;
          _isLoading = false;
        });

        // Auto scroll ke initial ayah jika ada
        if (widget.initialAyah != null && !_hasScrolledToInitial) {
          _hasScrolledToInitial = true;
          
          // Tunggu hingga layout selesai di-render
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _performAutoScroll();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _performAutoScroll() {
    if (!mounted || widget.initialAyah == null || _surah == null) return;
    
    // Tunggu scroll controller siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (!mounted || !_scrollController.hasClients) return;
        
        final targetAyah = widget.initialAyah!;
        
        // Estimasi tinggi per ayat
        final estimatedAyahHeight = _showTranslation ? 350.0 : 200.0;
        
        // Estimasi posisi scroll
        final estimatedPosition = (targetAyah - 1) * estimatedAyahHeight;
        
        // Pastikan tidak melebihi max scroll extent yang tersedia saat ini
        final maxScroll = _scrollController.position.maxScrollExtent;
        final safePosition = estimatedPosition.clamp(0.0, maxScroll);
        
        debugPrint('Jumping to estimated position: $safePosition (target ayah: $targetAyah, max: $maxScroll)');
        
        // Jump ke posisi estimasi
        _scrollController.jumpTo(safePosition);
        
        // Tunggu lebih lama untuk render
        Future.delayed(Duration(milliseconds: 500), () {
          if (!mounted) return;
          
          // Cek apakah masih perlu scroll lebih jauh
          // Jika estimatedPosition > maxScroll, scroll ke bawah maksimal dulu
          if (estimatedPosition > maxScroll) {
            debugPrint('Need to scroll further, scrolling to max extent');
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            
            // Tunggu lagi untuk render lebih banyak widget
            Future.delayed(Duration(milliseconds: 500), () {
              _attemptScroll(0);
            });
          } else {
            // Langsung coba scroll halus
            _attemptScroll(0);
          }
        });
      });
    });
  }

  void _attemptScroll(int attempt) {
    if (!mounted || widget.initialAyah == null || attempt > 8) {
      if (attempt > 8) {
        debugPrint('Scroll completed after max attempts - showing notification anyway');
      }
      // Tetap tampilkan notifikasi
      _showScrollNotification();
      return;
    }

    final key = _ayahKeys[widget.initialAyah!];
    final context = key?.currentContext;
    
    if (context != null) {
      try {
        debugPrint('Attempt $attempt: Context found! Scrolling to ayah ${widget.initialAyah}');
        
        // Scroll halus ke posisi exact
        Scrollable.ensureVisible(
          context,
          duration: Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.15,
        ).then((_) {
          debugPrint('✓ Successfully scrolled to ayah ${widget.initialAyah}');
          _showScrollNotification();
        }).catchError((e) {
          debugPrint('Error in ensureVisible: $e');
          _showScrollNotification();
        });
      } catch (e) {
        debugPrint('Error scrolling attempt $attempt: $e');
        // Retry
        Future.delayed(Duration(milliseconds: 200), () {
          _attemptScroll(attempt + 1);
        });
      }
    } else {
      debugPrint('Attempt $attempt: Context not ready for ayah ${widget.initialAyah}');
      
      // Coba scroll sedikit lebih jauh untuk trigger rendering
      if (attempt == 3 && _scrollController.hasClients) {
        final currentPosition = _scrollController.offset;
        final maxPosition = _scrollController.position.maxScrollExtent;
        
        if (currentPosition < maxPosition) {
          debugPrint('Attempt 3: Scrolling further to trigger more rendering');
          _scrollController.jumpTo((currentPosition + 500).clamp(0.0, maxPosition));
        }
      }
      
      // Retry dengan delay lebih lama
      Future.delayed(Duration(milliseconds: 250), () {
        _attemptScroll(attempt + 1);
      });
    }
  }
  
  void _showScrollNotification() {
    if (!mounted) return;
    
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Lanjut dari Ayat ${widget.initialAyah}'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              left: 20,
              right: 20,
            ),
          ),
        );
      }
    });
  }

  Future<void> _saveLastRead(int ayahNumber) async {
    if (_surah != null) {
      final bookmark = BookmarkModel(
        surahNumber: widget.surahNumber,
        ayahNumber: ayahNumber,
        surahName: _surah!.nameLatin,
        lastRead: DateTime.now(),
      );
      await _quranService.saveLastRead(bookmark);
    }
  }

  Future<void> _toggleBookmark(int ayahNumber) async {
    if (_surah != null) {
      if (_bookmarkedAyahs.contains(ayahNumber)) {
        await _quranService.removeBookmark(widget.surahNumber, ayahNumber);
        setState(() => _bookmarkedAyahs.remove(ayahNumber));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bookmark dihapus'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      } else {
        final bookmark = BookmarkModel(
          surahNumber: widget.surahNumber,
          ayahNumber: ayahNumber,
          surahName: _surah!.nameLatin,
          lastRead: DateTime.now(),
        );
        await _quranService.addBookmark(bookmark);
        setState(() => _bookmarkedAyahs.add(ayahNumber));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bookmark ditambahkan'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      }
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsSheet(),
    );
  }

  Widget _buildSettingsSheet() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.all(isTablet ? 28 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: isTablet ? 28 : 24),
              
              Text(
                'Ukuran Teks Arab',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.text_fields, size: isTablet ? 22 : 18),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 20.0,
                      max: 40.0,
                      divisions: 20,
                      activeColor: Color(0xFF059669),
                      label: _fontSize.round().toString(),
                      onChanged: (value) {
                        setModalState(() => _fontSize = value);
                        setState(() => _fontSize = value);
                        _quranService.saveFontSize(value);
                      },
                    ),
                  ),
                  Icon(Icons.text_fields, size: isTablet ? 32 : 28),
                ],
              ),
              SizedBox(height: isTablet ? 20 : 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Tampilkan Terjemahan',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  value: _showTranslation,
                  activeColor: Color(0xFF059669),
                  onChanged: (value) {
                    setModalState(() => _showTranslation = value);
                    setState(() => _showTranslation = value);
                    _quranService.saveShowTranslation(value);
                  },
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF059669),
              ),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(context, isTablet),
                _buildAyahList(isTablet),
              ],
            ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 380 : 320,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF059669),
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _showTranslation ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _showTranslation = !_showTranslation;
                _quranService.saveShowTranslation(_showTranslation);
              });
            },
            tooltip: _showTranslation ? 'Sembunyikan Terjemahan' : 'Tampilkan Terjemahan',
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.tune, color: Colors.white, size: 22),
            onPressed: _showSettings,
          ),
        ),
      ],
      // Tambahkan title yang muncul saat collapsed
      title: _surah != null
          ? AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 200),
              child: Text(
                _surah!.nameLatin,
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        // Title akan hilang saat expanded, muncul saat collapsed
        titlePadding: EdgeInsets.zero,
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF059669),
                    Color(0xFF047857),
                    Color(0xFF065F46),
                  ],
                ),
              ),
            ),
            
            Positioned(
              right: -80,
              top: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -50,
              top: 100,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: 50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            
            if (_surah != null)
              Positioned.fill(
                top: isTablet ? 100 : 85,
                child: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isTablet ? 80 : 60,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: isTablet ? 18 : 14),
                        
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 28 : 20,
                            vertical: isTablet ? 16 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: isTablet ? 50 : 40,
                                child: Image.asset(
                                  'assets/image/sname_${widget.surahNumber}.png',
                                  color: Colors.white,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      _surah!.name,
                                      style: TextStyle(
                                        fontFamily: 'Utsmani',
                                        fontSize: isTablet ? 32 : 26,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3),
                                            offset: Offset(0, 2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 10),
                              
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 10,
                                  vertical: isTablet ? 6 : 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 15 : 13,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '${_surah!.numberOfAyah} Ayat',
                                      style: TextStyle(
                                        fontSize: isTablet ? 13 : 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _surah!.nameLatin,
                                        style: TextStyle(
                                          fontSize: isTablet ? 13 : 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.95),
                                          letterSpacing: 0.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 18 : 14),
                        
                        if (_surah!.nameLatin != 'Al-Fatihah')
                          Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: _surah!.nameLatin == 'At-Taubah'
                                      ? (isTablet ? 48 : 38)
                                      : (isTablet ? 38 : 30),
                                  child: _surah!.nameLatin == 'At-Taubah'
                                      ? Image.asset(
                                          'assets/image/taawuz.png',
                                          color: Colors.white,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(
                                              'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
                                              style: TextStyle(
                                                fontFamily: 'Utsmani',
                                                fontSize: isTablet ? 18 : 14,
                                                color: Colors.white,
                                                height: 1.6,
                                              ),
                                              textAlign: TextAlign.center,
                                            );
                                          },
                                        )
                                      : Image.asset(
                                          'assets/image/bismillah.png',
                                          color: Colors.white,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(
                                              'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                                              style: TextStyle(
                                                fontFamily: 'Utsmani',
                                                fontSize: isTablet ? 18 : 14,
                                                color: Colors.white,
                                                height: 1.6,
                                              ),
                                              textAlign: TextAlign.center,
                                            );
                                          },
                                        ),
                                ),
                                
                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    _surah!.nameLatin == 'At-Taubah'
                                        ? "Aku berlindung kepada Allah dari godaan syaitan yang terkutuk"
                                        : "Dengan menyebut nama Allah yang maha pengasih lagi maha penyayang",
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : 10,
                                      color: Colors.white.withOpacity(0.85),
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0.2,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        SizedBox(height: isTablet ? 14 : 10),
                        
                        Container(
                          width: isTablet ? 80 : 60,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahList(bool isTablet) {
    if (_surah == null) return SliverToBoxAdapter(child: SizedBox());

    final ayahCount = int.parse(_surah!.numberOfAyah);
    
    return SliverPadding(
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 16,
        right: isTablet ? 24 : 16,
        bottom: isTablet ? 24 : 16,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ayahNumber = index + 1;
            return _buildAyahItem(ayahNumber, isTablet);
          },
          childCount: ayahCount,
        ),
      ),
    );
  }

  Widget _buildAyahItem(int ayahNumber, bool isTablet) {
    final ayahText = _surah!.text[ayahNumber.toString()] ?? '';
    final translation = _surah!.translations.id.text[ayahNumber.toString()] ?? '';
    final tafsir = _surah!.tafsir?.id?.kemenag?.text?[ayahNumber.toString()] ?? '';
    final isBookmarked = _bookmarkedAyahs.contains(ayahNumber);
    final isTargetAyah = widget.initialAyah == ayahNumber;

    return Container(
      key: _ayahKeys[ayahNumber],
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isBookmarked
            ? Border.all(color: Color(0xFF059669), width: 2)
            : isTargetAyah
                ? Border.all(color: Color(0xFF3B82F6), width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 14 : 12,
            ),
            decoration: BoxDecoration(
              color: isBookmarked 
                  ? Color(0xFF059669).withOpacity(0.1)
                  : isTargetAyah
                      ? Color(0xFF3B82F6).withOpacity(0.1)
                      : Color(0xFFF3F4F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Ganti bagian nomor ayat di method _buildAyahItem dengan kode ini:

Container(
  width: isTablet ? 36 : 32,
  height: isTablet ? 36 : 32,
  child: Stack(
    alignment: Alignment.center,
    children: [
      // Background image ornamen
      Image.asset(
        'assets/other/img_number.png',
        width: isTablet ? 36 : 32,
        height: isTablet ? 36 : 32,
        fit: BoxFit.contain,
        color: isTargetAyah
            ? Color(0xFF3B82F6)
            : Color(0xFF059669),
        colorBlendMode: BlendMode.srcIn,
      ),
      // Nomor ayat di tengah
      Text(
        '$ayahNumber',
        style: TextStyle(
            color: Color(0xFF059669),
          fontSize: isTablet ? 13 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),
                if (isBookmarked)
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF059669),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Bookmark',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 11 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isTargetAyah)
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Terakhir Dibaca',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 11 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: Color(0xFF059669),
                    size: isTablet ? 26 : 22,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _toggleBookmark(ayahNumber);
                  },
                  tooltip: isBookmarked ? 'Hapus Bookmark' : 'Tambah Bookmark',
                ),
                // Tombol Tafsir
                if (tafsir.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.menu_book,
                      color: Color(0xFFD97706),
                      size: isTablet ? 24 : 20,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showTafsirDialog(ayahNumber, ayahText, translation, tafsir, isTablet);
                    },
                    tooltip: 'Lihat Tafsir',
                  ),
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: Color(0xFF6B7280),
                    size: isTablet ? 24 : 20,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(
                      ClipboardData(
                        text: '$ayahText\n\n$translation\n\n(${_surah!.nameLatin} ayat $ayahNumber)',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Ayat disalin ke clipboard'),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Bagikan Ayat',
                ),
              ],
            ),
          ),
          
          // Long press untuk tandai terakhir dibaca
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showLastReadConfirmation(ayahNumber);
            },
            child: 

Container(
  padding: EdgeInsets.all(isTablet ? 24 : 20),
  child: Text(
    ayahText,
    textAlign: TextAlign.right,
    textDirection: TextDirection.rtl,
    style: TextStyle(
      fontFamily: 'Utsmani',
      fontSize: _fontSize,
      height: 2.0,
      letterSpacing: 0,
      wordSpacing: 0,
      color: Color(0xFF1F2937),
      fontWeight: FontWeight.w400,
    ),
  ),
),
          ),
          
          if (_showTranslation)
            Container(
              padding: EdgeInsets.only(
                left: isTablet ? 24 : 20,
                right: isTablet ? 24 : 20,
                bottom: isTablet ? 24 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    translation,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      height: 1.7,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  // Hint untuk long press
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: isTablet ? 16 : 14,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tekan tahan untuk tandai terakhir dibaca',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 11,
                            color: Color(0xFF6B7280),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showLastReadConfirmation(int ayahNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.bookmark_add,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tandai Terakhir Dibaca',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Tandai ayat $ayahNumber dari ${_surah!.nameLatin} sebagai terakhir dibaca?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveLastRead(ayahNumber);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Tersimpan sebagai terakhir dibaca'),
                      ),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Tandai',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTafsirDialog(int ayahNumber, String ayahText, String translation, String tafsir, bool isTablet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
            maxWidth: isTablet ? 650 : double.infinity,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF059669),
                      Color(0xFF047857),
                      Color(0xFF065F46),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ayat $ayahNumber',
                                style: TextStyle(
                                  fontSize: isTablet ? 15 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _surah!.nameLatin,
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tafsir Kementerian Agama RI',
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 12,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content with beautiful sections
              Flexible(
                child: Container(
                  color: Color(0xFFFAFAFA),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ayat Arab dengan ornamen
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF059669).withOpacity(0.08),
                                blurRadius: 20,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Top ornament
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF059669),
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(isTablet ? 28 : 24),
                                child: Text(
                                  ayahText,
                                  textAlign: TextAlign.justify,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'Utsmani',
                                    fontSize: isTablet ? 28 : 24,
                                    height: 2.3,
                                    letterSpacing: 0,
                                    wordSpacing: 2.0,
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Terjemahan dengan icon
                        Container(
                          padding: EdgeInsets.all(isTablet ? 22 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Color(0xFF059669).withOpacity(0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF059669), Color(0xFF047857)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.translate_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Terjemahan',
                                    style: TextStyle(
                                      fontSize: isTablet ? 15 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF059669),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14),
                              Text(
                                translation,
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontSize: isTablet ? 15 : 14,
                                  height: 1.75,
                                  color: Color(0xFF334155),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Tafsir dengan background pattern
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFFBEB),
                                Color(0xFFFEF3C7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Color(0xFFF59E0B).withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFF59E0B).withOpacity(0.1),
                                blurRadius: 15,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Pattern background
                              Positioned(
                                right: -20,
                                bottom: -20,
                                child: Icon(
                                  Icons.auto_stories_rounded,
                                  size: 120,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(isTablet ? 22 : 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF59E0B),
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFFF59E0B).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.auto_stories_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Tafsir',
                                          style: TextStyle(
                                            fontSize: isTablet ? 15 : 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD97706),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      tafsir,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        fontSize: isTablet ? 15 : 14,
                                        height: 1.8,
                                        color: Color(0xFF92400E),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}