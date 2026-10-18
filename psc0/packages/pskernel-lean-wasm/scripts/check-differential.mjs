import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {corpus} from './corpus.mjs';
const [native,launcher]=process.argv.slice(2);
if(!native||!launcher)throw new Error('usage: node check-differential.mjs <native-exe> <wasm-launcher>');
function run(cmd,args,input) {
  const result=spawnSync(cmd,args,{input,encoding:'utf8',maxBuffer:32*1024*1024,timeout:180000});
  if(result.error||result.status!==0)throw new Error('provider process failed: '+cmd+' '+result.stderr);
  try{return JSON.parse(result.stdout.trim());}
  catch{throw new Error('provider returned non-JSON: '+result.stdout.slice(0,500));}
}
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
  console.log('PSC0_WASM_PARITY PASS '+fixture.id);
}

const root=path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const sha256=f=>createHash('sha256').update(readFileSync(f)).digest('hex');
const sourceCommit=process.env.GITHUB_SHA??process.env.PSC_LEAN_WASM_SOURCE_COMMIT;
if(!sourceCommit||!/^[a-f0-9]{40}$/.test(sourceCommit))
  throw new Error('a concrete checked source commit is required');
const receipt={schemaVersion:1,sourceCommit,cases:corpus.map(c=>c.id),
  wasmSha256:sha256(path.join(root,'wasm/pskernel-lean.wasm')),
  launcherSha256:sha256(launcher),nativeSha256:sha256(native),passed:true};
mkdirSync(path.join(root,'.wasm-build'),{recursive:true});
writeFileSync(path.join(root,'.wasm-build/parity-receipt.json'),
  JSON.stringify(receipt,null,2)+'\n');
console.log('PSC0_WASM_NATIVE_PARITY_QUALIFIED '+receipt.cases.length);
