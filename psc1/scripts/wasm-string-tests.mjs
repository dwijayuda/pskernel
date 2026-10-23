import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {bindWasmStrings,withWasmTypedIo} from '../host-tools/typed-io-wasm.mjs';
import {createTypedIo} from '../host-tools/typed-io.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const work=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-wasm-string-'));
const evidence=path.join(root,'dist/scoped-correctness/wasm-string');
const native=process.env.PSC1_NATIVE||path.join(root,'.lake/build/bin/psc1');
const env={...process.env,PSC1_HOST_TOOLS:path.join(root,'host-tools/artifacts.mjs')};
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const records=[],failures=[];
const schema={echo:{parameters:['string'],result:'string'},join:{parameters:['string','string'],result:'string'},count:{parameters:['string'],result:'bool'}};
function write(p,s){fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,s);}
function run(cmd,args,options={}){
 const r=spawnSync('timeout',['--kill-after=5s','180s',cmd,...args],{cwd:root,env,encoding:'utf8',
  timeout:190000,maxBuffer:32*1024*1024,...options});
 assert.equal(r.error,undefined);assert.equal(r.status,0,cmd+' '+args.join(' ')+'\n'+r.stdout+r.stderr);
 return r.stdout;
}
function build(source,target,output,abi){
 run(native,['build',source,'--target',target,'--assurance','ordinary','--abi',abi,'--out',output]);
 const m=JSON.parse(fs.readFileSync(output+'.bundle.json','utf8'));
 assert.equal(m.logicalCheckerCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
 assert.equal(m.behaviorallyVerified,false);assert.equal(m.publicAbi,abi==='io-dispatcher'?'wasm-io-dispatcher':'wasm-string');
 run('wasm-tools',['validate',output]);return m;
}
const renamedCore=path.join(root,'dist/scoped-correctness/wasm-string-native/renamed-core.wasm');
const renamedComponent=path.join(root,'dist/scoped-correctness/wasm-string-native/renamed-component.wasm');
run('wasm-tools',['validate',renamedCore]);run('wasm-tools',['validate',renamedComponent]);
const renamed=new WebAssembly.Instance(new WebAssembly.Module(fs.readFileSync(renamedCore)));
const renamedBindings=bindWasmStrings(renamed,{echo:{parameters:['string','bool'],result:'string'}});
assert.equal(renamedBindings.call('echo','hygienic😀',true),'hygienic😀');
assert.equal(renamedBindings.call('echo','',false),'');
const renamedConsumer=path.join(work,'renamed-component.py');
write(renamedConsumer,[
 'import sys,wasmtime',
 'from wasmtime.component import Component,Linker',
 'sys.path.insert(0,sys.argv[2])',
 'from typed_io_component import component_engine',
 'engine=component_engine();store=wasmtime.Store(engine)',
 'component=Component.from_file(engine,sys.argv[1]);instance=Linker(engine).instantiate(store,component)',
 'function=instance.get_func(store,"echo");assert function is not None',
 'for text,flag in [("hygienic😀",True),("",False)]:',
 ' assert function(store,text,flag)==text;function.post_return(store)',
 'print("PSC1_WASM_HYGIENIC_LABEL_PASS")'
].join('\n'));
assert.match(run(process.env.PSC1_WASMTIME_PY,[renamedConsumer,renamedComponent,path.join(root,'host-tools')]),/PSC1_WASM_HYGIENIC_LABEL_PASS/);
console.log('PSC1_WASM_HYGIENIC_LABELS: PASS canonical ordered labels, collision avoidance and actual core/component consumers');

const oversizeFile=path.join(root,'dist/scoped-correctness/wasm-string-native/oversize-core.wasm');
run('wasm-tools',['validate',oversizeFile]);
const oversized=new WebAssembly.Instance(new WebAssembly.Module(fs.readFileSync(oversizeFile)),{
 'psc1:io':{dispatch(){throw Error('PSC1_OVERSIZE_UNEXPECTED_HOST_CALL');}}
});
const refused=oversized.exports.oversize(),view=new DataView(oversized.exports.memory.buffer,refused,8);
const refusal=new TextDecoder('utf-8',{fatal:true}).decode(new Uint8Array(oversized.exports.memory.buffer,
 view.getUint32(0,true),view.getUint32(4,true)));
assert.deepEqual(JSON.parse(refusal),{kind:'error',error:'tooLarge'});
const portable=createTypedIo({abi:'psc1-node-linux-string-io/1',capabilities:[],required:[],
 root:work,maxFileBytes:2097152,maxLineBytes:2097152,inputFd:0,outputFd:1});
try{assert.deepEqual(JSON.parse(refusal),JSON.parse(portable.execute('\0'.repeat(16777153))));}
finally{portable.close();}
const pureConsumer=path.join(work,'component-pure.py');
write(pureConsumer,[
 'import wasmtime,sys',
 'from wasmtime.component import Component,Linker',
 'sys.path.insert(0,sys.argv[2])',
 'from typed_io_component import component_engine',
 'engine=component_engine();store=wasmtime.Store(engine)',
 'component=Component.from_file(engine,sys.argv[1]);instance=Linker(engine).instantiate(store,component)',
 'def call(name,*args):',
 ' function=instance.get_func(store,name);assert function is not None',
 ' value=function(store,*args);function.post_return(store);return value',
 'for text in ("","A😀Ω","\\ufeffx","\\0","a"*65536): assert call("echo",text)==text',
 'assert call("join","left😀","Ωright")=="left😀Ωright"',
 'assert call("join","","")==""',
 'assert call("count","A😀Ω") is True',
 'assert call("count","😀") is False',
 'for _ in range(64): assert call("echo","x"*262144)=="x"*262144',
 'print("PSC1_COMPONENT_STRING_CONSUMER_PASS")'
].join('\n'));
const ioConsumer=path.join(work,'component-io.py');
write(ioConsumer,[
 'import sys',
 'sys.path.insert(0,sys.argv[2])',
 'from typed_io_component import with_component_io,component_engine',
 'config=dict(abi="psc1-wasm-component-linux-string-io/1",capabilities=["readUtf8","writeUtf8","readLine","writeLine"],required=["readUtf8","writeUtf8","readLine","writeLine"],root=sys.argv[3],maxFileBytes=4096,maxLineBytes=128,inputFd=0,outputFd=1)',
 'try:with_component_io({**config,"capabilities":[]}, "/missing-component",lambda call:call("run"))',
 'except RuntimeError as error:assert "REQUIRED_CAPABILITY_DENIED" in str(error)',
 'else:raise AssertionError("denied capability accepted")',
 'try:with_component_io({**config,"maxFileBytes":2097153}, "/missing-component",lambda call:call("run"))',
 'except RuntimeError as error:assert "CONFIGURATION" in str(error)',
 'else:raise AssertionError("unsupported bound accepted")',
 'assert with_component_io(config,sys.argv[1],lambda call:call("run")) is True',
 'import wasmtime,json',
 'from wasmtime.component import Component,Linker',
 'engine=component_engine();store=wasmtime.Store(engine);component=Component.from_file(engine,sys.argv[1]);linker=Linker(engine)',
 'def trap(_store,request):',
 ' value=json.loads(request)',
 ' if value.get("path")=="missing":raise RuntimeError("PSC1_HOST_TRAP")',
 ' return json.dumps(dict(kind="text",text="A") if value["op"]=="readUtf8" else dict(kind="unit"))',
 'with linker.root() as root: root.add_func("dispatch",trap)',
 'instance=linker.instantiate(store,component)',
 'try:instance.get_func(store,"run")(store)',
 'except RuntimeError as error:assert str(error)=="PSC1_HOST_TRAP"',
 'else:raise AssertionError("source handler swallowed host trap")'

].join('\n'));
// Each expected component trap has a fresh process/store; a trapped instance
// is not a reusable host boundary for an independent negative observation.
const shortConsumer=path.join(work,'component-short-circuit.py');
write(shortConsumer,[
 'import sys,json,wasmtime',
 'sys.path.insert(0,sys.argv[2])',
 'from typed_io_component import component_engine',
 'from wasmtime.component import Component,Linker',
 'engine=component_engine();store=wasmtime.Store(engine);component=Component.from_file(engine,sys.argv[1]);linker=Linker(engine)',
 'def short_trap(_store,request):',
 ' if request=="PSC1_SHORT_CIRCUIT_TRAP":raise RuntimeError("PSC1_SHORT_CIRCUIT_TRAP")',
 ' return json.dumps(dict(kind="error",error="notFound"))',
 'with linker.root() as root:root.add_func("dispatch",short_trap)',
 'instance=linker.instantiate(store,component)',
 'try:instance.get_func(store,"run")(store)',
 'except RuntimeError as error:assert str(error)=="PSC1_SHORT_CIRCUIT_TRAP"',
 'else:raise AssertionError("eager short-circuit control did not trap")'
].join('\n'));
for(const syntax of ['lean','ps'])for(const target of ['wasm-core','wasm-component']){
 const label=syntax+'-'+target,folder=path.join(work,label);
 try{
  const source=path.join(folder,'strings.'+syntax),output=path.join(folder,'strings.wasm');
  write(source,read('test/WasmStringFixtures.'+syntax));build(source,target,output,'wasm-string');
  if(target==='wasm-core'){
   const module=new WebAssembly.Module(fs.readFileSync(output)),instance=new WebAssembly.Instance(module);
   const api=bindWasmStrings(instance,schema);
   for(const text of ['','A😀Ω','\ufeffx','\0','a'.repeat(65536)])assert.equal(api.call('echo',text),text);
   assert.equal(api.call('join','left😀','Ωright'),'left😀Ωright');assert.equal(api.call('join','',''),'');
   assert.equal(api.call('count','A😀Ω'),true);assert.equal(api.call('count','😀'),false);
   for(let i=0;i<64;i++)assert.equal(api.call('echo','x'.repeat(262144)),'x'.repeat(262144));
   const e=instance.exports;
   for(const bytes of [[0xc0,0xaf],[0xed,0xa0,0x80],[0xf4,0x90,0x80,0x80],[0xe2,0x82],[0x80]]){
    new Uint8Array(e.memory.buffer,64,bytes.length).set(bytes);
    assert.throws(()=>e.echo(64,bytes.length),WebAssembly.RuntimeError);
   }
   for(const [pointer,length]of [[-1,1],[16777216,1],[16777215,2],[1,-1]])
    assert.throws(()=>e.echo(pointer,length),WebAssembly.RuntimeError);
   for(const args of [[0,0,2,1],[0,0,1,16777217],[1,1,1,1]])
    assert.throws(()=>e.cabi_realloc(...args),WebAssembly.RuntimeError);
   assert.equal(api.call('echo','after refused input'),'after refused input');
  }else{
   assert.ok(process.env.PSC1_WASMTIME_PY);
   assert.match(run(process.env.PSC1_WASMTIME_PY,[pureConsumer,output,path.join(root,'host-tools')]),/PSC1_COMPONENT_STRING_CONSUMER_PASS/);
   const wit=run('wasm-tools',['component','wit',output]);
   assert.match(wit,/string/);
  }
  const pointer=fs.realpathSync(output),manifestHash=hash(output+'.bundle.json');
  const base=['build',source,'--target',target,'--assurance','ordinary','--out',output];
  for(const tail of [['--abi','unknown'],['--abi'],['--abi','wasm-string','--abi','wasm-string'],
   ['--abi','wasm-string','--assurance','verified']]){
   const r=spawnSync(native,[...base,...tail],{cwd:root,env,encoding:'utf8',timeout:60000});
   assert.equal(r.error,undefined);assert.equal(r.signal,null);assert.notEqual(r.status,0);
   assert.match(r.stdout+r.stderr,/PSC1_(ABI_|ASSURANCE_)/);
   assert.equal(fs.realpathSync(output),pointer);assert.equal(hash(output+'.bundle.json'),manifestHash);
  }
  const ioSource=path.join(folder,'source/Run.'+syntax),ioOutput=path.join(folder,'io.wasm');
  write(ioSource,read('test/applications/SequencedIo/Run.'+syntax));
  write(path.join(folder,'source/SequencedIo/Program.'+syntax),read('test/applications/SequencedIo/Program.'+syntax));
  write(path.join(folder,'source/ProofScript/System/IO.'+syntax),read('stdlib/ProofScript/System/IO.'+syntax));
  const ioManifest=build(ioSource,target,ioOutput,'io-dispatcher');
  const capabilityRoot=path.join(folder,'root');fs.mkdirSync(capabilityRoot);
  fs.writeFileSync(path.join(capabilityRoot,'input.txt'),'hello😀');
  if(target==='wasm-core'){
   const input=path.join(folder,'stdin'),consoleOut=path.join(folder,'stdout');
   fs.writeFileSync(input,'world😀\r\n');fs.writeFileSync(consoleOut,'');
   const inputFd=fs.openSync(input,'r'),outputFd=fs.openSync(consoleOut,'w');
   try{
    const config={abi:'psc1-wasm-core-linux-string-io/1',capabilities:['readUtf8','writeUtf8','readLine','writeLine'],
     required:['readUtf8','writeUtf8','readLine','writeLine'],root:capabilityRoot,maxFileBytes:4096,maxLineBytes:128,inputFd,outputFd};
    let loaded=false;
    await assert.rejects(()=>withWasmTypedIo({...config,capabilities:[]},()=>{loaded=true;}, {},()=>{}),/REQUIRED_CAPABILITY_DENIED/);
    assert.equal(loaded,false);
    await assert.rejects(()=>withWasmTypedIo({...config,maxFileBytes:2097153},()=>{loaded=true;}, {},()=>{}),/CONFIGURATION/);
    assert.equal(loaded,false);
    await withWasmTypedIo(config,()=>new WebAssembly.Module(fs.readFileSync(ioOutput)),
     {run:{parameters:[],result:'bool'}},program=>assert.equal(program.call('run'),true));
    assert.equal(fs.readFileSync(consoleOut,'utf8'),'tick\ntick\nrecovered\necho:world😀\n');
    let trapped;
    trapped=new WebAssembly.Instance(new WebAssembly.Module(fs.readFileSync(ioOutput)),{'psc1:io':{dispatch(pointer,length,result){
     const memory=trapped.exports.memory;
     const request=JSON.parse(new TextDecoder().decode(new Uint8Array(memory.buffer,pointer>>>0,length>>>0)));
     if(request.path==='missing')throw Error('PSC1_HOST_TRAP');
     const response=JSON.stringify(request.op==='readUtf8'?{kind:'text',text:'A'}:{kind:'unit'});
     const bytes=new TextEncoder().encode(response),data=trapped.exports.cabi_realloc(0,0,1,bytes.length);
     new Uint8Array(memory.buffer,data,bytes.length).set(bytes);
     const record=new DataView(memory.buffer,result>>>0,8);record.setUint32(0,data,true);record.setUint32(4,bytes.length,true);
    }}});
    assert.throws(()=>trapped.exports.run(),/PSC1_HOST_TRAP/);
    let shortTrapped;
    shortTrapped=new WebAssembly.Instance(new WebAssembly.Module(fs.readFileSync(ioOutput)),{'psc1:io':{dispatch(pointer,length,result){
     const memory=shortTrapped.exports.memory;
     const request=new TextDecoder().decode(new Uint8Array(memory.buffer,pointer>>>0,length>>>0));
     if(request==='PSC1_SHORT_CIRCUIT_TRAP')throw Error('PSC1_SHORT_CIRCUIT_TRAP');
     const bytes=new TextEncoder().encode(JSON.stringify({kind:'error',error:'notFound'}));
     const data=shortTrapped.exports.cabi_realloc(0,0,1,bytes.length);
     new Uint8Array(memory.buffer,data,bytes.length).set(bytes);
     const record=new DataView(memory.buffer,result>>>0,8);record.setUint32(0,data,true);record.setUint32(4,bytes.length,true);
    }}});
    assert.throws(()=>shortTrapped.exports.run(),/PSC1_SHORT_CIRCUIT_TRAP/);
   }finally{fs.closeSync(inputFd);fs.closeSync(outputFd);}
  }else{
   const stdout=run(process.env.PSC1_WASMTIME_PY,[ioConsumer,ioOutput,path.join(root,'host-tools'),capabilityRoot],{input:'world😀\r\n'});
   assert.equal(stdout,'tick\ntick\nrecovered\necho:world😀\n');
   assert.equal(run(process.env.PSC1_WASMTIME_PY,[shortConsumer,ioOutput,path.join(root,'host-tools')]),'');
  }
  assert.equal(fs.readFileSync(path.join(capabilityRoot,'output.txt'),'utf8'),'processed:hello😀');
  records.push({syntax,target,passed:true,stringsSha256:hash(output),ioSha256:hash(ioOutput),
   admission:'independent-official-Lean',runtime:'executed',hostEffects:true,strictIr:'required-by-production-publication',
   checks:["general-source-sequencing","actual-file-read-atomic-write","actual-console-unicode-crlf","typed-error-recovery","host-trap-escapes","unsupported-abi-preserves-generation","short-circuit-skips-foreign-error","short-circuit-error-control-traps"],provider:target==='wasm-core'?'node':'python',abi:'wasm-io-dispatcher',
   checkerCommit:ioManifest.logicalCheckerCommit,artifactSha256:hash(ioOutput),manifestSha256:hash(ioOutput+'.bundle.json'),
   librarySha256:hash(path.join(root,'stdlib/ProofScript/System/IO.'+syntax)),
   applicationModuleSha256:hash(path.join(folder,'source/SequencedIo/Program.'+syntax)),
   sourceClosureSha256:ioManifest.sourceClosureSha256,kernelAdmissionSha256:ioManifest.kernelAdmissionSha256,
   sourceSha256:hash(ioSource),stringSourceSha256:hash(source),ioSourceSha256:hash(ioSource),
   hostProvider:target==='wasm-core'?'Node-explicit-capability-adapter':'Python-standalone-capability-adapter',
   validator:'wasm-tools-1.254.0',consumer:target==='wasm-core'?'Node-22.23.3':'wasmtime-python-49.0.0'});
  for(const [name,file]of [['strings',output],['io',ioOutput]])
   fs.cpSync(path.dirname(fs.realpathSync(file+'.bundle.json')),path.join(evidence,'bundles',label+'-'+name),{recursive:true});
  console.log('PSC1_WASM_STRING_PASS: '+label);
 }catch(error){failures.push({label,error:error.stack||String(error)});console.error('PSC1_WASM_STRING_FAIL: '+label+'\n'+error.stack);}
}
const receipt={schema:'psc1-wasm-string-io/1',testedCommit:process.env.GITHUB_SHA||null,
 branchHeadCommit:process.env.PSC1_HEAD_SHA||null,records,failures,passed:failures.length===0,
 completeFamily:false,releaseReady:false,
 oversizedRequest:{passed:true,binarySha256:hash(oversizeFile),requestBytes:16777153,
  portablePayloadLimit:2097152,foreignDispatchCalled:false,response:'tooLarge'}};
write(path.join(evidence,'results.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_WASM_STRING: '+JSON.stringify(receipt));assert.deepEqual(failures,[]);
assert.equal(records.length,4);fs.rmSync(work,{recursive:true,force:true});
