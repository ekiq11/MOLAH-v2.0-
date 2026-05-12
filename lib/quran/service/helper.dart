// quran/utils/audio_timestamps.dart (optional)
class AudioTimestamps {
  // Data estimasi timestamp per surah (dalam detik)
  // Ini adalah data dummy, Anda perlu data yang akurat untuk implementasi nyata
  static const Map<int, List<double>> surahTimestamps = {
    1: [0, 3, 6, 9, 12, 15, 18, 21], // Contoh untuk Al-Fatihah
    2: [0, 5, 10, 15, 20, 25, 30, 35], // Contoh untuk Al-Baqarah
    // Tambahkan data untuk surah lainnya...
  };

  static Duration getAyahStartTime(int surahNumber, int ayahNumber) {
    final timestamps = surahTimestamps[surahNumber];
    if (timestamps != null && ayahNumber <= timestamps.length) {
      return Duration(seconds: timestamps[ayahNumber - 1].toInt());
    }

    // Fallback: estimasi kasar
    const double averageAyahDuration = 5.5;
    final seconds = (ayahNumber - 1) * averageAyahDuration;
    return Duration(seconds: seconds.toInt());
  }
}
