param(
  [int]$HeapMiB = 12288,
  [int]$StackKiB = 65500,
  [string]$Log = "full-std.log",
  [switch]$SkipTests,
  [switch]$SkipCorpora,
  [switch]$SkipPreflight
)

$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))

function Require-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' was not found on PATH."
  }
}

Require-Command node
Require-Command npm
Require-Command lean

$nodeVersion = (& node --version).Trim()
$leanCommand = Get-Command lean -ErrorAction Stop
$leanVersion = (& lean --version | Select-Object -First 1).Trim()
$leanGitHash = (& lean --githash).Trim()
$env:LEAN434_BIN = Split-Path -Parent $leanCommand.Source
$oracleLock = Get-Content "ORACLE_LOCK.json" -Raw | ConvertFrom-Json
if ($leanVersion -notmatch "version 4\.34\.0.*Release") {
  throw "Expected Lean 4.34.0 Release, got: $leanVersion"
}
if ($leanGitHash -ne $oracleLock.leanCommit) {
  throw "Expected Lean commit $($oracleLock.leanCommit), got: $leanGitHash"
}

$env:PSKERNEL_STD_HEAP_MIB = "$HeapMiB"
$env:PSKERNEL_STD_STACK_KIB = "$StackKiB"

"pskernel canonical Full Std" | Set-Content $Log
"started=$(Get-Date -Format o)" | Add-Content $Log
"node=$nodeVersion" | Add-Content $Log
"lean=$leanVersion" | Add-Content $Log
"leanGitHash=$leanGitHash" | Add-Content $Log
"leanBin=$env:LEAN434_BIN" | Add-Content $Log
"heapMiB=$HeapMiB stackKiB=$StackKiB" | Add-Content $Log

Write-Host "Installing dependencies..."
& npm install --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $SkipTests) {
  Write-Host "Running full npm test gate..."
  "testsStarted=$(Get-Date -Format o)" | Add-Content $Log
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & npm test 2>&1 |
      ForEach-Object { $_.ToString() } |
      Tee-Object -FilePath $Log -Append
    $testCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  "testsFinished=$(Get-Date -Format o)" | Add-Content $Log
  "testsExitCode=$testCode" | Add-Content $Log
  if ($testCode -ne 0) {
    Write-Host "npm test failed. Full Std was not started; send/upload $Log."
    exit $testCode
  }
  Write-Host "npm test PASS."
} else {
  Write-Host "Skipping npm test; building pskernel..."
  & npm run build
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not $SkipCorpora) {
  Write-Host "Running bounded real-corpus gate..."
  "corporaStarted=$(Get-Date -Format o)" | Add-Content $Log
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & npm run check:corpus 2>&1 |
      ForEach-Object { $_.ToString() } |
      Tee-Object -FilePath $Log -Append
    $corporaCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  "corporaFinished=$(Get-Date -Format o)" | Add-Content $Log
  "corporaExitCode=$corporaCode" | Add-Content $Log
  if ($corporaCode -ne 0) {
    Write-Host "Bounded real-corpus gate failed. Full Std was not started; send/upload $Log."
    exit $corporaCode
  }
  Write-Host "Bounded real-corpus gate PASS."
}

if (-not $SkipPreflight) {
  Write-Host "Running canonical Init.Prelude module-stream preflight..."
  "preflightStarted=$(Get-Date -Format o)" | Add-Content $Log

  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & node scripts/module-stream-oracle.mjs Init.Prelude 2>&1 |
      ForEach-Object { $_.ToString() } |
      Tee-Object -FilePath $Log -Append
    $preflightCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  "preflightFinished=$(Get-Date -Format o)" | Add-Content $Log
  "preflightExitCode=$preflightCode" | Add-Content $Log
  if ($preflightCode -ne 0) {
    Write-Host "Canonical Init.Prelude preflight failed. Full Std was not started; send/upload $Log."
    exit $preflightCode
  }
  Write-Host "Canonical Init.Prelude preflight PASS."
}

Write-Host "Running canonical Full Std replay. Progress is also written to $Log"

# Windows PowerShell 5.1 turns native-process stderr into ErrorRecord objects.
# npm writes normal notices/progress to stderr, so with ErrorActionPreference=Stop
# a successful native command can be aborted before its exit code is observed.
# Keep strict PowerShell error handling everywhere else, but treat native stdout/
# stderr as ordinary log data for this one command.
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  & npm run oracle:std-full 2>&1 |
    ForEach-Object { $_.ToString() } |
    Tee-Object -FilePath $Log -Append
  $code = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}

"finished=$(Get-Date -Format o)" | Add-Content $Log
"exitCode=$code" | Add-Content $Log

if ($code -eq 0) {
  Write-Host "Full Std PASS. Please send/upload $Log."
} else {
  Write-Host "Full Std did not complete successfully. Please send/upload $Log; the last module/error is enough to continue debugging."
}
exit $code
