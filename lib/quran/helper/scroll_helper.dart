// quran/helper/scroll_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Ultimate scroll helper - Force render + Position calculation
class ScrollHelper {
  static void scrollToAyah({
    required ScrollController scrollController,
    required Map<int, GlobalKey> ayahKeys,
    required int targetAyah,
    required bool showTranslation,
    required VoidCallback onComplete,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 150), () {
        _forceRenderThenScroll(
          scrollController: scrollController,
          ayahKeys: ayahKeys,
          targetAyah: targetAyah,
          showTranslation: showTranslation,
          onComplete: onComplete,
        );
      });
    });
  }

  /// Strategy: Force render widgets dengan quick scan, lalu scroll precis
  static void _forceRenderThenScroll({
    required ScrollController scrollController,
    required Map<int, GlobalKey> ayahKeys,
    required int targetAyah,
    required bool showTranslation,
    required VoidCallback onComplete,
  }) {
    if (!scrollController.hasClients) {
      debugPrint('❌ ScrollController tidak ready');
      Future.delayed(Duration(milliseconds: 300), () {
        _forceRenderThenScroll(
          scrollController: scrollController,
          ayahKeys: ayahKeys,
          targetAyah: targetAyah,
          showTranslation: showTranslation,
          onComplete: onComplete,
        );
      });
      return;
    }

    debugPrint('🎯 Target: Ayat $targetAyah');

    // Cek apakah widget sudah ter-render
    final targetContext = ayahKeys[targetAyah]?.currentContext;

    if (targetContext != null) {
      debugPrint('✅ Widget sudah ada, direct scroll');
      _smoothScrollToContext(targetContext, onComplete);
      return;
    }

    // Widget belum ada - Force render dengan quick scan
    debugPrint('🔨 Force rendering widgets...');
    _quickScanToForceRender(
      scrollController: scrollController,
      ayahKeys: ayahKeys,
      targetAyah: targetAyah,
      showTranslation: showTranslation,
      onComplete: onComplete,
    );
  }

  /// Quick scan: Jump ke beberapa posisi untuk force render
  static void _quickScanToForceRender({
    required ScrollController scrollController,
    required Map<int, GlobalKey> ayahKeys,
    required int targetAyah,
    required bool showTranslation,
    required VoidCallback onComplete,
  }) {
    final maxScroll = scrollController.position.maxScrollExtent;
    final totalAyahs = ayahKeys.length;
    final avgHeight = showTranslation ? 320.0 : 200.0;

    // Estimasi posisi target dengan multiple factors
    final estimateByHeight = (targetAyah - 1) * avgHeight;
    final estimateByPercentage = maxScroll * ((targetAyah - 1) / totalAyahs);

    // Weight adjustment: untuk ayat jauh, lebih percaya percentage
    final weight = targetAyah > 50 ? 0.75 : 0.5;
    final targetPos =
        (estimateByPercentage * weight) + (estimateByHeight * (1 - weight));

    // Buat scan points dengan range lebih lebar untuk ayat jauh
    final scanRange = targetAyah > 100
        ? 4000.0
        : targetAyah > 50
        ? 2500.0
        : 1500.0;

    final scanPoints = {
      targetPos.clamp(0.0, maxScroll),
      (targetPos - scanRange * 0.5).clamp(0.0, maxScroll),
      (targetPos + scanRange * 0.5).clamp(0.0, maxScroll),
      (targetPos - scanRange).clamp(0.0, maxScroll),
      (targetPos + scanRange).clamp(0.0, maxScroll),
      (targetPos - scanRange * 1.5).clamp(0.0, maxScroll),
      (targetPos + scanRange * 1.5).clamp(0.0, maxScroll),
    }.toList(); // Remove duplicates

    debugPrint(
      '📍 Scanning ${scanPoints.length} positions (range: ${scanRange.toStringAsFixed(0)})...',
    );
    debugPrint(
      '📐 Target estimate: ${targetPos.toStringAsFixed(0)} (weight: $weight)',
    );

    _executeScanPoints(
      scrollController: scrollController,
      ayahKeys: ayahKeys,
      targetAyah: targetAyah,
      scanPoints: scanPoints,
      currentIndex: 0,
      showTranslation: showTranslation,
      onComplete: onComplete,
    );
  }

  /// Execute scan points satu per satu dengan check
  static void _executeScanPoints({
    required ScrollController scrollController,
    required Map<int, GlobalKey> ayahKeys,
    required int targetAyah,
    required List<double> scanPoints,
    required int currentIndex,
    required bool showTranslation,
    required VoidCallback onComplete,
  }) {
    if (!scrollController.hasClients) {
      debugPrint('❌ Controller lost');
      onComplete();
      return;
    }

    // Check if widget rendered
    final targetContext = ayahKeys[targetAyah]?.currentContext;
    if (targetContext != null) {
      debugPrint('✅ Widget ditemukan setelah ${currentIndex + 1} scan(s)!');
      _smoothScrollToContext(targetContext, onComplete);
      return;
    }

    // Jika masih ada scan points
    if (currentIndex < scanPoints.length) {
      final pos = scanPoints[currentIndex];
      debugPrint(
        '🔍 Scan ${currentIndex + 1}/${scanPoints.length}: ${pos.toStringAsFixed(0)}',
      );

      scrollController.jumpTo(pos);

      // Wait lebih lama untuk ayat jauh (biar sempat render)
      final waitTime = targetAyah > 100 ? 300 : 200;

      Future.delayed(Duration(milliseconds: waitTime), () {
        _executeScanPoints(
          scrollController: scrollController,
          ayahKeys: ayahKeys,
          targetAyah: targetAyah,
          scanPoints: scanPoints,
          currentIndex: currentIndex + 1,
          showTranslation: showTranslation,
          onComplete: onComplete,
        );
      });
    } else {
      // Semua scan selesai, gunakan position calculation
      debugPrint('💡 Using position calculation fallback');
      _usePositionCalculation(
        scrollController: scrollController,
        ayahKeys: ayahKeys,
        targetAyah: targetAyah,
        showTranslation: showTranslation,
        onComplete: onComplete,
      );
    }
  }

  /// Fallback: Hitung posisi dari ayat yang ter-render terdekat
  static void _usePositionCalculation({
    required ScrollController scrollController,
    required Map<int, GlobalKey> ayahKeys,
    required int targetAyah,
    required bool showTranslation,
    required VoidCallback onComplete,
  }) {
    if (!scrollController.hasClients) {
      onComplete();
      return;
    }

    // Cari ayat yang ter-render
    final renderedAyahs = <int, double>{};

    ayahKeys.forEach((ayahNum, key) {
      final context = key.currentContext;
      if (context != null) {
        try {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final position = box.localToGlobal(Offset.zero);
            final scrollPos = scrollController.offset + position.dy;
            renderedAyahs[ayahNum] = scrollPos;
          }
        } catch (e) {
          // Ignore
        }
      }
    });

    if (renderedAyahs.isEmpty) {
      debugPrint('❌ Tidak ada widget ter-render untuk kalkulasi');
      _useBasicEstimation(
        scrollController: scrollController,
        ayahKeys: ayahKeys,
        targetAyah: targetAyah,
        showTranslation: showTranslation,
        onComplete: onComplete,
      );
      return;
    }

    debugPrint('✅ Found ${renderedAyahs.length} rendered ayahs');

    // Cari ayat terdekat
    int? nearestAyah;
    double minDistance = double.infinity;

    renderedAyahs.forEach((ayahNum, pos) {
      final distance = (ayahNum - targetAyah).abs();
      if (distance < minDistance) {
        minDistance = distance.toDouble();
        nearestAyah = ayahNum;
      }
    });

    if (nearestAyah == null) {
      _useBasicEstimation(
        scrollController: scrollController,
        ayahKeys: ayahKeys,
        targetAyah: targetAyah,
        showTranslation: showTranslation,
        onComplete: onComplete,
      );
      return;
    }

    final nearestPos = renderedAyahs[nearestAyah]!;
    final avgHeight = showTranslation ? 320.0 : 200.0;
    final distance = targetAyah - nearestAyah!;
    final estimatedPos = nearestPos + (distance * avgHeight);

    final maxScroll = scrollController.position.maxScrollExtent;
    final targetPos = (estimatedPos - 300).clamp(
      0.0,
      maxScroll,
    ); // Offset lebih besar untuk positioning

    debugPrint('📐 Calculation: nearest=$nearestAyah, distance=$distance');
    debugPrint('📍 Target position: ${targetPos.toStringAsFixed(0)}');

    scrollController
        .animateTo(
          targetPos,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          debugPrint('✅ Scroll selesai');

          // Final check apakah widget sudah visible
          Future.delayed(Duration(milliseconds: 400), () {
            final finalContext = ayahKeys[targetAyah]?.currentContext;
            if (finalContext != null) {
              _smoothScrollToContext(finalContext, onComplete);
            } else {
              onComplete();
            }
          });
        });
  }

  /// Last resort: Basic estimation
  static void _useBasicEstimation({
    required ScrollController scrollController,
    required Map<int, GlobalKey> ayahKeys,
    required int targetAyah,
    required bool showTranslation,
    required VoidCallback onComplete,
  }) {
    if (!scrollController.hasClients) {
      onComplete();
      return;
    }

    final maxScroll = scrollController.position.maxScrollExtent;
    final totalAyahs = ayahKeys.length;
    final avgHeight = showTranslation ? 320.0 : 200.0;

    // Gunakan percentage-based untuk ayat jauh, height-based untuk ayat dekat
    final estimateByHeight = (targetAyah - 1) * avgHeight;
    final estimateByPercentage = maxScroll * ((targetAyah - 1) / totalAyahs);

    // Weight berbeda berdasarkan posisi ayat
    final weight = targetAyah > 100
        ? 0.85
        : // Sangat percaya percentage
          targetAyah > 50
        ? 0.70
        : 0.5;

    final estimatedPos =
        (estimateByPercentage * weight) + (estimateByHeight * (1 - weight));
    final targetPos = (estimatedPos - 300).clamp(0.0, maxScroll);

    debugPrint(
      '⚠️ Using basic estimation: ${targetPos.toStringAsFixed(0)} (weight: $weight)',
    );

    scrollController
        .animateTo(
          targetPos,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          debugPrint('✅ Scroll selesai (basic)');
          onComplete();
        });
  }

  /// Smooth scroll ke context yang ditemukan
  static void _smoothScrollToContext(
    BuildContext context,
    VoidCallback onComplete,
  ) {
    try {
      Scrollable.ensureVisible(
            context,
            duration: Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: 0.15,
          )
          .then((_) {
            debugPrint('✅ Final scroll complete');
            onComplete();
          })
          .catchError((e) {
            debugPrint('⚠️ ensureVisible error: $e');
            onComplete();
          });
    } catch (e) {
      debugPrint('❌ Scroll error: $e');
      onComplete();
    }
  }
}
