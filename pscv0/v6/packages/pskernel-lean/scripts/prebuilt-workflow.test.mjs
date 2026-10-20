import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const scriptDir=path.dirname(fileURLToPath(import.meta.url));
const repoRoot=path.resolve(scriptDir,'../../../..');
const workflowPath=path.join(
  repoRoot,
  '.github',
  'workflows',
  'psc2-lean-kernel-prebuilt.yml',
);

let workflow;
try{
  workflow=await readFile(workflowPath,'utf8');
}catch(cause){
  if(cause?.code==='ENOENT'){
    assert.fail('PSC2 Lean kernel prebuilt workflow is missing');
  }
  throw cause;
}

assert.match(workflow,/^on:\s*\n\s{2}workflow_dispatch:\s*$/mu);
assert.doesNotMatch(workflow,/^\s{2}(push|pull_request|schedule):/mu);
assert.match(workflow,/permissions:\s*\n\s{2}contents:\s*read\s*\n\s*jobs:/mu);

const expectedPairs=[
  ['ubuntu-24.04','linux-x64'],
  ['ubuntu-24.04-arm','linux-arm64'],
  ['macos-15-intel','darwin-x64'],
  ['macos-15','darwin-arm64'],
  ['windows-2025','win32-x64'],
];
for(const [runner,target] of expectedPairs){
  const escapedRunner=runner.replace(/[.*+?^${}()|[\]\\]/gu,'\\$&');
  const escapedTarget=target.replace(/[.*+?^${}()|[\]\\]/gu,'\\$&');
  assert.match(
    workflow,
    new RegExp(
      `-\\s+runner:\\s*${escapedRunner}\\s+target:\\s*${escapedTarget}`,
      'u',
    ),
    `missing native matrix pair ${runner} -> ${target}`,
  );
}

const literalTargets=[...workflow.matchAll(/^\s+target:\s+([a-z0-9-]+)\s*$/gmu)]
  .map(match=>match[1]);
assert.deepEqual(
  literalTargets.sort(),
  expectedPairs.map(([,target])=>target).sort(),
  'prebuilt workflow must contain exactly the five supported native targets',
);

assert.match(workflow,/^\s{2}build-native:\s*$/mu);
assert.match(workflow,/uses:\s*leanprover\/lean-action@v1/u);
assert.match(workflow,/lake-package-directory:\s*psc15selfhost/u);
assert.match(workflow,/auto-config:\s*false/u);
assert.match(workflow,/build:\s*false/u);
assert.match(workflow,/test:\s*false/u);
assert.match(workflow,/lint:\s*false/u);
assert.match(workflow,/uses:\s*actions\/setup-node@v4/u);
assert.match(workflow,/node-version:\s*22/u);
assert.match(workflow,/stage-native-prebuilt\.mjs/u);
assert.match(workflow,/uses:\s*actions\/upload-artifact@v4/u);

const writes=workflow.match(/contents:\s*write/gu)??[];
assert.equal(writes.length,1,'only one job may receive contents: write');
const assembleIndex=workflow.search(/^\s{2}assemble:\s*$/mu);
assert.notEqual(assembleIndex,-1,'assembly job is missing');
const assembleBlock=workflow.slice(assembleIndex);
assert.match(assembleBlock,/permissions:\s*\n\s{6}contents:\s*write/u);
assert.match(assembleBlock,/uses:\s*actions\/download-artifact@v4/u);
assert.match(assembleBlock,/assemble-prebuilt\.mjs/u);
assert.match(assembleBlock,/npm pack/u);
assert.match(assembleBlock,/packed-consumer\.test\.mjs/u);
assert.match(
  assembleBlock,
  /build\(psc2\): bundle pskernel-lean 4\.34\.0 native providers/u,
);
assert.match(assembleBlock,/git push/u);

const providerWorkflowPath=path.join(
  repoRoot,
  '.github',
  'workflows',
  'psc2-lean-kernel-provider.yml',
);
const providerWorkflow=await readFile(providerWorkflowPath,'utf8');
assert.match(providerWorkflow,/permissions:\s*\n\s{2}contents:\s*read\s*\n\s*jobs:/mu);

const packedJobStart=providerWorkflow.search(/^\s{2}packed-consumer:\s*$/mu);
assert.notEqual(
  packedJobStart,
  -1,
  'normal provider workflow must continuously verify packed consumers',
);
const nextTopLevelJob=providerWorkflow.slice(packedJobStart+1)
  .search(/^\s{2}[a-z0-9-]+:\s*$/mu);
const packedJob=nextTopLevelJob===-1
  ? providerWorkflow.slice(packedJobStart)
  : providerWorkflow.slice(packedJobStart,packedJobStart+1+nextTopLevelJob);
for(const [runner,target] of expectedPairs){
  const escapedRunner=runner.replace(/[.*+?^${}()|[\]\\]/gu,'\\$&');
  const escapedTarget=target.replace(/[.*+?^${}()|[\]\\]/gu,'\\$&');
  assert.match(
    packedJob,
    new RegExp(
      `-\\s+runner:\\s*${escapedRunner}\\s+target:\\s*${escapedTarget}`,
      'u',
    ),
    `missing packed-consumer matrix pair ${runner} -> ${target}`,
  );
}
assert.doesNotMatch(packedJob,/leanprover\/lean-action|elan-init|lake\s/u);
assert.match(packedJob,/uses:\s*actions\/setup-node@v4/u);
assert.match(packedJob,/node-version:\s*22/u);
assert.match(packedJob,/npm pack/u);
assert.match(packedJob,/packed-consumer\.test\.mjs/u);
assert.match(packedJob,/PSC_LEAN_KERNEL_PROVIDER_BIN/u);

const nativeJobStart=providerWorkflow.search(/^\s{2}native-provider:\s*$/mu);
assert.notEqual(nativeJobStart,-1,'native-provider job is missing');
const nativeJob=providerWorkflow.slice(nativeJobStart,packedJobStart);
assert.match(nativeJob,/unset PSC_LEAN_KERNEL_PROVIDER_BIN/u);
assert.match(nativeJob,/resolveLeanKernelProviderBinary/u);
assert.match(nativeJob,/source\s*!==\s*['"]bundled['"]/u);
assert.match(nativeJob,/psc\.mjs check/u);
assert.match(nativeJob,/psc\.mjs build/u);

process.stdout.write('PSC2_LEAN_KERNEL_PREBUILT_WORKFLOW_CONTRACT: PASS\n');
process.stdout.write('PSC2_LEAN_KERNEL_PROVIDER_WORKFLOW_CONTRACT: PASS\n');
