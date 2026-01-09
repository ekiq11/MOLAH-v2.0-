import 'package:flutter/material.dart';
import 'package:pizab_molah/pelanggaran/model/reward_model.dart';


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
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
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
                              if (displayName.isNotEmpty)
                                Text(
                                  displayName,
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
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.cloud_off, color: Colors.white, size: 18),
                              ),
                            if (isFromCache) SizedBox(height: 8),
                            GestureDetector(
                              onTap: onRefresh,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.refresh, color: Colors.white, size: 18),
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
          ),
        ),
      );
    },
  );
}

Widget buildInfoChip(IconData icon, String text) {
  return Container(
    constraints: BoxConstraints(maxWidth: 160),
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.25),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
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
          : Color(0xFFDC2626);

  return Expanded(
    child: GestureDetector(
      onTap: () => onTabChanged(value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected ? activeColor.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 4,
              offset: Offset(0, isSelected ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
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
              border: isToday ? Border.all(color: primaryColor, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: isToday ? primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: Offset(0, 5),
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
                            ? [Color(0xFF4CAF50).withOpacity(0.1), Colors.white]
                            : [Color(0xFFFF5252).withOpacity(0.1), Colors.white],
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
                                  color: primaryColor.withOpacity(0.3),
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
                                color: primaryColor.withOpacity(0.15),
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
                                color: primaryColor.withOpacity(0.15),
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
                              color: primaryColor.withOpacity(0.08),
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
          color: color.withOpacity(0.1),
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