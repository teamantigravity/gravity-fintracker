import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No hardcoded colors, date formats, or raw Text strings outside config/theme', () {
    final libDir = Directory('lib');
    final problems = <String>[];

    final allowedPaths = [
      RegExp(r'lib[/\\]config[/\\]'),
      RegExp(r'lib[/\\]theme[/\\]'),
      RegExp(r'\.g\.dart$'),
    ];

    final colorPattern = RegExp(r'''Color\s*\(\s*0x[A-Fa-f0-9]{6,8}''');
    final dateFormatPattern = RegExp(r'''DateFormat\s*\(\s*['"]''');
    final rawTextPattern = RegExp(r'''(?:Text|SnackBar\s*\(\s*content:\s*Text)\s*\(\s*['"][^'"\n]*['"]''');

    for (final file in libDir.listSync(recursive: true).whereType<File>()) {
      final path = file.path;
      if (allowedPaths.any((r) => r.hasMatch(path))) continue;
      if (!path.endsWith('.dart')) continue;

      final content = file.readAsStringSync();
      for (final match in colorPattern.allMatches(content)) {
        problems.add('$path: hardcoded color at ${match.start}');
      }
      for (final match in dateFormatPattern.allMatches(content)) {
        problems.add('$path: hardcoded DateFormat pattern at ${match.start}');
      }
      for (final match in rawTextPattern.allMatches(content)) {
        problems.add('$path: raw Text/SnackBar string at ${match.start}');
      }
    }

    if (problems.isNotEmpty) {
      fail('Hardcoded values found:\n${problems.join('\n')}');
    }
  });
}
