import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const scriptDir=path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot=path.resolve(scriptDir,'..');

const cli=JSON.parse(
  await readFile(path.join(selfhostRoot,'packages/cli/package.json'),'utf8'),
);
assert.equal(
  cli.optionalDependencies?.['@proofscript/pskernel-lean-wasm'],
  '4.34.0',
);

const psc=await readFile(
  path.join(selfhostRoot,'packages/cli/bin/psc.mjs'),
  'utf8',
);
assert.match(psc,/lean434-wasm/);

const generatedCheck=await readFile(
  path.join(scriptDir,'check-with-generated.mjs'),
  'utf8',
);
assert.match(generatedCheck,/await checkWithKernelProvider/);
assert.match(generatedCheck,/launcherPath/);

console.log('PSC2_KERNEL_PROVIDER_INTEGRATION_CONTRACT: PASS');
