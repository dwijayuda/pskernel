import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {withTypedIo} from '../host-tools/typed-io.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const evidence=path.join(root,'dist/scoped-correctness/typed-io-dispatcher');
const work=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-io-dispatcher-'));
const native=process.env.PSC1_NATIVE||path.join(root,'.lake/build/bin/psc1');
const env={...process.env,PSC1_HOST_TOOLS:path.join(root,'host-tools/artifacts.mjs')};
const targets=(process.env.PSC1_IO_DISPATCHER_TARGETS||'js,ts,rust').split(',');
assert.ok(targets.length&&targets.every(t=>['js','ts','rust','python'].includes(t)));
const records=[],failures=[];
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
function write(p,s){fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,s);}
function run(cmd,args,options={}){
 const r=spawnSync('timeout',['--kill-after=5s','180s',cmd,...args],
  {cwd:root,env,encoding:'utf8',timeout:190000,maxBuffer:32*1024*1024,...options});
 assert.equal(r.error,undefined);assert.equal(r.status,0,cmd+' '+args.join(' ')+'\n'+r.stdout+r.stderr);
 return r.stdout;
}
function refuse(args,pattern){
 const r=spawnSync(native,args,{cwd:root,env,encoding:'utf8',timeout:60000});
 assert.equal(r.error,undefined);assert.equal(r.signal,null);assert.notEqual(r.status,0);
 assert.match(r.stdout+r.stderr,pattern);
}
write(path.join(work,'package.json'),'{"type":"module"}\n');
for(const syntax of ['lean','ps'])for(const target of targets){
 const label=syntax+'-'+target,folder=path.join(work,label),source=path.join(folder,'source/Run.'+syntax);
 const output=path.join(folder,'module.'+{js:'js',ts:'ts',rust:'rs',python:'py'}[target]);
 try{
  write(source,read('test/applications/SequencedIo/Run.'+syntax));
  write(path.join(folder,'source/SequencedIo/Program.'+syntax),read('test/applications/SequencedIo/Program.'+syntax));
  write(path.join(folder,'source/ProofScript/System/IO.'+syntax),read('stdlib/ProofScript/System/IO.'+syntax));
  const args=['build',source,'--target',target,'--assurance','ordinary','--out',output];
  run(native,[...args,'--abi','io-dispatcher']);
  const manifest=JSON.parse(fs.readFileSync(output+'.bundle.json','utf8'));
  assert.equal(manifest.logicalCheckerCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(manifest.behaviorallyVerified,false);
  assert.equal(manifest.publicAbi,'io-dispatcher');
  const pointer=fs.realpathSync(output),bundleHash=hash(output+'.bundle.json');
  for(const tail of [['--abi','bad'],['--abi'],['--abi','io-dispatcher','--abi','io-dispatcher']]){
   refuse([...args,...tail],/PSC1_ABI_/);assert.equal(fs.realpathSync(output),pointer);assert.equal(hash(output+'.bundle.json'),bundleHash);
  }
  refuse([...args,'--abi','io-dispatcher','--assurance','verified'],/PSC1_ASSURANCE_DUPLICATE/);
  refuse(['build',source,'--target',target,'--out',output,'--abi','io-dispatcher','--assurance','verified'],/PSC1_VERIFIED_EXECUTION_UNAVAILABLE/);
  if(target!=='rust')refuse(args,/PSC1_.*(TYPE|PUBLIC|PARAMETER)/);
  if(target==='rust'){
   const crate=path.join(folder,'consumer');
   fs.cpSync(fs.realpathSync(output.replace(/\.rs$/,'.cargo')),crate,{recursive:true,dereference:true});
   write(path.join(crate,'tests/io_dispatcher.rs'),[
    '#[test] fn checked_source_sequence_callback() {',
    'let dispatch=std::rc::Rc::new(|request: String| -> String {',
    'if request.contains("\\\"path\\\":\\\"missing\\\"") { return "{\\\"kind\\\":\\\"error\\\",\\\"error\\\":\\\"notFound\\\"}".to_owned(); }',
    'if request.contains("\\\"op\\\":\\\"readUtf8\\\"") { return "{\\\"kind\\\":\\\"text\\\",\\\"text\\\":\\\"A\\\"}".to_owned(); }',
    'if request.contains("\\\"op\\\":\\\"readLine\\\"") { return "{\\\"kind\\\":\\\"line\\\",\\\"text\\\":null}".to_owned(); }',
    '"{\\\"kind\\\":\\\"unit\\\"}".to_owned() });',
    'assert!(psc1_generated::run(dispatch)); }'
   ].join('\n'));
   run('cargo',['test','--locked','--manifest-path',path.join(crate,'Cargo.toml'),'--test','io_dispatcher'],
    {env:{...env,CARGO_TARGET_DIR:path.join(folder,'cargo-target')}});
  }else if(target==='python'){
   const capabilityRoot=path.join(folder,'root');fs.mkdirSync(capabilityRoot);
   fs.writeFileSync(path.join(capabilityRoot,'input.txt'),'hello😀');
   const consumer=path.join(folder,'consumer.py');
   write(consumer,[
    'import importlib.util,sys',
    'sys.path.insert(0,sys.argv[2])',
    'from typed_io import TypedIo',
    'config=dict(abi="psc1-python-linux-string-io/1",capabilities=["readUtf8","writeUtf8","readLine","writeLine"],required=["readUtf8","writeUtf8","readLine","writeLine"],root=sys.argv[3],maxFileBytes=4096,maxLineBytes=128,inputFd=0,outputFd=1)',
    'with TypedIo(config) as host:',
    ' spec=importlib.util.spec_from_file_location("checked_guest",sys.argv[1])',
    ' guest=importlib.util.module_from_spec(spec);spec.loader.exec_module(guest)',
    ' assert guest.run(host.execute) is True',
    ' def trap(request):',
    '  import json',
    '  value=json.loads(request)',
    '  if value.get("path")=="missing": raise RuntimeError("PSC1_HOST_TRAP")',
    '  return json.dumps(dict(kind="text",text="A") if value["op"]=="readUtf8" else dict(kind="unit"))',
    ' try: guest.run(trap)',
    ' except RuntimeError as error: assert str(error)=="PSC1_HOST_TRAP"',
    ' else: raise AssertionError("guest swallowed host trap")'
   ].join('\n'));
   const stdout=run(process.env.PSC1_PYTHON||'python3',['-I',consumer,output,path.join(root,'host-tools'),capabilityRoot],{input:'world😀\r\n'});
   assert.equal(stdout,'tick\ntick\nrecovered\necho:world😀\n');
   assert.equal(fs.readFileSync(path.join(capabilityRoot,'output.txt'),'utf8'),'processed:hello😀');
  }else{
   let module=output;
   if(target==='ts'){
    assert.ok(process.env.PSC1_TSC);
    const consumer=path.join(folder,'consumer');
    run(process.execPath,[process.env.PSC1_TSC,'--ignoreConfig','--strict','--target','ES2022','--module','ESNext','--moduleResolution','Bundler','--outDir',consumer,fs.realpathSync(output)]);
    write(path.join(consumer,'package.json'),'{"type":"module"}\n');module=path.join(consumer,'module.js');
   }
   const capabilityRoot=path.join(folder,'root');fs.mkdirSync(capabilityRoot);
   fs.writeFileSync(path.join(capabilityRoot,'input.txt'),'hello😀');
   const input=path.join(folder,'stdin'),consoleOut=path.join(folder,'stdout');
   fs.writeFileSync(input,'world😀\r\n');fs.writeFileSync(consoleOut,'');
   const inputFd=fs.openSync(input,'r'),outputFd=fs.openSync(consoleOut,'w');
   try{
    const config={abi:'psc1-node-linux-string-io/1',capabilities:['readUtf8','writeUtf8','readLine','writeLine'],
     required:['readUtf8','writeUtf8','readLine','writeLine'],root:capabilityRoot,maxFileBytes:4096,maxLineBytes:128,inputFd,outputFd};
    await withTypedIo(config,()=>import(pathToFileURL(fs.realpathSync(module)).href),async(program,io)=>{
     const trace=[];
     assert.equal(program.run(request=>{trace.push(JSON.parse(request));return io.execute(request);}),true);
     assert.deepEqual(trace.map(r=>r.op),['readUtf8','writeUtf8','writeLine','writeLine','readUtf8','writeLine','readLine','writeLine']);
     assert.equal(fs.readFileSync(path.join(capabilityRoot,'output.txt'),'utf8'),'processed:hello😀');
     assert.equal(fs.readFileSync(consoleOut,'utf8'),'tick\ntick\nrecovered\necho:world😀\n');
     assert.throws(()=>program.run(request=>{
      const r=JSON.parse(request);
      if(r.path==='missing')throw Error('PSC1_HOST_TRAP');
      return JSON.stringify(r.op==='readUtf8'?{kind:'text',text:'A'}:{kind:'unit'});
     }),/PSC1_HOST_TRAP/);
    });
   }finally{fs.closeSync(inputFd);fs.closeSync(outputFd);}
  }
  records.push({syntax,target,passed:true,sourceSha256:hash(source),artifactSha256:hash(output),
   manifestSha256:bundleHash,hostEffects:target!=='rust',hostProvider:target==='rust'?'Rust-native-callback-mock':target==='python'?'Python-standalone-capability-adapter':'Linux-Node-capability-adapter',
   checkerCommit:manifest.logicalCheckerCommit,strictIr:'production-publication',abi:'io-dispatcher'});
  fs.cpSync(path.dirname(fs.realpathSync(output+'.bundle.json')),path.join(evidence,'bundles',label),{recursive:true});
  console.log('PSC1_IO_DISPATCHER_PASS: '+label);
 }catch(error){failures.push({label,error:error.stack||String(error)});console.error('PSC1_IO_DISPATCHER_FAIL: '+label+'\n'+error.stack);}
}
const receipt={schema:'psc1-io-dispatcher-execution/1',testedCommit:process.env.GITHUB_SHA||null,
 branchHeadCommit:process.env.PSC1_HEAD_SHA||null,records,failures,passed:failures.length===0,
 completeFamily:false,sevenHostAdapters:false};
write(path.join(evidence,'results.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_IO_DISPATCHER: '+JSON.stringify(receipt));assert.deepEqual(failures,[]);
assert.equal(records.length,2*targets.length);fs.rmSync(work,{recursive:true,force:true});
