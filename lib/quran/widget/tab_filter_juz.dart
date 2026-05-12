// widgets/juz_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:pizab_molah/quran/model/juz_model.dart';

// ✨ PREMIUM JUZ FILTER - Modern & Elegant
class JuzFilterWidget extends StatelessWidget {
  final int selectedJuz;
  final Function(int) onJuzSelected;
  final bool isTablet;

  const JuzFilterWidget({
    super.key,
    required this.selectedJuz,
    required this.onJuzSelected,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 12 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan info terpilih
          _buildHeader(),

          SizedBox(height: isTablet ? 14 : 12),

          // Grid Filter
          _buildFilterGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 16,
        vertical: isTablet ? 14 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF059669).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 40 : 36,
            height: isTablet ? 40 : 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: Colors.white,
              size: isTablet ? 22 : 20,
            ),
          ),

          SizedBox(width: isTablet ? 14 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Juz',
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  selectedJuz == 0
                      ? 'Semua Surah (1-114)'
                      : _getJuzDescription(selectedJuz),
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Reset button (jika ada filter aktif)
          if (selectedJuz != 0)
            GestureDetector(
              onTap: () => onJuzSelected(0),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 8 : 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: isTablet ? 18 : 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      child: Column(
        children: [
          // Baris 1: Semua + Juz 1-5
          _buildFilterRow([0, 1, 2, 3, 4, 5]),

          SizedBox(height: isTablet ? 10 : 8),

          // Baris 2: Juz 6-11
          _buildFilterRow([6, 7, 8, 9, 10, 11]),

          SizedBox(height: isTablet ? 10 : 8),

          // Baris 3: Juz 12-17
          _buildFilterRow([12, 13, 14, 15, 16, 17]),

          SizedBox(height: isTablet ? 10 : 8),

          // Baris 4: Juz 18-23
          _buildFilterRow([18, 19, 20, 21, 22, 23]),

          SizedBox(height: isTablet ? 10 : 8),

          // Baris 5: Juz 24-29
          _buildFilterRow([24, 25, 26, 27, 28, 29]),

          SizedBox(height: isTablet ? 10 : 8),

          // Baris 6: Juz 30 (Amma) - Special
          _buildJuzAmmaButton(),
        ],
      ),
    );
  }

  Widget _buildFilterRow(List<int> juzNumbers) {
    return Row(
      children: juzNumbers.map((juzNum) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 4 : 3),
            child: _buildFilterButton(juzNum),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterButton(int juzNum) {
    final isSelected = selectedJuz == juzNum;
    final isAllButton = juzNum == 0;

    return GestureDetector(
      onTap: () => onJuzSelected(juzNum),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: isTablet ? 48 : 44,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Color(0xFF059669) : Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF059669).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isAllButton
              ? Icon(
                  Icons.apps_rounded,
                  color: isSelected ? Colors.white : Color(0xFF6B7280),
                  size: isTablet ? 22 : 20,
                )
              : Text(
                  '$juzNum',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : Color(0xFF374151),
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildJuzAmmaButton() {
    final isSelected = selectedJuz == 30;

    return GestureDetector(
      onTap: () => onJuzSelected(30),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: isTablet ? 52 : 48,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Color(0xFFF59E0B) : Color(0xFFFBBF24),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? Color(0xFFF59E0B) : Color(0xFFFBBF24))
                  .withValues(alpha: 0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_rounded,
              color: isSelected ? Colors.white : Color(0xFFD97706),
              size: isTablet ? 22 : 20,
            ),
            SizedBox(width: 8),
            Text(
              'Juz 30 - Juz Amma',
              style: TextStyle(
                fontSize: isTablet ? 16 : 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Color(0xFFD97706),
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.star_rounded,
              color: isSelected ? Colors.white : Color(0xFFD97706),
              size: isTablet ? 22 : 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getJuzDescription(int juzNum) {
    final juz = JuzData.getJuzByNumber(juzNum);
    if (juz == null) return 'Juz $juzNum';

    final surahCount = juz.surahIds.length;
    if (juzNum == 30) {
      return 'Juz Amma • 37 Surah';
    }
    return 'Juz $juzNum • $surahCount Surah';
  }
}

// ✨ ALTERNATIVE: Minimal Horizontal Scroll Style
class JuzHorizontalFilter extends StatelessWidget {
  final int selectedJuz;
  final Function(int) onJuzSelected;
  final bool isTablet;

  const JuzHorizontalFilter({
    super.key,
    required this.selectedJuz,
    required this.onJuzSelected,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isTablet ? 24 : 16,
        right: isTablet ? 24 : 16,
        top: isTablet ? 12 : 10,
        bottom: isTablet ? 16 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: EdgeInsets.only(
              left: isTablet ? 4 : 2,
              bottom: isTablet ? 12 : 10,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: isTablet ? 18 : 16,
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 10),
                Text(
                  'Pilih Juz',
                  style: TextStyle(
                    fontSize: isTablet ? 17 : 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                Spacer(),
                if (selectedJuz != 0)
                  TextButton.icon(
                    onPressed: () => onJuzSelected(0),
                    icon: Icon(Icons.clear_all_rounded, size: 18),
                    label: Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF059669),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 14 : 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Horizontal scroll
          SizedBox(
            height: isTablet ? 56 : 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 31, // 0 (Semua) + 30 Juz
              itemBuilder: (context, index) {
                final juzNum = index == 0 ? 0 : index;
                return _buildChip(juzNum);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(int juzNum) {
    final isSelected = selectedJuz == juzNum;
    final isAll = juzNum == 0;
    final isAmma = juzNum == 30;

    return GestureDetector(
      onTap: () => onJuzSelected(juzNum),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: isTablet ? 10 : 8),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 18,
          vertical: isTablet ? 12 : 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (isAmma
                    ? LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      )
                    : LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                      ))
              : null,
          color: isSelected
              ? null
              : (isAmma ? Color(0xFFFEF3C7) : Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isAmma ? Color(0xFFF59E0B) : Color(0xFF059669))
                : (isAmma ? Color(0xFFFBBF24) : Color(0xFFE5E7EB)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isAmma ? Color(0xFFF59E0B) : Color(0xFF059669))
                        .withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAll)
              Icon(
                Icons.apps_rounded,
                color: isSelected ? Colors.white : Color(0xFF6B7280),
                size: isTablet ? 20 : 18,
              )
            else if (isAmma)
              Icon(
                Icons.star_rounded,
                color: isSelected ? Colors.white : Color(0xFFD97706),
                size: isTablet ? 18 : 16,
              )
            else
              Container(
                padding: EdgeInsets.all(isTablet ? 5 : 4),
                decoration: BoxDecoration(
                  color: (isSelected ? Colors.white : Color(0xFF059669))
                      .withValues(alpha: isSelected ? 0.25 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: isSelected ? Colors.white : Color(0xFF059669),
                  size: isTablet ? 16 : 14,
                ),
              ),

            SizedBox(width: isTablet ? 10 : 8),

            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAll ? 'Semua' : (isAmma ? 'Juz Amma' : 'Juz $juzNum'),
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isAmma ? Color(0xFFD97706) : Color(0xFF111827)),
                    letterSpacing: -0.2,
                  ),
                ),
                if (!isAll)
                  Text(
                    isAmma ? '37 Surah' : _getSurahCount(juzNum),
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSurahCount(int juzNum) {
    final juz = JuzData.getJuzByNumber(juzNum);
    if (juz == null) return '';
    return '${juz.surahIds.length} Surah';
  }
}
