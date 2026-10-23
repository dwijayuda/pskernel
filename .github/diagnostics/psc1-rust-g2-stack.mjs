// Exact generated Rust G2 sampling; no candidate adoption, admission or qualification.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
const artifactFile=files.find(p=>p.endsWith('/G1-service/artifact.json'));assert.ok(artifactFile);
assert.equal(sha(fs.readFileSync(artifactFile)),'ec0b0e6b3ddd90f8bc237e65f581a3e64f850b0d9de00b74a09580bbeee8a8fd');
const directory=path.dirname(artifactFile),m=JSON.parse(fs.readFileSync(artifactFile,'utf8'));
const qualification=JSON.parse(fs.readFileSync(files.find(p=>p.endsWith('/qualification.json')),'utf8'));
console.log('PSC1_RUST_PROTOTYPE_RECEIPT: '+JSON.stringify({bootstrap:qualification.bootstrap,serviceArtifact:qualification.serviceArtifact,generations:qualification.generations,attempts:qualification.attempts,sourceClosureDigest:qualification.sourceClosureDigest}));
assert.equal(m.target,'rust');assert.equal(m.service,true);assert.deepEqual(m.publicNames,['psCompilerRustServiceCandidate']);
function verify(){for(const f of m.files){assert.match(f.path,/^[a-zA-Z0-9_.-]+$/);const p=path.join(directory,f.path);assert.ok(fs.lstatSync(p).isFile()&&!fs.lstatSync(p).isSymbolicLink());const b=fs.readFileSync(p);assert.equal(b.length,f.bytes);assert.equal(sha(b),f.sha256);}}
verify();const request=files.find(p=>path.basename(p)==='G2-self.request.json');assert.ok(request);
assert.equal(sha(fs.readFileSync(request)),'4e8807fa2c2f07bf298a480046c76b689b9594bc04537d2e7720fd73e9879381');
const binary=path.resolve(directory,m.executable);fs.chmodSync(binary,0o700);fs.mkdirSync('diagnosis',{recursive:true});
for(const seconds of [180]){
 const output=path.resolve('diagnosis/response-'+seconds+'.json');
 const args=['--preserve-status','--signal=INT','--kill-after=3s',seconds+'s','gdb','--batch',
  '-ex','set pagination off','-ex','set confirm off','-ex','set print frame-arguments none',
  '-ex','set disable-randomization off','-ex','handle SIGSEGV stop print nopass','-ex','run','-ex','thread apply all bt 44','--args',binary,path.resolve(request),output];
 const start=Date.now(),r=spawnSync('timeout',args,{encoding:'utf8',timeout:(seconds+5)*1000,killSignal:'SIGKILL',maxBuffer:1024*1024});
 fs.writeFileSync('diagnosis/gdb-'+seconds+'.txt',(r.stdout||'')+'\n'+(r.stderr||''));
 verify();assert.equal(sha(fs.readFileSync(request)),'4e8807fa2c2f07bf298a480046c76b689b9594bc04537d2e7720fd73e9879381');
 console.log('PSC1_RUST_G2_NATIVE_STACK: '+JSON.stringify({seconds,elapsedMs:Date.now()-start,status:r.status,signal:r.signal,error:r.error?.message||null,
  executableSha256:sha(fs.readFileSync(binary)),sourceSha256:m.sourceSha256,requestSha256:sha(fs.readFileSync(request)),
  report:(r.stdout||'').split('\n').map(l=>l.slice(0,500)).slice(-80),stderr:(r.stderr||'').slice(-1500),
  responseProduced:fs.existsSync(output),qualification:false,adoption:'not-run',admission:'not-run'}));
}
