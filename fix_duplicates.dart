import 'dart:io';

void main() {
  fixFile('lib/screens/spp.dart');
  fixFile('lib/screens/ekskul.dart');
}

void fixFile(String path) {
  final file = File(path);
  String content = file.readAsStringSync();
  
  // Replace the exact duplicated patterns
  content = content.replaceAll(
    'fontWeight: FontWeight.w900,\n                  letterSpacing: -0.8,\n                  color: Colors.grey[800],\n                  letterSpacing: -0.5,',
    'fontWeight: FontWeight.w900,\n                  letterSpacing: -0.8,\n                  color: Colors.grey[800],'
  );
  
  content = content.replaceAll(
    'fontWeight: FontWeight.w900,\n                  letterSpacing: -0.8,\n              color: Colors.white,\n              letterSpacing: -0.5,',
    'fontWeight: FontWeight.w900,\n                  letterSpacing: -0.8,\n              color: Colors.white,'
  );
  
  content = content.replaceAll(
    'fontWeight: FontWeight.w900,\n                  letterSpacing: -0.8,\n                  color: Colors.grey[800],\n                  letterSpacing: -0.5,',
    'fontWeight: FontWeight.w900,\n                  letterSpacing: -0.8,\n                  color: Colors.grey[800],'
  );

  content = content.replaceAll(
    'fontWeight: FontWeight.w900,\n                  letterSpacing: -0.8,\n                color: Colors.grey[800],\n                letterSpacing: -0.5,',
    'fontWeight: FontWeight.w900,\n                  letterSpacing: -0.8,\n                color: Colors.grey[800],'
  );

  // General regex to find duplicate letterSpacing in the same block
  // We can just use a simpler regex that looks for two letterSpacings separated by only color or font properties
  final regex = RegExp(
    r'(letterSpacing:\s*[-.0-9]+,)([^}]+?)(letterSpacing:\s*[-.0-9]+,)',
  );
  
  // Wait, regex is risky. Let's just fix the compiler errors by removing ALL letterSpacings that appear after another letterSpacing within 5 lines
  
  List<String> lines = content.split('\n');
  List<String> newLines = [];
  
  int lastLetterSpacingLine = -10;
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('letterSpacing:')) {
      if (i - lastLetterSpacingLine < 5) {
        // This is a duplicate (close to previous one)
        // Skip it!
        continue;
      } else {
        lastLetterSpacingLine = i;
        newLines.add(lines[i]);
      }
    } else {
      newLines.add(lines[i]);
    }
  }
  
  file.writeAsStringSync(newLines.join('\n'));
  print('Fixed \$path');
}
