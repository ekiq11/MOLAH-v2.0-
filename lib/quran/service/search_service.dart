// service/search_service.dart - SMART SEARCH WITH FUZZY MATCHING
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class SearchResult {
  final String surahNumber;
  final String surahName;
  final int ayatNumber;
  final String arabicText;
  final String translation;
  final SearchResultType type;
  final double relevanceScore;

  SearchResult({
    required this.surahNumber,
    required this.surahName,
    required this.ayatNumber,
    required this.arabicText,
    required this.translation,
    this.type = SearchResultType.text,
    this.relevanceScore = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          ayatNumber == other.ayatNumber;

  @override
  int get hashCode => surahNumber.hashCode ^ ayatNumber.hashCode;
}

enum SearchResultType { text, direct }

class SurahSuggestion {
  final int number;
  final String name;
  final String arabicName;
  final int ayatCount;
  final double matchScore;

  SurahSuggestion({
    required this.number,
    required this.name,
    required this.arabicName,
    required this.ayatCount,
    required this.matchScore,
  });
}

class _SurahData {
  final int id;
  final String name;
  final List<String> arabicTexts;
  final List<String> translations;

  _SurahData({
    required this.id,
    required this.name,
    required this.arabicTexts,
    required this.translations,
  });
}

class SearchService {
  final Map<int, _SurahData> _surahCache = {};
  static const int _maxResults = 100;

  // Enhanced surah names with multiple variations
  final Map<String, List<String>> _surahVariations = {
    '1': ['fatihah', 'fatiha', 'alfatihah', 'al-fatihah', 'pembukaan'],
    '2': ['baqarah', 'baqoroh', 'albaqarah', 'al-baqarah', 'sapi', 'lembu'],
    '3': ['ali imran', 'imran', 'al-imran', 'keluarga imran'],
    '4': ['nisa', 'annisa', 'an-nisa', 'wanita', 'perempuan'],
    '5': ['maidah', 'almaidah', 'al-maidah', 'hidangan'],
    '6': ['anam', 'alanam', 'al-anam', 'binatang ternak'],
    '7': ['araf', 'alaraf', 'al-araf'],
    '8': ['anfal', 'alanfal', 'al-anfal', 'harta rampasan'],
    '9': ['taubah', 'tawbah', 'attaubah', 'at-taubah', 'pengampunan'],
    '10': ['yunus', 'nabi yunus'],
    '11': ['hud', 'nabi hud'],
    '12': ['yusuf', 'yusup', 'nabi yusuf', 'nabi yusup'],
    '13': ['rad', 'raad', 'arrad', 'ar-rad', 'guntur', 'guruh'],
    '14': ['ibrahim', 'nabi ibrahim'],
    '15': ['hijr', 'alhijr', 'al-hijr'],
    '16': ['nahl', 'annahl', 'an-nahl', 'lebah'],
    '17': ['isra', 'alisra', 'al-isra', 'perjalanan malam'],
    '18': ['kahf', 'alkahf', 'al-kahf', 'gua'],
    '19': ['maryam', 'mariam'],
    '20': ['taha', 'ta-ha', 'ta ha'],
    '21': ['anbiya', 'alanbiya', 'al-anbiya', 'para nabi'],
    '22': ['hajj', 'alhajj', 'al-hajj', 'haji'],
    '23': ['muminun', 'almuminun', 'al-muminun', 'orang-orang beriman'],
    '24': ['nur', 'annur', 'an-nur', 'cahaya'],
    '25': ['furqan', 'alfurqan', 'al-furqan', 'pembeda'],
    '26': ['syuara', 'syu\'ara', 'asysyuara', 'asy-syuara', 'penyair'],
    '27': ['naml', 'annaml', 'an-naml', 'semut'],
    '28': ['qasas', 'qosos', 'alqasas', 'al-qasas', 'kisah'],
    '29': ['ankabut', 'alankabut', 'al-ankabut', 'laba-laba'],
    '30': ['rum', 'arrum', 'ar-rum', 'romawi'],
    '31': ['luqman', 'lukman', 'loqman'],
    '32': ['sajdah', 'sajdah', 'assajdah', 'as-sajdah', 'sujud'],
    '33': ['ahzab', 'alahzab', 'al-ahzab', 'golongan'],
    '34': ['saba', 'saba\''],
    '35': ['fatir', 'fathir', 'pencipta'],
    '36': ['yasin', 'ya-sin', 'ya sin', 'yasiin'],
    '37': ['saffat', 'assaffat', 'as-saffat', 'barisan'],
    '38': ['sad'],
    '39': ['zumar', 'azzumar', 'az-zumar', 'rombongan'],
    '40': ['ghafir', 'gafir', 'yang mengampuni'],
    '41': ['fussilat', 'fushshilat', 'dijelaskan'],
    '42': ['syura', 'asysyura', 'asy-syura', 'musyawarah'],
    '43': ['zukhruf', 'azzukhruf', 'az-zukhruf', 'perhiasan'],
    '44': ['dukhan', 'addukhan', 'ad-dukhan', 'kabut'],
    '45': ['jasiyah', 'jatsiyah', 'aljasiyah', 'al-jasiyah', 'berlutut'],
    '46': ['ahqaf', 'alahqaf', 'al-ahqaf', 'bukit pasir'],
    '47': ['muhammad', 'nabi muhammad'],
    '48': ['fath', 'fat-h', 'alfath', 'al-fath', 'kemenangan'],
    '49': ['hujurat', 'hujuraat', 'alhujurat', 'al-hujurat', 'kamar'],
    '50': ['qaf', 'qaaf'],
    '51': ['zariyat', 'dzariyat', 'azzariyat', 'az-zariyat', 'angin'],
    '52': ['tur', 'thur', 'attur', 'at-tur', 'bukit'],
    '53': ['najm', 'annajm', 'an-najm', 'bintang'],
    '54': ['qamar', 'qomar', 'alqamar', 'al-qamar', 'bulan'],
    '55': ['rahman', 'arrahman', 'ar-rahman', 'maha pengasih'],
    '56': ['waqiah', 'waqi\'ah', 'alwaqiah', 'al-waqiah', 'hari kiamat'],
    '57': ['hadid', 'hadiid', 'alhadid', 'al-hadid', 'besi'],
    '58': ['mujadalah', 'mujadilah', 'almujadalah', 'al-mujadalah', 'gugatan'],
    '59': ['hasyr', 'hasyr', 'alhasyr', 'al-hasyr', 'pengusiran'],
    '60': [
      'mumtahanah',
      'mumtahanah',
      'almumtahanah',
      'al-mumtahanah',
      'wanita diuji',
    ],
    '61': ['saff', 'shaf', 'assaff', 'as-saff', 'barisan'],
    '62': ['jumuah', 'jum\'at', 'aljumuah', 'al-jumuah', 'jumat'],
    '63': [
      'munafiqun',
      'munafiqun',
      'almunafiqun',
      'al-munafiqun',
      'orang munafik',
    ],
    '64': [
      'taghabun',
      'taghaabun',
      'attaghabun',
      'at-taghabun',
      'hari ditimbang',
    ],
    '65': ['talaq', 'thalaq', 'attalaq', 'at-talaq', 'cerai'],
    '66': ['tahrim', 'tahriim', 'attahrim', 'at-tahrim', 'mengharamkan'],
    '67': ['mulk', 'almulk', 'al-mulk', 'kerajaan'],
    '68': ['qalam', 'alqalam', 'al-qalam', 'pena', 'nun'],
    '69': ['haqqah', 'haaqqah', 'alhaqqah', 'al-haqqah', 'hari kiamat'],
    '70': ['maarij', 'ma\'arij', 'almaarij', 'al-maarij', 'tempat naik'],
    '71': ['nuh', 'nooh', 'nabi nuh'],
    '72': ['jinn', 'jin', 'aljinn', 'al-jinn'],
    '73': [
      'muzzammil',
      'muzammil',
      'almuzzammil',
      'al-muzzammil',
      'berselimut',
    ],
    '74': [
      'muddassir',
      'mudatstsir',
      'almuddassir',
      'al-muddassir',
      'berselimut',
    ],
    '75': ['qiyamah', 'qiyaamah', 'alqiyamah', 'al-qiyamah', 'hari berbangkit'],
    '76': ['insan', 'alinsan', 'al-insan', 'manusia', 'dahr'],
    '77': ['mursalat', 'mursalaat', 'almursalat', 'al-mursalat', 'malaikat'],
    '78': ['naba', 'naba\'', 'annaba', 'an-naba', 'berita besar'],
    '79': ['naziat', 'naazi\'at', 'annaziat', 'an-naziat', 'malaikat'],
    '80': ['abasa', 'bermuka masam'],
    '81': ['takwir', 'attakwir', 'at-takwir', 'menggulung'],
    '82': ['infitar', 'alinfitar', 'al-infitar', 'terbelah'],
    '83': ['mutaffifin', 'almutaffifin', 'al-mutaffifin', 'curang'],
    '84': ['insyiqaq', 'insyiqaaq', 'alinsyiqaq', 'al-insyiqaq', 'terbelah'],
    '85': ['buruj', 'buruuj', 'alburuj', 'al-buruj', 'gugusan bintang'],
    '86': ['tariq', 'thariq', 'attariq', 'at-tariq', 'bintang'],
    '87': ['ala', 'a\'la', 'alala', 'al-ala', 'maha tinggi'],
    '88': [
      'ghasyiyah',
      'ghaasyiyah',
      'alghasyiyah',
      'al-ghasyiyah',
      'hari pembalasan',
    ],
    '89': ['fajr', 'fajar', 'alfajr', 'al-fajr', 'fajar'],
    '90': ['balad', 'albalad', 'al-balad', 'negeri'],
    '91': ['syams', 'shams', 'asysyams', 'asy-syams', 'matahari'],
    '92': ['lail', 'layl', 'allail', 'al-lail', 'malam'],
    '93': ['duha', 'dhuha', 'adduha', 'ad-duha', 'waktu duha'],
    '94': ['syarh', 'syarah', 'asysyarh', 'asy-syarh', 'lapang', 'insyirah'],
    '95': ['tin', 'tiin', 'attin', 'at-tin', 'buah tin'],
    '96': ['alaq', 'alaq', 'alalaq', 'al-alaq', 'segumpal darah', 'iqra'],
    '97': ['qadr', 'qodr', 'alqadr', 'al-qadr', 'kemuliaan'],
    '98': ['bayyinah', 'bayyinah', 'albayyinah', 'al-bayyinah', 'bukti'],
    '99': ['zalzalah', 'zalzalah', 'azzalzalah', 'az-zalzalah', 'goncangan'],
    '100': ['adiyat', 'aadiyat', 'aladiyat', 'al-adiyat', 'kuda perang'],
    '101': ['qariah', 'qaari\'ah', 'alqariah', 'al-qariah', 'hari kiamat'],
    '102': ['takasur', 'takaatsur', 'attakasur', 'at-takasur', 'bermegah'],
    '103': ['asr', 'ashar', 'alasr', 'al-asr', 'waktu'],
    '104': ['humazah', 'humazah', 'alhumazah', 'al-humazah', 'pengumpat'],
    '105': ['fil', 'fiil', 'alfil', 'al-fil', 'gajah'],
    '106': ['quraisy', 'quraysh', 'qurays'],
    '107': ['maun', 'maa\'un', 'almaun', 'al-maun', 'barang berguna'],
    '108': ['kausar', 'kautsar', 'alkausar', 'al-kausar', 'nikmat'],
    '109': ['kafirun', 'kafiroon', 'alkafirun', 'al-kafirun', 'orang kafir'],
    '110': ['nasr', 'nashr', 'annasr', 'an-nasr', 'pertolongan'],
    '111': ['lahab', 'masad', 'allahab', 'al-lahab', 'al-masad', 'api'],
    '112': [
      'ikhlas',
      'ikhlash',
      'alikhlas',
      'al-ikhlas',
      'kemurnian',
      'tauhid',
    ],
    '113': ['falaq', 'falaq', 'alfalaq', 'al-falaq', 'waktu subuh'],
    '114': ['nas', 'naas', 'annas', 'an-nas', 'manusia'],
  };

  final Map<int, String> _surahNames = {
    1: 'Al-Fatihah',
    2: 'Al-Baqarah',
    3: 'Ali \'Imran',
    4: 'An-Nisa',
    5: 'Al-Ma\'idah',
    6: 'Al-An\'am',
    7: 'Al-A\'raf',
    8: 'Al-Anfal',
    9: 'At-Taubah',
    10: 'Yunus',
    11: 'Hud',
    12: 'Yusuf',
    13: 'Ar-Ra\'d',
    14: 'Ibrahim',
    15: 'Al-Hijr',
    16: 'An-Nahl',
    17: 'Al-Isra',
    18: 'Al-Kahf',
    19: 'Maryam',
    20: 'Ta-Ha',
    21: 'Al-Anbiya',
    22: 'Al-Hajj',
    23: 'Al-Mu\'minun',
    24: 'An-Nur',
    25: 'Al-Furqan',
    26: 'Asy-Syu\'ara',
    27: 'An-Naml',
    28: 'Al-Qasas',
    29: 'Al-\'Ankabut',
    30: 'Ar-Rum',
    31: 'Luqman',
    32: 'As-Sajdah',
    33: 'Al-Ahzab',
    34: 'Saba\'',
    35: 'Fatir',
    36: 'Yasin',
    37: 'As-Saffat',
    38: 'Sad',
    39: 'Az-Zumar',
    40: 'Ghafir',
    41: 'Fussilat',
    42: 'Asy-Syura',
    43: 'Az-Zukhruf',
    44: 'Ad-Dukhan',
    45: 'Al-Jasiyah',
    46: 'Al-Ahqaf',
    47: 'Muhammad',
    48: 'Al-Fath',
    49: 'Al-Hujurat',
    50: 'Qaf',
    51: 'Az-Zariyat',
    52: 'At-Tur',
    53: 'An-Najm',
    54: 'Al-Qamar',
    55: 'Ar-Rahman',
    56: 'Al-Waqi\'ah',
    57: 'Al-Hadid',
    58: 'Al-Mujadalah',
    59: 'Al-Hasyr',
    60: 'Al-Mumtahanah',
    61: 'As-Saff',
    62: 'Al-Jumu\'ah',
    63: 'Al-Munafiqun',
    64: 'At-Taghabun',
    65: 'At-Talaq',
    66: 'At-Tahrim',
    67: 'Al-Mulk',
    68: 'Al-Qalam',
    69: 'Al-Haqqah',
    70: 'Al-Ma\'arij',
    71: 'Nuh',
    72: 'Al-Jinn',
    73: 'Al-Muzzammil',
    74: 'Al-Muddassir',
    75: 'Al-Qiyamah',
    76: 'Al-Insan',
    77: 'Al-Mursalat',
    78: 'An-Naba',
    79: 'An-Nazi\'at',
    80: '\'Abasa',
    81: 'At-Takwir',
    82: 'Al-Infitar',
    83: 'Al-Mutaffifin',
    84: 'Al-Insyiqaq',
    85: 'Al-Buruj',
    86: 'At-Tariq',
    87: 'Al-A\'la',
    88: 'Al-Ghasyiyah',
    89: 'Al-Fajr',
    90: 'Al-Balad',
    91: 'Asy-Syams',
    92: 'Al-Lail',
    93: 'Ad-Duha',
    94: 'Asy-Syarh',
    95: 'At-Tin',
    96: 'Al-\'Alaq',
    97: 'Al-Qadr',
    98: 'Al-Bayyinah',
    99: 'Az-Zalzalah',
    100: 'Al-\'Adiyat',
    101: 'Al-Qari\'ah',
    102: 'At-Takasur',
    103: 'Al-\'Asr',
    104: 'Al-Humazah',
    105: 'Al-Fil',
    106: 'Quraisy',
    107: 'Al-Ma\'un',
    108: 'Al-Kausar',
    109: 'Al-Kafirun',
    110: 'An-Nasr',
    111: 'Al-Lahab',
    112: 'Al-Ikhlas',
    113: 'Al-Falaq',
    114: 'An-Nas',
  };

  // Fuzzy matching dengan Levenshtein distance
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }
    return v0[s2.length];
  }

  double _calculateSimilarity(String query, String target) {
    query = query.toLowerCase();
    target = target.toLowerCase();

    // Exact match
    if (query == target) return 1.0;

    // Contains match
    if (target.contains(query)) return 0.9;
    if (query.contains(target)) return 0.85;

    // Fuzzy match
    int distance = _levenshteinDistance(query, target);
    int maxLen = query.length > target.length ? query.length : target.length;

    return 1.0 - (distance / maxLen);
  }

  List<SurahSuggestion> findSurahSuggestions(String query) {
    if (query.trim().isEmpty) return [];

    List<SurahSuggestion> suggestions = [];
    String queryLower = query.toLowerCase().trim();

    for (var entry in _surahVariations.entries) {
      int surahNum = int.parse(entry.key);
      List<String> variations = entry.value;

      double maxScore = 0.0;
      for (String variation in variations) {
        double score = _calculateSimilarity(queryLower, variation);
        if (score > maxScore) maxScore = score;
      }

      // Include if score > 0.5 (toleran terhadap typo)
      if (maxScore > 0.5) {
        suggestions.add(
          SurahSuggestion(
            number: surahNum,
            name: _surahNames[surahNum] ?? '',
            arabicName: '', // Will be loaded if needed
            ayatCount: 0, // Will be loaded if needed
            matchScore: maxScore,
          ),
        );
      }
    }

    // Sort by score
    suggestions.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return suggestions.take(5).toList();
  }

  Future<_SurahData> _loadSurahToCache(int surahNumber) async {
    if (_surahCache.containsKey(surahNumber)) {
      return _surahCache[surahNumber]!;
    }

    try {
      final ayahJson = await rootBundle.loadString(
        'assets/quran-json/ayat/arabic_verse_uthmani$surahNumber.json',
      );
      final ayahData = json.decode(ayahJson);

      final translationJson = await rootBundle.loadString(
        'assets/quran-json/terjemahan/$surahNumber.json',
      );
      final translationData = json.decode(translationJson);

      final listSurahJson = await rootBundle.loadString(
        'assets/quran-json/surah/list-surah.json',
      );
      final List<dynamic> listSurah = json.decode(listSurahJson);
      final surahMeta = listSurah.firstWhere(
        (s) => s['id'] == surahNumber,
        orElse: () => null,
      );

      final data = _SurahData(
        id: ayahData['id'] ?? surahNumber,
        name: surahMeta?['ltn'] ?? translationData['name'] ?? '',
        arabicTexts: List<String>.from(ayahData['aya'] ?? []),
        translations: List<String>.from(
          translationData['ayaTranslation'] ?? [],
        ),
      );

      _surahCache[surahNumber] = data;
      return data;
    } catch (e) {
      print('Error loading surah $surahNumber: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? _parseDirectQuery(String query) {
    final trimmed = query.trim().toLowerCase();

    // Format: "9:10"
    final pattern1 = RegExp(r'^(\d+)\s*[:]\s*(\d+)$');
    final match1 = pattern1.firstMatch(trimmed);
    if (match1 != null) {
      return {
        'surah': int.parse(match1.group(1)!),
        'ayat': int.parse(match1.group(2)!),
      };
    }

    // Format: "surat 9 ayat 10"
    final pattern2 = RegExp(
      r'(?:surat|surah|qs\.?)\s*(\d+)\s*(?:ayat|ayah|:)\s*(\d+)',
    );
    final match2 = pattern2.firstMatch(trimmed);
    if (match2 != null) {
      return {
        'surah': int.parse(match2.group(1)!),
        'ayat': int.parse(match2.group(2)!),
      };
    }

    // Smart surah name + ayat (toleran typo)
    final ayatPattern = RegExp(r'(\d+)$');
    final ayatMatch = ayatPattern.firstMatch(trimmed);

    if (ayatMatch != null) {
      String nameQuery = trimmed.replaceAll(ayatMatch.group(0)!, '').trim();
      nameQuery = nameQuery.replaceAll(RegExp(r'\s+ayat\s*'), '').trim();

      var suggestions = findSurahSuggestions(nameQuery);
      if (suggestions.isNotEmpty && suggestions.first.matchScore > 0.7) {
        return {
          'surah': suggestions.first.number,
          'ayat': int.parse(ayatMatch.group(1)!),
        };
      }
    }

    return null;
  }

  // Normalize Arabic text for better matching
  String _normalizeArabic(String text) {
    // Remove diacritical marks (tashkeel)
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  Future<List<SearchResult>> searchAll(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) return [];

    // Direct search
    final directQuery = _parseDirectQuery(trimmed);
    if (directQuery != null) {
      final surahNum = directQuery['surah'] as int;
      final ayatNum = directQuery['ayat'] as int;

      if (surahNum >= 1 && surahNum <= 114) {
        try {
          final surah = await _loadSurahToCache(surahNum);

          if (ayatNum > 0 && ayatNum <= surah.arabicTexts.length) {
            return [
              SearchResult(
                surahNumber: surah.id.toString(),
                surahName: surah.name,
                ayatNumber: ayatNum,
                arabicText: surah.arabicTexts[ayatNum - 1],
                translation: ayatNum <= surah.translations.length
                    ? surah.translations[ayatNum - 1]
                    : '',
                type: SearchResultType.direct,
                relevanceScore: 1.0,
              ),
            ];
          }
        } catch (e) {
          print('Error loading direct query: $e');
        }
      }
      return [];
    }

    // Text search
    if (trimmed.length < 3) return [];

    final results = <SearchResult>[];
    final queryLower = trimmed.toLowerCase();
    final normalizedQuery = _normalizeArabic(trimmed);

    for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
      if (results.length >= _maxResults) break;

      try {
        final surah = await _loadSurahToCache(surahNumber);

        for (int i = 0; i < surah.arabicTexts.length; i++) {
          if (results.length >= _maxResults) break;

          final arabicText = surah.arabicTexts[i];
          final normalizedText = _normalizeArabic(arabicText);
          final translation = i < surah.translations.length
              ? surah.translations[i]
              : '';

          bool matchArabic = normalizedText.contains(normalizedQuery);
          bool matchTranslation = translation.toLowerCase().contains(
            queryLower,
          );

          if (matchArabic || matchTranslation) {
            double score = 0.0;
            if (matchArabic) score += 0.6;
            if (matchTranslation) score += 0.4;

            results.add(
              SearchResult(
                surahNumber: surah.id.toString(),
                surahName: surah.name,
                ayatNumber: i + 1,
                arabicText: arabicText,
                translation: translation,
                type: SearchResultType.text,
                relevanceScore: score,
              ),
            );
          }
        }
      } catch (e) {
        print('Error searching surah $surahNumber: $e');
        continue;
      }
    }

    // Sort by relevance
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  Future<List<SearchResult>> searchByArabicText(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final results = <SearchResult>[];
    final normalizedQuery = _normalizeArabic(trimmed);

    for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
      if (results.length >= _maxResults) break;

      try {
        final surah = await _loadSurahToCache(surahNumber);

        for (int i = 0; i < surah.arabicTexts.length; i++) {
          if (results.length >= _maxResults) break;

          final arabicText = surah.arabicTexts[i];
          final normalizedText = _normalizeArabic(arabicText);

          if (normalizedText.contains(normalizedQuery)) {
            results.add(
              SearchResult(
                surahNumber: surah.id.toString(),
                surahName: surah.name,
                ayatNumber: i + 1,
                arabicText: arabicText,
                translation: i < surah.translations.length
                    ? surah.translations[i]
                    : '',
                type: SearchResultType.text,
                relevanceScore: 0.9,
              ),
            );
          }
        }
      } catch (e) {
        print('Error searching surah $surahNumber: $e');
        continue;
      }
    }

    return results;
  }

  Future<List<SearchResult>> searchByTranslation(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final results = <SearchResult>[];
    final queryLower = trimmed.toLowerCase();

    for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
      if (results.length >= _maxResults) break;

      try {
        final surah = await _loadSurahToCache(surahNumber);

        for (int i = 0; i < surah.translations.length; i++) {
          if (results.length >= _maxResults) break;

          final translation = surah.translations[i];

          if (translation.toLowerCase().contains(queryLower)) {
            results.add(
              SearchResult(
                surahNumber: surah.id.toString(),
                surahName: surah.name,
                ayatNumber: i + 1,
                arabicText: i < surah.arabicTexts.length
                    ? surah.arabicTexts[i]
                    : '',
                translation: translation,
                type: SearchResultType.text,
                relevanceScore: 0.8,
              ),
            );
          }
        }
      } catch (e) {
        print('Error searching surah $surahNumber: $e');
        continue;
      }
    }

    return results;
  }

  // Clear cache if needed
  void clearCache() {
    _surahCache.clear();
  }
}
