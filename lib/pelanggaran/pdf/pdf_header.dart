// ─────────────────────────────────────────────────────────────────────────────
// lib/pelanggaran/pdf/pdf_header.dart
// Header & footer tiap halaman + load logo assets/img/molah.png
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_colors.dart';
import 'pdf_models.dart';

// ─────────────────────────────────────────────
//  LOAD LOGO DARI ASSET
// ─────────────────────────────────────────────

Future<pw.ImageProvider> loadAppLogo() async {
  final bytes = await rootBundle.load('assets/img/molah.png');
  return pw.MemoryImage(bytes.buffer.asUint8List());
}

// ─────────────────────────────────────────────
//  PAGE THEME  (header + footer tiap halaman)
// ─────────────────────────────────────────────

pw.PageTheme buildPageTheme() {
  return pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(14, 14, 14, 14),
    buildBackground: (_) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Container(color: Clr.pageBg),
    ),
  );
}

/// Header widget — dipanggil dari MultiPage.header
pw.Widget buildPageHeader({
  required pw.ImageProvider logo,
  required LaporanPayload laporan,
  required pw.Context ctx,
  required int totalPages,
}) => _header(
  logo: logo,
  laporan: laporan,
  pageNum: ctx.pageNumber,
  totalPages: totalPages,
);

/// Footer widget — dipanggil dari MultiPage.footer
pw.Widget buildPageFooter(pw.Context ctx, LaporanPayload laporan) =>
    _footer(laporan);

// ─────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────

pw.Widget _header({
  required pw.ImageProvider logo,
  required LaporanPayload laporan,
  required int pageNum,
  required int totalPages,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      // ── Bar merah atas ─────────────────────────────
      pw.Container(
        height: 10,
        color: Clr.red,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'PIZAB MOLAH | SISTEM INFORMASI PESANTREN',
          style: pw.TextStyle(
            color: Clr.white,
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),

      // ── Panel putih ────────────────────────────────
      pw.Container(
        decoration: pw.BoxDecoration(
          color: Clr.white,
          border: pw.Border.all(color: Clr.border, width: 0.8),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        padding: const pw.EdgeInsets.fromLTRB(8, 7, 8, 5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Baris logo + judul + halaman
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo molah.png
                pw.SizedBox(
                  width: 30,
                  height: 30,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 8),

                // Judul
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LAPORAN REWARD & PELANGGARAN SANTRI',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: Clr.ink,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Diterbitkan resmi oleh Sistem PIZAB MOLAH  |  Data telah diverifikasi & dapat dipertanggungjawabkan',
                        style: pw.TextStyle(fontSize: 6.5, color: Clr.muted),
                      ),
                    ],
                  ),
                ),

                // Badge halaman
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: Clr.redLight,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: Clr.red, width: 0.5),
                  ),
                  child: pw.Text(
                    'Hal  $pageNum / $totalPages',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: Clr.red,
                    ),
                  ),
                ),
              ],
            ),

            // Divider
            pw.SizedBox(height: 5),
            pw.Divider(color: Clr.border, thickness: 0.5),
            pw.SizedBox(height: 4),

            // Info santri
            pw.Row(
              children: [
                _infoCell('NAMA SANTRI', laporan.namaSantri),
                pw.SizedBox(width: 10),
                _infoCell('NISN', laporan.nisn),
                pw.SizedBox(width: 10),
                _infoCell('KELAS / ASRAMA', laporan.kelasAsrama),
                pw.SizedBox(width: 10),
                _infoCell('TAHUN AJARAN', laporan.tahunAjaran),
              ],
            ),
            pw.SizedBox(height: 4),
          ],
        ),
      ),
      pw.SizedBox(height: 7),
    ],
  );
}

pw.Widget _infoCell(String label, String value) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 6, color: Clr.muted)),
        pw.SizedBox(height: 1.5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: Clr.ink,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  FOOTER
// ─────────────────────────────────────────────

pw.Widget _footer(LaporanPayload laporan) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Divider(color: Clr.border, thickness: 0.5),
      pw.SizedBox(height: 2),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ID Dokumen: ${laporan.docId}  |  Dicetak: ${laporan.timestampStr}',
            style: pw.TextStyle(fontSize: 6, color: Clr.muted),
          ),
          pw.Text(
            '© PIZAB MOLAH | Data sah & dapat dipertanggungjawabkan',
            style: pw.TextStyle(fontSize: 6, color: Clr.muted),
          ),
        ],
      ),
    ],
  );
}
