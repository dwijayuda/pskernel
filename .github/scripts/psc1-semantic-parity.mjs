// Real compiler values, fresh wire identities and semantic edits must match cold service bytes.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import{pathToFileURL}from'node:url';
const root=path.dirname(new URL(import.meta.resolve('proofscript/package.json')).pathname);
const host=path.join(root,'node_modules/@proofscript/compiler/dist/host/host-tools');
const{loadDistribution,resolveEngine}=await import(pathToFileURL(path.join(host,'installed-engine-resolver.mjs')));
const{compilerSourceClosureDigest}=await import(pathToFileURL(path.join(host,'compiler-host-protocol.mjs')));
const fixture=JSON.parse(fs.readFileSync(process.argv[2],'utf8')),distribution=loadDistribution(),results=[];
for(const variant of ['js','ts']){
 const engine=resolveEngine(variant,distribution),cold=await import(pathToFileURL(engine.candidate.path)),warm=await import(pathToFileURL(engine.preparedCandidate.path));
 for(const edit of ['initial','comment','body','refusal','recovery']){
  const sources=fixture.sources.map((source,index)=>({...source,text:source.text+(index===fixture.sources.length-1?'\n-- parity '+edit+'\n':'')}));
  if(edit==='body')sources.at(-1).text=sources.at(-1).text.replace('Result.ok success => success','Result.ok success => false');
  if(edit==='refusal')sources.at(-1).text=sources.at(-1).text.replace('Result.ok success => success','Result.ok success => 42');
  const fields=['psc1-compiler-service/2',variant+'-'+edit,compilerSourceClosureDigest(sources),'lean','ordinary-checked',fixture.entryModule,sources.map(s=>[s.module,s.text]),'io-dispatcher'];
  const request=JSON.stringify(['psc1-unified-compiler-service/2','js',fields]);
  const expected=cold.psCompilerServiceCandidate(request),actual=warm.psCompilerServiceCandidate(request);
  assert.equal(actual,expected,variant+':'+edit);
  const value=JSON.parse(actual);assert.equal(value.status,edit==='refusal'?'refused':'candidate',JSON.stringify(value).slice(0,300));
  results.push({variant,edit,status:value.status,cache:warm.psCompilerPreparationMetrics()});
 }
}
console.log('PSC1_SEMANTIC_PARITY '+JSON.stringify({status:'passed',cases:results.length,results}));
