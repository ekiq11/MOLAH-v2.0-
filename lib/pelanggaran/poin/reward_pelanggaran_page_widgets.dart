import 'package:flutter/material.dart';
import 'package:pizab_molah/pelanggaran/model/reward_model.dart';
import 'package:google_fonts/google_fonts.dart';


// Extension untuk _RewardPelanggaranPageState
// Taruh methods ini di dalam class _RewardPelanggaranPageState

// Student Header Widget
Widget buildStudentHeader(
  BuildContext context,
  AnimationController controller,
  Animation<double> slideAnimation,
  Animation<double> fadeAnimation,
  String displayName,
  String nisn,
  String kelasAsrama,
  bool isFromCache,
  VoidCallback onRefresh,
) {
  if (displayName.isEmpty && kelasAsrama.isEmpty) {
    return SizedBox.shrink();
  }

  return AnimatedBuilder(
    animation: controller,
    builder: (context, child) {
      return Transform.translate(
        offset: Offset(0, slideAnimation.value),
        child: Opacity(
          opacity: fadeAnimation.value,
          child: Container(
            margin: EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.blue[600],
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (displayName.isNotEmpty)
                            Text(
                              displayName,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1A1A1A),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              buildInfoChip(Icons.badge_outlined, nisn),
                              if (kelasAsrama.isNotEmpty)
                                buildInfoChip(Icons.school_outlined, kelasAsrama),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFromCache)
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.cloud_off, color: Colors.grey[600], size: 18),
                          ),
                        if (isFromCache) SizedBox(height: 8),
                        GestureDetector(
                          onTap: onRefresh,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.refresh, color: Colors.grey[600], size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget buildInfoChip(IconData icon, String text) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8E8E8E)),
        SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF8E8E8E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// Tab Button Widget
Widget buildTabButton(
  String value,
  String label,
  int count,
  IconData icon,
  String selectedTab,
  Function(String) onTabChanged,
) {
  bool isSelected = selectedTab == value;
  Color activeColor = value == 'reward'
      ? Color(0xFF4CAF50)
      : value == 'pelanggaran'
          ? Color(0xFFDC2626)
          : Color(0xFF10B981);

  return Expanded(
    child: GestureDetector(
      onTap: () => onTabChanged(value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30), // Pill shape
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.grey[500],
              size: 16,
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? activeColor : Colors.grey[700],
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// Data Card Widget
Widget buildDataCard(RewardPelanggaranData data, int index, DateTime? parsedDate) {
  bool isReward = data.isReward;
  bool isToday = false;

  if (parsedDate != null) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime cardDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    isToday = cardDate == today;
  }

  Color primaryColor = isReward ? Color(0xFF4CAF50) : Color(0xFFDC2626);

  return TweenAnimationBuilder(
    duration: Duration(milliseconds: 300 + (index * 50)),
    tween: Tween<double>(begin: 0, end: 1),
    builder: (context, double value, child) {
      return Transform.scale(
        scale: 0.95 + (0.05 * value),
        child: Opacity(
          opacity: value,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isToday ? primaryColor.withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                width: isToday ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isToday ? primaryColor.withValues(alpha: 0.15) : const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isReward
                            ? [Color(0xFF4CAF50).withValues(alpha: 0.1), Colors.white]
                            : [Color(0xFFFF5252).withValues(alpha: 0.1), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isReward ? Icons.star_rounded : Icons.warning_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    isReward ? 'REWARD' : 'PELANGGARAN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isToday) ...[
                          SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFF2196F3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.today, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'HARI INI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        Spacer(),
                        if (isReward && data.jumlahReward.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.emoji_events, color: primaryColor, size: 16),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      data.jumlahReward,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (!isReward && data.jumlahPelanggaran.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.remove_circle, color: primaryColor, size: 16),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      data.jumlahPelanggaran,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.jenisEtika.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data.jenisEtika,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isReward ? Color(0xFF2E7D32) : Color(0xFFD32F2F),
                                height: 1.4,
                              ),
                            ),
                          ),
                        if (data.rincianKejadian.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Text(
                            data.rincianKejadian,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        buildDetailRow(Icons.calendar_today, data.hariTanggal, Color(0xFF2196F3)),
                        if (data.waktu.isNotEmpty) ...[
                          SizedBox(height: 10),
                          buildDetailRow(Icons.access_time, data.waktu, Color(0xFFFF9800)),
                        ],
                        if (data.tempatKejadian.isNotEmpty) ...[
                          SizedBox(height: 10),
                          buildDetailRow(Icons.location_on, data.tempatKejadian, Color(0xFF4CAF50)),
                        ],
                        if (data.ustadzGuru.isNotEmpty) ...[
                          SizedBox(height: 10),
                          buildDetailRow(Icons.person, 'Pelapor: ${data.ustadzGuru}', Color(0xFF9C27B0)),
                        ],
                      ],
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
}

Widget buildDetailRow(IconData icon, String text, Color color) {
  return Row(
    children: [
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}