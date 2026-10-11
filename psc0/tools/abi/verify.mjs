// Cloud-only proof-of-interop: use the exact failed run's generated PSCV0
// bootstrap and immutable retained compiler. No full compiler generation here.
import assert from 'node:assert/strict';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { transferPscv0Ast, AST_ABI_VERSION } from './transport.mjs';
const root=process.argv[2],installed=process.argv[3];
assert(root&&installed,'missing ABI probe artifact/installed retained package');
const files=await readdir(path.join(root,'bootstrap'));
assert(files.includes('index.js'),'failed run artifact missing generated source');
const B=await import(pathToFileURL(path.join(root,'bootstrap','index.js')).href);
const C=await import(pathToFileURL(path.join(installed,'node_modules/@proofscript/compiler/dist/index.js')).href);
const K=await import(pathToFileURL(path.join(installed,'node_modules/@proofscript/pskernel-core/dist/core-checker.mjs')).href);
function tag(v){
 if(v===null||typeof v!=='object')return undefined;
 return Object.getOwnPropertySymbols(v).map(s=>v[s]).find(x=>typeof x==='string');
}
const get=(v,what)=>{
 if(tag(v)!=='ok')throw Error(what+': '+String(v?.error??tag(v)));
 return v.value;
};
const source='function add(x: Nat, y: Nat): Nat := Nat.add(x, y)\n'+
  'const grouped: Nat := (add(1))(2)\n';
const parsed=get(B.psPscv0ParseSource(true,source),'v7 PS source parser');
const ast=get(B.psPscv0LowerModule(parsed),'v7 PS AST lowering');
assert.throws(()=>C.psCompilerPreparationStepParsedWithOrigins(
  C.psCompilerPreparationStart(C.PsCompilerSourceKind.lean),ast),
  /invalid ProofScript constructor tag/,
  'foreign source AST must be refused at the receiving compiler ABI');
const result=transferPscv0Ast(B,C,ast,source);
assert.equal(result.receipt.schema,AST_ABI_VERSION);
assert(result.receipt.normalizedNodes>15,'not a valid complete source tree');
const state=C.psCompilerPreparationStart(C.PsCompilerSourceKind.lean);
const stepped=get(C.psCompilerPreparationStepParsedWithOrigins(state,result.module),
  'recipient-owned v7 AST elaboration');
const prepared=get(C.psCompilerPreparationFinish(stepped.state),'compiler admission preparation');
const stream=get(C.psCompilerAdmissionsFromPrepared(prepared),'canonical checked admissions');
const decision=K.checkCanonicalAdmissions(stream,{timeoutMs:120000});
assert.equal(decision.accepted,true,'independent kernel denied syntax AST admissions: '+JSON.stringify(decision));
const typeScript=get(C.psCompilerTypeScriptFromPrepared(prepared),'checked TS7 emission');
assert(typeScript.includes('grouped'),'checked compiled result missing grouped declaration');
// Negative: a bundled C List does not carry B's private List tag.
const switched={...ast,imports:C.List.nil()};
assert.throws(()=>transferPscv0Ast(B,C,switched,source),/PSCV0_AST_ABI_INVALID/);
// Negative: closed source field schema refuses extra keys even with right tags.
const malformed={...ast,untrustedField:true};
assert.throws(()=>transferPscv0Ast(B,C,malformed,source),/PSCV0_AST_ABI_INVALID/);
// Negative: constructor identity is not inferred from Symbol descriptions.
const fake={...ast,declarations:{[Symbol('ProofScript.List.tag')]:'nil'}};
assert.throws(()=>transferPscv0Ast(B,C,fake,source),/PSCV0_AST_ABI_INVALID/);
// Qualify the *real* selected 40-line v7 compiler module using the same
// generated bootstrap AST, without assuming its imports exist in the tiny
// standalone checker environment used above.
const selectedText=await readFile(path.join('packages','syntax','src-ps','Ps','Syntax','Translate.ps'),'utf8');
const selectedSha=createHash('sha256').update(selectedText).digest('hex');
assert.equal(selectedSha,'938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428',
  'selected compiler module changed without updating the source identity');
const selectedParsed=get(B.psPscv0ParseSource(true,selectedText),'selected v7 compiler module');
const selectedLowered=get(B.psPscv0LowerModule(selectedParsed),'selected v7 module source AST');
const selectedTransport=transferPscv0Ast(B,C,selectedLowered,selectedText);
assert(selectedTransport.receipt.normalizedNodes>result.receipt.normalizedNodes,
  'selected module must have a larger real source AST than the two-declaration fixture');
assert.equal(selectedTransport.receipt.sourceSha256,selectedSha);
console.log('PSCV0_AST_ABI_SELECTED_COMPILER_SOURCE: PASS '+JSON.stringify({
  module:'Ps.Syntax.Translate',sourceSha256:selectedSha,
  schema:AST_ABI_VERSION,validatedNodes:selectedTransport.receipt.normalizedNodes,
  noLeanTextParse:true,noKernelBypass:true
}));
const evidence={schema:AST_ABI_VERSION,
  source:result.receipt.sourceSha256,nodes:result.receipt.normalizedNodes,
  compiler:'retained PSC0',sourceRuntime:'generated PSCV0 bootstrap',
  tagReconstruction:'recipient-owned factories',nativeTextParserUsed:false,
  checkedTypeScriptEmitted:true,
  kernelAdmission:decision.accepted,provider:decision.provider,
  fullV7Conformance:false,newSelfhostFixedPoint:false};
console.log('PSCV0_AST_ABI_DIRECT_CHECKED: PASS '+JSON.stringify(evidence));
