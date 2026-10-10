/**
 * P1-I pinned upstream Lean Git *source-byte* and lexical locator review.
 * A lexical `instance NAME` line is only a candidate source locator;
 * it does not prove imported name resolution or PSCV Standard authority.
 */
import {createHash} from 'node:crypto';

const fail=why=>{throw Error('PSC_PSCV_SOURCE_BLOBS_'+why);};
export const lean435rc3Commit='470d5ce1400764999581fd26d5d72b00d990b0f4';
export const sourceModules=Object.freeze([
 Object.freeze({module:'Init.Prelude',path:'src/Init/Prelude.lean',
  blobSha1:'f87ee970af5149d74434f09a89aedff1a8fdb2d2'}),
 Object.freeze({module:'Init.Data.String.Defs',path:'src/Init/Data/String/Defs.lean',
  blobSha1:'f2502b701ef21070b4eaaefe6642ee8d7e58cede'}),
 Object.freeze({module:'Init.Data.Int.Basic',path:'src/Init/Data/Int/Basic.lean',
  blobSha1:'13eb3c86d79160bb9bda2edd33772d6d4439ce0c'}),
]);
const sha=x=>createHash('sha256').update(x).digest('hex');
export function gitBlobSha1(content) {
 if(typeof content!=='string')fail('NOT_SOURCE_TEXT');
 const bytes=Buffer.from(content,'utf8');
 return createHash('sha1').update('blob '+bytes.length+String.fromCharCode(0))
   .update(bytes).digest('hex');
}
const exact=(x,keys)=>x!==null&&typeof x==='object'&&
 !Array.isArray(x)&&Object.getPrototypeOf(x)===Object.prototype&&
 Object.keys(x).length===keys.length&&keys.every(k=>Object.hasOwn(x,k));

export function reviewPinnedLeanSource({typedDeclarations,upstreamCommit,sourceFiles}) {
 if(typedDeclarations?.identitySha256!==
    '8246970bdb3a79da9879bca1b191c5ddcd552589a54e4ef11a33cca6447925c5'||
    typedDeclarations?.observedDeclarationCount!==11||
    typedDeclarations?.verifiedExecutableAuthorized!==false||
    upstreamCommit!==lean435rc3Commit ||
    !Array.isArray(sourceFiles)||sourceFiles.length!==sourceModules.length)fail('PINNED_INPUTS');
 const byModule=new Map();
 for(let i=0;i<sourceFiles.length;i++){
  const f=sourceFiles[i],expect=sourceModules[i];
  if(!exact(f,['module','path','gitBlobSha1','sourceText'])||
     f.module!==expect.module||f.path!==expect.path||
     f.gitBlobSha1!==expect.blobSha1||
     typeof f.sourceText!=='string'||Buffer.byteLength(f.sourceText)>1_000_000||
     gitBlobSha1(f.sourceText)!==expect.blobSha1)fail('SOURCE_BLOB_BYTES');
  byModule.set(expect.module,{
   ...expect,sourceText:f.sourceText,
  });
 }
 const candidates=typedDeclarations.selectedDeclarations.map(selected=>{
  const module=byModule.get(selected.importedModule);
  if(!module||typeof selected.name!=='string'||selected.name.length>100)
    fail('UNMAPPED_IMPORTED_MODULE');
  const escaped=selected.name.replace(/[.*+?^${}()|[\]\\]/gu,'\\$&');
  const expression=new RegExp('^\\s*instance\\s+'+escaped+'(?=\\s|\\[|:|\\()','u');
  const matches=[];
  for(const [i,line] of module.sourceText.split('\n').entries()){
   if(expression.test(line))matches.push(i+1);
  }
  if(matches.length>1)fail('AMBIGUOUS_LEXICAL_DECLARATION');
  return {
   importedConstant:selected.name,
   actualImportedModule:selected.importedModule,
   actualTypeExpressionRepr:selected.typeExprRepr,
   upstreamSourcePath:module.path,
   sourceGitBlobSha1:module.blobSha1,
   lexicalExplicitInstanceLine:matches[0]??null,
   occurrenceKind:matches.length===1?'unique-literal-named-instance':'module-only',
   importedElaborationToSourceLineProved:false,
   approvedStandardSnapshotMapping:false,
  };
 });
 const identity={
  protocol:'psc-lean-pinned-lexical-provenance/0',
  leanGitCommit:upstreamCommit,
  typedObservationSha256:typedDeclarations.identitySha256,
  sourceBlobs:sourceModules,
  candidates,
 };
 return Object.freeze({
  schemaVersion:0,kind:identity.protocol,status:'immutable-git-blobs-lexical-candidates-only',
  identitySha256:sha(JSON.stringify(identity)),...identity,
  importedConstantCount:candidates.length,
  selectedSourceBlobCount:sourceModules.length,
  explicitlyNamedCandidateCount:candidates.filter(x=>x.lexicalExplicitInstanceLine!==null).length,
  exactElaboratorLineProven:false,
  acceptedForPSCVStandard:false,
  unresolvedNormativeIds:191,
  pscvCertificateAvailable:false,
  verifiedExecutableAuthorized:false,
  pscvVerified:false,
 });
}
