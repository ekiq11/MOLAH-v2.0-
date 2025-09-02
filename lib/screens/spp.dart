// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class SPPPaymentPage extends StatefulWidget {
  final String nisn;
  const SPPPaymentPage({super.key, required this.nisn});

  @override
  _SPPPaymentPageState createState() => _SPPPaymentPageState();
}

class SantriData {
  final String nisn;
  final String nama;
  final String status;
  final String iuranYTD;
  final String nominalDibayar;
  final String sisaPembayaran;
  final int lunasBulanKe;
  final String sisaUangTunggakan;

  // --- Data Uang Pangkal ---
  final String besarUangPangkal;
  final String jumlahDibayarUangPangkal;
  final String kekuranganUangPangkal;
  final double progressUangPangkal;

  SantriData({
    required this.nisn,
    required this.nama,
    required this.status,
    required this.iuranYTD,
    required this.nominalDibayar,
    required this.sisaPembayaran,
    required this.lunasBulanKe,
    required this.sisaUangTunggakan,
    // ---
    required this.besarUangPangkal,
    required this.jumlahDibayarUangPangkal,
    required this.kekuranganUangPangkal,
    required this.progressUangPangkal,
  });

  // Progress pembayaran SPP
  double get progressPercentage => (lunasBulanKe / 12.0).clamp(0.0, 1.0);

  // Daftar bulan yang sudah dibayar
  List<String> get paidMonths {
    final months = [
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
    ];
    return months.take(lunasBulanKe).toList();
  }

  // Daftar bulan yang belum dibayar
  List<String> get unpaidMonths {
    final months = [
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
    ];
    return months.skip(lunasBulanKe).toList();
  }

  // Iuran per bulan
  double get monthlyFee {
    try {
      String cleanAmount = iuranYTD.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanAmount.isEmpty) return 0;
      return int.parse(cleanAmount) / 12.0;
    } catch (e) {
      return 0;
    }
  }

  // Progress uang pangkal dalam persentase
  double get progressUangPangkalPercentage {
    try {
      double total =
          double.tryParse(besarUangPangkal.replaceAll(RegExp(r'[^\d]'), '')) ??
          0.0;
      double paid =
          double.tryParse(
            jumlahDibayarUangPangkal.replaceAll(RegExp(r'[^\d]'), ''),
          ) ??
          0.0;
      if (total <= 0) return 0.0;
      return (paid / total).clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }
}
// LENGKAP MODIFIKASI UNTUK _SPPPaymentPageState
// Hapus semua fungsi yang berhubungan dengan dialog dan ganti dengan navigasi

class _SPPPaymentPageState extends State<SPPPaymentPage>
    with TickerProviderStateMixin {
  SantriData? santriData;
  bool isLoading = true;
  String errorMessage = '';
  // HAPUS: final GlobalKey _invoiceKey = GlobalKey();

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  // Tambahkan URL CSV untuk uang pangkal
  final List<String> csvUrls = [
    'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv&gid=290556271',
    'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv',
  ];

  final List<String> monthNames = [
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchData();
  }

  void _initializeAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String _normalizeNisn(String nisn) {
    return nisn.trim().replaceFirst(RegExp(r'^0+'), '');
  }

  // GANTI: _showInvoiceDialog dengan _navigateToInvoice
  void _navigateToInvoice(String month, int monthIndex) {
    if (santriData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SPPInvoiceScreen(
          santriData: santriData!,
          monthName: month,
          monthIndex: monthIndex,
        ),
      ),
    );
  }

  // HAPUS semua fungsi dialog berikut ini:
  // - _showInvoiceDialog
  // - _downloadInvoice
  // - _buildInvoiceContent
  // - _buildInvoiceSection (yang untuk dialog)
  // - _buildInvoiceRow (yang untuk dialog)
  // - _buildInvoiceForCapture
  // - _generateInvoiceId
  // - _getJatuhTempo
  // - _formatDate
  // - _formatDateTime

  // KEEP semua fungsi lainnya seperti:
  // - fetchData()
  // - _formatCurrency()
  // - _buildContent()
  // - _buildProfileCard()
  // - dll.

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      print('Fetching data for NISN: ${widget.nisn}');
      String targetNisnNormalized = _normalizeNisn(widget.nisn);

      List<List<dynamic>> csvData = [];

      // Ambil data dari semua URL SPP
      for (String url in csvUrls) {
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final data = const CsvToListConverter().convert(response.body);
            csvData.addAll(data);
            print('Fetched from: $url');
            break;
          }
        } catch (e) {
          print('Failed to fetch from $url: $e');
        }
      }

      SantriData? foundSantri;

      // Cari data SPP
      for (int i = 3; i < csvData.length; i++) {
        if (csvData[i].length > 7) {
          String currentNisn = csvData[i][1].toString().trim();
          String currentNisnNormalized = _normalizeNisn(currentNisn);

          if (currentNisnNormalized == targetNisnNormalized) {
            int lunasBulanKe =
                int.tryParse(csvData[i][7].toString().trim()) ?? 0;

            foundSantri = SantriData(
              nisn: currentNisn,
              nama: csvData[i][2].toString().trim(),
              status: csvData[i][3].toString().trim(),
              iuranYTD: csvData[i][4].toString().trim(),
              nominalDibayar: csvData[i][5].toString().trim(),
              sisaPembayaran: csvData[i][6].toString().trim(),
              lunasBulanKe: lunasBulanKe,
              sisaUangTunggakan: csvData[i].length > 8
                  ? csvData[i][8].toString().trim()
                  : '0',
              // Default uang pangkal
              besarUangPangkal: '0',
              jumlahDibayarUangPangkal: '0',
              kekuranganUangPangkal: '0',
              progressUangPangkal: 0.0,
            );
            break;
          }
        }
      }

      // Jika data SPP ditemukan, ambil data uang pangkal
      if (foundSantri != null) {
        try {
          final upResponse = await http.get(
            Uri.parse(
              'https://docs.google.com/spreadsheets/d/1nKsOxOHqi4fmJ9aR4ZpSUiePKVtZG03L2Qjc_iv5QmU/export?format=csv&gid=1122446293',
            ),
          );
          if (upResponse.statusCode == 200) {
            List<List<dynamic>> upData = const CsvToListConverter().convert(
              upResponse.body,
            );
            for (int i = 1; i < upData.length; i++) {
              if (upData[i].length >= 8) {
                String upNisn = upData[i][1].toString().trim();
                if (_normalizeNisn(upNisn) == targetNisnNormalized) {
                  String besar = upData[i][4].toString().trim();
                  String dibayar = upData[i][6].toString().trim();
                  String kekurangan = upData[i][7].toString().trim();

                  double progress = 0.0;
                  try {
                    double total =
                        double.tryParse(
                          besar.replaceAll(RegExp(r'[^\d]'), ''),
                        ) ??
                        0.0;
                    double paid =
                        double.tryParse(
                          dibayar.replaceAll(RegExp(r'[^\d]'), ''),
                        ) ??
                        0.0;
                    progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
                  } catch (e) {
                    progress = 0.0;
                  }

                  foundSantri = SantriData(
                    nisn: foundSantri!.nisn,
                    nama: foundSantri.nama,
                    status: foundSantri.status,
                    iuranYTD: foundSantri.iuranYTD,
                    nominalDibayar: foundSantri.nominalDibayar,
                    sisaPembayaran: foundSantri.sisaPembayaran,
                    lunasBulanKe: foundSantri.lunasBulanKe,
                    sisaUangTunggakan: foundSantri.sisaUangTunggakan,
                    besarUangPangkal: besar,
                    jumlahDibayarUangPangkal: dibayar,
                    kekuranganUangPangkal: kekurangan,
                    progressUangPangkal: progress,
                  );
                  break;
                }
              }
            }
          }
        } catch (e) {
          print('Gagal ambil data uang pangkal: $e');
        }
      }

      setState(() {
        santriData = foundSantri;
        isLoading = false;
        if (foundSantri == null) {
          errorMessage = 'Data tidak ditemukan untuk NISN: ${widget.nisn}';
        }
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String _formatCurrency(String amount) {
    if (amount.isEmpty || amount == '-') return 'Rp 0';
    String cleanAmount = amount.replaceAll(RegExp(r'[^\d-]'), '');
    if (cleanAmount.isEmpty) return 'Rp 0';
    try {
      int number = int.parse(cleanAmount);
      bool isNegative = number < 0;
      number = number.abs();
      String formatted = number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return isNegative ? 'Rp ($formatted)' : 'Rp $formatted';
    } catch (e) {
      return 'Rp $amount';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Pembayaran SPP & Uang Pangkal',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.refresh, color: Colors.grey[700], size: 18),
            ),
            onPressed: fetchData,
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingWidget()
          : errorMessage.isNotEmpty
          ? _buildErrorWidget()
          : santriData == null
          ? _buildNotFoundWidget()
          : _buildContent(),
    );
  }

  // Dalam _buildPaymentHistory(), ubah onTap:
  Widget _buildPaymentHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: Color(0xFF4F46E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Riwayat Pembayaran SPP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4F46E5).withOpacity(0.1),
                  const Color(0xFF7C3AED).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4F46E5).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusInfo(
                  'Lunas',
                  '${santriData!.lunasBulanKe}',
                  const Color(0xFF10B981),
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatusInfo(
                  'Belum Lunas',
                  '${12 - santriData!.lunasBulanKe}',
                  const Color(0xFFEF4444),
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatusInfo('Total Bulan', '12', const Color(0xFF6B7280)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 3;
              if (constraints.maxWidth > 400) crossAxisCount = 4;
              if (constraints.maxWidth > 500) crossAxisCount = 6;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: monthNames.length,
                itemBuilder: (context, index) {
                  String monthName = monthNames[index];
                  bool isPaid = index < santriData!.lunasBulanKe;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: isPaid
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.15),
                                const Color(0xFF059669).withOpacity(0.2),
                              ],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFEF4444).withOpacity(0.08),
                                const Color(0xFFDC2626).withOpacity(0.12),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPaid
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : const Color(0xFFEF4444).withOpacity(0.2),
                        width: isPaid ? 2 : 1.5,
                      ),
                      boxShadow: isPaid
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _navigateToInvoice(
                          monthName,
                          index,
                        ), // PERUBAHAN UTAMA DI SINI
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isPaid
                                        ? [
                                            const Color(0xFF10B981),
                                            const Color(0xFF059669),
                                          ]
                                        : [
                                            const Color(0xFFEF4444),
                                            const Color(0xFFDC2626),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isPaid
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444))
                                              .withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isPaid
                                      ? Icons.check_rounded
                                      : Icons.schedule_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  monthName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isPaid
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444))
                                          .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPaid ? 'LUNAS' : 'BELUM',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: isPaid
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFF6B7280),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Pembayaran',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ketuk bulan untuk melihat invoice/bukti pembayaran. Pembayaran dimulai dari bulan Juli.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // KEEP semua widget build method lainnya seperti:
  // _buildLoadingWidget(), _buildErrorWidget(), _buildNotFoundWidget(),
  // _buildContent(), _buildProfileCard(), _buildPaymentSummary(),
  // _buildUangPangkalProgress(), _buildSummaryItem(), _buildStatusInfo()
  // (Tidak perlu diubah)

  Widget _buildLoadingWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildShimmerProfileCard(),
          const SizedBox(height: 20),
          _buildShimmerPaymentSummary(),
          const SizedBox(height: 20),
          _buildShimmerUangPangkal(),
          const SizedBox(height: 20),
          _buildShimmerPaymentHistory(),
        ],
      ),
    );
  }

  Widget _buildShimmerProfileCard() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[300]!, Colors.grey[200]!],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          _buildShimmerEffect(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 140,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerUangPangkal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerPaymentHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(children: [_buildShimmerEffect()]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
                stops: [
                  _shimmerAnimation.value - 0.3,
                  _shimmerAnimation.value,
                  _shimmerAnimation.value + 0.3,
                ],
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[100]!,
                  Colors.grey[300]!,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(0xFFF59E0B),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Data Tidak Ditemukan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NISN ${widget.nisn} tidak terdaftar dalam sistem pembayaran',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: fetchData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildPaymentSummary(),
            const SizedBox(height: 20),
            _buildUangPangkalProgress(),
            const SizedBox(height: 20),
            _buildPaymentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE53E3E), Color(0xFFE53E3E), Color(0xFFE53E3E)],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 44 : 48,
            height: isSmallScreen ? 44 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: isSmallScreen ? 20 : 22,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  'NISN: ${santriData!.nisn}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  santriData!.nama,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  santriData!.status,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: santriData!.lunasBulanKe >= 12
                    ? [
                        const Color(0xFF10B981).withOpacity(0.3),
                        const Color(0xFF059669).withOpacity(0.2),
                      ]
                    : [
                        const Color(0xFFFBBF24).withOpacity(0.3),
                        const Color(0xFFF59E0B).withOpacity(0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: santriData!.lunasBulanKe >= 12
                    ? const Color(0xFF10B981).withOpacity(0.5)
                    : const Color(0xFFFBBF24).withOpacity(0.5),
              ),
            ),
            child: Text(
              santriData!.lunasBulanKe >= 12 ? 'LUNAS' : 'BELUM LUNAS',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 10 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sisa widget lainnya tetap sama...
  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pembayaran SPP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress SPP',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${santriData!.lunasBulanKe}/12 Bulan',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: santriData!.progressPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        santriData!.lunasBulanKe >= 12
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(santriData!.progressPercentage * 100).toStringAsFixed(0)}% Selesai',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Iuran YTD',
                  _formatCurrency(santriData!.iuranYTD),
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Sudah Dibayar',
                  _formatCurrency(santriData!.nominalDibayar),
                  Icons.check_circle_rounded,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Sisa Pembayaran',
                  _formatCurrency(santriData!.sisaPembayaran),
                  Icons.pending_rounded,
                  const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Iuran/Bulan',
                  _formatCurrency(santriData!.monthlyFee.toInt().toString()),
                  Icons.payment_rounded,
                  const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUangPangkalProgress() {
    if (santriData!.besarUangPangkal == '0') return SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pembayaran Uang Pangkal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress Pembayaran',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${(santriData!.progressUangPangkalPercentage * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: santriData!.progressUangPangkalPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF7C3AED),
                      ),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Uang Pangkal',
                  _formatCurrency(santriData!.besarUangPangkal),
                  Icons.money_rounded,
                  const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Sudah Dibayar',
                  _formatCurrency(santriData!.jumlahDibayarUangPangkal),
                  Icons.check_circle_rounded,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Kekurangan',
                  _formatCurrency(santriData!.kekuranganUangPangkal),
                  Icons.pending_rounded,
                  const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.timeline,
                        color: const Color(0xFF7C3AED),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        santriData!.progressUangPangkalPercentage >= 1.0
                            ? 'LUNAS'
                            : 'BELUM LUNAS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              santriData!.progressUangPangkalPercentage >= 1.0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// KELAS SPP INVOICE SCREEN TERPISAH// KELAS SPP INVOICE SCREEN TERPISAH
class SPPInvoiceScreen extends StatefulWidget {
  final SantriData santriData;
  final String monthName;
  final int monthIndex;

  const SPPInvoiceScreen({
    super.key,
    required this.santriData,
    required this.monthName,
    required this.monthIndex,
  });

  @override
  State<SPPInvoiceScreen> createState() => _SPPInvoiceScreenState();
}

class _SPPInvoiceScreenState extends State<SPPInvoiceScreen>
    with TickerProviderStateMixin {
  final GlobalKey _invoiceKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  String _generateInvoiceId() {
    final now = DateTime.now();
    final monthIndex = widget.monthIndex + 1;
    return 'SPP${widget.santriData.nisn.substring(widget.santriData.nisn.length - 4)}${monthIndex.toString().padLeft(2, '0')}${now.year}';
  }

  String _formatCurrency(String amount) {
    if (amount.isEmpty || amount == '-') return 'Rp 0';
    String cleanAmount = amount.replaceAll(RegExp(r'[^\d-]'), '');
    if (cleanAmount.isEmpty) return 'Rp 0';
    try {
      int number = int.parse(cleanAmount);
      bool isNegative = number < 0;
      number = number.abs();
      String formatted = number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return isNegative ? 'Rp ($formatted)' : 'Rp $formatted';
    } catch (e) {
      return 'Rp $amount';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getJatuhTempo() {
    final monthNames = [
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
    ];
    final monthIndex = monthNames.indexOf(widget.monthName);
    final now = DateTime.now();
    final targetMonth = monthIndex + 7 > 12 ? monthIndex - 5 : monthIndex + 7;
    final targetYear = monthIndex + 7 > 12 ? now.year + 1 : now.year;
    final dueDate = DateTime(targetYear, targetMonth, 5);
    return _formatDate(dueDate);
  }

  bool get isPaid => widget.monthIndex < widget.santriData.lunasBulanKe;

  DateTime? get paymentDate {
    if (!isPaid) return null;
    final now = DateTime.now();
    return DateTime(
      now.year,
      widget.monthIndex + 7 > 12
          ? widget.monthIndex - 5
          : widget.monthIndex + 7,
      15,
    );
  }

  Future<void> _downloadInvoice() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      HapticFeedback.lightImpact();

      // Capture widget as image
      RenderRepaintBoundary boundary =
          _invoiceKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to device
      final directory = await getTemporaryDirectory();
      final invoiceId = _generateInvoiceId();
      final file = File('${directory.path}/invoice_$invoiceId.png');
      await file.writeAsBytes(pngBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Bukti Pembayaran SPP - ${widget.monthName}\nNISN: ${widget.santriData.nisn}\nNama: ${widget.santriData.nama}',
      );

      _showSuccessSnackBar('Invoice berhasil disimpan dan dibagikan!');
    } catch (e) {
      _showErrorSnackBar('Gagal mengunduh invoice: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _shareInvoice() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      HapticFeedback.lightImpact();

      final summary = _generateTextSummary();
      await Clipboard.setData(ClipboardData(text: summary));

      _showSuccessSnackBar('Ringkasan invoice disalin ke clipboard');
    } catch (e) {
      _showErrorSnackBar('Gagal membagikan invoice: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _generateTextSummary() {
    final invoiceId = _generateInvoiceId();
    final currentDate = _formatDate(DateTime.now());

    return '''
🧾 ${isPaid ? 'BUKTI PEMBAYARAN SPP' : 'TAGIHAN SPP'}

No. Invoice: $invoiceId
Tanggal: $currentDate

👤 INFORMASI SANTRI:
Nama: ${widget.santriData.nama}
NISN: ${widget.santriData.nisn}
Status: ${widget.santriData.status}

💰 DETAIL PEMBAYARAN:
Periode: ${widget.monthName}
Iuran per Bulan: ${_formatCurrency(widget.santriData.monthlyFee.toInt().toString())}
Status: ${isPaid ? 'LUNAS ✅' : 'BELUM LUNAS ⏳'}
${isPaid ? 'Tanggal Pembayaran: ${paymentDate != null ? _formatDate(paymentDate!) : '-'}' : 'Jatuh Tempo: ${_getJatuhTempo()}'}

📍 Pesantren Islam Zaid bin Tsabit
Sistem Pembayaran SPP
$currentDate
    ''';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          isPaid ? 'Bukti Pembayaran SPP' : 'Tagihan SPP',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.copy_all_rounded, size: isSmallScreen ? 20 : 24),
            onPressed: _isGenerating ? null : _shareInvoice,
            tooltip: 'Download',
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                // Invoice Widget
                RepaintBoundary(
                  key: _invoiceKey,
                  child: _buildInvoiceWidget(screenSize, isSmallScreen),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                _buildActionButtons(isSmallScreen),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceWidget(Size screenSize, bool isSmallScreen) {
    _generateInvoiceId();
    final currentDate = DateTime.now();

    // Calculate responsive sizes
    final invoiceWidth = screenSize.width - (isSmallScreen ? 24 : 32);
    final headerFontSize = isSmallScreen ? 16.0 : 18.0;
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final bodyFontSize = isSmallScreen ? 12.0 : 14.0;
    final smallFontSize = isSmallScreen ? 10.0 : 12.0;

    return Container(
      width: invoiceWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPaid
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesantren Islam Zaid bin Tsabit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sistem Pembayaran SPP',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: smallFontSize,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 12,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPaid ? 'BUKTI PEMBAYARAN SPP' : 'TAGIHAN SPP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isPaid ? 'LUNAS' : 'BELUM LUNAS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Invoice Details
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No. Invoice',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _generateInvoiceId(),
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tanggal',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatDate(currentDate),
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Divider(height: 32, thickness: 1, color: Colors.grey[300]),

                // Student Information
                _buildInfoSection(
                  'INFORMASI SANTRI',
                  [
                    _buildInfoRow(
                      'NISN',
                      widget.santriData.nisn,
                      bodyFontSize,
                      smallFontSize,
                    ),
                    _buildInfoRow(
                      'Nama',
                      widget.santriData.nama,
                      bodyFontSize,
                      smallFontSize,
                    ),
                    _buildInfoRow(
                      'Status',
                      widget.santriData.status,
                      bodyFontSize,
                      smallFontSize,
                    ),
                    _buildInfoRow(
                      'Periode',
                      widget.monthName,
                      bodyFontSize,
                      smallFontSize,
                    ),
                  ],
                  titleFontSize,
                  isSmallScreen,
                ),

                SizedBox(height: 20),

                // Payment Details
                _buildInfoSection(
                  'DETAIL PEMBAYARAN',
                  [
                    _buildInfoRow(
                      'Iuran per Bulan',
                      _formatCurrency(
                        widget.santriData.monthlyFee.toInt().toString(),
                      ),
                      bodyFontSize,
                      smallFontSize,
                    ),
                    if (isPaid) ...[
                      _buildInfoRow(
                        'Tanggal Pembayaran',
                        paymentDate != null ? _formatDate(paymentDate!) : '-',
                        bodyFontSize,
                        smallFontSize,
                      ),
                    ] else ...[
                      _buildInfoRow(
                        'Jatuh Tempo',
                        _getJatuhTempo(),
                        bodyFontSize,
                        smallFontSize,
                      ),
                    ],
                  ],
                  titleFontSize,
                  isSmallScreen,
                ),

                SizedBox(height: 20),

                // Payment Amount - Highlighted
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isPaid
                          ? [Colors.green[50]!, Colors.green[100]!]
                          : [Colors.orange[50]!, Colors.orange[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPaid ? Colors.green[300]! : Colors.orange[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL PEMBAYARAN',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: isPaid
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 10,
                              vertical: isSmallScreen ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? Colors.green[600]
                                  : Colors.orange[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPaid ? 'LUNAS' : 'BELUM LUNAS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: smallFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatCurrency(
                              widget.santriData.monthlyFee.toInt().toString(),
                            ),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: isPaid
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Payment Status Info
                _buildInfoSection(
                  'STATUS PEMBAYARAN',
                  [
                    _buildInfoRow(
                      'Status Pembayaran',
                      isPaid ? 'LUNAS' : 'BELUM LUNAS',
                      bodyFontSize,
                      smallFontSize,
                      isHighlight: true,
                    ),
                  ],
                  titleFontSize,
                  isSmallScreen,
                ),

                SizedBox(height: 24),

                // Footer
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF4F46E5).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPaid ? Icons.verified : Icons.info_outline,
                            color: const Color(0xFF4F46E5),
                            size: isSmallScreen ? 16 : 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            isPaid
                                ? 'BUKTI PEMBAYARAN'
                                : 'INFORMASI PEMBAYARAN',
                            style: TextStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4F46E5),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        isPaid
                            ? 'Jazakumullahu khairan, Anda telah melakukan pembayaran SPP untuk bulan ${widget.monthName}.'
                            : 'Silakan lakukan pembayaran sebelum jatuh tempo',
                        style: TextStyle(
                          fontSize: smallFontSize,
                          color: const Color(0xFF4F46E5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Verification Container - Only show if paid
                if (isPaid) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified,
                              color: Colors.green[600],
                              size: isSmallScreen ? 16 : 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'PEMBAYARAN TERVERIFIKASI',
                              style: TextStyle(
                                fontSize: smallFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Invoice ini adalah bukti sah pembayaran SPP',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Simpan bukti ini untuk keperluan administrasi',
                          style: TextStyle(
                            fontSize: smallFontSize - 1,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Generated timestamp
                Center(
                  child: Text(
                    'Dibuat pada: ${_formatDateTime(currentDate)}',
                    style: TextStyle(
                      fontSize: smallFontSize - 1,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<Widget> children,
    double titleFontSize,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    double bodyFontSize,
    double smallFontSize, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: smallFontSize,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: smallFontSize, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: bodyFontSize,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                color: isHighlight
                    ? (value.contains('LUNAS')
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                    : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _downloadInvoice,
            icon: _isGenerating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.share, size: isSmallScreen ? 18 : 20),
            label: Text(
              _isGenerating ? 'Proses...' : 'Share Invoice',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaid
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isGenerating ? null : _shareInvoice,
            icon: Icon(Icons.copy_all_outlined, size: isSmallScreen ? 18 : 20),
            label: Text(
              'Salin Invoice',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isPaid
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              side: BorderSide(
                color: isPaid
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
