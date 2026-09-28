import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';

const rootManifest=JSON.parse(
  await readFile(new URL('../package.json',import.meta.url),'utf8'),
);

assert.equal(
  rootManifest.dependencies?.['@proofscript/pskernel-lean'],
  'file:packages/pskernel-lean',
);

const provider=await import('@proofscript/pskernel-lean');
assert.equal(provider.leanKernelProviderVersion,'4.34.0');
assert.equal(
  provider.leanKernelProviderCommit,
  '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
);
assert.equal(typeof provider.checkCanonicalAdmissions,'function');

process.stdout.write('PSC2_LEAN_KERNEL_NPM_CONSUMER_TESTS: PASS\n');
