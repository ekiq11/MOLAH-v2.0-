// quran/widget/scroll_progress_overlay.dart
import 'package:flutter/material.dart';

/// Overlay untuk menampilkan progress saat auto-scroll
class ScrollProgressOverlay extends StatelessWidget {
  final int targetAyah;
  final String? message;
  final bool isVisible;

  const ScrollProgressOverlay({
    super.key,
    required this.targetAyah,
    this.message,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 32),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Islamic Pattern or Quran Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                SizedBox(height: 20),

                // Progress Indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF059669),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Message
                Text(
                  message ?? 'Membuka Ayat $targetAyah',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                Text(
                  'Mohon tunggu sebentar...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple loading overlay (minimal)
class SimpleScrollLoading extends StatelessWidget {
  final int targetAyah;
  final bool isVisible;

  const SimpleScrollLoading({
    super.key,
    required this.targetAyah,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Membuka Ayat $targetAyah...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
