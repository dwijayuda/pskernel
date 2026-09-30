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
const requiredEntries=[
  'provider/',
  'kernel/',
  'LEAN_LICENSE',
  'KERNEL_SOURCE_MANIFEST.json',
  'host/source-distribution.test.mjs',
];
for(const entry of requiredEntries){
  assert.ok(packageJson.files.includes(entry),`package files must include ${entry}`);
}
assert.equal(
  packageJson.scripts?.['verify:source'],
  'node host/source-distribution.test.mjs',
  'verify:source must point at the published source-distribution verifier',
);
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
  gitObjectSha('blob',license).toString('hex'),
  expectedLeanLicenseBlob,
  'LEAN_LICENSE must be byte-identical to the pinned Lean 4.34 license blob',
);
assert.equal(
  await gitFlatTreeSha(path.join(packageRoot,'kernel')),
  expectedKernelTree,
  'kernel/ must be byte-identical to the pinned Lean 4.34 src/kernel Git tree',
);
await readFile(path.join(packageRoot,'provider','PsKernelLean','Admission.lean'),'utf8');

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
  'kernel/type_checker.cpp',
  'kernel/environment.cpp',
  'provider/PsKernelLean/Admission.lean',
  'host/source-distribution.test.mjs',
]){
  assert.ok(packedFiles.has(file),`npm tarball missing ${file}`);
}

console.log('PSC2_LEAN_KERNEL_SOURCE_DISTRIBUTION: PASS');
