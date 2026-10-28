// Negative resource/metadata classes for the installed profile, before graph import.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {fixture} from './psc1-modular-fixture.mjs';
import {sha256} from '../../psc1/scripts/kernel435-qualified-artifact.mjs';
const f=fixture(),cases=[];
const root=path.join(f.root,'node_modules'),manifestFile=path.join(f.root,'dist/COMPILER_GRAPH.json');
const original=fs.readFileSync(manifestFile),manifest=JSON.parse(original);
const {verify}=await import(pathToFileURL(path.join(root,'@proofscript/compiler/dist/host/host-tools/executable/verify.mjs')).href);
const json=m=>Buffer.from(JSON.stringify(m,null,2)+'\n');
const check=()=>verify(root,original,sha256(original));
function rejected(name,action){assert.throws(action);cases.push(name);}
function changed(name,change){const m=JSON.parse(original);change(m);const b=json(m);rejected(name,()=>verify(root,b,sha256(b)));}
const sample=manifest.files.find(row=>row.path.includes('/dist/js/generated/')&&row.path.endsWith('.mjs'));
const file=path.join(root,sample.path),before=fs.readFileSync(file);
try {
 check();rejected('wrong-manifest-cohort',()=>verify(root,original,'0'.repeat(64)));
 try{
  fs.appendFileSync(file,'\nthrow Error("unverified execution");');
  rejected('altered-module',check);
  fs.writeFileSync(file,before);fs.renameSync(file,file+'.missing');
  rejected('missing-module',check);
  fs.renameSync(file+'.missing',file);fs.truncateSync(file,33554433);
  assert.throws(check,/PSC1_EXECUTABLE_FILE_SIZE/);cases.push('oversized-file-before-read');
 }finally{if(fs.existsSync(file+'.missing'))fs.renameSync(file+'.missing',file);fs.writeFileSync(file,before);}
 const extra=path.join(root,'unexpected.mjs');
 try{fs.writeFileSync(extra,'export {};');rejected('extra-file',check);}finally{fs.rmSync(extra,{force:true});}
 const dir=path.join(root,'unexpected-empty-directory');
 try{fs.mkdirSync(dir);rejected('extra-empty-directory',check);}finally{fs.rmSync(dir,{recursive:true,force:true});}
 const linked=path.join(root,'linked.mjs');
 try{fs.symlinkSync(file,linked);rejected('symlink-file',check);}finally{fs.rmSync(linked,{force:true});}
 const pin=path.join(root,manifest.bootstrapPin),pinBytes=fs.readFileSync(pin);
 try{fs.writeFileSync(pin,Buffer.alloc(4097,32));rejected('bounded-bootstrap-seal',check);}
 finally{fs.writeFileSync(pin,pinBytes);}
 changed('wrong-source-graph-cohort',m=>m.sourceGraph.manifestSha256='0'.repeat(64));
 changed('changed-owner-inventory',m=>m.owners.push(m.owners[0]));
 changed('changed-original-source-binding',m=>m.sourceClosureDigest='0'.repeat(64));
 changed('changed-original-module-pin',m=>m.files.find(r=>r.path===sample.path).sha256='0'.repeat(64));
 changed('unsafe-host-path',m=>m.files.find(r=>r.path.includes('/dist/host/')&&!r.path.endsWith('/package.json')).path='../escape');
 changed('undeclared-package-edge',m=>m.packages[0].dependencies['@proofscript/not-in-cohort']=m.version);
 // Kernel is an independent package with a distinct semver and no original unit
 // ownership. Exercise actual metadata runtime/peer cycles under a resealed test manifest.
 const kernel=manifest.packages.find(p=>p.name==='@proofscript/pskernel-lean-wasm');
 const metadata=path.join(root,kernel.name,'package.json'),metadataBytes=fs.readFileSync(metadata);
 for(const peer of [false,true]){
  try{
   const m=JSON.parse(original),p=m.packages.find(p=>p.name===kernel.name),meta=JSON.parse(metadataBytes);
   if(peer){p.peerDependencies={'@proofscript/compiler':m.version};meta.peerDependencies=p.peerDependencies;}
   else{p.dependencies={[p.name]:p.version};meta.dependencies=p.dependencies;}
   const b=json(meta);fs.writeFileSync(metadata,b);
   Object.assign(m.files.find(r=>r.path===kernel.name+'/package.json'),{bytes:b.length,sha256:sha256(b)});
   const bytes=json(m);rejected(peer?'peer-dependency-cycle':'runtime-dependency-cycle',()=>verify(root,bytes,sha256(bytes)));
  }finally{fs.writeFileSync(metadata,metadataBytes);}
 }
 check();assert.equal(cases.length,16);
 const source=path.join(f.directory,'Main.ps'),store=path.join(f.directory,'store');
 fs.writeFileSync(source,'def answer : Nat := 42\n');
 const first=JSON.parse(f.invoke(['build',source,'--out',store,'--publication-protocol','portable-file']));
 assert.equal(f.observe(first),'42');
 const pointer=fs.readFileSync(path.join(store,'current.json'));
 for(const target of ['ts','rust','wasm-component','python','php']){
  const r=f.call(['build',source,'--target',target,'--out',store,'--publication-protocol','portable-file']);
  assert.notEqual(r.status,0);assert.match(r.stderr,/OPTIONAL_PACKAGE_MISSING/);
  assert.deepEqual(fs.readFileSync(path.join(store,'current.json')),pointer);
  cases.push('missing-installed-consumer-'+target);
 }
 for(const engine of ['rust','wasm-core']){
  const r=f.call(['build',source,'--engine',engine,'--out',store,'--publication-protocol','portable-file']);
  assert.notEqual(r.status,0);assert.match(r.stderr,/ENGINE_NOT_QUALIFIED_FOR_COHORT/);
  assert.deepEqual(fs.readFileSync(path.join(store,'current.json')),pointer);
  cases.push('older-engine-cohort-refused-'+engine);
 }
 assert.equal(cases.length,23);
 const name=path.basename(f.runtime).startsWith('bun')?'bun':'node';
 const report={schema:'psc1-modular-installed-boundaries/1',testedCommit:process.env.GITHUB_SHA,status:'passed',runtime:f.runtime,inputCommit:process.env.PSC1_MODULAR_INPUT_COMMIT,cases};
 fs.writeFileSync('dist/modular-toolchain/boundaries-'+name+'.json',JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_MODULAR_INSTALLED_BOUNDARIES '+JSON.stringify(report));
}finally{fs.rmSync(f.directory,{recursive:true,force:true});}
