// Cloud-only qualification gate for generated JS KernelCore.
// Finite observational parity; not formal JS backend preservation.
import assert from 'node:assert/strict';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {checkCanonicalAdmissions as checkReference} from '../packages/pskernel-lean-wasm/index.mjs';
import {checkGeneratedAdmissionsWithPrelude} from '../npm-runtime/generated-core-provider.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const compiler=await import(pathToFileURL(path.join(root,'dist/npm-build/compiler/index.js')).href);
const kernel=await import(pathToFileURL(path.join(root,'dist/npm-build/pskernel-core/index.js')).href);
const prelude=JSON.parse(await readFile(path.join(root,'dist/npm-build/pskernel-core/prelude.json'),'utf8'));
const sha=x=>createHash('sha256').update(x).digest('hex');
const tag=x=>x&&typeof x==='object'?Object.getOwnPropertySymbols(x).map(k=>x[k]).find(v=>typeof v==='string'):undefined;
function unwrap(result,stage){
 const t=tag(result);
 if(t!=='ok')throw Error('PSC_NPM_QUALIFY_'+stage+'_FAILED: '+String(t)+' '+String(result?.error));
 return result.value;
}
const list=values=>values.reduceRight((xs,x)=>compiler.List.cons(x,xs),compiler.List.nil());
function encode(sources,kind='proofScript'){
 const k=kind==='proofScript'?compiler.PsCompilerSourceKind.proofScript:compiler.PsCompilerSourceKind.lean;
 const prepared=unwrap(compiler.psCompilerPrepareSources(k,list(sources)),'PREPARE');
 return unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared),'ADMISSIONS');
}
const cases=[];
async function compare(kind,source,expected){
 const js=checkGeneratedAdmissionsWithPrelude(kernel,source,prelude);
 assert.equal(typeof js.accepted,'boolean');
 let reference;
 try {reference=await checkReference(source,{timeoutMs:60000});}
 catch(err){throw Error('PSC_NPM_REFERENCE_UNAVAILABLE: '+String(err?.message||err));}
 if(js.accepted!==expected||reference.accepted!==expected||js.accepted!==reference.accepted){
   console.error('PSC_NPM_PARITY_DIAGNOSTIC '+JSON.stringify({kind,js,reference,expected}));
   throw Error('PSC_NPM_KERNEL_PARITY: '+kind);
 }
 cases.push({kind,admissionsSha256:sha(source),jsAccepted:js.accepted,leanWasmAccepted:reference.accepted,
  ...(Number.isSafeInteger(js.declarationIndex)?{rejectionIndex:js.declarationIndex}:{})});
}
const empty=JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:[]});
await compare('empty-canonical-admissions',empty,true);
const fixtures=[
 ['nat-constant','def answer : Nat := 42\n','proofScript'],
 ['identity','def same (x : Nat) : Nat := x\n','proofScript'],
 ['lean-constant','def leanAnswer : Nat := 7\n','lean'],
];
for(const [name,source,kind] of fixtures)await compare(name,encode([source],kind),true);
const good=JSON.parse(encode(['def doubleAnswer : Nat := 84\n']));
assert.ok(Array.isArray(good.admissions)&&good.admissions.length>0,'empty positive fixture');
const duplicate=JSON.stringify({...good,admissions:[...good.admissions,...good.admissions]});
await compare('duplicate-declaration-rejected',duplicate,false);
const output=p=>path.join(root,'dist/npm-build',p);
const result={schemaVersion:1,qualifier:'psc0-js-core-observational-parity/1',
 baseMainCommit:'748ee630e43ee1a89643cbc8cec3e31087788b08',
 runnerCommit:process.env.GITHUB_SHA||'unknown',
 kernelJsSha256:sha(await readFile(output('pskernel-core/index.js'))),
 compilerJsSha256:sha(await readFile(output('compiler/index.js'))),
 preludeSha256:sha(await readFile(output('pskernel-core/prelude.json'))),
 comparisonProvider:'pskernel-lean-wasm/Lean-4.34.0',
 cases,note:'Finite conformance, not a formal soundness or consistency proof.'};
await mkdir(output('qualification'),{recursive:true});
await writeFile(output('qualification/js-core-parity.json'),JSON.stringify(result,null,2)+'\n');
console.log('PSC_NPM_JS_CORE_PARITY: PASS '+JSON.stringify({
 cases:cases.length,positive:cases.filter(x=>x.jsAccepted).length,
 negative:cases.filter(x=>!x.jsAccepted).length}));
