import 'dart:io';

void main() async {
  final directory = Directory('lib');
  int replacedCount = 0;

  await for (var entity in directory.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = await entity.readAsString();
      
      if (content.contains(RegExp(r'\bprint\s*\('))) {
        // Tambahkan import jika belum ada
        if (!content.contains("import 'package:flutter/foundation.dart';") &&
            !content.contains("import 'package:flutter/material.dart';")) {
          content = "import 'package:flutter/foundation.dart';\n" + content;
        }

        // Replace print( dengan debugPrint(
        String newContent = content.replaceAll(RegExp(r'\bprint\s*\('), 'debugPrint(');
        
        await entity.writeAsString(newContent);
        replacedCount++;
        print('Replaced print in \${entity.path}');
      }
    }
  }

  print('Done. Modified \$replacedCount files.');
}
