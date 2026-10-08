import assert from 'node:assert/strict';
import {access,readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const differentialPath=path.join(here,'differential.test.mjs');

// Differential parity is part of the Node-WASM acceptance gate, not an
// optional follow-up. The implementation must compare the public native and
// WASM providers on the same canonical admissions payloads.
await access(differentialPath);
const source=await readFile(differentialPath,'utf8');
assert.match(source,/checkCanonicalAdmissions\s+as\s+checkNative/);
assert.match(source,/\.\.\/\.\.\/pskernel-lean\/index\.mjs/);
assert.match(source,/checkCanonicalAdmissions\s+as\s+checkWasm/);
assert.match(source,/\.\.\/index\.mjs/);
assert.match(source,/proofscript-checked-admissions/);
assert.match(source,/kernel-rejection/);
assert.match(source,/malformed/i);
assert.match(source,/PSC2_LEAN_KERNEL_WASM_DIFFERENTIAL: PASS/);

console.log('PSC2_LEAN_KERNEL_WASM_DIFFERENTIAL_CONTRACT: PASS');
