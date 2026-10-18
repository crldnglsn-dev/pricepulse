// Floor guard: diff-scoped enforcement of the CONSTRAINTS.md floor.
//
//   dart run tool/floor_guard.dart [--base <ref>]   (default base: HEAD)
//
// Adapted from the constraint-driven-development reference implementation.
// The diff plumbing, the CONSTRAINTS.md checks and the exit codes are kept
// identical; only the pattern lists are Dart-specific.
//
// Contract:
//   0  clean
//   1  at least one floor violation (block the change)
//   2  the guard could not run (not a git repo, no merge base) — never a "0"
//
// Reports the rule and the location, never a matched value.
import 'dart:convert';
import 'dart:io';

/// A line added or removed by the diff.
class _Change {
  _Change(this.file, this.text, this.added);
  final String file;
  final String text;
  final bool added;
}

/// A numeric threshold found in a CONSTRAINTS.md rule line, with the
/// direction its surrounding words imply.
class _Threshold {
  _Threshold(this.value, this.direction);
  final double value;

  /// "min" for a floor (>=, at least, must not fall), "max" for a ceiling
  /// (<=, at most, must not grow), null when the direction cannot be read.
  final String? direction;
}

/// `dart run tool/x.dart a b` keeps the script args after the script path.
final _args = () {
  final i = Platform.executableArguments.indexWhere(
    (a) => a.endsWith('floor_guard.dart'),
  );
  return i > -1 ? Platform.executableArguments.sublist(i + 1) : <String>[];
}();

// --- Patterns: the only stack-specific part ---------------------------------

/// 1. A silenced checker.
final _suppressions = RegExp(
  r'//\s*ignore:\s*\S'
  r'|//\s*ignore_for_file:'
  r'|/\*\s*ignore\s*\*/'
  r'|istanbul\s+ignore'
  r'|nosemgrep'
  r'|gitleaks:allow'
  r'|coverage:ignore',
  caseSensitive: false,
);

/// 4. Unfinished work.
final _stubs = RegExp(
  r'throw\s+UnimplementedError'
  r'|throw\s+UnsupportedError'
  r'|\bTODO\b'
  r'|\bcatch\s*\([^)]*\)\s*\{\s*\}'
  r'|\bcatch\s*\{\s*\}',
);

/// 2. A test made easier (added skips).
final _skips = RegExp(
  r"""\bskip\s*:\s*(true|['"])"""
  r'|\bSkip\s*\('
  r"""|\btag\s*:\s*['"]skip""",
);

final _isTest = RegExp(r'_test\.dart$|(^|/)test/');
final _isConstraints = RegExp(r'CONSTRAINTS\.md$');
final _isException = RegExp(r'^\|\s*(W|E)\d+\s*\|');

/// Pattern matching applies to source only. A constraints doc, a README or a
/// design note has to *name* the patterns it forbids, so matching prose would
/// flag the document that defines the rule.
final _isSource = RegExp(
  r'\.(dart|ts|tsx|js|jsx|mjs|py|go|rs|java|kt|swift|rb|php|cs|c|cc|cpp|h)$',
  caseSensitive: false,
);

// --- git plumbing ------------------------------------------------------------

String? _git(List<String> args, {bool diffExit = false}) {
  try {
    final r = Process.runSync('git', args, stdoutEncoding: utf8);
    if (r.exitCode == 0) return r.stdout as String;
    // `git diff --no-index` exits 1 when the two sides differ, which is the
    // normal case for a new file. Any other failure is null, and null must
    // never read as clean.
    if (diffExit && r.exitCode == 1) return r.stdout as String;
    return null;
  } on ProcessException {
    return null;
  }
}

Never _bail(String msg) {
  stderr.writeln('floor-guard: $msg');
  exit(2);
}

String _shorten(String text) {
  final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  return t.length > 120 ? '${t.substring(0, 120)}...' : t;
}

// --- Threshold direction -----------------------------------------------------

final _minBefore = RegExp(
  r'(>=|>|≥|at least|minimum|\bmin\b|no less than|not fall|not drop)\s*$',
  caseSensitive: false,
);
final _maxBefore = RegExp(
  r'(<=|<|≤|at most|maximum|\bmax\b|no more than|under|below|not grow|'
  r'not exceed)\s*$',
  caseSensitive: false,
);
final _minAfter = RegExp(
  r'^\s*\S*\s*(or more|or higher|must not fall|must not drop)',
  caseSensitive: false,
);
final _maxAfter = RegExp(
  r'^\s*\S*\s*(or less|or lower|must not grow|must not exceed)',
  caseSensitive: false,
);

/// Splits a rule line into its cells. A table row has one cell per column; a
/// bullet rule is a single cell.
List<String> _cells(String text) {
  final s = text.trim();
  if (!s.startsWith('|')) return [s];
  return s
      .split('|')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();
}

/// The numbers a rule line states, with the direction each one implies.
///
/// A rule states its threshold in the cell that carries the direction — "at
/// least 80%", "must not grow". Numbers in the other cells are supporting
/// detail — "1573 of 1744 lines" — and they necessarily change whenever the
/// rule is restated, because they describe the current state of the thing the
/// rule constrains. Comparing detail as if it were a threshold blocks every
/// legitimate ratchet raise, and a guard that always blocks is a guard that
/// gets switched off.
///
/// When no cell states a direction, every number in the row is treated as a
/// threshold. That is the conservative reading: a rule whose direction cannot
/// be read is blocked, not waved through.
List<_Threshold> _thresholds(String text) {
  final directed = <_Threshold>[];
  final undirected = <_Threshold>[];
  for (final cell in _cells(text)) {
    for (final t in _thresholdsIn(cell)) {
      (t.direction == null ? undirected : directed).add(t);
    }
  }
  return directed.isNotEmpty ? directed : undirected;
}

List<_Threshold> _thresholdsIn(String text) {
  final out = <_Threshold>[];
  for (final m in RegExp(r'\d+(?:\.\d+)?').allMatches(text)) {
    final start = m.start;
    // Clamp: Dart throws on a negative start where JS substr silently clamps.
    // A guard that crashes must never be mistaken for one that passes.
    final beforeStart = start > 24 ? start - 24 : 0;
    final before = text.substring(beforeStart, start).toLowerCase();
    final afterStart = m.end;
    final after = text
        .substring(
          afterStart,
          afterStart + 40 > text.length ? text.length : afterStart + 40,
        )
        .toLowerCase();
    final String? dir;
    if (_minBefore.hasMatch(before) || _minAfter.hasMatch(after)) {
      dir = 'min';
    } else if (_maxBefore.hasMatch(before) || _maxAfter.hasMatch(after)) {
      dir = 'max';
    } else {
      dir = null;
    }
    out.add(_Threshold(double.parse(m.group(0)!), dir));
  }
  return out;
}

/// A rule is a floor bullet or a table row, identified by the bullet's text
/// before its first colon, or the row's first cell. Prose and headings are not
/// rules and return null.
String? _ruleKey(String text) {
  final s = text.trim();
  if (s.startsWith('|')) {
    final cells = s
        .split('|')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    return cells.isEmpty ? null : cells.first;
  }
  if (s.startsWith('- ')) return s.substring(2).split(':').first.trim();
  return null;
}

// --- Diff parsing ------------------------------------------------------------

String _stripAb(String s) {
  var v = s.trim();
  if (v.startsWith('a/') || v.startsWith('b/')) v = v.substring(2);
  // Windows git writes NUL where POSIX git writes /dev/null.
  if (v == 'NUL' || v == '/dev/null') return '/dev/null';
  return v.replaceAll('\\', '/');
}

/// Walks a unified diff. `---`/`+++` are file headers only between a file's
/// `diff` line and its first `@@`; inside a hunk every line is content, so an
/// added `++i` or a removed `-- comment` is a change, not a header.
({List<_Change> changes, List<String> deleted}) _parseDiff(String diff) {
  final changes = <_Change>[];
  final deleted = <String>{};
  var file = '';
  var oldFile = '';
  var inHeader = false;

  for (final line in diff.split('\n')) {
    if (line.startsWith('diff ')) {
      inHeader = true;
    } else if (line.startsWith('@@')) {
      inHeader = false;
    } else if (inHeader) {
      if (line.startsWith('--- ')) {
        oldFile = _stripAb(line.substring(4));
      } else if (line.startsWith('+++ ')) {
        final newFile = _stripAb(line.substring(4));
        // A deletion names the old file in `+++ /dev/null`.
        file = newFile == '/dev/null' ? oldFile : newFile;
        if (newFile == '/dev/null') deleted.add(file);
      }
    } else if (line.startsWith('+')) {
      changes.add(_Change(file, line.substring(1), true));
    } else if (line.startsWith('-')) {
      changes.add(_Change(file, line.substring(1), false));
    }
  }
  return (changes: changes, deleted: deleted.toList());
}

// --- Main --------------------------------------------------------------------

void main(List<String> argv) {
  // A gate that throws must exit non-zero. Wrapping the whole run means an
  // unexpected error is reported as "could not run" (2), never as clean (0).
  try {
    _run(argv);
  } on Object catch (error, stack) {
    stderr.writeln('floor-guard: crashed — $error');
    stderr.writeln(stack);
    stderr.writeln('This is NOT a pass. The guard could not complete.');
    exit(2);
  }
}

void _run(List<String> argv) {
  final i = argv.indexOf('--base');
  final base = i > -1 && i + 1 < argv.length ? argv[i + 1] : _baseFrom(_args);

  final top = _git(['rev-parse', '--show-toplevel'])?.trim();
  if (top == null || top.isEmpty) _bail('not inside a git work tree');
  Directory.current = top;

  // HEAD is a valid merge base for an uncommitted working tree. Against a
  // branch base we need the real merge point.
  final mergeBase = base == 'HEAD'
      ? _git(['rev-parse', 'HEAD'])?.trim()
      : _git(['merge-base', base, 'HEAD'])?.trim();
  if (mergeBase == null || mergeBase.isEmpty) {
    _bail('no merge base against $base');
  }

  final tracked = _git(['diff', '--unified=0', mergeBase, '--']);
  if (tracked == null) _bail('could not diff against $mergeBase');

  final untrackedList = _git(['ls-files', '--others', '--exclude-standard']);
  if (untrackedList == null) _bail('could not list untracked files');

  final untracked = StringBuffer();
  for (final f in untrackedList.split('\n').where((s) => s.isNotEmpty)) {
    // `git diff` alone cannot see new files, so synthesise their diff.
    final d = _git([
      'diff',
      '--no-index',
      '--unified=0',
      'NUL',
      f,
    ], diffExit: true);
    if (d == null) _bail('could not diff untracked file $f');
    untracked.write(d);
  }

  final parsed = _parseDiff('$tracked\n$untracked');
  final changes = parsed.changes;
  final deleted = parsed.deleted;

  final findings = <String>[];
  void add(String rule, String file, String text) =>
      findings.add('  [$rule] $file: ${_shorten(text)}');

  for (final c in changes.where((c) => c.added)) {
    // The guard necessarily contains the very patterns it looks for, so its own
    // edits are exempt. A detector that flags itself cannot be maintained.
    final isSelf = c.file.endsWith('floor_guard.dart');
    final isSource = _isSource.hasMatch(c.file);
    if (isSource && !isSelf) {
      if (_suppressions.hasMatch(c.text)) {
        add('silenced-checker', c.file, c.text);
      }
      if (_stubs.hasMatch(c.text)) add('unfinished-work', c.file, c.text);
      if (_skips.hasMatch(c.text)) add('test-made-easier', c.file, c.text);
    }
    if (_isConstraints.hasMatch(c.file) &&
        _isException.hasMatch(c.text.trim())) {
      add('new-exception', c.file, c.text);
    }
  }

  // A test file deleted, or an assertion removed from a test file that stayed.
  for (final f in deleted) {
    if (_isTest.hasMatch(f)) add('test-deleted', f, 'file deleted');
  }
  for (final c in changes.where((c) => !c.added)) {
    if (_isTest.hasMatch(c.file)) continue;
    if (deleted.contains(c.file)) continue;
    if (RegExp(r'\b(expect|assert|fail)\s*\(').hasMatch(c.text)) {
      add('assertion-removed', c.file, c.text);
    }
  }

  final removedRules = changes
      .where((c) => !c.added && _isConstraints.hasMatch(c.file))
      .where((c) => _ruleKey(c.text) != null)
      .toList();
  final addedRules = changes
      .where((c) => c.added && _isConstraints.hasMatch(c.file))
      .where((c) => _ruleKey(c.text) != null)
      .toList();

  for (final r in removedRules) {
    final match = addedRules
        .where((x) => _ruleKey(x.text) == _ruleKey(r.text))
        .cast<_Change?>()
        .firstWhere((_) => true, orElse: () => null);

    if (match == null) {
      // Dropping an exception tightens the bar, so it stays silent.
      if (!_isException.hasMatch(r.text.trim())) {
        add('rule-removed', r.file, r.text);
      }
      continue;
    }

    final before = _thresholds(r.text);
    final after = _thresholds(match.text);
    String? verdict;

    for (final dir in ['min', 'max', null]) {
      if (verdict != null) break;
      final was = before.where((t) => t.direction == dir).toList();
      final now = after.where((t) => t.direction == dir).toList();
      for (var n = 0; n < was.length; n++) {
        final _Threshold? next = n < now.length ? now[n] : null;
        if (next == null) {
          verdict = 'threshold-removed';
        } else if (next.value == was[n].value) {
          continue;
        } else {
          final loosened = dir == 'min'
              ? next.value < was[n].value
              : (dir == 'max' ? next.value > was[n].value : true);
          if (loosened) {
            verdict = dir == null ? 'threshold-changed' : 'threshold-loosened';
          }
        }
        if (verdict != null) break;
      }
    }

    if (verdict != null) {
      add(verdict, r.file, '${r.text.trim()}  ->  ${match.text.trim()}');
    }
  }

  if (findings.isEmpty) {
    stdout.writeln('floor-guard: clean');
    exit(0);
  }
  stderr.writeln('floor-guard: ${findings.length} floor violation(s):');
  for (final f in findings) {
    stderr.writeln(f);
  }
  stderr.writeln(
    '\nEach is a move that lowers the bar. Fix the code, or route it through a '
    'tracked exception in CONSTRAINTS.md.',
  );
  exit(1);
}

String _baseFrom(List<String> args) {
  final i = args.indexOf('--base');
  return i > -1 && i + 1 < args.length ? args[i + 1] : 'HEAD';
}
