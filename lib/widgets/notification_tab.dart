import 'package:flutter/material.dart';
import '../dialogs/notification_dialog.dart';

class NotificationTab extends StatelessWidget {
  final Size screenSize;
  final String username;
  final Future<void> Function() onRefresh;

  const NotificationTab({
    super.key,
    required this.screenSize,
    required this.username,
    required this.onRefresh,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}j';
    } else {
      return '${difference.inDays}h';
    }
  }

  Widget _buildEmptyNotifications(Size screenSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(screenSize.width * 0.08),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: screenSize.width * 0.16,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: screenSize.height * 0.03),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: screenSize.width * 0.045,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          Text(
            'Perubahan data akan muncul di sini',
            style: TextStyle(
              fontSize: screenSize.width * 0.035,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationItem notification,
    Size screenSize,
  ) {
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : Colors.blue[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          GoogleSheetsMonitorService.markAsReadForUser(
            username,
            notification.id,
          );
        },
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenSize.width * 0.02),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.grey[100]
                    : Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification.isRead ? Icons.info_outline : Icons.info,
                color: notification.isRead
                    ? Colors.grey[600]
                    : Colors.blue[600],
                size: screenSize.width * 0.05,
              ),
            ),
            SizedBox(width: screenSize.width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.only(
                            right: screenSize.width * 0.02,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: screenSize.width * 0.035,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          fontSize: screenSize.width * 0.028,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenSize.height * 0.005),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.032,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.005),
                  Text(
                    'Sumber: ${notification.sheetName}',
                    style: TextStyle(
                      fontSize: screenSize.width * 0.028,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
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

  Widget _buildEnhancedNotificationList(
    List<NotificationItem> notifications,
    Size screenSize,
  ) {
    return RefreshIndicator(
      color: const Color(0xFF10B981),
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        itemCount: notifications.length,
        separatorBuilder: (_, __) =>
            SizedBox(height: screenSize.height * 0.015),
        itemBuilder: (context, index) =>
            _buildNotificationItem(notifications[index], screenSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: ValueListenableBuilder<List<NotificationItem>>(
            valueListenable:
                GoogleSheetsMonitorService.getNotificationsForUser(username) ??
                ValueNotifier([]),
            builder: (context, notifications, child) {
              final unreadCount = notifications.where((n) => !n.isRead).length;
              return Row(
                children: [
                  Icon(Icons.notifications_active, color: const Color(0xFF10B981)),
                  SizedBox(width: screenSize.width * 0.03),
                  Flexible(
                    child: Text(
                      'Notifikasi ($unreadCount baru)',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: screenSize.width * 0.045,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          centerTitle: false,
          actions: [
            ValueListenableBuilder<List<NotificationItem>>(
              valueListenable:
                  GoogleSheetsMonitorService.getNotificationsForUser(
                    username,
                  ) ??
                  ValueNotifier([]),
              builder: (context, notifications, child) {
                if (notifications.isNotEmpty) {
                  return TextButton(
                    onPressed: () async {
                      await GoogleSheetsMonitorService.clearAllNotificationsForUser(
                        username,
                      );
                    },
                    child: Text(
                      'Hapus Semua',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                        fontSize: screenSize.width * 0.032,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        Expanded(
          child: ValueListenableBuilder<List<NotificationItem>>(
            valueListenable:
                GoogleSheetsMonitorService.getNotificationsForUser(username) ??
                ValueNotifier([]),
            builder: (context, notifications, child) {
              if (notifications.isEmpty) {
                return _buildEmptyNotifications(screenSize);
              }
              return _buildEnhancedNotificationList(notifications, screenSize);
            },
          ),
        ),
      ],
    );
  }
}
