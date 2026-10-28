// Assemble candidate files under the existing package owners. This does not
// change .13, publish a registry package, or supply the M4 umbrella/checked API.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {inspectModule} from '../module-graph-inspection.mjs';
import {put,files,inventory,sha256,json,run,bounded,output} from './tools.mjs';
const version='0.1.0-psc1-modular.0';
const nodeFlags=['--max-old-space-size=4096','--stack-size=8192'];
export function packageGraph(emission,sourceRows,receipt){
 const root=path.join(output,'candidate'),packageRows=new Map(),sources=new Map();
 const directory=specifier=>path.join(root,'node_modules',...specifier.split('/').slice(0,2));
 const names=emission.packages.map(s=>s.split('/').slice(0,2).join('/'));
 for(const name of new Set(names)){
  packageRows.set(name,{name,dependencies:{},units:[]});
  sources.set(name,[]);
 }
 const addDependency=(owner,dependency)=>{
  if(owner!==dependency)packageRows.get(owner).dependencies[dependency]=version;
 };
 for(const [unit,specifier]of emission.packages.entries()){
  const name=names[unit],module=specifier.split('/')[3],pkg=directory(specifier);
  assert.match(module,/^[A-Za-z][A-Za-z0-9._-]*$/);
  packageRows.get(name).units.push(unit);
  const js=fs.readFileSync(path.join(output,emission.js[unit].file),'utf8');
  const ts=fs.readFileSync(path.join(output,emission.ts[unit].file),'utf8');
  const declarations=fs.readFileSync(path.join(output,'js','unit-'+unit+'.d.mts'),'utf8');
  put(path.join(pkg,'dist/js/generated',module+'.mjs'),js);
  put(path.join(pkg,'dist/js/generated',module+'.d.mts'),declarations);
  put(path.join(pkg,'src/ts/generated',module+'.mts'),ts);
  sources.get(name).push(path.join(pkg,'src/ts/generated',module+'.mts'));
  for(const variant of ['js','ts'])for(const imported of emission[variant][unit].imports){
   const dependency=imported.source.split('/').slice(0,2).join('/');
   assert.ok(packageRows.has(dependency),'PSC1_EXECUTABLE_UNDECLARED_IMPORT');
   addDependency(name,dependency);
  }
 }
 const ordered=[],done=new Set(),active=new Set();
 function visit(name){
  assert.ok(!active.has(name),'PSC1_EXECUTABLE_PACKAGE_CYCLE:'+name);
  if(done.has(name))return;active.add(name);
  for(const dep of Object.keys(packageRows.get(name).dependencies))visit(dep);
  active.delete(name);done.add(name);ordered.push(name);
 }
 for(const name of packageRows.keys())visit(name);
 const tsc=path.resolve('../node_modules/typescript/bin/tsc');
 assert.match(run(process.execPath,[tsc,'--version']),/Version 7[.]0[.]2/);
 const sdk=['typescript','@typescript/typescript-linux-x64'].flatMap(name=>{
  const dir=path.resolve('../node_modules',name);
  return files(dir).map(row=>({...row,file:path.join(dir,row.path)}));
 });
 const verifySdk=()=>{for(const row of sdk)assert.equal(sha256(fs.readFileSync(row.file)),row.sha256);};
 const compile=(label,config)=>{
  const file=path.join(output,label+'.json');put(file,json(config));verifySdk();
  bounded(label,[process.execPath,...nodeFlags,tsc,'--project',file],{addressSpace:false});verifySdk();
 };
 // Infer only the common JS helper declarations. IR-owned declarations come
 // from the same checked IR and must not be duplicated by JS inference.
 const helper=path.join(output,'js-runtime.mjs'),inferred=path.join(output,'inferred-runtime');
 compile('runtime-types',{compilerOptions:{allowJs:true,checkJs:false,declaration:true,emitDeclarationOnly:true,
  noEmitOnError:true,target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',types:[],outDir:inferred},files:[helper]});
 const runtime=path.join(directory(emission.packages[0]),'dist/js/generated/runtime.d.mts');
 fs.appendFileSync(runtime,fs.readFileSync(path.join(inferred,'js-runtime.d.mts')));
 const paths={};
 for(const [unit,specifier]of emission.packages.entries()){
  const module=specifier.split('/')[3],pkg=directory(specifier);
  paths[specifier]=[path.join(pkg,'dist/js/generated',module+'.d.mts')];
  paths[specifier+'/ts']=[path.join(pkg,'src/ts/generated',module+'.mts')];
 }
 for(const name of ordered){
  const pkg=path.join(root,'node_modules',name);
  compile('typescript-'+name.split('/')[1],{compilerOptions:{strict:true,verbatimModuleSyntax:true,noEmitOnError:true,
   target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',declaration:true,declarationMap:true,
   sourceMap:true,inlineSources:true,types:[],lib:['ES2022','DOM'],rootDir:path.join(pkg,'src/ts'),
   outDir:path.join(pkg,'dist/ts'),paths},files:sources.get(name)});
  for(const unit of packageRows.get(name).units){
   const specifier=emission.packages[unit],module=specifier.split('/')[3];
   paths[specifier+'/ts']=[path.join(pkg,'dist/ts/generated',module+'.d.mts')];
  }
  const dependencies=Object.fromEntries(Object.entries(packageRows.get(name).dependencies).sort());
  packageRows.get(name).dependencies=dependencies;
  put(path.join(pkg,'package.json'),json({name,version,type:'module',license:'Apache-2.0',engines:{node:'>=22.23.3'},
   exports:{'./generated/*/ts':{types:'./dist/ts/generated/*.d.mts',import:'./dist/ts/generated/*.mjs'},
    './generated/*':{types:'./dist/js/generated/*.d.mts',import:'./dist/js/generated/*.mjs'},'./package.json':'./package.json'},
   files:['dist','src','sources','PROVENANCE.json','LICENSE','NOTICE'],dependencies,
   proofscript:{profile:emission.protocol,sourceClosureDigest:emission.sourceClosureDigest,
    kind:'candidate-source-owned-executable-modules',admissionAuthority:false,publicationAuthority:false,
    publicApiPromotion:false,fullModularSelfHosting:false}}));
  put(path.join(pkg,'LICENSE'),fs.readFileSync('LICENSE'));
  put(path.join(pkg,'NOTICE'),fs.readFileSync('NOTICE'));
  const owned=sourceRows.filter(row=>row.package===name);
  for(const row of owned)put(path.join(pkg,'sources',row.module+'.lean'),row.text);
  put(path.join(pkg,'PROVENANCE.json'),json({schema:'psc1-executable-package-provenance/1',
   sourceClosureDigest:emission.sourceClosureDigest,sourceModules:owned.map(s=>s.module),
   units:packageRows.get(name).units.map(unit=>emission.units[unit]),logicalAdmission:'accepted',
   checkerCommit:receipt.checkerCommit,publicApiPromotion:false,
   originalSourceMapping:'captured declaration ownership; no fabricated Lean line maps'}));
 }
 const entryOwner=emission.owners.find(([name])=>name==='psCompilerServiceCandidate')?.[1];
 assert.ok(Number.isSafeInteger(entryOwner),'PSC1_EXECUTABLE_COMPILER_ENTRY_OWNER');
 const entrySpecifier=emission.packages[entryOwner],pkg=directory(entrySpecifier),module=entrySpecifier.split('/')[3];
 const entry=Object.fromEntries(['js','ts'].map(v=>[v,path.relative(root,path.join(pkg,'dist',v,'generated',module+'.mjs')).split(path.sep).join('/')]));
 const graphEvidence={};
 for(const variant of ['js','ts']){
  let weakMaps=0,symbols=0;
  graphEvidence[variant]=emission.packages.map((specifier,unit)=>{
   const pkg=directory(specifier),module=specifier.split('/')[3];
   const source=fs.readFileSync(path.join(pkg,'dist',variant,'generated',module+'.mjs'),'utf8'),row=inspectModule(source);
   assert.deepEqual(row.exports,[...emission[variant][unit].exports].sort(),'PSC1_EXECUTABLE_EXPORT_IDENTITY:'+specifier);
   assert.deepEqual(row.imports,emission[variant][unit].imports.filter(i=>!i.typeOnly).map(i=>({source:i.source,names:[...i.names].sort()})),
    'PSC1_EXECUTABLE_IMPORT_IDENTITY:'+specifier);
   assert.equal(row.weakMaps,unit===0?1:0,'PSC1_EXECUTABLE_SHARED_TRAMPOLINE');
   if(unit!==0)assert.equal(row.symbols,0,'PSC1_EXECUTABLE_SHARED_NOMINAL_IDENTITY');
   weakMaps+=row.weakMaps;symbols+=row.symbols;
   return {specifier,bytes:Buffer.byteLength(source),exports:row.exports.length,imports:row.imports.length};
  });
  console.log('PSC1_EXECUTABLE_GRAPH '+variant+' '+JSON.stringify({units:emission.units.length,weakMaps,symbols}));
 }
 const manifest={schema:'psc1-executable-npm-graph/1',protocol:emission.protocol,version,
  compilerCommit:process.env.GITHUB_SHA,sourceClosureDigest:emission.sourceClosureDigest,
  runtimeOwner:'@proofscript/foundation',logicalAdmission:'accepted',checkerCommit:receipt.checkerCommit,
  admissionsDigest:receipt.admissionsDigest,entry,packages:ordered.map(name=>packageRows.get(name)),
  owners:emission.owners,units:emission.units,graphEvidence,files:inventory(root),
  fullModularSelfHosting:false,publicApiPromotion:false};
 const bytes=Buffer.from(json(manifest)),manifestFile=path.join(output,'manifest.json');
 put(manifestFile,bytes);
 return {root,manifest,manifestFile,manifestBytes:bytes,manifestHash:sha256(bytes),sdkDigest:sha256(json(sdk.map(({file,...r})=>r)))};
}
