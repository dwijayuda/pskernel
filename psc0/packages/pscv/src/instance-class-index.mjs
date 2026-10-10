/**
 * P1-D typed class-head candidate index for the exact Lean 4.35.0-rc3
 * imported PSCVL.Policy environment. This DOES NOT map PSCV snapshot IDs
 * to Lean classes/instances: the typeclass search, scoped import priority
 * and source registry freeze still require separate qualification.
 */
import { createHash } from 'node:crypto';
import { validateAmbientRegistryInventory } from './ambient-registry-inventory.mjs';
import { extractRequiredStandardSurface } from './required-standard-surface.mjs';

const sha=x=>createHash('sha256').update(x).digest('hex');
const fail=x=>{throw new Error('PSC_PSCV_INSTANCE_CLASS_INDEX_'+x);};
const compare=(a,b)=>a<b?-1:a>b?1:0;

export function indexImportedInstanceClassHeads({
  normativeReference,rawAmbient,requiredSurface,
}) {
  const surface=extractRequiredStandardSurface(normativeReference);
  if(JSON.stringify(requiredSurface)!==JSON.stringify(surface))fail('NON_NORMATIVE_WORKBOOK');
  const ambient=validateAmbientRegistryInventory(rawAmbient);
  const groups=new Map();
  const unclassified=[];
  for(const entry of ambient.canonicalObserved.instances){
    if(entry.resultClassHead===null){
      unclassified.push(entry.name);
      continue;
    }
    if(!groups.has(entry.resultClassHead))groups.set(entry.resultClassHead,[]);
    groups.get(entry.resultClassHead).push({
      name:entry.name,priority:entry.priority,synthOrder:entry.synthOrder,
      imported:entry.imported,
      sourceLocator:null,
      exactInstanceSearchOrderQualified:false,
    });
  }
  const classes=[...groups.entries()].sort(([a],[b])=>compare(a,b)).map(([head,entries])=>({
    classHead:head,
    candidateCount:entries.length,
    members:entries.sort((a,b)=>b.priority-a.priority||compare(a.name,b.name)),
    // This is a review index by priority and name. It does not model
    // Lean tie-resolution, scope/import visibility or synthesis order.
    searchOrderQualified:false,
    semanticSnapshotIDsValidated:[],
  }));
  const classCount=classes.length;
  if(classCount<1 || classCount>5000 || unclassified.length>=rawAmbient.instances.length) {
    fail('NO_USABLE_LEAN_CLASS_INDEX');
  }
  const direct=['Bool.and','Bool.not','Bool.or'];
  const required=surface.requiredSnapshotIds;
  if(required.length!==194 || direct.some(x=>!required.includes(x)))fail('SURFACE_ID');
  const unresolved=required.filter(x=>!direct.includes(x));
  if(unresolved.length!==191)fail('UNRESOLVED_COUNT');
  const identity={
    protocol:'psc-imported-class-head-review/0',
    normativeSha256:surface.normativeSha256,
    ambientIdentitySha256:ambient.identitySha256,
    sourceTypeEnvironment:ambient.environment,
    classCount,importedInstances:ambient.importedInstanceCount,
    instancesWithNoSyntacticClassHead:unclassified.length,
    classes,
    unclassifiedInstanceNames:unclassified.sort(compare),
    // These identifiers are exact source requirements; none has yet been
    // mapped to a class head by an approved PSCV reference rule.
    remainingRequiredSnapshotIds:unresolved,
  };
  return Object.freeze({
    schemaVersion:0,
    kind:identity.protocol,
    state:'typed-candidate-index-not-authoritative',
    identitySha256:sha(JSON.stringify(identity)),
    ...identity,
    expectedStandardSnapshotIds:194,
    sourceLocatedDirectBooleanIDs:3,
    stillUnresolvedSnapshotIds:191,
    classHeadCandidatesAvailable:true,
    declarationMappingApproved:false,
    instanceResolutionQualified:false,
    importedScopeAndTieOrderQualified:false,
    sourceLineProvenanceComplete:false,
    effectsAndVerificationRegistryQualified:false,
    standardEnvironmentFrozen:false,
    verifiedExecutableAuthorized:false,
    pscvVerified:false,
  });
}
