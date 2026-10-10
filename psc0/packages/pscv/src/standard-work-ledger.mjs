/**
 * Closed requirement *inventory*, not closed PSCV Standard semantics.
 * Based on the pinned normative text and two executed Lean instance probes.
 * A shared source row does not prove a dictionary implements any `std.*` ID.
 */
import {createHash} from 'node:crypto';
import {extractRequiredStandardSurface} from './required-standard-surface.mjs';
import {reviewTypedResolution} from './typed-resolution-review.mjs';
import {inspectConcreteDictionaries} from './concrete-dictionary-review.mjs';

const sha=x=>createHash('sha256').update(x).digest('hex');
const fail=x=>{throw Error('PSC_PSCV_WORK_LEDGER_'+x);};
const direct=new Set(['Bool.not','Bool.and','Bool.or']);
export function buildStandardWorkLedger({normativeReference,typedSource,typedTranscript,
  concreteSource,concreteTranscript}) {
  const required=extractRequiredStandardSurface(normativeReference);
  const typed=reviewTypedResolution({normativeReference,source:typedSource,
    transcript:typedTranscript});
  const concrete=inspectConcreteDictionaries({normativeReference,source:concreteSource,
    transcript:concreteTranscript});
  if(typed.identitySha256!=='0a5cdad32ace1492158fab973a9da60d9b430ff529c71a9804e415e80efea712'||
     concrete.identitySha256!=='215f6e60a0319320690035dbbfa34deb812c53466f53f6dd8892daa99757cc29'||
     typed.normativeSha256!==required.normativeSha256||
     concrete.normativeSourceSha256!==required.normativeSha256)fail('PROBE_IDENTITY');
  const bySurface=new Map(required.requiredRows.map(x=>[x.id,x]));
  const byConcrete=new Map(concrete.observations.map(x=>[x.surfaceId,x]));
  const observations=typed.observed.map(g=>{
    const row=bySurface.get(g.surfaceId), c=byConcrete.get(g.surfaceId);
    if(!row||!c||c.genericParentGoal!==g.requestedLeanGoal||
       c.previouslyObservedGenericHead!==g.selectedTermText||
       JSON.stringify(c.normativeSnapshotIdsStillNeedingApproval)!==
       JSON.stringify(row.referencedSnapshotIds)||
       JSON.stringify(g.normativeRequiredSnapshotIds)!==
       JSON.stringify(row.referencedSnapshotIds))fail('PROBE_CROSS_REFERENCE');
    return {
      surfaceId:g.surfaceId,importedGenericGoal:g.requestedLeanGoal,
      importedGenericSelection:g.selectedTermText,
      concreteGoal:c.newConcreteSynthesisGoal,
      importedConcreteSelection:c.newlyObservedSelectedTerm,
      referencedSnapshotIds:row.referencedSnapshotIds,
      approvedMapping:false,dependencyRelationProved:false,
    };
  }).sort((a,b)=>a.surfaceId<b.surfaceId?-1:1);
  if(observations.length!==7||byConcrete.size!==7)fail('PILOT_COVERAGE');
  const ids=required.requiredSnapshotIds.map(id=>{
    const requiredBy=required.requiredRows.filter(x=>x.referencedSnapshotIds.includes(id))
      .map(x=>x.id);
    const pilotSurfaces=observations.filter(x=>x.referencedSnapshotIds.includes(id))
      .map(x=>x.surfaceId);
    if(requiredBy.length===0)fail('REQUIREMENT_COVERAGE');
    return {
      snapshotId:id,requiredBy,observedPilotSurfaceIds:pilotSurfaces,
      previousP1CSourceLocation:direct.has(id),
      selectedLeanDeclaration:null,allowedStandardInstance:null,
      exactClassAndTypeProved:false,instanceScopeAndTieOrderProved:false,
      pinnedSourceLineVerified:false,backendRuntimeEquivalenceProved:false,
      status:direct.has(id)?'prior-Bool-source-location-only':'unresolved',
    };
  });
  if(ids.length!==194||new Set(ids.map(x=>x.snapshotId)).size!==194||
     ids.filter(x=>x.previousP1CSourceLocation).length!==3)fail('REQUIRED_IDS');
  const identity={
    protocol:'psc-standard-work-ledger/0',
    normativeSourceSha256:required.normativeSha256,
    requiredSurfaceSha256:required.sourceDigest,
    typedWitnessSha256:typed.identitySha256,concreteWitnessSha256:concrete.identitySha256,
    surfaceRows:required.requiredRows,
    observations,snapshotIds:ids,
  };
  return Object.freeze({
    schemaVersion:0,kind:identity.protocol,
    status:'full-requirement-inventory-unresolved-mappings',
    identitySha256:sha(JSON.stringify(identity)),...identity,
    requiredRowsCount:required.sourceRowsCount,requiredIdsCount:ids.length,
    observedPilotSurfaces:observations.length,
    previousDirectSourceLocations:3,unresolvedIdsCount:191,
    importedEnvironmentApproved:false,orderedStandardFrozen:false,
    effectAndWPRegistryApproved:false,certificateAvailable:false,
    verifiedExecutableAuthorized:false,pscvVerified:false,
  });
}
