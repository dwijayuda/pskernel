import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {
  loadLeanKernelPrebuiltManifest,
  supportedLeanKernelProviderTargets,
  verifyLeanKernelPrebuiltBinary,
} from './prebuilt.mjs';

const hostDir=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(hostDir,'..');
const workspaceRoot=path.resolve(packageRoot,'../..');
const manifestPath=path.join(packageRoot,'package.json');
const indexPath=path.join(packageRoot,'index.mjs');

const manifest=JSON.parse(await readFile(manifestPath,'utf8'));
assert.equal(manifest.name,'@proofscript/pskernel-lean');
assert.equal(manifest.version,'4.34.0');
assert.equal(manifest.type,'module');
assert.equal(manifest.private,false);
assert.equal(manifest.exports?.['.'],'./index.mjs');
assert.equal(manifest.exports?.['./node'],'./host/node-provider.mjs');
assert.equal(manifest.proofscript?.bootstrap,false);
assert.equal(manifest.proofscript?.portable,false);
assert.equal(manifest.proofscript?.role,'external-lean-kernel-provider');
assert.ok(manifest.files.includes('PREBUILT_MANIFEST.json'));
assert.ok(manifest.files.includes('prebuilt/'));

const prebuiltManifest=loadLeanKernelPrebuiltManifest({packageRoot});
assert.deepEqual(
  Object.keys(prebuiltManifest.targets),
  [...supportedLeanKernelProviderTargets],
  'committed prebuilt manifest must contain exactly the five supported targets',
);
for(const target of supportedLeanKernelProviderTargets){
  const binaryPath=path.resolve(packageRoot,prebuiltManifest.targets[target].path);
  verifyLeanKernelPrebuiltBinary({
    binaryPath,
    target,
    manifest:prebuiltManifest,
    packageRoot,
  });
}

const api=await import(pathToFileURL(indexPath).href);
assert.equal(api.leanKernelProviderVersion,'4.34.0');
assert.equal(
  api.leanKernelProviderCommit,
  '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
);
assert.equal(typeof api.checkCanonicalAdmissions,'function');
assert.equal(typeof api.defaultLeanKernelProviderBinary,'function');

const workspaceCheck=spawnSync(
  process.execPath,
  ['scripts/check-workspace.mjs'],
  {cwd:workspaceRoot,encoding:'utf8'},
);
assert.equal(workspaceCheck.status,0,workspaceCheck.stderr);
assert.match(workspaceCheck.stdout,/PSC1_WORKSPACE_SHAPE: PASS \(21 workspaces\)/u);

process.stdout.write('PSC2_LEAN_KERNEL_NPM_PACKAGE_TESTS: PASS\n');
process.stdout.write('PSC2_LEAN_KERNEL_COMMITTED_PREBUILT_DIGESTS: PASS\n');
