// Cheap compiler-only second-module candidate conformance.
// Compares canonical compiler admissions and TS7 emission for the exact old Lean
// source and the new PSCV0 v7 .ps authoring of Ps.Foundation.List.
// Neither side invokes the independent kernel checker; this is NOT a release.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { transferPscv0Ast } from './transport.mjs';
const root=process.cwd(),artifact=path.resolve(process.argv[2]||''),
  installed=path.resolve(process.argv[3]||'');
assert(process.argv[2]&&process.argv[3],'Pass same qualified cached frontend and compiler toolchain as the fast lane');
const hash=b=>createHash('sha256').update(b).digest('hex');
const B=await import(pathToFileURL(path.join(artifact,'bootstrap','index.js')).href);
const C=await import(pathToFileURL(path.join(installed,'node_modules/@proofscript/compiler/dist/index.js')).href);
const tag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(s=>o[s]).find(v=>typeof v==='string'):undefined;
const ok=(v,label)=>{if(tag(v)!=='ok')throw Error(label+': '+String(v?.error??tag(v)));return v.value};
const baselinePath=path.join(root,'packages/foundation/src/Ps/Foundation/List.lean'),
  candidatePath=path.join(root,'packages/foundation/src-ps/Ps/Foundation/List.ps');
const oldSource=await readFile(baselinePath,'utf8'),source=await readFile(candidatePath,'utf8');
const parseStart=performance.now();
const oldModule=ok(C.psCompilerParseSource(C.PsCompilerSourceKind.lean,oldSource),'baseline List.lean parser');
const psSurface=ok(B.psPscv0ParseSource(true,source),'v7 candidate List.ps parser');
const newModule=transferPscv0Ast(B,C,ok(B.psPscv0LowerModule(psSurface),'v7 candidate source lowering'),source);
const parseMs=Math.round(performance.now()-parseStart);
const compile=(module,label)=>{
 const state=C.psCompilerPreparationStart(C.PsCompilerSourceKind.lean);
 const stepped=ok(C.psCompilerPreparationStepParsedWithOrigins(state,module),label+' actual elaboration');
 const prepared=ok(C.psCompilerPreparationFinish(stepped.state),label+' compiler finish');
 return {admissions:ok(C.psCompilerAdmissionsFromPrepared(prepared),label+' canonical admissions'),
   target:ok(C.psCompilerTypeScriptFromPrepared(prepared),label+' TypeScript emitter')};
};
const t=performance.now();
const old=compile(oldModule,'original Lean foundation compiler module');
const changed=compile(newModule.module,'v7 ProofScript-authored foundation compiler module');
const compileMs=Math.round(performance.now()-t);
const mismatch=(left,right)=>{
 if(left===right)return null;
 let i=0;while(i<left.length&&i<right.length&&left[i]===right[i])i++;
 return {at:i,old:left.slice(Math.max(0,i-100),i+200),
   v7:right.slice(Math.max(0,i-100),i+200),oldLength:left.length,newLength:right.length};
};
const admissionMismatch=mismatch(old.admissions,changed.admissions);
const targetMismatch=mismatch(old.target,changed.target);
const report={
 schema:'psc0-v7-second-module-compiler-differential/1',
 module:'Ps.Foundation.List',oldSourceSha256:hash(oldSource),
 candidateSourceSha256:hash(source),
 candidatePhysicalLines:source.split('\n').length-1,
 baselinePhysicalLines:oldSource.split('\n').length-1,
 candidateTransportedNodes:newModule.receipt.normalizedNodes,
 originalAdmissionsSha256:hash(old.admissions),candidateAdmissionsSha256:hash(changed.admissions),
 originalTypeScriptSha256:hash(old.target),candidateTypeScriptSha256:hash(changed.target),
 admissionsByteIdentical:admissionMismatch===null,
 emittedTypeScriptByteIdentical:targetMismatch===null,
 admissionDifference:admissionMismatch,targetDifference:targetMismatch,
 parseMs,compilerMs:compileMs,
 independentKernelCheckExecuted:false,newFullSelfhostFixedPoint:false
};
const out=path.join(root,'dist/pscv0-compiler-fast');
await mkdir(out,{recursive:true});
await writeFile(path.join(out,'foundation-list-differential.json'),JSON.stringify(report,null,2)+'\n');
console.log('PSCV0_SECOND_MODULE_DIFFERENTIAL: '+JSON.stringify(report));
if(admissionMismatch||targetMismatch)
 throw Error('Second compiler module is not yet strictly identical to its existing source: review the model/typed AST difference, not test output');
console.log('PSCV0_SECOND_MODULE_COMPILER: PASS source v7 List.ps corresponds to original Lean compiler admissions and TS7 output');
