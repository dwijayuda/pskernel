// Wall-clock profiles only; compiler semantics and every safety policy remain unchanged.
import assert from 'node:assert/strict';
export const PERFORMANCE_PROFILE='performance-240s';
export const CORRECTNESS_PROFILE='correctness-1800s';
export const LONG_CORRECTNESS_PROFILE='correctness-3600s';
const selfLimits=new Map([[PERFORMANCE_PROFILE,240000],[CORRECTNESS_PROFILE,1800000],[LONG_CORRECTNESS_PROFILE,3600000]]);
const policyLimits=new Map([['standard-240s',240000],['g2g3-correctness-1800s',1800000],['g2g3-correctness-3600s',3600000]]);
export function qualificationProfile(name=PERFORMANCE_PROFILE) {
 assert.ok(selfLimits.has(name),'PSC1_UNKNOWN_QUALIFICATION_PROFILE');
 return {name,g1TimeoutMs:240000,corpusTimeoutMs:240000,toolTimeoutMs:240000,
  selfCompileTimeoutMs:selfLimits.get(name),correctnessAndPerformanceSeparate:true};
}
export function compilerRequestLimit(profile,id) {
 const p=qualificationProfile(profile);
 const extended=profile!==PERFORMANCE_PROFILE&&['G2-self','G3-self'].includes(id);
 return {timeoutMs:extended?p.selfCompileTimeoutMs:240000,
  timeoutPolicy:extended?'g2g3-'+profile:'standard-240s'};
}
export function supervisorLimit(timeoutMs=240000,timeoutPolicy='standard-240s') {
 assert.ok(policyLimits.has(timeoutPolicy),'PSC1_UNKNOWN_TIMEOUT_POLICY');
 assert.ok(Number.isInteger(timeoutMs)&&timeoutMs>0&&timeoutMs<=policyLimits.get(timeoutPolicy),
  'PSC1_TIMEOUT_OUTSIDE_PROFILE');
 return {timeoutMs,timeoutPolicy,supervisorGuardMs:timeoutMs+5000};
}
