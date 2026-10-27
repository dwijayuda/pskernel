// Reuse the existing exact SDK policy from psc1-cli.yml; no runtime verifier changes.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {sha256} from './kernel435-qualified-artifact.mjs';
const root=path.resolve('packages/compiler/dist/implementation');
const d=JSON.parse(fs.readFileSync(path.join(root,'UNIVERSAL_DISTRIBUTION.json')));
const {verifyFile}=await import(pathToFileURL(path.join(root,'host-tools/installed-engine-resolver.mjs')).href);
const result=spawnSync('rustup',['run','1.90.0','rustc','--print','sysroot'],{encoding:'utf8',timeout:10000});
assert.equal(result.status,0,result.stderr);const sdk=result.stdout.trim(),pins=d.targetConsumers.rust.toolchain.files;
assert.ok(path.isAbsolute(sdk));assert.equal(pins.length,61);
const componentPin=pins.find(p=>p.path==='lib/rustlib/components');assert.ok(componentPin);
for(const pin of pins.filter(p=>p!==componentPin))verifyFile(sdk,pin,512*1024*1024);
const file=path.join(sdk,componentPin.path),before=fs.readFileSync(file);
if(sha256(before)!==componentPin.sha256){
 assert.equal(fs.realpathSync(file),file);assert.ok(fs.lstatSync(file).isFile());assert.ok(before.length<4096);
 const text=before.toString('utf8');assert.ok(text.endsWith('\n'));const lines=text.slice(0,-1).split('\n');
 assert.deepEqual([...lines].sort(),['cargo-x86_64-unknown-linux-gnu','rust-std-x86_64-unknown-linux-gnu','rustc-x86_64-unknown-linux-gnu'].sort());
 const permutations=values=>values.length===0?[[]]:values.flatMap((v,i)=>permutations(values.filter((_,j)=>i!==j)).map(rest=>[v,...rest]));
 const matching=permutations(lines).map(v=>Buffer.from(v.join('\n')+'\n')).filter(b=>b.length===componentPin.bytes&&sha256(b)===componentPin.sha256);
 assert.equal(matching.length,1);assert.deepEqual(fs.readFileSync(file),before);fs.writeFileSync(file,matching[0],{flag:'r+'});
}
for(const pin of pins)verifyFile(sdk,pin,512*1024*1024);
fs.writeFileSync('dist/npm-packages/rust-sdk.json',JSON.stringify({schema:'psc1-package-sdk/1',status:'passed',sdk,resources:61,
 metadataRestored:sha256(before)!==componentPin.sha256},null,2)+'\n');
console.log('PSC1_PACKAGE_RUST_SDK '+JSON.stringify({status:'passed',resources:61,sdk}));
