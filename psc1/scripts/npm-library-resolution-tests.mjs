import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { resolveImportedSource } from '../npm-cli/libraries.mjs';
const workspace = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const pin = JSON.parse(fs.readFileSync(path.join(workspace, 'NATIVE_SOURCE_PIN.json'), 'utf8'));
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-library-contract-'));
const write = (file, value) => { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, value); };
const json = value => JSON.stringify(value, null, 2) + '\n';
function library(prefix) {
  return { schemaVersion: 2, kind: 'portable-source', modulePrefix: prefix, sourceRoot: 'src', sourceKind: 'ps',
    publicModules: [prefix + '.Public'], compilerProfile: pin.compilerProfile, leanVersion: pin.version, leanCommit: pin.commit };
}
const projectMeta = { name: 'psc1-resolution-test', private: true,
  dependencies: { '@psc1-test/lib': '1.0.0' }, proofscript: { libraries: { Demo: '@psc1-test/lib' } } };
const projectFile = path.join(root, 'package.json');
write(projectFile, json(projectMeta));
const entry = path.join(root, 'src/Main.ps'); write(entry, 'def answer : Nat := 0\n');
const packageRoot = path.join(root, 'node_modules/@psc1-test/lib');
const packageFile = path.join(packageRoot, 'package.json');
const pkg = { name: '@psc1-test/lib', version: '1.0.0', exports: { '.': './guest.mjs', './package.json': './package.json' },
  proofscript: { library: library('Demo') } };
write(packageFile, json(pkg));
write(path.join(packageRoot, 'guest.mjs'), 'throw new Error("package JavaScript must never execute");\n');
const publicSource = path.join(packageRoot, 'src/Demo/Public.ps');
const privateSource = path.join(packageRoot, 'src/Demo/Private.ps');
write(publicSource, 'def publicValue : Nat := 1\n'); write(privateSource, 'def privateValue : Nat := 2\n');
let groups = 0;
try {
  assert.equal(await resolveImportedSource('Demo.Public', path.dirname(entry), entry), fs.realpathSync(publicSource)); groups++;
  await assert.rejects(resolveImportedSource('Demo.Private', path.dirname(entry), entry), /PRIVATE_MODULE/); groups++;
  assert.equal(await resolveImportedSource('Demo.Private', path.dirname(entry), publicSource), fs.realpathSync(privateSource)); groups++;
  await assert.rejects(resolveImportedSource('Ps.Core.Expr', path.dirname(entry), publicSource), /RESERVED_MODULE/); groups++;
  const changed = structuredClone(pkg); changed.proofscript.library.leanCommit = '0'.repeat(40);
  write(packageFile, json(changed));
  await assert.rejects(resolveImportedSource('Demo.Public', path.dirname(entry), entry), /PROFILE_MISMATCH/); groups++;
  write(packageFile, json(pkg));
  const outside = path.join(root, 'Outside.ps'); write(outside, 'def escaped : Nat := 3\n');
  fs.rmSync(publicSource); fs.symlinkSync(outside, publicSource);
  await assert.rejects(resolveImportedSource('Demo.Public', path.dirname(entry), entry), /SOURCE_ESCAPE/); groups++;
  fs.rmSync(publicSource); write(publicSource, 'def publicValue : Nat := 1\n');
  const undeclared = structuredClone(projectMeta); undeclared.dependencies = {};
  write(projectFile, json(undeclared));
  await assert.rejects(resolveImportedSource('Demo.Public', path.dirname(entry), entry), /UNDECLARED_DEPENDENCY/); groups++;
  write(projectFile, json(projectMeta));
  const wrongIdentity = structuredClone(pkg); wrongIdentity.name = '@psc1-test/other';
  write(packageFile, json(wrongIdentity));
  await assert.rejects(resolveImportedSource('Demo.Public', path.dirname(entry), entry), /PACKAGE_IDENTITY/); groups++;
  write(packageFile, json(pkg));
  const authority = structuredClone(pkg); authority.proofscript.library.axioms = ['False'];
  write(packageFile, json(authority));
  await assert.rejects(resolveImportedSource('Demo.Public', path.dirname(entry), entry), /UNSUPPORTED_AUTHORITY/); groups++;
  write(packageFile, json(pkg));
  // The importing package selects its own installed dependency version.
  const dependent = structuredClone(pkg);
  dependent.dependencies = { '@psc1-test/dep': '2.0.0' };
  dependent.proofscript.libraries = { Other: '@psc1-test/dep' };
  write(packageFile, json(dependent));
  for (const [location, version] of [[root, '1.0.0'], [packageRoot, '2.0.0']]) {
    const dir = path.join(location, 'node_modules/@psc1-test/dep');
    write(path.join(dir, 'package.json'), json({ name: '@psc1-test/dep', version,
      exports: { './package.json': './package.json' }, proofscript: { library: library('Other') } }));
    write(path.join(dir, 'src/Other/Public.ps'), 'def dependencyValue : Nat := ' + version[0] + '\n');
  }
  assert.equal(await resolveImportedSource('Other.Public', path.dirname(entry), publicSource),
    fs.realpathSync(path.join(packageRoot, 'node_modules/@psc1-test/dep/src/Other/Public.ps'))); groups++;
  console.log('PSC1_NPM_LIBRARY_RESOLUTION: PASS ' + groups + ' host boundary groups');
} finally { fs.rmSync(root, { recursive: true, force: true }); }
