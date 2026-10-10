#!/usr/bin/env node
/** Review the declarations from the existing qualified P1-J 84-goal run. */
import {execFileSync} from 'node:child_process';
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {selectedArithmeticNames,reviewSelectedArithmeticTypes}
 from '../src/arithmetic-instance-types.mjs';
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const reference=execFileSync('git',['-C',root,'show',
 'HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'],{
  encoding:'utf8',timeout:15000,maxBuffer:2*1024*1024,
});
const [mode,...args]=process.argv.slice(2);
if(mode==='names'&&args.length===3){
 const [leanPath,transcriptPath,namesPath]=args.map(x=>path.resolve(x));
 const {review,names}=selectedArithmeticNames({
  normativeReference:reference,generatedSource:await readFile(leanPath,'utf8'),
  transcript:await readFile(transcriptPath,'utf8'),
 });
 await writeFile(namesPath,JSON.stringify(names)+'\n');
 console.log(JSON.stringify({names:names.length,
  arithmeticObservationSha256:review.identitySha256,
  evidenceState:'names-extracted-from-qualified-Lean-only',
  verifiedExecutableAuthorized:false}));
}else if(mode==='review'&&args.length===5){
 const [leanPath,transcriptPath,namesPath,rawTypesPath,reportPath]=
   args.map(x=>path.resolve(x));
 const report=reviewSelectedArithmeticTypes({
   normativeReference:reference,
   generatedSource:await readFile(leanPath,'utf8'),
   transcript:await readFile(transcriptPath,'utf8'),
   selectedNames:JSON.parse(await readFile(namesPath,'utf8')),
   rawTypes:JSON.parse(await readFile(rawTypesPath,'utf8')),
 });
 await writeFile(reportPath,JSON.stringify(report)+'\n');
 console.log(JSON.stringify({state:report.status,
  importedDeclarations:report.selectedDeclarationCount,
  goals:report.arithmeticGoalsReviewed,
  identitySha256:report.identitySha256,
  verifiedExecutableAuthorized:false}));
}else{
 throw Error('PSC_PSCV_BATCH_DECL_TYPES_ARGS: names <lean> <output> <names.json> | review <lean> <output> <names.json> <raw> <review>');
}
