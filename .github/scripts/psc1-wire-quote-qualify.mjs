// Actual new G1 compiler graph: independent checking, unchanged legacy wire and native fast path.
import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const q=JSON.parse(fs.readFileSync('docs/PSC1_SEMANTIC_REUSE_QUALIFICATION_2026-10-29.json')),archive=await readQualifiedArtifact(q.qualification,'dist/wire-quote/qualified-reference');
const tar=path.join(archive,'modular-toolchain/tarballs',q.package.tarball);assert.equal(sha256(fs.readFileSync(tar)),q.package.sha256);
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

const directory=fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()),'psc1-wire-quote-'));
const run=(args,timeout=240000)=>{const r=spawnSync(process.execPath,args,{cwd:directory,encoding:'utf8',timeout,maxBuffer:33554432});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
const report={schema:'psc1-wire-quote-g1-qualification/1',testedCommit:process.env.GITHUB_SHA,status:'running',scope:'new G1 JS/TS graph and host serialization; not G2/G3/fixed points or default root promotion',variants:[]};
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 run([path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js'),'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),'--registry','http://127.0.0.1:9',tar]);
 const fixture=path.join(directory,'application.json');fs.writeFileSync(fixture,JSON.stringify({entryModule:'PracticalCli.Run',sources,expected}));
 fs.copyFileSync('../.github/scripts/psc1-wire-quote-harness.mjs',path.join(directory,'exercise.mjs'));
 const graphRoot=path.resolve('dist/executable-packages/compiler/candidate'),manifestFile=path.resolve('dist/executable-packages/compiler/manifest.json'),manifestSha=sha256(fs.readFileSync(manifestFile));
 for(const variant of['js','ts']){
  const text=run(['--max-old-space-size=4096','--stack-size=8192',path.join(directory,'exercise.mjs'),variant,graphRoot,manifestFile,manifestSha,process.cwd(),fixture]);
  const mark='PSC1_WIRE_QUOTE_VARIANT ',line=text.split('\n').find(l=>l.startsWith(mark));assert.ok(line,text);const data=JSON.parse(line.slice(mark.length));report.variants.push(data);console.log(line);
 }
 report.status='passed';report.manifestSha256=manifestSha;report.newCompilerSourceClosureDigest=JSON.parse(fs.readFileSync(manifestFile)).sourceClosureDigest;
}catch(error){report.status='failed';report.failure=String(error.stack||error);throw error;}
finally{fs.writeFileSync('dist/wire-quote/qualification.json',JSON.stringify(report,null,2)+'\n');console.log('PSC1_WIRE_QUOTE_QUALIFICATION '+JSON.stringify(report));fs.rmSync(directory,{recursive:true,force:true});}
