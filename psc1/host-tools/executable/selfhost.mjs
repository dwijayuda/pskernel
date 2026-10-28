// Genuine modular generations. No native compiler or handwritten semantic path.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {readOwnedCompilerSources} from '../compiler-source-inputs.mjs';
import {verify} from './verify.mjs';
import {sha256,json,put,files} from './tools.mjs';
import {supervised,admitAndPackage,packGraph,exactGraphs,nodeFlags} from './generation-tools.mjs';
const [variant,profile='correctness-1800s']=process.argv.slice(2);
assert.ok(['js','ts'].includes(variant));
assert.ok(['performance-240s','correctness-1800s'].includes(profile));
const base=path.resolve('dist/portable-modules'),input=JSON.parse(fs.readFileSync(path.join(base,'input.json')));
assert.equal(input.schema,'psc1-portable-modular-generation-input/1');
const current=readOwnedCompilerSources('Ps.CompilerUnified.Service');
assert.deepEqual(current,input.sourceRows.map(({module,path,text})=>({module,path,text})),'PSC1_MODULAR_SOURCE_CHANGED');
const requestFile=path.join(base,input.requestFile),g1File=path.join(base,input.g1.manifest);
const g1Bytes=fs.readFileSync(g1File),g1Root=path.join(base,input.g1.root);
const g1={manifest:verify(g1Root,g1Bytes,input.g1.manifestSha256),manifestHash:input.g1.manifestSha256,root:g1Root};
assert.equal(g1.manifest.sourceClosureDigest,input.reference.sourceClosureDigest);
const directory=path.join(base,'selfhost-'+variant);assert.ok(!fs.existsSync(directory));fs.mkdirSync(directory);
const report={schema:'psc1-portable-modular-selfhost/1',testedCommit:process.env.GITHUB_SHA,
 sourceCommit:input.sourceCommit,sourceClosureDigest:input.reference.sourceClosureDigest,variant,profile,
 status:'running',fixedPoint:'not-run',performanceQualification:profile==='performance-240s'?'pending':'not-run',
 nativeFrontendCalls:0,generations:[],g1ManifestSha256:g1.manifestHash,
 independentKernel:'official-Lean-4.35.0',semanticFuel:'unchanged',memoryStackPolicies:'unchanged',
 compilerRequestPolicy:'G1/corpus/tools 240s; only G2-self/G3-self use the explicit correctness profile'};
const checkpoint=()=>fs.writeFileSync(path.join(directory,'qualification.json'),json(report));
checkpoint();
try{
 const bin=path.resolve('.lake/build/bin'),hidden=path.join(directory,'native-frontends-quarantined');
 fs.mkdirSync(hidden);const moved=[];
 for(const name of fs.readdirSync(bin)){
  if(name==='psc1_independent_checker')continue;
  const file=path.join(bin,name);assert.ok(fs.lstatSync(file).isFile());
  moved.push({name,sha256:sha256(fs.readFileSync(file))});
  fs.renameSync(file,path.join(hidden,name));
 }
 assert.ok(fs.existsSync(path.join(bin,'psc1_independent_checker')));
 assert.ok(!fs.existsSync(path.join(bin,'psc1_portable_module_seed')));
 report.quarantinedNativeExecutables=moved;checkpoint();
 let producer=g1;
 for(const generation of [2,3]){
  const stage=path.join(directory,'G'+generation),config=path.join(directory,'G'+generation+'.json');
  put(config,json({engine:{root:producer.root,manifestFile:path.join(path.dirname(producer.root),'manifest.json'),
   manifestSha256:producer.manifestHash,variant},requestFile,directory:stage}));
  const execution=supervised({label:'G'+generation+'-'+variant,directory,profile,request:'G'+generation+'-self',
   command:[process.execPath,...nodeFlags,path.resolve('host-tools/executable/generation-runner.mjs'),config]});
  const graph=admitAndPackage(stage,input.sourceRows,input.sources,input.reference,
   {label:variant+'-G'+generation,compilerCommit:input.sourceCommit});
  exactGraphs(g1,graph);exactGraphs(producer,graph);
  const packages=packGraph(graph,path.join(stage,'tarballs'));
  assert.deepEqual(packages,input.g1.packages,'PSC1_MODULAR_NPM_TARBALL_FIXED_POINT');
  report.generations.push({generation,execution:execution.report,independentAdmission:graph.admitted,
   manifestSha256:graph.manifestHash,packages,fullGraphByteIdentity:true,
   originalAndTransformedIrIdentity:true,renderedNativeReferenceIdentity:true,status:'generated-and-independently-admitted'});
  checkpoint();
  // Reuse retained real output execution, strict TS, offline npm and graph-negative bodies.
  const audit=spawnSync(process.execPath,[...nodeFlags,'host-tools/executable/qualify.mjs',stage],
   {stdio:'inherit'});
  assert.equal(audit.status,0,'PSC1_MODULAR_GENERATION_CORPUS_FAILED');
  for(const pkg of packages)
   assert.equal(sha256(fs.readFileSync(path.join(stage,'tarballs',pkg.filename))),pkg.sha256,
    'PSC1_MODULAR_REPACK_DIFFERENCE');
  const evidence=JSON.parse(fs.readFileSync(path.join(stage,'execution-receipt.json')));
  report.generations.at(-1).executionEvidence=evidence;
  report.generations.at(-1).status='qualified-generated-modular-compiler';
  checkpoint();producer=graph;
 }
 report.status='passed';report.fixedPoint='exact-G1-G2-G3-graph-files-and-npm-tarballs';
 report.correctnessQualification='qualified-finite-linux-scope';
 report.performanceQualification=profile==='performance-240s'?'qualified-240s':'not-run';
 checkpoint();console.log('PSC1_PORTABLE_MODULAR_SELFHOST '+JSON.stringify(report));
}catch(error){
 report.status='failed';report.error=String(error.stack||error);checkpoint();throw error;
}

