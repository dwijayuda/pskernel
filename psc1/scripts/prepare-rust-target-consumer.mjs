// Optional Linux Rust target consumer, independent of generated compiler execution.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';
import assert from 'node:assert/strict';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const out=path.resolve('dist/rust-target-consumer');fs.mkdirSync(out,{recursive:true});
const run=(exe,args,cwd)=>{const r=spawnSync(exe,args,{cwd,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout.trim();};
assert.equal(process.platform,'linux');assert.equal(process.arch,'x64');
const sdk=run('rustup',['run','1.90.0','rustc','--print','sysroot']);
assert.match(run(path.join(sdk,'bin/rustc'),['--version']),/^rustc 1\.90\.0 /);
function inventory(root,prefix=''){return fs.readdirSync(path.join(root,prefix)).sort().flatMap(name=>{
 const relative=prefix?prefix+'/'+name:name,p=path.join(root,relative),st=fs.lstatSync(p);
 assert.ok(!st.isSymbolicLink(),'consumer resources must be regular');
 if(st.isDirectory())return inventory(root,relative);
 assert.ok(st.isFile());const bytes=fs.readFileSync(p);return [{path:relative,bytes:bytes.length,sha256:sha(bytes)}];
});}
const stage=path.join(out,'package');fs.rmSync(stage,{recursive:true,force:true});fs.mkdirSync(stage);
const deps=path.join(out,'deps');fs.mkdirSync(deps,{recursive:true});
fs.writeFileSync(path.join(deps,'Cargo.toml'),'[package]\nname="psc1-generated-target"\nversion="0.0.0"\nedition="2021"\n[[bin]]\nname="psc1-generated-target"\npath="main.rs"\n[dependencies]\nnum-bigint="=0.4.6"\nnum-traits="=0.2.19"\n');
fs.writeFileSync(path.join(deps,'main.rs'),'fn main(){}\n');
fs.copyFileSync('scripts/fixtures/selfhost-rust.Cargo.lock',path.join(deps,'Cargo.lock'));
run('rustup',['run','1.90.0','cargo','build','--release','--locked','--manifest-path',path.join(deps,'Cargo.toml')]);
fs.mkdirSync(path.join(stage,'deps'));
for(const file of fs.readdirSync(path.join(deps,'target/release/deps')))if(file.endsWith('.rlib'))fs.copyFileSync(path.join(deps,'target/release/deps',file),path.join(stage,'deps',file));
const inspector=path.resolve('scripts/rust-api-inspector'),lock=path.join(inspector,'Cargo.lock');
const locked=fs.existsSync(lock);
if(!locked){assert.equal(process.env.PSC1_RUST_CONSUMER_DIAGNOSTIC,'1');run('rustup',['run','1.90.0','cargo','generate-lockfile','--manifest-path',path.join(inspector,'Cargo.toml')]);}
console.log('PSC1_RUST_API_LOCK='+JSON.stringify(fs.readFileSync(lock,'utf8')));
run('rustup',['run','1.90.0','cargo','build','--release','--locked','--manifest-path',path.join(inspector,'Cargo.toml')]);
fs.copyFileSync(path.join(inspector,'target/release/psc1-rust-api-inspector'),path.join(stage,'api-inspector'));fs.chmodSync(path.join(stage,'api-inspector'),0o755);
fs.copyFileSync(lock,path.join(stage,'inspector.Cargo.lock'));fs.copyFileSync('scripts/fixtures/selfhost-rust.Cargo.lock',path.join(stage,'target.Cargo.lock'));
const sdkFiles=[...inventory(sdk,'lib'),...inventory(sdk,'libexec'),...inventory(sdk,'bin').filter(r=>r.path==='bin/rustc')];
const toolchain={version:'1.90.0',platform:'linux',arch:'x64',directoryName:path.basename(sdk),files:sdkFiles};
fs.writeFileSync(path.join(stage,'index.mjs'),'export const target="rust";\n');
fs.writeFileSync(path.join(stage,'package.json'),JSON.stringify({name:'@proofscript/rust-target-consumer-linux-x64',version:'0.1.0-psc1.6',type:'module',private:true,os:['linux'],cpu:['x64'],main:'index.mjs',exports:{'.':'./index.mjs','./package.json':'./package.json'},files:['index.mjs','api-inspector','deps','inspector.Cargo.lock','target.Cargo.lock']},null,2)+'\n');
fs.writeFileSync(path.join(out,'descriptor.json'),JSON.stringify({schema:'psc1-rust-target-consumer/1',locked,package:'@proofscript/rust-target-consumer-linux-x64',version:'0.1.0-psc1.6',entry:'index.mjs',inspector:'api-inspector',files:inventory(stage),toolchain},null,2)+'\n');
console.log('PSC1_RUST_TARGET_CONSUMER: '+JSON.stringify({locked,sdkFiles:sdkFiles.length,sdkBytes:sdkFiles.reduce((n,r)=>n+r.bytes,0),largestSdkFile:Math.max(...sdkFiles.map(r=>r.bytes)),packageFiles:inventory(stage).length}));
