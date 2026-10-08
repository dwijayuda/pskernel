import assert from 'node:assert/strict';
import {existsSync} from 'node:fs';
import {copyFile,mkdtemp,mkdir,readFile,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const temp=await mkdtemp(path.join(os.tmpdir(),'psc2-wasm-prebuilt-api-'));

// This is a host/integrity regression, NOT a Lean/WASM semantic test. Use a
// temporary package and launcher so no checked-in/generated artifact changes.
try{
  await mkdir(path.join(temp,'host'));
  await mkdir(path.join(temp,'wasm'));
  await copyFile(path.join(packageRoot,'index.mjs'),path.join(temp,'index.mjs'));
  await copyFile(path.join(here,'prebuilt.mjs'),path.join(temp,'host/prebuilt.mjs'));
  const {createKernel,checkCanonicalAdmissions}=await import(
    pathToFileURL(path.join(temp,'index.mjs')).href,
  );
  const {createWasmPrebuiltManifest}=await import(
    pathToFileURL(path.join(temp,'host/prebuilt.mjs')).href,
  );
  const marker=path.join(temp,'invocations.txt');
  const launcherPath=path.join(temp,'wasm/pskernel-lean.cjs');
  const wasmPath=path.join(temp,'wasm/pskernel-lean.wasm');
  const manifestPath=path.join(temp,'PREBUILT_WASM_MANIFEST.json');
  const identity={
    profile:'lean4.34-core',
    protocol:'pskernel-lean/1',provider:'lean4-cpp',leanVersion:'4.34.0',
    leanCommit:'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  };
  const launcher=`const fs=require('node:fs');
fs.appendFileSync(${JSON.stringify(marker)},process.argv[2]+'\\n');
console.log(JSON.stringify({...${JSON.stringify(identity)},status:'ok',accepted:true}));
`;
  const wasm=Buffer.from([0,97,115,109,1,0,0,0]);
  await writeFile(launcherPath,launcher);
  await writeFile(wasmPath,wasm);

  const defaultOptions=[
    ['omitted',undefined],
    ['empty',{}],
    ['undefined launcher',{launcherPath:undefined}],
    ['explicit bundled launcher',{launcherPath}],
    ['inherited undefined launcher',Object.create({launcherPath:undefined})],
    ['Node override only',{nodePath:process.execPath}],
    ['buffer override only',{maxBuffer:1024*1024}],
  ];
  for(const [label,options] of defaultOptions){
    await assert.rejects(createKernel(options),/failed to load Lean WASM prebuilt manifest/,
      `${label}: health must verify the bundled manifest before invocation`);
    await assert.rejects(checkCanonicalAdmissions('{}',options),
      /failed to load Lean WASM prebuilt manifest/,
      `${label}: checks must verify the bundled manifest before invocation`);
    assert.equal(existsSync(marker),false,`${label}: must fail before spawning the launcher`);
  }

  const manifest=createWasmPrebuiltManifest({
    packageRoot:temp,sourceCommit:'0123456789abcdef0123456789abcdef01234567',
  });
  const saveManifest=value=>writeFile(manifestPath,JSON.stringify(value)+'\n');
  await saveManifest(manifest);
  for(const [,options] of defaultOptions){
    const kernel=await createKernel(options);
    assert.equal(kernel.metadata.status,'ok');
    assert.equal((await kernel.checkCanonicalAdmissions('{}')).accepted,true);
    assert.equal((await checkCanonicalAdmissions('{}',options)).accepted,true);
  }
  const kernel=await createKernel({launcherPath:undefined});
  await rm(marker,{force:true});

  // The created handle must not cache away per-invocation integrity checking.
  await writeFile(wasmPath,Buffer.from([0,97,115,109,1,0,0,1]));
  for(const [,options] of defaultOptions){
    await assert.rejects(createKernel(options),/digest mismatch/);
    await assert.rejects(checkCanonicalAdmissions('{}',options),/digest mismatch/);
  }
  await assert.rejects(kernel.checkCanonicalAdmissions('{}'),/digest mismatch/);
  assert.equal(existsSync(marker),false,'tampered bytes must fail before invocation');
  await writeFile(wasmPath,wasm);

  for(const [key,value] of Object.entries({
    schemaVersion:2,packageName:'other',packageVersion:'0',protocol:'other',
    provider:'other',leanVersion:'0',leanCommit:'bad',emscriptenVersion:'0',
    sourceCommit:'',
  })){
    await saveManifest({...manifest,[key]:value});
    await assert.rejects(createKernel({launcherPath:undefined}),/manifest .*mismatch|sourceCommit is missing/);
  }
  await saveManifest({...manifest,artifacts:{...manifest.artifacts,
    wasm:{...manifest.artifacts.wasm,path:'../outside.wasm'},
  }});
  await assert.rejects(createKernel(),/path mismatch/);
  await saveManifest(manifest);
  await writeFile(wasmPath,Buffer.concat([wasm,Buffer.from([0])]));
  await assert.rejects(createKernel(),/size mismatch/);
  await writeFile(wasmPath,wasm);
  await writeFile(launcherPath,launcher+'// changed\n');
  await assert.rejects(createKernel(),/size mismatch/);
  assert.equal(existsSync(marker),false,'invalid artifacts/metadata must not run');

  // A genuinely external development launcher remains an intentional override;
  // no bundled manifest is required for it, but provider identity still is.
  await rm(manifestPath,{force:true});
  const external=path.join(temp,'external.cjs');
  await writeFile(external,launcher);
  assert.equal((await createKernel({launcherPath:external})).metadata.status,'ok');
  assert.equal((await checkCanonicalAdmissions('{}',{launcherPath:external})).accepted,true);
  assert.equal((await readFile(marker,'utf8')).trim().split('\n').length,2);
  await writeFile(external,`console.log(JSON.stringify(${JSON.stringify({...identity,protocol:'wrong',status:'ok'})}));\n`);
  await assert.rejects(createKernel({launcherPath:external}),/protocol mismatch/);
  console.log('PSC2_LEAN_KERNEL_WASM_PREBUILT_API_INTEGRITY: PASS (host mocks only; defaults, tampering, metadata, intentional override)');
}finally{
  await rm(temp,{recursive:true,force:true});
}
