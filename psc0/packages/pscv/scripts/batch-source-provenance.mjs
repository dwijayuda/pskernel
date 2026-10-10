#!/usr/bin/env node
/** Pinned upstream Git source bytes for P1-K actual imported declarations. */
import {execFileSync} from 'node:child_process';
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {reviewBatchSourceBlobs,expectedLeanSourcePath,leanCommit}
 from '../src/batch-source-provenance.mjs';
if(process.argv.length!==5)throw Error('PSC_PSCV_BATCH_BLOB_ARGS');
const [typedReportPath,upstreamRoot,reportPath]=process.argv.slice(2).map(x=>path.resolve(x));
const git=args=>execFileSync('git',['-C',upstreamRoot,...args],{
  encoding:'utf8',timeout:15000,maxBuffer:5*1024*1024,
});
const upstreamCommit=git(['rev-parse','HEAD']).trim();
if(upstreamCommit!==leanCommit)throw Error('PSC_PSCV_BATCH_BLOB_UPSTREAM_PIN');
const typedReport=JSON.parse(await readFile(typedReportPath,'utf8'));
const modules=[...new Set(typedReport.selectedDeclarations.map(x=>x.importedModule))].sort();
const files=modules.map(module=>{
 const sourcePath=expectedLeanSourcePath(module);
 try {
  const blobSha1=git(['rev-parse','HEAD:'+sourcePath]).trim();
  const sourceText=git(['show','HEAD:'+sourcePath]);
  return {module,path:sourcePath,found:true,blobSha1,sourceText};
 } catch(_err) {
  return {module,path:sourcePath,found:false,blobSha1:null,sourceText:null};
 }
});
const report=reviewBatchSourceBlobs({typedReport,upstreamCommit,sourceFiles:files});
await writeFile(reportPath,JSON.stringify(report)+'\n');
console.log(JSON.stringify({
 status:report.status,importedDeclarations:report.importedDeclarations,
 modules:report.sourceModulesAttempted,
 foundModules:report.sourceModulesFound,
 namedInstanceCandidates:report.lexicallyNamedInstanceCandidates,
 unlocatedModules:report.sourceModulesNotLocated,
 missingModuleNames:report.modules.filter(x=>!x.sourceFileLocated).map(x=>x.importedModule),
 identitySha256:report.identitySha256,
 verifiedExecutableAuthorized:false,
}));
