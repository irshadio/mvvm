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
/// Plus two confinement rules that previously relied only on convention:
///   5. `remote_client` (rc.*) is imported only by core/** (it owns the client
///      wiring) or a feature's `data/` layer — never a feature's domain/ or
///      presentation/ (§6/§12).
///   6. the quarantined `$Notifier` identifier appears only in core/state/
///      (§4/§12). Generated *.g.dart that legitimately extends it is excluded.
///
/// app/** and the entrypoint (lib/main.dart) may import anything — they are the
/// composition layer.
void main() {
  final violations = <String>[];
  final files = Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>().where(_isHandwrittenDart);

  for (final file in files) {
    final fromPath = file.path.replaceAll(r'\', '/');
    var notifierFlagged = false;
    for (final line in file.readAsLinesSync()) {
      // --- Identifier confinement: `$Notifier` only in core/state/ (§4) ---
      // The quarantined riverpod_generator base. Generated *.g.dart files
      // (which legitimately extend it) are excluded by _isHandwrittenDart.
      if (!notifierFlagged &&
          line.contains(_notifierToken) &&
          !_isCoreState(fromPath)) {
        notifierFlagged = true;
        violations.add(
          '  $fromPath\n    names $_notifierToken\n'
          '    -> $_notifierToken may appear only in core/state/ (§4)',
        );
      }

      final match = _importPattern.firstMatch(line);
      if (match == null) continue;
      final uri = match.group(1)!;

      // --- Import confinement: remote_client (rc.*) only in a feature's data/
      // (§6/§12). core/** owns the client wiring (network, bootstrap, the
      // failure_mapper) and is exempt; the rule bites inside features. ---
      if (uri.contains(_remoteClientPackage)) {
        final reason = _remoteClientViolation(fromPath);
        if (reason != null) {
          violations.add('  $fromPath\n    imports $uri\n    -> $reason');
        }
      }

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
const String _remoteClientPackage = 'package:remote_client/';
const String _notifierToken = r'$Notifier';
final RegExp _importPattern = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');

/// `$Notifier` is confined to `lib/core/state/` (the §4 quarantine).
bool _isCoreState(String path) => path.startsWith('lib/core/state/');

/// remote_client may be imported by core/** and app/** (infrastructure +
/// composition), and inside a feature ONLY under its `data/` layer. Anywhere
/// else in a feature (domain/ or presentation/) leaks a transport type past the
/// boundary.
String? _remoteClientViolation(String fromPath) {
  if (_zone(fromPath) != _Zone.feature) return null;
  if (fromPath.contains('/data/')) return null;
  return "remote_client (rc.*) may appear only in a feature's data/ layer "
      '(§6)';
}

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
