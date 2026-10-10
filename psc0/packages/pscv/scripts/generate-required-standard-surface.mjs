#!/usr/bin/env node
/** Source-owned PSCV 24.3 coverage worksheet; NOT a Standard registry manifest. */
import { execFileSync } from 'node:child_process';
import { writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { extractRequiredStandardSurface } from '../src/required-standard-surface.mjs';

if(process.argv.length!==3)throw Error('PSC_PSCV_SURFACE_USAGE');
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const reference=execFileSync('git',['-C',root,'show',
  'HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'],
{encoding:'utf8',timeout:15000,maxBuffer:2*1024*1024});
const out=extractRequiredStandardSurface(reference);
await writeFile(path.resolve(process.argv[2]),JSON.stringify(out)+'\n');
process.stdout.write(JSON.stringify({
  protocol:out.kind,sourceRowsCount:out.sourceRowsCount,
  uniqueReferencedIdsCount:out.uniqueReferencedIdsCount,
  sourceDigest:out.sourceDigest,
  completeStandardEnvironment:false,
  verifiedExecutableAuthorized:false,
})+'\n');
