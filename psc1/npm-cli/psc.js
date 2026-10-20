#!/usr/bin/env node
// Transport only: the same checked native executable owns every command and
// target. Never import the archived PSC0 generated compiler/kernel as a fallback.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn, spawnSync } from 'node:child_process';

const here = path.dirname(fileURLToPath(import.meta.url));
const workspace = path.resolve(here, '..');
const pin = JSON.parse(fs.readFileSync(path.join(workspace, 'NATIVE_SOURCE_PIN.json'), 'utf8'));
const installedNative = path.join(workspace, 'native', 'bin', 'psc1');
const native = process.env.PSC1_NATIVE || (fs.existsSync(installedNative)
  ? installedNative : path.join(workspace, '.lake', 'build', 'bin', 'psc1'));
const resolver = process.env.PSC1_LIBRARY_RESOLVER || path.join(workspace, 'npm-cli', 'libraries.mjs');
const nativeLibrary = path.join(workspace, 'native', 'lib');
const nativeEnv = { ...process.env, PSC1_LIBRARY_RESOLVER: resolver,
  LD_LIBRARY_PATH: [nativeLibrary, process.env.LD_LIBRARY_PATH].filter(Boolean).join(path.delimiter) };
const tools = process.env.PSC1_HOST_TOOLS || path.join(workspace, 'host-tools', 'artifacts.mjs');
const report = message => { console.error(message); process.exitCode = 1; };

if (!fs.existsSync(native)) {
  report('PSC1_NATIVE_MISSING: build the pinned PSC1 native executable or set PSC1_NATIVE. No generated-compiler fallback is permitted.');
} else {
  const identity = spawnSync(native, ['--identity'], { env: nativeEnv, encoding: 'utf8', timeout: 10_000, maxBuffer: 1024 * 1024 });
  let value;
  try { value = JSON.parse(identity.stdout || 'null'); } catch { value = null; }
  if (identity.error || identity.status !== 0 || value?.protocol !== pin.compilerProtocol ||
      value?.profile !== pin.compilerProfile || value?.lean !== pin.version ||
      value?.leanCommit !== pin.commit) {
    report('PSC1_NATIVE_IDENTITY_MISMATCH: the selected executable is not this PSC1 command/profile implementation.');
  } else {
    const child = spawn(native, process.argv.slice(2), {
      stdio: 'inherit', env: { ...nativeEnv, PSC1_HOST_TOOLS: tools }
    });
    for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => child.kill(signal));
    child.on('error', error => report(`PSC1_NATIVE_LAUNCH_FAILED: ${error.message}`));
    child.on('exit', (code, signal) => { process.exitCode = code ?? (signal === 'SIGINT' ? 130 : 1); });
  }
}
