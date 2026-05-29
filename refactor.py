import sys
import re

def process_home_dart():
    try:
        with open(r'd:\MOLAH\lib\home.dart', 'r', encoding='utf-8') as f:
            content = f.read()

        # Add imports at the beginning (after the first block of imports)
        import_str = "import 'package:flutter/material.dart';\nimport 'widgets/home_shimmer.dart';\nimport 'widgets/notification_tab.dart';\n"
        content = re.sub(r"import 'package:flutter/material\.dart';", import_str, content)

        # 1. Remove _shimmerController and _shimmerAnimation declarations
        content = re.sub(r"\s*late AnimationController _shimmerController;", "", content)
        content = re.sub(r"\s*late Animation<double> _shimmerAnimation;", "", content)

        # 2. Remove from dispose
        content = re.sub(r"\s*_shimmerController\.stop\(\);", "", content)
        content = re.sub(r"\s*_shimmerController\.dispose\(\);", "", content)

        # 3. Remove initialization
        content = re.sub(r"\s*_shimmerController = AnimationController\([\s\S]*?vsync: this,\s*\);", "", content)
        content = re.sub(r"\s*_shimmerAnimation = Tween<double>\(begin: -1\.0, end: 1\.0\)\.animate\([\s\S]*?curve: Curves\.easeInOut\),\s*\);", "", content)

        # 4. Remove shimmer usages (if blocks)
        content = re.sub(r"\s*if \(!_shimmerController\.isAnimating\) {\s*_shimmerController\.repeat\(\);\s*}", "", content)
        content = re.sub(r"\s*if \(_shimmerController\.isAnimating\) {\s*_shimmerController\.stop\(\);\s*}", "", content)
        content = re.sub(r"\s*if \(_santriData\.isEmpty && _isLoading\) {\s*_shimmerController\.repeat\(\);\s*}", "", content)
        content = re.sub(r"\s*if \(_isLoading\) {\s*_shimmerController\.repeat\(\);\s*}", "", content)

        # 5. Replace _buildLoadingState
        content = content.replace("_buildLoadingState(screenSize)", "HomeShimmerLoading(screenSize: screenSize)")
        
        # 6. Replace _buildEnhancedNotificationPage
        content = content.replace("_buildEnhancedNotificationPage(screenSize)", "NotificationTab(screenSize: screenSize, username: widget.username, onRefresh: _handleRefresh)")

        # 7. Remove the large methods at the end.
        # We know they start from `Widget _buildEnhancedNotificationPage(Size screenSize)` to the end.
        # So we can find the index of `Widget _buildEnhancedNotificationPage(Size screenSize)`
        idx1 = content.find("Widget _buildEnhancedNotificationPage(Size screenSize) {")
        if idx1 != -1:
            # We want to remove from idx1 up to the `// --- TAMBAHAN BARU: Method untuk pemberitahuan ---`
            # Wait, no, we need to keep `initConnectivity`, `_updateConnectionStatus`, `_showNoInternetNotification`, `_showSlowConnectionNotification`.
            # Let's find `// --- TAMBAHAN BARU: Method untuk pemberitahuan ---`
            idx2 = content.find("// --- TAMBAHAN BARU: Method untuk pemberitahuan ---")
            
            if idx2 != -1:
                content = content[:idx1] + content[idx2:]
            else:
                print("Could not find connectivity block")
        else:
            print("Could not find _buildEnhancedNotificationPage")

        # Now remove _buildLoadingState and all shimmer methods.
        # They might be before _buildEnhancedNotificationPage or after.
        # Let's just use regex to remove each method.
        # We need to be careful with curly braces. A simple approach is to find the method signature and remove up to the next method signature.
        methods_to_remove = [
            "Widget _buildLoadingState(Size screenSize) {",
            "Widget _buildShimmerContainer({",
            "Widget _buildHeaderShimmer(Size screenSize) {",
            "Widget _buildQuickActionsShimmer(Size screenSize) {",
            "Widget _buildReportShimmer(Size screenSize) {",
            "Widget _buildStudentInfoShimmer(Size screenSize) {"
        ]
        
        for method in methods_to_remove:
            idx = content.find(method)
            if idx != -1:
                # Find the end of the method by counting braces
                braces = 0
                started = False
                for i in range(idx, len(content)):
                    if content[i] == '{':
                        braces += 1
                        started = True
                    elif content[i] == '}':
                        braces -= 1
                    
                    if started and braces == 0:
                        content = content[:idx] + content[i+1:]
                        break

        with open(r'd:\MOLAH\lib\home.dart', 'w', encoding='utf-8') as f:
            f.write(content)
            
        print("Successfully processed home.dart")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    process_home_dart()
