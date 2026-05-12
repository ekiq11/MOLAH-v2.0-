// screens/util/error_handler.dart - BEAUTIFUL ERROR UI
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorHandler {
  // ========== ERROR TYPES ==========

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    ErrorType type = ErrorType.error,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _ErrorSnackBarContent(
          title: title,
          message: message,
          type: type,
          onRetry: onRetry,
          isTablet: isTablet,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(isTablet ? 20 : 16),
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ========== QUICK METHODS ==========

  static void showSuccess(
    BuildContext context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showError(
      context,
      title: title,
      message: message ?? 'Operasi berhasil!',
      type: ErrorType.success,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 4),
  }) {
    showError(
      context,
      title: title,
      message: message ?? 'Harap perhatikan peringatan ini',
      type: ErrorType.warning,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showError(
      context,
      title: title,
      message: message ?? 'Informasi penting',
      type: ErrorType.info,
      duration: duration,
    );
  }

  // ========== DIALOG ERRORS ==========

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    ErrorType type = ErrorType.error,
    String? details,
    VoidCallback? onRetry,
    bool barrierDismissible = true,
  }) async {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _ErrorDialog(
        title: title,
        message: message,
        type: type,
        details: details,
        onRetry: onRetry,
        isTablet: isTablet,
      ),
    );
  }

  // ========== NOTIFICATION SPECIFIC ERRORS ==========

  static void showNotificationError(
    BuildContext context, {
    required String operation,
    required dynamic error,
    VoidCallback? onRetry,
  }) {
    String title;
    String message;
    ErrorType type = ErrorType.error;

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission')) {
      title = 'Izin Diperlukan';
      message =
          'Aplikasi memerlukan izin notifikasi. Silakan aktifkan di pengaturan.';
      type = ErrorType.warning;
    } else if (errorString.contains('asset') ||
        errorString.contains('not found')) {
      title = 'File Tidak Ditemukan';
      message =
          'File audio adzan tidak ditemukan. Coba install ulang aplikasi.';
      type = ErrorType.error;
    } else if (errorString.contains('player') ||
        errorString.contains('audio')) {
      title = 'Masalah Audio';
      message = 'Gagal memutar audio. Pastikan volume tidak dalam mode silent.';
      type = ErrorType.warning;
    } else if (errorString.contains('schedule')) {
      title = 'Gagal Menjadwalkan';
      message =
          'Tidak dapat menjadwalkan notifikasi. Periksa pengaturan alarm.';
      type = ErrorType.error;
    } else {
      title = 'Operasi Gagal';
      message = 'Terjadi kesalahan saat $operation. Silakan coba lagi.';
      type = ErrorType.error;
    }

    showError(
      context,
      title: title,
      message: message,
      type: type,
      onRetry: onRetry,
      duration: Duration(seconds: 5),
    );
  }
}

// ========== ERROR TYPES ENUM ==========

enum ErrorType { success, error, warning, info }

// ========== SNACKBAR CONTENT WIDGET ==========

class _ErrorSnackBarContent extends StatefulWidget {
  final String title;
  final String message;
  final ErrorType type;
  final VoidCallback? onRetry;
  final bool isTablet;

  const _ErrorSnackBarContent({
    required this.title,
    required this.message,
    required this.type,
    this.onRetry,
    required this.isTablet,
  });

  @override
  State<_ErrorSnackBarContent> createState() => _ErrorSnackBarContentState();
}

class _ErrorSnackBarContentState extends State<_ErrorSnackBarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case ErrorType.success:
        return Color(0xFF10B981);
      case ErrorType.error:
        return Color(0xFFEF4444);
      case ErrorType.warning:
        return Color(0xFFF59E0B);
      case ErrorType.info:
        return Color(0xFF3B82F6);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ErrorType.success:
        return Icons.check_circle_rounded;
      case ErrorType.error:
        return Icons.error_rounded;
      case ErrorType.warning:
        return Icons.warning_rounded;
      case ErrorType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.isTablet ? 14.0 : 13.0;
    final titleSize = widget.isTablet ? 15.0 : 14.0;
    final iconSize = widget.isTablet ? 28.0 : 24.0;
    final padding = widget.isTablet ? 18.0 : 16.0;

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getBackgroundColor(),
                _getBackgroundColor().withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _getBackgroundColor().withValues(alpha: 0.4),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with pulse animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(widget.isTablet ? 10 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(),
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                  );
                },
                onEnd: () {
                  if (mounted) setState(() {});
                },
              ),

              SizedBox(width: 14),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.white.withValues(alpha: 0.95),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Retry button (optional)
              if (widget.onRetry != null) ...[
                SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      widget.onRetry?.call();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isTablet ? 14 : 12,
                        vertical: widget.isTablet ? 8 : 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: widget.isTablet ? 18 : 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontSize: fontSize - 1,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
}

// ========== ERROR DIALOG WIDGET ==========

class _ErrorDialog extends StatefulWidget {
  final String title;
  final String message;
  final ErrorType type;
  final String? details;
  final VoidCallback? onRetry;
  final bool isTablet;

  const _ErrorDialog({
    required this.title,
    required this.message,
    required this.type,
    this.details,
    this.onRetry,
    required this.isTablet,
  });

  @override
  State<_ErrorDialog> createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<_ErrorDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.type) {
      case ErrorType.success:
        return Color(0xFF10B981);
      case ErrorType.error:
        return Color(0xFFEF4444);
      case ErrorType.warning:
        return Color(0xFFF59E0B);
      case ErrorType.info:
        return Color(0xFF3B82F6);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ErrorType.success:
        return Icons.check_circle_outline_rounded;
      case ErrorType.error:
        return Icons.error_outline_rounded;
      case ErrorType.warning:
        return Icons.warning_amber_rounded;
      case ErrorType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final fontSize = widget.isTablet ? 14.0 : 13.0;
    final titleSize = widget.isTablet ? 18.0 : 16.0;
    final iconSize = widget.isTablet ? 64.0 : 56.0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.isTablet ? 500 : 340),
          padding: EdgeInsets.all(widget.isTablet ? 28 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withValues(alpha: 0.05)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(widget.isTablet ? 18 : 16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(), size: iconSize, color: color),
                    ),
                  );
                },
              ),

              SizedBox(height: widget.isTablet ? 24 : 20),

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12),

              // Message
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Details (expandable)
              if (widget.details != null) ...[
                SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showDetails
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: widget.isTablet ? 22 : 20,
                          color: color,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _showDetails
                              ? 'Sembunyikan Detail'
                              : 'Lihat Detail Error',
                          style: TextStyle(
                            fontSize: fontSize - 1,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showDetails) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(widget.isTablet ? 14 : 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Text(
                      widget.details!,
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        fontFamily: 'Courier',
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],

              SizedBox(height: widget.isTablet ? 28 : 24),

              // Action buttons
              Row(
                children: [
                  if (widget.onRetry != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onRetry?.call();
                        },
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: widget.isTablet ? 20 : 18,
                        ),
                        label: Text(
                          'Coba Lagi',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          padding: EdgeInsets.symmetric(
                            vertical: widget.isTablet ? 14 : 12,
                          ),
                          side: BorderSide(color: color, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: widget.isTablet ? 14 : 12,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
