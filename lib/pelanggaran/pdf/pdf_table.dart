// ─────────────────────────────────────────────────────────────────────────────
// lib/pelanggaran/pdf/pdf_table.dart
//
// Tabel data menggunakan semua field RewardPelanggaranData:
//   id, jenisPemberian, kodeEtika, jenisEtika,
//   jumlahPelanggaran, jumlahReward, nisn, namaSantri,
//   kelasAsrama, hariTanggal, waktu, tempatKejadian,
//   rincianKejadian, ustadzGuru
// ─────────────────────────────────────────────────────────────────────────────

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pizab_molah/pelanggaran/model/reward_model.dart';
import 'pdf_colors.dart';

// ─────────────────────────────────────────────
//  DEFINISI KOLOM
//  flex × 10 = int flex untuk pw.Flexible
// ─────────────────────────────────────────────

class _Col {
  final String label;
  final double flex;
  const _Col(this.label, this.flex);
}

const _cols = <_Col>[
  _Col('No.', 0.4),
  _Col('Tanggal / Waktu', 1.4),
  _Col('Kode', 0.6),
  _Col('Jenis Etika', 2.2),
  _Col('Rincian', 2.6),
  _Col('Tempat', 1.4),
  _Col('Poin', 0.7),
  _Col('Pelapor', 1.2),
];

// ─────────────────────────────────────────────
//  HEADING SEKSI
// ─────────────────────────────────────────────

pw.Widget buildSectionHeading({
  required String title,
  required PdfColor accent,
  required int count,
  required int poinTotal,
}) {
  final sign = poinTotal >= 0 ? '+' : '';
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: accent,
      borderRadius: pw.BorderRadius.circular(3),
    ),
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: Clr.white,
          ),
        ),
        pw.Text(
          '$count catatan   |   Total: $sign$poinTotal poin',
          style: pw.TextStyle(fontSize: 7.5, color: Clr.white),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  HEADER KOLOM TABEL
// ─────────────────────────────────────────────

pw.Widget _tableHeader() {
  return pw.Row(
    children: _cols.map((col) {
      return pw.Flexible(
        flex: (col.flex * 10).round(),
        child: pw.Container(
          color: Clr.tableHead,
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(
            col.label,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: Clr.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }).toList(),
  );
}

// ─────────────────────────────────────────────
//  SATU BARIS DATA
// ─────────────────────────────────────────────

pw.Widget _tableRow(RewardPelanggaranData d, int idx) {
  final isReward = d.isReward;
  final bg = idx % 2 == 1 ? Clr.rowAlt : Clr.white;
  final poinAccent = isReward ? Clr.green : Clr.red;
  final poinBg = isReward ? Clr.greenLight : Clr.redLight;
  final poinVal = isReward ? d.jumlahReward : d.jumlahPelanggaran;
  final poinText = poinVal.isNotEmpty
      ? (isReward ? '+$poinVal' : '-$poinVal')
      : '*';

  // Tanggal + waktu digabung
  final tglWaktu = [
    d.hariTanggal,
    d.waktu,
  ].where((s) => s.isNotEmpty).join('\n');

  pw.Widget cell(
    String text,
    double flex, {
    pw.TextStyle? style,
    bool center = false,
  }) {
    return pw.Flexible(
      flex: (flex * 10).round(),
      child: pw.Container(
        color: bg,
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
        child: pw.Text(
          text.isNotEmpty ? text : '*',
          style: style ?? pw.TextStyle(fontSize: 7, color: Clr.ink),
          maxLines: 3,
          overflow: pw.TextOverflow.clip,
        ),
      ),
    );
  }

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: Clr.border, width: 0.25)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // No.
        cell(
          '${idx + 1}',
          0.4,
          style: pw.TextStyle(fontSize: 7, color: Clr.muted),
          center: true,
        ),

        // Tanggal / Waktu
        cell(tglWaktu, 1.4, style: pw.TextStyle(fontSize: 6.5, color: Clr.ink)),

        // Kode Etika
        cell(
          d.kodeEtika,
          0.6,
          style: pw.TextStyle(
            fontSize: 6.5,
            fontWeight: pw.FontWeight.bold,
            color: poinAccent,
          ),
          center: true,
        ),

        // Jenis Etika
        cell(
          d.jenisEtika,
          2.2,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: Clr.ink,
          ),
        ),

        // Rincian Kejadian
        cell(
          d.rincianKejadian,
          2.6,
          style: pw.TextStyle(fontSize: 6.5, color: Clr.muted),
        ),

        // Tempat Kejadian
        cell(
          d.tempatKejadian,
          1.4,
          style: pw.TextStyle(fontSize: 6.5, color: Clr.muted),
        ),

        // Poin — badge
        pw.Flexible(
          flex: 7,
          child: pw.Container(
            color: bg,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                color: poinBg,
                border: pw.Border.all(color: poinAccent, width: 0.5),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                poinText,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: poinAccent,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ),

        // Pelapor (ustadzGuru)
        cell(
          d.ustadzGuru,
          1.2,
          style: pw.TextStyle(fontSize: 6.5, color: Clr.muted),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  TABEL LENGKAP
// ─────────────────────────────────────────────

pw.Widget buildDataTable({
  required String title,
  required PdfColor accent,
  required List<RewardPelanggaranData> rows,
  required int poinTotal,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      buildSectionHeading(
        title: title,
        accent: accent,
        count: rows.length,
        poinTotal: poinTotal,
      ),
      _tableHeader(),
      ...List.generate(rows.length, (i) => _tableRow(rows[i], i)),
    ],
  );
}
