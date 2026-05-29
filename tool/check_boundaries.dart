import 'dart:io';

/// Enforces the architecture's import boundaries. Run before every commit:
///
///     dart run tool/check_boundaries.dart
///
/// Rules (a `package:mvvm/...` import is illegal when):
///   1. core imports features or app (core stays generic).
///   2. one feature imports a different feature.
///   3. any feature imports app.
///   4. within a feature, domain imports data or presentation, or data
///      imports presentation (inner layers stay pure).
///
/// app/** and the entrypoint (lib/main.dart) may import anything — they are the
/// composition layer.
void main() {
  final violations = <String>[];
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where(_isHandwrittenDart);

  for (final file in files) {
    final fromPath = file.path.replaceAll(r'\', '/');
    for (final line in file.readAsLinesSync()) {
      final match = _importPattern.firstMatch(line);
      if (match == null) continue;
      final uri = match.group(1)!;
      if (!uri.startsWith(_packagePrefix)) continue;
      final toPath = 'lib/${uri.substring(_packagePrefix.length)}';
      final reason = _violation(fromPath, toPath);
      if (reason != null) {
        violations.add('  $fromPath\n    imports $uri\n    -> $reason');
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('OK: no import-boundary violations.');
    return;
  }
  stderr
    ..writeln('Import-boundary violations (${violations.length}):\n')
    ..writeln(violations.join('\n\n'));
  exitCode = 1;
}

const String _packagePrefix = 'package:mvvm/';
final RegExp _importPattern = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');

bool _isHandwrittenDart(File file) {
  final path = file.path;
  return path.endsWith('.dart') &&
      !path.endsWith('.g.dart') &&
      !path.endsWith('.freezed.dart');
}

String? _violation(String fromPath, String toPath) {
  final fromZone = _zone(fromPath);
  final toZone = _zone(toPath);

  if (fromZone == _Zone.core && toZone != _Zone.core) {
    return 'core may not import ${toZone.name}';
  }
  if (fromZone == _Zone.feature && toZone == _Zone.app) {
    return 'features may not import app';
  }
  if (fromZone == _Zone.feature && toZone == _Zone.feature) {
    final fromFeature = _feature(fromPath);
    final toFeature = _feature(toPath);
    if (fromFeature != toFeature) {
      return 'feature "$fromFeature" may not import feature "$toFeature"';
    }
    final fromLayer = _subLayer(fromPath);
    final toLayer = _subLayer(toPath);
    if (fromLayer == _Layer.domain && toLayer != _Layer.domain) {
      return 'domain may not import ${toLayer.name}';
    }
    if (fromLayer == _Layer.data && toLayer == _Layer.presentation) {
      return 'data may not import presentation';
    }
  }
  return null;
}

enum _Zone { core, app, feature, other }

enum _Layer { domain, data, presentation, other }

_Zone _zone(String path) {
  if (path.startsWith('lib/core/')) return _Zone.core;
  if (path.startsWith('lib/app/')) return _Zone.app;
  if (path.startsWith('lib/features/')) return _Zone.feature;
  return _Zone.other;
}

String _feature(String path) {
  final parts = path.split('/');
  final index = parts.indexOf('features');
  return (index >= 0 && index + 1 < parts.length) ? parts[index + 1] : '';
}

_Layer _subLayer(String path) {
  if (path.contains('/domain/')) return _Layer.domain;
  if (path.contains('/data/')) return _Layer.data;
  if (path.contains('/presentation/')) return _Layer.presentation;
  return _Layer.other;
}
