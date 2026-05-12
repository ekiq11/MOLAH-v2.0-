// models/juz_model.dart
class JuzModel {
  final int juzNumber;
  final String name;
  final int startPage;
  final String startSurah;
  final String firstWord;
  final List<int> surahIds;

  JuzModel({
    required this.juzNumber,
    required this.name,
    required this.startPage,
    required this.startSurah,
    required this.firstWord,
    required this.surahIds,
  });
}

class JuzData {
  // Data pembagian Juz berdasarkan standar Al-Qur'an
  static final List<JuzModel> allJuz = [
    JuzModel(
      juzNumber: 1,
      name: 'Juz 1',
      startPage: 1,
      startSurah: 'Al-Fatihah',
      firstWord: 'Alhamdu',
      surahIds: [1, 2], // Al-Fatihah - Al-Baqarah (ayat 1-141)
    ),
    JuzModel(
      juzNumber: 2,
      name: 'Juz 2',
      startPage: 22,
      startSurah: 'Al-Baqarah',
      firstWord: 'Sayakulu',
      surahIds: [2], // Al-Baqarah (ayat 142-252)
    ),
    JuzModel(
      juzNumber: 3,
      name: 'Juz 3',
      startPage: 42,
      startSurah: 'Al-Baqarah',
      firstWord: 'Tilka ar-rusulu',
      surahIds: [2, 3], // Al-Baqarah (253-286), Ali 'Imran (1-92)
    ),
    JuzModel(
      juzNumber: 4,
      name: 'Juz 4',
      startPage: 62,
      startSurah: 'Ali \'Imran',
      firstWord: 'Kullu atta\'ami',
      surahIds: [3, 4], // Ali 'Imran (93-200), An-Nisa (1-23)
    ),
    JuzModel(
      juzNumber: 5,
      name: 'Juz 5',
      startPage: 82,
      startSurah: 'An-Nisa',
      firstWord: 'Wal muhsanatu',
      surahIds: [4], // An-Nisa (24-147)
    ),
    JuzModel(
      juzNumber: 6,
      name: 'Juz 6',
      startPage: 102,
      startSurah: 'An-Nisa',
      firstWord: 'Laa yuhibbu',
      surahIds: [4, 5], // An-Nisa (148-176), Al-Ma'idah (1-81)
    ),
    JuzModel(
      juzNumber: 7,
      name: 'Juz 7',
      startPage: 121,
      startSurah: 'Al-Ma\'idah',
      firstWord: 'Latjidanna',
      surahIds: [5, 6], // Al-Ma'idah (82-120), Al-An'am (1-110)
    ),
    JuzModel(
      juzNumber: 8,
      name: 'Juz 8',
      startPage: 142,
      startSurah: 'Al-An\'am',
      firstWord: 'Walaw anna',
      surahIds: [6, 7], // Al-An'am (111-165), Al-A'raf (1-87)
    ),
    JuzModel(
      juzNumber: 9,
      name: 'Juz 9',
      startPage: 162,
      startSurah: 'Al-A\'raf',
      firstWord: 'Qalal mala\'u',
      surahIds: [7, 8], // Al-A'raf (88-206), Al-Anfal (1-40)
    ),
    JuzModel(
      juzNumber: 10,
      name: 'Juz 10',
      startPage: 182,
      startSurah: 'Al-Anfal',
      firstWord: 'Wa\'lamu',
      surahIds: [8, 9], // Al-Anfal (41-75), At-Tawbah (1-92)
    ),
    JuzModel(
      juzNumber: 11,
      name: 'Juz 11',
      startPage: 201,
      startSurah: 'At-Tawbah',
      firstWord: 'Innama assabeelu',
      surahIds: [9, 10, 11], // At-Tawbah (93-129), Yunus, Hud (1-5)
    ),
    JuzModel(
      juzNumber: 12,
      name: 'Juz 12',
      startPage: 222,
      startSurah: 'Hud',
      firstWord: 'Wama min',
      surahIds: [11, 12], // Hud (6-123), Yusuf (1-52)
    ),
    JuzModel(
      juzNumber: 13,
      name: 'Juz 13',
      startPage: 242,
      startSurah: 'Yusuf',
      firstWord: 'Wama ubarrio',
      surahIds: [
        12,
        13,
        14,
        15,
      ], // Yusuf (53-111), Ar-Ra'd, Ibrahim, Al-Hijr (1)
    ),
    JuzModel(
      juzNumber: 14,
      name: 'Juz 14',
      startPage: 262,
      startSurah: 'Al-Hijr',
      firstWord: 'Alif Lam Ra',
      surahIds: [15, 16], // Al-Hijr (2-99), An-Nahl (1-128)
    ),
    JuzModel(
      juzNumber: 15,
      name: 'Juz 15',
      startPage: 282,
      startSurah: 'Al-Isra',
      firstWord: 'Subhana allathee',
      surahIds: [17, 18], // Al-Isra, Al-Kahf (1-74)
    ),
    JuzModel(
      juzNumber: 16,
      name: 'Juz 16',
      startPage: 302,
      startSurah: 'Al-Kahf',
      firstWord: 'Qala alam',
      surahIds: [18, 19, 20], // Al-Kahf (75-110), Maryam, Ta-Ha (1-135)
    ),
    JuzModel(
      juzNumber: 17,
      name: 'Juz 17',
      startPage: 322,
      startSurah: 'Al-Anbiya',
      firstWord: 'Iqtaraba lilnnasi',
      surahIds: [21, 22], // Al-Anbiya, Al-Hajj (1-78)
    ),
    JuzModel(
      juzNumber: 18,
      name: 'Juz 18',
      startPage: 342,
      startSurah: 'Al-Mu\'minun',
      firstWord: 'Qad aflaha',
      surahIds: [23, 24, 25], // Al-Mu'minun, An-Nur, Al-Furqan (1-20)
    ),
    JuzModel(
      juzNumber: 19,
      name: 'Juz 19',
      startPage: 362,
      startSurah: 'Al-Furqan',
      firstWord: 'Waqala allatheena',
      surahIds: [25, 26, 27], // Al-Furqan (21-77), Ash-Shu'ara, An-Naml (1-55)
    ),
    JuzModel(
      juzNumber: 20,
      name: 'Juz 20',
      startPage: 382,
      startSurah: 'An-Naml',
      firstWord: 'Fama kana',
      surahIds: [27, 28, 29], // An-Naml (56-93), Al-Qasas, Al-'Ankabut (1-45)
    ),
    JuzModel(
      juzNumber: 21,
      name: 'Juz 21',
      startPage: 402,
      startSurah: 'Al-Ankabut',
      firstWord: 'Wala tujadiloo',
      surahIds: [
        29,
        30,
        31,
        32,
        33,
      ], // Al-'Ankabut (46-69), Ar-Rum, Luqman, As-Sajdah, Al-Ahzab (1-30)
    ),
    JuzModel(
      juzNumber: 22,
      name: 'Juz 22',
      startPage: 422,
      startSurah: 'Al-Ahzab',
      firstWord: 'Waman yaqnut',
      surahIds: [
        33,
        34,
        35,
        36,
      ], // Al-Ahzab (31-73), Saba, Fatir, Ya-Sin (1-27)
    ),
    JuzModel(
      juzNumber: 23,
      name: 'Juz 23',
      startPage: 442,
      startSurah: 'Ya-Sin',
      firstWord: 'Wama anzalna',
      surahIds: [
        36,
        37,
        38,
        39,
      ], // Ya-Sin (28-83), As-Saffat, Sad, Az-Zumar (1-31)
    ),
    JuzModel(
      juzNumber: 24,
      name: 'Juz 24',
      startPage: 462,
      startSurah: 'Az-Zumar',
      firstWord: 'Faman athlam',
      surahIds: [39, 40, 41], // Az-Zumar (32-75), Ghafir, Fussilat (1-46)
    ),
    JuzModel(
      juzNumber: 25,
      name: 'Juz 25',
      startPage: 482,
      startSurah: 'Fussilat',
      firstWord: 'Ilayhi yuraddu',
      surahIds: [
        41,
        42,
        43,
        44,
        45,
      ], // Fussilat (47-54), Ash-Shura, Az-Zukhruf, Ad-Dukhan, Al-Jathiyah
    ),
    JuzModel(
      juzNumber: 26,
      name: 'Juz 26',
      startPage: 502,
      startSurah: 'Al-Ahqaf',
      firstWord: 'Ha Meem tanzeel',
      surahIds: [
        46,
        47,
        48,
        49,
        50,
        51,
      ], // Al-Ahqaf, Muhammad, Al-Fath, Al-Hujurat, Qaf, Adh-Dhariyat (1-30)
    ),
    JuzModel(
      juzNumber: 27,
      name: 'Juz 27',
      startPage: 522,
      startSurah: 'Adh-Dhariyat',
      firstWord: 'Qala fama khatbukum',
      surahIds: [
        51,
        52,
        53,
        54,
        55,
        56,
        57,
      ], // Adh-Dhariyat (31-60), At-Tur, An-Najm, Al-Qamar, Ar-Rahman, Al-Waqi'ah, Al-Hadid
    ),
    JuzModel(
      juzNumber: 28,
      name: 'Juz 28',
      startPage: 542,
      startSurah: 'Al-Mujadila',
      firstWord: 'Qad sami',
      surahIds: [58, 59, 60, 61, 62, 63, 64, 65, 66], // Al-Mujadila - At-Tahrim
    ),
    JuzModel(
      juzNumber: 29,
      name: 'Juz 29',
      startPage: 562,
      startSurah: 'Al-Mulk',
      firstWord: 'Tabarak',
      surahIds: [
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
      ], // Al-Mulk - Al-Mursalat
    ),
    JuzModel(
      juzNumber: 30,
      name: 'Juz 30 (Juz Amma)',
      startPage: 582,
      startSurah: 'An-Naba\'',
      firstWord: 'Amma',
      surahIds: [
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99,
        100,
        101,
        102,
        103,
        104,
        105,
        106,
        107,
        108,
        109,
        110,
        111,
        112,
        113,
        114,
      ], // An-Naba - An-Nas
    ),
  ];

  // Helper methods
  static JuzModel? getJuzByNumber(int juzNumber) {
    try {
      return allJuz.firstWhere((juz) => juz.juzNumber == juzNumber);
    } catch (e) {
      return null;
    }
  }

  static int? getJuzBySurahId(int surahId) {
    for (var juz in allJuz) {
      if (juz.surahIds.contains(surahId)) {
        return juz.juzNumber;
      }
    }
    return null;
  }

  static List<int> getSurahIdsByJuz(int juzNumber) {
    final juz = getJuzByNumber(juzNumber);
    return juz?.surahIds ?? [];
  }

  static String getJuzName(int juzNumber) {
    final juz = getJuzByNumber(juzNumber);
    return juz?.name ?? 'Juz $juzNumber';
  }
}
