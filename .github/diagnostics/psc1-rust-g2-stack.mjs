// Exact generated Rust G2 sampling; no candidate adoption, admission or qualification.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
const artifactFile=files.find(p=>p.endsWith('/G1-service/artifact.json'));assert.ok(artifactFile);
assert.equal(sha(fs.readFileSync(artifactFile)),'5fd523e5cddbe6152ed9eb72c98ad866f8f01121c3ca00e4b3bec5f78229e41d');
const directory=path.dirname(artifactFile),m=JSON.parse(fs.readFileSync(artifactFile,'utf8'));
const qualification=JSON.parse(fs.readFileSync(files.find(p=>p.endsWith('/qualification.json')),'utf8'));
console.log('PSC1_RUST_PROTOTYPE_RECEIPT: '+JSON.stringify({bootstrap:qualification.bootstrap,serviceArtifact:qualification.serviceArtifact,generations:qualification.generations,attempts:qualification.attempts,sourceClosureDigest:qualification.sourceClosureDigest}));
assert.equal(m.target,'rust');assert.equal(m.service,true);assert.deepEqual(m.publicNames,['psCompilerRustServiceCandidate']);
function verify(){for(const f of m.files){assert.match(f.path,/^[a-zA-Z0-9_.-]+$/);const p=path.join(directory,f.path);assert.ok(fs.lstatSync(p).isFile()&&!fs.lstatSync(p).isSymbolicLink());const b=fs.readFileSync(p);assert.equal(b.length,f.bytes);assert.equal(sha(b),f.sha256);}}
verify();
const candidate=JSON.parse(fs.readFileSync(files.find(p=>p.endsWith('/G1-bootstrap.candidate.json')),'utf8'));
for(const key of ['originalIr','specializedIr']){
 const declarations=candidate[key][4];
 const rows=declarations.filter(d=>d[0].includes('psLexListLengthAcc')||(d[1].length>0&&d[3][0]==='function')).map(d=>({
  name:d[0],typeParameters:d[1],parameters:d[2],result:d[3],
  selfReference:JSON.stringify(d[4]).includes(JSON.stringify(['var',d[0]])),bodyBytes:JSON.stringify(d[4]).length}));
 console.log('PSC1_GENERIC_CURRIED_IR: '+JSON.stringify({phase:key,count:rows.length,rows}));
}
const generated=fs.readFileSync(path.join(directory,'module.rs'),'utf8');
console.log('PSC1_GENERIC_LENGTH_SOURCE: '+JSON.stringify({sourceSha256:m.sourceSha256,
 functions:generated.split('\\n').filter(l=>/fn [^(<]*psLexListLengthAcc/.test(l)).map(l=>({bytes:l.length,source:l.slice(0,16000)}))}));
verify();const request=files.find(p=>path.basename(p)==='G2-self.request.json');assert.ok(request);
assert.equal(sha(fs.readFileSync(request)),'7936829ce535a1ae2cafb9792f19278fe8c17a6c4ca4095c227667387b9f0e89');
const binary=path.resolve(directory,m.executable);fs.chmodSync(binary,0o700);fs.mkdirSync('diagnosis',{recursive:true});
for(const seconds of [60]){
 const output=path.resolve('diagnosis/response-'+seconds+'.json');
 const args=['--preserve-status','--signal=INT','--kill-after=3s',seconds+'s','gdb','--batch',
  '-ex','set pagination off','-ex','set confirm off','-ex','set print frame-arguments none',
  '-ex','set disable-randomization off','-ex','handle SIGSEGV stop print nopass','-ex','run','-ex','thread apply all bt 44','--args',binary,path.resolve(request),output];
 const start=Date.now(),r=spawnSync('timeout',args,{encoding:'utf8',timeout:(seconds+5)*1000,killSignal:'SIGKILL',maxBuffer:1024*1024});
 fs.writeFileSync('diagnosis/gdb-'+seconds+'.txt',(r.stdout||'')+'\n'+(r.stderr||''));
 verify();assert.equal(sha(fs.readFileSync(request)),'7936829ce535a1ae2cafb9792f19278fe8c17a6c4ca4095c227667387b9f0e89');
 console.log('PSC1_RUST_G2_NATIVE_STACK: '+JSON.stringify({seconds,elapsedMs:Date.now()-start,status:r.status,signal:r.signal,error:r.error?.message||null,
  executableSha256:sha(fs.readFileSync(binary)),sourceSha256:m.sourceSha256,requestSha256:sha(fs.readFileSync(request)),
  report:(r.stdout||'').split('\n').map(l=>l.slice(0,500)).slice(-80),stderr:(r.stderr||'').slice(-1500),
  responseProduced:fs.existsSync(output),qualification:false,adoption:'not-run',admission:'not-run'}));
}
