// Trusted manual-request policy; generated compiler wire cannot choose limits.
import assert from 'node:assert/strict';
import {qualificationProfile} from './selfhost-qualification-profiles.mjs';
export function validateUnifiedSelfhostRequest(r,branch){
 assert.ok(r&&typeof r==='object'&&!Array.isArray(r));
 assert.deepEqual(Object.keys(r).sort(),['schema','branch','parentCommit','action','mode','profile','g1TimeoutMs','g2g3TimeoutMs','targets'].sort());
 assert.equal(r.schema,'psc1-unified-selfhost-request/1');assert.equal(r.branch,branch);
 assert.match(r.parentCommit,/^[0-9a-f]{40}$/);
 assert.ok(['--g1-only','--self-host'].includes(r.mode));
 assert.equal(r.action,r.mode==='--g1-only'?'validate-independent-G1':'qualify-independent-G1-G2-G3');
 const p=qualificationProfile(r.profile);
 assert.equal(r.g1TimeoutMs,240000);assert.equal(r.g2g3TimeoutMs,p.selfCompileTimeoutMs);
 assert.ok(Array.isArray(r.targets)&&r.targets.length>0&&r.targets.every(t=>['js','ts','rust','wasm-core'].includes(t)));
 assert.equal(new Set(r.targets).size,r.targets.length);
 // The added hour profile is scoped to the user's active Rust investigation.
 if(r.profile==='correctness-3600s')assert.deepEqual(r.targets,['rust']);
 return r;
}
