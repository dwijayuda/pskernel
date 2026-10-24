import assert from 'node:assert/strict';
import fs from 'node:fs';import path from 'node:path';
import {sha,verifyArtifact,boundedRun} from '../host-tools/generated-target-tools.mjs';
import {compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
const target=process.argv[2],pins={"rust":{"artifact":"603fd70e3445a7673be4eafb2d853a673b4beeac61bc944135fea615e768d732","executable":"a488bd3d56a58c15d44d634d6590b985c80909d55d39319f5ea3c367fcf3bf00","closure":"a3350d645a81ed17f69af59333978c60e3b8f9e1d6855a999e0bc5844e183990"},"wasm-core":{"artifact":"a7b4a7e34161fba783fcb44a36a28e816d351e14ff7968388c2f091a171f7d37","executable":"3da7d2bf38a335303649c775a680fb9ab9d2e2d943306b0123c4ed856bd82883","closure":"a3350d645a81ed17f69af59333978c60e3b8f9e1d6855a999e0bc5844e183990"}};
function find(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory()){const r=find(p);if(r)return r;}else if(e.name==='qualification.json')return p;}}
const file=find('dist/v2-profile-input'),q=JSON.parse(fs.readFileSync(file)),root=path.dirname(file);
assert.equal(q.testedCommit,'783cf8fceeda094b3e49b166e4d10af05e4b0413');assert.equal(q.target,target);
assert.equal(q.sourceClosureDigest,pins[target].closure);
const manifest=path.join(root,'G1-service/artifact.json'),m=verifyArtifact(manifest,pins[target].artifact);
const exe=path.resolve(path.dirname(manifest),m.executable);assert.equal(sha(fs.readFileSync(exe)),pins[target].executable);
const wire=JSON.parse(fs.readFileSync(path.join(root,'G1-bootstrap.request.json')));
assert.equal(wire[0],'psc1-unified-compiler-service/2');assert.equal(wire[1],target);
assert.equal(compilerSourceClosureDigest(wire[2][6].map(([module,text])=>({module,text,kind:'lean'}))),q.sourceClosureDigest);
for(const [i,row]of q.sourceInventory.entries()){assert.equal(row.module,wire[2][6][i][0]);assert.equal(row.sha256,sha(wire[2][6][i][1]));}
wire[2][1]='G2-self';
const dir=path.resolve('dist/unified-v2-profile-'+target);fs.mkdirSync(dir,{recursive:true});
const input=path.join(dir,'request.json'),output=path.join(dir,'diagnostic-only.candidate.json');fs.writeFileSync(input,JSON.stringify(wire));
const requestHash=sha(fs.readFileSync(input));
let result;
if(target==='rust'){
 fs.chmodSync(exe,0o700);
 const gdb=path.join(dir,'sample.gdb');
 fs.writeFileSync(gdb,[
 'set pagination off','set confirm off','set print frame-arguments none','set print demangle on',
 'python','import threading,time,os,signal',
 'def interrupt_samples():',
 '  for _ in range(3):',
 '    time.sleep(60)',
 '    os.kill(os.getpid(),signal.SIGINT)',
 'threading.Thread(target=interrupt_samples,daemon=True).start()','end',
 'run','thread apply all bt 45','continue','thread apply all bt 45','continue','thread apply all bt 45','kill','quit'
 ].join('\n'));
 result=boundedRun('gdb',['--batch','-x',gdb,'--args',exe,input,output],{logDirectory:dir,timeoutMs:240000});
 fs.writeFileSync(path.join(dir,'stack-samples.txt'),result.stdout+'\n'+result.stderr);
 console.log('PSC1_RUST_STACK_SAMPLES: '+result.stdout.slice(-23000));
}else{
 result=boundedRun(process.execPath,['--prof','--logfile='+path.join(dir,'v8.log'),path.resolve('scripts/generated-target-runner.mjs'),manifest,pins[target].artifact,input,output,'performance-240s'],{logDirectory:dir,timeoutMs:240000});
 const logs=fs.readdirSync(dir).filter(n=>n.endsWith('.log'));
 assert.ok(logs.length,'actual V8 samples required');
 for(const [i,log]of logs.entries()){
  const processed=boundedRun(process.execPath,['--prof-process',path.join(dir,log)],{logDirectory:path.join(dir,'processing-'+i),timeoutMs:60000});
  fs.writeFileSync(path.join(dir,'profile-'+i+'.txt'),processed.stdout);fs.writeFileSync(path.join(dir,'profile-'+i+'.stderr.txt'),processed.stderr);
  console.log('PSC1_WASM_CPU_SAMPLES: '+processed.stdout.slice(0,24000));
 }
}
assert.equal(sha(fs.readFileSync(exe)),pins[target].executable);verifyArtifact(manifest,pins[target].artifact);assert.equal(sha(fs.readFileSync(input)),requestHash);
delete result.stdout;delete result.stderr;
const receipt={schema:'psc1-unified-v2-profile/1',testedCommit:process.env.GITHUB_SHA,target,sourceClosureDigest:q.sourceClosureDigest,serviceArtifact:pins[target].artifact,executableSha256:pins[target].executable,requestSha256:requestHash,result,qualification:false,admission:'not-run',publication:'not-run',scope:'Bounded sampling of exact verified v2 G1 and full 120-module G2 request; no native compiler delegation or candidate adoption; default stack and resource policies unchanged.'};
fs.writeFileSync(path.join(dir,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');console.log('PSC1_UNIFIED_V2_PROFILE: '+JSON.stringify(receipt));
