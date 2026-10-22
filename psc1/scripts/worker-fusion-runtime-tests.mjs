import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
const root=path.resolve('dist/worker-fusion');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const consumer=path.join(root,'consumer.mjs');
fs.writeFileSync(consumer,`import {pathToFileURL} from 'node:url';
import {performance} from 'node:perf_hooks';
import * as probe from './probe.mjs';
const m=await import(pathToFileURL(process.argv[2]).href);
const start=performance.now();
const early=m.entry(1000000000n,0n);
const earlyMs=performance.now()-start;
const full=m.entry(30000n,30000n);
const arithmetic=m.arithmeticEntry(100000n,7n);
const continuation=m.continuationEntry(100000n,7n,3n);
const evaluated=m.evaluatedEntry(100000n,7n);
const escaped=m.escaped(7n,10n);
const captured=m.capture(5n);
const stableAlias=m.stableAlias(5n,2n),literalAlias=m.literalAlias(2n);
const captureSelf=m.captureSelf(5n),captureLambda=m.captureLambda(5n),captureMatch=m.captureMatch(5n);
const shadow=m.shadow(2n);
const ordered=m.orderedWitness();
console.log(JSON.stringify({early:String(early),full:String(full),escaped:String(escaped),
 captured:String(captured),stableAlias:String(stableAlias),literalAlias:String(literalAlias),captureSelf:String(captureSelf),captureLambda:String(captureLambda),captureMatch:String(captureMatch),shadow:String(shadow),ordered:String(ordered),arithmetic:String(arithmetic),continuation:String(continuation),evaluated:String(evaluated),marks:probe.seen,
 earlyMs,maxRssKiB:process.resourceUsage().maxRSS}));\n`);
const records=[];
let expected=null;
for(const label of ['baseline','fused']) {
  const module=path.join(root,label+'.mjs');
  const start=performance.now();
  const run=spawnSync(process.execPath,[consumer,module],{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
  assert.equal(run.error,undefined,run.error?.message);
  assert.equal(run.status,0,run.stderr);
  const result=JSON.parse(run.stdout.trim());
  assert.ok(result.earlyMs<2000,'first return must avoid traversing billion-fuel range');
  const observation={...result};delete observation.earlyMs;delete observation.maxRssKiB;
  assert.deepEqual(observation,{early:'0',full:'0',escaped:'3',captured:'0',stableAlias:'0',literalAlias:'0',captureSelf:'0',captureLambda:'0',captureMatch:'0',shadow:'9',ordered:'3',arithmetic:'100007',continuation:'100010',evaluated:'100007',marks:['2','5']});
  if(expected)assert.deepEqual(observation,expected);else expected=observation;
  records.push({label,elapsedMs:Math.round(performance.now()-start),moduleSha256:sha(fs.readFileSync(module)),...result});
}
for(const label of ['baseline','fused']) {
  const strict=path.join(root,'strict-'+label+'.mjs');
  const run=spawnSync(process.execPath,['--input-type=module','-e',
    'import {pathToFileURL} from "node:url";const m=await import(pathToFileURL(process.argv[1]).href);m.strict(0n);',
    strict],{encoding:'utf8',timeout:2000,maxBuffer:32*1024*1024});
  assert.equal(run.error?.code,'ETIMEDOUT','ignored divergent rhs must still execute before returned lambda');
}
for(const label of ['baseline','fused']) {
  const strict=path.join(root,'strict-'+label+'.mjs');
  const run=spawnSync(process.execPath,['--input-type=module','-e',
    'import {pathToFileURL} from "node:url";const m=await import(pathToFileURL(process.argv[1]).href);m.curriedProbe(()=>{for(;;){}},()=>{throw Error("later argument evaluated before intermediate call");});',
    strict],{encoding:'utf8',timeout:2000,maxBuffer:32*1024*1024});
  assert.equal(run.error?.code,'ETIMEDOUT','intermediate curried call must diverge before later argument');
}
const result={schema:'psc1-typed-worker-fusion-runtime/1',commit:process.env.GITHUB_SHA,
  processTimeoutMs:240000,divergenceDeadlineMs:2000,records,
  preserved:['exact observations','escaping partial functions','old captured values','lexical shadowing','stable variable and literal aliases','self, lambda and constructor-match shadow capture',
    'left-to-right exact-once operands','strict divergent prefix','total Nat arithmetic prefix and 100000 traversal steps','unknown curried application order','evaluated local continuation and 100000 traversal steps'],
  formalPreservation:'not-provided'};
fs.writeFileSync(path.join(root,'results.json'),JSON.stringify(result,null,2)+'\n');
console.log('PSC1_TYPED_WORKER_FUSION_RUNTIME: '+JSON.stringify(result));
