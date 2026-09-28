import { mkdtempSync, readFileSync, writeFileSync, copyFileSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { collectBackendJsClosure } from './backend-js-closure.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sources = collectBackendJsClosure(root);
const out = mkdtempSync(path.join(os.tmpdir(), 'psc-js-source-'));
const phaseTimeoutMs = 90000;

function phase(label, command, args, cwd) {
  console.log(`BACKEND_JS_SOURCE_PHASE: ${label}: START`);
  const result = spawnSync(command, args, {
    cwd,
    stdio: 'inherit',
    timeout: phaseTimeoutMs,
  });
  if (result.error) {
    const code = result.error.code ?? result.error.message;
    throw new Error(`BACKEND_JS_SOURCE_PHASE_FAILED: ${label} (${code})`);
  }
  if (result.status !== 0) {
    throw new Error(`BACKEND_JS_SOURCE_PHASE_FAILED: ${label} (exit ${result.status})`);
  }
  console.log(`BACKEND_JS_SOURCE_PHASE: ${label}: PASS`);
}

function runPsc1(label, args) {
  phase(label, 'lake', ['exe', 'psc1', ...args], root);
}

try {
  const lean = path.join(out, 'BackendJs.lean');
  const ps = path.join(out, 'BackendJs.ps');
  const backendJs = path.join(out, 'backend.js');
  const backendMjs = path.join(out, 'backend.mjs');
  const probeRunner = path.join(out, 'generated-backend-probe.mjs');
  const probe = readFileSync(path.join(root, 'test/BackendJsSelfhostProbe.lean'), 'utf8');

  writeFileSync(lean, [...sources, { source: probe }].map(({ source }) => source.split(/\r?\n/u)
    .filter(line => !/^\s*import\s/u.test(line)).join('\n')).join('\n\n'));

  runPsc1('lean-check', ['check', lean]);
  runPsc1('lean-to-ps', ['translate', lean, '--to', 'ps', '--out', ps]);
  runPsc1('ps-check', ['check', ps]);
  console.log('BACKEND_JS_PSC1_SOURCE: PASS (Lean and canonical PS admission-ready checks)');

  runPsc1('ps-build', ['build', ps, '--out', backendJs]);
  copyFileSync(backendJs, backendMjs);
  writeFileSync(probeRunner, `
import assert from 'node:assert/strict';
import { writeFileSync } from 'node:fs';

const compiled = await import('./backend.mjs');
const emitted = compiled.psJsSelfhostProbe(undefined);
assert.equal(typeof emitted, 'string');
writeFileSync('./probe.mjs', emitted);
const result = await import('./probe.mjs');
assert.equal(result.answer, 9007199254740993123456789n);
`);
  phase('generated-execution', process.execPath, [probeRunner], out);
  console.log('BACKEND_JS_GENERATED_EXECUTION: PASS (PSC1 -> PS -> TS seed -> executable backend -> direct JS)');
} finally {
  rmSync(out, { recursive: true, force: true });
}
