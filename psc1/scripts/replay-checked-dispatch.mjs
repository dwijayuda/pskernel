// Test-only replay of exact unpublished candidate bytes. This never relaxes the
// qualified-artifact reader or treats a failed producer as a qualified compiler.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {spawnSync} from 'node:child_process';
const repo='dwijayuda/pskernel',requestFile='.github/qualification-requests/psc1-checked-dispatch-replay.json';
const request=JSON.parse(fs.readFileSync('../'+requestFile)),event=JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH));
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const run=(command,args,options={})=>{const r=spawnSync(command,args,{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,...options});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
assert.deepEqual(Object.keys(request).sort(),['schema','branch','parentCommit','action','input'].sort());
assert.equal(request.schema,'psc1-checked-dispatch-replay-request/1');
assert.equal(request.action,'qualify-exact-unpublished-candidate');
assert.equal(request.branch,'qualification/psc1-checked-dispatch-20261026');
assert.equal(process.env.GITHUB_REF,'refs/heads/'+request.branch);
assert.equal(request.parentCommit,event.before);assert.equal(event.after,process.env.GITHUB_SHA);
assert.equal(run('git',['rev-parse','HEAD^']).trim(),request.parentCommit);
assert.deepEqual(run('git',['diff','--name-only','-z',request.parentCommit,process.env.GITHUB_SHA]).split('\0').filter(Boolean),[requestFile]);
const input=request.input;
assert.deepEqual(Object.keys(input).sort(),['runId','jobId','artifactId','artifactSha256','sourceCommit','rootSha256','rootBytes'].sort());
for(const key of ['runId','jobId','artifactId','rootBytes'])assert.ok(Number.isSafeInteger(input[key])&&input[key]>0);
for(const key of ['artifactSha256','rootSha256'])assert.match(input[key],/^[a-f0-9]{64}$/);
assert.match(input.sourceCommit,/^[a-f0-9]{40}$/);
const api=resource=>JSON.parse(run('gh',['api','repos/'+repo+'/'+resource]));
const producer=api('actions/runs/'+input.runId),artifact=api('actions/artifacts/'+input.artifactId),job=api('actions/jobs/'+input.jobId);
assert.equal(producer.status,'completed');assert.equal(producer.head_sha,input.sourceCommit);
assert.equal(artifact.workflow_run.id,input.runId);assert.equal(artifact.workflow_run.head_sha,input.sourceCommit);
assert.equal(artifact.expired,false);assert.equal(artifact.digest,'sha256:'+input.artifactSha256);
assert.equal(job.run_id,input.runId);
assert.equal(job.steps.find(step=>step.name==='Assemble unchanged qualified G3s and actual kernels')?.conclusion,'success');
run('git',['merge-base','--is-ancestor',input.sourceCommit,'HEAD']);
const changed=run('git',['diff','--name-only',input.sourceCommit,'HEAD']).trim().split('\n').filter(Boolean);
for(const file of changed)assert.ok(
 file==='psc1/scripts/checked-dispatch-installed.mjs'||
 file==='psc1/scripts/replay-checked-dispatch.mjs'||
 file==='.github/workflows/psc1-checked-dispatch-replay.yml'||
 file===requestFile||
 file==='psc1/AI_WORK_STATE.md'||
 file.startsWith('psc1/docs/'),
 'production source changed; assemble a fresh candidate instead: '+file);
const temporary=path.resolve(process.env.RUNNER_TEMP,'psc1-dispatch-replay');fs.mkdirSync(temporary,{recursive:true});
const zip=path.join(temporary,'candidate.zip'),fd=fs.openSync(zip,'wx');
try{
 const result=spawnSync('gh',['api','repos/'+repo+'/actions/artifacts/'+input.artifactId+'/zip'],{stdio:['ignore',fd,'pipe'],encoding:'utf8',timeout:240000,maxBuffer:1024*1024});
 assert.equal(result.error,undefined,String(result.error));assert.equal(result.status,0,result.stderr);
}finally{fs.closeSync(fd);}
assert.ok(fs.statSync(zip).size<1024*1024*1024);assert.equal(sha(fs.readFileSync(zip)),input.artifactSha256);
const entries=run('unzip',['-Z1',zip]).split('\n').filter(Boolean);
for(const name of entries)assert.ok(!path.posix.isAbsolute(name)&&!name.includes('\\')&&!name.split('/').includes('..'));
const extraction=path.join(temporary,'input');fs.mkdirSync(extraction);
run('unzip',['-q',zip,'-d',extraction]);
const manifests=entries.filter(name=>name.endsWith('package-receipt.json'));assert.equal(manifests.length,1);
const candidate=path.dirname(path.join(extraction,manifests[0])),out=path.resolve('dist/slim-universal');
assert.ok(out.startsWith(path.resolve('dist')+path.sep));assert.equal(fs.existsSync(out),false);fs.mkdirSync(out,{recursive:true});
for(const name of ['tarballs','package-receipt.json','compiler-kernel-admission.json'])fs.cpSync(path.join(candidate,name),path.join(out,name),{recursive:true,dereference:false});
const receipt=JSON.parse(fs.readFileSync(path.join(out,'package-receipt.json')));
assert.equal(receipt.sourceCommit,input.sourceCommit);assert.equal(receipt.version,'0.1.0-psc1.7');
assert.equal(receipt.compilerSourceClosureDigest,'073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9');
const root=path.join(out,'tarballs',receipt.tarball),bytes=fs.readFileSync(root);
assert.equal(bytes.length,input.rootBytes);assert.equal(sha(bytes),input.rootSha256);assert.equal(receipt.sha256,input.rootSha256);
const snapshot=path.join(temporary,'root');fs.mkdirSync(snapshot);
run('tar',['xzf',root,'-C',snapshot]);
const distribution=JSON.parse(fs.readFileSync(path.join(snapshot,'package/UNIVERSAL_DISTRIBUTION.json')));
const productionFiles=distribution.hostFiles.filter(pin=>/^(host-tools|npm-cli|scripts)\//.test(pin.path));
for(const pin of productionFiles){
 assert.equal(sha(fs.readFileSync(pin.path)),pin.sha256,'packed production file differs from current source: '+pin.path);
 assert.equal(sha(fs.readFileSync(path.join(snapshot,'package',pin.path))),pin.sha256);
}
const crosscheck=JSON.parse(fs.readFileSync(path.join(out,'compiler-kernel-admission.json')));
assert.equal(crosscheck.admissionsSha256,'a1c75ace20b2071d66ea4a9263b98980c39bea92b5b4f459d26978f46c66f213');
assert.equal(crosscheck.agreement,true);
for(const provider of ['wasm','native']){assert.equal(crosscheck.providers[provider].accepted,true);assert.equal(crosscheck.providers[provider].invalidTypeRejected,true);}
const provenance={schema:'psc1-unpublished-candidate-replay/1',testedCommit:process.env.GITHUB_SHA,status:'identity-verified-tests-pending',input,changed,
 productionFilesIdentical:productionFiles.map(pin=>({path:pin.path,sha256:pin.sha256})),
 fullCompilerKernelEvidence:{producerRun:input.runId,producerJob:input.jobId,assemblyStep:'success',admissionsSha256:crosscheck.admissionsSha256,bytes:crosscheck.bytes,records:crosscheck.admissionRecords},
 originalProducerConclusion:producer.conclusion,originalProducerNotRelabeled:true,qualifiedCompilerReaderUnchanged:true};
fs.writeFileSync(path.join(out,'replay-provenance.json'),JSON.stringify(provenance,null,2)+'\n');
console.log('PSC1_CANDIDATE_REPLAY_IDENTITY '+JSON.stringify({sourceCommit:input.sourceCommit,testedCommit:process.env.GITHUB_SHA,rootSha256:input.rootSha256,productionFiles:productionFiles.length,sourceDiff:changed}));
