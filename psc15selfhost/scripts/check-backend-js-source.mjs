import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { collectBackendJsClosure } from './backend-js-closure.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sources = collectBackendJsClosure(root);
const out = mkdtempSync(path.join(os.tmpdir(), 'psc-js-source-'));
function run(args) {
  const result = spawnSync('lake', ['exe', 'psc1', ...args], { cwd: root, stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`BACKEND_JS_SOURCE_FAILED: ${args[0]} (exit ${result.status})`);
}
try {
  const lean = path.join(out, 'BackendJs.lean');
  const ps = path.join(out, 'BackendJs.ps');
  writeFileSync(lean, sources.map(({ source }) => source.split(/\r?\n/u)
    .filter(line => !/^\s*import\s/u.test(line)).join('\n')).join('\n\n'));
  run(['check', lean]);
  run(['translate', lean, '--to', 'ps', '--out', ps]);
  run(['check', ps]);
  console.log('BACKEND_JS_PSC1_SOURCE: PASS (Lean and canonical PS admission-ready checks)');
} finally { rmSync(out, { recursive: true, force: true }); }
