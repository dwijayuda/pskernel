// The retained real applications through the installed modular root and default Wasm kernel.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{spawnSync}from'node:child_process';import{pathToFileURL}from'node:url';
import{fixture}from'./psc1-modular-fixture.mjs';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
import{executeApplication}from'../../psc1/scripts/output-abi-applications.mjs';
const out=path.resolve('dist/modular-toolchain');
const input=JSON.parse(fs.readFileSync('../.github/scripts/psc1-preview-application-input.json'));
const archive=await readQualifiedArtifact(input.applicationReference,path.join(out,'application-reference'));
const tar=path.join(archive,'modular-checked-evidence.tar.gz'),preparedFile=path.join(out,'application-prepared.json');
const py='import tarfile,sys,pathlib\nwith tarfile.open(sys.argv[1]) as t:\n m=t.getmember("modular-checked/prepared.json")\n assert m.isfile() and 0<m.size<=33554432\n pathlib.Path(sys.argv[2]).write_bytes(t.extractfile(m).read())\n';
const unpack=spawnSync('python3',['-c',py,tar,preparedFile],{encoding:'utf8',timeout:120000});
assert.equal(unpack.error,undefined);assert.equal(unpack.status,0,unpack.stderr);
const prepared=JSON.parse(fs.readFileSync(preparedFile));
assert.equal(prepared.schema,'psc1-modular-application-preparation/1');
assert.equal(prepared.testedCommit,input.applicationReference.commit);
assert.equal(prepared.input.compilerSourceClosureDigest,'41eb40437e0df1722128c09c9b9da7cad0ccb1ad61371f23eb6bc2db4e9a1106');
assert.equal(prepared.records.length,8);
const f=fixture({consumers:true}),runtime=path.basename(f.runtime).startsWith('bun')?'bun':'node';
const records=[],report={schema:'psc1-modular-installed-applications/1',status:'running',
 testedCommit:process.env.GITHUB_SHA,inputCommit:input.sourceCommit,runtime,records,defaultKernel:'wasm',
 fullModularSelfHosting:false,applicationReference:input.applicationReference};
const save=()=>fs.writeFileSync(path.join(out,'installed-applications-'+runtime+'.json'),JSON.stringify(report,null,2)+'\n');
const buildFile=path.join(f.directory,'build-app.mjs');
fs.writeFileSync(buildFile,"import{build}from'proofscript';console.log(JSON.stringify(build(JSON.parse(process.argv[2]))));");
const runner=path.join(f.directory,'run-application.mjs');
const original=fs.readFileSync('scripts/practical-application-node.mjs','utf8');
const canonicalIo=path.resolve('host-tools/typed-io.mjs');
const installedIo=path.join(f.root,'node_modules/@proofscript/compiler/dist/host/host-tools/typed-io.mjs');
assert.equal(sha256(fs.readFileSync(installedIo)),sha256(fs.readFileSync(canonicalIo)));
const mappings=[["'../host-tools/typed-io.mjs'","'proofscript/io'"],
 ["'../host-tools/typed-io-wasm.mjs'",JSON.stringify(pathToFileURL(path.resolve('host-tools/typed-io-wasm.mjs')).href)]];
let mapped=original;
for(const[a,b]of mappings){assert.ok(mapped.includes(a));mapped=mapped.replace(a,b);}
let restored=mapped;for(const[a,b]of[...mappings].reverse())restored=restored.replace(b,a);
assert.equal(restored,original);fs.writeFileSync(runner,mapped);
const comparable=rows=>rows.map(({id,exitCode,stdoutSha256,outputSha256,preservedPrevious})=>({id,exitCode,stdoutSha256,outputSha256,preservedPrevious}));
try{
 for(const engine of['js','ts'])for(const expected of prepared.records){
  const fixture=prepared.reference.applications.find(row=>row.id===expected.id);assert.ok(fixture);
  const wire=expected.request;
  const options={engine,target:expected.target,entryModule:wire[5],assurance:wire[4],outputAbi:'io-dispatcher',
   sources:wire[6].map(([module,text])=>({module,kind:wire[3],text})),publicationProtocol:'portable-file',
   out:path.join(f.directory,'programs',engine,expected.id,expected.target)};
  const started=performance.now();
  const result=JSON.parse(f.ok(f.runtime,[...f.flags,buildFile,JSON.stringify(options)]));
  for(const key of['admissionsSha256','originalIrSha256','specializedIrSha256'])
   assert.equal(result.receipt[key],expected[key]);
  assert.equal(result.receipt.candidateSourceSha256,expected.sourceSha256);
  assert.equal(result.kernelProviders.join(','),'wasm');
  const contractFile=fixture.application==='cli-json'?'docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json':'docs/PSC1_COMPILER_APPLICATION_CONTRACT.json';
  const contractBytes=fs.readFileSync(contractFile);assert.equal(sha256(contractBytes),fixture.contractSha256);
  const cases=executeApplication({...fixture,contract:JSON.parse(contractBytes)},result.runtimeArtifact,
   path.join(f.directory,'cases',engine,expected.id,expected.target),runner);
  assert.deepEqual(comparable(cases),comparable(fixture.cases));
  records.push({engine,id:expected.id,target:expected.target,modules:fixture.modules,generation:result.generation,
   sourceClosureDigest:result.receipt.sourceClosureDigest,admissionsSha256:result.receipt.admissionsSha256,
   originalIrSha256:result.receipt.originalIrSha256,specializedIrSha256:result.receipt.specializedIrSha256,
   sourceSha256:result.receipt.candidateSourceSha256,elapsedMs:Math.round(performance.now()-started),cases});
  save();console.log('PSC1_MODULAR_INSTALLED_APPLICATION '+JSON.stringify({runtime,engine,id:expected.id,target:expected.target,cases:cases.length}));
 }
 assert.equal(records.length,16);assert.equal(records.reduce((n,r)=>n+r.cases.length,0),264);
 report.status='passed';
}catch(error){report.status='failed';report.failure=error.message;throw error;}
finally{save();console.log('PSC1_MODULAR_INSTALLED_APPLICATIONS '+JSON.stringify(report));fs.rmSync(f.directory,{recursive:true,force:true});}
