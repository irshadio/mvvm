import 'dart:convert';
import 'dart:io';

/// PostToolUse hook: advisory when an edited hand-written Dart file in lib/ or
/// test/ exceeds 200 lines. PostToolUse cannot block, so this surfaces context
/// telling the agent to split the file; the commit gate enforces it hard.
/// Cross-platform — reads the hook JSON from stdin.
Future<void> main() async {
  final path = _filePathFromStdin(await _readStdin());
  if (path == null) return;

  final normalized = path.replaceAll(r'\', '/');
  final isSource = RegExp(r'/(lib|test)/.*\.dart$').hasMatch(normalized);
  final isGenerated = RegExp(
    r'\.(g|freezed|mocks)\.dart$',
  ).hasMatch(normalized);
  if (!isSource || isGenerated) return;

  final file = File(path);
  if (!file.existsSync()) return;
  final lines = file.readAsLinesSync().length;
  if (lines <= 200) return;

  final context =
      "LOC GUARD: '$normalized' is $lines lines (limit 200). Split it before "
      'committing — extract a widget, helper, or mapper into its own file. '
      'The commit gate will block otherwise.';
  stdout.writeln(
    jsonEncode(<String, Object?>{
      'hookSpecificOutput': <String, Object?>{
        'hookEventName': 'PostToolUse',
        'additionalContext': context,
      },
    }),
  );
}

Future<String> _readStdin() async {
  final bytes = <int>[];
  await stdin.forEach(bytes.addAll);
  return utf8.decode(bytes, allowMalformed: true);
}

String? _filePathFromStdin(String raw) {
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      final input = decoded['tool_input'];
      if (input is Map<String, dynamic>) {
        final path = input['file_path'];
        if (path is String) return path;
      }
    }
  } on FormatException {
    return null;
  }
  return null;
}
