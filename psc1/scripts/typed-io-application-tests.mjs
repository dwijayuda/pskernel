import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {withTypedIo} from '../host-tools/typed-io.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const evidence=path.join(root,'dist/scoped-correctness/typed-io');
const work=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-typed-io-app-'));
fs.mkdirSync(evidence,{recursive:true});
const native=process.env.PSC1_NATIVE||path.join(root,'.lake/build/bin/psc1');
const env={...process.env,PSC1_HOST_TOOLS:path.join(root,'host-tools/artifacts.mjs')};
const sha=value=>crypto.createHash('sha256').update(value).digest('hex');
const hash=file=>sha(fs.readFileSync(file));
const read=relative=>fs.readFileSync(path.join(root,relative),'utf8');
const records=[],failures=[];
const payload='{"text":"A😀\\nZ"}',sourceResponse=JSON.stringify({kind:'text',text:payload});
const expectedText='{"text":"processed:A😀\\nZ"}';
function write(file,text){fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,text);}
function run(command,args,options={}){
 const result=spawnSync('timeout',['--kill-after=5s','120s',command,...args],
  {cwd:root,env,encoding:'utf8',timeout:130000,maxBuffer:32*1024*1024,...options});
 assert.equal(result.error,undefined,result.error?.message);
 assert.equal(result.status,0,command+' '+args.join(' ')+'\n'+result.stdout+result.stderr);
 return result.stdout;
}
const oracleSource=read('test/TypedIoApplicationReference.lean');
const oracleFile=path.join(evidence,'NativeTypedIo.lean');write(oracleFile,oracleSource);
const nativeOutput=run('lake',['env','lean','--run',oracleFile]);
write(path.join(evidence,'native-oracle.log'),nativeOutput);
const lines=nativeOutput.split('\n').filter(l=>l.startsWith('PSC1_TYPED_IO_ORACLE: '));
assert.equal(lines.length,1);const oracle=JSON.parse(lines[0].slice('PSC1_TYPED_IO_ORACLE: '.length));
assert.equal(oracle.version,'4.35.0');assert.equal(oracle.commit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
assert.deepEqual(JSON.parse(oracle.begin),{op:'readUtf8',path:'input.json'});
assert.deepEqual(JSON.parse(oracle.next),{op:'writeUtf8',path:'output.json',text:expectedText});
assert.equal(oracle.finish,true);
write(path.join(evidence,'native-oracle.json'),JSON.stringify(oracle,null,2)+'\n');
for(const syntax of ['lean','ps'])for(const target of ['js','ts','rust']){
 const label=syntax+'-'+target,folder=path.join(work,label);
 const source=path.join(folder,'source/Program.'+syntax);
 write(source,read('test/applications/TypedIo/Program.'+syntax));
 write(path.join(folder,'source/ProofScript/System/IO.'+syntax),read('stdlib/ProofScript/System/IO.'+syntax));
 const output=path.join(folder,'module.'+{js:'js',ts:'ts',rust:'rs'}[target]);
 try{
  run(native,['build',source,'--target',target,'--assurance','ordinary','--out',output]);
  const manifest=JSON.parse(fs.readFileSync(output+'.bundle.json','utf8'));
  assert.equal(manifest.logicalCheckerCommit,oracle.commit);
  assert.equal(manifest.behaviorallyVerified,false);
  assert.equal(manifest.runtimeContract,'psc1-runtime-semantics/1');
  const generationHash=hash(output+'.bundle.json');
  let load;
  if(target==='js'||target==='ts'){
   let module=output;
   if(target==='ts'){
    assert.ok(process.env.PSC1_TSC);
    const consumer=path.join(folder,'consumer');
    run(process.execPath,[process.env.PSC1_TSC,'--ignoreConfig','--strict','--target','ES2022','--module','ESNext','--moduleResolution','Bundler','--outDir',consumer,fs.realpathSync(output)]);
    write(path.join(consumer,'package.json'),'{"type":"module"}\n');
    module=path.join(consumer,'module.js');
   }
   load=()=>import(pathToFileURL(fs.realpathSync(module)).href);
  }else{
   const crate=path.join(folder,'consumer');
   fs.cpSync(fs.realpathSync(output.replace(/\.rs$/,'.cargo')),crate,{recursive:true,dereference:true});
   write(path.join(crate,'src/bin/io-consumer.rs'),[
    'fn main() {',
    ' let a: Vec<String> = std::env::args().collect();',
    ' let result = match a[1].as_str() {',
    '  "beginFile" => psc1_generated::beginFile(a[2].clone()),',
    '  "nextFile" => psc1_generated::nextFile(a[2].clone(), a[3].clone()),',
    '  "finishFile" => psc1_generated::finishFile(a[2].clone()).to_string(),',
    '  "beginLine" => psc1_generated::beginLine(false),',
    '  "nextLine" => psc1_generated::nextLine(a[2].clone()),',
    '  _ => panic!("unknown test action")',
    ' }; println!("{}", result);',
    '}'
   ].join('\n'));
   run('cargo',['build','--locked','--manifest-path',path.join(crate,'Cargo.toml'),'--bin','io-consumer'],
    {env:{...env,CARGO_TARGET_DIR:path.join(folder,'cargo-target')}});
   const binary=path.join(folder,'cargo-target/debug/io-consumer');
   load=async()=>Object.fromEntries(['beginFile','nextFile','finishFile','beginLine','nextLine'].map(name=>[name,(...args)=>{
    const text=run(binary,[name,...args.filter(a=>typeof a==='string')]).replace(/\n$/,'');
    return name==='finishFile'?JSON.parse(text):text;
   }]));
  }
  const capabilityRoot=path.join(folder,'root');fs.mkdirSync(capabilityRoot);
  const input=path.join(folder,'stdin'),outputConsole=path.join(folder,'stdout');
  fs.writeFileSync(path.join(capabilityRoot,'input.json'),payload);
  fs.writeFileSync(input,'😀\r\n\nlast');fs.writeFileSync(outputConsole,'');
  const inputFd=fs.openSync(input,'r'),outputFd=fs.openSync(outputConsole,'w');
  const config={abi:'psc1-node-linux-string-io/1',capabilities:['readUtf8','writeUtf8','readLine','writeLine'],
   required:['readUtf8','writeUtf8','readLine','writeLine'],root:capabilityRoot,maxFileBytes:4096,maxLineBytes:128,inputFd,outputFd};
  const checks=[];
  try{
   let loaded=false;
   await assert.rejects(()=>withTypedIo({...config,capabilities:[]},async()=>{loaded=true;return {};},()=>{}),/REQUIRED_CAPABILITY_DENIED/);
   assert.equal(loaded,false);checks.push('capability-preflight-before-load');
   await assert.rejects(()=>withTypedIo(config,load,()=>{throw Error('PSC1_TEST_PROGRAM_TRAP');}),/PSC1_TEST_PROGRAM_TRAP/);
   checks.push('application-trap-escapes-source-error-channel');
   await withTypedIo(config,load,async(program,io)=>{
    const begin=program.beginFile('input.json');assert.deepEqual(JSON.parse(begin),JSON.parse(oracle.begin));
    const response=io.execute(begin);assert.deepEqual(JSON.parse(response),JSON.parse(sourceResponse));
    const next=program.nextFile('output.json',response);assert.deepEqual(JSON.parse(next),JSON.parse(oracle.next));
    assert.equal(program.finishFile(io.execute(next)),true);
    assert.equal(fs.readFileSync(path.join(capabilityRoot,'output.json'),'utf8'),expectedText);
    checks.push('actual-json-file-read-transform-atomic-write');
    for(const error of ['notFound','pathDenied','invalidUtf8','tooLarge','capabilityDenied','ioFailure']){
     assert.equal(program.finishFile(JSON.stringify({kind:'error',error})),false);
     assert.deepEqual(JSON.parse(program.nextFile('output.json',JSON.stringify({kind:'error',error}))),
      {op:'writeLine',text:'read failed'});
    }
    checks.push('source-typed-error-handling');
    for(const [text,message]of [['{','invalid JSON'],['{}','missing text']]){
     assert.deepEqual(JSON.parse(program.nextFile('output.json',JSON.stringify({kind:'text',text}))),{op:'writeLine',text:message});
    }
    checks.push('compiled-malformed-json-and-shape-handling');
    for(const expected of ['echo:😀','echo:','echo:last','EOF']){
     const readRequest=program.beginLine(false);
     assert.deepEqual(JSON.parse(readRequest),{op:'readLine'});
     const line=io.execute(readRequest),writeRequest=program.nextLine(line);
     assert.deepEqual(JSON.parse(writeRequest),{op:'writeLine',text:expected});
     assert.equal(program.finishFile(io.execute(writeRequest)),true);
    }
    assert.equal(fs.readFileSync(outputConsole,'utf8'),'echo:😀\necho:\necho:last\nEOF\n');
    checks.push('actual-console-unicode-crlf-empty-eof');
    assert.equal(hash(output+'.bundle.json'),generationHash);
   });
  }finally{fs.closeSync(inputFd);fs.closeSync(outputFd);}
  records.push({syntax,target,passed:true,checks,hostProvider:'Linux-Node-explicit-capability-adapter',
   sourceSha256:hash(source),librarySha256:hash(path.join(root,'stdlib/ProofScript/System/IO.'+syntax)),
   artifactSha256:hash(output),manifestSha256:generationHash,oracleSha256:hash(oracleFile),
   admission:'independent-official-Lean',strictIr:'required-by-production-publication',
   standaloneTargetIo:target!=='rust',rustExecution:'separate-generated-consumer-process',
   publicAbi:'String protocol and scalar Bool',runtime:'executed'});
  fs.cpSync(path.dirname(fs.realpathSync(output+'.bundle.json')),path.join(evidence,'bundles',label),{recursive:true});
  console.log('PSC1_TYPED_IO_APPLICATION_PASS: '+label);
 }catch(error){failures.push({label,error:error.stack||String(error)});console.error('PSC1_TYPED_IO_APPLICATION_FAIL: '+label+'\n'+error.stack);}
}
const receipt={schema:'psc1-typed-io-application-execution/1',testedCommit:process.env.GITHUB_SHA||null,
 branchHeadCommit:process.env.PSC1_HEAD_SHA||null,checkerCommit:oracle.commit,
 passed:failures.length===0,records,failures,completeFamily:false,sevenHostAdapters:false,
 exclusions:['standalone Rust host adapter','Python/PHP host adapters','Wasm public String ABI and IO adapters','complete Practical Core release']};
write(path.join(evidence,'application.json'),JSON.stringify(receipt,null,2)+'\n');
assert.deepEqual(failures,[]);assert.equal(records.length,6);
console.log('PSC1_TYPED_IO_APPLICATION: '+JSON.stringify(receipt));
fs.rmSync(work,{recursive:true,force:true});
