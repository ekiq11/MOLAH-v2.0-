import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pizab_molah/screens/HafalanHistoryPage.dart';
import 'package:intl/intl.dart';

class HafalanPdfGenerator {
  HafalanPdfGenerator._();

  static Future<Uint8List> generate({
    required String nisn,
    required String namaSantri,
    required List<HafalanData> hafalanList,
    String? asrama,
    String? kelas,
  }) async {
    // Load Logo
    final logoBytes = await rootBundle.load('assets/img/molah.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final doc = pw.Document(
      title: 'Laporan Hafalan - $namaSantri',
      author: 'PIZAB MOLAH',
      creator: 'PIZAB MOLAH v1.0',
    );

    // Filter hafalan (hanya menampilkan 50 terbaru untuk menghindari error size)
    final printList = hafalanList.take(50).toList();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
        ),
        header: (ctx) => _buildHeader(
          ctx, 
          logoImage, 
          namaSantri, 
          nisn,
          kelas ?? '-',
          asrama ?? '-',
        ),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 20),
          _buildSummaryStats(hafalanList),
          pw.SizedBox(height: 20),
          _buildDataTable(printList),
          if (hafalanList.length > 50) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              '*Hanya menampilkan 50 setoran terakhir',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ]
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader(
    pw.Context ctx, 
    pw.ImageProvider logo, 
    String nama, 
    String nisn,
    String kelas,
    String asrama,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(
              width: 50,
              height: 50,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LAPORAN PROGRES HAFALAN QURAN',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Sistem Informasi Akademik PIZAB MOLAH',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(color: PdfColors.grey400, thickness: 1),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nama Santri', nama),
                _buildInfoRow('NISN', nisn),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Kelas', kelas),
                _buildInfoRow('Asrama', asrama),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ),
          pw.Text(
            ':  ',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryStats(List<HafalanData> list) {
    int countA = list.where((e) => e.nilai.toUpperCase() == 'A').length;
    int countB = list.where((e) => e.nilai.toUpperCase() == 'B').length;
    int countC = list.where((e) => e.nilai.toUpperCase() == 'C').length;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Setoran', '${list.length}x'),
          _buildStatItem('Nilai A (Jayyid Jiddan)', '$countA'),
          _buildStatItem('Nilai B (Jayyid)', '$countB'),
          _buildStatItem('Nilai C (Maqbul)', '$countC'),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDataTable(List<HafalanData> list) {
    return pw.TableHelper.fromTextArray(
      context: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.green700,
      ),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      data: <List<String>>[
        // Header
        ['Tanggal', 'Surah/Ayat', 'Nilai', 'Musyrif', 'Keterangan'],
        // Data
        ...list.map((item) {
          final hafalan = '${item.surahAwal} ${item.ayatAwal} - ${item.surahAkhir} ${item.ayatAkhir}';
          return [
            '${item.tanggal} ${item.waktu}',
            hafalan,
            item.nilai,
            item.mustami,
            item.keterangan,
          ];
        }),
      ],
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    final now = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400, thickness: 1),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dicetak pada: $now',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }
}
