// Project execution is permitted only in GitHub Actions Linux.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {resolveTypeScriptCli,typeScriptProfileArgs} from './typescript-cli.mjs';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
assert.match(process.env.GITHUB_SHA||'',/^[0-9a-f]{40}$/);
const dir='dist/pskernel-min/usable',pkg=path.join(dir,'package');
fs.mkdirSync(dir,{recursive:true});
const sha=data=>crypto.createHash('sha256').update(data).digest('hex');
const run=(command,args,input)=>{
 const r=spawnSync(command,args,{input,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+'\n'+r.stderr);return r.stdout;
};
fs.writeFileSync(path.join(dir,'compile.log'),run('lake',['env','lean','--run','scripts/MinKernelSourceCompile.lean','regular-runtime']));
const raw=fs.readFileSync(path.join(dir,'runtime.admissions.json'));assert.equal(raw.at(-1),10);
const canonical=raw.subarray(0,-1);fs.writeFileSync(path.join(dir,'runtime.canonical.admissions.json'),canonical);
assert.deepEqual(canonical,fs.readFileSync('dist/pskernel-min/regular-ingress/runtime.admissions.json'),'package exact complete connected runtime');
const official=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],canonical));
assert.equal(official.accepted,true);assert.equal(official.leanVersion,'4.35.0');
assert.equal(official.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const policy=JSON.parse(fs.readFileSync(path.join(dir,'runtime.source.json')));
assert.equal(policy.moduleCount,10);assert.equal(policy.origins.length,10);
assert.equal(policy.sourceAccepted,true);assert.equal(policy.targetAccepted,true);assert.equal(policy.originalIrAccepted,true);assert.equal(policy.providerChecked,false);
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([path.join(dir,'runtime.ts'),'--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
for(const sub of ['runtime','host','examples'])fs.mkdirSync(path.join(pkg,sub),{recursive:true});
fs.copyFileSync(path.join(dir,'runtime.js'),path.join(pkg,'runtime/kernel.js'));
fs.copyFileSync('packages/pskernel-min/host/ingress.mjs',path.join(pkg,'host/ingress.mjs'));
for(const name of ['index.mjs','index.d.ts','cli.mjs','worker.mjs','README.md'])fs.copyFileSync('packages/pskernel-min/standalone/'+name,path.join(pkg,name));
fs.chmodSync(path.join(pkg,'cli.mjs'),0o755);
const cases=JSON.parse(fs.readFileSync('scripts/minkernel-regular-ingress-cases.json'));
for(const name of ['nat-definition','regular-tree-fold','negative-self'])fs.writeFileSync(path.join(pkg,'examples',name+'.json'),cases.find(x=>x.id===name).source);
const sourcePolicy=JSON.parse(fs.readFileSync('dist/pskernel-min/regular-ingress/receipt.json'));
const sourceIdentities=sourcePolicy.sourceIdentities;
assert.equal(sourceIdentities.length,10);
const metadata={name:'@proofscript/pskernel-min',version:'0.1.0-r4b.1',
 sourceCommit:process.env.GITHUB_SHA,profile:'psc1-min-core-regular/1',
 fullCompilerSupported:false,productionDefault:false,generatedCodePreservation:'not-proved',
 sourceConsistency:'R4B proved source fragment; generated execution requires the compiler/runtime assumptions',
 linuxQualification:'see exact-tarball qualification.json outside package',
 sourceModules:10,sourceBytes:sourceIdentities.reduce((n,x)=>n+x.bytes,0),
 runtimePacket:{bytes:canonical.length,sha256:sha(canonical)},
 upstreamLean:{version:official.leanVersion,commit:official.leanCommit}};
fs.writeFileSync(path.join(pkg,'metadata.mjs'),'export default Object.freeze('+JSON.stringify(metadata,null,2)+');\n');
const packageJson={name:metadata.name,version:metadata.version,description:'Standalone checker for the proved bounded R4B canonical Core fragment',
 type:'module',engines:{node:'>=22.23.3'},bin:{'pskernel-min':'./cli.mjs'},
 exports:{'.':{types:'./index.d.ts',import:'./index.mjs'}},
 files:['index.mjs','index.d.ts','metadata.mjs','cli.mjs','worker.mjs','runtime','host','examples','README.md','manifest.json'],
 private:true,license:'UNLICENSED'};
fs.writeFileSync(path.join(pkg,'package.json'),JSON.stringify(packageJson,null,2)+'\n');
const entries=['index.mjs','index.d.ts','metadata.mjs','cli.mjs','worker.mjs','runtime/kernel.js','host/ingress.mjs',
 'examples/nat-definition.json','examples/regular-tree-fold.json','examples/negative-self.json','README.md','package.json'];
const manifest={schema:'pskernel-min/package-manifest/1',metadata,sourceIdentities,files:entries.map(file=>{
 const data=fs.readFileSync(path.join(pkg,file));return {path:file,bytes:data.length,sha256:sha(data)};}),officialSourceAdmission:official,
 trustBoundary:'Source consistency proof and finite native/generated/installed observations; no full compiler admission or generated-code preservation theorem.'};
fs.writeFileSync(path.join(pkg,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
const packed=JSON.parse(run('npm',['pack',path.resolve(pkg),'--json','--ignore-scripts','--pack-destination',dir]));
assert.equal(packed.length,1);
const tarball=path.join(dir,packed[0].filename),data=fs.readFileSync(tarball);
const receipt={schema:'pskernel-min/package-build/1',head:process.env.GITHUB_SHA,tarball,bytes:data.length,sha256:sha(data),
 packageFiles:packed[0].files.map(x=>x.path),manifest};
fs.writeFileSync(path.join(dir,'build-receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSKERNEL_MIN_PACKAGE_BUILT '+JSON.stringify({head:receipt.head,tarball,bytes:receipt.bytes,sha256:receipt.sha256}));
