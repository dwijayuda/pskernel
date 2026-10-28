// Target-only SDK/provider acquisition; no compiler executable is installed.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readQualifiedArtifact,sha256} from './kernel435-qualified-artifact.mjs';
const out=path.resolve('dist/modular-toolchain'),input=JSON.parse(fs.readFileSync('scripts/modular-toolchain-input.json'));
const archive=await readQualifiedArtifact(input.optional,path.join(out,'optional-input'));
function find(dir){return fs.readdirSync(dir).flatMap(n=>{const p=path.join(dir,n);return fs.lstatSync(p).isDirectory()?find(p):[p];});}
const assembly=JSON.parse(fs.readFileSync(path.join(out,'package-receipt.json')));
const descriptorBytes=fs.readFileSync(path.join(out,'consumer-descriptors.json'));
assert.equal(sha256(descriptorBytes),assembly.consumerDescriptorsSha256);
const d=JSON.parse(descriptorBytes);
const descriptors=[d.targetConsumers.ts,...d.targetConsumers.ts.dependencies,d.targetConsumers.rust,...Object.values(d.dispatchPackages)];
const all=find(archive),tarballs=descriptors.map(row=>{
 const name=row.package.replace('@','').replace('/','-')+'-'+row.version+'.tgz';
 const found=all.filter(p=>path.basename(p)===name);assert.equal(found.length,1,name);
 assert.equal(sha256(fs.readFileSync(found[0])),row.tarballSha256,name);return {package:row.package,file:found[0]};
});
const sdk=spawnSync('rustup',['run','1.90.0','rustc','--print','sysroot'],{encoding:'utf8',timeout:10000});
assert.equal(sdk.error,undefined);assert.equal(sdk.status,0,sdk.stderr);
const root=sdk.stdout.trim(),pins=d.targetConsumers.rust.toolchain.files;
assert.ok(path.isAbsolute(root));assert.equal(pins.length,61);
const verify=row=>{const b=fs.readFileSync(path.join(root,row.path));assert.equal(b.length,row.bytes);assert.equal(sha256(b),row.sha256,row.path);};
const component=pins.find(row=>row.path==='lib/rustlib/components');assert.ok(component);
for(const row of pins.filter(row=>row!==component))verify(row);
const file=path.join(root,component.path),before=fs.readFileSync(file);
if(sha256(before)!==component.sha256){
 assert.equal(fs.realpathSync(file),file);assert.ok(before.length<4096&&before.toString().endsWith('\n'));
 const lines=before.toString().trimEnd().split('\n');
 assert.deepEqual([...lines].sort(),['cargo-x86_64-unknown-linux-gnu','rust-std-x86_64-unknown-linux-gnu','rustc-x86_64-unknown-linux-gnu'].sort());
 const permutations=a=>!a.length?[[]]:a.flatMap((v,i)=>permutations(a.filter((_,j)=>i!==j)).map(p=>[v,...p]));
 const exact=permutations(lines).map(p=>Buffer.from(p.join('\n')+'\n')).filter(b=>b.length===component.bytes&&sha256(b)===component.sha256);
 assert.equal(exact.length,1);assert.deepEqual(fs.readFileSync(file),before);fs.writeFileSync(file,exact[0],{flag:'r+'});
}
for(const row of pins)verify(row);
const receipt={schema:'psc1-modular-toolchain-resources/1',testedCommit:process.env.GITHUB_SHA,tarballs,rustRoot:root,rustResources:61,referenceCompilerExecuted:false};
fs.writeFileSync(path.join(out,'resources.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_MODULAR_TOOLCHAIN_RESOURCES '+JSON.stringify(receipt));
