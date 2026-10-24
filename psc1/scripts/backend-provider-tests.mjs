// Exercise actual emit-only workers and the core transport in Linux CI.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {emitBackendProvider} from '../host-tools/backend-providers.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.join(root,'dist/backend-providers');
const sha=b=>createHash('sha256').update(b).digest('hex');
const run=(cmd,args,options={})=>{
 const r=spawnSync(cmd,args,{cwd:root,encoding:'utf8',timeout:120000,maxBuffer:64*1024*1024,...options});
 assert.equal(r.error,undefined,r.error?.message);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;
};
fs.mkdirSync(out,{recursive:true});
run(path.join(root,'.lake/build/bin/psc1_backend_provider_tests'),[path.join(out,'fixtures')]);
const core=path.join(root,'.lake/build/bin/psc1');
const id=JSON.parse(run(core,['--identity']));
assert.deepEqual(id.targets,['js','ts','rust','wasm-core','wasm-component']);
const coreSymbols=run('nm',['--defined-only',core]);
assert.doesNotMatch(coreSymbols,/initialize_Ps_BackendPython|initialize_Ps_BackendPhp|l_psPythonEmit|l_psPhpEmit/,
 'default executable must not link optional emitters');
const cases=[];
for(const target of ['python','php']){
 const binary=path.join(root,'.lake/build/bin/psc1_backend_'+target);
 const symbols=run('nm',['--defined-only',binary]);
 assert.doesNotMatch(symbols,/initialize_Ps_Compiler_Api|initialize_Ps_Elab_Term|initialize_PsKernelLean_|initialize_Ps_Host_DirectBackend/,
  'provider cannot contain source frontend/admission/publication host');
 assert.doesNotMatch(symbols,target==='python'?/initialize_Ps_BackendPhp/:/initialize_Ps_BackendPython/);
 const fixture=fs.readFileSync(path.join(out,'fixtures',target+'.request.json'));
 const expected=JSON.parse(fs.readFileSync(path.join(out,'fixtures',target+'.expected.json'),'utf8'));
 const stage=path.join(out,'wire-'+target);fs.mkdirSync(stage,{recursive:true});
 const requestFile=path.join(stage,'backend-request.json');fs.writeFileSync(requestFile,fixture);
 fs.writeFileSync(path.join(stage,'psc1-input.json'),'{}');
 const response=emitBackendProvider(stage,target,requestFile,path.join(root,'test/Main.ps'));
 expected.requestSha256=sha(fixture);assert.deepEqual(response,expected,'all provider fields equal retained in-process emitter');
 const provenance=JSON.parse(fs.readFileSync(path.join(stage,'psc1-input.json'),'utf8')).backendProvider;
 assert.equal(provenance.requestSha256,sha(fixture));assert.equal(provenance.publicationAuthority,'core-host');
 const malformed=path.join(stage,'malformed.json');fs.writeFileSync(malformed,'{"unexpected":true}');
 const bad=spawnSync(binary,['emit',malformed],{encoding:'utf8',timeout:10000,
  env:{...process.env,PSC1_BACKEND_REQUEST_SHA256:'0'.repeat(64)}});
 assert.notEqual(bad.status,0);assert.equal(bad.stdout,'');
 for(const syntax of ['lean','ps']){
  const source=path.join(out,'Input.'+syntax),output=path.join(out,syntax+(target==='python'?'.py':'.php'));
  fs.writeFileSync(source,'def answer : Nat := 42\n');
  run(core,['build',source,'--target',target,'--out',output]);
  const manifest=JSON.parse(fs.readFileSync(output+'.bundle.json','utf8'));
  assert.equal(manifest.logicalCheckerCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(manifest.backendProvider.target,target);assert.equal(manifest.backendProvider.candidateOnly,true);
  if(target==='python')run(process.env.PSC1_PYTHON||'python3',['-c',
   'import runpy,sys; assert runpy.run_path(sys.argv[1])["answer"]==42',output]);
  else run('php',['-r','$api=require $argv[1]; if(gmp_cmp($api["answer"],42)!==0)exit(1);',output]);
  const before=fs.readFileSync(output),held=binary+'.held';
  fs.renameSync(binary,held);
  try{
   const missing=spawnSync(core,['build',source,'--target',target,'--out',output],
    {cwd:root,encoding:'utf8',timeout:120000});
   assert.notEqual(missing.status,0);assert.match(missing.stderr,/PSC1_BACKEND_PROVIDER_MISSING/);
   assert.deepEqual(fs.readFileSync(output),before,'absent provider preserves previous output');
  }finally{fs.renameSync(held,binary);}
  cases.push({target,syntax,passed:true,admission:manifest.logicalCheckerCommit,requestSha256:manifest.backendProvider.requestSha256});
 }
}
const receipt={schema:'psc1-backend-provider-tests/1',testedCommit:process.env.GITHUB_SHA||null,
 defaultTargets:id.targets,defaultBinaryExcludesOptionalEmitters:true,providersExcludeFrontendCheckerAndPublisher:true,
 retainedPayloadsExact:true,malformedWorkerRefused:true,missingProviderPreservesOutput:true,cases};
fs.writeFileSync(path.join(out,'qualification.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_BACKEND_PROVIDERS: '+JSON.stringify(receipt));
