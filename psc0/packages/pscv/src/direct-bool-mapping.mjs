/**
 * P1-B direct Bool source-location bridge, NOT PSCV runtime certification.
 * All three normative direct Bool operations are logically declared
 * noncomputable by pinned Lean rc3 and have separate internal implementations
 * with named equality theorems. Locators below must be checked against the
 * exact pinned source blob, not against a possibly modified worktree file.
 */
import { createHash } from 'node:crypto';
import { extractLeanProvenanceBlueprint } from './lean-provenance.mjs';
import { extractRequiredStandardSurface } from './required-standard-surface.mjs';
import { validateAmbientRegistryInventory } from './ambient-registry-inventory.mjs';

const hash=x=>createHash('sha256').update(x).digest('hex');
const fail=x=>{throw new Error('PSC_PSCV_DIRECT_BOOL_MAPPING_'+x)};
const checked=Object.freeze([
  Object.freeze({id:'Bool.not',symbol:'not',internal:'Bool.Internal.not',
    theorem:'Bool.not_eq_internalNot'}),
  Object.freeze({id:'Bool.and',symbol:'and',internal:'Bool.Internal.and',
    theorem:'Bool.and_eq_internalAnd'}),
  Object.freeze({id:'Bool.or',symbol:'or',internal:'Bool.Internal.or',
    theorem:'Bool.or_eq_internalOr'}),
]);
const matchUnique=(lines, expectedPrefix, id)=>{
  const found=[];
  for(let i=0;i<lines.length;i++){
    if(lines[i].startsWith(expectedPrefix)){
      const c=lines[i].slice(expectedPrefix.length,expectedPrefix.length+1);
      if(c===' '||c===':'||c==='(')found.push(i+1);
    }
  }
  if(found.length!==1) fail('SOURCE_LOCATOR_'+id);
  return found[0];
};

export function auditDirectBooleanMapping({
  normativeReference,rawAmbient,sourceText,sourcePath,gitBlobSha1,surfaceWorkbook,
}) {
  const roots=extractLeanProvenanceBlueprint(normativeReference);
  const expectedRoot=roots.roots.find(x=>x.path==='src/Init/Prelude.lean');
  if(!expectedRoot||sourcePath!==expectedRoot.path||gitBlobSha1!==expectedRoot.gitBlobSha1) {
    fail('PINNED_SOURCE_BLOB');
  }
  if(typeof sourceText!=='string'||Buffer.byteLength(sourceText,'utf8')>8*1024*1024) {
    fail('SOURCE_BYTES');
  }
  const surface=extractRequiredStandardSurface(normativeReference);
  if(JSON.stringify(surfaceWorkbook)!==JSON.stringify(surface)) fail('SURFACE_NOT_NORMATIVE');
  const ambient=validateAmbientRegistryInventory(rawAmbient);
  const observed=new Map(ambient.canonicalObserved.directBool.map(x=>[x.snapshotId,x]));
  const lines=sourceText.split(/\r?\n/u);
  const selected=[];
  for(const row of checked){
    if(!surface.requiredSnapshotIds.includes(row.id))fail('MISSING_REQUIRED_DIRECT_ID');
    const info=observed.get(row.id);
    if(!info||info.logicalPresent!==true||info.internalPresent!==true||
        info.equalityTheoremPresent!==true||info.logicalNoncomputable!==true) {
      fail('LEAN_ENVIRONMENT_DIRECT_ID');
    }
    const publicLine=matchUnique(lines,'noncomputable def Bool.'+row.symbol,row.id);
    // Match an explicit Lean definition even when it has documented attributes.
    const implNeedle='def Bool.Internal.'+row.symbol;
    const implMatches=lines.flatMap((line,index)=>{
      const at=line.indexOf(implNeedle);
      if(at<0)return [];
      const suffix=line.slice(at+implNeedle.length,at+implNeedle.length+1);
      return [' ',':','('].includes(suffix)?[index+1]:[];
    });
    if(implMatches.length!==1)fail('INTERNAL_IMPLEMENTATION_'+row.id);
    const theoremLine=matchUnique(lines,'theorem '+row.theorem,row.id);
    if(!lines[theoremLine-1].includes('Eq Bool.'+row.symbol+' '+row.internal)) {
      fail('EQUALITY_THEOREM_TYPE_'+row.id);
    }
    selected.push(Object.freeze({
      snapshotId:row.id,
      mappingState:'located-pinned-Lean-logical-and-internal-declarations',
      logicalDeclaration:info.logicalDeclaration,
      logicalSourceLine:publicLine,
      logicalDeclaredNoncomputable:true,
      internalDeclaration:info.internalDeclaration,
      internalSourceLine:implMatches[0],
      internalNoncomputable:info.internalNoncomputable,
      equalityTheorem:info.equalityTheorem,
      equalityTheoremSourceLine:theoremLine,
      sourcePath,
      gitBlobSha1,
      // Equality theorem presence is observed from imported Lean; it does not
      // prove TS runtime semantics, source lowering or independent kernel
      // replay of PSCV-CERT-v1.
      theoremObservedByPinnedLean:true,
      independentlyKernelReplayed:false,
      runtimeBridgeQualified:false,
      allowedInClosedStandard:false,
      pscvVerified:false,
    }));
  }
  const selectedIds=new Set(selected.map(x=>x.snapshotId));
  const remaining=surface.requiredSnapshotIds.filter(x=>!selectedIds.has(x));
  const identity={
    protocol:'psc-standard-mapping-review/0',
    normativeSourceSha256:surface.normativeSha256,
    semanticVersion:'4.35.0-rc3',
    sourcePath,gitBlobSha1,
    sourceContentSha256:hash(sourceText),
    requiredSnapshotIds:surface.uniqueReferencedIdsCount,
    mappedDirectBooleanCount:selected.length,
    unresolvedSnapshotIds:remaining,
    mappings:selected,
  };
  return Object.freeze({
    schemaVersion:0,
    kind:identity.protocol,
    status:'partial-verified-Git-source-locators-only',
    mappingEvidenceSha256:hash(JSON.stringify(identity)),
    ...identity,
    unresolvedCount:remaining.length,
    orderedStandardRegistryQualified:false,
    approvedEffectsRegistryQualified:false,
    completeStandardEnvironment:false,
    pscvCertificateIssuerAvailable:false,
    verifiedExecutableAuthorized:false,
    pscvVerified:false,
  });
}
