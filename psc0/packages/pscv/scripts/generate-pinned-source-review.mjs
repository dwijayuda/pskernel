#!/usr/bin/env node
/** Review only the three upstream files actually named by pinned Lean. */
import {execFileSync} from 'node:child_process';
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {reviewPinnedLeanSource,sourceModules,lean435rc3Commit}
 from '../src/pinned-lean-source-review.mjs';
if(process.argv.length!==5)throw Error('PSC_PSCV_SOURCE_BLOBS_ARGS');
const [typedReportPath,upstreamRoot,outputPath]=process.argv.slice(2).map(x=>path.resolve(x));
const git=args=>execFileSync('git',['-C',upstreamRoot,...args],
 {encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const commit=git(['rev-parse','HEAD']).trim();
if(commit!==lean435rc3Commit)throw Error('PSC_PSCV_UPSTREAM_COMMIT_PIN');
const files=sourceModules.map(x=>({
 module:x.module,path:x.path,
 gitBlobSha1:git(['rev-parse','HEAD:'+x.path]).trim(),
 sourceText:git(['show','HEAD:'+x.path]),
}));
const reviewed=reviewPinnedLeanSource({
 typedDeclarations:JSON.parse(await readFile(typedReportPath,'utf8')),
 upstreamCommit:commit,sourceFiles:files,
});
await writeFile(outputPath,JSON.stringify(reviewed)+'\n');
console.log(JSON.stringify({
 status:reviewed.status,modules:reviewed.selectedSourceBlobCount,
 declarations:reviewed.importedConstantCount,
 exactNamedCandidates:reviewed.explicitlyNamedCandidateCount,
 candidates:reviewed.candidates.map(x=>({
  name:x.importedConstant,module:x.actualImportedModule,
  path:x.upstreamSourcePath,line:x.lexicalExplicitInstanceLine,
 })),
 identitySha256:reviewed.identitySha256,
 verifiedExecutableAuthorized:false,
}));
