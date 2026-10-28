// Assemble the installable preview from qualified graph/kernel resources only.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readQualifiedArtifact,sha256} from './kernel435-qualified-artifact.mjs';
import {verify,readManifestBytes} from '../host-tools/executable/verify.mjs';
const input=JSON.parse(fs.readFileSync('scripts/modular-toolchain-input.json'));
const out=path.resolve('dist/modular-toolchain');
assert.equal(out,path.join(process.cwd(),'dist/modular-toolchain'));
fs.mkdirSync(out,{recursive:true});
const json=x=>JSON.stringify(x,null,2)+'\n';
const write=(file,data)=>{fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,data);};
function files(root,prefix=''){
 return fs.readdirSync(path.join(root,prefix)).sort().flatMap(name=>{
  const rel=prefix?prefix+'/'+name:name,file=path.join(root,rel),s=fs.lstatSync(file);
  assert.ok(!s.isSymbolicLink(),'package symlink:'+rel);
  if(s.isDirectory())return files(root,rel);
  assert.ok(s.isFile());const bytes=fs.readFileSync(file);
  return [{path:rel,bytes:bytes.length,sha256:sha256(bytes)}];
 });
}
function run(exe,args,cwd=process.cwd()){
 const r=spawnSync(exe,args,{cwd,encoding:'utf8',timeout:240000,maxBuffer:33554432});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;
}
const graphArchive=await readQualifiedArtifact(input.graph.artifact,path.join(out,'graph-input'));
const graphRoot=path.join(graphArchive,'compiler/candidate');
const originalGraph=verify(graphRoot,readManifestBytes(path.join(graphArchive,'compiler/manifest.json')),input.graph.manifestSha256);
assert.equal(originalGraph.sourceClosureDigest,input.graph.compilerSourceClosureDigest);
const rootArchive=await readQualifiedArtifact(input.root,path.join(out,'root-input'));
const rootTars=files(rootArchive).filter(r=>path.basename(r.path)===input.root.tarball);
assert.equal(rootTars.length,1);
const tar=path.join(rootArchive,rootTars[0].path);
assert.ok(run('tar',['tzf',tar]).split('\n').filter(Boolean).every(p=>p.startsWith('package/')&&!p.includes('\\')&&!p.split('/').includes('..')));
const extracted=path.join(out,'reference');fs.mkdirSync(extracted);run('tar',['xzf',tar,'-C',extracted]);
const reference=path.join(extracted,'package'),referenceMeta=JSON.parse(fs.readFileSync(path.join(reference,'package.json')));
assert.equal(referenceMeta.name,'proofscript');assert.equal(referenceMeta.version,'0.1.0-psc1.13');
assert.equal(referenceMeta.bundledDependencies.length,20);
const graphNames=new Set(originalGraph.packages.map(p=>p.name));
const graphBytes=originalGraph.files.reduce((n,r)=>n+r.bytes,0);
const extraPackages=referenceMeta.bundledDependencies.filter(name=>!graphNames.has(name)).map(name=>{
 const inventory=files(path.join(reference,'node_modules',name));
 return {name,bytes:inventory.reduce((n,r)=>n+r.bytes,0),files:inventory.length};
});
const inspection={schema:'psc1-modular-toolchain-inspection/1',testedCommit:process.env.GITHUB_SHA,
 graphBytes,graphFiles:originalGraph.files.length,graphPackages:graphNames.size,extraPackages,
 projectedGraphBytes:graphBytes+extraPackages.reduce((n,r)=>n+r.bytes,0),
 exactGraphBound:134217728,oldCompilerExecuted:false};
write(path.join(out,'inspection.json'),json(inspection));
console.log('PSC1_MODULAR_TOOLCHAIN_INSPECTION '+JSON.stringify(inspection));
assert.equal(process.argv[2],'inspect');
