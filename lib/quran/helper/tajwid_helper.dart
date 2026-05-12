// quran/helper/tajwid_helper.dart - ✅ FIXED: 100% Consistent size ON/OFF
import 'package:flutter/material.dart';

class TajwidHelper {
  // ==================== WARNA TAJWID PROFESIONAL ====================

  // Hukum Nun Sukun & Tanwin
  static const Color izharColor = Color(0xFF10B981); // Emerald
  static const Color idghamColor = Color(0xFF3B82F6); // Blue
  static const Color idghamGhunnahColor = Color(0xFF2563EB); // Blue-dark
  static const Color iqlaabColor = Color(0xFFEC4899); // Pink
  static const Color ikhfaColor = Color(0xFFF59E0B); // Amber

  // Hukum Mim Sukun
  static const Color mimIzharColor = Color(0xFF14B8A6); // Teal
  static const Color mimIdghamColor = Color(0xFF06B6D4); // Cyan
  static const Color ikhfaShafawiColor = Color(0xFFFB923C); // Orange

  // Hukum Mad
  static const Color madThobiiColor = Color(0xFFDC2626); // Red
  static const Color madWajibColor = Color(0xFF991B1B); // Red-dark
  static const Color madJaizColor = Color(0xFFF97316); // Orange
  static const Color madLazimColor = Color(0xFF7F1D1D); // Red-darkest
  static const Color madAridColor = Color(0xFFEA580C); // Orange-dark
  static const Color madLinColor = Color(0xFFC2410C); // Orange-darker

  // Hukum Lainnya
  static const Color ghunnahColor = Color(0xFF059669); // Emerald-dark
  static const Color qalqalahColor = Color(0xFF0891B2); // Cyan-dark
  static const Color lafalahColor = Color(0xFF9333EA); // Purple
  static const Color raColor = Color(0xFF7C3AED); // Violet
  static const Color lamTarifColor = Color(0xFF6366F1); // Indigo

  // ==================== HURUF-HURUF KHUSUS ====================

  static const List<String> hurufIzhar = ['ء', 'ه', 'ع', 'ح', 'غ', 'خ'];
  static const List<String> hurufIdghamBilaGhunnah = ['ل', 'ر'];
  static const List<String> hurufIdghamBighunnah = ['ي', 'ن', 'م', 'و'];
  static const List<String> hurufIkhfa = [
    'ص',
    'ذ',
    'ث',
    'ك',
    'ج',
    'ش',
    'ق',
    'س',
    'د',
    'ط',
    'ز',
    'ف',
    'ت',
    'ض',
    'ظ',
  ];
  static const List<String> hurufQalqalah = ['ق', 'ط', 'ب', 'ج', 'د'];

  static const List<String> harakat = [
    'َ',
    'ِ',
    'ُ',
    'ً',
    'ٍ',
    'ٌ',
    'ْ',
    'ّ',
    'ٰ',
    'ٓ',
    'ٔ',
    'ٕ',
    '۟',
    '۠',
    'ۡ',
    'ۢ',
    'ۣ',
    'ۤ',
    'ۥ',
    'ۦ',
    'ۧ',
    'ۨ',
    '۪',
    '۫',
    '۬',
    'ۭ',
  ];

  // ✅ ULTIMATE FIX: Hapus shadow yang bikin perbedaan ukuran
  // Return TextSpan biasa saja, warna sudah cukup
  static TextSpan buildTajwidText(
    String arabicText, {
    required TextStyle baseStyle,
    bool enableTajwid = true,
  }) {
    if (!enableTajwid || arabicText.trim().isEmpty) {
      return TextSpan(text: arabicText, style: baseStyle);
    }

    final words = arabicText.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      final processedWord = _processWordWithColor(word, baseStyle);
      spans.add(processedWord);

      if (i < words.length - 1) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
      }
    }

    return TextSpan(children: spans);
  }

  static TextSpan _processWordWithColor(String word, TextStyle baseStyle) {
    if (word.isEmpty) return TextSpan(text: word, style: baseStyle);

    final tajwidRanges = _findAllTajwidRanges(word);

    if (tajwidRanges.isEmpty) {
      return TextSpan(text: word, style: baseStyle);
    }

    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (var range in tajwidRanges) {
      // Teks sebelum tajwid
      if (currentIndex < range.start) {
        spans.add(
          TextSpan(
            text: word.substring(currentIndex, range.start),
            style: baseStyle,
          ),
        );
      }

      // ✅ CLEAN FIX: Hanya warna saja, tanpa shadow
      // Ini 100% tidak mengubah layout/ukuran
      spans.add(
        TextSpan(
          text: word.substring(range.start, range.end),
          style: baseStyle.copyWith(color: range.color),
        ),
      );

      currentIndex = range.end;
    }

    // Sisa teks
    if (currentIndex < word.length) {
      spans.add(TextSpan(text: word.substring(currentIndex), style: baseStyle));
    }

    return TextSpan(children: spans);
  }

  // ==================== FIND ALL TAJWID RANGES ====================
  static List<TajwidRange> _findAllTajwidRanges(String word) {
    final ranges = <TajwidRange>[];

    ranges.addAll(_findLafzatullah(word));
    ranges.addAll(_findGhunnah(word));
    ranges.addAll(_findNunSukun(word));
    ranges.addAll(_findTanwin(word));
    ranges.addAll(_findMimSukun(word));
    ranges.addAll(_findQalqalah(word));
    ranges.addAll(_findMad(word));

    ranges.sort((a, b) => a.start.compareTo(b.start));
    return _mergeOverlappingRanges(ranges);
  }

  // ==================== FIND METHODS ====================

  static List<TajwidRange> _findLafzatullah(String word) {
    final ranges = <TajwidRange>[];
    final patterns = [
      'بِٱللَّه',
      'لِلَّهِ',
      'ٱللَّه',
      'اللَّه',
      'لِلَّه',
      'ٱللَّٰهُ',
    ];

    for (var pattern in patterns) {
      int index = word.indexOf(pattern);
      while (index != -1) {
        ranges.add(
          TajwidRange(
            start: index,
            end: index + pattern.length,
            color: lafalahColor,
            rule: 'Lafzatullah',
          ),
        );
        index = word.indexOf(pattern, index + 1);
      }
    }

    return ranges;
  }

  static List<TajwidRange> _findGhunnah(String word) {
    final ranges = <TajwidRange>[];

    for (int i = 0; i < word.length - 1; i++) {
      final char = word[i];
      final next = word[i + 1];

      if ((char == 'ن' || char == 'م') && next == 'ّ') {
        int end = i + 2;
        while (end < word.length && harakat.contains(word[end])) {
          end++;
        }

        ranges.add(
          TajwidRange(
            start: i,
            end: end,
            color: ghunnahColor,
            rule: 'Ghunnah Musyaddadah',
          ),
        );
      }
    }

    return ranges;
  }

  static List<TajwidRange> _findNunSukun(String word) {
    final ranges = <TajwidRange>[];

    for (int i = 0; i < word.length - 1; i++) {
      if (word[i] == 'ن' && word[i + 1] == 'ْ') {
        int end = i + 2;
        while (end < word.length && harakat.contains(word[end])) {
          end++;
        }

        final nextLetter = _getNextMeaningfulLetter(word, end);
        final color = _getNunSukunColor(nextLetter);

        ranges.add(
          TajwidRange(
            start: i,
            end: end,
            color: color,
            rule: _getNunSukunRuleName(nextLetter),
          ),
        );
      }
    }

    return ranges;
  }

  static List<TajwidRange> _findTanwin(String word) {
    final ranges = <TajwidRange>[];

    for (int i = 0; i < word.length; i++) {
      final char = word[i];

      if ('ًٌٍ'.contains(char)) {
        int end = i + 1;
        while (end < word.length && harakat.contains(word[end])) {
          end++;
        }

        final nextLetter = _getNextMeaningfulLetter(word, end);
        final color = _getTanwinColor(nextLetter);

        ranges.add(
          TajwidRange(
            start: i,
            end: end,
            color: color,
            rule: _getTanwinRuleName(nextLetter),
          ),
        );
      }
    }

    return ranges;
  }

  static List<TajwidRange> _findMimSukun(String word) {
    final ranges = <TajwidRange>[];

    for (int i = 0; i < word.length - 1; i++) {
      if (word[i] == 'م' && word[i + 1] == 'ْ') {
        int end = i + 2;
        while (end < word.length && harakat.contains(word[end])) {
          end++;
        }

        final nextLetter = _getNextMeaningfulLetter(word, end);
        Color color;
        String rule;

        if (nextLetter == 'ب') {
          color = ikhfaShafawiColor;
          rule = 'Ikhfa Syafawi';
        } else if (nextLetter == 'م') {
          color = mimIdghamColor;
          rule = 'Idgham Mimi';
        } else {
          color = mimIzharColor;
          rule = 'Izhar Syafawi';
        }

        ranges.add(TajwidRange(start: i, end: end, color: color, rule: rule));
      }
    }

    return ranges;
  }

  static List<TajwidRange> _findQalqalah(String word) {
    final ranges = <TajwidRange>[];

    for (int i = 0; i < word.length; i++) {
      final char = word[i];

      if (hurufQalqalah.contains(char)) {
        bool hasQalqalah = false;
        int end = i + 1;

        if (i + 1 < word.length && word[i + 1] == 'ْ') {
          hasQalqalah = true;
          end = i + 2;
        } else {
          int tempEnd = i + 1;
          while (tempEnd < word.length && harakat.contains(word[tempEnd])) {
            tempEnd++;
          }
          if (tempEnd == word.length) {
            hasQalqalah = true;
            end = tempEnd;
          }
        }

        if (hasQalqalah) {
          ranges.add(
            TajwidRange(
              start: i,
              end: end,
              color: qalqalahColor,
              rule: 'Qalqalah',
            ),
          );
        }
      }
    }

    return ranges;
  }

  static List<TajwidRange> _findMad(String word) {
    final ranges = <TajwidRange>[];

    for (int i = 0; i < word.length; i++) {
      final char = word[i];

      if (char == 'ى') {
        int end = i + 1;
        while (end < word.length && harakat.contains(word[end])) {
          end++;
        }
        ranges.add(
          TajwidRange(
            start: i,
            end: end,
            color: madThobiiColor,
            rule: 'Mad Thobi\'i',
          ),
        );
      } else if (char == 'آ') {
        int end = i + 1;
        while (end < word.length && harakat.contains(word[end])) {
          end++;
        }
        ranges.add(
          TajwidRange(
            start: i,
            end: end,
            color: madWajibColor,
            rule: 'Mad Wajib',
          ),
        );
      } else if (char == 'ا' && i > 0) {
        final prevChar = word[i - 1];
        if (_hasFathah(prevChar) || prevChar == 'َ') {
          int start = i - 1;
          int end = i + 1;
          while (end < word.length && harakat.contains(word[end])) {
            end++;
          }
          ranges.add(
            TajwidRange(
              start: start,
              end: end,
              color: madThobiiColor,
              rule: 'Mad Thobi\'i',
            ),
          );
        }
      } else if (char == 'و' && i > 0) {
        final prevChar = word[i - 1];
        if (_hasDhammah(prevChar) || prevChar == 'ُ') {
          int start = i - 1;
          int end = i + 1;
          while (end < word.length && harakat.contains(word[end])) {
            end++;
          }
          ranges.add(
            TajwidRange(
              start: start,
              end: end,
              color: madThobiiColor,
              rule: 'Mad Thobi\'i',
            ),
          );
        }
      } else if (char == 'ي' && i > 0) {
        final prevChar = word[i - 1];
        if (_hasKasrah(prevChar) || prevChar == 'ِ') {
          int start = i - 1;
          int end = i + 1;
          while (end < word.length && harakat.contains(word[end])) {
            end++;
          }
          ranges.add(
            TajwidRange(
              start: start,
              end: end,
              color: madThobiiColor,
              rule: 'Mad Thobi\'i',
            ),
          );
        }
      }
    }

    return ranges;
  }

  // ==================== HELPER METHODS ====================

  static List<TajwidRange> _mergeOverlappingRanges(List<TajwidRange> ranges) {
    if (ranges.isEmpty) return ranges;

    final merged = <TajwidRange>[];
    TajwidRange current = ranges[0];

    for (int i = 1; i < ranges.length; i++) {
      final next = ranges[i];

      if (next.start < current.end) {
        if (next.end > current.end) {
          current = TajwidRange(
            start: current.start,
            end: next.end,
            color: current.color,
            rule: current.rule,
          );
        }
      } else {
        merged.add(current);
        current = next;
      }
    }

    merged.add(current);
    return merged;
  }

  static String? _getNextMeaningfulLetter(String word, int startIndex) {
    for (int i = startIndex; i < word.length; i++) {
      final char = word[i];
      if (!harakat.contains(char)) {
        return char;
      }
    }
    return null;
  }

  static Color _getNunSukunColor(String? nextLetter) {
    if (nextLetter == null) return ikhfaColor;
    if (hurufIzhar.contains(nextLetter)) return izharColor;
    if (nextLetter == 'ب') return iqlaabColor;
    if (hurufIdghamBilaGhunnah.contains(nextLetter)) return idghamColor;
    if (hurufIdghamBighunnah.contains(nextLetter)) return idghamGhunnahColor;
    if (hurufIkhfa.contains(nextLetter)) return ikhfaColor;
    return ikhfaColor;
  }

  static String _getNunSukunRuleName(String? nextLetter) {
    if (nextLetter == null) return 'Ikhfa';
    if (hurufIzhar.contains(nextLetter)) return 'Izhar Halqi';
    if (nextLetter == 'ب') return 'Iqlab';
    if (hurufIdghamBilaGhunnah.contains(nextLetter)) {
      return 'Idgham Bila Ghunnah';
    }
    if (hurufIdghamBighunnah.contains(nextLetter)) return 'Idgham Bighunnah';
    if (hurufIkhfa.contains(nextLetter)) return 'Ikhfa Haqiqi';
    return 'Ikhfa';
  }

  static Color _getTanwinColor(String? nextLetter) {
    return _getNunSukunColor(nextLetter);
  }

  static String _getTanwinRuleName(String? nextLetter) {
    return _getNunSukunRuleName(nextLetter);
  }

  static bool _hasFathah(String char) {
    return char.contains('َ') || char.contains('ً');
  }

  static bool _hasDhammah(String char) {
    return char.contains('ُ') || char.contains('ٌ');
  }

  static bool _hasKasrah(String char) {
    return char.contains('ِ') || char.contains('ٍ');
  }

  // ==================== TAJWID LEGEND ====================
  static List<TajwidLegend> getTajwidLegends() {
    return [
      TajwidLegend(
        category: 'Hukum Nun Sukun & Tanwin',
        color: izharColor,
        name: 'Izhar Halqi',
        description: 'Nun sukun/tanwin bertemu 6 huruf halqi (ء ه ع ح غ خ)',
        example: 'مِنْ هَادٍ، مَنْ عَمِلَ',
        rule: 'Dibaca jelas tanpa dengung',
      ),
      TajwidLegend(
        category: 'Hukum Nun Sukun & Tanwin',
        color: idghamColor,
        name: 'Idgham Bila Ghunnah',
        description: 'Nun sukun/tanwin bertemu ل atau ر',
        example: 'مِنْ رَبِّهِمْ، هُدًى لِّلْمُتَّقِينَ',
        rule: 'Dilebur tanpa dengung, 2 harakat',
      ),
      TajwidLegend(
        category: 'Hukum Nun Sukun & Tanwin',
        color: idghamGhunnahColor,
        name: 'Idgham Bighunnah',
        description: 'Nun sukun/tanwin bertemu ي ن م و',
        example: 'مَنْ يَعْمَلْ، عَلِيمٌ مُّبِينٌ',
        rule: 'Dilebur dengan dengung, 2 harakat',
      ),
      TajwidLegend(
        category: 'Hukum Nun Sukun & Tanwin',
        color: iqlaabColor,
        name: 'Iqlab',
        description: 'Nun sukun/tanwin bertemu ب',
        example: 'مِنْ بَعْدِ، سَمِيعٌۢ بَصِيرٌ',
        rule: 'Diubah jadi Mim, dengung 2 harakat',
      ),
      TajwidLegend(
        category: 'Hukum Nun Sukun & Tanwin',
        color: ikhfaColor,
        name: 'Ikhfa Haqiqi',
        description: 'Nun sukun/tanwin bertemu 15 huruf ikhfa',
        example: 'مِنْ شَرِّ، يَوْمَئِذٍ صَافَّةً',
        rule: 'Samar dengan dengung, 2 harakat',
      ),
      TajwidLegend(
        category: 'Hukum Mim Sukun',
        color: ikhfaShafawiColor,
        name: 'Ikhfa Syafawi',
        description: 'Mim sukun bertemu ب',
        example: 'تَرْمِيهِمْ بِحِجَارَةٍ',
        rule: 'Samar dengan dengung bibir, 2 harakat',
      ),
      TajwidLegend(
        category: 'Hukum Mim Sukun',
        color: mimIdghamColor,
        name: 'Idgham Mimi',
        description: 'Mim sukun bertemu م',
        example: 'لَكُمْ مَّا كَسَبْتُمْ',
        rule: 'Dilebur dengan dengung, 2 harakat',
      ),
      TajwidLegend(
        category: 'Hukum Mim Sukun',
        color: mimIzharColor,
        name: 'Izhar Syafawi',
        description: 'Mim sukun bertemu selain ب dan م',
        example: 'وَلَهُمْ فِيهَا، هُمْ فِيهَا',
        rule: 'Dibaca jelas dari bibir',
      ),
      TajwidLegend(
        category: 'Hukum Ghunnah',
        color: ghunnahColor,
        name: 'Ghunnah Musyaddadah',
        description: 'Nun atau Mim bertasydid',
        example: 'إِنَّ، ثُمَّ، النَّاسِ',
        rule: 'Dengung sempurna, 2 harakat',
      ),
      TajwidLegend(
        category: 'Hukum Mad',
        color: madThobiiColor,
        name: 'Mad Thobi\'i',
        description: 'Panjang alami (alif, waw, ya)',
        example: 'قَالَ، يَقُولُ، قِيلَ',
        rule: '1 alif / 2 harakat',
      ),
      TajwidLegend(
        category: 'Hukum Mad',
        color: madWajibColor,
        name: 'Mad Wajib Muttashil',
        description: 'Mad + hamzah dalam 1 kata',
        example: 'جَآءَ، سَآءَ، السَّمَآءِ',
        rule: '2.5 alif / 5 harakat wajib',
      ),
      TajwidLegend(
        category: 'Hukum Qalqalah',
        color: qalqalahColor,
        name: 'Qalqalah',
        description: 'Huruf memantul (ق ط ب ج د)',
        example: 'يَخْلُقُ، أَحَطتُّ، لَمْ يَلِدْ',
        rule: 'Dipantulkan tanpa vokal',
      ),
      TajwidLegend(
        category: 'Lafzatullah',
        color: lafalahColor,
        name: 'Lafzatullah',
        description: 'Nama Allah SWT',
        example: 'ٱللَّهُ، بِٱللَّهِ، لِلَّهِ',
        rule: 'Dibaca dengan pengagungan',
      ),
    ];
  }

  static Map<String, List<TajwidLegend>> getTajwidLegendsByCategory() {
    final legends = getTajwidLegends();
    final Map<String, List<TajwidLegend>> grouped = {};

    for (var legend in legends) {
      if (!grouped.containsKey(legend.category)) {
        grouped[legend.category] = [];
      }
      grouped[legend.category]!.add(legend);
    }

    return grouped;
  }
}

// ==================== MODEL ====================
class TajwidRange {
  final int start;
  final int end;
  final Color color;
  final String rule;

  TajwidRange({
    required this.start,
    required this.end,
    required this.color,
    required this.rule,
  });
}

class TajwidLegend {
  final String category;
  final Color color;
  final String name;
  final String description;
  final String example;
  final String rule;

  TajwidLegend({
    required this.category,
    required this.color,
    required this.name,
    required this.description,
    required this.example,
    required this.rule,
  });
}
