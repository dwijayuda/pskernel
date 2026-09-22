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
& npm run oracle:std-full 2>&1 | Tee-Object -FilePath $Log -Append
$code = $LASTEXITCODE

"finished=$(Get-Date -Format o)" | Add-Content $Log
"exitCode=$code" | Add-Content $Log

if ($code -eq 0) {
  Write-Host "Full Std PASS. Please send/upload $Log."
} else {
  Write-Host "Full Std did not complete successfully. Please send/upload $Log; the last module/error is enough to continue debugging."
}
exit $code
