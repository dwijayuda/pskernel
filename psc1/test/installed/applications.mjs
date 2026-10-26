// Run the unchanged installed application assertions against the exact compiler
// source represented by the frozen G3 payload, not a later readability refactor.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {sha256} from '../../scripts/kernel435-qualified-artifact.mjs';
const current = process.cwd(), out = path.resolve('dist/slim-universal');
const q = JSON.parse(fs.readFileSync('docs/PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json'));
const snapshotCommit = q.exactCandidateReplay.testCommit;
assert.equal(snapshotCommit, '8383c6983e5fa2f2d945b02ba4b349ab64522c64');
const assembly = JSON.parse(fs.readFileSync(path.join(out, 'package-receipt.json')));
assert.equal(assembly.compilerSourceClosureDigest, q.compilerSourceClosureDigest);
assert.match(snapshotCommit, /^[a-f0-9]{40}$/);
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-cli-frozen-source-'));
function run(exe, args, options = {}) {
  const r = spawnSync(exe, args, {cwd: current, encoding: 'utf8',
    timeout: 240000, maxBuffer: 32 * 1024 * 1024, ...options});
  assert.equal(r.error, undefined, String(r.error)); assert.equal(r.status, 0, r.stdout + r.stderr);
}
run('git', ['merge-base', '--is-ancestor', snapshotCommit, 'HEAD']);
const archive = path.join(temporary, 'source.tar');
run('git', ['archive', '--format=tar', '--output=' + archive, snapshotCommit, 'psc1'],
  {cwd: path.resolve(current, '..')});
run('tar', ['xf', archive, '-C', temporary]);
const frozen = path.join(temporary, 'psc1');
const frozenOut = path.join(frozen, 'dist/slim-universal');
fs.mkdirSync(frozenOut, {recursive: true});
// Publication rejects symlinked path components. Use a physical replay store;
// neither this harness nor its source snapshot may weaken that guard.
fs.cpSync(path.join(out, 'tarballs'), path.join(frozenOut, 'tarballs'), {recursive: true});
fs.copyFileSync(path.join(out, 'package-receipt.json'), path.join(frozenOut, 'package-receipt.json'));
const script = path.join(current, 'scripts/generated-io-installed-applications.mjs');
const scriptHash = sha256(fs.readFileSync(script));
// Only this aggregate supervisor is25min. All original inner compiler/tool240s,
// independent checker120s, exact source/census/hash/contract assertions remain.
run(process.execPath, [script], {cwd: frozen, stdio: 'inherit', timeout: 1500000});
const resultFile = path.join(frozenOut, 'application-qualification.json');
const result = JSON.parse(fs.readFileSync(resultFile));
assert.equal(result.status, 'passed');
assert.equal(result.compilerSourceClosureDigest, assembly.compilerSourceClosureDigest);
assert.equal(sha256(fs.readFileSync(script)), scriptHash);
fs.copyFileSync(resultFile, path.join(out, 'application-qualification.json'));
const evidence = path.join(out, 'cli-frozen-application-stores.tar.gz');
run('tar', ['czf', evidence, '-C', frozenOut, 'installed-applications']);
const evidenceSha256 = sha256(fs.readFileSync(evidence));
const report = {schema: 'psc1-cli-frozen-application-source/1', status: 'passed',
  testedCommit: process.env.GITHUB_SHA, snapshotCommit,
  compilerSourceClosureDigest: assembly.compilerSourceClosureDigest,
  testScriptSha256: scriptHash, evidenceSha256, originalSourceAndCensusAssertions: 'unchanged and passed',
  currentDevelopmentCompilerPromotion: false};
fs.writeFileSync(path.resolve('dist/cli/frozen-application-source.json'),
  JSON.stringify(report, null, 2) + '\n');
console.log('PSC1_CLI_FROZEN_APPLICATION_SOURCE: ' + JSON.stringify(report));
