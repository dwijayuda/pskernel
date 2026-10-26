// Host-only .8 assembly from exact .7 artifacts that passed the installed replay.
// Do not rebuild or relabel any compiler/kernel/provider payload or G3 evidence.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readQualifiedArtifact, sha256} from './kernel435-qualified-artifact.mjs';
const qualification = JSON.parse(fs.readFileSync('docs/PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json'));
const old = qualification.exactCandidateReplay;
assert.equal(old.status, 'qualified-exact-candidate-installed');
const input = {run: old.run, job: old.job, commit: old.testCommit,
  artifact: old.artifact.id, zipSha256: old.artifact.sha256};
const archive = await readQualifiedArtifact(input, 'dist/cli-qualified-input');
function find(directory, suffix) {
  const result = [];
  for (const item of fs.readdirSync(directory, {withFileTypes: true})) {
    const file = path.join(directory, item.name);
    if (item.isDirectory()) result.push(...find(file, suffix));
    else if (item.isFile() && file.endsWith(suffix)) result.push(file);
  }
  return result;
}
const receipts = find(archive, '/package-receipt.json'); assert.equal(receipts.length, 1);
const original = JSON.parse(fs.readFileSync(receipts[0]));
assert.equal(original.version, '0.1.0-psc1.7');
assert.equal(original.sha256, old.rootSha256);
assert.equal(original.bytes, old.rootBytes);
const qualified = path.dirname(receipts[0]), out = path.resolve('dist/slim-universal');
assert.equal(fs.existsSync(out), false, 'fresh staging required');
fs.mkdirSync(out, {recursive: true});
fs.cpSync(path.join(qualified, 'tarballs'), path.join(out, 'tarballs'), {recursive: true});
fs.copyFileSync(path.join(qualified, 'compiler-kernel-admission.json'),
  path.join(out, 'compiler-kernel-admission.json'));
const run = (exe, args) => {
  const r = spawnSync(exe, args, {encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024});
  assert.equal(r.error, undefined, String(r.error)); assert.equal(r.status, 0, r.stdout + r.stderr);
  return r.stdout;
};
const tar = path.join(out, 'tarballs', original.tarball), bytes = fs.readFileSync(tar);
assert.equal(sha256(bytes), old.rootSha256); assert.equal(bytes.length, old.rootBytes);
for (const name of run('tar', ['tzf', tar]).split('\n').filter(Boolean))
  assert.ok(name.startsWith('package/') && !name.includes('\\') && !name.split('/').includes('..'));
run('tar', ['xzf', tar, '-C', out]);
const stage = path.join(out, 'package');
function inventory(directory, prefix = '') {
  const rows = [];
  for (const name of fs.readdirSync(path.join(directory, prefix)).sort()) {
    const relative = prefix ? prefix + '/' + name : name, file = path.join(directory, relative);
    const stat = fs.lstatSync(file);
    assert.ok(!stat.isSymbolicLink());
    if (stat.isDirectory()) rows.push(...inventory(directory, relative));
    else { assert.ok(stat.isFile()); const b = fs.readFileSync(file);
      rows.push({path: relative, bytes: b.length, sha256: sha256(b)}); }
  }
  return rows;
}
const before = inventory(stage);
const d = JSON.parse(fs.readFileSync(path.join(stage, 'UNIVERSAL_DISTRIBUTION.json')));
assert.equal(d.compilerSourceClosureDigest, qualification.compilerSourceClosureDigest);
// Every existing executable host boundary matches current source before reuse.
for (const pin of d.hostFiles.filter(p => /^(host-tools|npm-cli|scripts)\//.test(p.path))) {
  assert.equal(sha256(fs.readFileSync(pin.path)), pin.sha256, 'current production changed: ' + pin.path);
  assert.equal(sha256(fs.readFileSync(path.join(stage, pin.path))), pin.sha256);
}
const version = '0.1.0-psc1.8';
const added = ['npm-cli/proofscript-cli.mjs', 'npm-cli/cli-project.mjs'];
for (const file of added) fs.copyFileSync(file, path.join(stage, file));
fs.chmodSync(path.join(stage, added[0]), 0o755);
const metaFile = path.join(stage, 'package.json'), meta = JSON.parse(fs.readFileSync(metaFile));
meta.version = version;
meta.bin = {proofscript: './npm-cli/proofscript-cli.mjs',
  psc: './npm-cli/proofscript-cli.mjs', psc1: './npm-cli/proofscript-cli.mjs'};
fs.writeFileSync(metaFile, JSON.stringify(meta, null, 2) + '\n');
for (const name of ['npm-shrinkwrap.json', 'DEPENDENCY_LOCK.json']) {
  const file = path.join(stage, name);
  // npm's exact qualified tarball omits npm-shrinkwrap.json; preserve that absence.
  if (name === 'npm-shrinkwrap.json' && !fs.existsSync(file)) continue;
  const lock = JSON.parse(fs.readFileSync(file));
  lock.version = version; lock.packages[''].version = version;
  fs.writeFileSync(file, JSON.stringify(lock, null, 2) + '\n');
}
const guide = fs.readFileSync('docs/PSC1_CLI.md', 'utf8');
fs.appendFileSync(path.join(stage, 'README.md'), '\n\n' + guide);
d.version = version; d.packageBuildCommit = process.env.GITHUB_SHA;
const pin = file => {const b = fs.readFileSync(path.join(stage, file));
  return {path: file, bytes: b.length, sha256: sha256(b)};};
d.hostFiles = [...d.hostFiles.map(p => pin(p.path)), ...added.map(pin)];
const manifest = JSON.stringify(d, null, 2) + '\n';
fs.writeFileSync(path.join(stage, 'UNIVERSAL_DISTRIBUTION.json'), manifest);
fs.writeFileSync(path.join(stage, 'DISTRIBUTION_PIN.mjs'),
  "export const expectedDistributionSha256='" + sha256(manifest) + "';\n" +
  "export const expectedCompilerSourceClosureDigest='" + d.compilerSourceClosureDigest + "';\n");
const changed = new Set(['package.json', 'npm-shrinkwrap.json', 'DEPENDENCY_LOCK.json',
  'README.md', 'UNIVERSAL_DISTRIBUTION.json', 'DISTRIBUTION_PIN.mjs']);
for (const row of before)
  if (!changed.has(row.path)) assert.equal(sha256(fs.readFileSync(path.join(stage, row.path))), row.sha256,
    'host-only assembly changed retained payload: ' + row.path);
assert.equal(inventory(stage).length, before.length + added.length);
const packed = JSON.parse(run('npm', ['pack', stage, '--ignore-scripts', '--json',
  '--pack-destination', path.join(out, 'tarballs')]));
assert.equal(packed.length, 1);
const packedFile = path.join(out, 'tarballs', packed[0].filename), packedBytes = fs.readFileSync(packedFile);
const receipt = {...original, sourceCommit: process.env.GITHUB_SHA, version,
  tarball: packed[0].filename, sha256: sha256(packedBytes), bytes: packedBytes.length,
  hostOnly: true, hostInput: input, preservedPayloadFiles: before.filter(row => !changed.has(row.path)).length,
  sizeRatio: packedBytes.length / original.previousRootBytes,
  removedBytes: original.previousRootBytes - packedBytes.length,
  originalRootSha256: old.rootSha256,
  scope: 'host CLI only; unchanged qualified G3s/kernels/providers; installed qualification pending'};
fs.writeFileSync(path.join(out, 'package-receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_CLI_PACKAGE: ' + JSON.stringify({version, tarball: receipt.tarball,
  sha256: receipt.sha256, bytes: receipt.bytes, preservedPayloadFiles: receipt.preservedPayloadFiles}));
