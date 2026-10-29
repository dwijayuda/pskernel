// Adopt exact terminal installed bytes; no compiler or package rebuild.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
import{readOwnedCompilerSources}from'../../psc1/host-tools/compiler-source-inputs.mjs';
const q=JSON.parse(fs.readFileSync('docs/PSC1_WIRE_INSTALLED_QUALIFICATION_2026-10-30.json'));assert.equal(q.status,'qualified-finite-linux-node');
const archive=await readQualifiedArtifact(q.qualification,'dist/wire-installed-adoption-input');
const pins=JSON.parse(fs.readFileSync(path.join(archive,'wire-installed/pins.json'))),sources=JSON.parse(fs.readFileSync(path.join(archive,'wire-installed/sources.json')));assert.deepEqual(pins,q.hostSources);
for(const p of pins.pins){const b=fs.readFileSync(p.path.slice(5));assert.equal(b.length,p.bytes);assert.equal(sha256(b),p.sha256);assert.equal(b.toString('utf8'),sources[p.path]);}
const results=JSON.parse(fs.readFileSync(path.join(archive,'development-results/qualification.json'))),comparison=JSON.parse(fs.readFileSync(path.join(archive,'dedup-results/comparison.json'))),pkg=JSON.parse(fs.readFileSync(path.join(archive,'modular-toolchain/package-receipt.json')));
assert.equal(results.status,'passed');assert.equal(comparison.status,'passed');assert.deepEqual(results,q.results);assert.deepEqual(comparison,q.comparison);assert.deepEqual(pkg,q.package);assert.deepEqual(results.package,pkg);
const sq=JSON.parse(fs.readFileSync('docs/PSC1_WIRE_MODULAR_QUALIFICATION_2026-10-29.json'));assert.equal(sq.status,'qualified-finite-linux-modular-js-ts');assert.equal(sq.sourceClosureDigest,pkg.compilerSourceClosureDigest);assert.equal(sq.portableG1Seed.manifestSha256,pkg.sourceGraphManifestSha256);
const original=await readQualifiedArtifact(q.nativeG1Artifact,'dist/wire-installed-source-input');
const current=readOwnedCompilerSources('Ps.CompilerUnified.Service').map(row=>({module:row.module,kind:'lean',text:row.text}));assert.deepEqual(JSON.parse(fs.readFileSync(path.join(original,'executable-packages/compiler/sources.json'))),current);
const file=path.join(archive,'proofscript-wire-quote-linux-x64.zip');assert.ok(fs.existsSync(file));
const py=spawnSync('python3',['-c',
'import sys,json,zipfile,hashlib; z=zipfile.ZipFile(sys.argv[1]); assert z.testzip() is None; assert all(i.filename==i.filename.split("/")[-1] and "\\\\" not in i.filename for i in z.infolist()); print(json.dumps({"files":[{"file":i.filename,"bytes":i.file_size,"sha256":hashlib.sha256(z.read(i)).hexdigest()} for i in z.infolist()],"delivery":json.loads(z.read("DELIVERY.json"))}))',file],{encoding:'utf8',timeout:120000,maxBuffer:33554432});assert.equal(py.error,undefined,String(py.error));assert.equal(py.status,0,py.stderr);
const contents=JSON.parse(py.stdout);assert.deepEqual(contents.delivery,q.delivery);assert.equal(contents.delivery.status,'passed');
assert.deepEqual(contents.files.map(f=>f.file).sort(),[...q.delivery.files.map(f=>f.file),'DELIVERY.json','SHA256SUMS'].sort());for(const p of q.delivery.files)assert.deepEqual(contents.files.find(f=>f.file===p.file),p);
assert.equal(contents.files.find(f=>f.file===pkg.tarball).sha256,pkg.sha256);assert.equal(contents.files.find(f=>f.file===pkg.tarball).bytes,pkg.bytes);
const out='dist/wire-installed-adoption';assert.ok(!fs.existsSync(out));fs.mkdirSync(out,{recursive:true});fs.copyFileSync(file,path.join(out,path.basename(file)));
const adopted={schema:'psc1-wire-installed-source-adoption/1',status:'passed',commit:process.env.GITHUB_SHA,producerCommit:q.qualification.commit,qualificationRun:q.qualification.run,generationRun:sq.generationRun,sourceClosureDigest:sq.sourceClosureDigest,sourceGraphManifestSha256:pkg.sourceGraphManifestSha256,package:pkg.tarball,packageSha256:pkg.sha256,zipSha256:sha256(fs.readFileSync(file)),sourcePins:pins.pins.length,currentSourceMatchesQualifiedG1:true,nativeQuotingActive:true,rebuilt:false,noMerge:true,noPublication:true};
fs.writeFileSync(path.join(out,'ADOPTION.json'),JSON.stringify(adopted,null,2)+'\n');fs.writeFileSync(path.join(out,'SHA256SUMS'),[path.basename(file),'ADOPTION.json'].map(name=>sha256(fs.readFileSync(path.join(out,name)))+'  '+name).join('\n')+'\n');
console.log('PSC1_WIRE_INSTALLED_ADOPTION '+JSON.stringify(adopted));
