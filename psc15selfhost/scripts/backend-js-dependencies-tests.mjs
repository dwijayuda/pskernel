import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { collectBackendJsClosure } from './backend-js-closure.mjs';

const root = mkdtempSync(path.join(os.tmpdir(), 'psc-js-boundary-'));
function write(relative, contents) {
  const file = path.join(root, relative);
  mkdirSync(path.dirname(file), { recursive: true });
  writeFileSync(file, contents);
}
function manifest(folder, name, dependencies = {}) {
  write(`packages/${folder}/package.json`, JSON.stringify({ name, dependencies,
    proofscript: { portable: true, bootstrap: folder !== 'backend-js' } }));
}
try {
  manifest('backend-js', '@proofscript/backend-js-next', { '@proofscript/compiler-ir-next': '0.0.0-dev' });
  manifest('compiler-ir', '@proofscript/compiler-ir-next');
  write('packages/compiler-ir/src/Ps/CompilerIr/Model.lean', 'def irMarker : Nat := 1\n');
  const entry = 'packages/backend-js/src/Ps/BackendJs/Module.lean';
  write(entry, 'import Ps.CompilerIr.Model\ndef jsMarker : Nat := irMarker\n');
  assert.equal(collectBackendJsClosure(root).length, 2);
  write(entry, 'import Ps.BackendTs.Module\n');
  assert.throws(() => collectBackendJsClosure(root), /JS_SOURCE_DEPENDENCY/);
  write(entry, 'import Lean\n');
  assert.throws(() => collectBackendJsClosure(root), /JS_SOURCE_DEPENDENCY/);
  write(entry, 'import Ps.BackendJs.Module\n');
  assert.throws(() => collectBackendJsClosure(root), /JS_SOURCE_CYCLE/);
  write(entry, 'import Ps.CompilerIr.Model\n');
  manifest('compiler-ir', '@proofscript/compiler-ir-next', { typescript: '5.8.3' });
  assert.throws(() => collectBackendJsClosure(root), /JS_PACKAGE_DEPENDENCY/);
  manifest('compiler-ir', '@proofscript/compiler-ir-next');
  write('packages/backend-js/package.json', JSON.stringify({ name: '@proofscript/backend-js-next',
    proofscript: { portable: true, bootstrap: true } }));
  assert.throws(() => collectBackendJsClosure(root), /JS_BOOTSTRAP_ISOLATION/);
  console.log('BACKEND_JS_DEPENDENCY_TESTS: PASS');
} finally { rmSync(root, { recursive: true, force: true }); }
