// Attribute real compiler work only; this instrumented package is not a release claim.
import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';
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
const input=path.resolve('dist/modular-toolchain'),receipt=JSON.parse(fs.readFileSync(path.join(input,'package-receipt.json')));
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-semantic-phase-'));
const run=args=>{const r=spawnSync(process.execPath,args,{cwd:directory,encoding:'utf8',timeout:240000,maxBuffer:33554432});assert.equal(r.error,undefined);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 run([path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js'),'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),'--registry','http://127.0.0.1:9',path.join(input,'tarballs',receipt.tarball)]);
 fs.copyFileSync('../.github/scripts/psc1-persistent-profile-driver.mjs',path.join(directory,'profile.mjs'));
 const fixture=path.join(directory,'application.json');fs.writeFileSync(fixture,JSON.stringify({entryModule:'PracticalCli.Run',sources,expected}));
 const text=run([path.join(directory,'profile.mjs'),'warm-app',fixture]),line=text.split('\n').find(l=>l.startsWith('PSC1_PERSISTENT_PROFILE '));assert.ok(line,text);
 const report=JSON.parse(line.slice('PSC1_PERSISTENT_PROFILE '.length));assert.ok(report.outcomes.every(x=>x.admission==='accepted'&&x.application?.status==='passed'));
 fs.mkdirSync('dist/semantic-phase',{recursive:true});fs.writeFileSync('dist/semantic-phase/report.json',JSON.stringify({commit:process.env.GITHUB_SHA,receipt,report},null,2)+'\n');
 console.log('PSC1_SEMANTIC_PHASES '+JSON.stringify({commit:process.env.GITHUB_SHA,status:'passed',outcomes:report.outcomes,phases:report.phases,maxRssKiB:report.maxRssKiB,scope:'real application; instrumented host; source compiler and kernel unchanged'}));
}finally{fs.rmSync(directory,{recursive:true,force:true});}
