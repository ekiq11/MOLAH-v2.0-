// models/surah_model.dart
class SurahModel {
  final String number;
  final String name;
  final String nameLatin;
  final String numberOfAyah;
  final Map<String, String> text;
  final Translations translations;
  final Tafsir tafsir;

  SurahModel({
    required this.number,
    required this.name,
    required this.nameLatin,
    required this.numberOfAyah,
    required this.text,
    required this.translations,
    required this.tafsir,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['number'] ?? '',
      name: json['name'] ?? '',
      nameLatin: json['name_latin'] ?? '',
      numberOfAyah: json['number_of_ayah'] ?? '',
      text: Map<String, String>.from(json['text'] ?? {}),
      translations: Translations.fromJson(json['translations'] ?? {}),
      tafsir: Tafsir.fromJson(json['tafsir'] ?? {}),
    );
  }
}

class Translations {
  final TranslationId id;

  Translations({required this.id});

  factory Translations.fromJson(Map<String, dynamic> json) {
    return Translations(
      id: TranslationId.fromJson(json['id'] ?? {}),
    );
  }
}

class TranslationId {
  final String name;
  final Map<String, String> text;

  TranslationId({required this.name, required this.text});

  factory TranslationId.fromJson(Map<String, dynamic> json) {
    return TranslationId(
      name: json['name'] ?? '',
      text: Map<String, String>.from(json['text'] ?? {}),
    );
  }
}

class Tafsir {
  final TafsirId id;

  Tafsir({required this.id});

  factory Tafsir.fromJson(Map<String, dynamic> json) {
    return Tafsir(
      id: TafsirId.fromJson(json['id'] ?? {}),
    );
  }
}

class TafsirId {
  final Kemenag kemenag;

  TafsirId({required this.kemenag});

  factory TafsirId.fromJson(Map<String, dynamic> json) {
    return TafsirId(
      kemenag: Kemenag.fromJson(json['kemenag'] ?? {}),
    );
  }
}

class Kemenag {
  final String name;
  final String source;
  final Map<String, String> text;

  Kemenag({required this.name, required this.source, required this.text});

  factory Kemenag.fromJson(Map<String, dynamic> json) {
    return Kemenag(
      name: json['name'] ?? '',
      source: json['source'] ?? '',
      text: Map<String, String>.from(json['text'] ?? {}),
    );
  }
}

// models/bookmark_model.dart
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
      lastRead: DateTime.parse(json['lastRead'] ?? DateTime.now().toIso8601String()),
    );
  }
}