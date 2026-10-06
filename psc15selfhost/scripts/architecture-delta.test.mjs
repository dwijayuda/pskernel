import assert from "node:assert/strict";
import { test } from "node:test";
import { validateTrustDelta, validateSemanticDelta } from "./architecture-delta.mjs";

test("trust expansion requires explicit review",()=>{
  const result=validateTrustDelta({
    baseTrustManifest:"a",
    targetTrustManifest:"b",
    addedTrustedComponents:["new-checker"],
    removedTrustedComponents:[],
    changedContracts:[],
    changedCapabilities:[],
    changedProviderSecurity:[],
    changedAssumptions:[],
  });
  assert.equal(result.requiresExplicitReview,true);
});

test("security-only provider change can preserve semantic identity",()=>{
  const result=validateSemanticDelta({
    sourceIdentity:"lean4.34-core",
    destinationIdentity:"lean4.34-core",
    ruleAdditions:[],
    ruleRemovals:[],
    ruleChanges:[],
    representationOnlyChanges:[],
    securityOnlyChanges:["provider-runtime-hardening"],
    compatibilityImpact:"none",
    migrationEvidence:[],
  });
  assert.equal(result.semanticChange,false);
});

test("semantic rule change requires a new identity",()=>{
  assert.throws(()=>validateSemanticDelta({
    sourceIdentity:"same",
    destinationIdentity:"same",
    ruleAdditions:["new-rule"],
    ruleRemovals:[],
    ruleChanges:[],
    representationOnlyChanges:[],
    securityOnlyChanges:[],
    compatibilityImpact:"semantic",
    migrationEvidence:[],
  }),/IDENTITY_REQUIRED/);
});
