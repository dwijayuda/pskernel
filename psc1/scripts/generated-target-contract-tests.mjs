// Constructed data exercises host boundaries only; never grants qualification.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {sha,verifyArtifact,executeService} from '../host-tools/generated-target-tools.mjs';
import {createCompilerHostSession,compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
import {corpus,refusals,expectedObservations,rustObservations} from './generated-target-corpus.mjs';
assert.equal(corpus.length,5);assert.equal(refusals.length,5);
assert.deepEqual([...corpus,...refusals].map(c=>c.id).sort(),['lean-modules','ps-integer-unicode','ps-list-literal','lean-handler-pattern','lean-ordinary-loop','malformed-list','wrong-body','missing-import','checked-partial','verified'].sort());
assert.deepEqual(Object.keys(expectedObservations).sort(),corpus.map(c=>c.id).sort());
assert.deepEqual(Object.keys(rustObservations).sort(),corpus.map(c=>c.id).sort());
const sources=[{module:'Entry',kind:'lean',text:'def answer : Nat := 42\n'}];
for(const target of ['ts','rust']){
 const session=createCompilerHostSession({requestId:'negative',target,sources,canonicalAdmissions:'[]',checkerExecutable:'/must-not-execute'});
 assert.throws(()=>session.admit(JSON.stringify({protocol:'psc1-compiler-host/1',op:'admit',requestId:'negative',
  target:target==='ts'?'rust':'ts',sourceClosureDigest:compilerSourceClosureDigest(sources),admissions:'[]'})),/REQUEST_MISMATCH/);
}
const dir=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-target-boundary-'));
try{
 const source=path.join(dir,'module.js'),manifestFile=path.join(dir,'artifact.json');
 fs.writeFileSync(source,'export {};\n');
 fs.writeFileSync(path.join(dir,'module.ts'),'export {};\n');
 const m={schema:'psc1-generated-target-artifact/1',target:'ts',executable:'module.js',service:true,publicNames:[],
  sourceSha256:sha(fs.readFileSync(source)),
  files:['module.js','module.ts'].map(p=>({path:p,bytes:11,sha256:sha(fs.readFileSync(path.join(dir,p)))}))};
 fs.writeFileSync(manifestFile,JSON.stringify(m));const hash=sha(fs.readFileSync(manifestFile));
 assert.equal(verifyArtifact(manifestFile,hash).target,'ts');
 fs.writeFileSync(source,'export {x};\n');assert.throws(()=>verifyArtifact(manifestFile,hash));
 fs.writeFileSync(source,'export {};\n');fs.renameSync(source,path.join(dir,'real.js'));fs.symlinkSync('real.js',source);
 assert.throws(()=>verifyArtifact(manifestFile,hash));
 fs.unlinkSync(source);fs.renameSync(path.join(dir,'real.js'),source);
 fs.appendFileSync(manifestFile,' ');assert.throws(()=>verifyArtifact(manifestFile,hash),/MANIFEST_CHANGED/);
}finally{fs.rmSync(dir,{recursive:true,force:true});}
console.log('PSC1_GENERATED_TARGET_CONTRACT: corpus frozen; wrong target, changed artifact and symlink refused');

// A constructed refusal transport fixture proves invalid wire is forwarded unchanged.
// It supplies no compiler semantics, admission evidence or qualification.
const transport=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-target-wire-'));
try {
 const js='export function psCompilerTsServiceCandidate(input) { return JSON.stringify({status:"refused",input}); }\n';
 fs.writeFileSync(path.join(transport,'module.js'),js);
 fs.writeFileSync(path.join(transport,'module.ts'),'export {};\n');
 fs.writeFileSync(path.join(transport,'package.json'),'{"type":"module"}\n');
 const files=['module.js','module.ts','package.json'].map(p=>{
  const b=fs.readFileSync(path.join(transport,p));return {path:p,bytes:b.length,sha256:sha(b)};
 });
 const manifest={schema:'psc1-generated-target-artifact/1',target:'ts',executable:'module.js',
  service:true,publicNames:['psCompilerTsServiceCandidate'],sourceSha256:files.find(f=>f.path==='module.ts').sha256,files};
 const manifestFile=path.join(transport,'artifact.json');
 fs.writeFileSync(manifestFile,JSON.stringify(manifest));const hash=sha(fs.readFileSync(manifestFile));
 for(const [i,input] of ['malformed JSON','null','{}','["wrong-protocol","G2-self"]'].entries()) {
  const request=path.join(transport,'request-'+i+'.json'),output=path.join(transport,'response-'+i+'.json');
  fs.writeFileSync(request,input);
  await executeService(manifestFile,hash,request,output,'correctness-1800s');
  assert.deepEqual(JSON.parse(fs.readFileSync(output)),{status:'refused',input});
 }
 console.log('PSC1_GENERATED_TARGET_WIRE_REFUSAL: malformed wire forwarded unchanged');
} finally { fs.rmSync(transport,{recursive:true,force:true}); }
