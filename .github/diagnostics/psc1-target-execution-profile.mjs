// Profile the current bounded-token compiler: final 30 seconds of a 220-second G2 replay, not the end of the 1800-second request.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
fs.mkdirSync('diagnosis',{recursive:true});
console.log('PSC1_PROFILE_SOURCE: current bounded-token TS artifact; final 30 seconds of bounded 220s replay; diagnostic only');
function artifact(target,expected){
 const file=files.find(p=>p.endsWith('/G1-service/artifact.json')&&JSON.parse(fs.readFileSync(p,'utf8')).target===target);
 assert.ok(file);assert.equal(sha(fs.readFileSync(file)),expected);const m=JSON.parse(fs.readFileSync(file,'utf8')),directory=path.dirname(file);
 const verify=()=>{assert.equal(sha(fs.readFileSync(file)),expected);for(const f of m.files){assert.match(f.path,/^[a-zA-Z0-9_.-]+$/);const p=path.join(directory,f.path);assert.ok(fs.lstatSync(p).isFile()&&!fs.lstatSync(p).isSymbolicLink());const b=fs.readFileSync(p);assert.equal(b.length,f.bytes);assert.equal(sha(b),f.sha256);}};
 verify();return{m,directory,verify};
}
const ts=artifact('ts','3d491fac102424409c9359f702b1b61354bc3acd9aacbe00668200e941c4ca65');
const request=files.find(p=>p.endsWith('/G2-self.request.json')&&p.includes('generated-ts-compiler'));assert.ok(request);
assert.equal(sha(fs.readFileSync(request)),'50cedd8dd842d2d64723696097fff3c200b560ff1996cba7f929d1ddc227cf08');
const qualification=JSON.parse(fs.readFileSync(path.join(path.dirname(ts.directory),'qualification.json'),'utf8'));
assert.equal(qualification.sourceClosureDigest,'b5e496cc6734849116a7dd113257853d755271b20a44f419750993cd99069217');
assert.equal(ts.m.sourceSha256,qualification.bootstrap.sourceSha256);
console.log('PSC1_TS_EXECUTING_RECEIPT: '+JSON.stringify({bootstrap:qualification.bootstrap,serviceArtifact:qualification.serviceArtifact,generations:qualification.generations.map(g=>({generation:g.generation,observations:g.observations})),sourceClosureDigest:qualification.sourceClosureDigest,events:qualification.events,targetPlans:qualification.targetPlans}));

const originalFile=path.resolve(ts.directory,ts.m.executable),original=fs.readFileSync(originalFile,'utf8');

const startText='((__ps_s, __ps_b, __ps_e) => {';
const spans=[];let search=0;
while(true){
 const start=original.indexOf(startText,search);if(start<0)break;
 let depth=0,end=-1;
 for(let i=start+startText.length-1;i<original.length;i++){
  if(original[i]==='{')depth++;else if(original[i]==='}'&&--depth===0){end=i+2;break;}
 }
 assert.ok(end>start&&original[end-1]===')');
 spans.push({start,end,body:original.slice(start,end)});search=end;
}
assert.ok(spans.length>0);
const legacy=spans[0].body;
for(const span of spans)assert.equal(span.body.replace(/\s/g,''),legacy.replace(/\s/g,''));
let modified=original;
for(const span of spans.toReversed())modified=modified.slice(0,span.start)+'__ps$stringExtract'+modified.slice(span.end);
const helper=[
'const diagnosticExtractStats={calls:0,cacheHits:0,fastHits:0,prefixUtf16Skipped:0,fallbacks:0};',
'function __ps$stringExtract(text,start,end){',
' const stats=diagnosticExtractStats;stats.calls++;if(start>=end)return "";',
' const view=__ps$lastUtf8?.text===text?__ps$lastUtf8:__ps$previousUtf8?.text===text?__ps$previousUtf8:undefined;',
' if(view){stats.cacheHits++;if(start>=0n&&end<=view.size){const begin=view.positions[Number(start)],stop=view.positions[Number(end)];',
'  if(begin>0&&stop>0){stats.fastHits++;stats.prefixUtf16Skipped+=begin-1;return text.slice(begin-1,stop-1);}',
' }}',
' stats.fallbacks++;return ('+legacy+')(text,start,end);',
'}',
'export {diagnosticExtractStats};'
].join('\n');
modified+='\n'+helper;
console.log('PSC1_EXTRACT_REPLACEMENTS: '+JSON.stringify({callsites:spans.length,legacyBytes:legacy.length,scope:'derived copy only; cache hit and two valid boundaries; exact legacy fallback; no new cache entry'}));
const candidate=path.resolve(ts.directory,'diagnostic-string-extract.js');fs.writeFileSync(candidate,modified);
const runner=path.resolve('diagnosis/replay.mjs');
fs.writeFileSync(runner,[
"import fs from 'node:fs';import{pathToFileURL}from'node:url';",
"const api=await import(pathToFileURL(process.argv[2]).href);",
"const input=fs.readFileSync(process.argv[3],'utf8');",
"const output=api.psCompilerTsServiceCandidate(input);",
"if(typeof output!=='string'||Buffer.byteLength(output)>134217728)throw Error('response bound');",
"fs.writeFileSync(process.argv[4],output);if(api.diagnosticExtractStats)console.error('PSC1_EXTRACT_STATS: '+JSON.stringify(api.diagnosticExtractStats));"].join('\n'));
const requests=files.filter(p=>/\/G1-(?!bootstrap)[^/]+\.request\.json$/.test(p)&&p.includes('generated-ts-compiler')).sort();
assert.equal(requests.length,10);
const results=[];
for(let round=0;round<2;round++){
 for(const input of requests){
  const id=path.basename(input,'.request.json'),row={round,id};
  for(const mode of (round===0?['original','indexedExtract']:['indexedExtract','original'])){
   const directory=path.resolve('diagnosis',String(round),id,mode),output=path.join(directory,'response.json');
   const r=spawnSync('python3',['.github/diagnostics/bounded-process.py',JSON.stringify({
    command:[process.execPath,runner,mode==='original'?originalFile:candidate,path.resolve(input),output],
    directory,timeoutMs:240000,maxBuffer:32*1024*1024})],{encoding:'utf8',timeout:245000,killSignal:'SIGKILL',maxBuffer:1024*1024});
   assert.equal(r.status,0,r.stderr);const execution=JSON.parse(r.stdout);
   assert.equal(execution.status,0,JSON.stringify(execution));assert.equal(execution.error,null);
   row[mode]={...execution,responseSha256:sha(fs.readFileSync(output))};
  }
  assert.equal(row.original.responseSha256,row.indexedExtract.responseSha256);
  console.log('PSC1_STRING_EXTRACT_REPLAY: '+JSON.stringify(row));results.push(row);
 }
}
ts.verify();
const receipt={schema:'psc1-ts-cached-extract-diagnostic/1',originalManifestSha256:sha(fs.readFileSync(path.join(ts.directory,'artifact.json'))),
 originalExecutableSha256:sha(original),derivedExecutableSha256:sha(modified),workload:'ten actual stored G1 compiler corpus requests; each twice; alternating fresh-process order',
 originalElapsedMs:results.reduce((s,r)=>s+r.original.elapsedMs,0),candidateElapsedMs:results.reduce((s,r)=>s+r.indexedExtract.elapsedMs,0),
 results,qualification:false,adoption:'not-run',admission:'not-run',scope:'unadopted runtime hypothesis only; no G2 performance claim'};
fs.writeFileSync('diagnosis/string-extract-receipt.json',JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_STRING_EXTRACT_DIAGNOSTIC: '+JSON.stringify(receipt));

const directory=path.resolve('diagnosis/self-request'),output=path.join(directory,'response.json');
const started=Date.now();
const replay=spawnSync('python3',['.github/diagnostics/bounded-process.py',JSON.stringify({
 command:[process.execPath,runner,candidate,path.resolve(request),output],directory,timeoutMs:240000,maxBuffer:32*1024*1024
})],{encoding:'utf8',timeout:245000,killSignal:'SIGKILL',maxBuffer:1024*1024});
assert.equal(replay.status,0,replay.stderr);
const execution=JSON.parse(replay.stdout),produced=fs.existsSync(output);
let identity;
if(produced){
 const value=JSON.parse(fs.readFileSync(output,'utf8'));
 identity={status:value.status,sourceClosureDigest:value.sourceClosureDigest,sourceSha256:typeof value.source==='string'?sha(value.source):null,
 originalIrSha256:value.originalIr?sha(JSON.stringify(value.originalIr)):null,specializedIrSha256:value.specializedIr?sha(JSON.stringify(value.specializedIr)):null};
 if(value.status==='candidate'){
  assert.equal(identity.sourceClosureDigest,qualification.sourceClosureDigest);
  assert.equal(identity.sourceSha256,qualification.bootstrap.sourceSha256);
  assert.equal(identity.originalIrSha256,qualification.bootstrap.originalIrSha256);
  assert.equal(identity.specializedIrSha256,qualification.bootstrap.specializedIrSha256);
 }
}
console.log('PSC1_INDEXED_EXTRACT_G2_DIAGNOSTIC: '+JSON.stringify({execution,identity,produced,wallMs:Date.now()-started,
 stderr:fs.readFileSync(path.join(directory,'tool.stderr.txt'),'utf8').slice(-4000),qualification:false,adoption:'not-run',admission:'not-run'}));
ts.verify();
