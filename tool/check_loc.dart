import 'dart:io';

/// Fails if any hand-written Dart file in lib/ or test/ exceeds the line limit.
/// Run: dart run tool/check_loc.dart
///
/// Generated files (*.g.dart / *.freezed.dart / *.mocks.dart) are exempt.
const int _maxLines = 200;

void main() {
  final offenders = <String>[];

  for (final root in <String>['lib', 'test']) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('.g.dart') ||
          path.endsWith('.freezed.dart') ||
          path.endsWith('.mocks.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync().length;
      if (lines > _maxLines) offenders.add('  $path — $lines lines');
    }
  }

  if (offenders.isEmpty) {
    stdout.writeln('OK: every file is within $_maxLines lines.');
    return;
  }
  stderr
    ..writeln('LOC violations (limit $_maxLines) — split these:\n')
    ..writeln(offenders.join('\n'));
  exitCode = 1;
}
