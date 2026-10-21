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
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const native=process.env.PSC1_NATIVE||path.join(root,'.lake/build/bin/psc1');
const work=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-compiler-m-'));
const evidence=path.join(root,'dist/scoped-correctness',process.env.PSC1_COMPILERM_EVIDENCE||'compiler-m');
fs.mkdirSync(evidence,{recursive:true});
const contract=JSON.parse(fs.readFileSync(path.join(root,'docs/PSC1_COMPILERM_CASE_CONTRACT.json'),'utf8'));
const targets=(process.env.PSC1_COMPILERM_TARGETS||contract.targets.join(',')).split(',');
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
const leanFixture=read(path.join(root,'test/CompilerMFixtures.lean'));
const nativeAdapter=`
instance {C S E : Type} : Monad (CompilerM C S E) where
  pure := compilerPure
  bind := compilerBind
`;
const oracleSource='import Lean\n'+stripImports(resultLibrary)+'\n'+stripImports(effectLibrary)+'\n'+
 nativeAdapter+'\n'+stripImports(leanFixture)+'\n'+
 'def main : IO Unit := do\n  IO.println (\"PSC1_COMPILERM_ORACLE: \" ++ (Lean.Json.mkObj [("leanVersion",Lean.toJson Lean.versionString),("leanCommit",Lean.toJson Lean.githash),'+
 contract.cases.flatMap(c=>[false,true].map(flag=>'("'+c.id+(flag?'True':'False')+'",Lean.toJson (toString ('+c.id+' '+flag+')))')).join(',')+']).compress)\n';
const oracleFile=path.join(evidence,'CompilerMOracle.lean');write(oracleFile,oracleSource);
const oracleOutput=run('lake',['env','lean','--run',oracleFile]);
write(path.join(evidence,'native-oracle.log'),oracleOutput);
const oracleLines=oracleOutput.split('\n').filter(line=>line.startsWith('PSC1_COMPILERM_ORACLE: '));
assert.equal(oracleLines.length,1);
const oracle=JSON.parse(oracleLines[0].slice('PSC1_COMPILERM_ORACLE: '.length));
assert.equal(oracle.leanVersion,'4.35.0');
assert.equal(oracle.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
write(path.join(evidence,'native-oracle.json'),JSON.stringify(oracle,null,2)+'\n');
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
  const fixture=path.join(root,'test/CompilerMFixtures.'+syntax);
  write(path.join(folder,'CompilerMFixtures.'+syntax),read(fixture));
  // Imported identities remain private to the entry module; distinct wrapper
  // names avoid accidental self-reference and retain individual observations.
  const definitions=contract.cases.map((c,i)=>{
   const no=oracle[c.id+'False'],yes=oracle[c.id+'True'];
   assert.match(no,/^\d+$/);assert.match(yes,/^\d+$/);
   const name='check'+c.id;
   return syntax==='lean'?
    'def '+name+' (flag : Bool) : Bool := Nat.beq ('+c.id+' flag) (if flag then '+yes+' else '+no+')\n':
    'def '+name+'(flag : Bool) : Bool := Nat.beq('+c.id+'(flag), if (flag) { '+yes+' } else { '+no+' })\n';
  });
  const exports=contract.cases.map(c=>'check'+c.id);
  names.splice(0,names.length,...exports,'semantic');
  const combine=exports.map(name=>syntax==='lean'?'('+name+' flag)':'('+name+'(flag))').join(' && ');
  write(path.join(folder,'Entry.'+syntax),'import CompilerMFixtures\n'+definitions.join('\n')+
   (syntax==='lean'?'def semantic (flag : Bool) : Bool := ':'def semantic(flag : Bool) : Bool := ')+combine+'\n');
  const importLine='import ProofScript.Compiler.Effect\n';
  for(const [id,kind]of [['wrong-state','state'],['wrong-error','error']]){
   const action=kind==='state'?'compilerSet':'compilerThrow';
   write(path.join(folder,id+'.'+syntax),importLine+(syntax==='lean'?
    'def invalid : CompilerM Nat Nat Nat Unit := do\n  '+action+' true\n':
    'def invalid : CompilerM(Nat, Nat, Nat, Unit) := do { '+action+'(true) }\n'));
  }
  write(path.join(folder,'duplicate-prelude.'+syntax),'def Nat : Type := Bool\n');
  for(const target of targets){
   const label=syntax+'-'+target,extension={js:'js',ts:'ts',rust:'rs','wasm-core':'wasm','wasm-component':'wasm',python:'py',php:'php'}[target];
   const output=path.join(work,label,'module.'+extension);
   const args=['build',path.join(folder,'Entry.'+syntax),'--target',target,'--out',output];
   try{
    run(native,args);
    const manifest=JSON.parse(read(output+'.bundle.json'));
    assert.equal(manifest.logicalCheckerCommit,oracle.leanCommit);
    assert.equal(manifest.behaviorallyVerified,false);
    assert.equal(manifest.runtimeContract,'psc1-runtime-semantics/1');
    execute(target,output);
    const before=hash(output+'.bundle.json'),published=fs.realpathSync(output+'.bundle.json');
    const refusals={verified:reject([...args,'--assurance','verified'])};
    for(const id of ['wrong-state','wrong-error']){
     const wrong=[...args];wrong[1]=path.join(folder,id+'.'+syntax);refusals[id]=reject(wrong);
    }
    const duplicate=[...args];duplicate[1]=path.join(folder,'duplicate-prelude.'+syntax);
    refusals['duplicate-prelude']=reject(duplicate,/duplicateDeclaration:Nat/);
    assert.equal(hash(output+'.bundle.json'),before);
    assert.equal(fs.realpathSync(output+'.bundle.json'),published);
    const identity={syntax,target,passed:true,admission:'independent-official-Lean',
     strictIr:'required-by-production-publication',runtime:'executed',publicAbi:'Bool-to-Bool-scalars',
     sourceSha256:hash(fixture),entrySha256:hash(args[1]),artifactSha256:hash(output),
     manifestSha256:before,oracleSha256:hash(oracleFile),
     librarySha256:{result:sha(resultLibrary),effect:sha(effectLibrary)},refusals};
    for(const c of contract.cases) records.push({...identity,id:c.id,flags:[false,true],
     expected:{false:oracle[c.id+'False'],true:oracle[c.id+'True']}});
    console.log('PSC1_COMPILERM_TARGET_PASS: '+label);
   }catch(error){failures.push({label,error:error.stack||String(error)});console.error('PSC1_COMPILERM_TARGET_FAIL: '+label+'\n'+error.stack);}
   finally{
    if(fs.existsSync(output+'.bundle.json'))fs.cpSync(path.dirname(fs.realpathSync(output+'.bundle.json')),path.join(evidence,'bundles',label),{recursive:true});
   }
  }
 }
 assert.deepEqual(failures,[]);
 checkLanguageBackendParity(contract,records,{targets});
 console.log('PSC1_COMPILERM_CONFORMANCE: PASS '+records.length+' case/grammar/target obligations');
}finally{
 write(path.join(evidence,'results.json'),JSON.stringify({schema:'psc1-language-backend-execution/1',
  contract:contract.id,testedCommit:process.env.GITHUB_SHA||null,branchHeadCommit:process.env.PSC1_HEAD_SHA||null,
  checkerCommit:oracle.leanCommit,targets,records,failures,passed:failures.length===0&&records.length===contract.cases.length*2*targets.length},null,2)+'\n');
 fs.rmSync(work,{recursive:true,force:true});
}
