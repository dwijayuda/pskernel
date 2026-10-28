// Exact source ownership/body checks; not a parser, emitter or proof authority.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
const contract=JSON.parse(fs.readFileSync('EXECUTABLE_PACKAGE_CONTRACT.json'));
const baseline=fs.realpathSync(process.env.PSC1_EXECUTABLE_BASELINE),cases=[];
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const read=(root,file)=>fs.readFileSync(path.join(root,file),'utf8');
const record=name=>{cases.push(name);console.log('PSC1_EXECUTABLE_OWNERSHIP_CASE '+name);};
const git=spawnSync('git',['rev-parse','HEAD'],{cwd:baseline,encoding:'utf8'});
assert.equal(git.status,0);assert.equal(git.stdout.trim(),contract.baselineCommit);
const clean=()=>{const r=spawnSync('git',['status','--porcelain','--untracked-files=no'],{cwd:baseline,encoding:'utf8'});assert.equal(r.status,0);assert.equal(r.stdout.trim(),'');};
clean();record('baseline-is-exact-and-read-only');
const service='packages/compiler/src/Ps/Compiler/Service.lean';
const before=read(baseline,service),after=read('.',service),start=before.indexOf('structure Error where'),end=before.indexOf('structure Source where');
const errorBlock=before.slice(start,end),shared=read('.','packages/backend-common/src/Ps/BackendCommon/ServiceError.lean');
assert.ok(shared.includes(errorBlock));assert.ok(!after.includes('structure Error where'));
assert.equal(after.replace('import Ps.BackendCommon.ServiceError\n',''),before.slice(0,start)+before.slice(end));
record('error-contract-body-preserved');
const bodies=[];
for(const [dir,ns]of [['js','Js'],['ts','Ts'],['rust','Rust'],['wasm','Wasm']]){
 const file='packages/backend-'+dir+'/src/Ps/Backend'+ns+'/CompilerService.lean';
 const source=read(baseline,file),marker='namespace Ps.Internal.'+ns+'CompilerService',last='end Ps.Internal.'+ns+'CompilerService';
 const first=source.indexOf(marker),finish=source.indexOf(last)+last.length,body=source.slice(first,finish);
 const emitted=read('.','packages/backend-'+dir+'/src/Ps/Backend'+ns+'/Emit.lean');
 assert.ok(emitted.includes(body),'exact '+ns+' emitter body');
 for(const line of source.split('\n').filter(line=>line.startsWith('import ')&&line!=='import Ps.Compiler.Service'))
  assert.ok(emitted.split('\n').includes(line),'preserved backend import:'+line);
 assert.equal(read('.',file),'import Ps.Compiler.Service\nimport Ps.Backend'+ns+'.Emit\n'+source.slice(finish));
 bodies.push({backend:dir,sha256:hash(body),bytes:Buffer.byteLength(body)});
}
record('all-four-emitter-bodies-preserved');record('legacy-service-entry-points-preserved');
const owner=row=>{const m=row.path.replaceAll(path.sep,'/').match(/^packages\/([^/]+)\/src\//);assert.ok(m,row.path);return m[1];};
for(const entry of contract.sourceEntries.pureEmitters){
 const rows=readOwnedCompilerSources(entry);
 assert.ok(rows.some(row=>row.module===contract.sourceEntries.sharedError));
 for(const row of rows)assert.ok(!contract.boundaries.pureEmitterForbiddenOwners.includes(owner(row)),entry+' imports forbidden '+row.module);
}
record('pure-emitter-closures-have-no-frontend-driver');
const rows=readOwnedCompilerSources(contract.sourceEntries.unified),names=new Map(),edges=new Map();
for(const row of rows){
 const physical=owner(row),name=contract.sourceEntries.logicalOwnerOverrides[physical]??JSON.parse(read('.','packages/'+physical+'/package.json')).name;
 names.set(row.module,name);if(!edges.has(name))edges.set(name,new Set());
}
for(const row of rows)for(const match of row.text.matchAll(/^import\s+(.+)$/gm))for(const imported of match[1].trim().split(/\s+/)){
 assert.ok(names.has(imported),'registered closure import '+imported);
 if(names.get(row.module)!==names.get(imported))edges.get(names.get(row.module)).add(names.get(imported));
}
const done=new Set(),active=new Set(),order=[];
function visit(name){assert.ok(!active.has(name),'package source cycle:'+name);if(done.has(name))return;active.add(name);for(const dep of edges.get(name))visit(dep);active.delete(name);done.add(name);order.push(name);}
for(const name of edges.keys())visit(name);record('complete-source-package-graph-acyclic');
const entry=rows.at(-1).text;
for(const name of contract.sourceEntries.pureEmitters)assert.ok(entry.includes('import '+name+'\n'));
assert.ok(!/^import Ps[.]Backend\w+[.]CompilerService$/m.test(entry));
record('unified-entry-uses-pure-emitters');
// Historical M1/M2 extraction bodies remain checked at the immutable M4 epoch.
// M5 changes portable spelling deliberately; its exact source baseline and
// actual whole-compiler renderer-byte oracle are checked separately below.
const historical=file=>{
 const result=spawnSync('git',['show',contract.portableNormalization.historicalBodyCommit+':psc1/'+file],
  {encoding:'utf8',maxBuffer:33554432});
 assert.equal(result.status,0,result.stderr);return result.stdout;
};
for(const file of contract.portableNormalization.files){
 const result=spawnSync('git',['show',contract.portableNormalization.implementationBaselineCommit+':psc1/'+file],
  {encoding:'utf8',maxBuffer:33554432});
 assert.equal(result.status,0,result.stderr);
 assert.equal(read('.',file),result.stdout,'PSC1_PORTABLE_NORMALIZATION_SOURCE_BASELINE:'+file);
}
const rendererAudit=spawnSync(process.execPath,['scripts/check-portable-renderer-reference.mjs'],{encoding:'utf8'});
assert.equal(rendererAudit.status,0,rendererAudit.stdout+rendererAudit.stderr);
record('portable-normalization-source-baseline-and-immutable-renderers');
const commonPath='packages/backend-common/src/Ps/BackendCommon/Modules.lean';
const oldCommon=read(baseline,commonPath),model=historical('packages/backend-common/src/Ps/BackendCommon/ModuleModel.lean');
const markers=['structure PsModuleOwner','def psModulePackageSafe','structure PsModuleImport','def psModulePackage (',
 'def psModuleTypeNames','def psModuleCohort (','/-! Carry value'];
const positions=markers.map(marker=>{const i=oldCommon.indexOf(marker);assert.ok(i>=0);return i;});
for(const [start,end]of [[0,1],[2,3],[4,5],[6,null]])
 assert.ok(model.includes(oldCommon.slice(positions[start],end===null?undefined:positions[end])),'shared model exact body');
const retained=read('.',commonPath);
for(const [start,end]of [[1,2],[3,4],[5,6]])
 assert.ok(retained.includes(oldCommon.slice(positions[start],positions[end])),'retained pilot policy unchanged');
for(const [dir,ns]of [['js','Js'],['ts','Ts']]){
 const modulePath='packages/backend-'+dir+'/src/Ps/Backend'+ns+'/Modules.lean';
 const old=read(baseline,modulePath),cut=old.indexOf('def psEmit'+ns+'Modules');
 assert.ok(cut>0);
 const common=historical(modulePath.replace('Modules.lean','ModuleFiles.lean'));
 assert.equal(common.replace('import Ps.BackendCommon.ModuleModel','import Ps.BackendCommon.Modules'),old.slice(0,cut));
 assert.ok(read('.',modulePath).endsWith(old.slice(cut)),'retained module API exact body');
}
const oldPilot=read(baseline,'host/src/Ps/Host/ModularPilot.lean');
const sourceOwnership=oldPilot.slice(oldPilot.indexOf('def sourceOwners'),oldPilot.indexOf('def ownerJson'));
assert.ok(read('.','host/src/Ps/Host/SourceModules.lean').includes(sourceOwnership),'source ownership body preserved');
record('shared-module-renderer-bodies-preserved');
record('retained-pilot-profiles-unchanged');

const sources=rows.map(row=>({module:row.module,kind:'lean',text:row.text})),digest=compilerSourceClosureDigest(sources);
assert.notEqual(digest,'073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9');
record('new-source-identity-distinct-from-frozen-g3');clean();
assert.deepEqual(cases.slice().sort(),contract.requiredOwnershipCases.slice().sort());
const report={schema:'psc1-executable-source-ownership/1',testedCommit:process.env.GITHUB_SHA,status:'passed',cases,
 baselineCommit:contract.baselineCommit,sourceClosureDigest:digest,sourceModules:rows.length,
 sources:rows.map(row=>({module:row.module,path:row.path,bytes:Buffer.byteLength(row.text),sha256:hash(row.text)})),
 packageDependencies:Object.fromEntries([...edges].map(([name,deps])=>[name,[...deps].sort()])),order,bodies,
 errorContract:{sha256:hash(errorBlock),bytes:Buffer.byteLength(errorBlock)},
 portableNormalization:contract.portableNormalization,scope:'registered graph and historical M1/M2 bodies; current M5 normalized source baseline plus immutable reference audit; actual renderer-byte equivalence requires the separate full native build; not full modular self-host qualification'};
fs.mkdirSync('dist/executable-packages',{recursive:true});
fs.writeFileSync('dist/executable-packages/ownership.json',JSON.stringify(report,null,2)+'\n');
console.log('PSC1_EXECUTABLE_SOURCE_OWNERSHIP '+JSON.stringify(report));
