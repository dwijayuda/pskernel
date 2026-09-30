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
  run('lake', ['exe', 'psc2_backend_js_machine_int_tests']);
  run('lake', ['env', 'lean', 'test/BackendJsJ3Tests.lean']);
  run('lake', ['env', 'lean', 'test/BackendJsJ3NegativeTests.lean']);
  run('lake', ['env', 'lean', '--run', 'test/BackendJsJ3Runtime.lean', out]);
  run('node', ['--check', path.join(out, 'j3.mjs')]);
  const j3 = await import(pathToFileURL(path.join(out, 'j3.mjs')));
  assert.equal(j3.natAdd, 42n);
  assert.equal(j3.natSub, 0n);
  assert.equal(j3.natMul, 42n);
  assert.equal(j3.natDiv, 0n);
  assert.equal(j3.natMod, 9n);
  assert.equal(j3.natEq, true);
  assert.equal(j3.natNe, true);
  assert.equal(j3.natLe, true);
  assert.equal(j3.natLt, true);
  assert.equal(j3.intOfNat, 41n);
  assert.equal(j3.intNegSucc, -3n);
  assert.equal(j3.intNeg, -7n);
  assert.equal(j3.intAdd, 3n);
  assert.equal(j3.intSub, -2n);
  assert.equal(j3.intMul, -12n);
  assert.equal(j3.intEq, true);
  assert.equal(j3.intLe, true);
  assert.equal(j3.intLt, true);
  assert.equal(j3.intRepr, '-42');
  assert.equal(j3.boolNot, false);
  assert.equal(j3.boolAnd, false);
  assert.equal(j3.boolOr, true);
  assert.equal(j3.boolEq, true);
  assert.equal(j3.boolNe, true);
  run('lake', ['exe', 'psc2_backend_js_tests', out]);
  run('node', ['--check', path.join(out, 'direct.mjs')]);
  const direct = await import(pathToFileURL(path.join(out, 'direct.mjs')));
  const {
    identity: directIdentity,
    choose: directChoose,
    callIdentity: directCallIdentity,
    callIdentityLet: directCallIdentityLet,
    callCapturedLambda: directCallCapturedLambda,
    callInlineLambdaArgument: directCallInlineLambdaArgument,
    callSecond: directCallSecond,
    second: directSecond,
    renamedLocal: directRenamedLocal,
    ...directValues
  } = direct;
  assert.deepEqual(directValues, {
    largeNat: 9007199254740993123456789n,
    negativeInt: -9007199254740993123456789n,
    zero: 0n, yes: true, no: false,
    text: 'quote" slash\\ newline\n tab\t 😀 é', empty: '', control: '\0',
    lineSeparators: '\u2028\u2029', nothing: undefined, __psc_js_0: 7n,
    letAlias: 42n, shadowed: 2n,
  });
  assert.equal(directRenamedLocal, 3n);
  assert.equal(directIdentity(37n), 37n);
  assert.equal(directChoose(true), 10n);
  assert.equal(directChoose(false), 20n);
  assert.equal(directCallIdentity(73n), 73n);
  assert.equal(directCallIdentityLet(73n), 73n);
  assert.equal(directCallCapturedLambda(73n), 73n);
  assert.equal(directCallInlineLambdaArgument(73n), 73n);
  assert.equal(directSecond(11n, 73n), 73n);
  assert.equal(directCallSecond(73n), 73n);
  assert.deepEqual(Object.keys(await import(pathToFileURL(path.join(out, 'empty.mjs')))), []);
  run('tsc', [path.join(out, 'reference.ts'), '--target', 'ES2020', '--module', 'ES2020',
    '--outDir', path.join(out, 'reference'), '--strict', '--skipLibCheck']);
  // Explicit ESM extension avoids depending on the enclosing project's package type.
  const { copyFileSync } = await import('node:fs');
  copyFileSync(path.join(out, 'reference/reference.js'), path.join(out, 'reference.mjs'));
  const reference = await import(pathToFileURL(path.join(out, 'reference.mjs')));
  const {
    identity: referenceIdentity,
    choose: referenceChoose,
    callIdentity: referenceCallIdentity,
    callIdentityLet: referenceCallIdentityLet,
    callSecond: referenceCallSecond,
    second: referenceSecond,
    ...referenceValues
  } = reference;
  assert.deepEqual(directValues, referenceValues);
  assert.equal(directIdentity(9007199254740993123456789n),
    referenceIdentity(9007199254740993123456789n));
  assert.equal(directChoose(true), referenceChoose(true));
  assert.equal(directChoose(false), referenceChoose(false));
  assert.equal(directCallIdentity(9007199254740993123456789n),
    referenceCallIdentity(9007199254740993123456789n));
  assert.equal(directCallIdentityLet(9007199254740993123456789n),
    referenceCallIdentityLet(9007199254740993123456789n));
  assert.equal(directSecond(11n, 9007199254740993123456789n),
    referenceSecond(11n, 9007199254740993123456789n));
  assert.equal(directCallSecond(9007199254740993123456789n),
    referenceCallSecond(9007199254740993123456789n));
  console.log('BACKEND_JS_EXECUTION_DIFFERENTIAL: PASS');
} finally {
  rmSync(out, { recursive: true, force: true });
}
