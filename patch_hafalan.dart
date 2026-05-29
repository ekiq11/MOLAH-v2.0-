import 'dart:io';

void main() {
  final file = File('lib/screens/HafalanHistoryPage.dart');
  var content = file.readAsStringSync();

  // Patch Student Header
  final originalHeader = '''
          if (_currentNamaSantri.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.teal[600]!, Colors.teal[500]!],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: Text(
                      _currentNamaSantri[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentNamaSantri,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "NISN: \${widget.nisn}",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\${_allData.length} total',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
''';

  final newHeader = '''
          if (_currentNamaSantri.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal[400]!, Colors.teal[600]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _currentNamaSantri[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentNamaSantri,
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "NISN: \${widget.nisn}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '\${_allData.length}',
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Setoran',
                          style: TextStyle(
                            color: Colors.teal[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
''';

  content = content.replaceFirst(originalHeader, newHeader);

  // Now replace _buildSimpleCard
  final startCard = content.indexOf('  Widget _buildSimpleCard(HafalanData data, int index) {');
  final endCard = content.indexOf('  // Widget untuk loading indicator saat memuat data lebih banyak');
  
  if (startCard != -1 && endCard != -1) {
    final newCard = '''  Widget _buildSimpleCard(HafalanData data, int index) {
    bool isToday = false;
    bool isRecent = false;

    DateTime? parsedDate = _parseDateTime(data);
    if (parsedDate != null) {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime cardDate = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );

      isToday = cardDate == today;
      isRecent = now.difference(parsedDate).inDays <= 3 && !isToday;
    }

    List<Widget> cardChildren = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded, color: Colors.teal[600], size: 18),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isToday)
                        Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'HARI INI',
                            style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      else if (isRecent)
                        Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BARU',
                            style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Text(
                        _formatDate(data.tanggal),
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937), fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        _formatTime(data.waktu),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (data.nilai.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getNilaiColor(data.nilai).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data.nilai,
                style: TextStyle(
                  color: _getNilaiColor(data.nilai),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(height: 1, color: Colors.grey[200]),
      ),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mulai', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                SizedBox(height: 4),
                Text(
                  "\${data.surahAwal} \${data.ayatAwal}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey[400]),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sampai', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  SizedBox(height: 4),
                  Text(
                    "\${data.surahAkhir} \${data.ayatAkhir}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 16),
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.person_rounded, size: 16, color: Colors.grey[500]),
            SizedBox(width: 8),
            Text('Mustami:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                data.mustami,
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937), fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ];

    if (data.keterangan.isNotEmpty) {
      cardChildren.addAll([
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.keterangan,
                  style: TextStyle(color: Colors.orange[800], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ]);
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cardChildren,
      ),
    );
  }

''';
    content = content.substring(0, startCard) + newCard + content.substring(endCard);
  }

  file.writeAsStringSync(content);
  print('Patched HafalanHistoryPage.dart (Cleaned)');
}
