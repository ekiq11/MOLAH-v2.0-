// lib/pelanggaran/poin/reward_pelanggaran_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:pizab_molah/pelanggaran/model/reward_model.dart';
import 'package:pizab_molah/pelanggaran/poin/pelanggaran_notification.dart';
import 'package:pizab_molah/pelanggaran/poin/reward_pelanggaran_page_widgets.dart'
    as widgets;
import 'package:pizab_molah/pelanggaran/poin/shimmer_widget.dart';
import 'package:pizab_molah/pelanggaran/statistic/poin_static_widget.dart';
import 'package:pizab_molah/pelanggaran/pdf/laporan_pdf_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class RewardPelanggaranPage extends StatefulWidget {
  final String nisn;
  final String? namaSantri;

  const RewardPelanggaranPage({super.key, required this.nisn, this.namaSantri});

  @override
  State<RewardPelanggaranPage> createState() => _RewardPelanggaranPageState();
}

class _RewardPelanggaranPageState extends State<RewardPelanggaranPage>
    with TickerProviderStateMixin {
  List<RewardPelanggaranData> _allData = [];
  List<RewardPelanggaranData> _rewardData = [];
  List<RewardPelanggaranData> _pelanggaranData = [];
  PoinStatistik? _statistik;
  bool _loading = true;
  bool _isGeneratingPdf = false; // ← state PDF
  String _error = '';
  String _currentNamaSantri = '';
  String _currentKelasAsrama = '';
  bool _isFromCache = false;
  String _selectedTab = 'semua';
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  String? _lastPelanggaranId;

  static const String csvUrl =
      'https://docs.google.com/spreadsheets/d/1BZbBczH2OY8SB2_1tDpKf_B8WvOyk8TJl4esfT-dgzw/export?format=csv&gid=1620978739';
  static const int CACHE_DURATION_MINUTES = 15;

  // ════════════════════════════════════════════════
  //  LIFECYCLE
  // ════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadLastPelanggaranId();
    _loadData();
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _headerFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════
  //  PDF & SHARE
  // ════════════════════════════════════════════════

  /// Hasilkan byte PDF (dipakai bersama oleh print & share)
  Future<Uint8List> _generatePdfBytes() async {
    return LaporanPdfGenerator.generate(
      nisn: widget.nisn,
      namaSantri: _currentNamaSantri.isNotEmpty
          ? _currentNamaSantri
          : (widget.namaSantri ?? ''),
      kelasAsrama: _currentKelasAsrama,
      data: _allData,
    );
  }

  /// Tampilkan bottom-sheet pilihan aksi PDF
  void _showPdfOptions() {
    if (_allData.isEmpty) {
      _showSnack('Belum ada data untuk dicetak.', isError: false);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PdfOptionsSheet(
        onPreviewPrint: _previewAndPrint,
        onShareWa: () => _sharePdf(target: _ShareTarget.whatsapp),
        onShareTelegram: () => _sharePdf(target: _ShareTarget.telegram),
        onShareGeneral: () => _sharePdf(target: _ShareTarget.general),
      ),
    );
  }

  /// Buka dialog preview / print sistem
  Future<void> _previewAndPrint() async {
    Navigator.pop(context); // tutup sheet
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _generatePdfBytes();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Laporan_Santri_${widget.nisn}.pdf',
      );
    } catch (e) {
      _showSnack('Gagal membuat PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  /// Simpan PDF ke cache lalu share
  Future<void> _sharePdf({required _ShareTarget target}) async {
    Navigator.pop(context); // tutup sheet
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _generatePdfBytes();

      // Simpan ke file sementara
      final dir = await getTemporaryDirectory();
      final name = _currentNamaSantri.isNotEmpty
          ? _currentNamaSantri.replaceAll(' ', '_')
          : widget.nisn;
      final file = File('${dir.path}/Laporan_$name.pdf');
      await file.writeAsBytes(bytes);

      final xFile = XFile(file.path, mimeType: 'application/pdf');
      final subject = 'Laporan Reward & Pelanggaran — $_currentNamaSantri';
      final text =
          '📄 *Laporan Reward & Pelanggaran Santri*\n'
          '👤 $_currentNamaSantri\n'
          '🏫 $_currentKelasAsrama\n'
          '🆔 NISN: ${widget.nisn}\n\n'
          '_Diterbitkan oleh Sistem PIZAB MOLAH_';

      switch (target) {
        case _ShareTarget.whatsapp:
          await Share.shareXFiles([xFile], text: text, subject: subject);
          break;

        case _ShareTarget.telegram:
          await Share.shareXFiles([xFile], text: text, subject: subject);
          break;

        case _ShareTarget.general:
          await Share.shareXFiles([xFile], text: text, subject: subject);
          break;
      }
    } catch (e) {
      _showSnack('Gagal berbagi PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  DATA  (tidak ada perubahan dari versi asli)
  // ════════════════════════════════════════════════

  Future<void> _loadLastPelanggaranId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _lastPelanggaranId = prefs.getString(
        'last_pelanggaran_id_${widget.nisn}',
      );
    } catch (e) {
      debugPrint('Error loading last pelanggaran ID: $e');
    }
  }

  Future<void> _saveLastPelanggaranId(String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_pelanggaran_id_${widget.nisn}', id);
      _lastPelanggaranId = id;
    } catch (e) {
      debugPrint('Error saving last pelanggaran ID: $e');
    }
  }

  void _checkAndShowNewPelanggaranNotification() {
    if (_pelanggaranData.isEmpty) return;
    final latest = _pelanggaranData.first;
    if (_lastPelanggaranId != latest.id) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          PelanggaranNotification.show(context, latest);
          _saveLastPelanggaranId(latest.id);
        }
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });
      final cacheLoaded = await _loadFromCache();
      if (cacheLoaded) {
        setState(() {
          _loading = false;
          _isFromCache = true;
        });
        _headerAnimationController.forward();
        _checkAndShowNewPelanggaranNotification();
        if (await _isCacheExpired()) _refreshDataInBackground();
      } else {
        await _fetchFromServer();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'reward_pelanggaran_${widget.nisn}';
      final cachedData = prefs.getString(cacheKey);
      final cachedTs = prefs.getString('${cacheKey}_timestamp');
      final cachedName = prefs.getString('${cacheKey}_name');
      final cachedKelas = prefs.getString('${cacheKey}_kelas');
      if (cachedTs != null && cachedData != null) {
        final jsonList = json.decode(cachedData) as List<dynamic>;
        final dataList = jsonList
            .map((item) => RewardPelanggaranData.fromJson(item))
            .toList();
        if (dataList.isNotEmpty) {
          _processData(dataList);
          setState(() {
            _currentNamaSantri =
                cachedName ?? widget.namaSantri ?? dataList.first.namaSantri;
            _currentKelasAsrama = cachedKelas ?? dataList.first.kelasAsrama;
          });
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isCacheExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'reward_pelanggaran_${widget.nisn}';
      final ts = prefs.getString('${cacheKey}_timestamp');
      if (ts == null) return true;
      return DateTime.now().difference(DateTime.parse(ts)).inMinutes >
          CACHE_DURATION_MINUTES;
    } catch (_) {
      return true;
    }
  }

  Future<void> _saveToCache(
    List<RewardPelanggaranData> data,
    String nama,
    String kelas,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'reward_pelanggaran_${widget.nisn}';
      await prefs.setString(
        cacheKey,
        json.encode(data.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        '${cacheKey}_timestamp',
        DateTime.now().toIso8601String(),
      );
      await prefs.setString('${cacheKey}_name', nama);
      await prefs.setString('${cacheKey}_kelas', kelas);
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  Future<void> _refreshDataInBackground() async {
    try {
      await _fetchFromServer(showLoading: false);
    } catch (e) {
      debugPrint('Background refresh failed: $e');
    }
  }

  Future<void> _refreshData() => _fetchFromServer(showLoading: true);

  String _normalizeNisn(String nisn) {
    final cleaned = nisn.replaceAll("'", "").trim();
    if (cleaned.length == 9 && RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '0$cleaned';
    }
    return cleaned;
  }

  bool _isNisnMatch(String csvNisn, String target) {
    final cleaned = csvNisn.replaceAll("'", "").trim();
    final normCsv = _normalizeNisn(csvNisn);
    final normTarget = _normalizeNisn(target);
    return cleaned == target ||
        cleaned == normTarget ||
        normCsv == target ||
        normCsv == normTarget;
  }

  DateTime? _parseDateTime(RewardPelanggaranData data) {
    try {
      final dateStr = data.hariTanggal.trim();
      if (dateStr.isEmpty) return null;
      final patterns = [
        RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
        RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
        RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
      ];
      for (final p in patterns) {
        final m = p.firstMatch(dateStr);
        if (m != null) {
          int d, mo, y;
          if (p == patterns[1]) {
            y = int.parse(m.group(1)!);
            mo = int.parse(m.group(2)!);
            d = int.parse(m.group(3)!);
          } else {
            d = int.parse(m.group(1)!);
            mo = int.parse(m.group(2)!);
            y = int.parse(m.group(3)!);
          }
          if (_isValidDate(y, mo, d)) return DateTime(y, mo, d);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isValidDate(int y, int m, int d) =>
      y >= 1900 && y <= 2100 && m >= 1 && m <= 12 && d >= 1 && d <= 31;

  Future<void> _fetchFromServer({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _loading = true;
          _error = '';
        });
      }
      final res = await http.get(Uri.parse(csvUrl));
      if (res.statusCode == 200) {
        final data = const CsvToListConverter().convert(res.body);
        if (data.isNotEmpty) {
          final filtered = data
              .skip(1)
              .where(
                (row) =>
                    row.length > 6 &&
                    _isNisnMatch(row[6].toString(), widget.nisn),
              )
              .map((row) => RewardPelanggaranData.fromCsvRow(row))
              .toList();
          if (filtered.isNotEmpty) {
            filtered.sort((a, b) {
              final dA = _parseDateTime(a), dB = _parseDateTime(b);
              if (dA == null && dB == null) {
                return b.hariTanggal.compareTo(a.hariTanggal);
              }
              if (dA == null) return 1;
              if (dB == null) return -1;
              return dB.compareTo(dA);
            });
            final nama = widget.namaSantri ?? filtered.first.namaSantri;
            final kelas = filtered.first.kelasAsrama;
            await _saveToCache(filtered, nama, kelas);
            _processData(filtered);
            setState(() {
              _currentNamaSantri = nama;
              _currentKelasAsrama = kelas;
              _loading = false;
              _isFromCache = false;
            });
            if (showLoading) {
              _headerAnimationController.forward();
              _checkAndShowNewPelanggaranNotification();
            }
          } else {
            setState(() => _loading = false);
          }
        }
      } else {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat data';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  void _processData(List<RewardPelanggaranData> data) {
    _allData = data.take(20).toList();
    _rewardData = _allData.where((item) => item.isReward).toList();
    _pelanggaranData = _allData.where((item) => item.isPelanggaran).toList();
    _statistik = PoinStatistik.calculate(_allData);
  }

  List<RewardPelanggaranData> get _currentData {
    switch (_selectedTab) {
      case 'reward':
        return _rewardData;
      case 'pelanggaran':
        return _pelanggaranData;
      default:
        return _allData;
    }
  }

  // ════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final displayName = _currentNamaSantri.isNotEmpty
        ? _currentNamaSantri
        : (widget.namaSantri ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Reward & Pelanggaran',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        // ── TOMBOL PDF ──────────────────────────────────
        actions: [
          if (_isGeneratingPdf)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFDC2626),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PdfActionButton(
                enabled: _allData.isNotEmpty,
                onPressed: _showPdfOptions,
              ),
            ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFDC2626),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Student Header
            SliverToBoxAdapter(
              child: widgets.buildStudentHeader(
                context,
                _headerAnimationController,
                _headerSlideAnimation,
                _headerFadeAnimation,
                displayName,
                widget.nisn,
                _currentKelasAsrama,
                _isFromCache,
                _refreshData,
              ),
            ),

            // Statistics Widget
            if (_statistik != null)
              SliverToBoxAdapter(
                child: PoinStatisticsWidget(statistik: _statistik!),
              ),

            // Tab Buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    widgets.buildTabButton(
                      'semua',
                      'SEMUA',
                      _allData.length,
                      Icons.view_list,
                      _selectedTab,
                      (v) => setState(() => _selectedTab = v),
                    ),
                    const SizedBox(width: 8),
                    widgets.buildTabButton(
                      'reward',
                      'REWARD',
                      _rewardData.length,
                      Icons.star,
                      _selectedTab,
                      (v) => setState(() => _selectedTab = v),
                    ),
                    const SizedBox(width: 8),
                    widgets.buildTabButton(
                      'pelanggaran',
                      'PELANGGARAN',
                      _pelanggaranData.length,
                      Icons.warning,
                      _selectedTab,
                      (v) => setState(() => _selectedTab = v),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const ShimmerCard(),
                  childCount: 5,
                ),
              )
            else if (_error.isNotEmpty)
              _buildErrorSliver()
            else if (_currentData.isEmpty)
              _buildEmptySliver()
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => widgets.buildDataCard(
                    _currentData[i],
                    i,
                    _parseDateTime(_currentData[i]),
                  ),
                  childCount: _currentData.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  // ── Error state ──────────────────────────────────

  Widget _buildErrorSliver() => SliverFillRemaining(
    hasScrollBody: false,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: _CenteredStateWidget(
        icon: Icons.error_outline,
        iconColor: Colors.red[400]!,
        iconBg: Colors.red[50]!,
        title: 'Terjadi Kesalahan',
        subtitle: _error,
        action: ElevatedButton.icon(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba Lagi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ),
  );

  // ── Empty state ──────────────────────────────────

  Widget _buildEmptySliver() => SliverFillRemaining(
    hasScrollBody: false,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: _CenteredStateWidget(
        icon: Icons.inbox,
        iconColor: Colors.grey[400]!,
        iconBg: Colors.grey[100]!,
        title: 'Tidak Ada Data',
        subtitle: 'Belum ada catatan tersedia',
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  PRIVATE ENUM
// ══════════════════════════════════════════════════════

enum _ShareTarget { whatsapp, telegram, general }

// ══════════════════════════════════════════════════════
//  TOMBOL PDF  (animasi pulse merah)
// ══════════════════════════════════════════════════════

class _PdfActionButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _PdfActionButton({required this.enabled, required this.onPressed});

  @override
  State<_PdfActionButton> createState() => _PdfActionButtonState();
}

class _PdfActionButtonState extends State<_PdfActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.enabled ? _scale : const AlwaysStoppedAnimation(1.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: widget.enabled
              ? const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                )
              : null,
          color: widget.enabled ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          boxShadow: widget.enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: IconButton(
          tooltip: 'Unduh / Bagikan Laporan PDF',
          icon: const Icon(
            Icons.picture_as_pdf_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: widget.enabled ? widget.onPressed : null,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  BOTTOM SHEET PILIHAN PDF
// ══════════════════════════════════════════════════════

class _PdfOptionsSheet extends StatelessWidget {
  final VoidCallback onPreviewPrint;
  final VoidCallback onShareWa;
  final VoidCallback onShareTelegram;
  final VoidCallback onShareGeneral;

  const _PdfOptionsSheet({
    required this.onPreviewPrint,
    required this.onShareWa,
    required this.onShareTelegram,
    required this.onShareGeneral,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Judul
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan PDF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Pilih cara menggunakan laporan',
                      style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Opsi-opsi
          _OptionTile(
            icon: Icons.print_rounded,
            iconBg: const Color(0xFFEBF8FF),
            iconColor: const Color(0xFF3182CE),
            title: 'Preview & Cetak',
            subtitle: 'Buka dialog cetak sistem',
            onTap: onPreviewPrint,
          ),
          const SizedBox(height: 8),

          _OptionTile(
            icon: Icons.chat_rounded,
            iconBg: const Color(0xFFEBFFF1),
            iconColor: const Color(0xFF25D366),
            title: 'Kirim via WhatsApp',
            subtitle: 'Bagikan PDF ke WhatsApp',
            onTap: onShareWa,
          ),
          const SizedBox(height: 8),

          _OptionTile(
            icon: Icons.send_rounded,
            iconBg: const Color(0xFFEBF4FF),
            iconColor: const Color(0xFF229ED9),
            title: 'Kirim via Telegram',
            subtitle: 'Bagikan PDF ke Telegram',
            onTap: onShareTelegram,
          ),
          const SizedBox(height: 8),

          _OptionTile(
            icon: Icons.share_rounded,
            iconBg: const Color(0xFFF3F4FF),
            iconColor: const Color(0xFF6C63FF),
            title: 'Bagikan ke Aplikasi Lain',
            subtitle: 'Email, Drive, dan lainnya',
            onTap: onShareGeneral,
          ),
        ],
      ),
    );
  }
}

// ── Satu baris opsi ──────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  HELPER: State kosong / error
// ══════════════════════════════════════════════════════

class _CenteredStateWidget extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? action;

  const _CenteredStateWidget({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 60, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}
