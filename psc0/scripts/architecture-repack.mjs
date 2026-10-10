// Cloud-only fast candidate: retain exact compiler/kernel bytes, replace only
// host orchestration, then npm pack/install normally. No runtime generation.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { stageNpmHost, normalizeFacadeEntry } from './npm-host-packaging.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const [archiveDirectory, stageDirectory, variant] = process.argv.slice(2);
assert(archiveDirectory && stageDirectory && ['ps', 'lean'].includes(variant), 'repack arguments');
const sha = value => createHash('sha256').update(value).digest('hex');
const manifest = JSON.parse(await readFile(path.join(archiveDirectory, 'manifest.json'), 'utf8'));
assert.equal(manifest.sourceCommit, '2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a');
assert.equal(manifest.sourceVariant, variant);
const selected = ['proofscript-0.1.0-psc0.1.tgz', 'typescript-7.0.2.tgz', 'typescript-typescript-' + process.platform + '-x64-7.0.2.tgz'];
for (const filename of selected) {
  const record = manifest.packages.find(p => p.name === filename);
  assert(record && /^[a-f0-9]{64}$/u.test(record.sha256), 'missing artifact digest: ' + filename);
  assert.equal(sha(await readFile(path.join(archiveDirectory, filename))), record.sha256, 'artifact digest mismatch: ' + filename);
}
await mkdir(stageDirectory, { recursive: true });
execFileSync('tar', ['-xzf', path.join(archiveDirectory, selected[0]), '-C', stageDirectory]);
const target = path.join(stageDirectory, 'package');
const runtimePaths = ['node_modules/@proofscript/compiler/dist/index.js', 'node_modules/@proofscript/pskernel-core/dist/index.js'];
const before = await Promise.all(runtimePaths.map(async p => sha(await readFile(path.join(target, p)))));
await stageNpmHost(root, target);
const metadata = JSON.parse(await readFile(path.join(target, 'package.json'), 'utf8'));
for (const name of metadata.proofscript.corePackages) {
  const file = path.join(target, 'node_modules', name, 'package.json');
  const pkg = JSON.parse(await readFile(file, 'utf8'));
  if (name !== '@proofscript/pskernel-core') await writeFile(file, JSON.stringify(normalizeFacadeEntry(pkg, name.replace('@proofscript/', '')), null, 2) + '\n');
}
metadata.private = true; // This qualification candidate must not be published.
metadata.proofscript.architectureHost = 'checked-host/1';
await writeFile(path.join(target, 'package.json'), JSON.stringify(metadata, null, 2) + '\n');
const after = await Promise.all(runtimePaths.map(async p => sha(await readFile(path.join(target, p)))));
assert.deepEqual(after, before, 'retained runtime changed');
const report = { schema: 'psc0-reused-runtime-candidate/1', source: execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim(), variant, retainedRuntimeSource: manifest.sourceCommit, retainedRuntimeRun: 38075437516, compilerSha256: before[0], kernelSha256: before[1], compilerRegenerated: false, kernelRegenerated: false, newFixedPointClaimed: false, hostRepacked: true };
await writeFile(path.join(target, 'MANIFEST.json'), JSON.stringify(report, null, 2) + '\n');
await mkdir(path.join(root, 'dist/architecture-evidence'), { recursive: true });
await writeFile(path.join(root, 'dist/architecture-evidence/repack-' + variant + '.json'), JSON.stringify(report, null, 2) + '\n');
console.log('PSC_ARCHITECTURE_REPACK: PASS ' + JSON.stringify(report));
