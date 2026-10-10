// Continue the existing installed canary: one additional small source check,
// not a new compiler build. No npm scripts or package entrypoints are executed.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile, readdir, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const [prefix, variant, project] = process.argv.slice(2);
assert(prefix && project && ['ps', 'lean'].includes(variant));
const packageRoot = path.join(prefix, ...(process.platform === 'win32' ? ['node_modules'] : ['lib', 'node_modules']), 'proofscript');
const cli = path.join(packageRoot, 'bin/psc.js');
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const run = args => spawnSync(process.execPath, [cli, ...args], { cwd: project, encoding: 'utf8', timeout: 180000, maxBuffer: 4 * 1024 * 1024 });
const generations = (await readdir(path.join(project, '.psc-artifacts'))).filter(n => n.startsWith('Main-'));
assert.equal(generations.length, 1);
const prior = JSON.parse(await readFile(path.join(project, '.psc-artifacts', generations[0], 'receipt.json'), 'utf8'));
function inspect(audit) {
  const d = audit.libraryDisclosure;
  assert.equal(audit.checkedBinding.libraryDisclosureSha256, d.sha256);
  assert.equal(audit.inputs.libraryDisclosureSha256, d.sha256);
  assert.equal(d.sha256, hash('PSC0/LIBRARY-DISCLOSURE/1\0' + JSON.stringify(d.inventory)));
  assert.equal(d.inventory.libraries.length, 1);
  assert.equal(d.inventory.proofAuthority, 'none'); assert.deepEqual(d.inventory.executedExtensions, []);
  assert.equal(d.inventory.registryAuthenticityVerified, false);
  assert.equal(audit.claims.fullPscvVerified, false);
  const lib = d.inventory.libraries[0];
  assert.equal(lib.packageName, '@psc-fixture/math'); assert.equal(lib.version, '0.0.1');
  assert.deepEqual(lib.modules.map(m => m.moduleName), ['Demo.Math']);
  for (const e of [lib.manifest, ...lib.modules]) {
    const captured = audit.inputs.inputs.find(i => i.id === e.inputId);
    assert.equal(captured.sha256, e.sha256); assert.equal(captured.bytes, e.bytes);
  }
  return lib;
}
inspect(prior);
const pkg = path.join(project, 'node_modules/@psc-fixture/math');
const manifestPath = path.join(pkg, 'package.json'), originalManifest = await readFile(manifestPath);
const sourcePath = path.join(pkg, 'src/Demo/Math.' + variant), originalSource = await readFile(sourcePath);
const output = path.join(project, 'Main.js'), oldOutput = await readFile(output);
const trap = path.join(pkg, 'must-not-run.cjs'), marker = path.join(pkg, 'UNEXPECTED_EXECUTION');
let accepted;
try {
  const meta = JSON.parse(originalManifest.toString('utf8'));
  meta.main = './must-not-run.cjs'; meta.exports['.'] = './must-not-run.cjs';
  meta.scripts = { postinstall: 'node must-not-run.cjs' };
  meta.proofscript.suppressExtensionDisclosure = true;
  meta.proofscript.claims = { fullPscvVerified: true, proofAuthority: 'kernel' };
  await writeFile(trap, 'require("node:fs").writeFileSync(__dirname + "/UNEXPECTED_EXECUTION", "unexpected"); throw new Error("LIBRARY_JS_EXECUTED");\n');
  await writeFile(manifestPath, JSON.stringify(meta));
  const checked = run(['check', 'src/Main.' + variant, '--json']);
  assert(!checked.error && checked.status === 0, checked.stderr);
  accepted = JSON.parse(checked.stdout); const lib = inspect(accepted);
  assert.equal(accepted.canonicalAdmissionsSha256, prior.canonicalAdmissionsSha256, 'disclosure must not change compiler admissions');
  assert.equal(lib.manifest.sha256, hash(await readFile(manifestPath)));
  assert.equal(lib.modules[0].sha256, hash(originalSource));
  assert.deepEqual(lib.declaredScriptNames, ['postinstall']);
  const notice = checked.stderr.split(/\r?\n/u).find(s => s.startsWith('PSC_SOURCE_LIBRARIES: '));
  assert(notice, 'host disclosure was suppressed');
  assert.equal(JSON.parse(notice.slice('PSC_SOURCE_LIBRARIES: '.length)).sha256, accepted.libraryDisclosure.sha256);
  assert(checked.stderr.includes('PSC_SOURCE_LIBRARY: ')); assert(checked.stderr.includes('@psc-fixture/math'));
  assert(!existsSync(marker), 'package JavaScript or lifecycle script executed');
  // Invalid terms from a library still undergo ordinary compiler/kernel checks.
  await writeFile(sourcePath, 'def demoAnswer : Nat := Type\n');
  const invalid = run(['build', 'src/Main.' + variant, '--out', 'Main.js']);
  assert(!invalid.error && invalid.status !== 0, 'invalid library accepted');
  assert.deepEqual(await readFile(output), oldOutput);
  await writeFile(sourcePath, originalSource);
  meta.proofscript.extensions = ['must-not-run.cjs'];
  await writeFile(manifestPath, JSON.stringify(meta));
  const extension = run(['build', 'src/Main.' + variant, '--out', 'Main.js']);
  assert(!extension.error && extension.status !== 0 && extension.stderr.includes('PSC_EXECUTABLE_EXTENSIONS_UNSUPPORTED'), extension.stderr);
  assert.deepEqual(await readFile(output), oldOutput); assert(!existsSync(marker));
} finally {
  await writeFile(manifestPath, originalManifest); await writeFile(sourcePath, originalSource);
  await rm(trap, { force: true }); await rm(marker, { force: true });
}
const evidence = { schema: 'psc0-library-disclosure-qualification/1', source: process.env.GITHUB_SHA, platform: process.platform, node: process.version, variant, receiptAndCheckedBindingAgree: true, sourceAndManifestRawHashesMatch: true, canonicalAdmissionsUnchanged: true, jsonStdoutPreserved: true, hostStderrDisclosureUnsuppressibleByPackageMetadata: true, packageEntrypointNotExecuted: true, declaredScriptsNotExecutedByCompiler: true, invalidLibraryRefused: true, executableExtensionRequestRefused: true, previousExecutablePreserved: true, fixturesRestored: true, libraryDisclosureSha256: accepted.libraryDisclosure.sha256, compilerRegenerated: false, kernelRegenerated: false, fullFixedPointExecuted: false };
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
await writeFile(path.join(root, 'dist/architecture-evidence/library-' + variant + '.json'), JSON.stringify(evidence, null, 2) + '\n');
console.log('PSC_LIBRARY_INSTALLED: PASS ' + JSON.stringify(evidence));
