// Controlled application-only comparison using exact previously built roots.
import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';import{sha256,readQualifiedArtifact}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const sources=[],seen=new Set(),active=new Set();
function visit(module){
 if(seen.has(module))return;assert.match(module,/^[A-Za-z_][A-Za-z0-9_.]*$/);assert.ok(!active.has(module));
 const relative=module.replaceAll('.','/')+'.lean',matches=['test/applications','stdlib'].map(root=>path.join(root,relative)).filter(fs.existsSync);assert.equal(matches.length,1,module);
 const text=fs.readFileSync(matches[0],'utf8');active.add(module);
 for(const m of text.matchAll(/^import\s+(.+)$/gm))for(const dependency of m[1].trim().split(/\s+/))visit(dependency);
 active.delete(module);seen.add(module);sources.push({module,kind:'lean',text});
}
visit('PracticalCli.Run');
const expected=JSON.parse(fs.readFileSync('docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json')).cases.find(c=>c.id==='unicode-records');assert.ok(expected);

const q=JSON.parse(fs.readFileSync('docs/PSC1_SEMANTIC_REUSE_QUALIFICATION_2026-10-29.json'));
const prior=await readQualifiedArtifact(q.qualification,'dist/dedup-previous-package');
const current=JSON.parse(fs.readFileSync('dist/modular-toolchain/package-receipt.json'));
const roots=[
 {label:'qualified-.7',file:path.join(prior,'modular-toolchain/tarballs',q.package.tarball),sha256:q.package.sha256},
 {label:'candidate-.8',file:path.resolve('dist/modular-toolchain/tarballs',current.tarball),sha256:current.sha256}
],reports=[];
for(const root of roots){
 assert.equal(sha256(fs.readFileSync(root.file)),root.sha256);
 const directory=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-semantic-comparison-'));
 const run=args=>{const r=spawnSync(process.execPath,args,{cwd:directory,encoding:'utf8',timeout:240000,maxBuffer:33554432});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
 try{
  fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
  run([path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js'),'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),'--registry','http://127.0.0.1:9',root.file]);
  fs.copyFileSync('../.github/scripts/psc1-persistent-profile-driver.mjs',path.join(directory,'profile.mjs'));
  const fixture=path.join(directory,'application.json');fs.writeFileSync(fixture,JSON.stringify({entryModule:'PracticalCli.Run',sources,expected}));
  const text=run([path.join(directory,'profile.mjs'),'warm-app',fixture]),line=text.split('\n').find(l=>l.startsWith('PSC1_PERSISTENT_PROFILE '));assert.ok(line,text);
  const report=JSON.parse(line.slice('PSC1_PERSISTENT_PROFILE '.length));assert.ok(report.outcomes.every(r=>r.application?.status==='passed'&&r.admission==='accepted'));
  reports.push({label:root.label,sha256:root.sha256,report});
 }finally{fs.rmSync(directory,{recursive:true,force:true});}
}
const stable=reports.map(r=>({label:r.label,meanMs:r.report.outcomes.slice(1).reduce((n,o)=>n+o.compileWallMs,0)/2}));
const comparison={schema:'psc1-semantic-controlled-comparison/1',commit:process.env.GITHUB_SHA,status:'passed',scope:'Linux Node22.23.3; 11-module PracticalCli.Run; comment-only leaf edits; warm means exclude first; observations not universal guarantee',stable,speedup:stable[0].meanMs/stable[1].meanMs,reports};
fs.mkdirSync('dist/dedup-results',{recursive:true});fs.writeFileSync('dist/dedup-results/comparison.json',JSON.stringify(comparison,null,2)+'\n');
console.log('PSC1_DEDUP_CONTROLLED_COMPARISON '+JSON.stringify(comparison));
