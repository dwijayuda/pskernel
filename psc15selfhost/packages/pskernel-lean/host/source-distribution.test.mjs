import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const npm=process.platform==='win32'?'npm.cmd':'npm';
const packageJson=JSON.parse(await readFile(path.join(packageRoot,'package.json'),'utf8'));
const requiredEntries=[
  'provider/',
  'kernel/',
  'LEAN_LICENSE',
  'KERNEL_SOURCE_MANIFEST.json',
];
for(const entry of requiredEntries){
  assert.ok(packageJson.files.includes(entry),`package files must include ${entry}`);
}

const sourceManifest=JSON.parse(await readFile(path.join(packageRoot,'KERNEL_SOURCE_MANIFEST.json'),'utf8'));
assert.equal(sourceManifest.leanVersion,'4.34.0');
assert.equal(sourceManifest.leanCommit,'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
assert.equal(sourceManifest.upstreamSourcePath,'src/kernel');
assert.equal(sourceManifest.packageSourcePath,'kernel');
assert.equal(sourceManifest.sourceTreeSha,'636837af92156cf17226e56106f08eb553bfb961');
assert.equal(sourceManifest.license,'Apache-2.0');
assert.equal(sourceManifest.licenseFile,'LEAN_LICENSE');
assert.equal(sourceManifest.modified,false);

const license=await readFile(path.join(packageRoot,'LEAN_LICENSE'),'utf8');
assert.match(license,/Apache License 2\.0/);
assert.match(license,/Version 2\.0, January 2004/);
await readFile(path.join(packageRoot,'kernel','type_checker.cpp'),'utf8');
await readFile(path.join(packageRoot,'kernel','environment.cpp'),'utf8');
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
]){
  assert.ok(packedFiles.has(file),`npm tarball missing ${file}`);
}

console.log('PSC2_LEAN_KERNEL_SOURCE_DISTRIBUTION: PASS');
