// Wall-clock profiles only; compiler semantics and every safety policy remain unchanged.
import assert from 'node:assert/strict';
export const PERFORMANCE_PROFILE='performance-240s';
export const CORRECTNESS_PROFILE='correctness-1800s';
export function qualificationProfile(name=PERFORMANCE_PROFILE) {
 assert.ok([PERFORMANCE_PROFILE,CORRECTNESS_PROFILE].includes(name),'PSC1_UNKNOWN_QUALIFICATION_PROFILE');
 return {name,g1TimeoutMs:240000,corpusTimeoutMs:240000,toolTimeoutMs:240000,
  selfCompileTimeoutMs:name===CORRECTNESS_PROFILE?1800000:240000,
  correctnessAndPerformanceSeparate:true};
}
export function compilerRequestLimit(profile,id) {
 const p=qualificationProfile(profile);
 const extended=profile===CORRECTNESS_PROFILE&&['G2-self','G3-self'].includes(id);
 return {timeoutMs:extended?p.selfCompileTimeoutMs:240000,
  timeoutPolicy:extended?'g2g3-correctness-1800s':'standard-240s'};
}
export function supervisorLimit(timeoutMs=240000,timeoutPolicy='standard-240s') {
 assert.ok(['standard-240s','g2g3-correctness-1800s'].includes(timeoutPolicy),'PSC1_UNKNOWN_TIMEOUT_POLICY');
 assert.ok(Number.isInteger(timeoutMs)&&timeoutMs>0&&timeoutMs<=(timeoutPolicy==='g2g3-correctness-1800s'?1800000:240000),
  'PSC1_TIMEOUT_OUTSIDE_PROFILE');
 return {timeoutMs,timeoutPolicy,supervisorGuardMs:timeoutMs+5000};
}
