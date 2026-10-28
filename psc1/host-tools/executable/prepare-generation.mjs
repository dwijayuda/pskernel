// G1 preparation and differential emission. No modular self-host claim here.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {readOwnedCompilerSources} from '../compiler-source-inputs.mjs';
import {sha256,json,put,files,output} from './tools.mjs';
import {supervised,admitAndPackage,packGraph} from './generation-tools.mjs';
import {canonicalJson} from './quarantine.mjs';
for(const file of ['original-ir.json','specialized-ir.json','fused-ir.json','admissions.json','capture.json','modules.json']){
 const source=fs.readFileSync(path.join(output,file),'utf8');
 const suffix=file==='admissions.json'?'\n':'';
 assert.equal(canonicalJson(JSON.parse(source))+suffix,source,'PSC1_MODULAR_JSON_BYTE_ROUNDTRIP:'+file);
}
console.log('PSC1_MODULAR_JSON_BYTE_ROUNDTRIP_PASS all six candidate JSON files');
const base=path.resolve('dist/portable-modules');
assert.ok(!fs.existsSync(base));fs.mkdirSync(base,{recursive:true});
const sourceRows=readOwnedCompilerSources('Ps.CompilerUnified.Service').map(row=>{
 const physical=row.path.replaceAll(path.sep,'/').match(/^packages\/([^/]+)\/src\//)?.[1];
 assert.ok(physical);
 const owner=physical==='compiler-unified'?'@proofscript/compiler':
  JSON.parse(fs.readFileSync(path.join('packages',physical,'package.json'))).name;
 return {...row,package:owner};
});
const sources=JSON.parse(fs.readFileSync(path.join(output,'sources.json')));
const original=JSON.parse(fs.readFileSync(path.join(output,'request.json')));
const specifiers=JSON.parse(fs.readFileSync(path.join(output,'specifiers.json')));
const request=JSON.stringify(['psc1-modular-build/1',original,specifiers]);
assert.ok(Buffer.byteLength(request)<=33554432);
const requestFile=path.join(base,'compiler.request.json');put(requestFile,request);
const nativeFiles=files(output).filter(row=>/^((js|ts)\/unit-\d+\.(mjs|d\.mts|mts)|js-runtime\.mjs)$/.test(row.path));
const oracle=path.join(base,'native-reference');fs.mkdirSync(oracle);
const nativeOracleFiles=['reference.mjs','reference.mts'].map(file=>{
 const bytes=fs.readFileSync(path.join(output,file));put(path.join(oracle,file),bytes);
 return {path:'native-reference/'+file,bytes:bytes.length,sha256:sha256(bytes)};
});
const reference={
 nativeOracleFiles,
 sourceClosureDigest:original[2],
 identities:Object.fromEntries(['admissions.json','original-ir.json','specialized-ir.json','fused-ir.json']
  .map(file=>[file,sha256(fs.readFileSync(path.join(output,file)))])),
 capture:JSON.parse(fs.readFileSync(path.join(output,'capture.json'))),
 emission:JSON.parse(fs.readFileSync(path.join(output,'modules.json'))),
 emittedFiles:nativeFiles
};
const stage=path.join(base,'G1');
const nativeSeed=path.resolve('.lake/build/bin/psc1_portable_module_seed'),nativeSeedSha256=sha256(fs.readFileSync(nativeSeed));
const execution=supervised({label:'G1-native-portable',directory:base,native:true,
 command:[nativeSeed,requestFile,stage]});
assert.equal(sha256(fs.readFileSync(nativeSeed)),nativeSeedSha256);
const graph=admitAndPackage(stage,sourceRows,sources,reference,{label:'G1',compilerCommit:process.env.GITHUB_SHA});
const packages=packGraph(graph,path.join(stage,'tarballs'));
const input={schema:'psc1-portable-modular-generation-input/1',sourceCommit:process.env.GITHUB_SHA,
 sourceRows,sources,reference,requestFile:'compiler.request.json',g1:{manifest:'G1/manifest.json',
 manifestSha256:graph.manifestHash,root:'G1/candidate',packages}};
put(path.join(base,'input.json'),json(input));
const receipt={schema:'psc1-portable-modular-G1/1',status:'passed-native-reference-and-portable-generation',
 sourceCommit:process.env.GITHUB_SHA,sourceClosureDigest:reference.sourceClosureDigest,
 sourceModules:sources.length,units:graph.manifest.units.length,packages:packages.length,
 manifestSha256:graph.manifestHash,files:graph.manifest.files.length,
 bytes:graph.manifest.files.reduce((n,x)=>n+x.bytes,0),execution:execution.report,nativeSeedSha256,
 nativeOracleScope:'comparison-only; never imported by a generation producer',
 independentAdmission:graph.admitted,originalAndTransformedIrMatch:true,exactRenderedReferenceBytes:true,
 compilerSeconds:240,checkerSeconds:120,fullModularSelfHosting:false};
put(path.join(base,'g1-receipt.json'),json(receipt));
console.log('PSC1_PORTABLE_MODULAR_G1 '+JSON.stringify(receipt));

