// Bounded target checker sampling only; generated compiler code is never executed/adopted.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
const source=files.find(p=>p.endsWith('/G1-service/module.ts'));assert.ok(source);
const config=path.join(path.dirname(source),'tsconfig.json'),configuration=JSON.parse(fs.readFileSync(config,'utf8'));
assert.equal(configuration.compilerOptions.strict,true);assert.equal(configuration.compilerOptions.noEmitOnError,true);
assert.deepEqual(configuration.files,['module.ts']);
const compiler=path.resolve('node_modules/typescript/bin/tsc'),pkg=JSON.parse(fs.readFileSync('node_modules/typescript/package.json','utf8'));
assert.equal(pkg.version,'7.0.2');
fs.mkdirSync('diagnosis',{recursive:true});const sourceSha256=sha(fs.readFileSync(source));
console.log('PSC1_TS_CHECKER_PIN: '+JSON.stringify({version:pkg.version,compilerSha256:sha(fs.readFileSync(compiler)),
 entry:fs.readFileSync(compiler,'utf8').slice(0,1800),sourceSha256,sourceBytes:fs.statSync(source).size,strict:true}));
const directory=path.resolve('diagnosis/checker'),request={command:[process.execPath,'--prof',
 '--logfile='+path.resolve('diagnosis/checker-v8.log'),compiler,'--project',path.resolve(config)],
 directory,timeoutMs:30000,maxBuffer:32*1024*1024};
const result=spawnSync('python3',['.github/diagnostics/bounded-process.py',JSON.stringify(request)],{encoding:'utf8',timeout:35000,killSignal:'SIGKILL',maxBuffer:1024*1024});
assert.equal(result.status,0,result.stderr);assert.equal(sha(fs.readFileSync(source)),sourceSha256);
console.log('PSC1_TS_CHECKER_SAMPLE: '+result.stdout.trim());
const profiles=fs.readdirSync('diagnosis').filter(n=>n.endsWith('.log'));
for(const name of profiles){
 const file=path.resolve('diagnosis',name),r=spawnSync(process.execPath,['--prof-process',file],{encoding:'utf8',timeout:30000,killSignal:'SIGKILL',maxBuffer:32*1024*1024});
 fs.writeFileSync('diagnosis/'+name+'.txt',r.stdout||'');
 console.log('PSC1_TS_CHECKER_CPU: '+JSON.stringify({file:name,bytes:fs.statSync(file).size,
  sha256:sha(fs.readFileSync(file)),status:r.status,summary:(r.stdout||'').split('\n').slice(0,150),
  stderr:(r.stderr||'').slice(-1000),qualification:false,adoption:'not-run'}));
}
