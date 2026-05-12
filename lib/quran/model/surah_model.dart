// models/surah_model.dart - FIXED with revelationPlace getter
class SurahModel {
  final int id;
  final String ar;
  final String ltn;
  final String asma;
  final int len;
  final String type;
  final String trl;
  final String audio;
  final List<String> aya;
  final List<String> ayaTransliteration;
  final List<String> ayaTranslation;

  SurahModel({
    required this.id,
    required this.ar,
    required this.ltn,
    required this.asma,
    required this.len,
    required this.type,
    required this.trl,
    required this.audio,
    required this.aya,
    required this.ayaTransliteration,
    required this.ayaTranslation,
  });

  // Getter untuk backward compatibility
  String get number => id.toString();
  String get name => ar;
  String get nameLatin => ltn;
  String get numberOfAyah => len.toString();
  String get revelation => type;
  String get translation => trl;

  // TAMBAHAN: Getter revelationPlace untuk QuranAppBar
  String get revelationPlace {
    // Konversi type menjadi format yang lebih user-friendly
    if (type.toLowerCase().contains('mak')) {
      return 'Makkah';
    } else if (type.toLowerCase().contains('mad')) {
      return 'Madinah';
    }
    return type; // Fallback ke nilai asli jika tidak match
  }

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] ?? 0,
      ar: json['ar'] ?? '',
      ltn: json['ltn'] ?? '',
      asma: json['asma'] ?? '',
      len: json['len'] ?? 0,
      type: json['type'] ?? '',
      trl: json['trl'] ?? '',
      audio: json['audio'] ?? '',
      aya: json['aya'] != null ? List<String>.from(json['aya']) : [],
      ayaTransliteration: json['ayaTransliteration'] != null
          ? List<String>.from(json['ayaTransliteration'])
          : [],
      ayaTranslation: json['ayaTranslation'] != null
          ? List<String>.from(json['ayaTranslation'])
          : [],
    );
  }

  factory SurahModel.fromCombinedJson({
    required Map<String, dynamic> ayahJson,
    required Map<String, dynamic> transliterationJson,
    required Map<String, dynamic> translationJson,
    Map<String, dynamic>? metadataJson,
  }) {
    return SurahModel(
      id: ayahJson['id'] ?? 0,
      ar: ayahJson['name'] ?? '',
      ltn: metadataJson?['ltn'] ?? translationJson['name'] ?? '',
      asma: ayahJson['name'] ?? '',
      len: (ayahJson['aya'] as List?)?.length ?? 0,
      type: metadataJson?['type'] ?? 'Makkiyah',
      trl: translationJson['translation'] ?? '',
      audio: metadataJson?['audio'] ?? '',
      aya: ayahJson['aya'] != null ? List<String>.from(ayahJson['aya']) : [],
      ayaTransliteration: transliterationJson['ayaTranslation'] != null
          ? List<String>.from(transliterationJson['ayaTranslation'])
          : [],
      ayaTranslation: translationJson['ayaTranslation'] != null
          ? List<String>.from(translationJson['ayaTranslation'])
          : [],
    );
  }

  // Helper methods
  String getAyahText(int ayahNumber) {
    if (ayahNumber > 0 && ayahNumber <= aya.length) {
      return aya[ayahNumber - 1];
    }
    return '';
  }

  String getAyahTransliteration(int ayahNumber) {
    if (ayahNumber > 0 && ayahNumber <= ayaTransliteration.length) {
      return ayaTransliteration[ayahNumber - 1];
    }
    return '';
  }

  String getAyahTranslation(int ayahNumber) {
    if (ayahNumber > 0 && ayahNumber <= ayaTranslation.length) {
      return ayaTranslation[ayahNumber - 1];
    }
    return '';
  }
}

// Model untuk List Surah
class SurahListModel {
  final int id;
  final String ar;
  final String ltn;
  final String asma;
  final int len;
  final String type;
  final String trl;
  final String audio;

  SurahListModel({
    required this.id,
    required this.ar,
    required this.ltn,
    required this.asma,
    required this.len,
    required this.type,
    required this.trl,
    required this.audio,
  });

  // Getter untuk backward compatibility
  String get number => id.toString();
  String get name => ar;
  String get nameLatin => ltn;
  String get numberOfAyah => len.toString();
  String get revelation => type;
  String get translation => trl;

  // TAMBAHAN: Getter revelationPlace
  String get revelationPlace {
    if (type.toLowerCase().contains('mak')) {
      return 'Makkah';
    } else if (type.toLowerCase().contains('mad')) {
      return 'Madinah';
    }
    return type;
  }

  factory SurahListModel.fromJson(Map<String, dynamic> json) {
    return SurahListModel(
      id: json['id'] ?? 0,
      ar: json['ar'] ?? '',
      ltn: json['ltn'] ?? '',
      asma: json['asma'] ?? '',
      len: json['len'] ?? 0,
      type: json['type'] ?? '',
      trl: json['trl'] ?? '',
      audio: json['audio'] ?? '',
    );
  }
}

// Bookmark Model tetap sama
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
      surahNumber: json['surahNumber'] ?? 1,
      ayahNumber: json['ayahNumber'] ?? 1,
      surahName: json['surahName'] ?? '',
      lastRead: DateTime.parse(
        json['lastRead'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
