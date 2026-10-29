// Reuse the passing G1 graph; no compiler rebuild for benchmark-controller changes.
import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const pin=JSON.parse(fs.readFileSync('../.github/psc1/quote-paired-input.json')),archive=await readQualifiedArtifact(pin,'dist/quote-paired-input');
const pins=JSON.parse(fs.readFileSync(path.join(archive,'wire-quote/host-pins.json'))),hostSources=JSON.parse(fs.readFileSync(path.join(archive,'wire-quote/host-sources.json')));
for(const row of pins.pins){const value=hostSources[row.path];assert.equal(Buffer.byteLength(value),row.bytes);assert.equal(sha256(value),row.sha256);fs.writeFileSync(row.path.slice(5),value);}
const nativeSource=hostSources['psc1/host-tools/prepared-engine.mjs'],needle='const nativeQuoteEntry = service.Ps_Internal_CompilerService_compilePreparedWithQuote;';
assert.equal(nativeSource.split(needle).length,2);
const reference=nativeSource.replace(needle,'const nativeQuoteEntry = undefined;');
fs.writeFileSync('host-tools/quote-portable-reference.mjs',reference);
const q=JSON.parse(fs.readFileSync('docs/PSC1_SEMANTIC_REUSE_QUALIFICATION_2026-10-29.json')),oldArchive=await readQualifiedArtifact(q.qualification,'dist/quote-paired-reference'),tar=path.join(oldArchive,'modular-toolchain/tarballs',q.package.tarball);assert.equal(sha256(fs.readFileSync(tar)),q.package.sha256);
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

const directory=fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()),'psc1-quote-paired-'));
const run=args=>{const r=spawnSync(process.execPath,args,{cwd:directory,encoding:'utf8',timeout:240000,maxBuffer:33554432});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
const report={schema:'psc1-quote-paired/1',commit:process.env.GITHUB_SHA,graphSource:pin.commit,status:'running',scope:'paired candidate-only prepared calls; same graph, capture/reuse/IR policies; fixed native versus generated portable quoting; not end-to-end CLI',variants:[]};
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');run([path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js'),'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),'--registry','http://127.0.0.1:9',tar]);
 const fixture=path.join(directory,'application.json');fs.writeFileSync(fixture,JSON.stringify({entryModule:'PracticalCli.Run',sources,expected}));
 fs.copyFileSync('../.github/scripts/psc1-quoting-paired-harness.mjs',path.join(directory,'exercise.mjs'));
 const graphRoot=path.join(archive,'executable-packages/compiler/candidate'),manifestFile=path.join(archive,'executable-packages/compiler/manifest.json'),manifestSha=sha256(fs.readFileSync(manifestFile));
 for(const variant of['js','ts']){
  const text=run(['--max-old-space-size=4096','--stack-size=8192',path.join(directory,'exercise.mjs'),variant,graphRoot,manifestFile,manifestSha,process.cwd(),fixture]),mark='PSC1_QUOTE_PAIRED_VARIANT ',line=text.split('\n').find(x=>x.startsWith(mark));assert.ok(line,text);const result=JSON.parse(line.slice(mark.length));report.variants.push(result);console.log(line);
 }
 report.status='passed';report.referenceAdapterSha256=sha256(reference);
}finally{
 fs.mkdirSync('dist/quote-paired',{recursive:true});fs.writeFileSync('dist/quote-paired/report.json',JSON.stringify(report,null,2)+'\n');console.log('PSC1_QUOTE_PAIRED '+JSON.stringify(report));fs.rmSync(directory,{recursive:true,force:true});
}
