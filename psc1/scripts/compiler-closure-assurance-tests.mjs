// Live assurance boundary: a partial backend cannot be promoted to checked-only.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
const root = process.cwd();
const run = spawnSync(process.execPath,
  ['scripts/compiler-closure-qualification.mjs', '--phase', 'directjs-compiler', '--assurance', 'checked'],
  { cwd: root, encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
assert.equal(run.error, undefined);
assert.notEqual(run.status, 0, 'checked-only must refuse actual source partials');
const result = JSON.parse(fs.readFileSync(path.join(root,
  'dist/scoped-correctness/compiler-closure/directjs-compiler/checked/results.json'), 'utf8'));
assert.equal(result.commit, process.env.GITHUB_SHA);
assert.equal(result.assurance, 'checked');
assert.equal(result.passed, false);
for (const grammar of ['lean', 'ps']) {
  const lane = result.lanes[grammar];
  assert.equal(lane.probe.integrityError, null);
  assert.equal(lane.observed.records.length, result.modules);
  assert.ok(lane.observed.records.every(row => row.parse === 'accepted' && row.elaboration === 'accepted'));
  assert.equal(lane.observed.preparation, 'refused');
  assert.equal(lane.observed.detail, 'admission-encoding:unsupportedDeclaration');
  assert.equal(lane.observed.admission, 'not-run');
  assert.equal(lane.observed.ir, 'not-run');
}
console.log('PSC1_CHECKED_BACKEND_PARTIAL_BOUNDARY: both actual source lanes refused as required');
