import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const dist=path.join(root,'dist/pscv0-bridge');
const prefix=process.env.PSCV0_PREFIX;
assert(prefix,'PSCV0_PREFIX required');
const installed=path.join(prefix,...(process.platform==='win32'?['node_modules']:['lib','node_modules']),'proofscript');
const C=await import(pathToFileURL(path.join(installed,'node_modules/@proofscript/compiler/dist/index.js')).href);
const B=await import(pathToFileURL(path.join(dist,'index.js')).href);
const K=await import(pathToFileURL(path.join(installed,'node_modules/@proofscript/pskernel-core/dist/core-checker.mjs')).href);
const sha=b=>createHash('sha256').update(b).digest('hex');
const report=JSON.parse(await readFile(path.join(dist,'build-report.json'),'utf8'));
assert.equal(sha(await readFile(path.join(dist,'index.js'))),report.bridgeJsSha256);
assert.equal(sha(await readFile(path.join(installed,'node_modules/@proofscript/compiler/dist/index.js'))),report.builderJsSha256);
const tag=x=>x&&typeof x==='object'?Object.getOwnPropertySymbols(x).map(s=>x[s]).find(v=>typeof v==='string'):undefined;
const json=x=>JSON.stringify(x,(_k,v)=>typeof v==='bigint'?v.toString():v);
function ok(r,stage='bridge') { assert.equal(tag(r),'ok',stage+': '+json(r)); return r.value; }
const constant=x=>typeof x==='function'?x():x;
const parse=s=>B.psPscv0ParseSource(true,s);
const lower=s=>ok(B.psPscv0LowerToLean(true,s),'lower '+s);
const lean=s=>ok(B.psPscv0TranslateReadable(true,false,s),'readable Lean');
const prepare=s=>ok(C.psCompilerPrepareSource(C.PsCompilerSourceKind.lean,s),'compiler prepare '+s);
const admissions=s=>ok(C.psCompilerAdmissionsFromPrepared(prepare(s)),'canonical admissions');
const psBody=(name,body,parameters='a: Except String Nat',type='Except String Nat')=>`function ${name}(${parameters}): ${type} := do {\n${body}\n}\n`;
const fixtures=[
  {name:'step',ps:psBody('step','  let x ← a\n  return Nat.succ(x)'),native:'def step (a : Except String Nat) : Except String Nat := do\n  let x ← a\n  return Nat.succ x\n',expanded:'def step (a : Except String Nat) : Except String Nat :=\n  match a with\n  | Except.error pscv0InternalError => Except.error pscv0InternalError\n  | Except.ok x => Except.ok (Nat.succ x)\n'},
  {name:'two',ps:psBody('two','  let x ← a\n  let y ← b\n  return Nat.add(x, y)','a: Except String Nat, b: Except String Nat'),native:'def two (a : Except String Nat) (b : Except String Nat) : Except String Nat := do\n  let x ← a\n  let y ← b\n  return Nat.add x y\n'},
  {name:'localValue',ps:psBody('localValue','  let x ← a\n  let y : Nat := Nat.succ(x)\n  Except.ok(y)')},
  {name:'wildcard',ps:psBody('wildcard','  let _ ← a\n  return 42')},
  {name:'discard',ps:psBody('discard','  a\n  return 42')},
  {name:'finalAction',ps:psBody('finalAction','  a')},
  {name:'hygiene',ps:psBody('hygiene','  let x ← a\n  return pscv0InternalError','pscv0InternalError: Nat, a: Except String Nat')},
  {name:'asciiBind',ps:psBody('asciiBind','  let x <- a\n  return x')},
  {name:'strings',ps:psBody('strings','  return "do; -- λ"','a: Except String Nat','Except String String')},
  {name:'shadowLet',ps:psBody('shadowLet','  let x ← a\n  let x : Nat := Nat.succ(x)\n  return x')},
];
test('bridge is generated portable PSCV0 candidate, not a relabeled legacy runtime',()=>{
  assert.equal(constant(B.psPscv0LanguageEdition),'pscv0');
  assert.equal(constant(B.psPscv0SurfaceCapability),'declaration-except-do/1');
  assert.equal(constant(B.psPscv0FullConformance),false);
  assert.equal(constant(B.psPscv0ReferenceSha256),'843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5');
  assert.equal(report.referenceSha256,'843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5');
  assert.equal(report.builder,'retained self-hosted JavaScript PSC0 compiler');
  assert.equal(report.existingCompilerSourceFilesUnchanged,69);
  assert.equal(report.newInstalledFixedPoint,false);
});
for(const fixture of fixtures)test('source intent and semantic round trip: '+fixture.name,()=>{
  const s=ok(parse(fixture.ps));
  assert.equal(B.psPscv0ReplayOriginal(s),fixture.ps);
  const native=lean(fixture.ps);
  assert.match(native,/:= do\n/);
  assert.doesNotMatch(native,/match a with/,'high-level intent erased during source printing');
  const regenerated=ok(B.psPscv0TranslateReadable(false,true,native));
  assert.match(regenerated,/do \{/);
  assert.equal(admissions(lower(fixture.ps)),admissions(lower(regenerated)));
  if(fixture.native)assert.equal(admissions(lower(fixture.ps)),admissions(ok(B.psPscv0LowerToLean(false,fixture.native))));
  if(fixture.expanded)assert.equal(admissions(lower(fixture.ps)),admissions(fixture.expanded));
});
const negatives=[
  ['missing braces','function f(a: Except String Nat): Except String Nat := do\n  return 1\n','BRACES-REQUIRED'],
  ['empty do',psBody('f',''),'DO-EMPTY'],
  ['dangling bind',psBody('f','  let x ← a'),'MISSING-FINAL-ACTION'],
  ['dangling let',psBody('f','  let x := 1'),'MISSING-FINAL-ACTION'],
  ['nonterminal return',psBody('f','  return 1\n  return 2'),'NONTERMINAL-RETURN'],
  ['same-line semicolons',psBody('f','  let x ← a; return x'),'NEWLINE-REQUIRED'],
  ['mutation',psBody('f','  let mut x := 1\n  return x'),'MUTATION'],
  ['loop',psBody('f','  while true { a }\n  return 1'),'UNSUPPORTED'],
  ['throw',psBody('f','  throw "e"'),'UNSUPPORTED'],
  ['nested do',psBody('f','  let x ← do { return 1 }\n  return x'),'NESTING'],
  ['nested return',psBody('f','  if (true) { return 1 } else { a }'),'NESTED-RETURN'],
  ['different effect',psBody('f','  return 1','a: Nat','Id Nat'),'EXPLICIT-EXCEPT'],
  ['effect shadow',psBody('f','  let Except := 1\n  return 1'),'EFFECT-SHADOW'],
  ['binder effect shadow',psBody('f','  return 1','Except: Type','Except String Nat'),'EFFECT-SHADOW'],
  ['gap call',psBody('f','  let x ← a\n  return Nat.succ (x)'),'PSCV0-APP-02'],
  ['comment gap',psBody('f','  let x ← a\n  return Nat.succ /- gap -/ (x)'),'PSCV0-APP-02'],
  ['empty call not implemented',psBody('f','  return Nat.zero()'),'APP-03'],
  ['partial excluded','partial def bad(a: Nat): Nat := a\n','PARTIAL-EXCLUDED'],
  ['unclosed group',psBody('f','  return Nat.succ((1)'),'DELIMITER'],
  ['mismatched group',psBody('f','  return Nat.succ(1]'),'DELIMITER'],
  ['nested body position','function f(a: Except String Nat): Except String Nat := { do { return 1 } }\n','DECLARATION-BODY-ONLY'],
];
for(const [name,source,code] of negatives)test('refuse '+name,()=>{
  const result=parse(source);assert.equal(tag(result),'error',name+' unexpectedly parsed');assert.match(result.error,new RegExp(code));
});
test('comments are retained verbatim, never silently discarded by canonical printing',()=>{
  const source='-- important documentation\n'+fixtures[0].ps;
  const surface=ok(parse(source));
  assert.equal(B.psPscv0ReplayOriginal(surface),source);
  assert.equal(surface.commentTrivia,true);
  const formatted=B.psPscv0PrintSurfaceModule(false,surface);
  assert.equal(tag(formatted),'error');assert.equal(formatted.error,'PSCV0-TRIVIA-PRINT-PENDING');
  assert.equal(admissions(lower(source)),admissions(lower(fixtures[0].ps)));
});
test('BOM and nested comment delimiters in string literals are not dropped source trivia',()=>{
  const source='\ufeff'+fixtures.find(x=>x.name==='strings').ps;
  const surface=ok(parse(source));
  assert.equal(B.psPscv0ReplayOriginal(surface),source);
  assert.equal(surface.commentTrivia,false);
  ok(B.psPscv0PrintSurfaceModule(false,surface));
});
test('parameterless const remains a value, never a new Unit-parameter function',()=>{
  const source='const constant: Except String Nat := do {\n  return 42\n}\n';
  assert.match(lean(source),/^def constant : Except/);
  assert.equal(admissions(lower(source)),admissions('def constant : Except String Nat := Except.ok 42\n'));
});
test('wrong returned value and incompatible action error types are rejected by the actual compiler',()=>{
  for(const source of [psBody('bad','  return "wrong"'),psBody('bad','  let x ← a\n  return x','a: Except Nat Nat')]){
    const result=C.psCompilerPrepareSource(C.PsCompilerSourceKind.lean,lower(source));
    assert.equal(tag(result),'error','ill-typed lowering was accepted');
  }
});
test('input budget is a refusal, not success with truncated source',()=>{
  const result=parse(' '.repeat(1048577));assert.equal(tag(result),'error');assert.equal(result.error,'PSCV0-SOURCE-BYTE-BUDGET');
});
test('generated bridge output compiles, selected kernel admits fixtures, and runtime sequencing is correct',async()=>{
  const joined=fixtures.map(f=>lower(f.ps)).join('\n');
  const prepared=prepare(joined);
  const stream=ok(C.psCompilerAdmissionsFromPrepared(prepared));
  const decision=K.checkCanonicalAdmissions(stream,{timeoutMs:120000});
  assert.equal(decision.accepted,true,json(decision));
  const ts=ok(C.psCompilerTypeScriptFromPrepared(prepared));
  const dir=path.join(dist,'runtime-tests-'+process.platform);await mkdir(dir,{recursive:true});
  await writeFile(path.join(dir,'index.ts'),ts);await writeFile(path.join(dir,'package.json'),'{"type":"module"}\n');
  const req=createRequire(path.join(installed,'package.json'));
  const metaFile=req.resolve('typescript/package.json'),meta=JSON.parse(await readFile(metaFile,'utf8'));
  assert.equal(meta.version,'7.0.2');
  const cli=path.join(path.dirname(metaFile),typeof meta.bin==='string'?meta.bin:meta.bin.tsc);
  const r=spawnSync(process.execPath,[cli,'--ignoreConfig',path.join(dir,'index.ts'),'--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'],{encoding:'utf8',timeout:120000,maxBuffer:4*1024*1024});
  assert(!r.error&&r.status===0,String(r.error||r.stderr||r.stdout));
  const F=await import(pathToFileURL(path.join(dir,'index.js')).href);
  const good=F.Except.ok(10n),bad=F.Except.error('first'),bad2=F.Except.error('second');
  assert.equal(F.step(good).value,11n);assert.equal(F.step(bad).error,'first');
  assert.equal(F.two(good,F.Except.ok(20n)).value,30n);
  assert.equal(F.two(bad,bad2).error,'first');assert.equal(F.two(good,bad2).error,'second');
  assert.equal(F.localValue(good).value,11n);assert.equal(F.shadowLet(good).value,11n);
  assert.equal(F.hygiene(99n,good).value,99n);assert.equal(F.hygiene(99n,bad).error,'first');
  assert.equal(F.wildcard(good).value,42n);assert.equal(F.discard(bad).error,'first');
  assert.equal(F.asciiBind(good).value,10n);assert.equal(F.strings(good).value,'do; -- λ');
  const summary={source:process.env.GITHUB_SHA,platform:process.platform,node:process.version,bridgeJsSha256:report.bridgeJsSha256,fixtureAdmissionSha256:sha(stream),kernelProvider:decision.provider,fixtureKernelAdmitted:true,fixtureCount:fixtures.length,firstErrorAndValueBehavior:true,fullSelfhostCycleExecuted:false};
  await writeFile(path.join(dist,'runtime-report-'+process.platform+'.json'),JSON.stringify(summary,null,2)+'\n');
  // Preserve the actual generated functions and equality statement. The native
  // lane established that explicit constructor cases close this proof; symbolic
  // rfl alone is not a requirement of semantic correspondence.
  const reference=fixtures[1].ps.replace('function two(','function referenceProgram(');
  const lowered=fixtures[1].ps.replace('function two(','function loweredProgram(');
  const proof=lean(reference)+'\n'+lower(lowered)+'\ntheorem pscv0_do_correspondence (a b : Except String Nat) :\n    referenceProgram a b = loweredProgram a b := by\n  cases a <;> cases b <;> rfl\n\n#print axioms pscv0_do_correspondence\n';
  await writeFile(path.join(dist,'reference.lean'),proof);
  console.log('PSCV0_BRIDGE_RUNTIME: PASS '+JSON.stringify(summary));
});
