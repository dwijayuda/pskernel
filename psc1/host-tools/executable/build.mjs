// Production whole-compiler candidate build. Default .13 distribution and the
// deferred pilot are not invoked or replaced. Linux build tools are host-owned.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {readOwnedCompilerSources} from '../compiler-source-inputs.mjs';
import {compilerSourceClosureDigest,createCompilerHostSession} from '../compiler-host-protocol.mjs';
import {packageGraph} from './package.mjs';
import {verify} from './verify.mjs';
import {put,sha256,json,bounded,output} from './tools.mjs';

assert.equal(process.platform,'linux');
assert.ok(!fs.existsSync(output),'PSC1_EXECUTABLE_FRESH_OUTPUT_REQUIRED');
fs.mkdirSync(output,{recursive:true});
const rows=readOwnedCompilerSources('Ps.CompilerUnified.Service');
const sourceRows=rows.map(row=>{
 const owner=row.path.replaceAll(path.sep,'/').match(/^packages\/([^/]+)\/src\//)?.[1];
 assert.ok(owner);
 const packageName=owner==='compiler-unified'?'@proofscript/compiler':
  JSON.parse(fs.readFileSync(path.join('packages',owner,'package.json'))).name;
 assert.match(packageName,/^@proofscript\/[a-z0-9-]+$/);
 return {...row,package:packageName};
});
const sources=sourceRows.map(row=>({module:row.module,kind:'lean',text:row.text}));
const digest=compilerSourceClosureDigest(sources),requestId='production-executable-compiler-build';
const request=['psc1-compiler-service/1',requestId,digest,'lean','ordinary-checked',
 'Ps.CompilerUnified.Service',sources.map(s=>[s.module,s.text])];
const requestFile=path.join(output,'request.json'),specifiersFile=path.join(output,'specifiers.json');
put(requestFile,JSON.stringify(request));
const specifiers=['@proofscript/foundation/generated/runtime',
 ...sourceRows.map(row=>row.package+'/generated/'+row.module)];
put(specifiersFile,json(specifiers));put(path.join(output,'sources.json'),json(sources));
const producer=path.resolve('.lake/build/bin/psc1_executable_packages');
const checker=path.resolve('.lake/build/bin/psc1_independent_checker');
const pins=[producer,checker,path.resolve('host-tools/process/bounded-process.py'),'/usr/bin/prlimit'].map(file=>{
 assert.equal(fs.realpathSync(file),file);assert.ok(fs.lstatSync(file).isFile());return {file,sha256:sha256(fs.readFileSync(file))};
});
const pinCheck=()=>{for(const pin of pins)assert.equal(sha256(fs.readFileSync(pin.file)),pin.sha256);};
pinCheck();
const capture=bounded('capture',[producer,'capture',requestFile,output]);pinCheck();
const canonicalAdmissions=fs.readFileSync(path.join(output,'admissions.json'),'utf8');
const session=createCompilerHostSession({requestId,target:'js',sources,canonicalAdmissions,checkerExecutable:checker});
const started=performance.now();
const receipt=session.admit(JSON.stringify({protocol:'psc1-compiler-host/1',op:'admit',requestId,target:'js',
 sourceClosureDigest:digest,admissions:canonicalAdmissions}));
pinCheck();put(path.join(output,'admission-receipt.json'),json({...receipt,elapsedMs:Math.round(performance.now()-started)}));
const captured=JSON.parse(fs.readFileSync(path.join(output,'capture.json')));
assert.equal(captured.sourceClosureDigest,digest);assert.equal(captured.assurance,'ordinary-checked');
assert.equal(captured.leanVersion,'4.35.0');assert.equal(captured.leanCommit,receipt.checkerCommit);
assert.deepEqual(captured.sourceModules,sources.map(s=>s.module));
const emit=bounded('emit',[producer,'emit',output,specifiersFile,digest]);pinCheck();
const emission=JSON.parse(fs.readFileSync(path.join(output,'modules.json')));
assert.equal(emission.protocol,'psc1-executable-compiler/1');assert.equal(emission.sourceClosureDigest,digest);
assert.equal(emission.units.length,sources.length+1);assert.equal(emission.sourceToUnit.length,specifiers.length);
assert.equal(new Set(emission.sourceToUnit).size,specifiers.length);
const owned=emission.units.flatMap(u=>u.names);
assert.equal(owned.length,captured.counts[2]);assert.equal(new Set(owned).size,owned.length);
const packaged=packageGraph(emission,sourceRows,receipt,captured);
verify(packaged.root,packaged.manifestBytes,packaged.manifestHash);
// These failures are checked before any graph import or candidate execution.
const negative=[];
const rejected=(name,action)=>{assert.throws(action);negative.push(name);};
const sample=packaged.manifest.files.find(row=>row.path.endsWith('.mjs'));
const sampleFile=path.join(packaged.root,sample.path),sampleBytes=fs.readFileSync(sampleFile);
fs.writeFileSync(sampleFile,Buffer.concat([sampleBytes,Buffer.from('\n// changed')]));
rejected('altered-module',()=>verify(packaged.root,packaged.manifestBytes,packaged.manifestHash));
fs.writeFileSync(sampleFile,sampleBytes);
fs.renameSync(sampleFile,sampleFile+'.missing');
rejected('missing-module',()=>verify(packaged.root,packaged.manifestBytes,packaged.manifestHash));
fs.renameSync(sampleFile+'.missing',sampleFile);
const extra=path.join(packaged.root,'extra.mjs');fs.writeFileSync(extra,'export {};');
rejected('extra-module',()=>verify(packaged.root,packaged.manifestBytes,packaged.manifestHash));fs.unlinkSync(extra);
rejected('wrong-manifest-cohort',()=>verify(packaged.root,packaged.manifestBytes,'0'.repeat(64)));
for(const [name,change]of [
 ['duplicate-owner',m=>m.owners.push(m.owners[0])],
 ['unsafe-path',m=>m.files[0].path='../escape.mjs'],
 ['wrong-runtime-owner',m=>m.runtimeOwner='@proofscript/compiler'],
 ['wrong-checker',m=>m.checkerCommit='0'.repeat(40)]
]){
 const modified=JSON.parse(packaged.manifestBytes);change(modified);const bytes=Buffer.from(json(modified));
 rejected(name,()=>verify(packaged.root,bytes,sha256(bytes)));
}
verify(packaged.root,packaged.manifestBytes,packaged.manifestHash);pinCheck();
const summary={schema:'psc1-executable-production-build/1',testedCommit:process.env.GITHUB_SHA,
 sourceClosureDigest:digest,sourceModules:sources.length,compilerAssurance:captured.assurance,partialNames:captured.partialNames,counts:captured.counts,
 generatedUnits:emission.units.length,packages:packaged.manifest.packages.map(p=>p.name),
 computedInitializers:emission.units.flatMap(u=>u.computedInitializers).length,
 manifestSha256:packaged.manifestHash,logicalAdmission:receipt,
 originalIrSha256:sha256(fs.readFileSync(path.join(output,'original-ir.json'))),
 transformedIrSha256:sha256(fs.readFileSync(path.join(output,'fused-ir.json'))),
 capture:capture.report,emission:emit.report,negativeCases:negative,
 candidateFiles:packaged.manifest.files.length,
 candidateBytes:packaged.manifest.files.reduce((n,r)=>n+r.bytes,0),typescriptResourcesSha256:packaged.sdkDigest,
 claims:{wholeCompilerCapture:true,actualSourceOwnedBodies:true,strictOriginalAndTransformedIR:true,
 independentCanonicalCoreAdmission:true,strictTypeScript:true,compilerExecution:false,
 fullModularSelfHosting:false,rootUmbrellaPromotion:false,defaultDistributionChanged:false}};
put(path.join(output,'build-receipt.json'),json(summary));
console.log('PSC1_EXECUTABLE_PRODUCTION_BUILD '+JSON.stringify(summary));
