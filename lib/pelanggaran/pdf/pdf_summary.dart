// ─────────────────────────────────────────────────────────────────────────────
// lib/pelanggaran/pdf/pdf_summary.dart
// Blok verifikasi, kartu statistik (pakai PoinStatistik), tanda tangan
// ─────────────────────────────────────────────────────────────────────────────

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_colors.dart';
import 'pdf_models.dart';

// ─────────────────────────────────────────────
//  BLOK VERIFIKASI
// ─────────────────────────────────────────────

pw.Widget buildVerificationBlock(LaporanPayload laporan) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: Clr.greenLight,
      border: pw.Border.all(color: Clr.green, width: 0.8),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: pw.Row(
      children: [
        // Badge verified — shield hijau + centang putih (vector, tanpa font)
        pw.Container(
          width: 20,
          height: 20,
          child: pw.CustomPaint(
            size: const PdfPoint(20, 20),
            painter: (canvas, size) {
              final cx = size.x / 2;

              // Shield body — Y dibalik (20 - y) karena PDF origin dari bawah
              canvas
                ..setFillColor(Clr.green)
                ..moveTo(cx, 19) // atas tengah
                ..lineTo(19, 16) // atas kanan
                ..lineTo(19, 10) // tengah kanan
                ..curveTo(19, 5, cx, 1, cx, 1) // runcing bawah kanan
                ..curveTo(cx, 1, 1, 5, 1, 10) // runcing bawah kiri
                ..lineTo(1, 16) // tengah kiri
                ..closePath()
                ..fillPath();

              // Centang putih — Y dibalik
              canvas
                ..setStrokeColor(Clr.white)
                ..setLineWidth(1.8)
                ..moveTo(6.5, 10) // titik kiri
                ..lineTo(9, 7.5) // titik tengah bawah
                ..lineTo(13.5, 12.5) // titik kanan atas
                ..strokePath();
            },
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DOKUMEN INI TELAH DIVERIFIKASI OLEH SISTEM PIZAB MOLAH',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: Clr.green,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'ID: ${laporan.docId}   |   Waktu: ${laporan.timestampStr}   |   NISN: ${laporan.nisn}',
                style: pw.TextStyle(fontSize: 6.5, color: Clr.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  SATU KARTU STATISTIK
// ─────────────────────────────────────────────

pw.Widget _statCard({
  required String label,
  required String value,
  required PdfColor accent,
  required PdfColor bg,
}) {
  return pw.Expanded(
    child: pw.Container(
      height: 54,
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: Clr.border, width: 0.6),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          // Bar aksen kiri
          pw.Container(
            width: 4,
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                bottomLeft: pw.Radius.circular(4),
              ),
            ),
          ),
          pw.SizedBox(width: 7),
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label.toUpperCase(),
                  style: pw.TextStyle(fontSize: 5.5, color: Clr.muted),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  BARIS 4 KARTU STATISTIK
//  Menggunakan PoinStatistik yang sudah ada
// ─────────────────────────────────────────────

pw.Widget buildStatsRow(LaporanPayload laporan) {
  final st = laporan.statistik;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Judul seksi
      pw.Text(
        'RINGKASAN POIN',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: Clr.ink,
        ),
      ),
      pw.Container(
        width: 44,
        height: 2,
        margin: const pw.EdgeInsets.only(top: 2, bottom: 6),
        color: Clr.red,
      ),

      // 4 kartu
      pw.Row(
        children: [
          _statCard(
            label: 'Total Reward',
            value: '+${st.totalReward}',
            accent: Clr.green,
            bg: Clr.greenLight,
          ),
          pw.SizedBox(width: 4),
          _statCard(
            label: 'Total Pelanggaran',
            value: '-${st.totalPelanggaran}',
            accent: Clr.red,
            bg: Clr.redLight,
          ),
          pw.SizedBox(width: 4),
          _statCard(
            label: 'Selisih Poin',
            value: laporan.selisihLabel,
            accent: st.selisih >= 0 ? Clr.green : Clr.red,
            bg: st.selisih >= 0 ? Clr.greenLight : Clr.redLight,
          ),
          pw.SizedBox(width: 4),
          _statCard(
            label: 'Status Santri',
            value: laporan.status.label,
            accent: laporan.status.color,
            bg: laporan.status.bgColor,
          ),
        ],
      ),

      pw.SizedBox(height: 5),

      // Baris count
      pw.Text(
        'Reward: ${st.jumlahReward} catatan   |   '
        'Pelanggaran: ${st.jumlahPelanggaran} catatan   |   '
        'Total: ${laporan.allData.length} catatan',
        style: pw.TextStyle(fontSize: 7, color: Clr.muted),
      ),
    ],
  );
}

// ─────────────────────────────────────────────
//  PROGRESS BAR PERBANDINGAN
// ─────────────────────────────────────────────

pw.Widget buildProgressBar(LaporanPayload laporan) {
  final st = laporan.statistik;
  final total = st.totalReward + st.totalPelanggaran;
  final pct = total > 0 ? st.totalReward / total : 0.5;
  final rPct = (pct * 100).toStringAsFixed(0);
  final pPct = ((1 - pct) * 100).toStringAsFixed(0);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Perbandingan Reward vs Pelanggaran',
            style: pw.TextStyle(fontSize: 7, color: Clr.muted),
          ),
          pw.Text(
            '$rPct% : $pPct%',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: Clr.ink,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Container(
        height: 7,
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFE2E8F0),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(
          children: [
            // Reward (hijau)
            if (pct > 0)
              pw.Flexible(
                flex: (pct * 100).round(),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: Clr.green,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: const pw.Radius.circular(4),
                      bottomLeft: const pw.Radius.circular(4),
                      topRight: pct >= 1.0
                          ? const pw.Radius.circular(4)
                          : pw.Radius.zero,
                      bottomRight: pct >= 1.0
                          ? const pw.Radius.circular(4)
                          : pw.Radius.zero,
                    ),
                  ),
                ),
              ),
            // Pelanggaran (merah)
            if (pct < 1.0)
              pw.Flexible(
                flex: ((1 - pct) * 100).round(),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: Clr.red,
                    borderRadius: pw.BorderRadius.only(
                      topRight: const pw.Radius.circular(4),
                      bottomRight: const pw.Radius.circular(4),
                      topLeft: pct <= 0
                          ? const pw.Radius.circular(4)
                          : pw.Radius.zero,
                      bottomLeft: pct <= 0
                          ? const pw.Radius.circular(4)
                          : pw.Radius.zero,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      pw.SizedBox(height: 3),
      pw.Row(
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: const pw.BoxDecoration(
              color: Clr.green,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            'Reward',
            style: pw.TextStyle(fontSize: 6.5, color: Clr.muted),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            width: 8,
            height: 8,
            decoration: const pw.BoxDecoration(
              color: Clr.red,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            'Pelanggaran',
            style: pw.TextStyle(fontSize: 6.5, color: Clr.muted),
          ),
        ],
      ),
    ],
  );
}

// ─────────────────────────────────────────────
//  BLOK TANDA TANGAN
// ─────────────────────────────────────────────

pw.Widget buildSignatureBlock() {
  const cols = ['Wali Kelas / Musyrif', 'Kepala Asrama', 'Orang Tua / Wali'];

  return pw.Container(
    decoration: pw.BoxDecoration(
      color: const PdfColor.fromInt(0xFFF9FAFB),
      border: pw.Border.all(color: Clr.border, width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    padding: const pw.EdgeInsets.all(10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PENGESAHAN LAPORAN',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: Clr.ink,
          ),
        ),
        pw.Container(
          width: 52,
          height: 1.5,
          margin: const pw.EdgeInsets.symmetric(vertical: 3),
          color: Clr.red,
        ),
        pw.Text(
          'Laporan ini sah dan dapat dipertanggungjawabkan. '
          'Diterbitkan oleh Sistem PIZAB MOLAH berdasarkan data yang telah diverifikasi.',
          style: pw.TextStyle(fontSize: 7, color: Clr.muted),
        ),
        pw.SizedBox(height: 10),

        // Kolom tanda tangan
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: cols.map((lbl) {
            return pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.only(right: 6),
                padding: const pw.EdgeInsets.fromLTRB(6, 5, 6, 5),
                decoration: pw.BoxDecoration(
                  color: Clr.white,
                  border: pw.Border.all(color: Clr.border, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      lbl,
                      style: pw.TextStyle(fontSize: 7, color: Clr.muted),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 26),
                    pw.Divider(color: Clr.border, thickness: 0.5),
                    pw.Text(
                      '(tanda tangan & cap)',
                      style: pw.TextStyle(fontSize: 6, color: Clr.border),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}
