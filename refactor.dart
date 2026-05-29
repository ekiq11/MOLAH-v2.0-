import 'dart:io';

void main() async {
  final file = File('lib/home.dart');
  if (!await file.exists()) {
    print('home.dart not found!');
    return;
  }

  String content = await file.readAsString();

  // Add imports
  final importStr = "import 'package:flutter/material.dart';\nimport 'widgets/home_shimmer.dart';\nimport 'widgets/notification_tab.dart';\n";
  content = content.replaceFirst("import 'package:flutter/material.dart';", importStr);

  // 1. Remove _shimmerController and _shimmerAnimation declarations
  content = content.replaceAll(RegExp(r'\s*late AnimationController _shimmerController;'), '');
  content = content.replaceAll(RegExp(r'\s*late Animation<double> _shimmerAnimation;'), '');

  // 2. Remove from dispose
  content = content.replaceAll(RegExp(r'\s*_shimmerController\.stop\(\);'), '');
  content = content.replaceAll(RegExp(r'\s*_shimmerController\.dispose\(\);'), '');

  // 3. Remove initialization
  content = content.replaceAll(RegExp(r'\s*_shimmerController = AnimationController\([\s\S]*?vsync: this,\s*\);'), '');
  content = content.replaceAll(RegExp(r'\s*_shimmerAnimation = Tween<double>\(begin: -1\.0, end: 1\.0\)\.animate\([\s\S]*?curve: Curves\.easeInOut\),\s*\);'), '');

  // 4. Remove shimmer usages
  content = content.replaceAll(RegExp(r'\s*if \(!_shimmerController\.isAnimating\) \{\s*_shimmerController\.repeat\(\);\s*\}'), '');
  content = content.replaceAll(RegExp(r'\s*if \(_shimmerController\.isAnimating\) \{\s*_shimmerController\.stop\(\);\s*\}'), '');
  content = content.replaceAll(RegExp(r'\s*if \(_santriData\.isEmpty && _isLoading\) \{\s*_shimmerController\.repeat\(\);\s*\}'), '');
  content = content.replaceAll(RegExp(r'\s*if \(_isLoading\) \{\s*_shimmerController\.repeat\(\);\s*\}'), '');

  // 5. Replace usages
  content = content.replaceAll('_buildLoadingState(screenSize)', 'HomeShimmerLoading(screenSize: screenSize)');
  content = content.replaceAll('_buildEnhancedNotificationPage(screenSize)', 'NotificationTab(screenSize: screenSize, username: widget.username, onRefresh: _handleRefresh)');

  // 7. Remove methods
  final idx1 = content.indexOf('Widget _buildEnhancedNotificationPage(Size screenSize) {');
  if (idx1 != -1) {
    final idx2 = content.indexOf('// --- TAMBAHAN BARU: Method untuk pemberitahuan ---');
    if (idx2 != -1) {
      content = content.substring(0, idx1) + content.substring(idx2);
    }
  }

  final methodsToRemove = [
    'Widget _buildLoadingState(Size screenSize) {',
    'Widget _buildShimmerContainer({',
    'Widget _buildHeaderShimmer(Size screenSize) {',
    'Widget _buildQuickActionsShimmer(Size screenSize) {',
    'Widget _buildReportShimmer(Size screenSize) {',
    'Widget _buildStudentInfoShimmer(Size screenSize) {'
  ];

  for (final method in methodsToRemove) {
    var idx = content.indexOf(method);
    while (idx != -1) {
      int braces = 0;
      bool started = false;
      int endIndex = -1;
      
      for (int i = idx; i < content.length; i++) {
        if (content[i] == '{') {
          braces++;
          started = true;
        } else if (content[i] == '}') {
          braces--;
        }
        
        if (started && braces == 0) {
          endIndex = i;
          break;
        }
      }
      
      if (endIndex != -1) {
        content = content.substring(0, idx) + content.substring(endIndex + 1);
      }
      
      // Look for any other occurrences
      idx = content.indexOf(method);
    }
  }

  await file.writeAsString(content);
  print('Refactored successfully!');
}
