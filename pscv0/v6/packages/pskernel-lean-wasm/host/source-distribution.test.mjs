import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {readdir,readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const npm=process.platform==='win32'?'npm.cmd':'npm';
const expectedKernelTree='636837af92156cf17226e56106f08eb553bfb961';
const expectedLeanLicenseBlob='813da297567374691eaae7a88739dbbefd2afdfd';

function gitObjectSha(type,body){
  const payload=Buffer.isBuffer(body)?body:Buffer.from(body);
  return createHash('sha1')
    .update(Buffer.from(`${type} ${payload.length}\0`))
    .update(payload)
    .digest();
}


async function gitTreeSha(root){
  const entries=(await readdir(root,{withFileTypes:true}))
    .sort((a,b)=>Buffer.from(a.name).compare(Buffer.from(b.name)));
  const treeParts=[];
  for(const entry of entries){
    const entryPath=path.join(root,entry.name);
    if(entry.isFile()){
      treeParts.push(Buffer.from(`100644 ${entry.name}\0`));
      treeParts.push(gitObjectSha('blob',await readFile(entryPath)));
    }else if(entry.isDirectory()){
      treeParts.push(Buffer.from(`40000 ${entry.name}\0`));
      treeParts.push(Buffer.from(await gitTreeSha(entryPath),'hex'));
    }else{
      throw new Error(`unsupported source snapshot entry: ${entryPath}`);
    }
  }
  return gitObjectSha('tree',Buffer.concat(treeParts)).toString('hex');
}

async function gitFlatTreeSha(root){
  const entries=(await readdir(root,{withFileTypes:true}))
    .sort((a,b)=>Buffer.from(a.name).compare(Buffer.from(b.name)));
  const treeParts=[];
  for(const entry of entries){
    assert.equal(entry.isFile(),true,`kernel audit snapshot must stay flat: ${entry.name}`);
    const body=await readFile(path.join(root,entry.name));
    treeParts.push(Buffer.from(`100644 ${entry.name}\0`));
    treeParts.push(gitObjectSha('blob',body));
  }
  return gitObjectSha('tree',Buffer.concat(treeParts)).toString('hex');
}

const packageJson=JSON.parse(await readFile(path.join(packageRoot,'package.json'),'utf8'));
for(const entry of [
  'provider/',
  'kernel/',
  'source/',
  'scripts/',
  'patches/',
  'LEAN_LICENSE',
  'KERNEL_SOURCE_MANIFEST.json',
  'PREBUILT_WASM_MANIFEST.json',
  'PROOFSCRIPT_SOURCE_MANIFEST.json',
]){
  assert.ok(packageJson.files.includes(entry),`package files must include ${entry}`);
}
assert.equal(
  packageJson.scripts?.['build:wasm'],
  'bash scripts/build-wasm.sh && node scripts/write-prebuilt-manifest.mjs',
);
assert.equal(packageJson.scripts?.['build:kernel'],'npm run build:wasm');
assert.equal(packageJson.scripts?.['verify:source'],'node host/source-distribution.test.mjs');
assert.equal(packageJson.scripts?.['verify:prebuilt'],'node host/verify-prebuilt.mjs');
for(const hook of ['preinstall','install','postinstall']){
  assert.equal(packageJson.scripts?.[hook],undefined,`${hook} must not compile Lean or WebAssembly`);
}

const sourceManifest=JSON.parse(await readFile(path.join(packageRoot,'KERNEL_SOURCE_MANIFEST.json'),'utf8'));
assert.equal(sourceManifest.leanVersion,'4.34.0');
assert.equal(sourceManifest.leanCommit,'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
assert.equal(sourceManifest.upstreamSourcePath,'src/kernel');
assert.equal(sourceManifest.packageSourcePath,'kernel');
assert.equal(sourceManifest.sourceTreeSha,expectedKernelTree);
assert.equal(sourceManifest.license,'Apache-2.0');
assert.equal(sourceManifest.licenseFile,'LEAN_LICENSE');
assert.equal(sourceManifest.modified,false);

const license=await readFile(path.join(packageRoot,'LEAN_LICENSE'));
assert.equal(
  gitObjectSha('blob',license).toString('hex'),
  expectedLeanLicenseBlob,
  'LEAN_LICENSE must be byte-identical to the pinned Lean 4.34 license blob',
);
assert.equal(
  await gitFlatTreeSha(path.join(packageRoot,'kernel')),
  expectedKernelTree,
  'kernel/ must be byte-identical to the pinned Lean 4.34 src/kernel Git tree',
);
const proofscriptManifest=JSON.parse(
  await readFile(path.join(packageRoot,'PROOFSCRIPT_SOURCE_MANIFEST.json'),'utf8'),
);
assert.equal(proofscriptManifest.schemaVersion,1);
assert.equal(proofscriptManifest.packageName,'@proofscript/pskernel-lean-wasm');
assert.equal(proofscriptManifest.snapshotRoot,'source/proofscript');
assert.equal(proofscriptManifest.sourceTreeSha,'22f39d23220cc53b499640b5777e944a9aad5a97');
assert.equal(
  await gitTreeSha(path.join(packageRoot,'source','proofscript')),
  proofscriptManifest.sourceTreeSha,
  'WASM ProofScript source snapshot must match its recorded Git tree',
);
assert.equal(
  await gitTreeSha(path.join(packageRoot,'source','proofscript','provider')),
  proofscriptManifest.components.provider,
);
assert.equal(
  await gitTreeSha(path.join(packageRoot,'source','proofscript','wasm-provider')),
  proofscriptManifest.components['wasm-provider'],
);
await readFile(path.join(packageRoot,'provider','PsKernelLeanWasm','Api.lean'),'utf8');
await readFile(path.join(packageRoot,'source','proofscript','foundation','Ps','Foundation','Name.lean'),'utf8');
await readFile(path.join(packageRoot,'source','proofscript','provider','PsKernelLean','Admission.lean'),'utf8');
await readFile(path.join(packageRoot,'scripts','build-wasm.sh'),'utf8');
await readFile(path.join(packageRoot,'scripts','write-prebuilt-manifest.mjs'),'utf8');
await readFile(path.join(packageRoot,'host','prebuilt.mjs'),'utf8');
await readFile(path.join(packageRoot,'host','verify-prebuilt.mjs'),'utf8');
await readFile(path.join(packageRoot,'patches','lean4-4.34.0-emscripten-uv-stubs.patch'),'utf8');

const packed=spawnSync(npm,['pack','--json','--dry-run'],{
  cwd:packageRoot,
  encoding:'utf8',
  windowsHide:true,
});
assert.equal(packed.status,0,packed.stderr);
const report=JSON.parse(packed.stdout);
assert.equal(report.length,1);
const packedFiles=new Set(report[0].files.map(file=>file.path));
for(const file of [
  'LEAN_LICENSE',
  'KERNEL_SOURCE_MANIFEST.json',
  'PROOFSCRIPT_SOURCE_MANIFEST.json',
  'kernel/type_checker.cpp',
  'provider/PsKernelLeanWasm/Api.lean',
  'source/proofscript/foundation/Ps/Foundation/Name.lean',
  'source/proofscript/provider/PsKernelLean/Admission.lean',
  'scripts/build-wasm.sh',
  'scripts/apply-wasm-abi.mjs',
  'scripts/write-prebuilt-manifest.mjs',
  'host/prebuilt.mjs',
  'host/verify-prebuilt.mjs',
  'patches/lean4-4.34.0-emscripten-uv-stubs.patch',
]){
  assert.ok(packedFiles.has(file),`npm tarball missing ${file}`);
}

console.log('PSC2_LEAN_KERNEL_WASM_SOURCE_DISTRIBUTION: PASS');
