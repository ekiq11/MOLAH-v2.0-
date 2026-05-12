// ─────────────────────────────────────────────────────────────────────────────
// lib/pelanggaran/pdf/laporan_pdf_generator.dart
//
// Entry point utama — merakit semua bagian menjadi Uint8List siap share/print.
//
// CARA PAKAI dari RewardPelanggaranPage:
// ─────────────────────────────────────
//   final bytes = await LaporanPdfGenerator.generate(
//     nisn        : widget.nisn,
//     namaSantri  : _currentNamaSantri,
//     kelasAsrama : _currentKelasAsrama,
//     data        : _allData,
//   );
//   await Printing.layoutPdf(onLayout: (_) async => bytes);
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pizab_molah/pelanggaran/model/reward_model.dart';

import 'pdf_colors.dart';
import 'pdf_header.dart';
import 'pdf_models.dart';
import 'pdf_summary.dart';
import 'pdf_table.dart';

class LaporanPdfGenerator {
  LaporanPdfGenerator._();

  // ═══════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════

  static Future<Uint8List> generate({
    required String nisn,
    required String namaSantri,
    required String kelasAsrama,
    required List<RewardPelanggaranData> data,
    String tahunAjaran = '2024 / 2025',
  }) async {
    // 1. Buat payload
    final laporan = LaporanPayload.build(
      nisn: nisn,
      namaSantri: namaSantri,
      kelasAsrama: kelasAsrama,
      tahunAjaran: tahunAjaran,
      data: data,
    );

    // 2. Load logo dari assets/img/molah.png
    final logo = await loadAppLogo();

    // 3. Buat dokumen
    final doc = pw.Document(
      title: 'Laporan Reward & Pelanggaran - $namaSantri',
      author: 'PIZAB MOLAH - Sistem Informasi Pesantren',
      subject: 'Laporan Poin Santri Terverifikasi',
      creator: 'PIZAB MOLAH v1.0',
    );

    // 4. Tambah halaman — header & footer lewat MultiPage
    doc.addPage(
      pw.MultiPage(
        pageTheme: buildPageTheme(),
        header: (ctx) => buildPageHeader(
          logo: logo,
          laporan: laporan,
          ctx: ctx,
          totalPages: 99, // MultiPage tidak tahu total halaman di awal
        ),
        footer: (ctx) => buildPageFooter(ctx, laporan),
        build: (ctx) => _buildContent(laporan),
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════
  //  KONTEN HALAMAN
  // ═══════════════════════════════════════════════

  static List<pw.Widget> _buildContent(LaporanPayload laporan) {
    final st = laporan.statistik;

    return [
      // ── Blok verifikasi ──────────────────────────────────
      buildVerificationBlock(laporan),
      pw.SizedBox(height: 10),

      // ── Kartu statistik ──────────────────────────────────
      buildStatsRow(laporan),
      pw.SizedBox(height: 6),

      // ── Progress bar perbandingan ─────────────────────────
      buildProgressBar(laporan),
      pw.SizedBox(height: 8),

      // ── Divider ───────────────────────────────────────────
      pw.Divider(color: Clr.border, thickness: 0.5),
      pw.SizedBox(height: 6),

      // ── Tabel Reward ─────────────────────────────────────
      if (laporan.rewardList.isNotEmpty) ...[
        buildDataTable(
          title: 'DATA REWARD',
          accent: Clr.green,
          rows: laporan.rewardList,
          poinTotal: st.totalReward,
        ),
        pw.SizedBox(height: 12),
      ],

      // ── Tabel Pelanggaran ─────────────────────────────────
      if (laporan.pelanggaranList.isNotEmpty) ...[
        buildDataTable(
          title: 'DATA PELANGGARAN',
          accent: Clr.red,
          rows: laporan.pelanggaranList,
          poinTotal: -st.totalPelanggaran,
        ),
        pw.SizedBox(height: 14),
      ],

      // ── Blok tanda tangan ─────────────────────────────────
      buildSignatureBlock(),
    ];
  }
}
