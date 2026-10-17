# Runs the PricePulse quality gates in the right order, cheapest first.
# Mirrors the "How to run everything" section of CONSTRAINTS.md — that file is
# the source of truth; this is a convenience wrapper.
#
#   ./tool/check.ps1           # fast + task-end gates
#   ./tool/check.ps1 -Full     # adds the network pre-demo gate
param([switch]$Full)

$ErrorActionPreference = 'Continue'
$failed = @()

function Step($name, [scriptblock]$body) {
  Write-Host ""
  Write-Host "=== $name ===" -ForegroundColor Cyan
  & $body
  if ($LASTEXITCODE -ne 0) {
    $script:failed += "$name (exit $LASTEXITCODE)"
    Write-Host "  FAILED" -ForegroundColor Red
  }
}

# --- fast: every edit, under 5s --------------------------------------------
Step 'analyze (types + lint)' { flutter analyze }

Step 'floor guard' { dart run tool/floor_guard.dart }

# --- task end ---------------------------------------------------------------
Step 'tests' { flutter test }

Step 'coverage' {
  flutter test --coverage
  dart run tool/coverage_check.dart --min 80 --changed 80
}

# --- pre-demo only: hits the network ---------------------------------------
if ($Full) {
  Step 'verify seed links' { dart run tool/verify_links.dart }
}

Write-Host ""
if ($failed.Count -eq 0) {
  Write-Host "All gates passed." -ForegroundColor Green
  exit 0
}
Write-Host "Failed gates:" -ForegroundColor Red
$failed | ForEach-Object { Write-Host "  - $_" }
Write-Host ""
Write-Host "Fix the code, or route it through a tracked exception in CONSTRAINTS.md."
exit 1
