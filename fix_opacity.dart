import 'dart:io';

void main() {
  final dir = Directory('lib');
  int totalReplaced = 0;
  
  if (!dir.existsSync()) {
    print('Directory lib not found');
    return;
  }
  
  final regex = RegExp(r'\.withOpacity\(([^)]+)\)');
  
  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      var newContent = content.replaceAllMapped(
        regex, 
        (match) => '.withValues(alpha: ${match.group(1)})'
      );
      
      // Handle edge cases where withOpacity might have nested parens
      // By using string replacement for common ones if needed, but regex usually catches most
      
      if (content != newContent) {
        entity.writeAsStringSync(newContent);
        totalReplaced++;
        print('Updated: ${entity.path}');
      }
    }
  }
  print('Replaced in $totalReplaced files.');
}
