// File lengkap yang menggabungkan semua logic dengan build method
// Pastikan semua import sudah benar

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:pizab_molah/pelanggaran/model/reward_model.dart';
import 'package:pizab_molah/pelanggaran/poin/pelanggaran_notification.dart';
import 'package:pizab_molah/pelanggaran/poin/reward_pelanggaran_page_widgets.dart' as widgets;
import 'package:pizab_molah/pelanggaran/poin/shimmer_widget.dart';
import 'package:pizab_molah/pelanggaran/statistic/poin_static_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';



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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadLastPelanggaranId();
    _loadData();
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutCubic),
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

  Future<void> _loadLastPelanggaranId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _lastPelanggaranId = prefs.getString('last_pelanggaran_id_${widget.nisn}');
    } catch (e) {
      print('Error loading last pelanggaran ID: $e');
    }
  }

  Future<void> _saveLastPelanggaranId(String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_pelanggaran_id_${widget.nisn}', id);
      _lastPelanggaranId = id;
    } catch (e) {
      print('Error saving last pelanggaran ID: $e');
    }
  }

  void _checkAndShowNewPelanggaranNotification() {
    if (_pelanggaranData.isEmpty) return;
    RewardPelanggaranData latest = _pelanggaranData.first;
    if (_lastPelanggaranId != latest.id) {
      Future.delayed(Duration(milliseconds: 500), () {
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
      bool cacheLoaded = await _loadFromCache();
      if (cacheLoaded) {
        setState(() {
          _loading = false;
          _isFromCache = true;
        });
        _headerAnimationController.forward();
        _checkAndShowNewPelanggaranNotification();
        if (await _isCacheExpired()) {
          _refreshDataInBackground();
        }
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String cacheKey = 'reward_pelanggaran_${widget.nisn}';
      String? cachedData = prefs.getString(cacheKey);
      String? cachedTimestamp = prefs.getString('${cacheKey}_timestamp');
      String? cachedName = prefs.getString('${cacheKey}_name');
      String? cachedKelas = prefs.getString('${cacheKey}_kelas');
      if (cachedTimestamp != null && cachedData != null) {
        List<dynamic> jsonList = json.decode(cachedData);
        List<RewardPelanggaranData> dataList =
            jsonList.map((item) => RewardPelanggaranData.fromJson(item)).toList();
        if (dataList.isNotEmpty) {
          _processData(dataList);
          setState(() {
            _currentNamaSantri = cachedName ?? widget.namaSantri ?? dataList.first.namaSantri;
            _currentKelasAsrama = cachedKelas ?? dataList.first.kelasAsrama;
          });
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isCacheExpired() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String cacheKey = 'reward_pelanggaran_${widget.nisn}';
      String? cachedTimestamp = prefs.getString('${cacheKey}_timestamp');
      if (cachedTimestamp == null) return true;
      DateTime cacheTime = DateTime.parse(cachedTimestamp);
      return DateTime.now().difference(cacheTime).inMinutes > CACHE_DURATION_MINUTES;
    } catch (e) {
      return true;
    }
  }

  Future<void> _saveToCache(List<RewardPelanggaranData> data, String namaSantri, String kelasAsrama) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String cacheKey = 'reward_pelanggaran_${widget.nisn}';
      List<Map<String, dynamic>> jsonList = data.map((item) => item.toJson()).toList();
      await prefs.setString(cacheKey, json.encode(jsonList));
      await prefs.setString('${cacheKey}_timestamp', DateTime.now().toIso8601String());
      await prefs.setString('${cacheKey}_name', namaSantri);
      await prefs.setString('${cacheKey}_kelas', kelasAsrama);
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> _refreshDataInBackground() async {
    try {
      await _fetchFromServer(showLoading: false);
    } catch (e) {
      print('Background refresh failed: $e');
    }
  }

  Future<void> _refreshData() async {
    await _fetchFromServer(showLoading: true);
  }

  String _normalizeNisn(String nisn) {
    String cleaned = nisn.replaceAll("'", "").trim();
    if (cleaned.length == 9 && RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '0$cleaned';
    }
    return cleaned;
  }

  bool _isNisnMatch(String csvNisn, String targetNisn) {
    String cleanedCsvNisn = csvNisn.replaceAll("'", "").trim();
    String normalizedCsvNisn = _normalizeNisn(csvNisn);
    String normalizedTargetNisn = _normalizeNisn(targetNisn);
    return cleanedCsvNisn == targetNisn ||
        cleanedCsvNisn == normalizedTargetNisn ||
        normalizedCsvNisn == targetNisn ||
        normalizedCsvNisn == normalizedTargetNisn;
  }

  DateTime? _parseDateTime(RewardPelanggaranData data) {
    try {
      String dateStr = data.hariTanggal.trim();
      if (dateStr.isEmpty) return null;
      List<RegExp> datePatterns = [
        RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
        RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
        RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
      ];
      for (RegExp pattern in datePatterns) {
        RegExpMatch? match = pattern.firstMatch(dateStr);
        if (match != null) {
          int day, month, year;
          if (pattern == datePatterns[1]) {
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
          }
          if (_isValidDate(year, month, day)) {
            return DateTime(year, month, day);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isValidDate(int year, int month, int day) {
    if (year < 1900 || year > 2100) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    return true;
  }

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
        final data = CsvToListConverter().convert(res.body);
        if (data.isNotEmpty) {
          final filtered = data
              .skip(1)
              .where((row) => row.length > 6 && _isNisnMatch(row[6].toString(), widget.nisn))
              .map((row) => RewardPelanggaranData.fromCsvRow(row))
              .toList();
          if (filtered.isNotEmpty) {
            filtered.sort((a, b) {
              DateTime? dateA = _parseDateTime(a);
              DateTime? dateB = _parseDateTime(b);
              if (dateA == null && dateB == null) {
                return b.hariTanggal.compareTo(a.hariTanggal);
              } else if (dateA == null) {
                return 1;
              } else if (dateB == null) {
                return -1;
              } else {
                return dateB.compareTo(dateA);
              }
            });
            String namaSantri = widget.namaSantri ?? filtered.first.namaSantri;
            String kelasAsrama = filtered.first.kelasAsrama;
            await _saveToCache(filtered, namaSantri, kelasAsrama);
            _processData(filtered);
            setState(() {
              _currentNamaSantri = namaSantri;
              _currentKelasAsrama = kelasAsrama;
              _loading = false;
              _isFromCache = false;
            });
            if (showLoading) {
              _headerAnimationController.forward();
              _checkAndShowNewPelanggaranNotification();
            }
          } else {
            setState(() {
              _loading = false;
            });
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

  @override
  Widget build(BuildContext context) {
    String displayName = _currentNamaSantri.isNotEmpty ? _currentNamaSantri : (widget.namaSantri ?? '');
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Reward & Pelanggaran',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFFDC2626), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Color(0xFFDC2626),
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
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
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    widgets.buildTabButton('semua', 'SEMUA', _allData.length, Icons.view_list, _selectedTab, (value) {
                      setState(() => _selectedTab = value);
                    }),
                    SizedBox(width: 8),
                    widgets.buildTabButton('reward', 'REWARD', _rewardData.length, Icons.star, _selectedTab, (value) {
                      setState(() => _selectedTab = value);
                    }),
                    SizedBox(width: 8),
                    widgets.buildTabButton('pelanggaran', 'PELANGGARAN', _pelanggaranData.length, Icons.warning, _selectedTab, (value) {
                      setState(() => _selectedTab = value);
                    }),
                  ],
                ),
              ),
            ),
            
            // Content
            _loading
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ShimmerCard(),
                      childCount: 5,
                    ),
                  )
                : _error.isNotEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Container(
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height * 0.3,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Terjadi Kesalahan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    _error,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _refreshData,
                                  icon: Icon(Icons.refresh),
                                  label: Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : _currentData.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: SingleChildScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              child: Container(
                                constraints: BoxConstraints(
                                  minHeight: MediaQuery.of(context).size.height * 0.3,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Tidak Ada Data',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Belum ada catatan tersedia',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => widgets.buildDataCard(
                                _currentData[index],
                                index,
                                _parseDateTime(_currentData[index]),
                              ),
                              childCount: _currentData.length,
                            ),
                          ),
            
            SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}