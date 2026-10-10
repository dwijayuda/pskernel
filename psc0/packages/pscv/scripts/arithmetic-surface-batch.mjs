#!/usr/bin/env node
/** Generate/review 42-row pinned normative class resolution batch. */
import {execFileSync} from 'node:child_process';
import {writeFile,readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {buildArithmeticBatch,reviewArithmeticBatch} from '../src/arithmetic-surface-batch.mjs';

const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const normativeReference=execFileSync('git',['-C',root,'show',
  'HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'],{
  encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000,
});
const [mode,...args]=process.argv.slice(2);
if(mode==='generate'&&args.length===2){
 const [leanPath,planPath]=args.map(x=>path.resolve(x));
 const p=buildArithmeticBatch(normativeReference);
 await writeFile(leanPath,p.generatedSource);
 // Keep only the generated-source digest, not a self-asserted proof flag.
 const {generatedSource,...meta}=p;
 await writeFile(planPath,JSON.stringify(meta)+'\n');
 console.log(JSON.stringify({status:p.status,rows:p.sourceRowCount,
   goals:p.typedQueryCount,planSha256:p.identitySha256,
   verifiedExecutableAuthorized:false}));
}else if(mode==='review'&&args.length===3){
 const [leanPath,transcriptPath,reviewPath]=args.map(x=>path.resolve(x));
 const p=reviewArithmeticBatch({
  normativeReference,
  generatedSource:await readFile(leanPath,'utf8'),
  transcript:await readFile(transcriptPath,'utf8'),
 });
 await writeFile(reviewPath,JSON.stringify(p)+'\n');
 console.log(JSON.stringify({status:p.state,rows:p.observedArithmeticRows,
  observations:p.observedGoals,unresolved:p.unresolvedNormativeIDs,
  identitySha256:p.identitySha256,
  verifiedExecutableAuthorized:false}));
}else {
 throw Error('PSC_PSCV_ARITHMETIC_BATCH_ARGS: generate <lean> <plan> | review <lean> <transcript> <report>');
}
