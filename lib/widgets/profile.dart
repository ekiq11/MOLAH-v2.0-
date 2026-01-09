import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  final String nisn;
  final Map<String, dynamic>? santriData;

  const ProfilePage({
    super.key,
    required this.nisn,
    this.santriData,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _data => widget.santriData ?? {};

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profil Santri',
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Header Card
                  _buildProfileHeader(isSmallScreen),
                  
                  SizedBox(height: 20),
                  
                  // Academic Info Section
                  _buildSectionHeader('Informasi Akademik', Icons.school_rounded, Colors.blue),
                  SizedBox(height: 12),
                  _buildAcademicInfo(isSmallScreen),
                  
                  SizedBox(height: 24),
                  
                  // Status Section
                  _buildSectionHeader('Status & Laporan', Icons.assessment_rounded, Colors.purple),
                  SizedBox(height: 12),
                  _buildStatusInfo(isSmallScreen),
                  
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isSmallScreen) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: Color(0xFFDC2626),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Profil Santri',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFDC2626),
                Color(0xFFB91C1C),
                Color(0xFF991B1B),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isSmallScreen) {
    String name = _data['nama'] ?? 'Nama Santri';
    String nisn = widget.nisn;
    String initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Container(
      margin: EdgeInsets.fromLTRB(0, 8, 0, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDC2626),
            Color(0xFFB91C1C),
            Color(0xFF991B1B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFDC2626).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.white.withOpacity(0.7)],
                      ),
                    ),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 160),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.badge_outlined, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      nisn,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_data['kelas'] != null && _data['kelas'].toString().isNotEmpty)
                              Container(
                                constraints: BoxConstraints(maxWidth: 160),
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.school_outlined, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _data['kelas'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Detail informasi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfo(bool isSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = isSmallScreen ? 12.0 : 16.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        final cards = [
          _InfoCardData(
            title: 'KELAS',
            value: _data['kelas'] ?? 'Belum Ada',
            icon: Icons.class_rounded,
            gradientColors: [Colors.blue[400]!, Colors.blue[600]!],
            bgColor: Colors.blue[50]!,
          ),
          _InfoCardData(
            title: 'LEMBAGA',
            value: _getLembagaShortName(_data['lembaga']),
            icon: Icons.account_balance_rounded,
            gradientColors: [Colors.cyan[400]!, Colors.cyan[600]!],
            bgColor: Colors.cyan[50]!,
          ),
          _InfoCardData(
            title: 'ASRAMA',
            value: _getCleanedAsramaName(_data['asrama']),
            icon: Icons.home_rounded,
            gradientColors: [Colors.indigo[400]!, Colors.indigo[600]!],
            bgColor: Colors.indigo[50]!,
          ),
          _InfoCardData(
            title: 'STATUS',
            value: _data['status'] ?? 'Aktif',
            icon: Icons.verified_user_rounded,
            gradientColors: [Colors.teal[400]!, Colors.teal[600]!],
            bgColor: Colors.teal[50]!,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((cardData) {
            return SizedBox(
              width: itemWidth,
              child: _buildFlexibleCard(cardData: cardData, itemWidth: itemWidth, isSmallScreen: isSmallScreen),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatusInfo(bool isSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = isSmallScreen ? 12.0 : 16.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        final cards = [
          _InfoCardData(
            title: 'ABSENSI',
            value: _data['absensi'] ?? 'KBM Belum dimulai',
            icon: Icons.calendar_today_rounded,
            gradientColors: [Colors.purple[400]!, Colors.purple[600]!],
            bgColor: Colors.purple[50]!,
          ),
          _InfoCardData(
            title: 'HAFALAN',
            value: _formatHafalan(_data['jumlah_hafalan']),
            icon: Icons.menu_book_rounded,
            gradientColors: [Colors.deepPurple[400]!, Colors.deepPurple[600]!],
            bgColor: Colors.deepPurple[50]!,
          ),
          _InfoCardData(
            title: 'STATUS IZIN',
            value: _data['status_izin'] ?? 'Sedang Dipondok',
            icon: Icons.assignment_rounded,
            gradientColors: [Colors.pink[400]!, Colors.pink[600]!],
            bgColor: Colors.pink[50]!,
          ),
          _InfoCardData(
            title: 'IZIN TERAKHIR',
            value: _formatIzinTerakhir(_data['izin_terakhir']),
            icon: Icons.event_rounded,
            gradientColors: [Colors.red[400]!, Colors.red[600]!],
            bgColor: Colors.red[50]!,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((cardData) {
            return SizedBox(
              width: itemWidth,
              child: _buildFlexibleCard(cardData: cardData, itemWidth: itemWidth, isSmallScreen: isSmallScreen),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFlexibleCard({
    required _InfoCardData cardData,
    required double itemWidth,
    required bool isSmallScreen,
  }) {
    final double paddingValue = itemWidth < 160 ? 12 : (itemWidth < 200 ? 14 : 16);
    final double iconSize = itemWidth < 160 ? 20 : (itemWidth < 200 ? 22 : 24);
    final double titleFontSize = itemWidth < 160 ? 10 : (itemWidth < 200 ? 10.5 : 11);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardData.gradientColors[1].withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardData.bgColor.withOpacity(0.3),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(paddingValue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(itemWidth < 160 ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: cardData.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cardData.gradientColors[1].withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(cardData.icon, color: Colors.white, size: iconSize),
                ),
                SizedBox(height: 10),
                Text(
                  cardData.title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Text(
                  cardData.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCleanedAsramaName(String? asrama) {
    if (asrama == null || asrama.isEmpty) return 'Belum Ada';
    final normalized = asrama.trim().toUpperCase();
    final binIndex = normalized.indexOf(' BIN ');
    if (binIndex != -1) {
      return normalized.substring(0, binIndex).trim();
    }
    return asrama.trim();
  }

  String _getLembagaShortName(String? lembaga) {
    if (lembaga == null || lembaga.isEmpty) return 'Belum Ada';
    return lembaga.length >= 3 ? lembaga.substring(0, 3).toUpperCase() : lembaga.toUpperCase();
  }

  String _formatHafalan(dynamic hafalanData) {
    if (hafalanData == null) return 'Belum terdata';
    final hafalanString = hafalanData.toString().trim();
    if (hafalanString.isEmpty || hafalanString == '-' || hafalanString.toLowerCase() == 'null' || hafalanString == '0') {
      return 'Belum terdata';
    }
    return '$hafalanString Juz';
  }

  String _formatIzinTerakhir(dynamic izinData) {
    if (izinData == null) return 'Belum Pernah Izin';
    final izinString = izinData.toString().trim();
    if (izinString.isEmpty || izinString == '-' || izinString.toLowerCase() == 'null' || izinString.toLowerCase() == 'belum ada') {
      return 'Belum Pernah Izin';
    }
    return izinString;
  }
}

class _InfoCardData {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final Color bgColor;

  _InfoCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.bgColor,
  });
}