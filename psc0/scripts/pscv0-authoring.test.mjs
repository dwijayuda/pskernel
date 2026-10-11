// The generated candidate, not a JavaScript rewrite of the translation APIs.
import assert from 'node:assert/strict';
import { test, after } from 'node:test';
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const dir=path.join(root,'dist/pscv0-bridge'),authoring=path.join(dir,'authoring');
const prefix=process.env.PSCV0_PREFIX;assert(prefix);
const installed=path.join(prefix,...(process.platform==='win32'?['node_modules']:['lib','node_modules']),'proofscript');
const report=JSON.parse(await readFile(path.join(dir,'build-report.json'),'utf8'));
const receipt=JSON.parse(await readFile(path.join(authoring,'receipt.json'),'utf8'));
const hash=b=>createHash('sha256').update(b).digest('hex');
assert.equal(hash(await readFile(path.join(dir,'index.js'))),report.bridgeJsSha256);
const B=await import(pathToFileURL(path.join(dir,'index.js')).href);
const C=await import(pathToFileURL(path.join(installed,'node_modules/@proofscript/compiler/dist/index.js')).href);
const tag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(k=>o[k]).find(v=>typeof v==='string'):undefined;
const ok=r=>{assert.equal(tag(r),'ok',String(r?.error));return r.value;};
function data(o){
  if(typeof o==='bigint')return {nat:o.toString()};
  if(!o||typeof o!=='object')return o;
  if(Array.isArray(o))return o.map(data);
  return {...Object.fromEntries(Object.entries(o).map(([k,v])=>[k,data(v)])),...(tag(o)?{constructorTag:tag(o)}:{})};
}
let comparisons=0,successes=0,refusals=0;
const earned={selectedSource:false,selfSource:false,errorBranch:false,noFallback:false};
const leanSources=[
  '', 'def answer : Nat := 42\n',
  'def identity (n : Nat) : Nat := n\n',
  'def text : String := "hello λ"\n',
  '-- original comment\ndef answer : Nat := 1\n',
  'structure Pair where\n  left : Nat\n  right : Bool\n',
  'def bad', 'def x : Nat := "unterminated', 'import\n',
];
const psSources=[
  '', 'def answer: Nat := 42\n',
  'function identity(n: Nat): Nat := n\n',
  'const text: String := "hello λ"\n',
  '-- original comment\nconst answer: Nat := 1\n',
  'structure Pair where {\n  left: Nat\n  right: Bool\n}\n',
  'function broken(', 'const x: String := "unterminated', 'import\n',
];
test('candidate compiler module really comes from its authoritative PS source',async()=>{
  const input=report.closure.find(x=>x.module==='Ps.Syntax.Translate');
  assert.equal(input.sourceKind,'pscv0');
  assert.equal(input.path,'packages/syntax/src-ps/Ps/Syntax/Translate.ps');
  assert.equal(input.rawSha256,receipt.sourceSha256);
  assert.equal(report.authoring.selectedPsModules,1);
  assert.equal(report.authoring.noFallback,true);
  assert.equal(report.authoring.directGeneratedSourceAstHandoff,true);
  assert.equal(report.authoring.compilerInput,'generated-v7-pscv0-syntax-module');
  assert.equal(report.authoring.readableLeanProjectionOnly,true);
  assert.equal(receipt.candidateSourceAuthority,'ps');
  for(const [file,digest] of Object.entries(receipt.products))assert.equal(hash(await readFile(path.join(authoring,file))),digest);
  assert.equal(typeof B.psTranslationMapError,'function','candidate helper not generated');
  earned.selectedSource=true;
});
test('newly generated bridge consumes its own selected PS module and preserves both projections',async()=>{
  const source=await readFile(path.join(authoring,'Translate.ps'),'utf8');
  assert.equal(ok(B.psPscv0LowerToLean(true,source)),await readFile(path.join(authoring,'Translate.lowered.lean'),'utf8'));
  const readable=ok(B.psPscv0TranslateReadable(true,false,source));
  assert.equal(readable,await readFile(path.join(authoring,'Translate.lean'),'utf8'));
  assert.equal((readable.match(/:= do\n/g)||[]).length,4);
  const roundtrip=ok(B.psPscv0TranslateReadable(false,true,readable));
  assert.equal(ok(B.psPscv0LowerToLean(true,roundtrip)),ok(B.psPscv0LowerToLean(true,source)));
  earned.selfSource=true;
});
for(const [name,sources] of [
  ['psTranslateLeanToProofScript',leanSources],['psTranslateProofScriptToLean',psSources],
  ['psCanonicalizeLeanSource',leanSources],['psCanonicalizeProofScriptSource',psSources],
])test('generated original/candidate correspondence: '+name,()=>{
  for(const source of sources){
    const expected=C[name](source),actual=B[name](source);
    assert.deepEqual(data(actual),data(expected),name+' on '+JSON.stringify(source));
    comparisons++;if(tag(expected)==='ok')successes++;else refusals++;
  }
});
test('generic error adapter evaluates only the selected branch',()=>{
  let calls=0;
  const wrapped=message=>B.PsTranslationError.print(B.PsSourcePrintError.unsupportedSourceForm(message));
  const wrap=message=>{calls++;return wrapped(message);};
  const success=B.psTranslationMapError(wrap,B.Except.ok(42n));
  assert.equal(success.value,42n);assert.equal(calls,0);
  const failure=B.psTranslationMapError(wrap,B.Except.error('first'));
  assert.deepEqual(data(failure),data(B.Except.error(wrapped('first'))));
  assert.equal(calls,1);earned.errorBranch=true;
});
test('candidate PSCV0 source never falls back to predecessor grammar on failure',()=>{
  const bad='function bad(a: Except String Nat): Except String Nat := do\n  return 1\n';
  const result=B.psPscv0LowerToLean(true,bad);
  assert.equal(tag(result),'error');assert.match(result.error,/BRACES-REQUIRED/);
  const partial=B.psPscv0LowerToLean(true,'partial def bad(n: Nat): Nat := n\n');
  assert.equal(tag(partial),'error');assert.match(partial.error,/PARTIAL-EXCLUDED/);
  earned.noFallback=true;
});
after(async()=>{
  assert.equal(comparisons,36);assert(successes>0&&refusals>0);
  assert(Object.values(earned).every(v=>v),'do not publish a success report for unearned outcomes');
  const result={schema:'psc0-pscv0-authoring-generated-tests/1',source:process.env.GITHUB_SHA,
    platform:process.platform,node:process.version,bridgeJsSha256:report.bridgeJsSha256,
    module:receipt.module,authoritativePsSha256:receipt.sourceSha256,comparisons,successes,refusals,
    selectedPsModules:1,selfSourceReadAndLowered:earned.selfSource,readableLeanRoundTrip:earned.selfSource,
    noFallback:earned.noFallback,kernelRegenerated:false,fullCompilerSelfhost:false};
  await writeFile(path.join(dir,'authoring-tests-'+process.platform+'.json'),JSON.stringify(result,null,2)+'\n');
  console.log('PSCV0_AUTHORING_GENERATED: PASS '+JSON.stringify(result));
});
