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
const historical = spawnSync('git', ['show', '446a0f21c6288a7c20b843bbeadcd18ba1460fa2:psc1/' + originalPath], {cwd: root, encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024});
assert.equal(historical.status, 0, historical.stderr);
assert.equal(historical.stdout,
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

const currentBaseline='7fc146ef50ff5ba28bae033e334c49d1a9cd5637';
const previous=spawnSync('git',['show',currentBaseline+':psc1/'+originalPath],{cwd:root,encoding:'utf8',timeout:10000,maxBuffer:1024*1024});
assert.equal(previous.status,0,previous.stderr);
const begin=previous.stdout.indexOf('def psWasmTypeUsesNatWithFuel');
const end=previous.stdout.indexOf('def psWasmExportsOfDeclarations',begin);
assert.ok(begin>=0&&end>begin);
const moved=previous.stdout.slice(begin,end);
const runtimePath='packages/backend-wasm/src/Ps/BackendWasm/Lower/RuntimeNeeds.lean';
const runtime=fs.readFileSync(path.join(root,runtimePath),'utf8');
assert.deepEqual(runtime.slice(0,runtime.indexOf('def psWasmTypeUsesNatWithFuel')).split('\n').filter(x=>x.startsWith('import ')),['import Ps.CompilerIr.Model','import Ps.Foundation.List']);
assert.equal(runtime.slice(runtime.indexOf('def psWasmTypeUsesNatWithFuel')),moved,'all runtime dependency declarations byte-identical');
assert.equal(fs.readFileSync(path.join(root,originalPath),'utf8'),'import Ps.BackendWasm.Lower.RuntimeNeeds\n'+previous.stdout.replace(moved,''),'all remaining Lower bytes retained');
assert.ok(fs.readFileSync(path.join(root,'lakefile.lean'),'utf8').includes(String.fromCharCode(96)+'Ps.BackendWasm.Lower.RuntimeNeeds,'));
const current={schema:'psc1-runtime-needs-extraction/1',testedCommit:process.env.GITHUB_SHA,baseline:currentBaseline,originalPath,extractedPath:runtimePath,movedDeclarations:[...moved.matchAll(/^def ([^\s{(]+)/gm)].map(m=>m[1]),movedLines:moved.split('\n').length-1,bodies:'byte-identical',remainingDeclarations:'byte-identical',historicalExtraction:'original proof retained against immutable446a0f21',newCompilerGenerationQualification:'separate; packaged G3 unchanged'};
fs.writeFileSync(path.join(out,'runtime-needs.json'),JSON.stringify(current,null,2)+'\n');
console.log('PSC1_RUNTIME_NEEDS_EXTRACTION: PASS '+JSON.stringify(current));

// Third extraction: only the three TypeScript runtime definitions and their comments.
const tsBaseline='b426f9763ed2a576135ed2089671d48e21f1ff32';
const tsPath='packages/backend-ts/src/Ps/BackendTs/Module.lean';
const tsOriginal=spawnSync('git',['show',tsBaseline+':psc1/'+tsPath],{cwd:root,encoding:'utf8',timeout:10000,maxBuffer:1024*1024});
assert.equal(tsOriginal.status,0,tsOriginal.stderr);
const tsBegin=tsOriginal.stdout.indexOf('-- Each recursive call suspends its generator;');
const tsEnd=tsOriginal.stdout.indexOf('-- Eta parameters are already evaluated variables.',tsBegin);
assert.ok(tsBegin>=0&&tsEnd>tsBegin);
const tsMoved=tsOriginal.stdout.slice(tsBegin,tsEnd);
const tsRuntime='packages/backend-ts/src/Ps/BackendTs/RuntimeSupport.lean';
assert.equal(fs.readFileSync(path.join(root,tsRuntime),'utf8'),'import Ps.BackendTs.Type\n\n'+tsMoved);
assert.equal(fs.readFileSync(path.join(root,tsPath),'utf8'),'import Ps.BackendTs.RuntimeSupport\n'+tsOriginal.stdout.replace(tsMoved,''));
assert.deepEqual([...tsMoved.matchAll(/^def (\\S+)/gm)].map(x=>x[1]),['psTsStackRuntimeSupport','psTsUtf8RuntimeSupport','psTsRuntimeSupport']);
assert.ok(fs.readFileSync(path.join(root,'lakefile.lean'),'utf8').includes(String.fromCharCode(96)+'Ps.BackendTs.RuntimeSupport,'));
fs.writeFileSync(path.join(out,'typescript-runtime.json'),JSON.stringify({schema:'psc1-typescript-runtime-extraction/1',testedCommit:process.env.GITHUB_SHA,baseline:tsBaseline,movedDefinitions:3,movedUtf8Bytes:Buffer.byteLength(tsMoved),bodies:'byte-identical',remainingModule:'byte-identical-except-import-and-removal',wholeCompilerPreservation:'not-claimed',newFrozenG3:'not-claimed'},null,2)+'\n');
console.log('PSC1_TYPESCRIPT_RUNTIME_EXTRACTION: PASS');
