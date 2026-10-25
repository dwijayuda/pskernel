import assert from 'node:assert/strict';import fs from 'node:fs';
import {validateUnifiedSelfhostRequest} from './unified-selfhost-request.mjs';
import {qualificationProfile,compilerRequestLimit,supervisorLimit} from './selfhost-qualification-profiles.mjs';
const branch='qualification/test',base={schema:'psc1-unified-selfhost-request/1',branch,parentCommit:'a'.repeat(40),
 action:'qualify-independent-G1-G2-G3',mode:'--self-host',profile:'correctness-1800s',g1TimeoutMs:240000,g2g3TimeoutMs:1800000,targets:['rust']};
let checks=0;
for(const [profile,limit]of [['performance-240s',240000],['correctness-1800s',1800000],['correctness-3600s',3600000]]){
 validateUnifiedSelfhostRequest({...base,profile,g2g3TimeoutMs:limit},branch);checks++;
 const p=qualificationProfile(profile);assert.equal(p.g1TimeoutMs,240000);assert.equal(p.corpusTimeoutMs,240000);assert.equal(p.toolTimeoutMs,240000);
 for(const id of ['G1-bootstrap','G1-case','arbitrary','G2-self-extra',undefined])assert.deepEqual(compilerRequestLimit(profile,id),{timeoutMs:240000,timeoutPolicy:'standard-240s'});
 for(const id of ['G2-self','G3-self']){const r=compilerRequestLimit(profile,id);assert.equal(r.timeoutMs,limit);assert.equal(supervisorLimit(r.timeoutMs,r.timeoutPolicy).supervisorGuardMs,limit+5000);}
}
for(const change of [
 r=>r.profile='unbounded',r=>r.g1TimeoutMs=3600000,r=>r.g2g3TimeoutMs=3600000,
 r=>r.targets=['rust','rust'],r=>r.targets=['python'],r=>r.action='publish',
 r=>r.parentCommit='stale',r=>r.branch='other',r=>r.checker='/bin/true',
 r=>{r.profile='correctness-3600s';r.g2g3TimeoutMs=3600000;r.targets=['ts'];},
 r=>{r.profile='correctness-3600s';r.g2g3TimeoutMs=3600000;r.targets=['rust','wasm-core'];}
]){const r=structuredClone(base);change(r);assert.throws(()=>validateUnifiedSelfhostRequest(r,branch));checks++;}
assert.throws(()=>supervisorLimit(240001,'standard-240s'));
assert.throws(()=>supervisorLimit(1800001,'g2g3-correctness-1800s'));
assert.throws(()=>supervisorLimit(3600001,'g2g3-correctness-3600s'));
console.log('PSC1_UNIFIED_REQUEST_PROFILES: '+JSON.stringify({checks,profiles:['performance-240s','correctness-1800s','correctness-3600s'],longProfileTargets:['rust'],g1Ms:240000,toolMs:240000,checkerMs:120000}));
