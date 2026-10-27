// Workspace/package metadata validation. No compiler soundness claim.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const contract=JSON.parse(fs.readFileSync(path.join(root,'NPM_PACKAGE_CONTRACT.json')));
const built=process.argv.includes('--built'),names=new Map();
for(const p of contract.packages){
 const directory=path.join(root,'packages',p.directory),meta=JSON.parse(fs.readFileSync(path.join(directory,'package.json')));
 assert.equal(meta.name,p.name,'existing package name');assert.equal(meta.license,'Apache-2.0');
 assert.equal(meta.type,'module');assert.ok(meta.scripts.build&&meta.scripts.clean);
 assert.equal(meta.repository.directory,'psc1/packages/'+p.directory);
 for(const forbidden of ['preinstall','install','postinstall','prepare'])assert.ok(!meta.scripts[forbidden]);
 assert.equal(meta.version,p.kind==='independent-kernel'?contract.kernelPackageVersion:contract.version);
 names.set(meta.name,meta);
 const targets=value=>typeof value==='string'?[value]:Object.values(value).flatMap(targets);
 for(const file of targets(meta.exports)){
  assert.ok(file.startsWith('./')&&!file.includes('..'),'local package export');
  if(built)assert.ok(fs.statSync(path.join(directory,file)).isFile(),p.name+':'+file);
 }
 if(built)assert.ok(fs.statSync(path.join(directory,'dist/index.js')).isFile());
}
for(const meta of names.values())for(const [dep,version]of Object.entries(meta.dependencies??{})){
 assert.ok(names.has(dep),'declared existing workspace dependency:'+dep);
 assert.equal(names.get(dep).version,version,'exact compatible version');
}
// Check declared runtime/peer edges, including the optional providers, for cycles.
const visited=new Set(),active=new Set();
function visit(name){
 assert.ok(!active.has(name),'workspace dependency cycle:'+name);if(visited.has(name))return;
 active.add(name);const meta=names.get(name);
 for(const dep of new Set([...Object.keys(meta.dependencies??{}),...Object.keys(meta.peerDependencies??{})]))
  if(names.has(dep))visit(dep);
 active.delete(name);visited.add(name);
}
for(const name of names.keys())visit(name);
const umbrella=names.get('proofscript'),owner=names.get(contract.implementationOwner);
assert.ok(owner&&!owner.dependencies.proofscript);
assert.deepEqual(Object.keys(umbrella.dependencies).sort(),contract.corePackages.slice().sort());
assert.deepEqual(umbrella.bundledDependencies.slice().sort(),contract.corePackages.slice().sort());
for(const name of names.keys())if(name!=='proofscript')
 assert.ok(!Object.hasOwn(names.get(name).dependencies??{},'proofscript'),'no dependency back to umbrella');
for(const name of contract.optionalPackages)assert.ok(!Object.hasOwn(umbrella.dependencies,name));
for(const dir of contract.sourceOnlyWithoutNpmName){
 assert.ok(fs.statSync(path.join(root,'packages',dir,'src')).isDirectory());
 assert.equal(fs.existsSync(path.join(root,'packages',dir,'package.json')),false,'do not invent npm name');
}
const workspace=JSON.parse(fs.readFileSync(path.join(root,'package.json')));
assert.ok(workspace.workspaces.includes('packages/*'));
assert.ok(workspace.scripts['build:packages']);assert.ok(workspace.scripts['check:workspace']);
console.log('PSC1_WORKSPACE_PACKAGES '+JSON.stringify({status:'passed',namedPackages:names.size,
 sourceOnlyUnnamed:contract.sourceOnlyWithoutNpmName,compilerModularity:'deferred',built}));
