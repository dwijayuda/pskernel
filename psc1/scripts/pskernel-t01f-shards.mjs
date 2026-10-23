// Same-workflow T01F runtime shards. This script authenticates inputs; only the
// independently executing kernel decides admission and expression judgments.
import {closeSync, copyFileSync, existsSync, mkdirSync, openSync, readFileSync,
  readdirSync, writeFileSync, writeSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {spawn} from 'node:child_process';
import {join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const samples=['','a','é','€','😀','Aé€😀'];
const leanCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const repository='dwijayuda/pskernel';
const routes={
  generated:{producerJob:'generated-dag-integration',shardJob:'t01f-generated-shards',
    workflow:'.github/workflows/psc1-pskernel-expr-v2-integration.yml',
    artifact:'psc1-v2-dag-generated-js',kind:'lean-generated-js',
    primary:'psc1/dist/expr-v2/integration/kernel.js',
    provider:'dist/expr-v2/integration/provider/',kernelName:'kernel'},
  canonical:{producerJob:'psc1-portability',shardJob:'t01f-canonical-shards',
    workflow:'.github/workflows/psc1-pskernel-core-correctness.yml',
    artifact:'psc1-canonical-kernel-qualification',kind:'canonical-ps-generated-js',
    primary:'psc1/dist/pskernel-selfhost/pskernel-core.js',
    provider:'dist/pskernel-selfhost/provider/',kernelName:'pskernel-core'}
};
const fail=message=>{throw Error('PSC1_T01F_SHARD_GATE_FAILED '+message);};
const must=(condition,message)=>{if(!condition)fail(message);};
const same=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
const json=path=>JSON.parse(readFileSync(path,'utf8'));
const digest=path=>{const b=readFileSync(path);return {bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')};};
const digestEqual=(a,b)=>a?.bytes===b?.bytes&&a?.sha256===b?.sha256&&/^[0-9a-f]{64}$/.test(a.sha256);
function files(dir){
  const result=[];
  for(const entry of readdirSync(dir,{withFileTypes:true})){
    const path=join(dir,entry.name);
    if(entry.isDirectory())result.push(...files(path));
    else {must(entry.isFile(),'non-regular artifact entry');result.push(path);}
  }
  return result;
}
function suffix(all,ending){
  const found=all.filter(path=>path===ending||path.endsWith('/'+ending));
  must(found.length===1,'expected exactly one artifact entry: '+ending);
  return found[0];
}
const lines=path=>readFileSync(path,'utf8').split(/\r?\n/u);
function records(log,prefix){return log.filter(line=>line.startsWith(prefix)).map(line=>JSON.parse(line.slice(prefix.length)));}
function oneRecord(log,prefix){const found=records(log,prefix);must(found.length===1,'one marker: '+prefix);return found[0];}
function nativeMarkers(path){
  const log=lines(path);
  must(log.filter(line=>line==='PSC1_T01F_FULL_STRING: PASS authenticClosure=true independentAdmission=true fuel=4096').length===1,'native full PASS');
  must(log.filter(line=>line==='PSC1_T01F_METADATA_PASS declarations=377').length===1,'native metadata377');
  must(log.filter(line=>line==='PSC1_T01F_CLOSURE_PASS requests=294 declarations=377').length===1,'native requests294');
  for(const prefix of ['PSC1_T01F_CASE_PASS ','PSC1_T01F_SINGLETON_PASS '])
    must(same(records(log,prefix),samples),'all six native samples: '+prefix);
}

function authenticate(route,artifactDirectory){
  const config=routes[route];must(config,'known route');
  must(process.env.GITHUB_REPOSITORY===repository,'repository');
  must(/^[0-9a-f]{40}$/.test(process.env.GITHUB_SHA??''),'source SHA');
  must(/^[1-9][0-9]*$/.test(process.env.GITHUB_RUN_ID??''),'run ID');
  must(/^[1-9][0-9]*$/.test(process.env.GITHUB_RUN_ATTEMPT??''),'run attempt');
  must((process.env.GITHUB_WORKFLOW_REF??'').startsWith(repository+'/'+config.workflow+'@'),'workflow route');
  must(/^v22\./u.test(process.version),'Node22');
  const all=files(resolve(artifactDirectory));
  const prefix='psc1-t01f-'+route+'/';
  const provenancePath=suffix(all,prefix+'provenance.json');
  const fixturePath=suffix(all,prefix+'fixture.json');
  const kernelPath=suffix(all,config.primary);
  const provenance=json(provenancePath),fixture=json(fixturePath);
  must(provenance.schema==='psc1-t01f-source-provenance-v1','provenance schema');
  for(const [field,value]of Object.entries({sourceSha:process.env.GITHUB_SHA,
    runId:process.env.GITHUB_RUN_ID,runAttempt:process.env.GITHUB_RUN_ATTEMPT,
    route,job:config.producerJob,leanCommit,kernelFuel:4096,nodeOldSpaceLimitMiB:2048,
    requests:294,metadata:377}))must(provenance[field]===value,'producer '+field);
  must(/^v22\./u.test(provenance.node),'producer Node22');
  must(same(provenance.samples,samples),'producer six samples');
  must(fixture.format==='psc1-authentic-string435-v1'&&fixture.leanVersion==='4.35.0'&&
    fixture.leanCommit===leanCommit,'actual fixture pin');
  must(fixture.declarations.length===294&&fixture.metadata.length===377&&
    same(fixture.samples,samples),'actual fixture full closure');
  must(readFileSync(suffix(all,prefix+'lean-githash.txt'),'utf8').trim()===leanCommit,'producer Lean commit');
  must(readFileSync(suffix(all,prefix+'lean-version.txt'),'utf8').trim()===provenance.leanVersion&&
    /\b4\.35\.0\b/u.test(provenance.leanVersion),'producer Lean version');
  nativeMarkers(suffix(all,prefix+'native.log'));
  const fixtureProducerPath=resolve('test/PsKernelExprV2StringEnvironmentRegression.lean');
  const runnerPath=resolve('scripts/pskernel-expr-v2-string-environment-smoke.mjs');
  const hashes={kernel:digest(kernelPath),fixture:digest(fixturePath),
    fixtureProducer:digest(fixtureProducerPath),generatedRunner:digest(runnerPath),
    provenance:digest(provenancePath),orchestrator:digest(fileURLToPath(import.meta.url)),
    workflow:digest(resolve('..',config.workflow))};
  for(const key of ['kernel','fixture','fixtureProducer','generatedRunner'])
    must(digestEqual(provenance[key],hashes[key]),'current '+key+' digest');
  const manifestPath=suffix(all,config.provider+'artifacts.json');
  const manifest=json(manifestPath);
  for(const[field,value]of Object.entries({schema:'pskernel-core-artifacts-v1',repository,
    sourceSha:process.env.GITHUB_SHA,workflowRun:'https://github.com/'+repository+'/actions/runs/'+process.env.GITHUB_RUN_ID,
    runAttempt:process.env.GITHUB_RUN_ATTEMPT,kind:config.kind,
    leanToolchain:'leanprover/lean4:v4.35.0',leanCommit,typescript:'7.0.2',checkerFuelDefault:4096}))
    must(manifest[field]===value,'provider manifest '+field);
  must(/^v22\./u.test(manifest.node),'provider manifest Node22');
  const expected=[config.kernelName+'.js',config.kernelName+'.ts',config.kernelName+'.d.ts',
    config.kernelName+'.js.map','scripts/pskernel-canonical-provider.mjs',
    'npm-runtime/canonical-admissions-wire.mjs','package.json','README.md',
    ...(route==='canonical'?['canonical-source.tar.gz']:[])].map(x=>config.provider+x).sort();
  must(Array.isArray(manifest.files)&&same(manifest.files.map(x=>x.path).sort(),expected),'complete provider manifest');
  for(const record of manifest.files)
    must(digestEqual(record,digest(suffix(all,record.path))),'provider file digest: '+record.path);
  must(digestEqual(digest(suffix(all,config.provider+config.kernelName+'.js')),hashes.kernel),'provider/primary kernel equality');
  hashes.providerManifest=digest(manifestPath);
  const identity={repository,sourceSha:process.env.GITHUB_SHA,runId:process.env.GITHUB_RUN_ID,
    runAttempt:process.env.GITHUB_RUN_ATTEMPT,workflow:config.workflow,route,
    producerJob:config.producerJob,producerArtifact:config.artifact,leanCommit,
    kernelFuel:4096,nodeOldSpaceLimitMiB:2048,requests:294,metadata:377,samples,hashes};
  return {identity,config,kernelPath,fixturePath,runnerPath};
}

function validateShardLog(path,index,identity){
  const log=lines(path),sample=samples[index];
  must(log.filter(line=>line.startsWith('PSC1_T01F_FULL_STRING_JS: PASS ')).length===0,'shard must not claim full matrix');
  must(same(records(log,'PSC1_T01F_JS_CASE_PASS '),[sample]),'one selected complete case');
  must(same(records(log,'PSC1_T01F_JS_SINGLETON_PASS '),[sample]),'one selected singleton sequence');
  must(log.filter(line=>line.startsWith('PSC1_T01F_JS_ADMIT_BEGIN ')).length===294,'whole closure independently readmitted');
  must(oneRecord(log,'PSC1_T01F_ADMISSION_COMPLETE ').requests===294,'admission294');
  must(oneRecord(log,'PSC1_T01F_METADATA_COMPLETE ').declarations===377,'metadata377');
  const result=oneRecord(log,'PSC1_T01F_STRING_SHARD_JS: PASS ');
  const expected={sampleIndex:index,sample,availableSamples:6,executedSamples:1,samples:1,
    requests:294,metadata:377,declarations:'377',fuel:4096,independentAdmission:true,
    kernelSha256:identity.hashes.kernel.sha256,fixtureSha256:identity.hashes.fixture.sha256,
    harnessSha256:identity.hashes.generatedRunner.sha256};
  for(const[key,value]of Object.entries(expected))must(result[key]===value,'shard result '+key);
  must(Number.isSafeInteger(result.assertions)&&result.assertions===1400,
    'exactly 1400 executed assertions for the selected sample, including repeated prefixes');
  must(Array.isArray(result.measurements)&&result.measurements.length===1,'one complete sample measurement');
  must(result.diagnosticTracing===false,'uninstrumented final shard');
  for(const field of['constructionMs','admissionMs','metadataMs','totalMs'])
    must(Number.isFinite(result[field])&&result[field]>=0,'finite timing '+field);
  const measurement=result.measurements[0];
  must(measurement.sample===sample&&measurement.utf8Bytes===Buffer.byteLength(sample,'utf8'),'selected sample measurement');
  must(Number.isSafeInteger(measurement.owners)&&measurement.owners>0,'owner count');
  for(const field of['ownerAndConstructionMs','totalMs'])
    must(Number.isFinite(measurement[field])&&measurement[field]>=0,'finite sample timing '+field);
  for(const field of['rss','heapTotal','heapUsed','external','arrayBuffers'])
    must(Number.isSafeInteger(measurement.memory?.[field])&&measurement.memory[field]>=0,'complete sample memory '+field);
  for(const field of['arenaNodes','ownedArenaNodes'])
    must(typeof measurement[field]==='string'&&BigInt(measurement[field])>=0n&&
      BigInt(measurement[field]).toString()===measurement[field],'canonical node count '+field);
  return result;
}

async function runShard(route,artifactDirectory,outputDirectory,indexText){
  must(['0','1','2','3','4','5'].includes(indexText),'canonical sample index0..5');
  const index=Number(indexText),auth=authenticate(route,artifactDirectory);
  must(process.env.GITHUB_JOB===auth.config.shardJob,'shard job');
  const out=resolve(outputDirectory);must(!existsSync(out),'fresh shard output');mkdirSync(out,{recursive:true});
  const detached=join(out,'detached');mkdirSync(detached);
  for(const[source,name]of[[auth.kernelPath,'kernel.mjs'],[auth.fixturePath,'fixture.json'],[auth.runnerPath,'runner.mjs']])
    copyFileSync(source,join(detached,name));
  writeFileSync(join(out,'inputs.json'),JSON.stringify(auth.identity,null,2)+'\n');
  const logPath=join(out,'generated.log'),memoryPath=join(out,'generated.memory');
  const descriptor=openSync(logPath,'wx');
  const started=performance.now();
  let result;
  try{
    result=await new Promise((resolveResult,reject)=>{
      const child=spawn('/usr/bin/time',['-f','peak_rss_kib=%M wall_seconds=%e exit_status=%x','-o',memoryPath,
        process.execPath,'--max-old-space-size=2048','--expose-gc','runner.mjs','kernel.mjs','fixture.json',indexText],
        {cwd:detached,env:{...process.env,PATH:'',NODE_OPTIONS:'',PSC1_T01F_TRACE:'0'},stdio:['ignore','pipe','pipe']});
      for(const stream of[child.stdout,child.stderr])stream.on('data',chunk=>{writeSync(descriptor,chunk);process.stdout.write(chunk);});
      child.once('error',reject);child.once('close',(code,signal)=>resolveResult({code,signal}));
    });
  }finally{closeSync(descriptor);}
  must(result.code===0&&result.signal===null,'runtime exit '+JSON.stringify(result));
  const measurement=readFileSync(memoryPath,'utf8').trim();
  must(/^peak_rss_kib=[0-9]+ wall_seconds=[0-9]+(?:\.[0-9]+)? exit_status=0$/u.test(measurement),'successful memory measurement');
  const runtime=validateShardLog(logPath,index,auth.identity);
  const receipt={schema:'psc1-t01f-shard-receipt-v1',status:'pass',identity:auth.identity,
    job:process.env.GITHUB_JOB,node:process.version,sampleIndex:index,sample:samples[index],
    elapsedMs:performance.now()-started,measurement,runtime,
    log:digest(logPath),memory:digest(memoryPath)};
  writeFileSync(join(out,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
  console.log('PSC1_T01F_SHARD_RECEIPT_PASS '+JSON.stringify({route,index,sourceSha:auth.identity.sourceSha}));
}

function aggregate(route,artifactDirectory,shardsDirectory,outputDirectory){
  const auth=authenticate(route,artifactDirectory),all=files(resolve(shardsDirectory));
  const paths=all.filter(path=>path.endsWith('/receipt.json'));
  must(paths.length===6,'exactly six shard receipts');
  const receipts=paths.map(path=>({path,value:json(path)})).sort((a,b)=>a.value.sampleIndex-b.value.sampleIndex);
  for(let index=0;index<6;index++){
    const {path,value}=receipts[index];
    must(value.schema==='psc1-t01f-shard-receipt-v1'&&value.status==='pass','passed shard receipt');
    must(same(value.identity,auth.identity),'same authenticated source/route/run/attempt/input digests');
    must(value.job===auth.config.shardJob&&/^v22\./u.test(value.node),'shard job/runtime');
    must(value.sampleIndex===index&&value.sample===samples[index],'every sample exactly once');
    const dir=resolve(path,'..'),logPath=join(dir,'generated.log'),memoryPath=join(dir,'generated.memory');
    must(digestEqual(value.log,digest(logPath))&&digestEqual(value.memory,digest(memoryPath)),'raw shard evidence digests');
    must(value.measurement===readFileSync(memoryPath,'utf8').trim()&&
      /^peak_rss_kib=[0-9]+ wall_seconds=[0-9]+(?:\.[0-9]+)? exit_status=0$/u.test(value.measurement),'successful shard memory record');
    must(same(value.runtime,validateShardLog(logPath,index,auth.identity)),'rechecked complete shard markers');
  }
  // Shared prefixes intentionally execute in every sample and contribute to this total.
  const executedAssertions=receipts.reduce((total,{value})=>total+value.runtime.assertions,0);
  must(executedAssertions===8400,'exactly 8400 executed assertions across the six selected samples');
  const out=resolve(outputDirectory);must(!existsSync(out),'fresh aggregate output');mkdirSync(out,{recursive:true});
  const result={schema:'psc1-t01f-sharded-qualification-v1',status:'pass',identity:auth.identity,
    job:process.env.GITHUB_JOB,node:process.version,shards:6,samples,requestsPerShard:294,
    metadataPerShard:377,independentAdmissionPerShard:true,completeNegativesPerSample:true,
    singletonSequences:6,assertionsPerSample:1400,executedAssertions,includesRepeatedPrefix:true,
    performanceQualified:false,
    receipts:receipts.map(({path,value})=>({sampleIndex:value.sampleIndex,sample:value.sample,
      receipt:digest(path),measurement:value.measurement,runtime:value.runtime}))};
  writeFileSync(join(out,'qualification.json'),JSON.stringify(result,null,2)+'\n');
  console.log('PSC1_T01F_FULL_STRING_SHARDED_JS: PASS '+JSON.stringify(result));
}

const[mode,route,artifactDirectory,a,b]=process.argv.slice(2);
must(process.argv.length===7,'usage: run route artifactDir outputDir index OR aggregate route artifactDir shardsDir outputDir');
if(mode==='run')await runShard(route,artifactDirectory,a,b);
else if(mode==='aggregate')aggregate(route,artifactDirectory,a,b);
else fail('unknown mode');
