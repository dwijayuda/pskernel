#!/usr/bin/env node
/** Produce the complete normative work ledger after REAL pinned Lean probes. */
import {execFileSync} from 'node:child_process';
import {readFile,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {buildStandardWorkLedger} from '../src/standard-work-ledger.mjs';
if(process.argv.length!==5)throw Error('PSC_PSCV_WORK_LEDGER_ARGUMENTS');
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const show=p=>execFileSync('git',['-C',root,'show','HEAD:'+p],
 {encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const ledger=buildStandardWorkLedger({
 normativeReference:show('pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'),
 typedSource:show('PSCVL/TypedInstanceWitness.lean'),
 concreteSource:show('PSCVL/ConcreteDictionaryWitness.lean'),
 typedTranscript:await readFile(path.resolve(process.argv[2]),'utf8'),
 concreteTranscript:await readFile(path.resolve(process.argv[3]),'utf8'),
});
await writeFile(path.resolve(process.argv[4]),JSON.stringify(ledger)+'\n');
console.log(JSON.stringify({status:ledger.status,rows:ledger.requiredRowsCount,
 ids:ledger.requiredIdsCount,observed:ledger.observedPilotSurfaces,
 unresolved:ledger.unresolvedIdsCount,sha256:ledger.identitySha256,
 verifiedExecutableAuthorized:false}));
