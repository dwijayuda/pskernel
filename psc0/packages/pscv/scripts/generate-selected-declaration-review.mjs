#!/usr/bin/env node
/** Cloud review of pinned Lean source-module and type observations. */
import {execFileSync} from 'node:child_process';
import {readFile,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {reviewSelectedDeclarationTypes} from '../src/selected-declaration-review.mjs';
if(process.argv.length!==6)throw Error('PSC_PSCV_DECL_TYPES_ARGS');
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const git=p=>execFileSync('git',['-C',root,'show','HEAD:'+p],
 {encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const report=reviewSelectedDeclarationTypes({
 normativeReference:git('pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'),
 typedSource:git('PSCVL/TypedInstanceWitness.lean'),
 concreteSource:git('PSCVL/ConcreteDictionaryWitness.lean'),
 typedTranscript:await readFile(path.resolve(process.argv[2]),'utf8'),
 concreteTranscript:await readFile(path.resolve(process.argv[3]),'utf8'),
 rawTypes:JSON.parse(await readFile(path.resolve(process.argv[4]),'utf8')),
});
await writeFile(path.resolve(process.argv[5]),JSON.stringify(report)+'\n');
console.log(JSON.stringify({status:report.status,
  declarations:report.observedDeclarationCount,
  unresolved:report.remainingUnresolvedIDs,
  identitySha256:report.identitySha256,
  verifiedExecutableAuthorized:false}));
