// Migration-specific correspondence: movement is allowed; algorithm edits are not.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const baseline = '3089cbc369bc8a11f540c13140c7003c9dadf4a8';
const originalPath = 'packages/backend-wasm/src/Ps/BackendWasm/Lower.lean';
const extractedPath = 'packages/backend-wasm/src/Ps/BackendWasm/Lower/TypeInventory.lean';
const original = spawnSync('git', ['show', baseline + ':psc1/' + originalPath], {
  cwd: root, encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024,
});
assert.equal(original.status, 0, original.stderr);
function section(start, stop) {
  const begin = original.stdout.indexOf(start);
  const end = original.stdout.indexOf(stop, begin);
  assert.ok(begin >= 0 && end > begin, 'baseline extraction boundaries');
  return original.stdout.slice(begin, end);
}
const fold = section('def psWasmListFoldlWorker', 'def psWasmListPair?');
const inventory = section('def psWasmFunctionTypeListContains', 'def psWasmLowerArrayType');
const extracted = fs.readFileSync(path.join(root, extractedPath), 'utf8');
const bodyStart = extracted.indexOf('def psWasmListFoldlWorker');
assert.ok(bodyStart > 0, 'module header required');
const imports = extracted.slice(0, bodyStart).split('\n').filter(line => line.startsWith('import '));
assert.deepEqual(imports, ['import Ps.BackendWasm.Type', 'import Ps.Foundation.List']);
assert.equal(extracted.slice(bodyStart), fold + inventory, 'all moved declaration bytes retained');
assert.equal(fs.readFileSync(path.join(root, originalPath), 'utf8'),
  'import Ps.BackendWasm.Lower.TypeInventory\n' +
  original.stdout.replace(fold, '').replace(inventory, ''),
  'all remaining Lower declarations and imports retained');
assert.ok(fs.readFileSync(path.join(root, 'lakefile.lean'), 'utf8')
  .includes(String.fromCharCode(96) + 'Ps.BackendWasm.Lower.TypeInventory,'), 'explicit Lake root required');
const names = [...(fold + inventory).matchAll(/^def ([^\s{(]+)/gm)].map(match => match[1]);
assert.equal(names.length, 27);
const out = path.join(root, 'dist/readability');
fs.mkdirSync(out, {recursive: true});
const receipt = {
  schema: 'psc1-readability-module-extraction/1',
  commit: process.env.GITHUB_SHA,
  baseline, originalPath, extractedPath,
  movedDeclarations: names,
  movedLines: (fold + inventory).split('\n').length - 1,
  declarationBodies: 'byte-identical-to-baseline',
  remainingDeclarations: 'byte-identical-to-baseline',
  formalCompilerPreservation: 'not-claimed',
  frozenGeneratedPayloadQualification: 'unchanged-original-identities',
};
fs.writeFileSync(path.join(out, 'module.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_READABILITY_MODULE: PASS ' + JSON.stringify(receipt));
