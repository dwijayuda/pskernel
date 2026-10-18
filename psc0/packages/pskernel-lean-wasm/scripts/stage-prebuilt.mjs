import {createHash} from 'node:crypto';
import {readFile,writeFile} from 'node:fs/promises';
import {corpus} from './corpus.mjs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const file=relative=>path.join(root,relative);
const commit=process.env.GITHUB_SHA??process.env.PSC_LEAN_WASM_SOURCE_COMMIT;
if(!commit||!/^[a-f0-9]{40}$/.test(commit))throw new Error('source commit required');
const receipt=JSON.parse(await readFile(file('.wasm-build/parity-receipt.json'),'utf8'));
const expectedCases=corpus.map(c=>c.id);
const expectedCorpusSha256=createHash('sha256').update(JSON.stringify(corpus)).digest('hex');
if(corpus.length<11 || receipt.schemaVersion!==2||receipt.sourceCommit!==commit||
   receipt.passed!==true || receipt.corpusSha256!==expectedCorpusSha256 ||
   JSON.stringify(receipt.cases)!==JSON.stringify(expectedCases))
  throw new Error('missing matching native-vs-Wasm kernel parity evidence');
const assets={};
for(const name of ['wasm/pskernel-lean.cjs','wasm/pskernel-lean.wasm']){
  const bytes=await readFile(file(name));
  if(!bytes.length)throw new Error('empty compiler artifact: '+name);
  assets[name]={path:name,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')};
}
if(receipt.wasmSha256!==assets['wasm/pskernel-lean.wasm'].sha256 ||
   receipt.launcherSha256!==assets['wasm/pskernel-lean.cjs'].sha256)
  throw new Error('kernel binary changed since native-vs-Wasm parity');
const wasm=await readFile(file('wasm/pskernel-lean.wasm'));
if(wasm.subarray(0,4).toString('hex')!=='0061736d')throw new Error('not wasm');
const module=new WebAssembly.Module(wasm);
if(!WebAssembly.Module.exports(module).some(e=>e.kind==='memory') &&
   !WebAssembly.Module.imports(module).some(e=>e.kind==='memory'))
  throw new Error('expected linear-memory Wasm');
const manifest={
 schemaVersion:1,packageName:'@proofscript/pskernel-lean-wasm',
 protocol:'pskernel-lean-wasm/2',provider:'lean4-cpp',profile:'pscv0-v7.2',
 leanVersion:'4.35.0',leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
 emscriptenVersion:'6.0.9',memoryModel:'linear',qualified:true,
 qualificationTier:'admission-smoke',productionReady:false,
 parityCases:expectedCases,corpusSha256:expectedCorpusSha256,
 sourceCommit:commit,
 assurance:'kernel-runtime-native-wasm-differential-smoke; NOT an independent soundness proof',
 assets,
};

await writeFile(file('PREBUILT_WASM_MANIFEST.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('PSC0_WASM_PREBUILT_STAGED '+assets['wasm/pskernel-lean.wasm'].bytes);
