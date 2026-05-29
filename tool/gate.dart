import 'dart:io';

/// The project quality gate. Cross-platform (Windows / macOS / Linux).
///
/// Exits 0 when every step passes, 1 on the first failure. Used by the
/// `/mvvm-gate` skill, the `mvvm-verifier` agent, and the PreToolUse commit
/// hook. Run: `dart run tool/gate.dart`.
Future<void> main() async {
  // Each entry is [display-name, executable, ...args].
  const steps = <List<String>>[
    ['build_runner', 'dart', 'run', 'build_runner', 'build'],
    ['analyze', 'flutter', 'analyze'],
    ['boundaries', 'dart', 'run', 'tool/check_boundaries.dart'],
    ['loc', 'dart', 'run', 'tool/check_loc.dart'],
    ['test', 'flutter', 'test'],
  ];

  for (final step in steps) {
    final name = step.first;
    final exe = step[1];
    final args = step.sublist(2);
    stdout.writeln('== $name ==');
    // runInShell resolves flutter/dart launchers (.bat on Windows) on all OSes.
    final result = await Process.run(exe, args, runInShell: true);
    stdout.write((result.stdout as String?) ?? '');
    stderr.write((result.stderr as String?) ?? '');
    if (result.exitCode != 0) {
      stdout.writeln('FAILED: $name (exit ${result.exitCode})');
      exit(1);
    }
  }

  stdout.writeln('GATE PASSED');
}
