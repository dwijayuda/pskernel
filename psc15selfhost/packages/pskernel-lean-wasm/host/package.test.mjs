import assert from 'node:assert/strict';
import {mkdtemp,readFile,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {checkCanonicalAdmissions,createKernel} from '../index.mjs';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const workspaceRoot=path.resolve(packageRoot,'../..');

const manifest=JSON.parse(await readFile(path.join(packageRoot,'package.json'),'utf8'));
assert.equal(manifest.name,'@proofscript/pskernel-lean-wasm');
assert.equal(manifest.version,'4.34.0');
assert.equal(manifest.type,'module');
assert.equal(manifest.private,false);
assert.equal(manifest.proofscript?.bootstrap,false);
assert.equal(manifest.proofscript?.portable,false);
assert.equal(manifest.proofscript?.role,'external-lean-kernel-provider-wasm');

const leanPin=JSON.parse(await readFile(path.join(packageRoot,'LEAN_SOURCE_PIN.json'),'utf8'));
assert.equal(leanPin.leanVersion,'4.34.0');
assert.equal(leanPin.leanCommit,'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
assert.equal(leanPin.protocol,'pskernel-lean/1');
assert.equal(leanPin.provider,'lean4-cpp');
assert.equal(leanPin.profile,'lean4.34-core');

const emscriptenPin=JSON.parse(await readFile(path.join(packageRoot,'EMSCRIPTEN_PIN.json'),'utf8'));
assert.equal(emscriptenPin.version,'6.0.9');
assert.notEqual(emscriptenPin.version,'latest');
assert.notEqual(emscriptenPin.version,'tot');

const rootIndex=await readFile(path.join(packageRoot,'index.mjs'),'utf8');
assert.match(rootIndex,/createKernel/);
assert.match(rootIndex,/checkCanonicalAdmissions/);

// Published package documentation is part of the npm contract. Keep the WASM
// assurance path explicit about exact pins, bootstrap exclusion, generated
// artifact names, and the public Node API instead of relying on native-provider
// documentation that has different distribution/build behavior.
const readme=await readFile(path.join(packageRoot,'README.md'),'utf8');
assert.match(readme,/@proofscript\/pskernel-lean-wasm/);
assert.match(readme,/Lean 4\.34\.0/);
assert.match(readme,/Emscripten 6\.0\.9/);
assert.match(readme,/not part of.*bootstrap/is);
assert.match(readme,/createKernel/);
assert.match(readme,/checkCanonicalAdmissions/);
assert.match(readme,/pskernel-lean\.cjs/);
assert.match(readme,/pskernel-lean\.wasm/);

const building=await readFile(path.join(packageRoot,'BUILDING.md'),'utf8');
assert.match(building,/6\.0\.9/);
assert.match(building,/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/);
assert.match(building,/scripts\/build-wasm\.sh/);
assert.match(building,/--health/);
assert.match(building,/--check/);
assert.match(building,/host Lean.*C emitter/is);

const closure=await readFile(path.join(workspaceRoot,'scripts/bootstrap-closure-contract-tests.mjs'),'utf8');
assert.match(closure,/pskernel-lean-wasm/);

const tempRoot=await mkdtemp(path.join(os.tmpdir(),'psc2-lean-wasm-host-'));
try{
  const launcherPath=path.join(tempRoot,'provider.cjs');
  await writeFile(launcherPath,`
const fs=require('node:fs');
const metadata={
  protocol:'pskernel-lean/1',
  provider:'lean4-cpp',
  leanVersion:'4.34.0',
  leanCommit:'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
};
const command=process.argv[2];
if(command==='--health'){
  process.stdout.write(JSON.stringify({...metadata,status:'ok'}));
  process.exit(0);
}
if(command==='--check'){
  const source=fs.readFileSync(0,'utf8');
  if(source.includes('"reject":true')){
    process.stdout.write(JSON.stringify({...metadata,accepted:false,errorKind:'kernel-rejection',declarationIndex:0}));
  }else{
    process.stdout.write(JSON.stringify({...metadata,accepted:true}));
  }
  process.exit(0);
}
process.exit(2);
`,'utf8');

  const kernel=await createKernel({launcherPath});
  assert.equal(kernel.metadata.protocol,'pskernel-lean/1');
  assert.equal(kernel.metadata.status,'ok');

  const accepted=await kernel.checkCanonicalAdmissions('{"reject":false}');
  assert.equal(accepted.accepted,true);
  assert.equal(accepted.provider,'lean4-cpp');

  const rejected=await checkCanonicalAdmissions('{"reject":true}',{launcherPath});
  assert.equal(rejected.accepted,false);
  assert.equal(rejected.errorKind,'kernel-rejection');
  assert.equal(rejected.declarationIndex,0);

  await assert.rejects(
    ()=>checkCanonicalAdmissions(null,{launcherPath}),
    /input must be a string/,
  );
  await assert.rejects(
    ()=>createKernel({launcherPath:path.join(tempRoot,'missing.cjs')}),
    /WASM kernel provider/,
  );
}finally{
  await rm(tempRoot,{recursive:true,force:true});
}

console.log('PSC2_LEAN_KERNEL_WASM_PACKAGE_CONTRACT: PASS');
