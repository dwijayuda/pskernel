import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {buildPilot} from '../../host-tools/modular/build.mjs';
import {run,sha256,moduleProfile,compileSources} from '../../host-tools/modular/compiler.mjs';
import {readPublication} from '../../host-tools/transactional-publication.mjs';

const files=[
 ['Ps.Foundation.List','packages/foundation/src/Ps/Foundation/List.lean'],
 ['Ps.Foundation.Name','packages/foundation/src/Ps/Foundation/Name.lean'],
 ['Ps.Foundation.Text','packages/foundation/src/Ps/Foundation/Text.lean'],
 ['Ps.Bridge.Json','packages/bridge/src/Ps/Bridge/Json.lean'],
 ['Pilot.Consumer','test/modular/Extended.lean']
];
const sources=files.map(([module,file])=>({module,kind:'lean',text:fs.readFileSync(file,'utf8')}));
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-extended-packages-'));
const producer=path.resolve('.lake/build/bin/psc1_modular_pilot'),tsc=path.resolve('../node_modules/typescript/bin/tsc');
const observation=fs.readFileSync('test/modular/extended-observe.mjs','utf8');
const result={schema:'psc1-extended-modular-qualification/2',testedCommit:process.env.GITHUB_SHA,
 scope:'five-source compiler component graph with explicit specialization/worker provenance; not whole-compiler modular self-hosting',
 cases:[],profiles:[],wholeCompilerQualified:false,modularSelfHosted:false};
const record=(name,data={status:'passed'})=>{result.cases.push({name,...data});console.log('PSC1_EXTENDED_CASE '+name);};
function install(built,name){
 const cwd=path.join(temporary,name);fs.mkdirSync(cwd);
 fs.writeFileSync(path.join(cwd,'package.json'),JSON.stringify({name:'extended-offline-consumer',private:true,type:'module'}));
 run('npm',['install','--offline','--ignore-scripts','--no-audit','--no-fund','--registry','http://127.0.0.1:9',
   '--cache',path.join(cwd,'empty-cache'),...[...built.packages,built.rootTar].map(p=>path.join(built.directory,p.tarball))],{cwd});
 fs.writeFileSync(path.join(cwd,'observe.mjs'),observation);return cwd;
}
function observe(cwd,variant,runtime=process.execPath,reference){
 return JSON.parse(run(runtime,['observe.mjs',reference?'reference':'installed',variant,...(reference?[reference]:[])],{cwd}));
}
function declarations(cwd,resolution){
 fs.writeFileSync(path.join(cwd,'consumer.mts'),[
  "import{loadPilot}from '@proofscript/modular-compiler-pilot';",
  "const js=await loadPilot();const ts=await loadPilot({variant:'ts'});",
  "const a:bigint=js.consumer.extendedNumbers(42n);",
  "const b:string=ts.consumer.extendedCanonical('{}');",
  "const c:bigint=ts.consumer.extendedDepth(ts.names.psNameAppendNum(ts.consumer.extendedSeed,42n));",
  "const d:string=ts.modules['@proofscript/modular-pilot-ps-foundation-text'].psTextBuilderFinish(ts.modules['@proofscript/modular-pilot-ps-foundation-text'].psTextBuilderEmpty);",
  "// @ts-expect-error Nat requires bigint",
  "js.consumer.extendedNumbers(42);",
  "// @ts-expect-error source parameter is String",
  "ts.consumer.extendedCanonical(42n);",
  "// @ts-expect-error JS and TS nominal representations differ",
  "ts.consumer.extendedDepth(js.consumer.extendedSeed);",
  "// @ts-expect-error declared module map is finite",
  "js.modules['@proofscript/unlisted'];"
 ].join('\n'));
 fs.writeFileSync(path.join(cwd,'tsconfig.json'),JSON.stringify({compilerOptions:{strict:true,noEmit:true,
   target:'ES2022',module:resolution==='NodeNext'?'NodeNext':'ESNext',moduleResolution:resolution,
   types:[],lib:['ES2022','DOM']},files:['consumer.mts']}));
 run(process.execPath,[tsc,'--project','tsconfig.json'],{cwd});
}
function audit(c){
 const names=raw=>({structure:new Map(raw[2].map(item=>[item[0],item])),
   inductive:new Map(raw[3].map(item=>[item[0],item])),declaration:new Map(raw[4].map(item=>[item[0],item]))});
 const carry=(input,inputOwners,output,rows)=>{
   const a=names(input),b=names(output),owners=new Map(inputOwners),seen=new Set();
   assert.equal(owners.size,input[4].length);
   assert.equal(rows.length,output[2].length+output[3].length+output[4].length);
   const next=[];
   for(const row of rows){
     assert.ok(a[row.kind]?.has(row.inputName));assert.ok(b[row.kind]?.has(row.outputName));
     const key=row.kind+':'+row.outputName;assert.ok(!seen.has(key));seen.add(key);
     if(row.rule==='retained-identity'){assert.equal(row.outputName,row.inputName);assert.deepEqual(row.arguments,[]);}
     else if(row.rule==='specialization'){assert.equal(row.arguments.length,a[row.kind].get(row.inputName)[1].length);}
     else{assert.equal(row.rule,'worker');assert.equal(row.kind,'declaration');assert.ok(!a.declaration.has(row.outputName));}
     if(row.kind==='declaration')next.push([row.outputName,owners.get(row.inputName)]);
   }
   return new Map(next);
 };
 const selected=carry(c.originalIr,c.originalOwners,c.specializedIr,c.transformOrigins.specialization);
 assert.deepEqual(selected,new Map(c.specializedOwners));
 const final=carry(c.specializedIr,c.specializedOwners,c.transformedIr,c.transformOrigins.workerFusion);
 assert.deepEqual(final,new Map(c.owners));
 const created=c.transformOrigins.specialization.filter(row=>row.rule==='specialization');
 assert.ok(created.some(row=>row.kind==='structure'));assert.ok(created.some(row=>row.kind==='inductive'));
 assert.ok(created.some(row=>row.kind==='declaration'));
 const values=new Set(created.filter(row=>row.kind==='declaration').map(row=>row.outputName));
 const chained=c.transformOrigins.workerFusion.filter(row=>row.rule==='worker'&&values.has(row.inputName));
 assert.ok(chained.length>=2);
 for(const row of chained)assert.equal(final.get(row.outputName),selected.get(row.inputName));
 assert.ok(c.units.slice(1).every(unit=>unit.names.length>0));assert.equal(c.units.length,6);
 return{original:c.originalIr[4].length,specialized:c.specializedIr[4].length,
   fused:c.transformedIr[4].length,specializations:created.length,
   workers:c.transformOrigins.workerFusion.filter(row=>row.rule==='worker').length,
   specializedWorkers:chained.length,unitValues:c.units.map(unit=>unit.names.length)};
}
function refuse(cwd,label,change,restore){
 try{
  change();
  const code="import{loadPilot}from '@proofscript/modular-compiler-pilot';try{await loadPilot();process.exitCode=2}catch(e){if(!String(e).includes('PSC1_MODULAR_')&&e.code!=='ENOENT')throw e;console.log('refused')}";
  assert.equal(run(process.execPath,['--input-type=module','--eval',code],{cwd}).trim(),'refused');
  record(label,{status:'refused-before-import'});
 }finally{restore();}
}
try{
 const ps=sources.map((source,index)=>{
  const file=path.join(temporary,'source-'+index+'.lean');fs.writeFileSync(file,source.text);
  return{...source,kind:'ps',text:run('/usr/bin/prlimit',['--as=4294967296','--stack=8388608','--cpu=240','--',producer,'--translate',file])};
 });
 const builds=[];
 for(const input of [sources,ps]){
  const kind=input[0].kind,out=path.resolve('dist/modular/extended-'+kind);
  const variants=Object.fromEntries((kind==='lean'?ps:sources).map(source=>[source.module,source]));
  const built=buildPilot({sources:input,out,profile:'extended',sourceVariants:variants,requestId:'extended-pack-'+kind});
  builds.push(built);
  const c=built.candidate,originAudit=audit(c);record(kind+'-origin-composition',{status:'passed',...originAudit});
  const cwd=install(built,'installed-'+kind);
  for(const resolution of ['NodeNext','Bundler']){declarations(cwd,resolution);record(kind+'-'+resolution);}
  const referenceJs=path.join(cwd,'reference-js.mjs');fs.writeFileSync(referenceJs,c.referenceJs);
  fs.writeFileSync(path.join(cwd,'reference-ts.mts'),c.referenceTs);
  fs.writeFileSync(path.join(cwd,'reference-config.json'),JSON.stringify({compilerOptions:{strict:true,noEmitOnError:true,
    target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',rootDir:cwd,outDir:path.join(cwd,'reference-output'),
    types:[],lib:['ES2022','DOM']},files:['reference-ts.mts']}));
  run(process.execPath,[tsc,'--project','reference-config.json'],{cwd});
  for(const variant of ['js','ts']){
   const reference=variant==='js'?referenceJs:path.join(cwd,'reference-output/reference-ts.mjs');
   const expected=observe(cwd,variant,process.execPath,reference);
   for(const runtime of [process.execPath,'bun']){
    const actual=observe(cwd,variant,runtime);assert.deepEqual(actual.observations,expected.observations);
    record(kind+'-'+variant+'-'+actual.runtime,{status:'passed',observations:actual.observations.length,
      elapsedMs:actual.elapsedMs,loadedMs:actual.loadedMs,processMaxRssKiB:actual.processMaxRssKiB});
   }
  }
  for(const [index,pkg]of built.packages.entries()){
   const root=path.join(cwd,'node_modules',pkg.name),meta=JSON.parse(fs.readFileSync(path.join(root,'package.json')));
   assert.equal(meta.license,'Apache-2.0');assert.equal(meta.version,'0.1.0-psc1-modular-pilot.1');
   assert.ok(Object.keys(meta.dependencies).every(name=>built.packages.some(p=>p.name===name)));
   for(const branch of ['.','./ts'])for(const key of ['types','import'])assert.ok(fs.statSync(path.join(root,meta.exports[branch][key])).isFile());
   const map=JSON.parse(fs.readFileSync(path.join(root,'dist/ts/index.mjs.map'))),text=fs.readFileSync(path.join(root,'src/ts/index.mts'),'utf8');
   assert.deepEqual(map.sourcesContent,[text]);
   if(index>0)for(const source of [input[index-1],variants[input[index-1].module]])
     assert.equal(fs.readFileSync(path.join(root,'sources',source.module.split('.').at(-1)+'.'+source.kind),'utf8'),source.text);
  }
  record(kind+'-inventory-and-source-maps');
  const target=path.join(cwd,'node_modules/@proofscript/modular-pilot-ps-bridge-json/dist/js/index.mjs'),before=fs.readFileSync(target);
  refuse(cwd,kind+'-modified-json-module',()=>fs.appendFileSync(target,'\nthrow Error("executed");'),()=>fs.writeFileSync(target,before));
  const provenance=path.join(cwd,'node_modules/@proofscript/modular-pilot-ps-foundation-list/PROVENANCE.json'),old=fs.readFileSync(provenance);
  refuse(cwd,kind+'-modified-transform-provenance',()=>fs.writeFileSync(provenance,'{}'),()=>fs.writeFileSync(provenance,old));
  const installable=path.resolve('dist/modular/installable-extended-'+kind);fs.mkdirSync(installable,{recursive:true});
  for(const item of [...built.packages,built.rootTar])fs.copyFileSync(path.join(built.directory,item.tarball),path.join(installable,item.tarball));
  fs.writeFileSync(path.join(installable,'SHA256SUMS'),[...built.packages,built.rootTar].map(p=>p.sha256+'  '+p.tarball).join('\n')+'\n');
  fs.writeFileSync(path.join(installable,'INSTALL.txt'),'Experimental compiler component graph. Install all seven tarballs together with npm install --offline --ignore-scripts <seven .tgz paths>.\nDefault proofscript distribution and whole modular self-hosting are separate.\n');
  result.profiles.push({kind,sourceClosureDigest:built.receipt.sourceClosureDigest,cohortSha256:built.cohortSha256,
    generation:built.generation,originAudit,execution:built.execution,admission:built.receipt,
    tarballs:[...built.packages,built.rootTar].map(({name,tarball,bytes,sha256})=>({name,tarball,bytes,sha256}))});
  if(kind==='lean'){
   const again=buildPilot({sources:input,out:path.resolve('dist/modular/extended-reproduction'),profile:'extended',
     sourceVariants:variants,requestId:'extended-pack-lean'});
   assert.deepEqual([...again.packages,again.rootTar].map(p=>p.sha256),[...built.packages,built.rootTar].map(p=>p.sha256));
   record('extended-exact-seven-tarball-reproduction');
   const pointer=fs.readFileSync(path.join(out,'current.json'));
   assert.throws(()=>buildPilot({sources:input,out,profile:'extended',sourceVariants:variants,requestId:'extended-transaction-fault',
     publicationFault:point=>{if(point==='before-commit')throw Error('extended-injected');}}),/extended-injected/);
   assert.deepEqual(fs.readFileSync(path.join(out,'current.json')),pointer);
   assert.equal(readPublication(out,'portable-file').generation,built.generation);record('extended-before-commit-retains-prior');
  }
 }
 assert.notEqual(builds[0].receipt.sourceClosureDigest,builds[1].receipt.sourceClosureDigest);
 assert.deepEqual(builds[0].candidate.originalIr,builds[1].candidate.originalIr);
 assert.deepEqual(builds[0].candidate.specializedIr,builds[1].candidate.specializedIr);
 assert.deepEqual(builds[0].candidate.transformedIr,builds[1].candidate.transformedIr);
 assert.equal(builds[0].candidate.admissions,builds[1].candidate.admissions);record('cross-grammar-exact-core-and-transform-parity');
 assert.throws(()=>moduleProfile('extended',[{module:'P.A_B'},{module:'P.A.B'}]),/PSC1_MODULAR_PACKAGE_IDENTITY/);
 record('package-slug-collision',{status:'refused'});
 assert.throws(()=>compileSources({sources:[...sources,...sources],profile:'extended'}),/PSC1_MODULAR_SOURCE_SCOPE/);
 record('extended-source-bound',{status:'refused'});
 result.status='passed';fs.writeFileSync('dist/modular/extended-qualification.json',JSON.stringify(result,null,2)+'\n');
 console.log('PSC1_EXTENDED_QUALIFIED '+JSON.stringify(result));
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
