// Actual installed G3 executors, real official kernel, strict target consumers.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';
import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';
const out=path.resolve('dist/slim-universal'),assembly=JSON.parse(fs.readFileSync(path.join(out,'package-receipt.json')));
const work=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-checked-publication-'));
fs.writeFileSync(path.join(work,'package.json'),'{"type":"module","private":true}');
const npm=path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js');
const env={...process.env,PATH:path.dirname(process.execPath)};
for(const key of Object.keys(env))if(key==='NODE_OPTIONS'||key.startsWith('PSC1_')||key==='LEAN_PATH'||key==='ELAN_TOOLCHAIN'||key==='PSC_LEAN_KERNEL_PROVIDER_BIN')delete env[key];
const tarballs=path.join(out,'tarballs');
const packages=[assembly.tarball,...['rust','wasm-core','nativeKernel'].map(k=>assembly.input.packages[k].tarball),assembly.targetConsumers.ts.tarball];
const install=spawnSync(process.execPath,[npm,'install','--prefix',work,'--cache',path.join(work,'cache'),'--offline','--registry','http://127.0.0.1:9','--ignore-scripts','--no-audit','--no-fund',...packages.map(p=>path.join(tarballs,p))],{cwd:work,env,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
assert.equal(install.status,0,install.stdout+install.stderr);
const consumer=path.join(work,'consumer.mjs'),output=path.join(out,'checked-publication.json');
fs.writeFileSync(consumer,`import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
import {build,compile,readPublication,getCompilerMetadata} from 'proofscript';
const records=[],negatives=[];
const source=(kind,n)=>({sources:[{module:'Entry',kind,text:'def answer : Nat := '+n+'\\n'}],entryModule:'Entry'});
for(const engine of ['js','ts','rust','wasm-core'])for(const kind of ['lean','ps'])for(const target of ['js','ts','wasm-core']) {
 const options={...source(kind,42),engine,target,publicationProtocol:'portable-file',out:path.resolve('stores',engine,kind,target)};
 const result=build(options);assert.equal(result.logicalAdmission,'accepted');assert.equal(result.target,target);assert.equal(result.durability,'confirmed');assert.deepEqual(result.kernelProviders,['wasm']);
 const current=readPublication(options);assert.equal(current.generation,result.generation);assert.equal(current.target,result.artifact);assert.equal(fs.existsSync(path.join(options.out,'current')),false);
 let api=await import(pathToFileURL(result.runtimeArtifact).href);if(target==='wasm-core')api=api.default;assert.equal(api.answer,42n);
 const next=build({...options,...source(kind,43)});assert.notEqual(next.generation,result.generation);let old=await import(pathToFileURL(result.runtimeArtifact).href);if(target==='wasm-core')old=old.default;assert.equal(old.answer,42n,'immutable reader');
 const prior=readPublication(options).generation;
 for(const changed of [{assurance:'verified'},{target:'php'},{publicationProtocol:'arbitrary'},{sources:[{module:'Entry',kind,text:'def answer : Bool := 42\\n'}]}]) {
  assert.throws(()=>build({...options,...changed}));assert.equal(readPublication(options).generation,prior);negatives.push({engine,kind,target,priorPreserved:true});
 }
 records.push({engine,kind,target,generation:result.generation,logicalAdmission:result.logicalAdmission,consumer:result.receipt.targetArtifact.consumer,immutableReader:true});
 console.log('PSC1_CHECKED_TARGET_CASE: '+JSON.stringify(records.at(-1)));
}
const options={...source('lean',42),target:'ts',out:path.resolve('sdk-negative'),publicationProtocol:'portable-file'};
build(options);const prior=readPublication(options).generation;
const sdk=path.resolve('node_modules/typescript'),saved=sdk+'.saved';fs.renameSync(sdk,saved);
try{assert.throws(()=>build(options),/OPTIONAL_PACKAGE_MISSING/);}finally{fs.renameSync(saved,sdk);}
assert.equal(readPublication(options).generation,prior);negatives.push({id:'missing-ts-sdk',priorPreserved:true});
const file=path.join(sdk,'bin/tsc'),bytes=fs.readFileSync(file);fs.appendFileSync(file,'\\n');
try{assert.throws(()=>build(options),/IDENTITY|RESOURCE|CHANGED/);}finally{fs.writeFileSync(file,bytes);}
assert.equal(readPublication(options).generation,prior);negatives.push({id:'corrupt-ts-sdk',priorPreserved:true});
assert.equal(records.length,24);assert.equal(negatives.length,98);
fs.writeFileSync(${JSON.stringify(output)},JSON.stringify({schema:'psc1-installed-checked-publication/1',testedCommit:process.env.GITHUB_SHA,status:'passed',platform:process.platform,compilerSourceClosureDigest:getCompilerMetadata().compilerSourceClosureDigest,records,negatives,nonLinuxQualification:'not-run',rustOutput:'consumer-not-yet-integrated'},null,2)+'\\n');
console.log('PSC1_INSTALLED_CHECKED_PUBLICATION: PASS '+JSON.stringify({cases:records.length,negatives:negatives.length}));
`);
const result=spawnSync(process.execPath,[consumer],{cwd:work,env,encoding:'utf8',timeout:1500000,maxBuffer:32*1024*1024});
console.log(result.stdout);assert.equal(result.error,undefined,String(result.error));assert.equal(result.status,0,result.stderr);
