import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = mkdtempSync(path.join(os.tmpdir(), 'psc-backend-js-'));
function run(command, args) {
  const result = spawnSync(command, args, { cwd: root, stdio: 'inherit' });
  if (result.error) throw result.error;
  assert.equal(result.status, 0, `${command} failed`);
}
try {
  run('lake', ['exe', 'psc2_backend_js_tests', out]);
  run('node', ['--check', path.join(out, 'direct.mjs')]);
  const direct = await import(pathToFileURL(path.join(out, 'direct.mjs')));
  const { identity: directIdentity, ...directValues } = direct;
  assert.deepEqual(directValues, {
    largeNat: 9007199254740993123456789n,
    negativeInt: -9007199254740993123456789n,
    zero: 0n, yes: true, no: false,
    text: 'quote" slash\\ newline\n tab\t 😀 é', empty: '', control: '\0',
    lineSeparators: '\u2028\u2029', nothing: undefined, __psc_js_0: 7n,
    letAlias: 42n, shadowed: 2n, renamedLocal: 3n,
  });
  assert.equal(directIdentity(37n), 37n);
  assert.deepEqual(Object.keys(await import(pathToFileURL(path.join(out, 'empty.mjs')))), []);
  run('tsc', [path.join(out, 'reference.ts'), '--target', 'ES2020', '--module', 'ES2020',
    '--outDir', path.join(out, 'reference'), '--strict', '--skipLibCheck']);
  // Explicit ESM extension avoids depending on the enclosing project's package type.
  const { copyFileSync } = await import('node:fs');
  copyFileSync(path.join(out, 'reference/reference.js'), path.join(out, 'reference.mjs'));
  const reference = await import(pathToFileURL(path.join(out, 'reference.mjs')));
  const { identity: referenceIdentity, ...referenceValues } = reference;
  assert.deepEqual(directValues, referenceValues);
  assert.equal(directIdentity(9007199254740993123456789n),
    referenceIdentity(9007199254740993123456789n));
  console.log('BACKEND_JS_EXECUTION_DIFFERENTIAL: PASS');
} finally {
  rmSync(out, { recursive: true, force: true });
}
