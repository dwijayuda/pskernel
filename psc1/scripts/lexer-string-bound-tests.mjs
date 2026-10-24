// Measured lexer stage only, never a G2/G3 qualification.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {compilerSourceClosureDigest,createCompilerHostSession} from '../host-tools/compiler-host-protocol.mjs';
import {sha,buildTarget,verifyArtifact,runTool,boundedRun} from '../host-tools/generated-target-tools.mjs';
import {validateClosureCounts} from './compiler-closure-contract.mjs';
const out=path.resolve('dist/lexer-string-bound');fs.mkdirSync(out,{recursive:true});
const old=fs.readFileSync('test/fixtures/LexerBeforeStringBound.lean.txt','utf8');
const probe=fs.readFileSync('test/fixtures/LexerStringBoundProbe.lean.txt','utf8');
const ordered=readOwnedCompilerSources('Ps.Syntax.Lexer');
const inputs=readOwnedCompilerSources('Ps.CompilerUnified.Service').filter(r=>[
 'Ps.Syntax.Lexer','Ps.Bridge.CheckedAdmissions','Ps.BackendRust.Runtime','Ps.BackendRust.Expr',
 'Ps.BackendWasm.EncodeExpr','Ps.CompilerUnified.Service'].includes(r.module));
assert.ok(inputs.length>=4);
for(const [id,text]of [['empty',''],['unicode','λ "🙂" -- line\n42'],['escape','"a\\"b"'],['unterminated','"a'],['newline','"a\nb"'],['slash','"a\\']]){
 const file=path.join(out,id+'.input');fs.writeFileSync(file,text);inputs.push({module:id,path:file,text});
}
const records=[];
for(const kind of ['legacy','current']){
 const dir=path.join(out,kind);fs.mkdirSync(dir,{recursive:true});
 const sources=ordered.map(({module,text})=>({module,kind:'lean',text:module==='Ps.Syntax.Lexer'&&kind==='legacy'?old:text}));
 sources.push({module:'Probe',kind:'lean',text:probe});
 const digest=compilerSourceClosureDigest(sources),id='lexer-'+kind;
 const wire=['psc1-unified-compiler-service/2','rust',['psc1-compiler-service/1',id,digest,'lean','ordinary-checked','Probe',sources.map(r=>[r.module,r.text])]];
 const input=path.join(dir,'request.json'),output=path.join(dir,'candidate.json');fs.writeFileSync(input,JSON.stringify(wire));
 const seed=runTool(path.resolve('.lake/build/bin/psc1_unified_service_seed'),['rust',input,output],{logDirectory:dir});
 const candidate=JSON.parse(fs.readFileSync(output));assert.equal(candidate.status,'candidate',JSON.stringify(candidate));
 for(const [key,value]of Object.entries({requestId:id,sourceClosureDigest:digest,grammar:'lean',assurance:'ordinary-checked',target:'rust',candidateOnly:true,admission:'not-run'}))assert.equal(candidate[key],value);
 assert.deepEqual(candidate.publicNames,['psCompilerServiceCandidate']);
 const sourceCount=candidate.origins.reduce((n,row)=>n+row[3].reduce((k,item)=>k+item[4].length,0),0);
 validateClosureCounts({assurance:'ordinary-checked',sourceCoreDeclarations:candidate.sourceDeclarations,coreDeclarations:candidate.logicalDeclarations,partialNames:candidate.partialNames},sourceCount,'ordinary-checked');
 const admitted=createCompilerHostSession({requestId:id,target:'rust',sources,canonicalAdmissions:candidate.admissionRequest.admissions,checkerExecutable:path.resolve('.lake/build/bin/psc1_independent_checker')}).admit(JSON.stringify(candidate.admissionRequest));
 assert.equal(admitted.accepted,true);
 const artifact=buildTarget({target:'rust',source:candidate.source,directory:path.join(dir,'service'),service:true,serviceKind:'unified',publicNames:candidate.publicNames});
 const m=verifyArtifact(artifact.file,artifact.sha256),observations=[];
 for(const row of inputs){
  const outputFile=path.join(dir,'observed-'+observations.length+'.txt');
  const event=boundedRun(path.join(m.directory,m.executable),[path.resolve(row.path),outputFile],{logDirectory:dir,timeoutMs:240000});
  assert.equal(event.error,null);assert.equal(event.status,0);
  const value=fs.readFileSync(outputFile,'utf8');
  if(row.module.startsWith('Ps.'))assert.match(value,/^[1-9][0-9]*$/,'compiler source must lex');
  observations.push({module:row.module,inputSha256:sha(row.text),bytes:Buffer.byteLength(row.text),value,elapsedMs:event.elapsedMs,maxRssKiB:event.maxRssKiB,peakTreeRssKiB:event.peakTreeRssKiB});
 }
 records.push({kind,sourceClosureDigest:digest,admissionSha256:admitted.admissionsDigest,checkerCommit:admitted.checkerCommit,artifactSha256:artifact.sha256,seedEvent:seed.event,observations});
}
assert.deepEqual(records[0].observations.map(r=>[r.module,r.inputSha256,r.value]),records[1].observations.map(r=>[r.module,r.inputSha256,r.value]));
const q={schema:'psc1-lexer-string-bound-stage/1',testedCommit:process.env.GITHUB_SHA,status:'passed',allInputProof:'LexerStringBoundTests.exact_original',oldLexerSha256:sha(old),currentLexerSha256:sha(ordered.at(-1).text),records,qualification:false,scope:'Rust generated lexer stage on real compiler source files and malformed literals; not whole G2 or a fixed point'};
fs.writeFileSync(path.join(out,'qualification.json'),JSON.stringify(q,null,2)+'\n');
console.log('PSC1_LEXER_STRING_BOUND_STAGE: '+JSON.stringify(q));
