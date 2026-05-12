// ─────────────────────────────────────────────────────────────────────────────
// PATCH: reward_pelanggaran_page.dart
//
// Tambahkan 4 hal berikut ke file yang sudah ada.
// Tidak perlu mengubah logika fetch/cache yang sudah berjalan.
// ─────────────────────────────────────────────────────────────────────────────

// ════════════════════════════════════════════
//  [1] TAMBAH di bagian import (paling atas)
// ════════════════════════════════════════════

// import 'package:printing/printing.dart';
// import 'package:pizab_molah/pelanggaran/pdf/laporan_pdf_generator.dart';


// ════════════════════════════════════════════
//  [2] TAMBAH 1 field di _RewardPelanggaranPageState
// ════════════════════════════════════════════

// bool _isGeneratingPdf = false;


// ════════════════════════════════════════════
//  [3] TAMBAH method di _RewardPelanggaranPageState
// ════════════════════════════════════════════

/*
Future<void> _downloadPdf() async {
  if (_allData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content         : Text('Belum ada data untuk dicetak.'),
        backgroundColor : Colors.orange,
        behavior        : SnackBarBehavior.floating,
      ),
    );
    return;
  }

  setState(() => _isGeneratingPdf = true);

  try {
    final bytes = await LaporanPdfGenerator.generate(
      nisn        : widget.nisn,
      namaSantri  : _currentNamaSantri.isNotEmpty
                      ? _currentNamaSantri
                      : (widget.namaSantri ?? ''),
      kelasAsrama : _currentKelasAsrama,
      data        : _allData,
    );

    await Printing.layoutPdf(
      onLayout : (_) async => bytes,
      name     : 'Laporan_Santri_${widget.nisn}.pdf',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content         : Text('Gagal membuat PDF: $e'),
          backgroundColor : Colors.red,
          behavior        : SnackBarBehavior.floating,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isGeneratingPdf = false);
  }
}
*/


// ════════════════════════════════════════════
//  [4] TAMBAH actions ke AppBar yang sudah ada
//      (hanya tambah parameter actions: [...])
// ════════════════════════════════════════════

/*
appBar: AppBar(
  backgroundColor : Colors.white,
  elevation       : 0,
  centerTitle     : true,
  title: const Text(
    'Reward & Pelanggaran',
    style: TextStyle(
      color      : Color(0xFF2D3748),
      fontWeight : FontWeight.bold,
      fontSize   : 18,
    ),
  ),
  leading: IconButton(
    icon      : const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFFDC2626), size: 20),
    onPressed : () => Navigator.pop(context),
  ),

  // ↓ TAMBAHKAN BAGIAN INI ↓
  actions: [
    if (_isGeneratingPdf)
      const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width  : 20,
          height : 20,
          child  : CircularProgressIndicator(
            strokeWidth : 2,
            color       : Color(0xFFDC2626),
          ),
        ),
      )
    else
      IconButton(
        tooltip   : 'Unduh Laporan PDF',
        icon      : const Icon(
          Icons.picture_as_pdf_outlined,
          color: Color(0xFFDC2626),
        ),
        onPressed : _allData.isEmpty ? null : _downloadPdf,
      ),
  ],
),
*/
