// Coverage check for CONSTRAINTS.md.
//
//   dart run tool/coverage_check.dart [--min <pct>]
//
// Reads the lcov that `flutter test --coverage` already wrote — it never runs
// the suite a second time — and reports line coverage for `lib/`.
//
//   --min <pct>    fail if total line coverage is below this
//   --changed <pct>  also fail if any file touched since --base is below this
//   --base <ref>   what counts as "changed" (default: HEAD)
//
// The ratchet number (total coverage must not fall) lives in CONSTRAINTS.md.
import 'dart:io';

const _lcovPath = 'coverage/lcov.info';

class _FileCoverage {
  _FileCoverage(this.path);
  final String path;
  int found = 0;
  int hit = 0;

  double get pct => found == 0 ? 100 : hit / found * 100;
}

void main(List<String> args) {
  final minIdx = args.indexOf('--min');
  final min = minIdx > -1 && minIdx + 1 < args.length
      ? double.parse(args[minIdx + 1])
      : null;

  final chIdx = args.indexOf('--changed');
  final changedMin = chIdx > -1 && chIdx + 1 < args.length
      ? double.parse(args[chIdx + 1])
      : null;

  final baseIdx = args.indexOf('--base');
  final base = baseIdx > -1 && baseIdx + 1 < args.length
      ? args[baseIdx + 1]
      : 'HEAD';

  final file = File(_lcovPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'coverage-check: $_lcovPath not found.\n'
      '  Run: flutter test --coverage',
    );
    exit(2);
  }

  final byPath = <String, _FileCoverage>{};
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      final p = _normalise(line.substring(3));
      byPath.putIfAbsent(p, () => _FileCoverage(p));
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length < 2) continue;
      final f = byPath.values.last;
      f.found++;
      if (int.tryParse(parts[1].trim()) != 0) f.hit++;
    }
  }

  // Only application code; generated and test-only paths are not the bar.
  final lib =
      byPath.values
          .where(
            (f) => f.path.startsWith('lib/') && !f.path.contains('/generated/'),
          )
          .toList()
        ..sort((a, b) => a.pct.compareTo(b.pct));

  final totalFound = lib.fold<int>(0, (s, f) => s + f.found);
  final totalHit = lib.fold<int>(0, (s, f) => s + f.hit);
  final total = totalFound == 0 ? 100.0 : totalHit / totalFound * 100;

  for (final f in lib) {
    stdout.writeln(
      '  ${f.pct.toStringAsFixed(1).padLeft(6)}%  '
      '${f.hit.toString().padLeft(4)}/${f.found.toString().padLeft(4)}  '
      '${f.path}',
    );
  }
  stdout.writeln(
    '\nTotal line coverage (lib/): ${total.toStringAsFixed(1)}%  '
    '($totalHit/$totalFound)',
  );

  if (min != null && total < min) {
    stderr.writeln(
      '\ncoverage-check: FAIL — ${total.toStringAsFixed(1)}% is below the '
      '${min.toStringAsFixed(0)}% floor.',
    );
    exit(1);
  }

  // Coverage of changed lines is the number this project can actually move,
  // so it is what the per-file floor applies to.
  if (changedMin != null) {
    final touched = _changedLibFiles(base);
    if (touched == null) {
      stderr.writeln(
        '\ncoverage-check: could not diff against $base — run from a git repo '
        'with a merge base. Not treating this as a pass.',
      );
      exit(2);
    }
    if (touched.isEmpty) {
      stdout.writeln('coverage-check: no changed lib/ files since $base');
    } else {
      stdout.writeln('\nChanged lib/ files since $base:');
      final below = <_FileCoverage>[];
      for (final path in touched) {
        final f = byPath[path];
        if (f == null) {
          stdout.writeln('  (no coverage record)  $path');
          continue;
        }
        stdout.writeln('  ${f.pct.toStringAsFixed(1).padLeft(6)}%  $path');
        if (f.found > 0 && f.pct < changedMin) below.add(f);
      }
      if (below.isNotEmpty) {
        stderr.writeln(
          '\ncoverage-check: FAIL — ${below.length} changed file(s) below '
          '${changedMin.toStringAsFixed(0)}%:\n'
          '${below.map((f) => '  ${f.pct.toStringAsFixed(1)}%  ${f.path}').join('\n')}',
        );
        exit(1);
      }
    }
  }

  stdout.writeln('coverage-check: OK');
}

/// Paths of `lib/` files touched since [base], including untracked ones.
Set<String>? _changedLibFiles(String base) {
  Set<String>? collect(String out) {
    final set = <String>{};
    for (final line in out.split('\n')) {
      final p = line.trim().replaceAll('\\', '/');
      if (p.startsWith('lib/') && p.endsWith('.dart')) set.add(p);
    }
    return set;
  }

  final tracked = _git(['diff', '--name-only', base, '--']);
  if (tracked == null) return null;
  final result = collect(tracked) ?? <String>{};

  final untracked = _git([
    'ls-files',
    '--others',
    '--exclude-standard',
    '--',
    'lib/',
  ]);
  if (untracked == null) return null;
  result.addAll(collect(untracked) ?? const <String>{});
  return result;
}

String? _git(List<String> args) {
  try {
    final r = Process.runSync('git', args);
    return r.exitCode == 0 ? r.stdout as String : null;
  } on ProcessException {
    return null;
  }
}

String _normalise(String raw) {
  var p = raw.trim().replaceAll('\\', '/');
  // lcov paths can be absolute or repo-relative depending on the runner.
  final idx = p.indexOf('/lib/');
  if (idx > -1) p = p.substring(idx + 1);
  return p;
}
