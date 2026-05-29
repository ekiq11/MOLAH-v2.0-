import 'package:flutter/foundation.dart';
// service/quran_service.dart - COMPLETE WITH DARK MODE SUPPORT
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pizab_molah/quran/model/surah_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranService {
  static const String _bookmarksKey = 'quran_bookmarks';
  static const String _lastReadKey = 'quran_last_read';
  static const String _fontSizeKey = 'quran_font_size';
  static const String _showTranslationKey = 'quran_show_translation';
  static const String _showTransliterationKey = 'quran_show_transliteration';
  static const String _showTajwidKey = 'quran_show_tajwid';
  static const String _darkModeKey = 'quran_dark_mode'; // ✅ ADDED

  // ==================== LOAD SURAH ====================
  Future<SurahModel?> loadSurah(int surahNumber) async {
    try {
      debugPrint('📖 Loading surah $surahNumber...');

      // Load ayat (teks Arab)
      final ayahJson = await rootBundle.loadString(
        'assets/quran-json/ayat/arabic_verse_uthmani$surahNumber.json',
      );
      final ayahData = json.decode(ayahJson);
      debugPrint('✅ Ayah data loaded for surah $surahNumber');

      // Load transliteration
      final transliterationJson = await rootBundle.loadString(
        'assets/quran-json/transliteration/$surahNumber.json',
      );
      final transliterationData = json.decode(transliterationJson);
      debugPrint('✅ Transliteration data loaded for surah $surahNumber');

      // Load translation
      final translationJson = await rootBundle.loadString(
        'assets/quran-json/terjemahan/$surahNumber.json',
      );
      final translationData = json.decode(translationJson);
      debugPrint('✅ Translation data loaded for surah $surahNumber');

      // Load surah metadata
      final listSurahJson = await rootBundle.loadString(
        'assets/quran-json/surah/list-surah.json',
      );
      final List<dynamic> listSurah = json.decode(listSurahJson);
      final surahMeta = listSurah.firstWhere(
        (s) => s['id'] == surahNumber,
        orElse: () => null,
      );
      debugPrint('✅ Metadata loaded for surah $surahNumber');

      // Gabungkan semua data
      final surahModel = SurahModel(
        id: ayahData['id'] ?? surahNumber,
        ar: ayahData['name'] ?? '',
        ltn: surahMeta?['ltn'] ?? translationData['name'] ?? '',
        asma: ayahData['name'] ?? '',
        len: (ayahData['aya'] as List?)?.length ?? 0,
        type: surahMeta?['type'] ?? 'Makkiyah',
        trl: translationData['translation'] ?? '',
        audio: surahMeta?['audio'] ?? '',
        aya: List<String>.from(ayahData['aya'] ?? []),
        ayaTransliteration: List<String>.from(
          transliterationData['ayaTranslation'] ?? [],
        ),
        ayaTranslation: List<String>.from(
          translationData['ayaTranslation'] ?? [],
        ),
      );

      debugPrint(
        '✅ Surah $surahNumber loaded successfully with ${surahModel.len} ayat',
      );
      return surahModel;
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading surah $surahNumber: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // ==================== LOAD SURAH LIST ====================
  Future<List<SurahListModel>> loadSurahList() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/quran-json/surah/list-surah.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      return jsonData.map((json) => SurahListModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading surah list: $e');
      return [];
    }
  }

  // ==================== BOOKMARKS ====================
  Future<List<BookmarkModel>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];

      return bookmarksJson
          .map((json) => BookmarkModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting bookmarks: $e');
      return [];
    }
  }

  Future<void> addBookmark(BookmarkModel bookmark) async {
    try {
      final bookmarks = await getBookmarks();

      // Remove existing bookmark for this ayah if exists
      bookmarks.removeWhere(
        (b) =>
            b.surahNumber == bookmark.surahNumber &&
            b.ayahNumber == bookmark.ayahNumber,
      );

      bookmarks.add(bookmark);

      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = bookmarks
          .map((b) => jsonEncode(b.toJson()))
          .toList();

      await prefs.setStringList(_bookmarksKey, bookmarksJson);
    } catch (e) {
      debugPrint('❌ Error adding bookmark: $e');
    }
  }

  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    try {
      final bookmarks = await getBookmarks();
      bookmarks.removeWhere(
        (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
      );

      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = bookmarks
          .map((b) => jsonEncode(b.toJson()))
          .toList();

      await prefs.setStringList(_bookmarksKey, bookmarksJson);
    } catch (e) {
      debugPrint('❌ Error removing bookmark: $e');
    }
  }

  Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    try {
      final bookmarks = await getBookmarks();
      return bookmarks.any(
        (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
      );
    } catch (e) {
      debugPrint('❌ Error checking bookmark: $e');
      return false;
    }
  }

  // ==================== LAST READ ====================
  Future<BookmarkModel?> getLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReadJson = prefs.getString(_lastReadKey);

      if (lastReadJson != null) {
        return BookmarkModel.fromJson(jsonDecode(lastReadJson));
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting last read: $e');
      return null;
    }
  }

  Future<void> saveLastRead(BookmarkModel bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastReadKey, jsonEncode(bookmark.toJson()));
    } catch (e) {
      debugPrint('❌ Error saving last read: $e');
    }
  }

  // ==================== SETTINGS ====================

  // Font Size
  Future<double> getFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_fontSizeKey) ?? 28.0;
    } catch (e) {
      debugPrint('❌ Error getting font size: $e');
      return 28.0;
    }
  }

  Future<void> saveFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, size);
    } catch (e) {
      debugPrint('❌ Error saving font size: $e');
    }
  }

  // Translation
  Future<bool> getShowTranslation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showTranslationKey) ?? true;
    } catch (e) {
      debugPrint('❌ Error getting show translation: $e');
      return true;
    }
  }

  Future<void> saveShowTranslation(bool show) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showTranslationKey, show);
    } catch (e) {
      debugPrint('❌ Error saving show translation: $e');
    }
  }

  // Transliteration
  Future<bool> getShowTransliteration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showTransliterationKey) ?? true;
    } catch (e) {
      debugPrint('❌ Error getting show transliteration: $e');
      return true;
    }
  }

  Future<void> saveShowTransliteration(bool show) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showTransliterationKey, show);
    } catch (e) {
      debugPrint('❌ Error saving show transliteration: $e');
    }
  }

  // Tajwid
  Future<bool> getShowTajwid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showTajwidKey) ?? false;
    } catch (e) {
      debugPrint('❌ Error getting show tajwid: $e');
      return false;
    }
  }

  Future<void> saveShowTajwid(bool show) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showTajwidKey, show);
      debugPrint('✅ Tajwid setting saved: $show');
    } catch (e) {
      debugPrint('❌ Error saving show tajwid: $e');
    }
  }

  // ✅ Dark Mode
  Future<bool> getDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_darkModeKey) ?? false;
    } catch (e) {
      debugPrint('❌ Error getting dark mode: $e');
      return false;
    }
  }

  Future<void> saveDarkMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, isDark);
      debugPrint('✅ Dark mode setting saved: $isDark');
    } catch (e) {
      debugPrint('❌ Error saving dark mode: $e');
    }
  }
}
