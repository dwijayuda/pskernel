param(
  [int]$HeapMiB = 12288,
  [int]$StackKiB = 65500,
  [string]$Log = "full-std.local.log",
  [switch]$SkipTests,
  [switch]$SkipCorpora,
  [switch]$SkipNativeSmoke,
  [switch]$SkipPreflight
)

$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))

$LogPath = [System.IO.Path]::GetFullPath($Log)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Log([string]$Text) {
  [System.IO.File]::AppendAllText(
    $script:LogPath,
    $Text + [Environment]::NewLine,
    $script:Utf8NoBom
  )
}

function Write-NativeLogLine($Value) {
  $line = $Value.ToString()
  Write-Host $line
  Write-Log $line
}

function Require-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' was not found on PATH."
  }
}

Require-Command git
Require-Command node
Require-Command npm
Require-Command lean

$gitCommit = (& git rev-parse HEAD).Trim()
$gitBranch = (& git rev-parse --abbrev-ref HEAD).Trim()
$trackedChanges = @(& git status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0) {
  throw "Unable to inspect git working tree."
}
if ($trackedChanges.Count -ne 0) {
  $dirtySummary = ($trackedChanges -join "; ")
  throw "Tracked working-tree changes are present. Commit/stash them before producing assurance evidence. git status: $dirtySummary"
}

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

[System.IO.File]::WriteAllText(
  $LogPath,
  "pskernel canonical Full Std" + [Environment]::NewLine,
  $Utf8NoBom
)
Write-Log "started=$(Get-Date -Format o)"
Write-Log "gitCommit=$gitCommit"
Write-Log "gitBranch=$gitBranch"
Write-Log "gitTrackedTree=clean"
Write-Log "node=$nodeVersion"
Write-Log "lean=$leanVersion"
Write-Log "leanGitHash=$leanGitHash"
Write-Log "leanBin=$env:LEAN434_BIN"
Write-Log "heapMiB=$HeapMiB stackKiB=$StackKiB"

Write-Host "Installing locked dependencies with npm ci..."
Write-Log "dependencyInstall=npm ci"
Write-Log "dependencyInstallStarted=$(Get-Date -Format o)"
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  & npm ci --no-audit --no-fund 2>&1 | ForEach-Object { Write-NativeLogLine $_ }
  $dependencyInstallCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}
Write-Log "dependencyInstallFinished=$(Get-Date -Format o)"
Write-Log "dependencyInstallExitCode=$dependencyInstallCode"
if ($dependencyInstallCode -ne 0) {
  Write-Host "npm ci failed before any kernel replay. This is a packaging/dependency gate failure; send/upload $Log."
  exit $dependencyInstallCode
}

$postInstallTrackedChanges = @(& git status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0) {
  throw "Unable to inspect git working tree after npm ci."
}
if ($postInstallTrackedChanges.Count -ne 0) {
  $dirtySummary = ($postInstallTrackedChanges -join "; ")
  throw "npm ci changed tracked files; refusing assurance evidence. git status: $dirtySummary"
}

if (-not $SkipTests) {
  Write-Host "Running full npm test gate..."
  Write-Log "testsStarted=$(Get-Date -Format o)"
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & npm test 2>&1 | ForEach-Object { Write-NativeLogLine $_ }
    $testCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  Write-Log "testsFinished=$(Get-Date -Format o)"
  Write-Log "testsExitCode=$testCode"
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
  Write-Log "corporaStarted=$(Get-Date -Format o)"
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & npm run check:corpus 2>&1 | ForEach-Object { Write-NativeLogLine $_ }
    $corporaCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  Write-Log "corporaFinished=$(Get-Date -Format o)"
  Write-Log "corporaExitCode=$corporaCode"
  if ($corporaCode -ne 0) {
    Write-Host "Bounded real-corpus gate failed. Full Std was not started; send/upload $Log."
    exit $corporaCode
  }
  Write-Host "Bounded real-corpus gate PASS."
}

if (-not $SkipNativeSmoke) {
  Write-Host "Running Lean compiler-IR native reduction smoke..."
  Write-Log "nativeSmokeStarted=$(Get-Date -Format o)"
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & npm run oracle:native-smoke 2>&1 | ForEach-Object { Write-NativeLogLine $_ }
    $nativeSmokeCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  Write-Log "nativeSmokeFinished=$(Get-Date -Format o)"
  Write-Log "nativeSmokeExitCode=$nativeSmokeCode"
  if ($nativeSmokeCode -ne 0) {
    Write-Host "Native compiler-IR smoke failed. Canonical replay was not started; send/upload $Log."
    exit $nativeSmokeCode
  }
  Write-Host "Native compiler-IR smoke PASS."
}

if (-not $SkipPreflight) {
  Write-Host "Running canonical Init.Prelude module-stream preflight..."
  Write-Log "preflightStarted=$(Get-Date -Format o)"

  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & node scripts/module-stream-oracle.mjs Init.Prelude 2>&1 | ForEach-Object { Write-NativeLogLine $_ }
    $preflightCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  Write-Log "preflightFinished=$(Get-Date -Format o)"
  Write-Log "preflightExitCode=$preflightCode"
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
  & npm run oracle:std-full 2>&1 | ForEach-Object { Write-NativeLogLine $_ }
  $code = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}

Write-Log "finished=$(Get-Date -Format o)"
Write-Log "exitCode=$code"

if ($code -eq 0) {
  Write-Host "Full Std PASS. Please send/upload $Log."
} else {
  Write-Host "Full Std did not complete successfully. Please send/upload $Log; the last module/error is enough to continue debugging."
}
exit $code
