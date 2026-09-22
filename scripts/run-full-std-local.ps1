param(
  [int]$HeapMiB = 12288,
  [int]$StackKiB = 65500,
  [string]$Log = "full-std.log"
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
$leanVersion = (& lean --version | Select-Object -First 1).Trim()
if ($leanVersion -notmatch "version 4\.34\.0.*Release") {
  throw "Expected Lean 4.34.0 Release, got: $leanVersion"
}

$env:PSKERNEL_STD_HEAP_MIB = "$HeapMiB"
$env:PSKERNEL_STD_STACK_KIB = "$StackKiB"

"pskernel canonical Full Std" | Set-Content $Log
"started=$(Get-Date -Format o)" | Add-Content $Log
"node=$nodeVersion" | Add-Content $Log
"lean=$leanVersion" | Add-Content $Log
"heapMiB=$HeapMiB stackKiB=$StackKiB" | Add-Content $Log

Write-Host "Installing dependencies..."
& npm install --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Building pskernel..."
& npm run build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

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
