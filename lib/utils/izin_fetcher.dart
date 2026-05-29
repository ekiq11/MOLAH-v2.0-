import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/izin_model.dart';

class IzinFetcher {
  static const String _csvUrl = 'https://docs.google.com/spreadsheets/d/1lhpKDk7jojvn4DQEhhXMoEZW5m100pz4sQjsVGVmTm0/export?format=csv&gid=1930710330';

  // Menyimpan data mockup untuk simulasi jika URL belum diganti
  static const String _mockCsvData = '''
Tanggal,Waktu Izin,NISN,Nama,KelasAsrama,Tanggal Izin,Batas Izin,Alasan Izin,Tanggal Balik,Waktu Balik,Status,Keterangan
26/4/2026,10:09:08,0120251003,AHMAD ABUD,/ALI BIN ABI THALIB,26/4/2026,26/4/2026 12:00:00,Izin keluar,22/5/2026,18:29:01,Sudah Balik Ke Pondok,Tepat Waktu
26/4/2026,9:44:22,0120251012,ILHAM APRIAN,/THALHAH BIN UBAIDILLAH,26/4/2026,26/4/2026 12:00:00,rawat gigi,22/5/2026,18:28:41,Sudah Balik Ke Pondok,Tepat Waktu
''';

  static Future<List<IzinModel>> fetchRiwayatIzin(String nisn) async {
    try {
      String csvBody = '';

      if (_csvUrl.contains('PLACEHOLDER_URL')) {
        // Gunakan mock data jika URL belum diset
        csvBody = _mockCsvData;
        await Future.delayed(const Duration(milliseconds: 800)); // Simulasi network
      } else {
        final response = await http.get(Uri.parse(_csvUrl));
        if (response.statusCode == 200) {
          csvBody = response.body;
        } else {
          throw Exception('Gagal memuat data perizinan. Status: ${response.statusCode}');
        }
      }

      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvBody);
      List<IzinModel> riwayatIzin = [];

      for (var row in csvTable) {
        if (row.length > 2) { // Baris header skip bisa dilakukan dengan if (row[0].toString().toLowerCase().contains('tanggal'))
          if (row[0].toString().toLowerCase().contains('tanggal')) continue;

          // NISN di kolom index 2
          String rowNisn = row[2].toString().trim();
          String targetNisn = nisn.trim();

          // Pengecekan matching yang sama dengan fetcher_data.dart
          bool isMatch = false;
          if (rowNisn == targetNisn) {
            isMatch = true;
          } else if (rowNisn == targetNisn.replaceFirst(RegExp(r'^0+'), '')) {
            isMatch = true;
          } else if (rowNisn.padLeft(targetNisn.length, '0') == targetNisn) {
            isMatch = true;
          }

          if (isMatch) {
            riwayatIzin.add(IzinModel.fromCsv(row));
          }
        }
      }

      // Sort dari yang terbaru ke terlama berdasarkan index atau timestamp kasar
      // Karena id kolom pertama biasanya incremental (2,3,4...), kita bisa balik urutannya
      return riwayatIzin.reversed.toList();

    } catch (e) {
      throw Exception('Gagal memproses data perizinan: $e');
    }
  }

  // Mendapatkan status izin aktif (jika santri sedang izin)
  static Future<IzinModel?> getIzinAktif(String nisn) async {
    final riwayat = await fetchRiwayatIzin(nisn);
    if (riwayat.isEmpty) return null;

    // Karena data biasanya berurut dari atas ke bawah (terlama ke terbaru di sheet)
    // kita gunakan reversed agar yang terbaru ada di atas.
    // Jika data terbaru isSedangIzin, berarti santri sedang izin
    final dataTerbaru = riwayat.first;
    if (dataTerbaru.isSedangIzin) {
      return dataTerbaru;
    }
    
    return null; // Sedang di pondok
  }
}
