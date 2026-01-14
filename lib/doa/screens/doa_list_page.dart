// screens/doa_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizab_molah/doa/model/model_doa.dart';

import 'doa_detail_page.dart';

class DoaListPage extends StatefulWidget {
  const DoaListPage({super.key});

  @override
  State<DoaListPage> createState() => _DoaListPageState();
}

class _DoaListPageState extends State<DoaListPage> {
  List<Doa> _allDoas = [];
  List<Doa> _filteredDoas = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoas() async {
    try {
      final String response = await rootBundle.loadString('assets/json/doa.json');
      final List<dynamic> data = json.decode(response);
      
      setState(() {
        _allDoas = data.map((json) => Doa.fromJson(json)).toList();
        _filteredDoas = _allDoas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data doa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterDoas(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDoas = _allDoas;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredDoas = _allDoas.where((doa) {
          // Cari di nama
          if (doa.nama.toLowerCase().contains(lowerQuery)) return true;
          
          // Cari di transliterasi
          if (doa.transliterasi.toLowerCase().contains(lowerQuery)) return true;
          
          // Cari di arti
          if (doa.arti.toLowerCase().contains(lowerQuery)) return true;
          
          // Cari di kata kunci
          if (doa.kataKunci.any((kata) => kata.toLowerCase().contains(lowerQuery))) {
            return true;
          }
          
          return false;
        }).toList();
      }
    });
  }

  double _getResponsiveFontSize(double screenWidth, {required double base}) {
    if (screenWidth < 360) {
      return base * 0.9;
    } else if (screenWidth < 400) {
      return base;
    } else if (screenWidth < 600) {
      return base * 1.05;
    } else {
      return base * 1.1;
    }
  }

  double _getResponsivePadding(double screenWidth, {required double base}) {
    if (screenWidth < 360) {
      return base * 0.85;
    } else if (screenWidth < 600) {
      return base;
    } else {
      return base * 1.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(screenWidth),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(_getResponsivePadding(screenWidth, base: 16)),
              child: _buildSearchBar(screenWidth),
            ),
          ),
          if (_searchQuery.isNotEmpty && _filteredDoas.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _getResponsivePadding(screenWidth, base: 16),
                  0,
                  _getResponsivePadding(screenWidth, base: 16),
                  8,
                ),
                child: Text(
                  'Ditemukan ${_filteredDoas.length} doa',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(screenWidth, base: 13),
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          _buildContent(screenWidth),
        ],
      ),
    );
  }

  Widget _buildAppBar(double screenWidth) {
    final titleFontSize = _getResponsiveFontSize(screenWidth, base: 18);
    final iconSize = screenWidth < 360 ? 100.0 : 120.0;
    final expandedHeight = screenWidth < 360 ? 110.0 : 120.0;
    
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF059669),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Doa-Doa Harian',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF059669),
                Color(0xFF047857),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: iconSize,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        iconSize: screenWidth < 360 ? 22 : 24,
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    final hintFontSize = _getResponsiveFontSize(screenWidth, base: 14);
    final iconSize = screenWidth < 360 ? 20.0 : 24.0;
    final verticalPadding = screenWidth < 360 ? 12.0 : 14.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterDoas,
        style: TextStyle(fontSize: hintFontSize),
        decoration: InputDecoration(
          hintText: 'Cari doa, kata kunci...',
          hintStyle: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: hintFontSize,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFF059669),
            size: iconSize,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Color(0xFF9CA3AF)),
                  iconSize: iconSize,
                  onPressed: () {
                    _searchController.clear();
                    _filterDoas('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: verticalPadding,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(double screenWidth) {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF059669),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat doa...',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, base: 14),
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredDoas.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: screenWidth < 360 ? 56 : 64,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'Tidak ada doa' : 'Doa tidak ditemukan',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(screenWidth, base: 16),
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _getResponsivePadding(screenWidth, base: 24),
                ),
                child: Text(
                  _searchQuery.isEmpty 
                      ? 'Silakan tambahkan doa di file JSON'
                      : 'Coba kata kunci lain',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(screenWidth, base: 14),
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        _getResponsivePadding(screenWidth, base: 16),
        0,
        _getResponsivePadding(screenWidth, base: 16),
        16,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final doa = _filteredDoas[index];
            return _buildDoaCard(doa, index, screenWidth);
          },
          childCount: _filteredDoas.length,
        ),
      ),
    );
  }

  Widget _buildDoaCard(Doa doa, int index, double screenWidth) {
    final cardPadding = _getResponsivePadding(screenWidth, base: 16);
    final iconSize = screenWidth < 360 ? 44.0 : 48.0;
    final idFontSize = _getResponsiveFontSize(screenWidth, base: 16);
    final titleFontSize = _getResponsiveFontSize(screenWidth, base: 14);
    final subtitleFontSize = _getResponsiveFontSize(screenWidth, base: 12);
    final spacing = screenWidth < 360 ? 12.0 : 16.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoaDetailPage(
                doas: _filteredDoas,
                initialIndex: index,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF059669),
                      Color(0xFF047857),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    doa.idDoa,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: idFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doa.nama,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      doa.arti,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: screenWidth < 360 ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}