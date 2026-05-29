import 'dart:io';

void main() {
  final file = File('lib/home.dart');
  String content = file.readAsStringSync();

  // 1. Add imports if not exist
  if (!content.contains('package:pizab_molah/widgets/profile.dart')) {
    content = content.replaceFirst(
      "import 'widgets/bento_dashboard.dart';",
      "import 'widgets/bento_dashboard.dart';\nimport 'package:pizab_molah/widgets/profile.dart';\nimport 'package:pizab_molah/screens/reward.dart';"
    );
  }

  // 2. Modify _onBottomNavTap
  final oldOnBottomNavTap = '''  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _currentIndex = 0);
        break;
      case 1:
        setState(() => _currentIndex = 1);
        break;
      case 2:
        setState(() => _currentIndex = 2);
        break;
      case 3:
        _showLogoutDialog();
        break;
    }
  }''';

  final newOnBottomNavTap = '''  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
  }''';

  content = content.replaceFirst(oldOnBottomNavTap, newOnBottomNavTap);

  // 3. Update IndexedStack children
  final oldIndexedStack = '''                  index: _currentIndex,
                  children: [
                    _isLoading && _santriData.isEmpty
                        ? HomeShimmerLoading(screenSize: screenSize)
                        : _buildMainContent(screenSize),
                    NotificationTab(screenSize: screenSize, username: widget.username, onRefresh: _handleRefresh),
                    PaymentPage(
                      username: widget.username,
                      studentName: _santriData['nama'] ?? 'Santri',
                    ),
                  ],''';

  final newIndexedStack = '''                  index: _currentIndex,
                  children: [
                    _isLoading && _santriData.isEmpty
                        ? HomeShimmerLoading(screenSize: screenSize)
                        : _buildMainContent(screenSize),
                    PaymentPage(
                      username: widget.username,
                      studentName: _santriData['nama'] ?? 'Santri',
                    ),
                    RewardPelanggaranPage(
                      nisn: widget.username,
                      namaSantri: _santriData['nama'] ?? 'Santri',
                    ),
                    NotificationTab(
                      screenSize: screenSize,
                      username: widget.username,
                      onRefresh: _handleRefresh,
                    ),
                    ProfilePage(
                      nisn: widget.username,
                      santriData: _santriData,
                    ),
                  ],''';
  
  if (content.contains(oldIndexedStack)) {
    content = content.replaceFirst(oldIndexedStack, newIndexedStack);
  } else {
    print('Failed to find oldIndexedStack');
  }

  // 4. Custom Floating Bottom Navigation Bar
  final oldBottomNav = '''  Widget _buildBottomNavigationBar(Size screenSize) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex > 2 ? 0 : _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey[500],
        selectedFontSize: screenSize.width * 0.028,
        unselectedFontSize: screenSize.width * 0.025,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            // DIPERBAIKI: Gunakan ValueListenableBuilder untuk ikon notifikasi
            icon: ValueListenableBuilder<List<NotificationItem>>(
              valueListenable:
                  GoogleSheetsMonitorService.getNotificationsForUser(
                    widget.username,
                  ) ??
                  ValueNotifier([]),
              builder: (context, notifications, child) {
                final unreadCount = notifications
                    .where((n) => !n.isRead)
                    .length;
                return _buildNotificationIcon(unreadCount: unreadCount);
              },
            ),
            activeIcon: ValueListenableBuilder<List<NotificationItem>>(
              valueListenable:
                  GoogleSheetsMonitorService.getNotificationsForUser(
                    widget.username,
                  ) ??
                  ValueNotifier([]),
              builder: (context, notifications, child) {
                final unreadCount = notifications
                    .where((n) => !n.isRead)
                    .length;
                return _buildNotificationIcon(
                  unreadCount: unreadCount,
                  active: true,
                );
              },
            ),
            label: 'Notifikasi',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, color: Colors.grey),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Tagihan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_rounded, color: Colors.grey),
            activeIcon: Icon(Icons.logout_rounded, color: Colors.red[600]),
            label: 'Keluar',
          ),
        ],
      ),
    );
  }''';

  final newBottomNav = '''  Widget _buildBottomNavigationBar(Size screenSize) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: _currentIndex > 4 ? 0 : _currentIndex,
            onTap: _onBottomNavTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFF10B981),
            unselectedItemColor: Colors.grey[400],
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.receipt_long_rounded)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.receipt_long_rounded)),
                label: 'Tagihan',
              ),
              const BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.emoji_events_rounded)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.emoji_events_rounded)),
                label: 'Reward',
              ),
              BottomNavigationBarItem(
                icon: ValueListenableBuilder<List<NotificationItem>>(
                  valueListenable:
                      GoogleSheetsMonitorService.getNotificationsForUser(
                        widget.username,
                      ) ??
                      ValueNotifier([]),
                  builder: (context, notifications, child) {
                    final unreadCount = notifications
                        .where((n) => !n.isRead)
                        .length;
                    return Padding(padding: const EdgeInsets.only(bottom: 4), child: _buildNotificationIcon(unreadCount: unreadCount));
                  },
                ),
                activeIcon: ValueListenableBuilder<List<NotificationItem>>(
                  valueListenable:
                      GoogleSheetsMonitorService.getNotificationsForUser(
                        widget.username,
                      ) ??
                      ValueNotifier([]),
                  builder: (context, notifications, child) {
                    final unreadCount = notifications
                        .where((n) => !n.isRead)
                        .length;
                    return Padding(padding: const EdgeInsets.only(bottom: 4), child: _buildNotificationIcon(
                      unreadCount: unreadCount,
                      active: true,
                    ));
                  },
                ),
                label: 'Notif',
              ),
              const BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }''';

  if (content.contains(oldBottomNav)) {
    content = content.replaceFirst(oldBottomNav, newBottomNav);
  } else {
    print('Failed to find oldBottomNav');
  }

  // 5. If we use ImageFilter, we must import 'dart:ui' if not present
  if (!content.contains("import 'dart:ui';")) {
     content = "import 'dart:ui';\n" + content;
  }

  // 6. Make scaffold background extend to bottom nav
  final scaffoldBody = '''      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(''';
  
  final newScaffoldBody = '''      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBody: true, // Untuk floating nav bar
        body: SafeArea(
          bottom: false,''';

  if (content.contains(scaffoldBody)) {
    content = content.replaceFirst(scaffoldBody, newScaffoldBody);
  } else {
    print('Failed to find scaffoldBody');
  }

  file.writeAsStringSync(content);
  print('Patched home.dart successfully');
}
