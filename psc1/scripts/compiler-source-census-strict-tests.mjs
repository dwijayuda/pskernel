// Exercise strict mode against the actual live closure, accepting only the measured verdict.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const evidence = path.join(root, 'dist/scoped-correctness/compiler-source-census');
const inventory = JSON.parse(fs.readFileSync(path.join(evidence, 'inventory.json'), 'utf8'));
const phase = inventory.phases.find(p => p.name === 'semantic-compiler');
const measured = Object.fromEntries(['lean', 'ps'].map(grammar => {
  assert.equal(inventory.lanes[grammar].probe.completed, true);
  const data = JSON.parse(fs.readFileSync(path.join(evidence, inventory.lanes[grammar].stages), 'utf8'));
  const rows = data.records.filter(row => phase.modules.includes(row.module));
  assert.equal(rows.length, phase.modules.length);
  return [grammar, rows.every(row => row.parse === 'accepted' && row.elaboration === 'accepted' &&
    (grammar === 'lean' || row.translation === 'accepted'))];
}));
const shouldAccept = measured.lean && measured.ps;
const run = spawnSync(process.execPath, ['scripts/compiler-source-census.mjs',
  '--strict-phase', phase.name], { cwd: root, encoding: 'utf8', timeout: 240000,
    maxBuffer: 32 * 1024 * 1024 });
assert.equal(run.error, undefined);
assert.equal(run.signal, null);
if (shouldAccept) assert.equal(run.status, 0, run.stderr);
else {
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /PSC1_CENSUS_STRICT_REFUSAL:/);
}
fs.writeFileSync(path.join(evidence, 'strict-semantic.json'), JSON.stringify({
  schema: 'psc1-census-live-strict-check/1', commit: process.env.GITHUB_SHA || null,
  phase: phase.name, measured, expectedAcceptance: shouldAccept, status: run.status,
  passed: true, stdout: run.stdout, stderr: run.stderr,
  admission: 'not-run', ir: 'not-run', fixedPoint: 'not-run'
}, null, 2) + '\n');
console.log('PSC1_CENSUS_LIVE_STRICT: measured ' +
  (shouldAccept ? 'complete acceptance' : 'incomplete closure refusal') + ' verified');
