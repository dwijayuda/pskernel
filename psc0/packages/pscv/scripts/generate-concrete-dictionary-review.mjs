#!/usr/bin/env node
/** Non-authoritative concrete dictionary witness report from pinned Lean. */
import {execFileSync} from 'node:child_process';
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {inspectConcreteDictionaries} from '../src/concrete-dictionary-review.mjs';
if(process.argv.length!==4)throw Error('PSC_PSCV_CONCRETE_DICT_ARGS');
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const show=p=>execFileSync('git',['-C',root,'show','HEAD:'+p],
  {encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const result=inspectConcreteDictionaries({
  normativeReference:show('pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'),
  source:show('PSCVL/ConcreteDictionaryWitness.lean'),
  transcript:await readFile(path.resolve(process.argv[2]),'utf8'),
});
await writeFile(path.resolve(process.argv[3]),JSON.stringify(result)+'\n');
console.log(JSON.stringify({status:result.status,goals:result.count,
  unresolved:result.unresolvedStandardIds,sha256:result.identitySha256,
  verifiedExecutableAuthorized:false}));
