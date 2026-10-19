#!/usr/bin/env node
// Transport only: the same checked native executable owns every command and
// target. Never import the archived PSC0 generated compiler/kernel as a fallback.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn, spawnSync } from 'node:child_process';

const here = path.dirname(fileURLToPath(import.meta.url));
const workspace = path.resolve(here, '..');
const native = process.env.PSC1_NATIVE || path.join(workspace, '.lake', 'build', 'bin', 'psc1');
const tools = process.env.PSC1_HOST_TOOLS || path.join(workspace, 'host-tools', 'artifacts.mjs');
const report = message => { console.error(message); process.exitCode = 1; };

if (!fs.existsSync(native)) {
  report('PSC1_NATIVE_MISSING: build the pinned PSC1 native executable or set PSC1_NATIVE. No generated-compiler fallback is permitted.');
} else {
  const identity = spawnSync(native, ['--identity'], { encoding: 'utf8', timeout: 10_000, maxBuffer: 1024 * 1024 });
  let value;
  try { value = JSON.parse(identity.stdout || 'null'); } catch { value = null; }
  if (identity.error || identity.status !== 0 || value?.protocol !== 'psc1-native/1' ||
      value?.profile !== 'psc1-checked-direct/1' || value?.lean !== '4.34.0') {
    report('PSC1_NATIVE_IDENTITY_MISMATCH: the selected executable is not this PSC1 command/profile implementation.');
  } else {
    const child = spawn(native, process.argv.slice(2), {
      stdio: 'inherit', env: { ...process.env, PSC1_HOST_TOOLS: tools }
    });
    for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => child.kill(signal));
    child.on('error', error => report(`PSC1_NATIVE_LAUNCH_FAILED: ${error.message}`));
    child.on('exit', (code, signal) => { process.exitCode = code ?? (signal === 'SIGINT' ? 130 : 1); });
  }
}
