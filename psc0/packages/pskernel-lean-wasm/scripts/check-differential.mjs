import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {corpus} from './corpus.mjs';
const [native,launcher]=process.argv.slice(2);
if(!native||!launcher)throw new Error('usage: node check-differential.mjs <native-exe> <wasm-launcher>');
import {runJsonProvider} from './run-provider.mjs';
const run=runJsonProvider;
const nativeHealth=run(native,['--health']);
const wasmHealth=run(process.execPath,[launcher,'--health']);
assert.equal(nativeHealth.status,'ok');
assert.deepEqual(wasmHealth,nativeHealth);
for(const fixture of corpus){
  const nativeResult=run(native,['--check'],fixture.input);
  const wasmResult=run(process.execPath,[launcher,'--check'],fixture.input);
  assert.equal(nativeResult.accepted,fixture.accept,fixture.id+' native');
  assert.equal(wasmResult.accepted,fixture.accept,fixture.id+' Wasm');
  assert.deepEqual(wasmResult,nativeResult,fixture.id+' native/Wasm parity');
  if(fixture.errorKind)assert.equal(wasmResult.errorKind,fixture.errorKind,fixture.id);
  if(fixture.declarationIndex!==undefined)
    assert.equal(wasmResult.declarationIndex,fixture.declarationIndex,fixture.id+' failed index');
  console.log('PSC0_WASM_PARITY PASS '+fixture.id);
}

const root=path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const sha256=f=>createHash('sha256').update(readFileSync(f)).digest('hex');
const sourceCommit=process.env.GITHUB_SHA??process.env.PSC_LEAN_WASM_SOURCE_COMMIT;
if(!sourceCommit||!/^[a-f0-9]{40}$/.test(sourceCommit))
  throw new Error('a concrete checked source commit is required');
const receipt={schemaVersion:2,sourceCommit,cases:corpus.map(c=>c.id),
  corpusSha256:createHash('sha256').update(JSON.stringify(corpus)).digest('hex'),
  wasmSha256:sha256(path.join(root,'wasm/pskernel-lean.wasm')),
  launcherSha256:sha256(launcher),nativeSha256:sha256(native),passed:true};
mkdirSync(path.join(root,'.wasm-build'),{recursive:true});
writeFileSync(path.join(root,'.wasm-build/parity-receipt.json'),
  JSON.stringify(receipt,null,2)+'\n');
console.log('PSC0_WASM_NATIVE_PARITY_QUALIFIED '+receipt.cases.length);
