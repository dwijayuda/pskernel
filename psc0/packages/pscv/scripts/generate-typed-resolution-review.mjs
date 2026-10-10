#!/usr/bin/env node
/** Cloud-only producer following the actual pinned Lean witness compilation. */
import { execFileSync } from 'node:child_process';
import { readFile,writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { reviewTypedResolution } from '../src/typed-resolution-review.mjs';
if(process.argv.length!==4)throw Error('PSC_PSCV_TYPED_WITNESS_ARGS');
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const gitShow=p=>execFileSync('git',['-C',root,'show','HEAD:'+p],
  {encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const report=reviewTypedResolution({
  normativeReference:gitShow('pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'),
  source:gitShow('PSCVL/TypedInstanceWitness.lean'),
  transcript:await readFile(path.resolve(process.argv[2]),'utf8'),
});
await writeFile(path.resolve(process.argv[3]),JSON.stringify(report)+'\n');
console.log(JSON.stringify({
  state:report.status,goals:report.goalsObserved,
  unresolved:report.unresolvedStandardSnapshotIds,
  fingerprint:report.identitySha256,verifiedExecutableAuthorized:false,
}));
