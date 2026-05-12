// ─────────────────────────────────────────────────────────────────────────────
// lib/pelanggaran/pdf/pdf_colors.dart
// Palet warna PDF — mengikuti tema Flutter PIZAB MOLAH
// ─────────────────────────────────────────────────────────────────────────────

import 'package:pdf/pdf.dart';

class Clr {
  Clr._();

  // ── Brand ────────────────────────────────────────────
  static const PdfColor red          = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor redDark      = PdfColor.fromInt(0xFF991B1B);
  static const PdfColor redLight     = PdfColor.fromInt(0xFFFFF5F5);

  // ── Text ─────────────────────────────────────────────
  static const PdfColor ink          = PdfColor.fromInt(0xFF2D3748);
  static const PdfColor muted        = PdfColor.fromInt(0xFF718096);

  // ── Reward ───────────────────────────────────────────
  static const PdfColor green        = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor greenDark    = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor greenLight   = PdfColor.fromInt(0xFFF0FDF4);

  // ── Pelanggaran ──────────────────────────────────────
  static const PdfColor orange       = PdfColor.fromInt(0xFFD97F0F);
  static const PdfColor orangeLight  = PdfColor.fromInt(0xFFFFFAF0);

  // ── UI Chrome ────────────────────────────────────────
  static const PdfColor border       = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor rowAlt       = PdfColor.fromInt(0xFFF7FAFC);
  static const PdfColor tableHead    = PdfColor.fromInt(0xFF374151);
  static const PdfColor white        = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor pageBg       = PdfColor.fromInt(0xFFF8FAFC);
}
