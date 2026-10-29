// Reuse exact terminal Linux package bytes; do not rebuild the compiler or SDKs.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import{spawnSync}from'node:child_process';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const pin=JSON.parse(fs.readFileSync('../.github/psc1/semantic-qualified-input.json'));
const archive=await readQualifiedArtifact(pin,'dist/semantic-qualified-input');
const receipt=JSON.parse(fs.readFileSync(path.join(archive,'modular-toolchain/package-receipt.json')));
const tar=path.join(archive,'modular-toolchain/tarballs',receipt.tarball);assert.equal(sha256(fs.readFileSync(tar)),receipt.sha256);
fs.mkdirSync('dist/modular-toolchain',{recursive:true});fs.cpSync(path.join(archive,'modular-toolchain'),'dist/modular-toolchain',{recursive:true});
fs.cpSync(path.join(archive,'persistent-candidate'),'dist/persistent-candidate',{recursive:true});
fs.cpSync(path.join(archive,'semantic-phase'),'dist/semantic-phase',{recursive:true});
const old=await readQualifiedArtifact({run:40863008602,job:123410688965,commit:'c83039f05a445f496f71aea2429ba75c61b81f40',artifact:12892806521,zipSha256:'31a902490abbc1b93816b25123375e4928b85f43f9a23802605a771da81cde7a'},'dist/semantic-sdk-input');
const zip=path.join(old,'proofscript-persistent-linux-x64.zip'),sdk='dist/semantic-sdk-expanded';fs.mkdirSync(sdk);
const py=spawnSync('python3',['-c','import pathlib,zipfile,sys; r=pathlib.Path(sys.argv[2]).resolve(); z=zipfile.ZipFile(sys.argv[1]); assert all((r/i.filename).resolve().is_relative_to(r) for i in z.infolist()); z.extractall(r)',zip,sdk],{encoding:'utf8',timeout:120000});assert.equal(py.status,0,py.stderr);
const files=fs.readdirSync(sdk).filter(f=>f.endsWith('.tgz')&&!f.startsWith('proofscript-'));assert.ok(files.length>0);
const sdkManifest=JSON.parse(fs.readFileSync(path.join(sdk,'ADOPTION.json')));
for(const file of files){const expected=sdkManifest.files.find(r=>r.file===file);assert.ok(expected);assert.equal(sha256(fs.readFileSync(path.join(sdk,file))),expected.sha256);}
const target='dist/modular-toolchain/typescript-platforms/linux-x64';fs.mkdirSync(target,{recursive:true});
for(const file of files)fs.copyFileSync(path.join(sdk,file),path.join(target,file));
fs.writeFileSync(path.join(target,'resources.json'),JSON.stringify({platform:'linux-x64',packages:files.map(tarball=>({tarball}))}));
console.log('PSC1_SEMANTIC_PACKAGE_REUSE '+JSON.stringify({producer:pin.commit,package:receipt.tarball,sha256:receipt.sha256,sdkFiles:files}));
