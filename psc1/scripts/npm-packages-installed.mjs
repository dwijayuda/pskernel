// Focused installed-package qualification. No compiler/kernel rebuild/self-host rerun.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {fixtures} from './kernel435-fixtures.mjs';
import {corpus,refusals} from './generated-target-corpus.mjs';
import {sha256} from './kernel435-qualified-artifact.mjs';
const root=process.cwd(),out=path.resolve('dist/npm-packages'),contract=JSON.parse(fs.readFileSync('NPM_PACKAGE_CONTRACT.json'));
const builds=JSON.parse(fs.readFileSync(path.join(out,'package-builds.json'))).packages;
assert.equal(builds.length,contract.packages.length);
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-existing-packages-')),cases=[];
const json=x=>JSON.stringify(x,null,2)+'\n';
const record=(name,data={})=>{cases.push({name,status:'passed',...data});console.log('PSC1_NPM_PACKAGE_CASE '+name);};
function call(exe,args,cwd,extra={}){return spawnSync(exe,args,{cwd,encoding:'utf8',timeout:240000,maxBuffer:33554432,...extra});}
function run(exe,args,cwd,extra={}){const r=call(exe,args,cwd,extra);assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;}
function project(name){
 const cwd=path.join(temp,name);fs.mkdirSync(cwd);fs.writeFileSync(path.join(cwd,'package.json'),'{"private":true,"type":"module"}');return cwd;
}
function install(cwd,tarballs,extra=[]){
 return run('npm',['install','--offline','--ignore-scripts','--no-audit','--no-fund','--registry','http://127.0.0.1:9',
  '--cache',path.join(cwd,'empty-cache'),...extra,...tarballs],cwd);
}
function script(cwd,name,text,args=[],runtime=process.execPath){
 const file=path.join(cwd,name);fs.writeFileSync(file,text);
 return run(runtime,[file,...args],cwd);
}
const tar=r=>path.join(out,'tarballs',r.tarball);
function verifyTars(){for(const r of builds){const b=fs.readFileSync(tar(r));assert.equal(b.length,r.bytes);assert.equal(sha256(b),r.sha256);}}
try{
 verifyTars();
 const defaultProject=project('default'),rootBuild=builds.find(r=>r.name==='proofscript');
 install(defaultProject,[tar(rootBuild)]);
 const defaultRoot=path.join(defaultProject,'node_modules/proofscript');
 const installedImpl=path.join(defaultRoot,'dist/implementation'),d=JSON.parse(fs.readFileSync(path.join(installedImpl,'UNIVERSAL_DISTRIBUTION.json')));
 for(const pin of d.hostFiles){const b=fs.readFileSync(path.join(installedImpl,pin.path));assert.equal(sha256(b),pin.sha256,'packed host pin:'+pin.path);}
 const identity=JSON.parse(run(path.join(defaultProject,'node_modules/.bin/psc'),['--identity'],defaultProject));
 assert.equal(identity.version,contract.version);assert.equal(identity.defaultKernel,'wasm');
 assert.equal(identity.engines.rust.installed,false);assert.equal(identity.engines['wasm-core'].installed,false);
 assert.match(run(path.join(defaultProject,'node_modules/.bin/psc'),['--help'],defaultProject),/psc check/);
 for(const n of ['@proofscript/backend-python','@proofscript/backend-php','@proofscript/compiler-rust-linux-x64',
   '@proofscript/compiler-wasm','@proofscript/pskernel-lean'])assert.equal(fs.existsSync(path.join(defaultProject,'node_modules',n)),false);
 record('default-root-is-small-and-optional-payloads-absent',{rootTarballBytes:rootBuild.bytes});
 const global=path.join(temp,'global');
 install(defaultProject,[tar(rootBuild)],['--global','--prefix',global]);
 assert.match(run(path.join(global,'bin/psc'),['--help'],defaultProject),/psc check/);
 record('fresh-global-cli');

 fs.writeFileSync(path.join(defaultProject,'Main.lean'),'def answer : Nat := 42\n');
 const localCli=path.join(defaultProject,'node_modules/.bin/psc');
 const checked=JSON.parse(run(localCli,['check','Main.lean'],defaultProject));
 assert.equal(checked.logicalAdmission,'accepted');record('fresh-local-cli-check');
 const published=JSON.parse(run(path.join(global,'bin/psc'),['build','Main.lean','--target','js',
  '--publication-protocol','portable-file','--out','compiled'],defaultProject));
 assert.equal(published.logicalAdmission,'accepted');assert.equal(published.durability,'confirmed');
 assert.ok(fs.statSync(published.runtimeArtifact).isFile());
 script(defaultProject,'published.mjs',"import{pathToFileURL}from 'node:url';const m=await import(pathToFileURL(process.argv[2]));if(m.answer!==42n)throw Error('CLI output');",[published.runtimeArtifact]);
 record('fresh-global-cli-checked-publication');

 const cwd=project('all-packages');install(cwd,builds.map(tar));record('all24-offline-install');
 const nodes=path.join(cwd,'node_modules'),rootInstalled=path.join(nodes,'proofscript');
 const exportCode=[
  "import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';",
  "const records=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));let count=0;",
  "for(const r of records){const m=JSON.parse(fs.readFileSync(path.join('node_modules',r.name,'package.json')));",
  "assert.equal(m.name,r.name);for(const [key,value]of Object.entries(m.exports)){",
  "const name=r.name+(key==='.'?'':key.slice(1));const target=typeof value==='string'?value:value.import;",
  "if(target.endsWith('.json'))await import(name,{with:{type:'json'}});else await import(name);count++;}}",
  "console.log(JSON.stringify({count}));"
 ].join('\n');
 const manifest=path.join(cwd,'packages.json');fs.writeFileSync(manifest,json(builds));
 const exports=JSON.parse(script(cwd,'imports.mjs',exportCode,[manifest]));

 for(const p of contract.packages){
  const packageRoot=path.join(nodes,p.name);
  assert.equal(sha256(fs.readFileSync(path.join(packageRoot,'LICENSE'))),sha256(fs.readFileSync('LICENSE')));
  assert.ok(fs.readFileSync(path.join(packageRoot,'NOTICE'),'utf8').trim().length>0);
 }
 for(const dir of ['backend-python','backend-php'])for(const name of ['LICENSE','NOTICE'])
  assert.ok(fs.statSync(path.join(nodes,'@proofscript',dir,'dist/QUALIFIED_INPUT_'+name)).size>0);
 record('owned-licenses-and-qualified-input-notices-retained');
 const frozenAudit=JSON.parse(fs.readFileSync(path.join(out,'inventory.json')));
 const metadataChanges=new Set(['package.json','UNIVERSAL_DISTRIBUTION.json','DISTRIBUTION_PIN.mjs','DEPENDENCY_LOCK.json','npm-shrinkwrap.json']);
 let preserved=0;
 for(const pin of frozenAudit.frozenFiles){
  if(pin.path.startsWith('node_modules/')||metadataChanges.has(pin.path))continue;
  const bytes=fs.readFileSync(path.join(rootInstalled,'dist/implementation',pin.path));
  assert.equal(bytes.length,pin.bytes);assert.equal(sha256(bytes),pin.sha256);preserved++;
 }
 assert.ok(preserved>50);record('qualified-root-execution-files-byte-preserved',{files:preserved,metadataChanges:[...metadataChanges]});
record('all-advertised-exports-import',{exports:exports.count});
 for(const runtime of [process.execPath,'bun']){
  const observed=script(cwd,'shared.mjs',[
   "import assert from 'node:assert/strict';",
   "import * as root from 'proofscript';import * as compiler from '@proofscript/compiler';",
   "import * as foundation from '@proofscript/foundation';import * as syntax from '@proofscript/syntax/compiler';",
   "assert.equal(root.compile,compiler.compile);assert.equal(root.compile,syntax.compile);",
   "assert.equal(root.getCompilerMetadata,compiler.getCompilerMetadata);",
   "const sources=foundation.readSources();assert.ok(sources.length>=5);assert.ok(sources.some(s=>s.module==='Ps.Foundation.Name'));",
   "assert.equal(foundation.sourcePackage.internalRuntimeApi,false);",
   "assert.equal('psNameAppendStr' in foundation,false);",
   "console.log(JSON.stringify({sourceModules:sources.length,version:root.getCompilerMetadata().version}));"
  ].join('\n'),[],runtime);
  record('single-shared-runtime-'+(runtime==='bun'?'bun':'node'),JSON.parse(observed));
 }
 const payloads=[];
 function findBundles(dir){for(const n of fs.readdirSync(dir)){const p=path.join(dir,n),s=fs.lstatSync(p);
  if(s.isDirectory())findBundles(p);else if(n==='module.js'&&p.includes('/selfhost/'))payloads.push(p);}}
 findBundles(nodes);assert.equal(payloads.length,2,'only the original JS and TS compiler executors');
 record('no-per-package-compiler-bundle-duplication',{payloads:payloads.map(p=>path.relative(nodes,p))});
 const baseline=project('baseline');
 // Root archive may include an enclosing directory. Locate its exact pinned tarball.
 const baseInput=JSON.parse(fs.readFileSync('scripts/npm-packages-input.json')).root;
 let baselineTar;
 function findBase(dir){for(const n of fs.readdirSync(dir)){const p=path.join(dir,n);if(fs.statSync(p).isDirectory())findBase(p);else if(n===baseInput.tarball)baselineTar=p;}}
 findBase(path.join(out,'qualified-input'));assert.ok(baselineTar);install(baseline,[baselineTar]);
 const samples=corpus.slice(0,2).map(c=>({sources:c.sources.map(s=>({...s,kind:c.grammar})),entryModule:c.entry,assurance:c.assurance}));
 for(const [index,options]of samples.entries()){
  for(const engine of ['js','ts']){
   const compile="import {compile}from 'proofscript';const r=compile(JSON.parse(process.argv[2]));console.log(JSON.stringify({source:r.source,admission:r.logicalAdmission,ir:r.irValidation}));";
   const args=[JSON.stringify({...options,engine,target:'js'})];
   const actual=JSON.parse(script(cwd,'compile.mjs',compile,args));
   const expected=JSON.parse(script(baseline,'compile.mjs',compile,args));
   assert.equal(actual.admission,'accepted');assert.deepEqual(actual,expected);
   fs.writeFileSync(path.join(cwd,'output-'+index+'-'+engine+'.mjs'),actual.source);
   const check="import * as m from './output-"+index+"-"+engine+".mjs';"+corpus[index].consumer;
   script(cwd,'observe.mjs',check);
   record('checked-source-and-output-parity-'+index+'-'+engine);
  }
 }
 for(const provider of ['@proofscript/pskernel-lean-wasm','@proofscript/pskernel-lean']){
  const results=JSON.parse(script(cwd,'kernel.mjs',[
   "import {createKernel}from "+JSON.stringify(provider)+";",
   "const h=await createKernel({allowSourceCheckoutFallback:false});",
   "const fixtures=JSON.parse(process.argv[2]),r=[];",
   "for(const f of fixtures)r.push((await h.checkCanonicalAdmissions(f.input)).accepted);",
   "console.log(JSON.stringify(r));"
  ].join('\n'),[JSON.stringify(fixtures)]));
  assert.deepEqual(results,fixtures.map(f=>f.accepted));
  record('independent-'+provider.split('/')[1]+'-accept-and-reject',{cases:results.length});
 }
 // New adapters return the existing checked API; no source language is reimplemented.
 for(const target of ['js','wasm-core','python','php']){
  const options={...samples[0],engine:'js',target};
  const selectedPackage='@proofscript/backend-'+(target==='wasm-core'?'wasm':target);
  const code="import{compile}from '"+selectedPackage+"';const r=compile(JSON.parse(process.argv[2]));if(r.logicalAdmission!=='accepted')throw Error('unchecked');console.log(JSON.stringify({target:r.target,sourceEncoding:r.sourceEncoding,source:r.source}));";
  const response=JSON.parse(script(cwd,'targets.mjs',code,[JSON.stringify(options)]));
  assert.equal(response.target,target);assert.ok(response.source.length>0);record('checked-installed-target-'+target);
 }
 // Optional execution engines, validators and SDKs retain their original archives.
 const extras=JSON.parse(fs.readFileSync(path.join(out,'qualified-bundles.json'))),extraTars=new Map();
 function findExtras(dir){for(const n of fs.readdirSync(dir)){const p=path.join(dir,n);if(fs.statSync(p).isDirectory())findExtras(p);else if(n.endsWith('.tgz'))extraTars.set(n,p);}}
 findExtras(path.join(out,'qualified-bundles'));
 const external=extras.filter(e=>!builds.some(b=>b.name===e.meta.name));
 for(const e of external)assert.equal(sha256(fs.readFileSync(extraTars.get(e.tarball))),e.sha256);
 install(cwd,external.map(e=>extraTars.get(e.tarball)));record('unchanged-optional-engines-and-sdks-install');
 const tsc=path.join(nodes,'typescript/bin/tsc');
 fs.writeFileSync(path.join(cwd,'consumer.mts'),[
  "import{compile,getCompilerMetadata}from '@proofscript/compiler';",
  "import{readSources}from '@proofscript/foundation';",
  "import{compile as compileJs}from '@proofscript/backend-js';",
  "import{createKernel}from '@proofscript/pskernel-lean-wasm';",
  "const sources=readSources();const source:string=sources[0].text;",
  "const v:string=getCompilerMetadata().version;",
  "const r=compileJs({sources:[{module:'Main',kind:'lean',text:'def answer : Nat := 42'}],entryModule:'Main'});",
  "const accepted:'accepted'=r.logicalAdmission;",
  "const kernel=await createKernel();const ok:boolean=(await kernel.checkCanonicalAdmissions('{}')).accepted;",
  "// @ts-expect-error kind is a closed grammar",
  "compile({sources:[{module:'Main',kind:'unknown',text:''}],entryModule:'Main'});",
  "// @ts-expect-error no private low-level helper is exposed",
  "import{psNameAppendStr}from '@proofscript/foundation';"
 ].join('\n'));
 fs.writeFileSync(path.join(cwd,'tsconfig.json'),JSON.stringify({compilerOptions:{strict:true,noEmit:true,target:'ES2022',
  module:'NodeNext',moduleResolution:'NodeNext',types:[],lib:['ES2022','DOM']},files:['consumer.mts']}));
 run(process.execPath,[tsc,'--project','tsconfig.json'],cwd);record('accurate-strict-public-declarations');
 for(const engine of ['rust','wasm-core']){
  const options={...samples[0],engine,target:'js'};
  const actual=JSON.parse(script(cwd,'compile.mjs',"import{compile}from 'proofscript';const r=compile(JSON.parse(process.argv[2]));console.log(JSON.stringify({source:r.source,admission:r.logicalAdmission,ir:r.irValidation}));",[JSON.stringify(options)]));
  const expected=JSON.parse(script(cwd,'compile.mjs',"import{compile}from 'proofscript';const r=compile(JSON.parse(process.argv[2]));console.log(JSON.stringify({source:r.source,admission:r.logicalAdmission,ir:r.irValidation}));",[JSON.stringify({...options,engine:'js'})]));
  assert.deepEqual(actual,expected);record('existing-optional-compiler-engine-'+engine);
 }
 for(const target of ['ts','rust','wasm-component']){
  const options=target==='wasm-component'?{sources:[{module:'Entry',kind:'lean',text:'def answer : Bool := true'}],entryModule:'Entry',engine:'js',target}:
   {...samples[0],engine:'js',target};
  const selectedPackage=target==='wasm-component'?'@proofscript/backend-wasm/compiler':'@proofscript/backend-'+target;
  const response=JSON.parse(script(cwd,'more-targets.mjs',"import{compile}from '"+selectedPackage+"';const r=compile(JSON.parse(process.argv[2]));if(r.logicalAdmission!=='accepted')throw Error('unchecked');console.log(JSON.stringify({target:r.target,source:r.source}));",[JSON.stringify(options)]));
  assert.equal(response.target,target);assert.ok(response.source.length>0);record('checked-installed-target-'+target);
 }
 // Compile actual source snapshots from a separately installed existing package.
 const foundationCode=[
  "import{readSources}from '@proofscript/foundation';import{compile}from '@proofscript/compiler';",
  "const sources=[...readSources()];const text=sources.map(s=>'import '+s.module).join('\\n')+'\\ndef answer : String := psNameToString (psNameAppendStr PsName.anonymous \"café\")\\n';",
  "sources.push({module:'Entry',kind:'lean',text});const r=compile({sources,entryModule:'Entry'});",
  "if(r.logicalAdmission!=='accepted')throw Error('unchecked');console.log(JSON.stringify(r.source));"
 ].join('\n');
 const foundationOutput=JSON.parse(script(cwd,'source-package.mjs',foundationCode));
 fs.writeFileSync(path.join(cwd,'foundation-output.mjs'),foundationOutput);
 script(cwd,'foundation-observe.mjs',"import{answer}from './foundation-output.mjs';if(answer!=='café')throw Error('source package output');");
 record('existing-source-package-compiles-through-shared-compiler');


 const mismatch=call(process.execPath,['--input-type=module','--eval',
  "import{compile}from '@proofscript/backend-js';try{compile({target:'rust'});throw Error('accepted')}catch(e){if(String(e).includes('accepted'))throw e;if(!String(e).includes('PSC1_PACKAGE_TARGET'))throw e;}"],cwd);
 assert.equal(mismatch.status,0,mismatch.stderr);record('backend-target-mismatch-refused');

 for(const fixture of refusals.slice(0,4)){
  const code="import{compile}from 'proofscript';try{compile(JSON.parse(process.argv[2]));throw Error('unexpected-acceptance')}catch(e){if(String(e).includes('unexpected-acceptance'))throw e;console.log('refused')}";
  const options={sources:[{module:'Entry',kind:fixture.grammar,text:fixture.source}],entryModule:'Entry',assurance:fixture.assurance};
  assert.equal(script(cwd,'refuse.mjs',code,[JSON.stringify(options)]).trim(),'refused');record('semantic-refusal-'+fixture.id);
 }
 // Source integrity is data integrity; it does not confer proof-admission authority.
 const source=path.join(nodes,'@proofscript/foundation/src/Ps/Foundation/Name.lean'),before=fs.readFileSync(source);
 try{fs.appendFileSync(source,'\n-- changed\n');
  const r=call(process.execPath,['--input-type=module','--eval',"import{readSources}from '@proofscript/foundation';readSources();"],cwd);
  assert.notEqual(r.status,0);assert.match(r.stderr,/PSC1_PACKAGE_SOURCE_IDENTITY/);
 }finally{fs.writeFileSync(source,before);}record('modified-source-snapshot-refused');
 const implementation=path.join(rootInstalled,'dist/implementation'),body=path.join(implementation,'selfhost/js/module.js'),bodyBytes=fs.readFileSync(body);
 try{fs.appendFileSync(body,"\nthrow Error('tampered-executed');");
  const r=call(process.execPath,[path.join(cwd,'compile.mjs'),JSON.stringify({...samples[0],engine:'js',target:'js'})],cwd);
  assert.notEqual(r.status,0);assert.match(r.stderr,/PSC1_INSTALLED_RESOURCE_IDENTITY/);assert.doesNotMatch(r.stderr,/tampered-executed/);
 }finally{fs.writeFileSync(body,bodyBytes);}record('modified-executable-refused-before-execution');
 const broken=path.join(nodes,'@proofscript/compiler/package.json'),oldMeta=fs.readFileSync(broken);
 try{const m=JSON.parse(oldMeta);m.exports['.'].import='./dist/missing.js';fs.writeFileSync(broken,json(m));
  const r=call(process.execPath,['--input-type=module','--eval',"import '@proofscript/compiler'"],cwd);
  assert.notEqual(r.status,0);assert.match(r.stderr,/ERR_MODULE_NOT_FOUND/);
 }finally{fs.writeFileSync(broken,oldMeta);}record('broken-export-refused');
 const missing=project('missing-dependency');
 const r=call('npm',['install','--offline','--ignore-scripts','--registry','http://127.0.0.1:9','--cache',path.join(missing,'empty'),
  tar(builds.find(b=>b.name==='@proofscript/compiler'))],missing);
 assert.notEqual(r.status,0);record('missing-exact-shared-dependency-refused');
 const incompatible=project('incompatible');
 const wrong=call('npm',['install','--offline','--ignore-scripts','--registry','http://127.0.0.1:9','--cache',path.join(incompatible,'empty'),
  baselineTar,tar(builds.find(b=>b.name==='@proofscript/compiler'))],incompatible);
 assert.notEqual(wrong.status,0);record('incompatible-shared-version-refused');
 for(const dir of ['foundation','proofscript']){
  const original=builds.find(b=>b.directory===dir);
  run('npm',['run','clean'],path.join(root,'packages',dir));
  assert.equal(fs.existsSync(path.join(root,'packages',dir,'dist')),false);
  run('npm',['run','build'],path.join(root,'packages',dir));
  const repacked=JSON.parse(run('npm',['pack','--ignore-scripts','--json','--pack-destination',out],path.join(root,'packages',dir)))[0];
  assert.equal(sha256(fs.readFileSync(path.join(out,repacked.filename))),original.sha256);
  record('clean-build-pack-reproduces-'+dir);
 }
 verifyTars();
 for(const p of contract.packages)run('npm',['run','build'],path.join(root,'packages',p.directory));
 record('individual-build-command-all24');
 assert.deepEqual(cases.map(c=>c.name).sort(),contract.requiredCases,'finite distribution case coverage');
 const report={schema:'psc1-simple-npm-package-qualification/1',testedCommit:process.env.GITHUB_SHA,
  status:'passed',modularNpmDistribution:'qualified-linux-packaging-scope',independentCompilerInternalModularity:'deferred',
  cases,packages:builds.map(({files,...r})=>r),sharedImplementationOwner:'proofscript',
  qualification:'npm/API/CLI/source-adapter wiring with preserved qualified implementation; not new internal-module or fixed-point qualification',
  platforms:['linux-x64'],noRegistryPublication:true};
 fs.writeFileSync(path.join(out,'qualification.json'),json(report));console.log('PSC1_SIMPLE_PACKAGES_QUALIFIED '+JSON.stringify(report));
}finally{fs.rmSync(temp,{recursive:true,force:true});}
