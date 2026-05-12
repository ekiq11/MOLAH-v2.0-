// ─────────────────────────────────────────────────────────────────────────────
// lib/pelanggaran/pdf/pdf_models.dart
// Model data khusus PDF — dibuat dari RewardPelanggaranData & PoinStatistik
// yang sudah ada di reward_model.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:pdf/pdf.dart';
import 'package:pizab_molah/pelanggaran/model/reward_model.dart';
import 'pdf_colors.dart';

// ─────────────────────────────────────────
//  STATUS SANTRI
// ─────────────────────────────────────────

enum StatusSantri { baik, perluPerhatian, perluTindakan }

extension StatusSantriX on StatusSantri {
  String get label {
    switch (this) {
      case StatusSantri.baik:
        return 'BAIK';
      case StatusSantri.perluPerhatian:
        return 'PERLU PERHATIAN';
      case StatusSantri.perluTindakan:
        return 'PERLU TINDAKAN';
    }
  }

  PdfColor get color {
    switch (this) {
      case StatusSantri.baik:
        return Clr.green;
      case StatusSantri.perluPerhatian:
        return Clr.orange;
      case StatusSantri.perluTindakan:
        return Clr.red;
    }
  }

  PdfColor get bgColor {
    switch (this) {
      case StatusSantri.baik:
        return Clr.greenLight;
      case StatusSantri.perluPerhatian:
        return Clr.orangeLight;
      case StatusSantri.perluTindakan:
        return Clr.redLight;
    }
  }
}

// ─────────────────────────────────────────
//  PAYLOAD LAPORAN
//  Satu objek ini diteruskan ke semua widget PDF
// ─────────────────────────────────────────

class LaporanPayload {
  final String nisn;
  final String namaSantri;
  final String kelasAsrama;
  final String tahunAjaran;
  final DateTime generatedAt;
  final List<RewardPelanggaranData> allData;
  final List<RewardPelanggaranData> rewardList;
  final List<RewardPelanggaranData> pelanggaranList;
  final PoinStatistik statistik;

  LaporanPayload._({
    required this.nisn,
    required this.namaSantri,
    required this.kelasAsrama,
    required this.tahunAjaran,
    required this.generatedAt,
    required this.allData,
    required this.rewardList,
    required this.pelanggaranList,
    required this.statistik,
  });

  // ── Factory ───────────────────────────────────────────
  factory LaporanPayload.build({
    required String nisn,
    required String namaSantri,
    required String kelasAsrama,
    required List<RewardPelanggaranData> data,
    String tahunAjaran = '2024 / 2025',
  }) {
    return LaporanPayload._(
      nisn: nisn,
      namaSantri: namaSantri,
      kelasAsrama: kelasAsrama,
      tahunAjaran: tahunAjaran,
      generatedAt: DateTime.now(),
      allData: data,
      rewardList: data.where((d) => d.isReward).toList(),
      pelanggaranList: data.where((d) => d.isPelanggaran).toList(),
      statistik: PoinStatistik.calculate(data), // pakai method yang sudah ada
    );
  }

  // ── Computed ──────────────────────────────────────────
  StatusSantri get status {
    final s = statistik.selisih;
    if (s >= 10) return StatusSantri.baik;
    if (s >= -10) return StatusSantri.perluPerhatian;
    return StatusSantri.perluTindakan;
  }

  String get selisihLabel =>
      statistik.selisih >= 0 ? '+${statistik.selisih}' : '${statistik.selisih}';

  /// ID dokumen unik untuk footer
  String get docId {
    final d = generatedAt;
    String p2(int n) => n.toString().padLeft(2, '0');
    return 'PIZAB-$nisn-'
        '${d.year}${p2(d.month)}${p2(d.day)}'
        '${p2(d.hour)}${p2(d.minute)}${p2(d.second)}';
  }

  /// Timestamp untuk ditampilkan di header & footer
  String get timestampStr {
    const bulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final d = generatedAt;
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${d.day} ${bulan[d.month]} ${d.year}  |  ${p2(d.hour)}:${p2(d.minute)} WIB';
  }
}
