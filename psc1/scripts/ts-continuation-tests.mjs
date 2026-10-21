import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {formatEcma} from '../host-tools/artifacts.mjs';
const folder=path.resolve('dist/scoped-correctness/ts-continuations');
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
function run(command,args,options={}){
 const result=spawnSync(command,args,{encoding:'utf8',timeout:30000,maxBuffer:8*1024*1024,...options});
 assert.equal(result.error,undefined,result.error?.message);assert.equal(result.status,0,result.stdout+result.stderr);
 return result.stdout;
}
run('.lake/build/bin/psc1_ts_continuation_tests',[]);
const raw=path.join(folder,'raw.ts'),formatted=path.join(folder,'module.ts');
fs.writeFileSync(formatted,(await formatEcma(fs.readFileSync(raw,'utf8'),'ts')).text);
assert.ok(process.env.PSC1_TSC,'independent pinned TypeScript checker required');
run(process.execPath,[process.env.PSC1_TSC,'--ignoreConfig','--strict','--target','ES2022','--module','ESNext',
 '--moduleResolution','Bundler','--outDir',path.join(folder,'consumer'),formatted]);
fs.writeFileSync(path.join(folder,'consumer/package.json'),'{"type":"module"}\n');
const module=path.join(folder,'consumer/module.js'),consumer=path.join(folder,'observe.mjs');
fs.writeFileSync(consumer,`import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const m=await import(pathToFileURL(process.argv[2]).href);
assert.equal(m.even(500000n),1n);assert.equal(m.odd(500001n),1n);
assert.equal(m.sum(5000n),12502500n);
assert.equal(m.letValue(7n),8n);assert.equal(m.letTail(7n),1n);
assert.equal(m.condition(0n),7n);assert.equal(m.condition(1n),9n);
const captured=m.make(3n);assert.equal(captured(3n),1n);assert.equal(captured(4n),0n);
assert.equal(m.capture(5n),7n);
const marks=[];
const ordered=m.ordered(n=>{marks.push("callee");assert.equal(n,0n);return(a,b)=>{marks.push("call");return a+b;};},
 n=>{marks.push("left");assert.equal(n,1n);return n;},n=>{marks.push("right");assert.equal(n,2n);return n;});
assert.equal(ordered,3n);assert.deepEqual(marks,["callee","left","right","call"]);
const trap=new Error("foreign trap sentinel");
for(const name of ["trapTail","trapValue"])assert.throws(()=>m[name](()=>{throw trap;}),error=>error===trap);
const maxRssKiB=process.resourceUsage().maxRSS;
console.log(JSON.stringify({passed:true,mutualTailCalls:1000001,nonTailDepth:5000,maxRssKiB,
 checks:["mutual tail results","non-tail arithmetic continuation","local value continuation","local tail result",
 "condition continuation","escaping lambda owner","old captured value","callee and operands exact-once left-to-right",
 "tail foreign trap escapes","non-tail foreign trap escapes"]}));
`);
const observed=JSON.parse(run(process.execPath,[consumer,module]));
assert.equal(observed.passed,true);assert.ok(observed.maxRssKiB>0&&observed.maxRssKiB<=262144,'bounded tail-driver process RSS');
const divergent=spawnSync(process.execPath,['--input-type=module','-e',
 'import {pathToFileURL} from "node:url";const m=await import(pathToFileURL(process.argv[1]).href);m.strictValue(0n);',module],
 {encoding:'utf8',timeout:2000,maxBuffer:8*1024*1024});
assert.equal(divergent.error?.code,'ETIMEDOUT','unused divergent local RHS must remain strict');
const receipt={schema:'psc1-ts-continuation-runtime/1',testedCommit:process.env.GITHUB_SHA,
 branchHeadCommit:process.env.PSC1_HEAD_SHA,passed:true,independentTypeCheck:true,strictInputIr:true,
 nativeFixtureSha256:sha('test/TsContinuationTests.lean'),rawSha256:sha(raw),formattedSha256:sha(formatted),
 executableSha256:sha(module),...observed,strictDivergenceDeadlineMs:2000,maxRssBoundKiB:262144,
 scope:'Backend IR regression; independently admitted real compiler application supplies source evidence.'};
fs.writeFileSync(path.join(folder,'results.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_TS_CONTINUATION_RUNTIME: '+JSON.stringify(receipt));
