// Use already generated checked TS as the target fixture. Do not regenerate
// the compiler/kernel or perform another source elaboration for this comparison.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { mkdir, readdir, readFile, writeFile, appendFile, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const [prefix, variant, project] = process.argv.slice(2);
assert(prefix && project && ['ps', 'lean'].includes(variant));
const packageRoot = path.join(prefix, ...(process.platform === 'win32' ? ['node_modules'] : ['lib', 'node_modules']), 'proofscript');
const require = createRequire(path.join(packageRoot, 'package.json'));
const { createTypeScriptTarget, captureTypeScriptInstallation, targetFlags } = await import(pathToFileURL(path.join(packageRoot, 'bin/target-toolchain.mjs')).href);
const { targetEnvironment } = await import(pathToFileURL(path.join(packageRoot, 'bin/target-process.mjs')).href);
const { publishGeneration } = await import(pathToFileURL(path.join(packageRoot, 'bin/publication.mjs')).href);
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const generations = (await readdir(path.join(project, '.psc-artifacts'))).filter(n => n.startsWith('Main-'));
assert.equal(generations.length, 1);
const generation = path.join(project, '.psc-artifacts', generations[0]);
const receipt = JSON.parse(await readFile(path.join(generation, 'receipt.json'), 'utf8'));
assert.equal(receipt.checkedBinding.targetPlanSha256, receipt.target.planSha256);
assert.equal(receipt.target.nativeProcessClosed, true);
assert.equal(receipt.target.targetSemanticsProven, false);
assert.equal(receipt.target.plan.toolchain.version, '7.0.2');
assert.equal(receipt.target.plan.toolchain.registryAuthenticityVerified, false);
assert(receipt.target.plan.flags.includes('--noResolve'));
const inputText = await readFile(path.join(generation, 'Main.ts'), 'utf8');
assert.equal(hash(inputText), receipt.target.inputTypeScriptSha256);
const inputDir = path.join(project, 'target-correspondence');
await mkdir(inputDir);
const input = path.join(inputDir, 'Equivalent.ts');
await writeFile(input, inputText);
const installation = await captureTypeScriptInstallation(require.resolve('typescript/package.json'));
assert.equal(installation.identity.nativeExecutableSha256, receipt.target.plan.toolchain.nativeExecutableSha256);
const legacy = () => spawnSync(process.execPath, [installation.launcher, '--ignoreConfig', input, ...targetFlags], { cwd: inputDir, env: targetEnvironment(), encoding: 'utf8', timeout: 30000, maxBuffer: 1024 * 1024 });
const reference = legacy();
assert(!reference.error && reference.status === 0, 'retained original launcher failed: ' + reference.stderr + reference.stdout);
const original = {};
for (const extension of ['.ts', '.js', '.d.ts', '.js.map']) original[extension] = await readFile(input.slice(0, -3) + extension, 'utf8');
for (const extension of ['.js', '.d.ts', '.js.map']) await rm(input.slice(0, -3) + extension);
// Prove that the fixture really is sensitive to ambient typings under the old
// invocation, then prove the new private typeRoots keep those files out.
const noise = path.join(project, 'node_modules/@types/psc-target-noise');
await mkdir(noise, { recursive: true });
await writeFile(path.join(noise, 'index.d.ts'), 'export declare const malformed: ;\n');
const polluted = legacy();
assert(!polluted.error && polluted.status !== 0, 'ambient fixture did not reach original TypeScript invocation');
assert((polluted.stdout + polluted.stderr).includes('psc-target-noise'), 'reference failed for an unrelated reason');
const target = await createTypeScriptTarget();
let generated;
try {
  generated = await target.compile(input);
  for (const extension of Object.keys(original)) assert.equal(generated.products[extension], original[extension], 'native target differs from original launcher: ' + extension);
  assert.equal(generated.evidence.nativeProcessClosed, true);
  await assert.rejects(target.compile(input), /SESSION_STATE/);
} finally { await rm(noise, { recursive: true, force: true }); }
// Modify only the isolated CI installation, after all target processes closed.
// Revalidate at publication; restore original bytes in every path.
const primary = path.join(project, 'Main.js'), before = await readFile(primary, 'utf8');
const bytes = await readFile(installation.executable);
try {
  await appendFile(installation.executable, Buffer.from([0]));
  await assert.rejects(publishGeneration({ output: primary, products: generated.products, receipt: {}, snapshot: { protectedPaths: [], revalidate: target.revalidate } }), /IDENTITY_CHANGED/);
  assert.equal(await readFile(primary, 'utf8'), before);
} finally { await writeFile(installation.executable, bytes); }
const libraryTarget = await createTypeScriptTarget();
const entry = installation.snapshot.identity.entries.find(e => e.kind === 'file' && e.id.endsWith('.d.ts'));
assert(entry, 'no TypeScript library captured');
const rootId = entry.id.split('/')[0];
const root = installation.snapshot.roots.find(r => r.id === rootId).directory;
const file = path.join(root, entry.id.slice(rootId.length + 1)), saved = await readFile(file);
try {
  await appendFile(file, '\n// changed after capture\n');
  await assert.rejects(libraryTarget.revalidate(), /IDENTITY_CHANGED/);
} finally { await writeFile(file, saved); }
const evidence = { schema: 'psc0-target-installed-qualification/1', source: process.env.GITHUB_SHA, platform: process.platform, node: process.version, variant, toolchain: installation.identity, actualCompilerEmittedFixture: true, originalLauncherProductsEqual: ['ts','js','d.ts','js.map'], ambientTypesReachOriginalInvocation: true, ambientTypesExcludedFromOwnedTarget: true, planBoundToCheckedHandle: true, nativeDriftRefusesPublication: true, previousExecutablePreserved: true, libraryDriftRefused: true, toolchainBytesRestored: true, compilerRegenerated: false, kernelRegenerated: false, fullFixedPointExecuted: false };
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
await writeFile(path.join(repoRoot, 'dist/architecture-evidence/target-' + variant + '.json'), JSON.stringify(evidence, null, 2) + '\n');
console.log('PSC_TARGET_INSTALLED: PASS ' + JSON.stringify(evidence));
