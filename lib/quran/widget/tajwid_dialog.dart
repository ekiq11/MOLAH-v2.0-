// quran/widget/tajwid_dialog.dart - ✅ COMPLETE Tajwid Guide with Color Visual
import 'package:flutter/material.dart';
import 'package:pizab_molah/quran/helper/tajwid_helper.dart';

class TajwidLegendDialog {
  static void show(BuildContext context) {
    final legends = TajwidHelper.getTajwidLegendsByCategory();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panduan Warna Tajwid',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${TajwidHelper.getTajwidLegends().length} hukum bacaan',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFD97706),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Teks berwarna menandakan hukum tajwid pada ayat Al-Qur\'an',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF92400E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Legends by category
                    ...legends.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryHeader(entry.key),
                          SizedBox(height: 12),
                          ...entry.value.map((legend) {
                            return _buildLegendItem(legend);
                          }),
                          SizedBox(height: 24),
                        ],
                      );
                    }),

                    // Footer note
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF059669),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pelajari tajwid untuk membaca Al-Qur\'an dengan benar sesuai kaidah',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF065F46),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCategoryHeader(String category) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF059669).withValues(alpha: 0.1),
            Color(0xFF047857).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Text(
            category,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildLegendItem(TajwidLegend legend) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with color indicator
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: legend.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Color indicator dengan huruf Arab berwarna
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: legend.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: legend.color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: legend.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'ٱ',
                      style: TextStyle(
                        fontFamily: 'Utsmani',
                        fontSize: 28,
                        color: legend.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        legend.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        legend.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Example section with colored text
          if (legend.example.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Contoh (teks berwarna):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Render example dengan tajwid color (tanpa shadow)
                  RichText(
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    text: TextSpan(
                      text: legend.example,
                      style: TextStyle(
                        fontFamily: 'Utsmani',
                        fontSize: 22,
                        color: legend.color,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Rule section
          if (legend.rule.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: legend.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: legend.color,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      legend.rule,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
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
}
