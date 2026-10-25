// Recheck the exact frozen compiler graph shared by the four qualified engines.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createIndependentKernelToolchain} from '../host-tools/kernel-toolchain.mjs';import {readQualifiedArtifact,sha256} from './kernel435-qualified-artifact.mjs';
const input=JSON.parse(fs.readFileSync('scripts/kernel435-frozen-compiler-input.json','utf8')),archive=await readQualifiedArtifact(input,'dist/kernel435-frozen-input'),root=path.resolve(process.argv[2]),expected='4a43d82487eb09e6efcac248d6db211e9c2854bd2a9e04a9202affce6bdd3e39';let canonical,qualified=false;
function findStrings(value){
 const todo=[value];while(todo.length){const next=todo.pop();if(!next||typeof next!=='object')continue;
  for(const [key,v]of Object.entries(next)){
   if(key==='admissions'&&typeof v==='string'&&sha256(v)===expected)canonical=v;
   else if(v&&typeof v==='object')todo.push(v);
  }
 }
}
function visit(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const file=path.join(dir,e.name);if(e.isDirectory())visit(file);else if(e.isFile()&&e.name.endsWith('.json')){const st=fs.statSync(file);if(st.size>128*1024*1024)continue;const bytes=fs.readFileSync(file);if(sha256(bytes)===expected)canonical=bytes.toString('utf8');let data;try{data=JSON.parse(bytes.toString('utf8'));}catch{continue;}
 if(data.schema==='psc1-generated-target-qualification/1'&&data.target==='rust'&&data.status==='passed'&&data.mode==='--self-host'&&data.sourceClosureDigest==='07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af'&&data.testedCommit===input.commit)qualified=true;
 findStrings(data);
 }}}
visit(archive);assert.equal(qualified,true,'frozen genuine self-host qualification missing');assert.equal(typeof canonical,'string','exact admitted compiler graph missing');assert.equal(sha256(canonical),expected);
const checker=await createIndependentKernelToolchain({root,provider:'both'}),start=Date.now(),result=await checker.checkCanonicalAdmissions(canonical);assert.equal(result.accepted,true);assert.equal(result.agreement,true);assert.equal(result.admissionsSha256,expected);
const receipt={schema:'psc1-kernel435-frozen-compiler-admission/1',sourceCommit:process.env.GITHUB_SHA,status:'passed',compilerSourceClosureDigest:'07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af',admissionsSha256:expected,qualifiedInput:input,providers:['native','wasm'],wasmMemoryModel:'linear',elapsedMs:Date.now()-start,checkerRequestLimitMs:120000,fullGenerationReplayed:false,scope:'exact frozen admitted graph shared across independently qualified JS/TS/Rust/Wasm chains; independent logical rechecking only'};
fs.mkdirSync('dist/kernel435-core-installed',{recursive:true});fs.writeFileSync('dist/kernel435-core-installed/frozen-compiler-admission.json',JSON.stringify(receipt,null,2)+'\n');console.log('PSC1_KERNEL435_FROZEN_COMPILER: '+JSON.stringify(receipt));
