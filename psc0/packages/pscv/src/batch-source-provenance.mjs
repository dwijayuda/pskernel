/**
 * P1-L: pinned Lean source Git-blob provenance for ALL selected P1-K
 * arithmetic instance declarations. Lexical instance positions are only
 * candidates; neither declaration elaboration nor Standard policy follows.
 */
import {createHash} from 'node:crypto';
import {literalInstanceLineCandidates} from './pinned-lean-source-review.mjs';
const fail=x=>{throw Error('PSC_PSCV_BATCH_BLOB_PROVENANCE_'+x)};
const sha=x=>createHash('sha256').update(x).digest('hex');
const expectedImportTypes='abc06182e2875b15f150fabd567fa7a3c86ccb783030bf0ac04dc635fe41a372';
export const leanCommit='470d5ce1400764999581fd26d5d72b00d990b0f4';
const regex=/^(?:Init|Std)(?:\.[A-Za-z][A-Za-z0-9_]*)+$/u;
const compare=(a,b)=>a<b?-1:a>b?1:0;

export function expectedLeanSourcePath(moduleName) {
 if(typeof moduleName!=='string'||moduleName.length>256||!regex.test(moduleName))
   fail('IMPORTED_MODULE_PATH');
 return 'src/'+moduleName.replaceAll('.','/')+'.lean';
}
export function shaGitBlob(content) {
 if(typeof content!=='string')fail('BLOB_NOT_TEXT');
 const bytes=Buffer.from(content,'utf8');
 return createHash('sha1').update('blob '+bytes.length+String.fromCharCode(0))
   .update(bytes).digest('hex');
}
const object=x=>x!==null&&typeof x==='object'&&!Array.isArray(x)&&
 Object.getPrototypeOf(x)===Object.prototype;
const exact=(x,keys)=>object(x)&&Object.keys(x).length===keys.length&&
 keys.every(k=>Object.hasOwn(x,k));

export function reviewBatchSourceBlobs({typedReport,upstreamCommit,sourceFiles}) {
 if(typedReport?.identitySha256!==expectedImportTypes||
   typedReport?.selectedDeclarationCount!==45||
   typedReport?.verifiedExecutableAuthorized!==false||
   upstreamCommit!==leanCommit||
   !Array.isArray(sourceFiles)||sourceFiles.length>100)fail('PINNED_REPORT');
 const declarations=typedReport.selectedDeclarations;
 const modules=[...new Set(declarations.map(x=>x.importedModule))].sort(compare);
 if(modules.length<1||sourceFiles.length!==modules.length)fail('MODULE_COVERAGE');
 const byModule=new Map();
 let foundModules=0;
 for(let i=0;i<modules.length;i++){
  const entry=sourceFiles[i],name=modules[i],src=expectedLeanSourcePath(name);
  if(!exact(entry,['module','path','found','blobSha1','sourceText'])||
     entry.module!==name||entry.path!==src||typeof entry.found!=='boolean')
    fail('SOURCE_FILE_SCHEMA');
  if(entry.found){
    if(typeof entry.sourceText!=='string'||
       Buffer.byteLength(entry.sourceText)>4*1024*1024||
       !/^[a-f0-9]{40}$/u.test(entry.blobSha1)||
       shaGitBlob(entry.sourceText)!==entry.blobSha1)fail('PINNED_BLOB_MISMATCH');
    foundModules++;
  }else if(entry.blobSha1!==null||entry.sourceText!==null){
    fail('MISSING_MODULE_MUST_NOT_HAVE_SOURCE');
  }
  byModule.set(name,entry);
 }
 if(foundModules<1)fail('NO_UPSTREAM_SOURCE_FOUND');
 const observed=declarations.map(decl=>{
   const f=byModule.get(decl.importedModule);
   if(!f||typeof decl.name!=='string')fail('DECLARATION_TO_MODULE');
   const hits=f.found?literalInstanceLineCandidates(f.sourceText,decl.name):[];
   if(hits.length>1)fail('AMBIGUOUS_LEXICAL_DECLARATION');
   return Object.freeze({
    selectedConstant:decl.name,
    importedModule:decl.importedModule,
    actualLeanDeclarationTypeRepr:decl.typeExprRepr,
    candidateSourcePath:f.found?f.path:null,
    sourceGitBlobSha1:f.found?f.blobSha1:null,
    explicitNamedInstanceCandidateLine:hits[0]??null,
    lexicalOnly:hits.length===1,
    sourceToElaborationProved:false,
    standardInstanceScopeAndOrderQualified:false,
    semanticSnapshotIDMappingApproved:false,
   });
 });
 const modulesReport=sourceFiles.map(x=>({
   importedModule:x.module,
   sourcePath:x.found?x.path:null,
   pinnedSourceBlobSha1:x.found?x.blobSha1:null,
   sourceFileLocated:x.found,
 }));
 const identity={
   protocol:'psc-lean-imported-instance-source-provenance/0',
   upstreamLeanCommit:leanCommit,
   previousTypedReportSha256:typedReport.identitySha256,
   modules:modulesReport,selectedConstants:observed,
 };
 return Object.freeze({
  schemaVersion:0,kind:identity.protocol,
  status:'pinned-git-source-evidence-with-unproved-lexical-line-candidates',
  identitySha256:sha(JSON.stringify(identity)),...identity,
  importedDeclarations:observed.length,
  sourceModulesAttempted:modules.length,
  sourceModulesFound:foundModules,
  sourceModulesNotLocated:modules.length-foundModules,
  lexicallyNamedInstanceCandidates:observed.filter(x=>x.lexicalOnly).length,
  normativeSnapshotIDs:194,unresolvedStandardIDs:191,
  importedDeclarationSemanticsQualified:false,
  closedStandardRegistryQualified:false,
  verifiedExecutableAuthorized:false,pscvVerified:false,
 });
}
