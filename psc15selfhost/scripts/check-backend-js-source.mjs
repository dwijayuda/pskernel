import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, writeFileSync, copyFileSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
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
  const probe = readFileSync(path.join(root, 'test/BackendJsSelfhostProbe.lean'), 'utf8');
  writeFileSync(lean, [...sources, { source: probe }].map(({ source }) => source.split(/\r?\n/u)
    .filter(line => !/^\s*import\s/u.test(line)).join('\n')).join('\n\n'));
  run(['check', lean]);
  run(['translate', lean, '--to', 'ps', '--out', ps]);
  run(['check', ps]);
  console.log('BACKEND_JS_PSC1_SOURCE: PASS (Lean and canonical PS admission-ready checks)');
  run(['build', ps, '--out', path.join(out, 'backend.js')]);
  copyFileSync(path.join(out, 'backend.js'), path.join(out, 'backend.mjs'));
  const compiled = await import(pathToFileURL(path.join(out, 'backend.mjs')));
  const emitted = compiled.psJsSelfhostProbe(undefined);
  assert.equal(typeof emitted, 'string');
  writeFileSync(path.join(out, 'probe.mjs'), emitted);
  const result = await import(pathToFileURL(path.join(out, 'probe.mjs')));
  assert.equal(result.answer, 9007199254740993123456789n);
  console.log('BACKEND_JS_GENERATED_EXECUTION: PASS (PSC1 -> PS -> TS seed -> executable backend -> direct JS)');
} finally { rmSync(out, { recursive: true, force: true }); }
