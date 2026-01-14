// services/quran_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pizab_molah/quran/model/surah_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


class QuranService {
  // Load surah dari assets
  Future<SurahModel?> loadSurah(int surahNumber) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/quran-json/update/$surahNumber.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Ambil data surah pertama dari JSON
      final surahData = jsonData[surahNumber.toString()];
      if (surahData != null) {
        return SurahModel.fromJson(surahData);
      }
      return null;
    } catch (e) {
      print('Error loading surah $surahNumber: $e');
      return null;
    }
  }

  // Load daftar semua surah (untuk list)
  Future<List<Map<String, dynamic>>> loadSurahList() async {
    List<Map<String, dynamic>> surahList = [];
    
    for (int i = 1; i <= 114; i++) {
      try {
        final surah = await loadSurah(i);
        if (surah != null) {
          surahList.add({
            'number': surah.number,
            'name': surah.name,
            'nameLatin': surah.nameLatin,
            'numberOfAyah': surah.numberOfAyah,
          });
        }
      } catch (e) {
        print('Error loading surah $i for list: $e');
      }
    }
    
    return surahList;
  }

  // Simpan bookmark terakhir dibaca
  Future<void> saveLastRead(BookmarkModel bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read', json.encode(bookmark.toJson()));
  }

  // Ambil bookmark terakhir dibaca
  Future<BookmarkModel?> getLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastReadString = prefs.getString('last_read');
      
      if (lastReadString != null) {
        return BookmarkModel.fromJson(json.decode(lastReadString));
      }
      return null;
    } catch (e) {
      print('Error getting last read: $e');
      return null;
    }
  }

  // Simpan bookmark custom
  Future<void> addBookmark(BookmarkModel bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookmarks = prefs.getStringList('bookmarks') ?? [];
    
    // Cek apakah bookmark sudah ada
    final existingIndex = bookmarks.indexWhere((b) {
      final bookmarkData = json.decode(b);
      return bookmarkData['surahNumber'] == bookmark.surahNumber &&
             bookmarkData['ayahNumber'] == bookmark.ayahNumber;
    });
    
    if (existingIndex == -1) {
      bookmarks.add(json.encode(bookmark.toJson()));
      await prefs.setStringList('bookmarks', bookmarks);
    }
  }

  // Ambil semua bookmarks
  Future<List<BookmarkModel>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> bookmarks = prefs.getStringList('bookmarks') ?? [];
      
      return bookmarks.map((b) {
        return BookmarkModel.fromJson(json.decode(b));
      }).toList();
    } catch (e) {
      print('Error getting bookmarks: $e');
      return [];
    }
  }

  // Hapus bookmark
  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookmarks = prefs.getStringList('bookmarks') ?? [];
    
    bookmarks.removeWhere((b) {
      final bookmarkData = json.decode(b);
      return bookmarkData['surahNumber'] == surahNumber &&
             bookmarkData['ayahNumber'] == ayahNumber;
    });
    
    await prefs.setStringList('bookmarks', bookmarks);
  }

  // Simpan setting font size
  Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', fontSize);
  }

  // Ambil setting font size
  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('font_size') ?? 28.0;
  }

  // Simpan setting translation visibility
  Future<void> saveShowTranslation(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_translation', show);
  }

  // Ambil setting translation visibility
  Future<bool> getShowTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_translation') ?? true;
  }
}