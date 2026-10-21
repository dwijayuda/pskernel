// Authored .lean/.ps fixtures; native Lean reference evaluates the exact checked
// effect library using native Monad syntax. No target acts as another's oracle.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { checkLanguageBackendParity } from './check-language-backend-parity.mjs';
const suite=process.argv[2]||'--compiler-m';
assert.ok(['--compiler-m','--stdlib-collections','--json-application','--inference-control','--typed-io-protocol','--typed-io-sequencing','--checked-order','--library-application'].includes(suite));
const libraryApplication=suite==='--library-application';
const checkedOrder=suite==='--checked-order';
const ioSequencing=suite==='--typed-io-sequencing';
const ioProtocol=suite==='--typed-io-protocol';
const inferenceControl=suite==='--inference-control';
const collections=suite==='--stdlib-collections';
const jsonApplication=suite==='--json-application';
const fixtureName=libraryApplication?'LibraryApplication':checkedOrder?'OrderFixtures':ioSequencing?'TypedIoSequencingFixtures':ioProtocol?'TypedIoProtocolFixtures':inferenceControl?'InferenceControlFixtures':jsonApplication?'JsonRecordApplication':collections?'StdlibCollectionFixtures':'CompilerMFixtures';
const contractFile=libraryApplication?'PSC1_LIBRARY_APPLICATION_CASE_CONTRACT.json':checkedOrder?'PSC1_ORDER_CASE_CONTRACT.json':ioSequencing?'PSC1_TYPED_IO_SEQUENCING_CASE_CONTRACT.json':ioProtocol?'PSC1_TYPED_IO_PROTOCOL_CASE_CONTRACT.json':inferenceControl?'PSC1_INFERENCE_CONTROL_CASE_CONTRACT.json':jsonApplication?'PSC1_JSON_APPLICATION_CASE_CONTRACT.json':collections?'PSC1_STDLIB_COLLECTION_CASE_CONTRACT.json':'PSC1_COMPILERM_CASE_CONTRACT.json';
const evidenceName=libraryApplication?(process.env.PSC1_LIBRARY_EVIDENCE||'library-application'):checkedOrder?(process.env.PSC1_ORDER_EVIDENCE||'checked-order'):ioSequencing?(process.env.PSC1_IO_SEQUENCING_EVIDENCE||'typed-io-sequencing'):ioProtocol?(process.env.PSC1_IO_PROTOCOL_EVIDENCE||'typed-io-protocol'):inferenceControl?(process.env.PSC1_INFERENCE_EVIDENCE||'inference-control'):jsonApplication?(process.env.PSC1_JSON_EVIDENCE||'json-application'):collections?(process.env.PSC1_COLLECTION_EVIDENCE||'stdlib-collections'):(process.env.PSC1_COMPILERM_EVIDENCE||'compiler-m');
const targetSelection=libraryApplication?process.env.PSC1_LIBRARY_TARGETS:checkedOrder?process.env.PSC1_ORDER_TARGETS:ioSequencing?process.env.PSC1_IO_SEQUENCING_TARGETS:ioProtocol?process.env.PSC1_IO_PROTOCOL_TARGETS:inferenceControl?process.env.PSC1_INFERENCE_TARGETS:jsonApplication?process.env.PSC1_JSON_TARGETS:collections?process.env.PSC1_COLLECTION_TARGETS:process.env.PSC1_COMPILERM_TARGETS;
const marker=libraryApplication?'PSC1_LIBRARY_APPLICATION':checkedOrder?'PSC1_CHECKED_ORDER':ioSequencing?'PSC1_TYPED_IO_SEQUENCING':ioProtocol?'PSC1_TYPED_IO_PROTOCOL':inferenceControl?'PSC1_INFERENCE_CONTROL':jsonApplication?'PSC1_JSON_APPLICATION':collections?'PSC1_COLLECTION':'PSC1_COMPILERM';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const native=process.env.PSC1_NATIVE||path.join(root,'.lake/build/bin/psc1');
const work=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-compiler-m-'));
const evidence=path.join(root,'dist/scoped-correctness',evidenceName);
fs.mkdirSync(evidence,{recursive:true});
const contract=JSON.parse(fs.readFileSync(path.join(root,'docs',contractFile),'utf8'));
const targets=(targetSelection||contract.targets.join(',')).split(',');
assert.equal(new Set(targets).size,targets.length);
assert.ok(targets.length&&targets.every(t=>contract.targets.includes(t)));
const names=[...contract.cases.map(c=>c.id),'semantic'];
const records=[],failures=[];
const env={...process.env,PSC1_HOST_TOOLS:path.join(root,'host-tools/artifacts.mjs')};
const read=file=>fs.readFileSync(file,'utf8');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const hash=file=>sha(fs.readFileSync(file));
function write(file,text){fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,text);}
function run(cmd,args,options={}){
 const deadline=options.timeout??120000;
 const result=spawnSync('timeout',['--kill-after=5s',Math.ceil(deadline/1000)+'s',cmd,...args],
  {env,encoding:'utf8',cwd:root,maxBuffer:32*1024*1024,...options,timeout:deadline+10000});
 assert.equal(result.error,undefined,result.error?.message);
 assert.equal(result.status,0,cmd+' '+args.join(' ')+'\n'+result.stdout+result.stderr);
 return result.stdout;
}
function reject(args,expected){
 const r=spawnSync(native,args,{env,encoding:'utf8',cwd:root,timeout:60000});
 assert.equal(r.error,undefined);assert.equal(r.signal,null);assert.notEqual(r.status,0);
 assert.match(r.stdout+r.stderr,/PSC1_|PSC2_/);
 if(expected)assert.match(r.stdout+r.stderr,expected);
 return sha(r.stdout+r.stderr);
}
write(path.join(work,'package.json'),'{"type":"module"}\n');
const stripImports=text=>text.split('\n').filter(line=>!line.startsWith('import ')).join('\n');
const resultLibrary=read(path.join(root,'stdlib/ProofScript/Data/Result.lean'));
const effectLibrary=read(path.join(root,'stdlib/ProofScript/Compiler/Effect.lean'));
const extraLibraries={option:read(path.join(root,'stdlib/ProofScript/Data/Option.lean')),
 prod:read(path.join(root,'stdlib/ProofScript/Data/Prod.lean')),
 list:read(path.join(root,'stdlib/ProofScript/Data/List.lean')),
 array:read(path.join(root,'stdlib/ProofScript/Data/Array.lean'))};
const jsonLibraries=(jsonApplication||ioProtocol||ioSequencing)?{ordering:read(path.join(root,'stdlib/ProofScript/Data/Ordering.lean')),json:read(path.join(root,'stdlib/ProofScript/Data/Json.lean'))}:{};
if(ioProtocol||ioSequencing)jsonLibraries.io=read(path.join(root,'stdlib/ProofScript/System/IO.lean'));
const librarySha256=Object.fromEntries(Object.entries({...extraLibraries,...jsonLibraries,result:resultLibrary,effect:effectLibrary}).map(([key,value])=>[key,sha(value)]));
const leanFixture=read(path.join(root,'test',fixtureName+'.lean'));
const nativeAdapter=`
instance {C S E : Type} : Monad (CompilerM C S E) where
  pure := compilerPure
  bind := compilerBind
instance {C S E : Type} : MonadExceptOf E (CompilerM C S E) where
  throw := compilerThrow
  tryCatch := compilerTryCatch
`;
const oracleSource=libraryApplication?read(path.join(root,'test/LibraryApplicationReference.lean')):ioSequencing?read(path.join(root,'test/TypedIoSequencingReference.lean')):ioProtocol?read(path.join(root,'test/TypedIoProtocolReference.lean')):jsonApplication?read(path.join(root,'test/JsonRecordReference.lean')):'import Lean\n'+Object.values(extraLibraries).map(stripImports).join('\n')+'\n'+stripImports(resultLibrary)+'\n'+stripImports(effectLibrary)+'\n'+Object.values(jsonLibraries).map(stripImports).join('\n')+'\n'+
 nativeAdapter+'\n'+stripImports(leanFixture)+'\n'+
 'def main : IO Unit := do\n  IO.println (\"PSC1_COMPILERM_ORACLE: \" ++ (Lean.Json.mkObj [("leanVersion",Lean.toJson Lean.versionString),("leanCommit",Lean.toJson Lean.githash),'+
 contract.cases.flatMap(c=>[false,true].map(flag=>'("'+c.id+(flag?'True':'False')+'",Lean.toJson (toString ('+c.id+' '+flag+')))')).join(',')+']).compress)\n';
const oracleFile=path.join(evidence,'PracticalOracle.lean');write(oracleFile,oracleSource);
const oracleOutput=run('lake',['env','lean','--run',oracleFile]);
write(path.join(evidence,'native-oracle.log'),oracleOutput);
const oracleLines=oracleOutput.split('\n').filter(line=>line.startsWith('PSC1_COMPILERM_ORACLE: '));
assert.equal(oracleLines.length,1);
const oracle=JSON.parse(oracleLines[0].slice('PSC1_COMPILERM_ORACLE: '.length));
assert.equal(oracle.leanVersion,'4.35.0');
assert.equal(oracle.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
write(path.join(evidence,'native-oracle.json'),JSON.stringify(oracle,null,2)+'\n');
let independentReferenceSha256=libraryApplication?sha(read(path.join(root,'test/LibraryApplicationReference.lean'))):null;
if(collections){
 const referenceFile=path.join(root,'test/StandardCollectionReference.lean');
 const referenceSource=read(referenceFile);
 // Run in a separate native process importing only Lean, never PSC1 helper bodies.
 const referenceOutput=run('lake',['env','lean','--run',referenceFile]);
 write(path.join(evidence,'standard-reference.lean'),referenceSource);
 write(path.join(evidence,'standard-reference.log'),referenceOutput);
 const lines=referenceOutput.split('\n').filter(line=>line.startsWith('PSC1_STANDARD_COLLECTION_REFERENCE: '));
 assert.equal(lines.length,1);
 const reference=JSON.parse(lines[0].slice('PSC1_STANDARD_COLLECTION_REFERENCE: '.length));
 assert.equal(reference.leanVersion,oracle.leanVersion);
 assert.equal(reference.leanCommit,oracle.leanCommit);
 for(const c of contract.cases)for(const flag of ['False','True'])
  assert.equal(oracle[c.id+flag],reference[c.id+flag],'stdlib helper differs from native standard operation: '+c.id+flag);
 independentReferenceSha256=sha(referenceSource);
 console.log('PSC1_COLLECTION_STANDARD_REFERENCE: PASS six independent native comparisons');
}
function execute(target, output) {
  if (target === 'js' || target === 'ts') {
    let js = output;
    if (target === 'ts') {
      assert.ok(process.env.PSC1_TSC, 'independent pinned TypeScript compiler required');
      const out = path.join(path.dirname(output), 'consumer');
      run(process.execPath, [process.env.PSC1_TSC, '--ignoreConfig', '--strict', '--target', 'ES2022',
        '--module', 'ESNext', '--moduleResolution', 'Bundler', '--outDir', out, fs.realpathSync(output)]);
      write(path.join(out, 'package.json'), '{"type":"module"}\n');
      js = path.join(out, 'module.js');
    }
    run(process.execPath, ['--input-type=module', '-e',
      'import assert from "node:assert/strict"; const m=await import(' + JSON.stringify(pathToFileURL(fs.realpathSync(js)).href) +
      '); assert.deepEqual(Object.keys(m).sort(),'+JSON.stringify([...names].sort())+'); for(const name of Object.keys(m)){assert.equal(m[name](false),true,name); assert.equal(m[name](true),true,name);}']);
  } else if (target === 'rust') {
    const crate = path.join(path.dirname(output), 'consumer');
    fs.cpSync(fs.realpathSync(output.replace(/\.rs$/, '.cargo')), crate, { recursive: true, dereference: true });
    write(path.join(crate, 'tests/typed_errors.rs'),
      '#[test] fn compiler_effect_contract() { '+names.map(name=>'assert!(psc1_generated::'+name+'(false)); assert!(psc1_generated::'+name+'(true));').join(' ')+' }\n');
    run('cargo', ['test', '--locked', '--manifest-path', path.join(crate, 'Cargo.toml')],
      { env: { ...env, CARGO_TARGET_DIR: path.join(work, 'cargo-target') } });
  } else if (target === 'wasm-core') {
    run(process.execPath, ['--input-type=module', '-e',
      'import fs from "node:fs"; import assert from "node:assert/strict"; const {instance}=await WebAssembly.instantiate(fs.readFileSync(' +
      JSON.stringify(output) + ')); assert.deepEqual(Object.keys(instance.exports).sort(),'+JSON.stringify([...names].sort())+'); for(const name of Object.keys(instance.exports)){assert.equal(instance.exports[name](0),1,name); assert.equal(instance.exports[name](1),1,name);}']);
  } else if (target === 'wasm-component') {
    for (const name of names) for (const flag of ['false','true']) {
      assert.equal(run('wasmtime', ['run', '--invoke', name+'(' + flag + ')', output]).trim(), 'true');
    }
  } else if (target === 'python') {
    run(process.env.PSC1_PYTHON || 'python3', ['-I', '-c',
      'import importlib.util,sys\ns=importlib.util.spec_from_file_location("typed_errors",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)\nassert sorted(m.__all__)=='+JSON.stringify([...names].sort())+'\nfor name in m.__all__:\n f=getattr(m,name);assert f(False) is True,name;assert f(True) is True,name\n', output]);
  } else {
    run(process.env.PSC1_PHP || 'php', ['-d', 'memory_limit=1G', '-r',
      '$m=require $argv[1]; $keys=array_keys($m);sort($keys);if($keys!==json_decode('+JSON.stringify(JSON.stringify([...names].sort()))+',true))exit(1); foreach($m as $name=>$f){if($f(false)!==true || $f(true)!==true){fwrite(STDERR,$name);exit(1);}}', output]);
  }
}

try {
 for(const syntax of contract.grammars){
  const folder=path.join(evidence,'sources',syntax);
  const fixture=path.join(root,'test/'+fixtureName+'.'+syntax);
  write(path.join(folder,fixtureName+'.'+syntax),read(fixture));
  if(ioProtocol||ioSequencing)write(path.join(folder,'ProofScript/System/IO.'+syntax),read(path.join(root,'stdlib/ProofScript/System/IO.'+syntax)));
  // Imported identities remain private to the entry module; distinct wrapper
  // names avoid accidental self-reference and retain individual observations.
  const applicationModuleSha256={};
  if(jsonApplication||libraryApplication){
   for(const module of contract.requiredModules){
    const relative=module+'.'+syntax,source=read(path.join(root,'test/applications',relative));
    write(path.join(folder,relative),source);applicationModuleSha256[relative]=sha(source);
   }
  }
  const definitions=contract.cases.map((c,i)=>{
   const no=oracle[c.id+'False'],yes=oracle[c.id+'True'];
   assert.match(no,/^\d+$/);assert.match(yes,/^\d+$/);
   const name='check'+c.id.toLowerCase();
   return syntax==='lean'?
    'def '+name+' (flag : Bool) : Bool := Nat.beq ('+c.id+' flag) (if flag then '+yes+' else '+no+')\n':
    'def '+name+'(flag : Bool) : Bool := Nat.beq('+c.id+'(flag), if (flag) { '+yes+' } else { '+no+' })\n';
  });
  const exports=contract.cases.map(c=>'check'+c.id.toLowerCase());
  names.splice(0,names.length,...exports,'semantic');
  const combine=exports.map(name=>syntax==='lean'?'('+name+' flag)':'('+name+'(flag))').join(' && ');
  write(path.join(folder,'Entry.'+syntax),'import '+fixtureName+'\n'+definitions.join('\n')+
   (syntax==='lean'?'def semantic (flag : Bool) : Bool := ':'def semantic(flag : Bool) : Bool := ')+combine+'\n');
  const negativeCases=libraryApplication?[
  {
    "id": "wrong-input",
    "lean": "import PracticalLibrary.Transform\ndef invalid : Array Nat := libraryTransform true\n",
    "ps": "import PracticalLibrary.Transform\ndef invalid : Array(Nat) := libraryTransform(true)\n"
  },
  {
    "id": "missing-module",
    "lean": "import PracticalLibrary.Missing\ndef invalid : Bool := true\n",
    "ps": "import PracticalLibrary.Missing\ndef invalid : Bool := true\n"
  },
  {
    "id": "duplicate-module",
    "lean": "import PracticalLibrary.Input\ndef libraryInput : Bool := true\n",
    "ps": "import PracticalLibrary.Input\ndef libraryInput : Bool := true\n"
  }
]:checkedOrder?[
{"id":"mixed-domain","lean":"def invalid (a : Nat) (b : Int) : Prop := a < b\n","ps":"def invalid(a : Nat, b : Int) : Prop := a < b\n"},
{"id":"bool-order","lean":"def invalid : Prop := true < false\n","ps":"def invalid : Prop := true < false\n"},
{"id":"prop-as-bool","lean":"def invalid : Bool := 1 < 2\n","ps":"def invalid : Bool := 1 < 2\n"},
{"id":"chained","lean":"def invalid : Prop := 1 < 2 < 3\n","ps":"def invalid : Prop := 1 < 2 < 3\n"},
{"id":"mixed-arithmetic","lean":"def invalid (a : Nat) (b : Int) : Nat := a + b\n","ps":"def invalid(a : Nat, b : Int) : Nat := a + b\n"},
{"id":"mixed-equality","lean":"def invalid (a : Nat) (b : Int) : Bool := a == b\n","ps":"def invalid(a : Nat, b : Int) : Bool := a == b\n"},
{"id":"bool-arithmetic","lean":"def invalid : Bool := true + false\n","ps":"def invalid : Bool := true + false\n"}]:ioSequencing?[
  {
    "id": "wrong-path",
    "lean": "import ProofScript.System.IO\ndef invalid : Io String := ioReadUtf8 true\n",
    "ps": "import ProofScript.System.IO\ndef invalid : Io(String) := ioReadUtf8(true)\n"
  },
  {
    "id": "wrong-result",
    "lean": "import ProofScript.System.IO\ndef invalid : Io Nat := do\n  let text : String <- ioReadUtf8 \"x\"\n  return text\n",
    "ps": "import ProofScript.System.IO\ndef invalid : Io(Nat) := do { let text : String <- ioReadUtf8(\"x\")\n return text }\n"
  },
  {
    "id": "wrong-effect",
    "lean": "import ProofScript.System.IO\ndef invalid : Id String := do\n  ioReadUtf8 \"x\"\n",
    "ps": "import ProofScript.System.IO\ndef invalid : Id(String) := do { ioReadUtf8(\"x\") }\n"
  }
]:ioProtocol?[
  {
    "id": "wrong-path",
    "lean": "import ProofScript.System.IO\ndef invalid : IoRequest := IoRequest.readUtf8 true\n",
    "ps": "import ProofScript.System.IO\ndef invalid : IoRequest := IoRequest.readUtf8(true)\n"
  },
  {
    "id": "wrong-payload",
    "lean": "import ProofScript.System.IO\ndef invalid : Result Nat IoError := ioReadTextResult \"{}\"\n",
    "ps": "import ProofScript.System.IO\ndef invalid : Result(Nat, IoError) := ioReadTextResult(\"{}\")\n"
  }
]:inferenceControl?[
{"id":"wrong-state","lean":"import ProofScript.Compiler.Effect\ndef invalid : CompilerM Nat Nat Nat Unit := do\n  compilerSet true\n","ps":"import ProofScript.Compiler.Effect\ndef invalid : CompilerM(Nat, Nat, Nat, Unit) := do { compilerSet(true) }\n"},
{"id":"wrong-error","lean":"import ProofScript.Compiler.Effect\ndef invalid : CompilerM Nat Nat Nat Unit := do\n  compilerThrow true\n","ps":"import ProofScript.Compiler.Effect\ndef invalid : CompilerM(Nat, Nat, Nat, Unit) := do { compilerThrow(true) }\n"},
{"id":"wrong-return","lean":"def invalid : Id Nat := do\n  if true then return false\n  return 7\n","ps":"def invalid : Id(Nat) := do {\n if (true) { return false }\n return 7\n}\n"},
{"id":"shadow-mutable","lean":"def invalid : Id Nat := do\n  let mut value : Nat := 1\n  if true then\n    let value : Nat := 2\n    value := 3\n  return value\n","ps":"def invalid : Id(Nat) := do {\n let mut value : Nat := 1\n if (true) {\n  let value : Nat := 2\n  value := 3\n }\n return value\n}\n"},
{"id":"nested-assignment","lean":"def invalid : Id Nat := do\n  let mut value : Nat := 1\n  let inner : Nat <- (do\n    value := 2\n    return value\n  )\n  return inner\n","ps":"def invalid : Id(Nat) := do {\n let mut value : Nat := 1\n let inner : Nat <- (do {\n  value := 2\n  return value\n })\n return inner\n}\n"},
{"id":"escaping-handler","lean":"def invalid : Except Nat Nat := do\n  try\n    throw 1\n  catch error =>\n    pure ()\n  return error\n","ps":"def invalid : Except(Nat, Nat) := do {\n try { throw 1 } catch error => { pure(()) }\n return error\n}\n"},
{"id":"wrong-handler-result","lean":"def invalid : Except Nat Nat := do\n  try\n    throw 1\n  catch error =>\n    return true\n","ps":"def invalid : Except(Nat, Nat) := do {\n try { throw 1 } catch error => { return true }\n}\n"},
{"id":"malformed-handler","lean":"def invalid : Except Nat Nat := do\n  try\n    throw 1\n  catch =>\n    return 2\n","ps":"def invalid : Except(Nat, Nat) := do {\n try { throw 1 } catch => { return 2 }\n}\n"},
{"id":"wrong-arity","lean":"import InferenceControlFixtures\ndef invalid : Nat := boundedAfter 0 true 1\n","ps":"import InferenceControlFixtures\ndef invalid : Nat := boundedAfter(0, true, 1)\n"},
{"id":"ambiguous-call","lean":"import InferenceControlFixtures\ndef invalid : Nat := let ignored := boundedId #[]; 1\n","ps":"import InferenceControlFixtures\ndef invalid : Nat := let ignored := boundedId(#[])\n 1\n"},
{"id":"wrong-unit","lean":"import InferenceControlFixtures\ndef invalid : Nat := boundedUnit true\n","ps":"import InferenceControlFixtures\ndef invalid : Nat := boundedUnit(true)\n"},
{"id":"empty-unit-call","lean":"import InferenceControlFixtures\ndef invalid : Nat := boundedUnit()\n","ps":"import InferenceControlFixtures\ndef invalid : Nat := boundedUnit()\n"},
   {id:'wrong-context',lean:'import InferenceControlFixtures\ndef invalid : Int := boundedId true\n',
    ps:'import InferenceControlFixtures\ndef invalid : Int := boundedId(true)\n'},
   {id:'ambiguous-array',lean:'def invalid : Nat := let values := #[]; 1\n',
    ps:'def invalid : Nat := let values := #[]\n 1\n'},
   {id:'dependent-type',lean:'import InferenceControlFixtures\ndef invalid : Int := boundedDependent Nat true 1\n',
    ps:'import InferenceControlFixtures\ndef invalid : Int := boundedDependent(Nat, true, 1)\n'},
   {id:'unresolved-lambda',lean:'def invalid : Nat := let f := fun value => value; 1\n',
    ps:'def invalid : Nat := let f := fun value => value\n 1\n'},
   {id:'escaping-local',lean:'def invalid : Id Nat := do\n  if true then\n    let hidden : Nat := 1\n    pure ()\n  return hidden\n',
    ps:'def invalid : Id(Nat) := do {\n if (true) { let hidden : Nat := 1\n pure(()) }\n return hidden\n}\n'},
   {id:'type-changing',lean:'def invalid : Id Nat := do\n  let mut value : Nat := 1\n  value := true\n  return value\n',
    ps:'def invalid : Id(Nat) := do {\n let mut value : Nat := 1\n value := true\n return value\n}\n'}
  ]:jsonApplication?[
   {id:'wrong-record-type',lean:'import JsonRecords.Transform\ndef invalid : Result Nat JsonError := recordCode true\n',
    ps:'import JsonRecords.Transform\ndef invalid : Result(Nat, JsonError) := recordCode(true)\n'},
   {id:'wrong-record-list',lean:'import JsonRecords.Transform\ndef invalid : Result Nat JsonError := sumRecordCodes [true]\n',
    ps:'import JsonRecords.Transform\ndef invalid : Result(Nat, JsonError) := sumRecordCodes([true])\n'}
  ]:collections?[
   {id:'wrong-element',lean:'def invalid : List Nat := [true]\n',ps:'def invalid : List(Nat) := [true]\n'},
   {id:'wrong-index',lean:'def invalid : Option Nat := let values : Array Nat := #[1]; values[true]?\n',
    ps:'def invalid : Option(Nat) := let values : Array(Nat) := #[1]\n values[true]?\n'}
  ]:[
   {id:'wrong-state',lean:'import ProofScript.Compiler.Effect\ndef invalid : CompilerM Nat Nat Nat Unit := do\n  compilerSet true\n',
    ps:'import ProofScript.Compiler.Effect\ndef invalid : CompilerM(Nat, Nat, Nat, Unit) := do { compilerSet(true) }\n'},
   {id:'wrong-error',lean:'import ProofScript.Compiler.Effect\ndef invalid : CompilerM Nat Nat Nat Unit := do\n  compilerThrow true\n',
    ps:'import ProofScript.Compiler.Effect\ndef invalid : CompilerM(Nat, Nat, Nat, Unit) := do { compilerThrow(true) }\n'}
  ];
  for(const item of negativeCases)write(path.join(folder,item.id+'.'+syntax),item[syntax]);
  write(path.join(folder,'duplicate-prelude.'+syntax),'def Nat : Type := Bool\n');
  for(const target of targets){
   const label=syntax+'-'+target,extension={js:'js',ts:'ts',rust:'rs','wasm-core':'wasm','wasm-component':'wasm',python:'py',php:'php'}[target];
   const output=path.join(work,label,'module.'+extension);
   const args=['build',path.join(folder,'Entry.'+syntax),'--target',target,'--out',output];
   if(checkedOrder||jsonApplication||ioProtocol||ioSequencing)args.push('--assurance','ordinary');
   if(target==='wasm-component')args.push('--exports',names.join(','));
   try{
    run(native,args);
    const manifest=JSON.parse(read(output+'.bundle.json'));
    assert.equal(manifest.logicalCheckerCommit,oracle.leanCommit);
    assert.equal(manifest.behaviorallyVerified,false);
    assert.equal(manifest.runtimeContract,'psc1-runtime-semantics/1');
    execute(target,output);
    const before=hash(output+'.bundle.json'),published=fs.realpathSync(output+'.bundle.json');
    const verifiedArgs=[...args],assuranceIndex=verifiedArgs.indexOf('--assurance');
    if(assuranceIndex<0)verifiedArgs.push('--assurance','verified');
    else verifiedArgs[assuranceIndex+1]='verified';
    const refusals={verified:reject(verifiedArgs)};
    for(const {id} of negativeCases){
     const wrong=[...args];wrong[1]=path.join(folder,id+'.'+syntax);refusals[id]=reject(wrong,inferenceControl&&id==='malformed-handler'?/PSC1_PROJECT_PARSE_FAILED/:inferenceControl&&id==='empty-unit-call'?/PSC1_PROJECT_(PARSE|ELAB)_FAILED/:checkedOrder&&id==='chained'?/PSC1_PROJECT_PARSE_FAILED:.*parentheses around nonassociative comparison/:libraryApplication&&id==='missing-module'?/PSC1_PROJECT_.*(IMPORT|MODULE|SOURCE)/:/PSC1_PROJECT_ELAB_FAILED/);
    }
    const duplicate=[...args];duplicate[1]=path.join(folder,'duplicate-prelude.'+syntax);
    refusals['duplicate-prelude']=reject(duplicate,/duplicateDeclaration:Nat/);
    if(target==='wasm-component'){
     for(const selection of [names[0]+','+names[0],'not-in-entry',...(libraryApplication?['libraryInput','libraryTransform']:[]),'']){
      const malformed=[...args];malformed[malformed.length-1]=selection;
      reject(malformed,/PSC1_COMPONENT_EXPORT/);
     }
    }
    assert.equal(hash(output+'.bundle.json'),before);
    assert.equal(fs.realpathSync(output+'.bundle.json'),published);
    const identity={syntax,target,passed:true,admission:'independent-official-Lean',
     strictIr:'required-by-production-publication',runtime:'executed',publicAbi:'Bool-to-Bool-scalars',
     sourceSha256:hash(fixture),entrySha256:hash(args[1]),artifactSha256:hash(output),
     manifestSha256:before,oracleSha256:hash(oracleFile),
     librarySha256,refusals,...(libraryApplication?{applicationBoundaryChecks:contract.applicationBoundaryChecks}:{}),...((jsonApplication||libraryApplication)?{applicationModuleSha256}:{}),...((collections||libraryApplication)?{independentReferenceSha256,referenceComparison:'native-standard-operations'}:{})};
    for(const c of contract.cases) records.push({...identity,id:c.id,flags:[false,true],
     expected:{false:oracle[c.id+'False'],true:oracle[c.id+'True']}});
    console.log(marker+'_TARGET_PASS: '+label);
   }catch(error){failures.push({label,error:error.stack||String(error)});console.error(marker+'_TARGET_FAIL: '+label+'\n'+error.stack);}
   finally{
    if(fs.existsSync(output+'.bundle.json'))fs.cpSync(path.dirname(fs.realpathSync(output+'.bundle.json')),path.join(evidence,'bundles',label),{recursive:true});
   }
  }
 }
 assert.deepEqual(failures,[]);
 checkLanguageBackendParity(contract,records,{targets});
 console.log(marker+'_CONFORMANCE: PASS '+records.length+' case/grammar/target obligations');
}finally{
 write(path.join(evidence,'results.json'),JSON.stringify({schema:'psc1-language-backend-execution/1',
  contract:contract.id,testedCommit:process.env.GITHUB_SHA||null,branchHeadCommit:process.env.PSC1_HEAD_SHA||null,
  checkerCommit:oracle.leanCommit,targets,records,failures,passed:failures.length===0&&records.length===contract.cases.length*2*targets.length},null,2)+'\n');
 fs.rmSync(work,{recursive:true,force:true});
}
