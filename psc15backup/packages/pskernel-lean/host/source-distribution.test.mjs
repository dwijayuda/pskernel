import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {readdir,readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const npmCommand=process.platform==='win32'?process.execPath:'npm';
const npmPrefix=process.platform==='win32'
  ? [path.join(process.env.APPDATA??'', 'npm/node_modules/npm/bin/npm-cli.js')]
  : [];
const expectedKernelTree='636837af92156cf17226e56106f08eb553bfb961';
const expectedLeanLicenseBlob='813da297567374691eaae7a88739dbbefd2afdfd';

function canonicalTextBytes(body){
  const payload=Buffer.isBuffer(body)?body:Buffer.from(body);
  return Buffer.from(payload.toString('utf8').replace(/\r\n/gu,'\n'),'utf8');
}

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
      treeParts.push(gitObjectSha('blob',canonicalTextBytes(await readFile(entryPath))));
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
    const body=canonicalTextBytes(await readFile(path.join(root,entry.name)));
    treeParts.push(Buffer.from(`100644 ${entry.name}\0`));
    treeParts.push(gitObjectSha('blob',body));
  }
  return gitObjectSha('tree',Buffer.concat(treeParts)).toString('hex');
}

const packageJson=JSON.parse(await readFile(path.join(packageRoot,'package.json'),'utf8'));
const requiredEntries=[
  'provider/',
  'kernel/',
  'LEAN_LICENSE',
  'KERNEL_SOURCE_MANIFEST.json',
  'host/source-distribution.test.mjs',
  'host/verify-prebuilt.mjs',
  'source/',
  'scripts/build-native.mjs',
  'scripts/build-native-slim.mjs',
  'scripts/native-slim-differential.test.mjs',
  'PROOFSCRIPT_SOURCE_MANIFEST.json',
  'lakefile.lean',
  'lean-toolchain',
];
for(const entry of requiredEntries){
  assert.ok(packageJson.files.includes(entry),`package files must include ${entry}`);
}
assert.equal(packageJson.scripts?.['build:kernel'],'node scripts/build-native.mjs');
assert.equal(packageJson.scripts?.['build:native'],'node scripts/build-native.mjs');
assert.equal(
  packageJson.scripts?.['verify:source'],
  'node host/source-distribution.test.mjs',
  'verify:source must point at the published source-distribution verifier',
);
assert.equal(packageJson.scripts?.['verify:prebuilt'],'node host/verify-prebuilt.mjs');
for(const hook of ['preinstall','install','postinstall']){
  assert.equal(packageJson.scripts?.[hook],undefined,`${hook} must not compile or mutate the provider package`);
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
  gitObjectSha('blob',canonicalTextBytes(license)).toString('hex'),
  expectedLeanLicenseBlob,
  'LEAN_LICENSE canonical LF content must match the pinned Lean 4.34 license blob',
);
assert.equal(
  await gitFlatTreeSha(path.join(packageRoot,'kernel')),
  expectedKernelTree,
  'kernel/ canonical LF content must match the pinned Lean 4.34 src/kernel Git tree',
);
const proofscriptManifest=JSON.parse(
  await readFile(path.join(packageRoot,'PROOFSCRIPT_SOURCE_MANIFEST.json'),'utf8'),
);
assert.equal(proofscriptManifest.schemaVersion,1);
assert.equal(proofscriptManifest.packageName,'@proofscript/pskernel-lean');
assert.equal(proofscriptManifest.snapshotRoot,'source/proofscript');
assert.equal(proofscriptManifest.sourceRevision,'1b21b2483df7e8de7542873c24eaff2501539b1b');
assert.equal(
  await gitTreeSha(path.join(packageRoot,'source','proofscript')),
  proofscriptManifest.sourceTreeSha,
  'ProofScript source snapshot must match its recorded Git tree',
);
assert.equal(
  await gitTreeSha(path.join(packageRoot,'provider')),
  proofscriptManifest.components.provider,
  'provider/ must match the frozen provider source tree',
);
assert.equal(
  await gitTreeSha(path.join(packageRoot,'source','proofscript','provider')),
  proofscriptManifest.components.provider,
  'source/proofscript/provider must match provider/',
);
await readFile(path.join(packageRoot,'provider','PsKernelLean','Admission.lean'),'utf8');
await readFile(path.join(packageRoot,'source','proofscript','foundation','Ps','Foundation','Name.lean'),'utf8');
await readFile(path.join(packageRoot,'source','proofscript','provider','PsKernelLean','Admission.lean'),'utf8');
await readFile(path.join(packageRoot,'scripts','build-native.mjs'),'utf8');
await readFile(path.join(packageRoot,'scripts','build-native-slim.mjs'),'utf8');
await readFile(path.join(packageRoot,'scripts','native-slim-differential.test.mjs'),'utf8');
await readFile(path.join(packageRoot,'host','verify-prebuilt.mjs'),'utf8');
await readFile(path.join(packageRoot,'lakefile.lean'),'utf8');
assert.equal((await readFile(path.join(packageRoot,'lean-toolchain'),'utf8')).trim(),'leanprover/lean4:v4.34.0');

const packed=spawnSync(npmCommand,[...npmPrefix,'pack','--json','--dry-run'],{
  cwd:packageRoot,
  encoding:'utf8',
  windowsHide:true,
});
assert.equal(packed.status,0,packed.stderr);
const rawReport=JSON.parse(packed.stdout);
const report=Array.isArray(rawReport)?rawReport:Object.values(rawReport);
assert.equal(report.length,1);
const packedFiles=new Set(report[0].files.map(file=>file.path));
for(const file of [
  'LEAN_LICENSE',
  'KERNEL_SOURCE_MANIFEST.json',
  'kernel/type_checker.cpp',
  'kernel/environment.cpp',
  'provider/PsKernelLean/Admission.lean',
  'source/proofscript/foundation/Ps/Foundation/Name.lean',
  'source/proofscript/provider/PsKernelLean/Admission.lean',
  'PROOFSCRIPT_SOURCE_MANIFEST.json',
  'scripts/build-native.mjs',
  'scripts/build-native-slim.mjs',
  'scripts/native-slim-differential.test.mjs',
  'host/source-distribution.test.mjs',
  'host/verify-prebuilt.mjs',
  'lakefile.lean',
  'lean-toolchain',
]){
  assert.ok(packedFiles.has(file),`npm tarball missing ${file}`);
}

console.log('PSC2_LEAN_KERNEL_SOURCE_DISTRIBUTION: PASS');
