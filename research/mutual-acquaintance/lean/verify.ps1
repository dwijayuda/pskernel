$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Write-Host 'Lean version:'
& lean --version
if ($LASTEXITCODE -ne 0) { throw 'Lean version check failed' }
$files = @('MutualAcquaintance.lean','MutualAcquaintanceDynamics.lean','MutualAcquaintanceIdentification.lean','MutualAcquaintanceDecision.lean')
foreach ($file in $files) {
  Write-Host "Verifying $file ..."
  & lean ".\$file"
  $code = $LASTEXITCODE
  if ($code -ne 0) { throw "Lean failed ($code) for $file" }
  $digest = (Get-FileHash -Algorithm SHA256 ".\$file").Hash.ToLowerInvariant()
  Write-Host "PASS $file SHA256=$digest"
}
Write-Host 'PASS: All Lean files compiled (no reported errors).'
