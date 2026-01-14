// screens/dzikir_main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizab_molah/dzikir/screens/list_dzikir.dart';

class DzikirMainPage extends StatelessWidget {
  const DzikirMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C3AED),
              Color(0xFF6D28D9),
              Color(0xFF5B21B6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, screenWidth),
              Expanded(
                child: _buildContent(context, screenWidth, screenHeight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Dzikir Pagi & Petang',
                style: TextStyle(
                  fontSize: screenWidth < 360 ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: 20),
          
          // Header Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 50,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 24),

          Text(
            'Pilihlah Waktu Dzikir',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 12),

          Text(
            'Bacalah dzikir untuk ketenangan jiwa\ndan keberkahan hidup',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth < 360 ? 14 : 15,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),

          SizedBox(height: 40),

          // Dzikir Pagi Card - Hijau
          _buildDzikirCard(
            context: context,
            title: 'Dzikir Pagi',
            subtitle: 'Setelah Shubuh sampai Terbit Matahari',
            icon: Icons.wb_sunny,
            gradientColors: [
              Color(0xFF10B981), // Hijau terang
              Color(0xFF059669), // Hijau emerald
            ],
            type: 'pagi',
            screenWidth: screenWidth,
          ),

          SizedBox(height: 20),

          // Dzikir Petang Card - Abu Gelap
          _buildDzikirCard(
            context: context,
            title: 'Dzikir Petang',
            subtitle: 'Setelah Ashar sampai Terbenam Matahari',
            icon: Icons.nights_stay,
            gradientColors: [
              Color(0xFF334155), // Abu slate
              Color(0xFF1E293B), // Abu gelap slate
            ],
            type: 'petang',
            screenWidth: screenWidth,
          ),

          SizedBox(height: 40),

          // Info Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dzikir pagi dan petang adalah amalan yang sangat dianjurkan untuk perlindungan dan keberkahan',
                    style: TextStyle(
                      fontSize: screenWidth < 360 ? 12 : 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDzikirCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required String type,
    required double screenWidth,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DzikirListPage(type: type),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[1].withOpacity(0.4),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: screenWidth < 360 ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: screenWidth < 360 ? 12 : 13,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}