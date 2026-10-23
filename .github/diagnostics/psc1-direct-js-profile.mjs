// Executes only retained generated compiler bytes on its captured real G2 workload.
// Sampling overhead makes this diagnostic ineligible for performance qualification.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';
import {sha,boundedRun,verifyArtifact} from '../../psc1/host-tools/generated-target-tools.mjs';
import {compilerSourceClosureDigest} from '../../psc1/host-tools/compiler-host-protocol.mjs';
import {compilerRequestLimit} from '../../psc1/scripts/selfhost-qualification-profiles.mjs';
const expected=JSON.parse(fs.readFileSync('../.github/diagnostics/psc1-direct-js-profile.json'));
assert.equal(expected.schema,'psc1-direct-generated-profile-request/1');assert.equal(process.version,'v22.23.3');
const inputRoot=path.resolve('../input/direct-js'),out=path.resolve('dist/direct-js-profile');
function walk(root){return fs.readdirSync(root,{withFileTypes:true}).flatMap(e=>{const f=path.join(root,e.name);assert.equal(e.isSymbolicLink(),false);return e.isDirectory()?walk(f):[f];});}
const reports=walk(inputRoot).filter(f=>path.basename(f)==='qualification.json');assert.equal(reports.length,1);
const root=path.dirname(reports[0]);
fs.mkdirSync(out,{recursive:true});
const report=JSON.parse(fs.readFileSync(path.join(root,'qualification.json')));
assert.equal(report.target,'js');assert.equal(report.testedCommit,expected.requestCommit);
assert.equal(report.status,'failed');assert.deepEqual(report.generations.map(g=>g.generation),[1]);
assert.equal(report.sourceClosureDigest,expected.sourceClosureDigest);
assert.equal(report.generations[0].logicalAdmission,'accepted');
assert.equal(report.generations[0].observations.length,10);
const bootstrap=JSON.parse(fs.readFileSync(path.join(root,'G1-bootstrap.request.json')));
const sources=bootstrap[6].map(([module,text])=>({module,kind:bootstrap[3],text}));
assert.equal(compilerSourceClosureDigest(sources),expected.sourceClosureDigest);
for(const [i,s] of sources.entries()){
 const r=report.sourceInventory[i];assert.equal(r.module,s.module);
 assert.equal(r.bytes,Buffer.byteLength(s.text));assert.equal(r.sha256,sha(s.text));
}
for(const file of ['scripts/generated-target-runner.mjs','scripts/selfhost-qualification-profiles.mjs',
 'host-tools/generated-target-tools.mjs','host-tools/generated-target-profiles.mjs',
 'host-tools/generated-wasm-transport.mjs','scripts/bounded-process.py']){
 const r=report.tools.find(t=>t.file.endsWith('/'+file));assert.ok(r);assert.equal(sha(fs.readFileSync(file)),r.sha256);
}
const artifact=path.join(root,'G1-service/artifact.json'),m=verifyArtifact(artifact,expected.serviceSha256);
assert.equal(m.target,'js');assert.equal(m.service,true);

const source=fs.readFileSync(path.join(root,'G1-service/module.js'),'utf8');assert.equal(sha(source),m.sourceSha256);
const sourceShape={bytes:Buffer.byteLength(source),generators:(source.match(/function\*/g)||[]).length,
 generatorLetWrappers:(source.match(/yield\* \(function\*/g)||[]).length,
 lazyViewGetters:source.split('})(__ps$utf8Known(').length-1,
 invokeSites:source.split('yield* __ps$invoke(').length-1,tailInvokeSites:source.split('yield* __ps$tailInvoke(').length-1,directDriverSites:source.split('(yield { fn:').length-1};
console.log('PSC1_ACTUAL_JS_EMISSION_SHAPE: '+JSON.stringify(sourceShape));
const selected=source.split('\n').map((text,index)=>({text,line:index+1})).filter(r=>/^function(?:\*)? (?:__ps\$impl\$)?psStringEqFromWithFuel/.test(r.text));
console.log('PSC1_ACTUAL_STRING_EQUAL_WORKER: '+JSON.stringify(selected.map(r=>({...r,text:r.text.slice(0,5000)}))));
fs.writeFileSync(path.join(out,'emission-shape.json'),JSON.stringify({sourceShape,selected},null,2)+'\n');
const request=path.join(root,'G2-self.request.json');assert.equal(sha(fs.readFileSync(request)),expected.requestSha256);
assert.equal(JSON.parse(fs.readFileSync(request))[1],'G2-self');assert.equal(fs.existsSync('.lake/build/bin/psc1_target_service_seed'),false);
const limits=compilerRequestLimit('performance-240s','G2-self');assert.equal(limits.timeoutMs,240000);
const output=path.join(out,'G2-self.candidate.json');
const args=['--prof','--logfile='+path.join(out,'v8.log'),path.resolve('scripts/generated-target-runner.mjs'),
 artifact,expected.serviceSha256,request,output,'performance-240s'];
const result=boundedRun(process.execPath,args,{...limits,logDirectory:path.join(out,'actual-G2-process')});
verifyArtifact(artifact,expected.serviceSha256);assert.equal(sha(fs.readFileSync(request)),expected.requestSha256);
const logs=fs.readdirSync(out).filter(f=>f.endsWith('.log'));assert.ok(logs.length>0,'V8_PROFILE_LOG_MISSING');
const processed=[];
for(const file of logs){
 const r=boundedRun(process.execPath,['--prof-process',path.join(out,file)],{timeoutMs:120000,logDirectory:path.join(out,'processed-'+processed.length)});
 fs.writeFileSync(path.join(out,file+'.txt'),r.stdout);processed.push({file,status:r.status,error:r.error});
 const lines=r.stdout.split(String.fromCharCode(10));const summary={};
 for(const [section,count] of [['JavaScript',30],['Summary',15],['Bottom up (heavy) profile',40]]){
  const at=lines.findIndex(l=>l.includes('['+section+']'));assert.ok(at>=0,section);summary[section]=lines.slice(at,at+count);
 }
 console.log('PSC1_DIRECT_JS_CPU_SECTIONS: '+JSON.stringify(summary));
}
const receipt={schema:'psc1-direct-generated-cpu-diagnosis/1',testedCommit:process.env.GITHUB_SHA,
 source:expected,retainedG1:{sourceSha256:m.sourceSha256,artifactSha256:expected.serviceSha256,
 independentlyAdmitted:true,observations:10},requestSha256:expected.requestSha256,
 profile:'performance-240s',samplingOverhead:true,qualification:false,nativeDelegation:false,
 execution:{elapsedMs:result.elapsedMs,status:result.status,signal:result.signal,error:result.error,
 maxRssKiB:result.maxRssKiB,peakTreeRssKiB:result.peakTreeRssKiB},processed};
fs.writeFileSync(path.join(out,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_DIRECT_JS_CPU_DIAGNOSIS: '+JSON.stringify(receipt));
