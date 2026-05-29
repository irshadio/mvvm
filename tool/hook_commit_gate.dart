import 'dart:convert';
import 'dart:io';

/// PreToolUse hook: blocks `git commit` until the quality gate passes.
/// Cross-platform — reads the hook JSON from stdin, runs `tool/gate.dart`, and
/// denies the commit if the gate fails. No-ops fast for non-commit commands.
Future<void> main() async {
  final command = _commandFromStdin(await _readStdin());
  if (!RegExp(r'git\s+commit').hasMatch(command)) return; // not a commit

  final gate = await Process.run(
    'dart',
    ['run', 'tool/gate.dart'],
    runInShell: true,
  );
  if (gate.exitCode == 0) return; // gate passed → allow the commit

  final out = (gate.stdout as String?) ?? '';
  final err = (gate.stderr as String?) ?? '';
  final reason =
      'COMMIT BLOCKED — quality gate failed. Fix these and re-commit:\n\n'
      '$out\n$err';
  stdout.writeln(
    jsonEncode(<String, Object?>{
      'hookSpecificOutput': <String, Object?>{
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'deny',
        'permissionDecisionReason': reason,
      },
    }),
  );
  exit(2);
}

Future<String> _readStdin() async {
  final bytes = <int>[];
  await stdin.forEach(bytes.addAll);
  return utf8.decode(bytes, allowMalformed: true);
}

String _commandFromStdin(String raw) {
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      final input = decoded['tool_input'];
      if (input is Map<String, dynamic>) {
        final command = input['command'];
        if (command is String) return command;
      }
    }
  } on FormatException {
    return '';
  }
  return '';
}
