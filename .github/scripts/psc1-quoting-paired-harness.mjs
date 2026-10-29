// Paired transport comparison: same generated graph and prepared-state policies.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{pathToFileURL}from'node:url';
import{checkCanonicalAdmissions}from'proofscript';import{createTypedIo}from'proofscript/io';
const [variant,graphRoot,manifestFile,manifestSha,repo,fixtureFile]=process.argv.slice(2),load=file=>import(pathToFileURL(path.join(repo,file)));
const nativeModule=await load('host-tools/prepared-engine.mjs'),portableModule=await load('host-tools/quote-portable-reference.mjs');
const{compilerSourceClosureDigest}=await load('host-tools/compiler-host-protocol.mjs');
const options={root:graphRoot,manifestFile,manifestSha256:manifestSha,variant,outputs:true};
const engines={native:await nativeModule.loadPreparedEngine(options),portable:await portableModule.loadPreparedEngine(options)};
const fixture=JSON.parse(fs.readFileSync(fixtureFile)),rows=[];
for(const [index,edit]of['initial','body','comment'].entries()){
 const sources=fixture.sources.map((s,i)=>({...s,text:(i===fixture.sources.length-1&&edit!=='initial'?s.text.replace('Result.ok success => success','Result.ok success => if success then true else false'):s.text)+(i===fixture.sources.length-1?'\n-- paired '+edit+'\n':'')}));
 const fields=['psc1-compiler-service/2','paired-'+variant+'-'+edit,compilerSourceClosureDigest(sources),'lean','ordinary-checked',fixture.entryModule,sources.map(s=>[s.module,s.text]),'io-dispatcher'];
 const input=JSON.stringify(['psc1-unified-compiler-service/2','js',fields]),outputs={},times={},metrics={};
 for(const mode of(index%2?['portable','native']:['native','portable'])){
  const start=performance.now();outputs[mode]=engines[mode].candidate(input);times[mode]=performance.now()-start;metrics[mode]=engines[mode].metrics();
 }
 assert.equal(outputs.native,outputs.portable);assert.ok(metrics.native.nativeQuoteCalls>0);assert.equal(metrics.portable.nativeQuoteCalls,0);
 for(const mode of['native','portable']){
  const candidate=JSON.parse(outputs[mode]);assert.equal(candidate.status,'candidate');assert.equal((await checkCanonicalAdmissions(candidate.admissionRequest.admissions)).accepted,true);
  const folder=path.resolve(variant+'-'+edit+'-'+mode);fs.mkdirSync(folder);fs.writeFileSync(path.join(folder,'input.json'),'[{"text":"A","count":2},{"text":"\\uD83D\\uDE00","count":-4}]');
  const target=path.join(folder,'target.mjs');fs.writeFileSync(target,candidate.source);
  const fd=fs.openSync(path.join(folder,'stdout.txt'),'w'),io=createTypedIo({abi:'psc1-node-linux-string-io/1',capabilities:['readUtf8','writeUtf8','writeLine'],required:['readUtf8','writeUtf8','writeLine'],root:folder,maxFileBytes:512,maxLineBytes:128,inputFd:0,outputFd:fd});
  try{assert.equal((await import(pathToFileURL(target))).run(JSON.stringify(['transform','input.json','output.json']),s=>io.execute(s)),true);}
  finally{io.close();try{fs.closeSync(fd);}catch(error){if(error.code!=='EBADF')throw error;}}
  assert.equal(fs.readFileSync(path.join(folder,'output.json'),'utf8'),fixture.expected.output);assert.equal(fs.readFileSync(path.join(folder,'stdout.txt'),'utf8'),fixture.expected.stdout);
 }
 rows.push({edit,candidateMs:times,savedMs:times.portable-times.native,metrics,exactBytes:true,independentAdmissions:2,applicationExecutions:2});
}
console.log('PSC1_QUOTE_PAIRED_VARIANT '+JSON.stringify({variant,status:'passed',rows,maxRssKiB:process.resourceUsage().maxRSS}));
