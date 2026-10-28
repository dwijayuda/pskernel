import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {buildPilot} from '../../host-tools/modular/build.mjs';
import {run,sha256,moduleProfile,compileSources} from '../../host-tools/modular/compiler.mjs';
import {readPublication} from '../../host-tools/transactional-publication.mjs';

const partitioned=process.argv.includes('--partitioned'),profile=partitioned?'partitioned':'extended';
const files=[
 ['Ps.Foundation.List','packages/foundation/src/Ps/Foundation/List.lean'],
 ['Ps.Foundation.Name','packages/foundation/src/Ps/Foundation/Name.lean'],
 ['Ps.Foundation.Text','packages/foundation/src/Ps/Foundation/Text.lean'],
 ['Ps.Bridge.Json','packages/bridge/src/Ps/Bridge/Json.lean'],
 ['Pilot.Consumer','test/modular/Extended.lean']
];
if(partitioned)files.splice(files.length-1,0,
 ['Ps.Foundation.Source','packages/foundation/src/Ps/Foundation/Source.lean'],
 ['Ps.Foundation.StringSet','packages/foundation/src/Ps/Foundation/StringSet.lean']);
if(partitioned)files[files.length-1][1]='test/modular/Partitioned.lean';
const sources=files.map(([module,file])=>({module,kind:'lean',text:fs.readFileSync(file,'utf8')}));
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-extended-packages-'));
const producer=path.resolve('.lake/build/bin/psc1_modular_pilot'),tsc=path.resolve('../node_modules/typescript/bin/tsc');
let observation=fs.readFileSync('test/modular/extended-observe.mjs','utf8');
if(partitioned)observation=observation.replace('graph.modules).length,6','graph.modules).length,7').replace("console.log(JSON.stringify",`assert.equal(c.partitionedSetHas('café🌱'),true);
assert.equal(c.partitionedSetHas('absent'),false);
assert.equal(c.partitionedColumn(c.partitionedSpan),42n);
console.log(JSON.stringify`);
const contract=JSON.parse(fs.readFileSync(partitioned?'test/modular/partition-contract.json':'test/modular/extended-contract.json','utf8'));
const result={contractSha256:sha256(JSON.stringify(contract)),schema:partitioned?'psc1-partitioned-modular-qualification/3':'psc1-extended-modular-qualification/2',testedCommit:process.env.GITHUB_SHA,
 scope:partitioned?'seven-source compiler graph, SCC/type-only partitioning; not whole-compiler modular self-hosting':'five-source compiler component graph with explicit specialization/worker provenance; not whole-compiler modular self-hosting',
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
 if(partitioned)fs.appendFileSync(path.join(cwd,'consumer.mts'),[
  "",
  "const e:bigint=ts.consumer.partitionedColumn(ts.consumer.partitionedSpan);",
  "const f:boolean=js.consumer.partitionedSetHas('café🌱');",
  "// @ts-expect-error shared type-only structure requires nominal TS value",
  "ts.consumer.partitionedColumn(js.consumer.partitionedSpan);"
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
 assert.deepEqual(final,new Map(partitioned?c.unpartitionedOwners:c.owners));
 if(partitioned){
  assert.deepEqual(new Map([...final].map(([name,owner])=>[name,c.partition.sourceToUnit[owner]])),new Map(c.owners));
  assert.equal(c.partition.sourceToUnit[5],0,'real Foundation.Source is type-only');
  assert.equal(c.packages.length,7);assert.equal(c.sourceModules.length,7);
 }
 const created=c.transformOrigins.specialization.filter(row=>row.rule==='specialization');
 assert.ok(created.some(row=>row.kind==='structure'));assert.ok(created.some(row=>row.kind==='inductive'));
 assert.ok(created.some(row=>row.kind==='declaration'));
 const values=new Set(created.filter(row=>row.kind==='declaration').map(row=>row.outputName));
 const chained=c.transformOrigins.workerFusion.filter(row=>row.rule==='worker'&&values.has(row.inputName));
 assert.ok(chained.length>=2);
 for(const row of chained)assert.equal(final.get(row.outputName),selected.get(row.inputName));
 assert.ok(c.units.slice(1).every(unit=>unit.names.length>0));assert.equal(c.units.length,partitioned?7:6);
 return{original:c.originalIr[4].length,specialized:c.specializedIr[4].length,
   fused:c.transformedIr[4].length,specializations:created.length,
   workers:c.transformOrigins.workerFusion.filter(row=>row.rule==='worker').length,
   specializedWorkers:chained.length,unitValues:c.units.map(unit=>unit.names.length)};
}

function baselineParity(built,input,cwd,kind){
 const baseline=process.env.PSC1_TRANSFORM_BASELINE;
 assert.ok(baseline,'PSC1_TRANSFORM_BASELINE is required; baseline parity cannot be skipped');
 assert.equal(run('git',['-C',baseline,'rev-parse','HEAD']).trim(),'cc13ebfabf6763703ee1ec75a663002a9134bc74');
 assert.equal(run('git',['-C',baseline,'status','--porcelain','--untracked-files=no']).trim(),'');
 const candidate=built.candidate,requestFile=path.join(cwd,'baseline-request.json');
 fs.writeFileSync(requestFile,JSON.stringify(['psc1-modular-pilot/2',candidate.requestId,
   candidate.sourceClosureDigest,input[0].kind,'checked',input.at(-1).module,input.map(s=>[s.module,s.text])]));
 const script=path.resolve('test/modular/TransformParity.lean'),pin=sha256(fs.readFileSync(script));
 const driver=process.env.PSC1_TRANSFORM_BASELINE_DRIVER,driverSource=process.env.PSC1_TRANSFORM_BASELINE_DRIVER_SOURCE;
 assert.ok(driver&&driverSource,'native baseline harness required');
 assert.equal(fs.realpathSync(driver),driver);assert.ok(fs.lstatSync(driver).isFile());
 assert.equal(sha256(fs.readFileSync(driverSource)),pin);
 const driverSha256=sha256(fs.readFileSync(driver));
 const directory=path.join(cwd,'baseline-process');
 const execution=JSON.parse(run('python3',[path.resolve('host-tools/process/bounded-process.py'),JSON.stringify({
   command:['/usr/bin/prlimit','--as=4294967296','--stack=8388608','--cpu=240','--',
     driver,requestFile],
   directory,timeoutMs:240000,maxBuffer:32*1024*1024
 })],{timeout:245000,cwd:baseline}));
 // Python and its bounded child inherit this explicit baseline cwd.
 assert.equal(execution.error,null,fs.readFileSync(path.join(directory,'tool.stderr.txt'),'utf8'));
 assert.equal(execution.status,0,fs.readFileSync(path.join(directory,'tool.stderr.txt'),'utf8'));
 const report=JSON.parse(fs.readFileSync(path.join(directory,'tool.stdout.txt'),'utf8'));
 assert.equal(report.leanVersion,'4.35.0');assert.equal(report.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
 for(const key of ['originalIr','specializedIr','transformedIr','admissions','referenceJs','referenceTs'])
   assert.deepEqual(report[key],candidate[key],'PSC1_TRANSFORM_BASELINE_'+key);
 assert.equal(sha256(fs.readFileSync(script)),pin);
 assert.equal(sha256(fs.readFileSync(driver)),driverSha256);
 assert.equal(sha256(fs.readFileSync(driverSource)),pin);
 assert.equal(run('git',['-C',baseline,'status','--porcelain','--untracked-files=no']).trim(),'');
 record(kind+'-baseline-transform-parity',{status:'passed',baselineCommit:'cc13ebfabf6763703ee1ec75a663002a9134bc74',driverSha256,
   originalIrSha256:sha256(JSON.stringify(report.originalIr)),specializedIrSha256:sha256(JSON.stringify(report.specializedIr)),
   fusedIrSha256:sha256(JSON.stringify(report.transformedIr)),execution});
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
  const kind=input[0].kind,out=path.resolve('dist/modular/'+(partitioned?'partitioned-':'extended-')+kind);
  const variants=Object.fromEntries((kind==='lean'?ps:sources).map(source=>[source.module,source]));
  const built=buildPilot({sources:input,out,profile,sourceVariants:variants,requestId:'extended-pack-'+kind});
  builds.push(built);
  const c=built.candidate,originAudit=audit(c);record(kind+'-origin-composition',{status:'passed',...originAudit});
  const cwd=install(built,'installed-'+kind);
  baselineParity(built,input,cwd,kind);
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
   assert.equal(meta.license,'Apache-2.0');assert.equal(meta.version,partitioned?'0.1.0-psc1-modular-pilot.2':'0.1.0-psc1-modular-pilot.1');
   assert.ok(Object.keys(meta.dependencies).every(name=>built.packages.some(p=>p.name===name)));
   for(const branch of ['.','./ts'])for(const key of ['types','import'])assert.ok(fs.statSync(path.join(root,meta.exports[branch][key])).isFile());
   const map=JSON.parse(fs.readFileSync(path.join(root,'dist/ts/index.mjs.map'))),text=fs.readFileSync(path.join(root,'src/ts/index.mts'),'utf8');
   assert.deepEqual(map.sourcesContent,[text]);
   const selected=partitioned?input.filter((_,i)=>c.partition.sourceToUnit[i+1]===index):index===0?[]:[input[index-1]];
   for(const original of selected)for(const source of [original,variants[original.module]])
     assert.equal(fs.readFileSync(path.join(root,'sources',(partitioned?source.module:source.module.split('.').at(-1))+'.'+source.kind),'utf8'),source.text);
  }
  record(kind+'-inventory-and-source-maps');
  const target=path.join(cwd,'node_modules/@proofscript/modular-pilot-ps-bridge-json/dist/js/index.mjs'),before=fs.readFileSync(target);
  refuse(cwd,kind+'-modified-json-module',()=>fs.appendFileSync(target,'\nthrow Error("executed");'),()=>fs.writeFileSync(target,before));
  const provenance=path.join(cwd,'node_modules/@proofscript/modular-pilot-ps-foundation-list/PROVENANCE.json'),old=fs.readFileSync(provenance);
  refuse(cwd,kind+'-modified-transform-provenance',()=>fs.writeFileSync(provenance,'{}'),()=>fs.writeFileSync(provenance,old));
  const installable=path.resolve('dist/modular/'+(partitioned?'installable-partitioned-':'installable-extended-')+kind);fs.mkdirSync(installable,{recursive:true});
  for(const item of [...built.packages,built.rootTar])fs.copyFileSync(path.join(built.directory,item.tarball),path.join(installable,item.tarball));
  fs.writeFileSync(path.join(installable,'SHA256SUMS'),[...built.packages,built.rootTar].map(p=>p.sha256+'  '+p.tarball).join('\n')+'\n');
  fs.writeFileSync(path.join(installable,'INSTALL.txt'),'Experimental compiler component graph. Install all matching tarballs together with npm install --offline --ignore-scripts <seven .tgz paths>.\nDefault proofscript distribution and whole modular self-hosting are separate.\n');
  result.profiles.push({kind,sourceClosureDigest:built.receipt.sourceClosureDigest,cohortSha256:built.cohortSha256,
    generation:built.generation,originAudit,execution:built.execution,admission:built.receipt,
    tarballs:[...built.packages,built.rootTar].map(({name,tarball,bytes,sha256})=>({name,tarball,bytes,sha256}))});
  if(kind==='lean'){
   const again=buildPilot({sources:input,out:path.resolve(partitioned?'dist/modular/partitioned-reproduction':'dist/modular/extended-reproduction'),profile:partitioned?'partitioned':'extended',
     sourceVariants:variants,requestId:'extended-pack-lean'});
   assert.deepEqual([...again.packages,again.rootTar].map(p=>p.sha256),[...built.packages,built.rootTar].map(p=>p.sha256));
   record(partitioned?'partitioned-exact-eight-tarball-reproduction':'extended-exact-seven-tarball-reproduction');
   const pointer=fs.readFileSync(path.join(out,'current.json'));
   assert.throws(()=>buildPilot({sources:input,out,profile:partitioned?'partitioned':'extended',sourceVariants:variants,requestId:'extended-transaction-fault',
     publicationFault:point=>{if(point==='before-commit')throw Error('extended-injected');}}),/extended-injected/);
   assert.deepEqual(fs.readFileSync(path.join(out,'current.json')),pointer);
   assert.equal(readPublication(out,'portable-file').generation,built.generation);record('extended-before-commit-retains-prior');
   let uncertain;
   try{buildPilot({sources:input,out,profile:partitioned?'partitioned':'extended',sourceVariants:variants,requestId:'extended-after-commit',
     publicationFault:point=>{if(point==='after-commit')throw Error('extended-after-commit');}});}
   catch(error){uncertain=error;}
   assert.equal(uncertain?.message,'PSC1_SERVICE_PUBLICATION_COMMITTED_DURABILITY_UNCERTAIN');
   assert.equal(uncertain.committedPublication.durability,'unconfirmed');
   const committed=readPublication(out,'portable-file');
   assert.equal(committed.generation,uncertain.committedPublication.generation);
   assert.notEqual(committed.generation,built.generation);
   const committedInput=JSON.parse(fs.readFileSync(path.join(committed.directory,'qualification-input.json')));
   const recovered=install({...committedInput,directory:committed.directory},'extended-committed');
   observe(recovered,'ts');record('extended-after-commit-reports-uncertainty');
  }
 }
 const mixed=install(builds[0],'cross-profile');
 const prior=readPublication(path.resolve('dist/modular/lean-cohort'),'portable-file');
 const priorInput=JSON.parse(fs.readFileSync(path.join(prior.directory,'qualification-input.json')));
 const legacy=install({...priorInput,directory:prior.directory},'legacy-source');
 const destination=path.join(mixed,'node_modules/@proofscript/modular-pilot-runtime');
 fs.rmSync(destination,{recursive:true});
 fs.cpSync(path.join(legacy,'node_modules/@proofscript/modular-pilot-runtime'),destination,{recursive:true});
 refuse(mixed,'cross-profile-package-mix',()=>{},()=>{});
 assert.notEqual(builds[0].receipt.sourceClosureDigest,builds[1].receipt.sourceClosureDigest);
 assert.deepEqual(builds[0].candidate.originalIr,builds[1].candidate.originalIr);
 assert.deepEqual(builds[0].candidate.specializedIr,builds[1].candidate.specializedIr);
 assert.deepEqual(builds[0].candidate.transformedIr,builds[1].candidate.transformedIr);
 assert.equal(builds[0].candidate.admissions,builds[1].candidate.admissions);record('cross-grammar-exact-core-and-transform-parity');
 assert.throws(()=>moduleProfile(profile,[{module:'P.A_B'},{module:'P.A.B'}]),/PSC1_MODULAR_PACKAGE_IDENTITY/);
 record('package-slug-collision',{status:'refused'});
 assert.throws(()=>compileSources({sources:[...sources,...sources],profile:'extended'}),/PSC1_MODULAR_SOURCE_SCOPE/);
 record('extended-source-bound',{status:'refused'});
 assert.deepEqual(result.cases.map(row=>row.name).sort(),contract.requiredCases);
 result.status='passed';fs.writeFileSync(partitioned?'dist/modular/partitioned-qualification.json':'dist/modular/extended-qualification.json',JSON.stringify(result,null,2)+'\n');
 console.log((partitioned?'PSC1_PARTITIONED_QUALIFIED ':'PSC1_EXTENDED_QUALIFIED ')+JSON.stringify(result));
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
