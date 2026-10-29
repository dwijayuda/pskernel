// One controlled comparison on one Linux runner; reuse both exact installed roots.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';
const sources=[],seen=new Set(),active=new Set();
function visit(module){
 if(seen.has(module))return;assert.match(module,/^[A-Za-z_][A-Za-z0-9_.]*$/);assert.ok(!active.has(module));
 const relative=module.replaceAll('.','/')+'.lean',matches=['test/applications','stdlib'].map(root=>path.join(root,relative)).filter(fs.existsSync);assert.equal(matches.length,1,module);
 const text=fs.readFileSync(matches[0],'utf8');active.add(module);
 for(const m of text.matchAll(/^import\s+(.+)$/gm))for(const dependency of m[1].trim().split(/\s+/))visit(dependency);
 active.delete(module);seen.add(module);sources.push({module,kind:'lean',text});
}
visit('PracticalCli.Run');
const contract=JSON.parse(fs.readFileSync('docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json')),expected=contract.cases.find(c=>c.id==='unicode-records');assert.ok(expected);
const fixture=path.resolve('dist/persistent-application-input.json');
fs.writeFileSync(fixture,JSON.stringify({entryModule:'PracticalCli.Run',sources,expected}));
const run=file=>{const r=spawnSync(process.execPath,[file],{encoding:'utf8',timeout:600000,maxBuffer:33554432,env:{...process.env,PSC1_PROFILE_APPLICATION_FILE:fixture}});assert.equal(r.error,undefined);assert.equal(r.status,0,r.stdout+r.stderr);};
run('../.github/scripts/psc1-persistent-profile.mjs');
run('../.github/scripts/psc1-persistent-after.mjs');
const before=JSON.parse(fs.readFileSync('dist/persistent-profile/results.json'));
const after=JSON.parse(fs.readFileSync('dist/persistent-results/profile.json'));
assert.equal(before.package.version,'0.1.0-psc1-modular.5');assert.equal(after.receipt.version,'0.1.0-psc1-modular.6');
function measurements(reports){
 return reports.map(r=>{
  const values=r.outcomes.map(x=>x.compileWallMs);assert.ok(values.every(Number.isFinite));
  const stable=r.mode.startsWith('warm')?values.slice(1):values;
  if(r.mode==='warm-app')assert.ok(r.outcomes.every(x=>x.application?.status==='passed'));
  return {mode:r.mode,meanMs:stable.reduce((a,b)=>a+b,0)/stable.length,samplesMs:values,reads:r.total.reads,bytes:r.total.bytes,maxRssKiB:r.maxRssKiB,memoryScope:r.maxRssScope};
 });
}
const old=measurements(before.reports),next=measurements(after.reports);
const rows=next.map(row=>{const prior=old.find(x=>x.mode===row.mode);assert.ok(prior);return {mode:row.mode,beforeMs:prior.meanMs,afterMs:row.meanMs,speedup:prior.meanMs/row.meanMs,beforeBytes:prior.bytes,afterBytes:row.bytes};});
const report={schema:'psc1-persistent-controlled-comparison/1',commit:process.env.GITHUB_SHA,status:'passed',platform:process.platform,arch:process.arch,node:process.version,beforePackage:before.package,afterPackage:after.receipt,application:{entryModule:'PracticalCli.Run',sources:sources.length,sourceBytes:sources.reduce((n,s)=>n+Buffer.byteLength(s.text),0),case:'unicode-records',actualExecution:'passed for both installed packages and all three edits'},rows,before:old,after:next,scope:'one runner; tiny source and one existing real application; warm means exclude first request; no general speed guarantee'};
const out='dist/proofscript-persistent-linux-x64';
fs.writeFileSync(path.join(out,'COMPARISON.json'),JSON.stringify(report,null,2)+'\n');
fs.writeFileSync(path.join(out,'MEASUREMENTS.md'),'# Same-runner installed comparison\n\nCold and warm API compilation on Linux/Node'+process.version+'. Warm means exclude the first request.\n\n| Workload | .5 | .6 | Speedup |\n| --- | ---: | ---: | ---: |\n'+rows.map(r=>'| '+r.mode+' | '+r.beforeMs.toFixed(0)+'ms | '+r.afterMs.toFixed(0)+'ms | '+r.speedup.toFixed(2)+'x |').join('\n')+'\n\nThe existing multi-module CLI/JSON application compiles and executes its Unicode-record case under both packages after each leaf edit. The official kernel is unchanged and checks each issued request. These are observational samples, not a universal performance guarantee. Memory scope excludes subprocesses; see COMPARISON.json.\n');
console.log('PSC1_PERSISTENT_COMPARISON '+JSON.stringify({status:'passed',rows,application:report.application}));
