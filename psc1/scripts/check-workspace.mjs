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
 assert.equal(meta.version,p.kind==='independent-kernel'?'4.35.0':contract.version);
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
for(const dir of contract.sourceOnlyWithoutNpmName){
 assert.ok(fs.statSync(path.join(root,'packages',dir,'src')).isDirectory());
 assert.equal(fs.existsSync(path.join(root,'packages',dir,'package.json')),false,'do not invent npm name');
}
const workspace=JSON.parse(fs.readFileSync(path.join(root,'package.json')));
assert.ok(workspace.workspaces.includes('packages/*'));
assert.ok(workspace.scripts['build:packages']);assert.ok(workspace.scripts['check:workspace']);
console.log('PSC1_WORKSPACE_PACKAGES '+JSON.stringify({status:'passed',namedPackages:names.size,
 sourceOnlyUnnamed:contract.sourceOnlyWithoutNpmName,compilerModularity:'deferred',built}));
