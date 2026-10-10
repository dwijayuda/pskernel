#!/usr/bin/env node
/** P1-M explicit dictionary terms from exact prior P1-J real Lean response. */
import {execFileSync} from 'node:child_process';
import {readFile,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {prepareDictionaryApplications,reviewDictionaryApplications}
 from '../src/explicit-dictionary-edges.mjs';
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const normativeReference=execFileSync('git',['-C',root,'show',
 'HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'],{
 encoding:'utf8',timeout:15000,maxBuffer:2*1024*1024,
});
const [mode,...args]=process.argv.slice(2);
if(mode==='generate'&&args.length===4){
 const [originalLean,transcript,outLean,outMeta]=args.map(x=>path.resolve(x));
 const p=prepareDictionaryApplications({
  normativeReference,source:await readFile(originalLean,'utf8'),
  transcript:await readFile(transcript,'utf8'),
 });
 await writeFile(outLean,p.source);
 const {source,...meta}=p;
 await writeFile(outMeta,JSON.stringify(meta)+'\n');
 console.log(JSON.stringify({status:p.state,attempted:p.attemptedExplicitApplications,
  specializedExcluded:p.excludedSpecializedGenericInstances,
  identitySha256:p.identitySha256,certificateAuthorized:false}));
}else if(mode==='review'&&args.length===5){
 const [originalLean,transcript,generatedLean,leanOutput,outReview]=
   args.map(x=>path.resolve(x));
 const r=reviewDictionaryApplications({
  normativeReference,
  originalLean:await readFile(originalLean,'utf8'),
  originalTranscript:await readFile(transcript,'utf8'),
  generatedSource:await readFile(generatedLean,'utf8'),
  leanCheckOutput:await readFile(leanOutput,'utf8'),
 });
 await writeFile(outReview,JSON.stringify(r)+'\n');
 console.log(JSON.stringify({status:r.status,
  attempted:r.attemptedExplicitApplications,
  specializedExcluded:r.excludedSpecializedGenericInstances,
  identitySha256:r.identitySha256,
  verifiedExecutableAuthorized:false}));
}else{
 throw Error('PSC_PSCV_DICTIONARY_EDGE_ARGS: generate <batchLean> <batchOutput> <explicitLean> <manifest> | review <batchLean> <batchOutput> <explicitLean> <leanOutput> <review>');
}
