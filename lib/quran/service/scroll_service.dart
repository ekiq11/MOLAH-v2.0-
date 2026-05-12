// quran/service/quran_service.dart
// Pastikan method ini ada di QuranService Anda

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuranService {
  // ... existing code ...

  /// Get last read bookmark (global, bukan per-surah)
  Future<BookmarkModel?> getLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReadJson = prefs.getString('last_read');

      if (lastReadJson == null || lastReadJson.isEmpty) {
        return null;
      }

      final data = json.decode(lastReadJson);
      return BookmarkModel.fromJson(data);
    } catch (e) {
      debugPrint('❌ Error getting last read: $e');
      return null;
    }
  }

  /// Save last read bookmark (akan override last read sebelumnya)
  Future<void> saveLastRead(BookmarkModel bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkJson = json.encode(bookmark.toJson());
      await prefs.setString('last_read', bookmarkJson);

      debugPrint(
        '✅ Last read saved: Surah ${bookmark.surahNumber}, Ayat ${bookmark.ayahNumber}',
      );
    } catch (e) {
      debugPrint('❌ Error saving last read: $e');
      rethrow;
    }
  }

  /// Clear last read
  Future<void> clearLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_read');
      debugPrint('🗑️ Last read cleared');
    } catch (e) {
      debugPrint('❌ Error clearing last read: $e');
    }
  }

  /// Get all bookmarks (untuk bookmark list)
  Future<List<BookmarkModel>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString('bookmarks');

      if (bookmarksJson == null || bookmarksJson.isEmpty) {
        return [];
      }

      final List<dynamic> data = json.decode(bookmarksJson);
      return data.map((item) => BookmarkModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('❌ Error getting bookmarks: $e');
      return [];
    }
  }

  /// Add bookmark
  Future<void> addBookmark(BookmarkModel bookmark) async {
    try {
      final bookmarks = await getBookmarks();

      // Prevent duplicate
      bookmarks.removeWhere(
        (b) =>
            b.surahNumber == bookmark.surahNumber &&
            b.ayahNumber == bookmark.ayahNumber,
      );

      bookmarks.add(bookmark);

      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = json.encode(
        bookmarks.map((b) => b.toJson()).toList(),
      );
      await prefs.setString('bookmarks', bookmarksJson);

      debugPrint(
        '✅ Bookmark added: Surah ${bookmark.surahNumber}, Ayat ${bookmark.ayahNumber}',
      );
    } catch (e) {
      debugPrint('❌ Error adding bookmark: $e');
      rethrow;
    }
  }

  /// Remove bookmark
  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    try {
      final bookmarks = await getBookmarks();
      bookmarks.removeWhere(
        (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
      );

      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = json.encode(
        bookmarks.map((b) => b.toJson()).toList(),
      );
      await prefs.setString('bookmarks', bookmarksJson);

      debugPrint('🗑️ Bookmark removed: Surah $surahNumber, Ayat $ayahNumber');
    } catch (e) {
      debugPrint('❌ Error removing bookmark: $e');
      rethrow;
    }
  }

  /// Get font size
  Future<double> getFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('font_size') ?? 28.0;
    } catch (e) {
      debugPrint('❌ Error getting font size: $e');
      return 28.0;
    }
  }

  /// Save font size
  Future<void> saveFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('font_size', size);
    } catch (e) {
      debugPrint('❌ Error saving font size: $e');
    }
  }

  /// Get show translation preference
  Future<bool> getShowTranslation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('show_translation') ?? true;
    } catch (e) {
      debugPrint('❌ Error getting show translation: $e');
      return true;
    }
  }

  /// Save show translation preference
  Future<void> saveShowTranslation(bool show) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_translation', show);
    } catch (e) {
      debugPrint('❌ Error saving show translation: $e');
    }
  }
}

// Model untuk bookmark
class BookmarkModel {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final DateTime lastRead;

  BookmarkModel({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.lastRead,
  });

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'lastRead': lastRead.toIso8601String(),
    };
  }

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      surahName: json['surahName'] as String,
      lastRead: DateTime.parse(json['lastRead'] as String),
    );
  }

  @override
  String toString() {
    return 'Bookmark(surah: $surahNumber, ayah: $ayahNumber, name: $surahName)';
  }
}
