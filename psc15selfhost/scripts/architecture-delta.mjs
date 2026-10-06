import { readFile } from "node:fs/promises";

const trustSchema=JSON.parse(await readFile(
  new URL("../contracts/audit/TRUST_DELTA_V1.json",import.meta.url),
  "utf8",
));
const semanticSchema=JSON.parse(await readFile(
  new URL("../contracts/audit/SEMANTIC_DELTA_V1.json",import.meta.url),
  "utf8",
));

function requireFields(value,fields,prefix){
  for(const field of fields){
    if(!Object.hasOwn(value,field)) throw new Error(prefix+"_MISSING: "+field);
  }
}

export function validateTrustDelta(delta){
  requireFields(delta,trustSchema.requiredFields,"PSC_TRUST_DELTA");
  const expansions=[
    ...(delta.addedTrustedComponents??[]),
    ...(delta.changedCapabilities??[]),
    ...(delta.changedAssumptions??[]),
  ];
  return Object.freeze({
    contract:trustSchema.contract,
    requiresExplicitReview:expansions.length>0,
  });
}

export function validateSemanticDelta(delta){
  requireFields(delta,semanticSchema.requiredFields,"PSC_SEMANTIC_DELTA");
  const semanticChange=
    (delta.ruleAdditions??[]).length>0||
    (delta.ruleRemovals??[]).length>0||
    (delta.ruleChanges??[]).length>0;
  if(semanticChange&&delta.sourceIdentity===delta.destinationIdentity){
    throw new Error("PSC_SEMANTIC_DELTA_IDENTITY_REQUIRED");
  }
  return Object.freeze({
    contract:semanticSchema.contract,
    semanticChange,
  });
}
