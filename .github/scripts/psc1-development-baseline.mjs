// Installed .ps latency baseline. No product files or acceptance policy are changed.
import fs from'node:fs';import path from'node:path';import os from'node:os';
import assert from'node:assert/strict';import{spawnSync}from'node:child_process';import{createHash}from'node:crypto';
const input=path.resolve('dist/development-input'),r=JSON.parse(fs.readFileSync(path.join(input,'package-receipt.json')));
const hash=b=>createHash('sha256').update(b).digest('hex'),tar=path.join(input,'tarballs',r.tarball);
assert.equal(hash(fs.readFileSync(tar)),r.sha256);assert.equal(r.sha256,'97f0bd6809c9f2a910b64ca96977c0725c6810291ea2f5991ce74fdfcf142446');
const directory=fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()),'psc1-development-'));
const run=(exe,args,cwd=directory)=>{const x=spawnSync(exe,args,{cwd,encoding:'utf8',timeout:240000,maxBuffer:33554432});
 assert.equal(x.error,undefined,String(x.error));assert.equal(x.status,0,x.stdout+x.stderr);return x.stdout;};
const npm=path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js');
const metrics={schema:'psc1-installed-development-baseline/1',testedCommit:process.env.GITHUB_SHA,
 package:r,platform:process.platform,arch:process.arch,node:process.version,status:'running',samples:[],
 scope:'small .ps source, repeated cold processes; observational timing, not a performance gate or warm-worker measurement'};
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 const sdk=path.resolve('dist/development-typescript'),resources=JSON.parse(fs.readFileSync(path.join(sdk,'resources.json')));
 run(process.execPath,[npm,'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),
  '--registry','http://127.0.0.1:9',tar,...resources.packages.map(p=>{const file=path.join(sdk,p.tarball);assert.equal(hash(fs.readFileSync(file)),p.sha256);return file;})]);
 const root=path.join(directory,'node_modules/proofscript'),cli=path.join(root,'dist/psc.mjs');
 fs.writeFileSync(path.join(directory,'Main.ps'),'def answer : Nat := 42\n');
 for(let repeat=0;repeat<2;repeat++)for(const [command,target]of[['check','js'],['build','js'],['build','ts']]){
  const output=path.join(directory,'out-'+command+'-'+target+'-'+repeat),started=performance.now();
  const value=JSON.parse(run(process.execPath,[cli,command,'Main.ps','--target',target,...(command==='build'?['--out',output]:[])]));
  assert.equal(value.logicalAdmission,'accepted');
  const sample={command,target,repeat,wallMs:performance.now()-started};
  if(command==='build'){
   const session=JSON.parse(fs.readFileSync(path.join(path.dirname(value.runtimeArtifact),'session.json')));
   sample.events=session.events.map(({role,elapsedMs,status,state})=>({role,elapsedMs,status,state}));
   sample.files=fs.readdirSync(path.dirname(value.runtimeArtifact)).map(name=>({name,bytes:fs.statSync(path.join(path.dirname(value.runtimeArtifact),name)).size}));
  }
  metrics.samples.push(sample);console.log('PSC1_DEVELOPMENT_SAMPLE '+JSON.stringify(sample));
 }
 const driver=path.join(directory,'profile-host.mjs');
 fs.writeFileSync(driver,`import fs from'node:fs';import cp from'node:child_process';import{syncBuiltinESMExports}from'node:module';
 const counts={reads:0,readBytes:0,readMs:0,writes:0,writeBytes:0,children:[]},read=fs.readFileSync,write=fs.writeFileSync,spawn=cp.spawnSync;
 fs.readFileSync=function(...args){const start=performance.now(),b=read.apply(this,args);counts.reads++;counts.readBytes+=typeof b==='string'?Buffer.byteLength(b):b.byteLength;counts.readMs+=performance.now()-start;return b;};
 fs.writeFileSync=function(...args){counts.writes++;counts.writeBytes+=typeof args[1]==='string'?Buffer.byteLength(args[1]):args[1]?.byteLength||0;return write.apply(this,args);};
 cp.spawnSync=function(...args){const start=performance.now(),r=spawn.apply(this,args);counts.children.push({executable:args[0].split('/').at(-1),firstArgument:args[1]?.[0]?.split('/').at(-1),wallMs:performance.now()-start,status:r.status});return r;};
 syncBuiltinESMExports();const {build}=await import('proofscript'),start=performance.now();
 const r=build({entryModule:'Main',sources:[{module:'Main',kind:'ps',text:'def answer : Nat := 42\\n'}],target:'js',out:'profile-out'});
 write('host-profile.json',JSON.stringify({status:r.logicalAdmission,wallMs:performance.now()-start,...counts},null,2)+'\\n');`);
 run(process.execPath,['--cpu-prof','--cpu-prof-dir',path.resolve('dist/development-profile'),driver]);
 metrics.hostProfile=JSON.parse(fs.readFileSync(path.join(directory,'host-profile.json')));
 metrics.status='passed';
}finally{
 fs.mkdirSync('dist/development-profile',{recursive:true});
 fs.writeFileSync('dist/development-profile/baseline.json',JSON.stringify(metrics,null,2)+'\n');
 console.log('PSC1_DEVELOPMENT_BASELINE '+JSON.stringify(metrics));
 fs.rmSync(directory,{recursive:true,force:true});
}
