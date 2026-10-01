#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2); const command = args.shift();
let script; let forwarded;
if (!command || command === '--help') {
  console.log(`PSC2 Lean-checked profile (default kernel: pskernel-lean / lean434)
  node lean-checked/psc.mjs check <entry> [--compiler compiler.js | --seed binary]
  node lean-checked/psc.mjs build <entry> --out output.js [--compiler compiler.js | --seed binary]
  node lean-checked/psc.mjs bootstrap
  node lean-checked/psc.mjs selfhost
  node lean-checked/psc.mjs fixed-point
  node lean-checked/psc.mjs verify-selfhost

The original npm run fixed-point remains a compiler-only diagnostic.
This profile never silently falls back to an unchecked build.`);
} else {
  if (command === 'check' || command === 'build') {
    script = 'scripts/checked-build.mjs'; forwarded = [...args];
    if (command === 'check') forwarded.push('--check');
  } else {
    const stage = { bootstrap: 'bootstrap', selfhost: 'next', 'fixed-point': 'fixed-point', 'verify-selfhost': 'verify' }[command];
    if (!stage || args.length) throw new Error('Unsupported checked-profile command or option');
    script = 'scripts/checked-selfhost.mjs'; forwarded = [stage];
  }
  const result = spawnSync(process.execPath, [path.join(root, script), ...forwarded], { cwd: root, stdio: 'inherit' });
  if (result.error) throw result.error;
  process.exitCode = result.status ?? 1;
}
