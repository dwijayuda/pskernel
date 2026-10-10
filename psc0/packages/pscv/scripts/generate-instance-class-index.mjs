#!/usr/bin/env node
/** P1-D source-anchored imported typeclass index; not a PSCV Standard. */
import { execFileSync } from 'node:child_process';
import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { indexImportedInstanceClassHeads } from '../src/instance-class-index.mjs';
if(process.argv.length!==5)throw Error('PSC_PSCV_CLASS_INDEX_ARGS');
const [rawPath,surfacePath,outPath]=process.argv.slice(2).map(x=>path.resolve(x));
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const normativeReference=execFileSync('git',[
  '-C',root,'show','HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'
],{encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const rawAmbient=JSON.parse(await readFile(rawPath,'utf8'));
const requiredSurface=JSON.parse(await readFile(surfacePath,'utf8'));
const report=indexImportedInstanceClassHeads({
  normativeReference,rawAmbient,requiredSurface,
});
await writeFile(outPath,JSON.stringify(report)+'\n');
process.stdout.write(JSON.stringify({
  status:report.state,
  importedInstances:report.importedInstances,
  instanceEntries:rawAmbient.instances.length,
  resultClassHeads:report.classCount,
  missingResultHeads:report.instancesWithNoSyntacticClassHead,
  remainingIDs:report.stillUnresolvedSnapshotIds,
  identitySha256:report.identitySha256,
  standardEnvironmentFrozen:false,
  verifiedExecutableAuthorized:false,
})+'\n');
