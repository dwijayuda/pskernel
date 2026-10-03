#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const command = args.shift();
let script;
let forwarded;

if (!command || command === '--help') {
  console.log(`PSC2 checked compiler profile (default kernel: lean434 native)
  node lean-checked/psc.mjs check <entry> [--compiler compiler.js | --seed binary] [--kernel lean434|lean434-wasm|pskernel-core]
  node lean-checked/psc.mjs build <entry> --out output.js [--compiler compiler.js | --seed binary] [--kernel lean434|lean434-wasm|pskernel-core]
  node lean-checked/psc.mjs bootstrap [--kernel lean434|lean434-wasm|pskernel-core]
  node lean-checked/psc.mjs selfhost [--kernel lean434|lean434-wasm|pskernel-core]
  node lean-checked/psc.mjs fixed-point [--kernel lean434|lean434-wasm|pskernel-core]
  node lean-checked/psc.mjs verify-selfhost [--kernel lean434|lean434-wasm|pskernel-core]

lean434 uses @proofscript/pskernel-lean and is the default native checker.
lean434-wasm uses @proofscript/pskernel-lean-wasm as the explicit portable alternative.
pskernel-core preserves the generated owned kernel as an explicit experimental alternative.
The original npm run fixed-point remains a compiler-only diagnostic.
This profile never silently falls back to an unchecked or different kernel.`);
} else {
  if (command === 'check' || command === 'build') {
    script = 'scripts/checked-build.mjs';
    forwarded = [...args];
    if (command === 'check') forwarded.push('--check');
  } else {
    const stage = {
      bootstrap: 'bootstrap',
      selfhost: 'next',
      'fixed-point': 'fixed-point',
      'verify-selfhost': 'verify',
    }[command];
    if (!stage) throw new Error('Unsupported checked-profile command');
    forwarded = [stage, ...args];
    script = 'scripts/checked-selfhost.mjs';
  }
  const result = spawnSync(process.execPath, [path.join(root, script), ...forwarded], {
    cwd: root,
    stdio: 'inherit',
  });
  if (result.error) throw result.error;
  process.exitCode = result.status ?? 1;
}
