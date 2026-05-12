import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizab_molah/quran/model/surah_model.dart';
import 'package:pizab_molah/quran/screens/read_page.dart';
import 'package:pizab_molah/quran/service/quran_service.dart';

class QuranBookmarksPage extends StatefulWidget {
  const QuranBookmarksPage({super.key});

  @override
  State<QuranBookmarksPage> createState() => _QuranBookmarksPageState();
}

class _QuranBookmarksPageState extends State<QuranBookmarksPage> {
  final QuranService _quranService = QuranService();
  List<BookmarkModel> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);

    final bookmarks = await _quranService.getBookmarks();

    // Sort by last read (newest first)
    bookmarks.sort((a, b) => b.lastRead.compareTo(a.lastRead));

    setState(() {
      _bookmarks = bookmarks;
      _isLoading = false;
    });
  }

  Future<void> _deleteBookmark(BookmarkModel bookmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDeleteDialog(bookmark),
    );

    if (confirmed == true) {
      await _quranService.removeBookmark(
        bookmark.surahNumber,
        bookmark.ayahNumber,
      );
      _loadBookmarks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bookmark berhasil dihapus',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildDeleteDialog(BookmarkModel bookmark) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: Color(0xFFEF4444),
                size: 40,
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'Hapus Bookmark?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 12),

            // Content
            Text(
              'Anda akan menghapus bookmark untuk:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    bookmark.surahName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ayat ${bookmark.ayahNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEF4444),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Bookmark Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF059669),
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF059669),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat bookmark...',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                ],
              ),
            )
          : _bookmarks.isEmpty
          ? _buildEmptyState(isTablet)
          : ListView.builder(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = _bookmarks[index];
                return _buildBookmarkItem(bookmark, isTablet, index);
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 48 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: isTablet ? 80 : 64,
                color: Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Belum Ada Bookmark',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tandai ayat favorit Anda dengan menekan ikon bookmark saat membaca Al-Qur\'an',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: isTablet ? 16 : 14,
              ),
              decoration: BoxDecoration(
                color: Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF059669).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF059669),
                    size: isTablet ? 22 : 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Tekan ',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      color: Color(0xFF047857),
                    ),
                  ),
                  Icon(
                    Icons.bookmark,
                    color: Color(0xFF059669),
                    size: isTablet ? 20 : 18,
                  ),
                  Text(
                    ' untuk menandai ayat',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      color: Color(0xFF047857),
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

  Widget _buildBookmarkList(bool isTablet) {
    return SliverPadding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final bookmark = _bookmarks[index];
          return _buildBookmarkItem(bookmark, isTablet, index);
        }, childCount: _bookmarks.length),
      ),
    );
  }

  Widget _buildBookmarkItem(BookmarkModel bookmark, bool isTablet, int index) {
    final timeAgo = _getTimeAgo(bookmark.lastRead);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFAFAFA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF059669).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: Offset(0, 4),
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
                    surahNumber: bookmark.surahNumber,
                    initialAyah: bookmark.ayahNumber,
                  ),
                ),
              );
              _loadBookmarks();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: isTablet ? 64 : 56,
                    height: isTablet ? 64 : 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF059669).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.bookmark_rounded,
                      color: Colors.white,
                      size: isTablet ? 30 : 26,
                    ),
                  ),
                  SizedBox(width: isTablet ? 20 : 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookmark.surahName,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 10 : 8,
                                vertical: isTablet ? 6 : 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF059669).withValues(alpha: 0.15),
                                    Color(0xFF047857).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xFF059669).withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bookmark,
                                    size: isTablet ? 14 : 12,
                                    color: Color(0xFF059669),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ayat ${bookmark.ayahNumber}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 13 : 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.access_time_rounded,
                              size: isTablet ? 14 : 12,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: isTablet ? 13 : 11,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8),

                  // Delete Button
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: isTablet ? 24 : 22,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _deleteBookmark(bookmark);
                      },
                      tooltip: 'Hapus Bookmark',
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
}
