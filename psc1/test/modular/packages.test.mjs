// Qualification of actual generated compiler-component npm packages.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {buildPilot} from '../../host-tools/modular/build.mjs';
import {compileSources,run,sha256,packageNames,packageVersion,umbrellaName} from '../../host-tools/modular/compiler.mjs';
import {inspectModule} from '../../host-tools/modular/graph.mjs';
import {readPublication} from '../../host-tools/transactional-publication.mjs';
const root=process.cwd(),temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-modular-tests-'));
const observer=fs.readFileSync(new URL('./observe.mjs',import.meta.url),'utf8');
const producer=path.resolve('.lake/build/bin/psc1_modular_pilot');
const tsc=path.resolve('../node_modules/typescript/bin/tsc');
const result={schema:'psc1-modular-pilot-qualification/1',testedCommit:process.env.GITHUB_SHA,
 scope:'real compiler Foundation.Name plus dependent consumer; not a complete modular compiler or self-hosting qualification',
 cases:[],profiles:[],performanceTargetClaim:false,portableReleaseQualified:false};
const leanSources=[
 {module:'Ps.Foundation.Name',kind:'lean',text:fs.readFileSync('packages/foundation/src/Ps/Foundation/Name.lean','utf8')},
 {module:'Pilot.Consumer',kind:'lean',text:fs.readFileSync('test/modular/Consumer.lean','utf8')}
];
function record(name,value){result.cases.push({name,...value});console.log('PSC1_MODULAR_CASE '+name);}
function install(built,name){
 const cwd=path.join(temporary,name);fs.mkdirSync(cwd);
 fs.writeFileSync(path.join(cwd,'package.json'),JSON.stringify({name:'pilot-offline-consumer',private:true,type:'module'}));
 const archives=[...built.packages,built.rootTar].map(p=>path.join(built.directory,p.tarball));
 run('npm',['install','--offline','--ignore-scripts','--no-audit','--no-fund','--registry','http://127.0.0.1:9',
   '--cache',path.join(cwd,'empty-cache'),...archives],{cwd});
 fs.writeFileSync(path.join(cwd,'observe.mjs'),observer);
 return cwd;
}
function observe(cwd,variant,mode='installed',reference,runtime=process.execPath){
 return JSON.parse(run(runtime,['observe.mjs',mode,variant,...(reference?[reference]:[])],{cwd}));
}
function types(cwd,resolution){
 const source=[
 "import {loadPilot} from '@proofscript/modular-compiler-pilot';",
 "import {psNameDepth,psNameAppendStr} from '@proofscript/modular-pilot-names';",
 "import {pilotSeed} from '@proofscript/modular-pilot-consumer';",
 "import {psNameDepth as typedDepth} from '@proofscript/modular-pilot-names/ts';",
 "import {pilotSeed as typedSeed} from '@proofscript/modular-pilot-consumer/ts';",
 "const depth:bigint=psNameDepth(psNameAppendStr(pilotSeed,'name'));",
 "const typed:bigint=typedDepth(typedSeed);",
 "const js=await loadPilot();const ts=await loadPilot({variant:'ts'});",
 "const cross:bigint=ts.consumer.pilotDepth(ts.names.psNameAppendNum(ts.consumer.pilotSeed,2n));",
 "// @ts-expect-error the generated function needs a Name",
 "psNameDepth('wrong');",
 "// @ts-expect-error Nat uses bigint",
 "psNameAppendStr(pilotSeed,42);",
 "// @ts-expect-error JS structural data cannot be mixed with TS symbol data",
 "typedDepth(pilotSeed);",
 "// @ts-expect-error TS symbol data cannot be mixed with JS structural data",
 "psNameDepth(typedSeed);",
 "// @ts-expect-error variants are a closed selection",
 "await loadPilot({variant:'python'});"
 ].join('\n');
 fs.writeFileSync(path.join(cwd,'consumer.mts'),source);
 const config={compilerOptions:{strict:true,noEmit:true,skipLibCheck:false,target:'ES2022',
   module:resolution==='NodeNext'?'NodeNext':'ESNext',moduleResolution:resolution,
   types:[],lib:['ES2022','DOM']},files:['consumer.mts']};
 fs.writeFileSync(path.join(cwd,'tsconfig.json'),JSON.stringify(config));
 run(process.execPath,[tsc,'--project','tsconfig.json'],{cwd});
}
function refusedLoad(cwd,name,mutate,restore){
 try{
   mutate();
   const sentinel=path.join(cwd,'tampered-target-executed');
   const script="import{loadPilot}from '@proofscript/modular-compiler-pilot';try{await loadPilot();process.exitCode=2;}catch(e){if(!String(e).includes('PSC1_MODULAR_')&&!['ENOENT'].includes(e.code))throw e;console.log('refused');}";
   assert.equal(run(process.execPath,['--input-type=module','--eval',script],{cwd}).trim(),'refused');
   assert.equal(fs.existsSync(sentinel),false);
   record(name,{status:'refused-before-target-import'});
 }finally{restore();}
}
try{
 const psSources=leanSources.map((s,index)=>{
   const file=path.join(temporary,'translate-'+index+'.lean');fs.writeFileSync(file,s.text);
   return{...s,kind:'ps',text:run(producer,['--translate',file])};
 });
 const builds=[];
 for(const sources of [leanSources,psSources]){
   const grammar=sources[0].kind;
   const out=path.resolve('dist/modular',grammar+'-cohort');
   const variants=Object.fromEntries((grammar==='lean'?psSources:leanSources).map(s=>[s.module,s]));
   const built=buildPilot({sources,out,sourceVariants:variants,requestId:'modular-pack-'+grammar});
   builds.push(built);
   assert.equal(built.receipt.accepted,true);
   const installed=install(built,grammar+'-consumer');
   for(const resolution of ['NodeNext','Bundler']){types(installed,resolution);record(grammar+'-'+resolution,{status:'passed'});}
   const referenceJs=path.join(installed,'reference-js.mjs');fs.writeFileSync(referenceJs,built.candidate.referenceJs);
   const referenceTs=path.join(installed,'reference-ts.mts');fs.writeFileSync(referenceTs,built.candidate.referenceTs);
   const referenceOut=path.join(installed,'reference-out');
   run(process.execPath,[tsc,referenceTs,'--strict','--target','ES2022','--module','NodeNext',
     '--moduleResolution','NodeNext','--outDir',referenceOut,'--types','node'],{cwd:root});
   for(const variant of ['js','ts']){
     const reference=variant==='js'?referenceJs:path.join(referenceOut,'reference-ts.mjs');
     const expected=observe(installed,variant,'reference',reference);
     for(const runtime of [process.execPath,'bun']){
       const actual=observe(installed,variant,'installed',undefined,runtime);
       assert.deepEqual(actual.observations,expected.observations);
       record(grammar+'-'+variant+'-'+actual.runtime,{status:'passed',elapsedMs:actual.elapsedMs,observations:actual.observations.length});
     }
   }
   result.profiles.push({grammar,generation:built.generation,cohortSha256:built.cohortSha256,
     sourceClosureDigest:built.receipt.sourceClosureDigest,admission:built.receipt,execution:built.execution,
     tarballs:[...built.packages,built.rootTar].map(({name,tarball,bytes,sha256})=>({name,tarball,bytes,sha256}))});
   if(grammar==='lean'){
     const scope=path.join(installed,'node_modules','@proofscript');
     const pkg=path.join(scope,'modular-pilot-names'),target=path.join(pkg,'dist/js/index.mjs');
     const original=fs.readFileSync(target);
     refusedLoad(installed,'modified-generated-body',()=>fs.appendFileSync(target,"\nthrow Error('executed');\n"),
       ()=>fs.writeFileSync(target,original));
     const extra=path.join(pkg,'unexpected.mjs');
     refusedLoad(installed,'extra-module',()=>fs.writeFileSync(extra,'throw Error("executed");'),()=>fs.unlinkSync(extra));
     const extraDir=path.join(pkg,'unexpected-empty');
     refusedLoad(installed,'extra-empty-directory',()=>fs.mkdirSync(extraDir),()=>fs.rmdirSync(extraDir));
     refusedLoad(installed,'missing-module',()=>fs.renameSync(target,target+'.removed'),()=>fs.renameSync(target+'.removed',target));
     refusedLoad(installed,'symlink-module',()=>{
       fs.renameSync(target,target+'.original');fs.symlinkSync(target+'.original',target);
     },()=>{fs.unlinkSync(target);fs.renameSync(target+'.original',target);});
     const metadata=path.join(pkg,'package.json'),before=fs.readFileSync(metadata);
     refusedLoad(installed,'wrong-version',()=>fs.writeFileSync(metadata,JSON.stringify({...JSON.parse(before),version:'99.0.0'})),
       ()=>fs.writeFileSync(metadata,before));
     const cohort=path.join(scope,'modular-compiler-pilot','cohort.json'),old=fs.readFileSync(cohort);
     refusedLoad(installed,'forged-admission-metadata',()=>fs.writeFileSync(cohort,JSON.stringify({...JSON.parse(old),logicalAdmission:'accepted',sourceClosureDigest:'0'.repeat(64)})),
       ()=>fs.writeFileSync(cohort,old));
     const nested=path.join(scope,'modular-compiler-pilot','node_modules');
     refusedLoad(installed,'nested-runtime-copy',()=>{
       fs.mkdirSync(path.join(nested,'@proofscript'),{recursive:true});
       fs.cpSync(path.join(scope,'modular-pilot-runtime'),path.join(nested,'@proofscript','modular-pilot-runtime'),{recursive:true});
     },()=>fs.rmSync(nested,{recursive:true,force:true}));
     const pointer=fs.readFileSync(path.join(out,'current.json'));
     assert.throws(()=>buildPilot({sources,out,sourceVariants:variants,requestId:'modular-before-commit',
       publicationFault:point=>{if(point==='before-commit')throw Error('injected-before-commit');}}),/injected-before-commit/);
     assert.deepEqual(fs.readFileSync(path.join(out,'current.json')),pointer);
     assert.equal(readPublication(out,'portable-file').generation,built.generation);
     observe(installed,'js');record('cohort-before-commit-preserves-prior',{status:'passed'});
   }
 }
 assert.notEqual(builds[0].receipt.sourceClosureDigest,builds[1].receipt.sourceClosureDigest);
 // A same-version package from a different exact source cohort must be rejected.
 const mixed=install(builds[0],'mixed-cohort');
 const other=install(builds[1],'other-cohort');
 const runtimeDir=path.join(mixed,'node_modules/@proofscript/modular-pilot-runtime');
 fs.rmSync(runtimeDir,{recursive:true});fs.cpSync(path.join(other,'node_modules/@proofscript/modular-pilot-runtime'),runtimeDir,{recursive:true});
 refusedLoad(mixed,'same-version-wrong-source-cohort',()=>{},()=>{});
 const illTyped=leanSources.map(s=>({...s}));illTyped[1].text+="\ndef pilotBroken : Nat := \"not a Nat\"\n";
 assert.throws(()=>compileSources({sources:illTyped,requestId:'modular-invalid-source'}),/PSC1_MODULAR_CANDIDATE/);
 record('ill-typed-source',{status:'refused'});
 const missing=leanSources.map(s=>({...s}));missing[1].text=missing[1].text.replace('import Ps.Foundation.Name','import Missing.Compiler');
 assert.throws(()=>compileSources({sources:missing,requestId:'modular-missing-import'}),/PSC1_MODULAR_CANDIDATE/);
 record('missing-source-import',{status:'refused'});
 for(const source of ["export * from './compiler.mjs';","export {x} from './compiler.mjs';",
   "const x=await import('node:fs');","export const then=()=>{};","eval('code');","new Function('code');"]){
   assert.throws(()=>inspectModule(source),/PSC1_MODULAR_/);
 }
 record('facade-dynamic-authority-and-thenable-graphs',{status:'refused',count:6});
 result.status='passed';fs.mkdirSync('dist/modular',{recursive:true});
 fs.writeFileSync('dist/modular/qualification.json',JSON.stringify(result,null,2)+'\n');
 console.log('PSC1_MODULAR_QUALIFIED '+JSON.stringify(result));
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
