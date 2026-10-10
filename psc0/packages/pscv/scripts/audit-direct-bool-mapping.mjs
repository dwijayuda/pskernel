#!/usr/bin/env node
/**
 * Cloud-only exact Git-source audit of the three Bool direct operations.
 * The audit includes the actual pinned Lean 4.35rc3 declaration and internal
 * counterpart lines, not just source scans. No executable authorization.
 */
import { execFileSync } from 'node:child_process';
import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { auditDirectBooleanMapping } from '../src/direct-bool-mapping.mjs';
import { pinnedLeanCommit } from '../src/lean-provenance.mjs';

if(process.argv.length!==6)throw Error('PSC_PSCV_BOOL_AUDIT_ARGS');
const [sourceDirectory,rawAmbientPath,requiredSurfacePath,outputPath]=process.argv.slice(2)
  .map(x=>path.resolve(x));
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const git=(cwd,...args)=>execFileSync('git',['-C',cwd,...args],{
  encoding:'utf8',timeout:15000,maxBuffer:8*1024*1024,
}).trimEnd();
const head=git(sourceDirectory,'rev-parse','HEAD');
if(head!==pinnedLeanCommit)throw Error('PSC_PSCV_BOOL_AUDIT_PINNED_COMMIT');
const pathName='src/Init/Prelude.lean';
const line=git(sourceDirectory,'ls-tree','--full-tree','HEAD','--',pathName);
const match=/^100644 blob ([a-f0-9]{40})\tsrc\/Init\/Prelude\.lean$/u.exec(line);
if(!match)throw Error('PSC_PSCV_BOOL_AUDIT_GIT_TREE');
const blob=execFileSync('git',['-C',sourceDirectory,'cat-file','blob',match[1]],{
  timeout:15000,maxBuffer:8*1024*1024,
}).toString('utf8');
const norm=git(root,'show','HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md');
const ambient=JSON.parse(await readFile(rawAmbientPath,'utf8'));
const worksheet=JSON.parse(await readFile(requiredSurfacePath,'utf8'));
const report=auditDirectBooleanMapping({
  normativeReference:norm,rawAmbient:ambient,sourceText:blob,
  sourcePath:pathName,gitBlobSha1:match[1],surfaceWorkbook:worksheet,
});
await writeFile(outputPath,JSON.stringify(report,null,2)+'\n');
process.stdout.write(JSON.stringify({
  status:report.status,mapped:report.mappedDirectBooleanCount,
  unresolved:report.unresolvedCount,
  source:report.sourcePath,sourceBlob:report.gitBlobSha1,
  sourceContentSha256:report.sourceContentSha256,
  mappingEvidenceSha256:report.mappingEvidenceSha256,
  completeStandardEnvironment:false,verifiedExecutableAuthorized:false,
})+'\n');
