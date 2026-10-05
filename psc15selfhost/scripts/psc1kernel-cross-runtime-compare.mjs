// Opt-in same-runner experiment. Restore the sole temporary source substitution
// even if generation fails. No compiler fixed point or second native build.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
const source = 'packages/pskernel-core/src/Ps/KernelCore/Core/Substitution/Lift.lean';
const current = readFileSync(source);
execFileSync('git', ['fetch', '--depth=1', 'origin', 'd379472dcd515fceabd2e444a22245f75db4a9e8'],
  { stdio: 'inherit', timeout: 30_000 });
const baseline = execFileSync('git', ['show',
  'd379472dcd515fceabd2e444a22245f75db4a9e8:psc15selfhost/' + source]);
try {
  writeFileSync(source, baseline);
  execFileSync('.lake/build/bin/psc1', ['build', 'test/KernelCore/Bench/CrossRuntime.lean',
    '--out', 'dist/cross-runtime/baseline.js'], { stdio: 'inherit', timeout: 120_000 });
} finally { writeFileSync(source, current); }
