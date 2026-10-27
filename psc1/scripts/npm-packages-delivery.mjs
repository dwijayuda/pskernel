// Deliver the exact qualified tarballs; no registry publication or extra compiler build.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {sha256} from './kernel435-qualified-artifact.mjs';
const root=path.resolve('dist/npm-packages'),q=JSON.parse(fs.readFileSync(path.join(root,'qualification.json')));
assert.equal(q.status,'passed');
const defaults=path.join(root,'installable'),optional=path.join(root,'optional');
for(const dir of [defaults,optional])fs.mkdirSync(dir,{recursive:true});
const optionalNames=new Set(['@proofscript/backend-python','@proofscript/backend-php','@proofscript/pskernel-lean']);
const records=[];
for(const r of q.packages){
 const source=path.join(root,'tarballs',r.tarball),bytes=fs.readFileSync(source);
 assert.equal(sha256(bytes),r.sha256);const directory=optionalNames.has(r.name)?optional:defaults;
 fs.copyFileSync(source,path.join(directory,r.tarball));records.push({...r,directory:directory===defaults?'installable':'optional'});
}
const extraRecords=JSON.parse(fs.readFileSync(path.join(root,'qualified-bundles.json'))),extraPaths=new Map();
function collect(dir){for(const n of fs.readdirSync(dir)){const p=path.join(dir,n);if(fs.statSync(p).isDirectory())collect(p);else if(n.endsWith('.tgz'))extraPaths.set(n,p);}}
collect(path.join(root,'qualified-bundles'));
for(const e of extraRecords.filter(e=>!q.packages.some(p=>p.name===e.meta.name))){
 const source=extraPaths.get(e.tarball);assert.equal(sha256(fs.readFileSync(source)),e.sha256);
 fs.copyFileSync(source,path.join(optional,e.tarball));records.push({name:e.meta.name,version:e.meta.version,
  tarball:e.tarball,bytes:e.bytes,sha256:e.sha256,directory:'optional',unchangedQualifiedArchive:true});
}
for(const [directory,label]of [[defaults,'installable'],[optional,'optional']]){
 const entries=records.filter(r=>r.directory===label);
 fs.writeFileSync(path.join(directory,'SHA256SUMS'),entries.map(r=>r.sha256+'  '+r.tarball).join('\n')+'\n');
 fs.writeFileSync(path.join(directory,'PACKAGES.json'),JSON.stringify(entries,null,2)+'\n');
 fs.copyFileSync('LICENSE',path.join(directory,'LICENSE'));fs.copyFileSync('NOTICE',path.join(directory,'NOTICE'));
}
fs.writeFileSync(path.join(defaults,'INSTALL.txt'),[
 'Unpublished ProofScript PSC1 .13 package cohort. Verify SHA256SUMS.',
 'Default CLI only: npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.13.tgz',
 'Core packages are already installed by the root tarball. Do not install every standalone tarball unless you need direct bare-name imports.',
 'Then: npx --no-install psc --help',
 'The default root automatically includes all20 core packages, the shared compiler and the genuine Lean4.35.0 linear-memory Wasm kernel.',
 'Optional native/Python/PHP/SDK/engine artifacts are separate. Install exact matching files explicitly.',
 'Use import from proofscript/foundation, proofscript/compiler or proofscript/backend-js without relying on npm hoisting. Source-only interfaces do not fabricate private compiler APIs.',
 'No installation hook, package registry publication or new modular G2/G3 claim.',
 'Release qualification currently covers Linux x64. Other platforms retain separate qualification boundaries.'
].join('\n')+'\n');
fs.writeFileSync(path.join(optional,'INSTALL.txt'),'Optional qualified payloads and SDKs. Install selected exact tarballs into the same project as the .13 root. Python/PHP/native/SDK consumers retain Linux/platform limits; do not mix incompatible cohort versions. Vendor SDKs retain upstream licenses.\n');
const manifest={schema:'psc1-simple-npm-delivery/1',status:'qualified-linux',testedCommit:process.env.GITHUB_SHA,
 modularNpmDistribution:'completed-in-documented-scope',independentCompilerInternalModularity:'deferred',
 packages:records,qualification:q};
fs.writeFileSync(path.join(root,'delivery.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('PSC1_NPM_DELIVERY '+JSON.stringify({defaults:records.filter(r=>r.directory==='installable').length,
 optional:records.filter(r=>r.directory==='optional').length,defaultBytes:records.filter(r=>r.directory==='installable').reduce((n,r)=>n+r.bytes,0),
 optionalBytes:records.filter(r=>r.directory==='optional').reduce((n,r)=>n+r.bytes,0)}));
