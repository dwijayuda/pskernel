// Finite metadata/notice overlay on qualified npm artifacts. No executable is rebuilt.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {applyProjectLicense,projectOwnedName} from './license.mjs';
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const legal=new Set(['package.json','LICENSE','NOTICE','APACHE-2.0.txt']);
function run(exe,args){
  const r=spawnSync(exe,args,{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
  assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;
}
function inventory(root,prefix=''){
  return fs.readdirSync(path.join(root,prefix)).sort().flatMap(name=>{
    const relative=prefix?prefix+'/'+name:name,file=path.join(root,relative),s=fs.lstatSync(file);
    assert.ok(!s.isSymbolicLink());if(s.isDirectory())return inventory(root,relative);
    assert.ok(s.isFile());const b=fs.readFileSync(file);
    return [{path:relative,bytes:b.length,sha256:hash(b)}];
  });
}
function retain(before,after,permitted){
  for(const row of before)if(!permitted.has(row.path))
    assert.deepEqual(after.find(p=>p.path===row.path),row,'licensing changed retained code/data: '+row.path);
  for(const row of after)if(!before.some(p=>p.path===row.path))
    assert.ok(permitted.has(row.path),'unexpected added artifact: '+row.path);
}
export function finalizeProjectLicenses(output){
  const tarballs=path.join(output,'tarballs'),receiptFile=path.join(output,'package-receipt.json');
  const receipt=JSON.parse(fs.readFileSync(receiptFile)),work=path.join(output,'license-overlay');
  assert.equal(fs.existsSync(work),false,'fresh license staging required');fs.mkdirSync(work);
  const packages=new Map(),retainedThirdParty=[];
  for(const filename of fs.readdirSync(tarballs).filter(n=>n.endsWith('.tgz')).sort()){
    const file=path.join(tarballs,filename),bytes=fs.readFileSync(file);
    const names=run('tar',['tzf',file]).split('\n').filter(Boolean);
    assert.ok(names.every(n=>n.startsWith('package/')&&!n.includes('\\')&&!n.split('/').includes('..')));
    const meta=JSON.parse(run('tar',['xOf',file,'package/package.json']));
    if(!projectOwnedName(meta.name)){retainedThirdParty.push({package:meta.name,tarball:filename,sha256:hash(bytes)});continue;}
    assert.equal(packages.has(meta.name),false,'duplicate owned package tarball');
    const directory=path.join(work,String(packages.size));fs.mkdirSync(directory);
    run('tar',['xzf',file,'-C',directory]);const root=path.join(directory,'package');
    const before=inventory(root),delta=applyProjectLicense(root),after=inventory(root);
    retain(before,after,legal);
    packages.set(meta.name,{root,before,delta,oldTarball:filename,oldSha256:hash(bytes),name:meta.name});
  }
  const root=packages.get('proofscript');assert.ok(root,'one installed universal root required');
  function pack(item){
    const packed=JSON.parse(run('npm',['pack',item.root,'--ignore-scripts','--json','--pack-destination',tarballs]));
    assert.equal(packed.length,1);
    const filename=packed[0].filename,bytes=fs.readFileSync(path.join(tarballs,filename));
    if(filename!==item.oldTarball)fs.unlinkSync(path.join(tarballs,item.oldTarball));
    Object.assign(item,{tarball:filename,sha256:hash(bytes),bytes:bytes.length,files:inventory(item.root),
      version:JSON.parse(fs.readFileSync(path.join(item.root,'package.json'))).version});
  }
  for(const item of packages.values())if(item!==root)pack(item);
  const manifestFile=path.join(root.root,'UNIVERSAL_DISTRIBUTION.json');
  const d=JSON.parse(fs.readFileSync(manifestFile));assert.equal(d.schema,'psc1-universal-npm-distribution/1');
  function descriptor(row){
    const item=packages.get(row?.package);if(!item||item===root)return;
    assert.equal(row.version,item.version);row.files=item.files;row.tarballSha256=item.sha256;
    if(row.tarball!==undefined)row.tarball=item.tarball;
  }
  for(const row of Object.values(d.engines))if(row.kind==='optional-package')descriptor(row);
  for(const row of Object.values(d.kernels))descriptor(row);
  for(const row of Object.values(d.targetConsumers))descriptor(row);
  for(const row of Object.values(d.dispatchPackages))descriptor(row);
  // The bundled mandatory kernel must match its separately installable tarball.
  const bundled=d.kernels.wasm,embedded=path.join(root.root,'node_modules',bundled.package);
  const embeddedBefore=inventory(embedded),embeddedDelta=applyProjectLicense(embedded);
  retain(embeddedBefore,inventory(embedded),legal);
  assert.deepEqual(inventory(embedded),bundled.files,'bundled and standalone kernel metadata/notices must agree');
  for(const filename of ['DEPENDENCY_LOCK.json','npm-shrinkwrap.json']){
    const file=path.join(root.root,filename);if(!fs.existsSync(file))continue;
    const lock=JSON.parse(fs.readFileSync(file));if(lock.packages?.[''])lock.packages[''].license='Apache-2.0';
    for(const [name,item]of packages)if(lock.packages?.['node_modules/'+name])
      lock.packages['node_modules/'+name].license='Apache-2.0';
    fs.writeFileSync(file,JSON.stringify(lock,null,2)+'\n');
  }
  const pin=file=>{const b=fs.readFileSync(path.join(root.root,file));return{path:file,bytes:b.length,sha256:hash(b)};};
  const newLegal=root.delta.changedFiles.filter(p=>p!=='package.json');
  d.hostFiles=[...new Map([...d.hostFiles.map(p=>pin(p.path)),...newLegal.map(pin)].map(p=>[p.path,p])).values()];
  d.projectLicense='Apache-2.0';d.thirdPartyNotices='retained component licenses; no third-party relicensing';
  const text=JSON.stringify(d,null,2)+'\n';fs.writeFileSync(manifestFile,text);
  fs.writeFileSync(path.join(root.root,'DISTRIBUTION_PIN.mjs'),
    "export const expectedDistributionSha256='"+hash(text)+"';\n"+
    "export const expectedCompilerSourceClosureDigest='"+d.compilerSourceClosureDigest+"';\n");
  const allowed=new Set([...legal,'DEPENDENCY_LOCK.json','npm-shrinkwrap.json','UNIVERSAL_DISTRIBUTION.json','DISTRIBUTION_PIN.mjs',
    ...embeddedDelta.changedFiles.map(p=>'node_modules/'+bundled.package+'/'+p)]);
  retain(root.before,inventory(root.root),allowed);pack(root);
  receipt.preLicenseRootSha256=receipt.sha256;receipt.tarball=root.tarball;
  receipt.sha256=root.sha256;receipt.bytes=root.bytes;receipt.projectLicense='Apache-2.0';
  receipt.dispatchPackages=d.dispatchPackages;receipt.targetConsumers=d.targetConsumers;
  for(const row of Object.values(receipt.input.packages)){
    const item=packages.get(row.package);if(item)Object.assign(row,{version:item.version,tarball:item.tarball,sha256:item.sha256,bytes:item.bytes});
  }
  receipt.optionalExecutionPackages=['rust','wasm-core'].map(k=>receipt.input.packages[k]);
  for(const key of ['repackagedTools','repackagedExecutionPackages'])for(const row of receipt[key]||[]){
    const item=packages.get(row.package);if(item)Object.assign(row,{sha256:item.sha256,tarball:item.tarball,license:'Apache-2.0',...(row.files?{files:item.files}:{})});
  }
  receipt.licensing={status:'assembled-pending-installed-gate',sourceCommit:process.env.GITHUB_SHA,
    owned:[...packages.values()].map(p=>({package:p.name,version:p.version,tarball:p.tarball,sha256:p.sha256,
      previousSha256:p.oldSha256,license:'Apache-2.0',delta:p.delta})),retainedThirdParty,
    executablePolicy:'all non-license bytes retained; root integrity manifests/locks refreshed'};
  receipt.sizeRatio=root.bytes/receipt.previousRootBytes;receipt.removedBytes=receipt.previousRootBytes-root.bytes;
  fs.writeFileSync(receiptFile,JSON.stringify(receipt,null,2)+'\n');
  fs.cpSync(root.root,path.join(output,'package'),{recursive:true});
  console.log('PSC1_LICENSE_OVERLAY '+JSON.stringify({root:receipt.sha256,bytes:receipt.bytes,owned:packages.size,retainedThirdParty}));
}
