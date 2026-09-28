import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdtemp,mkdir,readFile,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {
  leanKernelProviderTargetKey,
  loadLeanKernelPrebuiltManifest,
  resolveLeanKernelProviderBinary,
  supportedLeanKernelProviderTargets,
  verifyLeanKernelPrebuiltBinary,
} from './prebuilt.mjs';

const expectedTargets=[
  'linux-x64',
  'linux-arm64',
  'darwin-x64',
  'darwin-arm64',
  'win32-x64',
];
assert.deepEqual(supportedLeanKernelProviderTargets,expectedTargets);
assert.equal(leanKernelProviderTargetKey({platform:'linux',arch:'x64'}),'linux-x64');
assert.equal(leanKernelProviderTargetKey({platform:'linux',arch:'arm64'}),'linux-arm64');
assert.equal(leanKernelProviderTargetKey({platform:'darwin',arch:'x64'}),'darwin-x64');
assert.equal(leanKernelProviderTargetKey({platform:'darwin',arch:'arm64'}),'darwin-arm64');
assert.equal(leanKernelProviderTargetKey({platform:'win32',arch:'x64'}),'win32-x64');
assert.throws(
  ()=>leanKernelProviderTargetKey({platform:'win32',arch:'arm64'}),
  /no bundled provider for win32-arm64.*supported targets:/s,
);
assert.throws(
  ()=>leanKernelProviderTargetKey({platform:'plan9',arch:'mips'}),
  /no bundled provider for plan9-mips.*supported targets:/s,
);

const tempRoot=await mkdtemp(path.join(os.tmpdir(),'psc2-prebuilt-resolver-'));
try{
  const packageRoot=path.join(tempRoot,'package');
  const target='linux-x64';
  const binaryPath=path.join(
    packageRoot,'prebuilt',target,'psc2_lean_kernel_provider',
  );
  await mkdir(path.dirname(binaryPath),{recursive:true});
  const bytes=Buffer.from('fixture-provider-bytes');
  await writeFile(binaryPath,bytes);
  const sha256=createHash('sha256').update(bytes).digest('hex');

  const targets=Object.fromEntries(expectedTargets.map(key=>[
    key,
    {
      path:`prebuilt/${key}/${key.startsWith('win32-')?'psc2_lean_kernel_provider.exe':'psc2_lean_kernel_provider'}`,
      sha256:key===target?sha256:'0'.repeat(64),
    },
  ]));
  const manifest={
    schema:1,
    package:'@proofscript/pskernel-lean',
    packageVersion:'4.34.0',
    protocol:'pskernel-lean/1',
    provider:'lean4-cpp',
    leanVersion:'4.34.0',
    leanCommit:'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
    profile:'lean4.34-core',
    targets,
  };
  await writeFile(
    path.join(packageRoot,'PREBUILT_MANIFEST.json'),
    `${JSON.stringify(manifest,null,2)}\n`,
  );

  const loaded=loadLeanKernelPrebuiltManifest({packageRoot});
  assert.equal(loaded.targets[target].sha256,sha256);

  const override=resolveLeanKernelProviderBinary({
    platform:'linux',
    arch:'x64',
    env:{PSC_LEAN_KERNEL_PROVIDER_BIN:'/custom/provider'},
    packageRoot,
  });
  assert.deepEqual(override,{
    binaryPath:'/custom/provider',
    source:'override',
  });

  const bundled=resolveLeanKernelProviderBinary({
    platform:'linux',
    arch:'x64',
    env:{},
    packageRoot,
  });
  assert.equal(bundled.binaryPath,binaryPath);
  assert.equal(bundled.source,'bundled');
  assert.equal(bundled.target,target);
  verifyLeanKernelPrebuiltBinary({
    binaryPath:bundled.binaryPath,
    target:bundled.target,
    manifest:loaded,
    packageRoot,
  });

  const workspaceRoot=path.resolve(packageRoot,'../..');
  const lakeBinary=path.join(workspaceRoot,'.lake','build','bin','psc2_lean_kernel_provider');
  await mkdir(path.dirname(lakeBinary),{recursive:true});
  await writeFile(lakeBinary,'lake-fixture');
  const stillBundled=resolveLeanKernelProviderBinary({
    platform:'linux',arch:'x64',env:{},packageRoot,
  });
  assert.equal(stillBundled.source,'bundled');
  assert.equal(stillBundled.binaryPath,binaryPath);

  await rm(binaryPath,{force:true});
  const fallback=resolveLeanKernelProviderBinary({
    platform:'linux',arch:'x64',env:{},packageRoot,
    allowSourceCheckoutFallback:true,
  });
  assert.equal(fallback.source,'source-checkout');
  assert.equal(fallback.binaryPath,lakeBinary);

  assert.throws(
    ()=>resolveLeanKernelProviderBinary({
      platform:'linux',arch:'x64',env:{},packageRoot,
      allowSourceCheckoutFallback:false,
    }),
    /bundled Lean kernel provider is missing/,
  );

  await writeFile(binaryPath,bytes);
  await writeFile(binaryPath,Buffer.from('tampered'));
  assert.throws(
    ()=>verifyLeanKernelPrebuiltBinary({
      binaryPath,
      target,
      manifest:loaded,
      packageRoot,
    }),
    /checksum mismatch/,
  );

  const unsafe={...manifest,targets:{...manifest.targets,[target]:{
    path:'../escape/provider',
    sha256,
  }}};
  await writeFile(
    path.join(packageRoot,'PREBUILT_MANIFEST.json'),
    `${JSON.stringify(unsafe,null,2)}\n`,
  );
  assert.throws(
    ()=>loadLeanKernelPrebuiltManifest({packageRoot}),
    /escapes package root/,
  );
}finally{
  await rm(tempRoot,{recursive:true,force:true});
}

process.stdout.write('PSC2_LEAN_KERNEL_PREBUILT_RESOLVER_TESTS: PASS\n');
