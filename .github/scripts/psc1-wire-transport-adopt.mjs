// Adopt exact tested source/package identities; no compiler build or repeated suite.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import{spawnSync}from'node:child_process';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const q=JSON.parse(fs.readFileSync('docs/PSC1_WIRE_TRANSPORT_QUALIFICATION_2026-10-29.json'));
assert.equal(q.status,'qualified-finite-linux-host-and-g1-transport');
const run=(exe,args)=>{const r=spawnSync(exe,args,{encoding:'utf8',timeout:120000,maxBuffer:33554432});assert.equal(r.error,undefined);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
for(const pin of q.hostSources.pins){const b=fs.readFileSync(pin.path.slice(5));assert.equal(b.length,pin.bytes,pin.path);assert.equal(sha256(b),pin.sha256,pin.path);if(pin.path.endsWith('.mjs'))run(process.execPath,['--check',pin.path.slice(5)]);}
run('git',['diff','--exit-code',q.baseCommit,'--','packages','host','lakefile.lean','lean-toolchain']);
const archive=await readQualifiedArtifact(q.qualification,'dist/wire-transport-adoption-input');
assert.deepEqual(JSON.parse(fs.readFileSync(path.join(archive,'persistent-candidate/pins.json'))),q.hostSources);
const result=JSON.parse(fs.readFileSync(path.join(archive,'development-results/qualification.json')));assert.equal(result.status,'passed');assert.deepEqual(result,q.results);
const comparison=JSON.parse(fs.readFileSync(path.join(archive,'dedup-results/comparison.json')));assert.equal(comparison.status,'passed');assert.deepEqual(comparison,q.comparison);
const generated=await readQualifiedArtifact(q.generatedQualification,'dist/wire-transport-g1-input');
assert.deepEqual(JSON.parse(fs.readFileSync(path.join(generated,'wire-quote/qualification.json'))),q.generatedResults);
assert.deepEqual(JSON.parse(fs.readFileSync(path.join(generated,'executable-packages/compiler/build-receipt.json'))),q.generatedBuild);
const generatedManifest=fs.readFileSync(path.join(generated,'executable-packages/compiler/manifest.json'));assert.equal(sha256(generatedManifest),q.generatedResults.manifestSha256);
const sourceRows=(await import('../../psc1/host-tools/compiler-source-inputs.mjs')).readOwnedCompilerSources('Ps.CompilerUnified.Service').map(row=>({module:row.module,kind:'lean',text:row.text}));
assert.deepEqual(JSON.parse(fs.readFileSync(path.join(generated,'executable-packages/compiler/sources.json'))),sourceRows);
for(const pin of q.legacyAudit.hostPins){const current=q.hostSources.pins.find(row=>row.path===pin.path);assert.deepEqual(current,pin);}
const pairedArchive=await readQualifiedArtifact(q.pairedQualification,'dist/wire-transport-paired-input');
assert.deepEqual(JSON.parse(fs.readFileSync(path.join(pairedArchive,'report.json'))),q.paired);
const receipt=JSON.parse(fs.readFileSync(path.join(archive,'modular-toolchain/package-receipt.json')));assert.deepEqual(receipt,q.package);
const out=path.resolve('dist/proofscript-wire-transport-linux-x64');fs.mkdirSync(out,{recursive:true});assert.equal(fs.readdirSync(out).length,0);
const tar=path.join(archive,'modular-toolchain/tarballs',receipt.tarball),bytes=fs.readFileSync(tar);assert.equal(bytes.length,receipt.bytes);assert.equal(sha256(bytes),receipt.sha256);fs.writeFileSync(path.join(out,receipt.tarball),bytes);
const extraction='dist/semantic-adoption-root';fs.mkdirSync(extraction,{recursive:true});const names=run('tar',['tzf',tar]).split('\n').filter(Boolean);assert.ok(names.every(n=>n.startsWith('package/')&&!n.includes('\\')&&!n.split('/').includes('..')));run('tar',['xzf',tar,'-C',extraction]);
const pkg=path.join(extraction,'package'),descriptor=fs.readFileSync(path.join(pkg,'node_modules/@proofscript/compiler/dist/host/UNIVERSAL_DISTRIBUTION.json'));assert.equal(sha256(descriptor),receipt.consumerDescriptorsSha256);
const distribution=JSON.parse(descriptor),expected=[distribution.targetConsumers.ts,...distribution.targetConsumers.ts.dependencies],matched=new Set();
const sdkDirectory=path.join(archive,'modular-toolchain/typescript-platforms/linux-x64'),sdk=JSON.parse(fs.readFileSync(path.join(sdkDirectory,'resources.json')));assert.equal(sdk.platform,'linux-x64');assert.equal(sdk.packages.length,expected.length);
for(const item of sdk.packages){assert.equal(item.tarball,path.basename(item.tarball));const b=fs.readFileSync(path.join(sdkDirectory,item.tarball)),digest=sha256(b),entry=expected.find(e=>e.tarballSha256===digest);assert.ok(entry);assert.ok(!matched.has(entry.package));matched.add(entry.package);fs.writeFileSync(path.join(out,item.tarball),b);}
for(const name of ['LICENSE','NOTICE'])if(fs.existsSync(path.join(pkg,name)))fs.copyFileSync(path.join(pkg,name),path.join(out,name));
fs.writeFileSync(path.join(out,'QUALIFICATION.json'),JSON.stringify(q,null,2)+'\n');
fs.writeFileSync(path.join(out,'COMPARISON.json'),JSON.stringify(comparison,null,2)+'\n');
fs.writeFileSync(path.join(out,'PAIRED_QUOTING.json'),JSON.stringify(q.paired,null,2)+'\n');
fs.writeFileSync(path.join(out,'INSTALL.md'),'# ProofScript .9 Linux x64 development package\n\nRequires Node >=22.23.3; this host is qualified on Linux/Node22.23.3 only.\nExtract this ZIP and run:\n\n```sh\nnpm init -y\nnpm install --offline --ignore-scripts ./'+receipt.tarball+' '+sdk.packages.map(p=>'./'+p.tarball).join(' ')+'\nnpm exec -- psc init\nnpm exec -- psc check\nnpm exec -- psc build --target ts --out out --watch\n```\n\nWarm builds use the generated original-IR check once; check-only retains adapter validation.\nThe installed graph retains source17ce1991 and its qualified G3 identities.\nNative quoting is checked in a separate new G1 graph and is NOT active in this retained graph.\nNew-source G2/G3/fixed-point qualification is required before graph promotion.\nWatch reuses compiler modules and equivalent private immutable semantic/emitter inputs.\nChanged bodies invalidate affected work; errors clear reuse. Independent checking and strict IR always remain.\nFull audit dumps: --evidence full. JS/TS/Rust/Wasm output backend architecture is unchanged; optional Python/PHP remain separate.\nNo registry publication. .4 retains its existing Windows/macOS evidence; .9 host qualification is Linux/Node only.\nCOMPARISON.json records actual same-runner comment-edit observations, not universal speed or body-edit guarantees.\n');
const inventory=fs.readdirSync(out).sort().map(file=>({file,bytes:fs.statSync(path.join(out,file)).size,sha256:sha256(fs.readFileSync(path.join(out,file)))}));
fs.writeFileSync(path.join(out,'SHA256SUMS'),inventory.map(i=>i.sha256+'  '+i.file).join('\n')+'\n');
const adoption={schema:'psc1-wire-transport-source-adoption/1',commit:process.env.GITHUB_SHA,status:'passed',sourcePins:q.hostSources.pins.length,qualificationRun:q.qualification.run,packageSha256:receipt.sha256,currentSourceMatchesCheckedG1:true,retainedInstalledGraphUnchanged:true,nativeQuoteEnabledInInstalledGraph:false,files:inventory};fs.writeFileSync(path.join(out,'ADOPTION.json'),JSON.stringify(adoption,null,2)+'\n');
run('python3',['-c','import pathlib,zipfile; r=pathlib.Path("dist/proofscript-wire-transport-linux-x64"); z=zipfile.ZipFile(str(r)+".zip","w",zipfile.ZIP_DEFLATED); [z.write(p,p.name) for p in sorted(r.iterdir())]; z.close()']);
console.log('PSC1_WIRE_TRANSPORT_ADOPTION '+JSON.stringify(adoption));
