import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdtemp,mkdir,readFile,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {stageNativePrebuilt} from './stage-native-prebuilt.mjs';

const leanCommit='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';
const sourceCommit='1234567890abcdef1234567890abcdef12345678';
const health={
  status:'ok',
  protocol:'pskernel-lean/1',
  provider:'lean4-cpp',
  leanVersion:'4.34.0',
  leanCommit,
  profile:'lean4.34-core',
};

const root=await mkdtemp(path.join(os.tmpdir(),'psc2-stage-native-'));
try{
  const inputDir=path.join(root,'input');
  const outDir=path.join(root,'out');
  await mkdir(inputDir,{recursive:true});
  const binary=path.join(inputDir,'psc2_lean_kernel_provider');
  const bytes=Buffer.from('native-provider-fixture');
  await writeFile(binary,bytes);

  const result=await stageNativePrebuilt({
    target:'linux-x64',
    binaryPath:binary,
    sourceCommit,
    leanGithash:leanCommit,
    health,
    outDir,
  });
  assert.equal(result.target,'linux-x64');
  assert.equal(result.executable,'psc2_lean_kernel_provider');
  assert.equal(result.sourceCommit,sourceCommit);
  assert.equal(result.packageVersion,'4.34.0');
  assert.equal(result.protocol,'pskernel-lean/1');
  assert.equal(result.provider,'lean4-cpp');
  assert.equal(result.profile,'lean4.34-core');
  assert.equal(result.leanVersion,'4.34.0');
  assert.equal(result.leanCommit,leanCommit);
  assert.equal(result.size,bytes.length);
  assert.equal(
    result.sha256,
    createHash('sha256').update(bytes).digest('hex'),
  );

  const stagedBinary=path.join(outDir,'psc2_lean_kernel_provider');
  assert.deepEqual(await readFile(stagedBinary),bytes);
  const metadata=JSON.parse(await readFile(path.join(outDir,'artifact.json'),'utf8'));
  assert.deepEqual(metadata,result);

  await assert.rejects(
    stageNativePrebuilt({
      target:'win32-arm64',binaryPath:binary,sourceCommit,
      leanGithash:leanCommit,health,outDir:path.join(root,'bad-target'),
    }),
    /unsupported Lean kernel prebuilt target/,
  );
  await assert.rejects(
    stageNativePrebuilt({
      target:'linux-x64',binaryPath:binary,sourceCommit,
      leanGithash:'0'.repeat(40),health,outDir:path.join(root,'bad-hash'),
    }),
    /Lean githash mismatch/,
  );
  await assert.rejects(
    stageNativePrebuilt({
      target:'linux-x64',binaryPath:binary,sourceCommit,
      leanGithash:leanCommit,health:{...health,leanVersion:'4.35.0'},
      outDir:path.join(root,'bad-health'),
    }),
    /health leanVersion mismatch/,
  );
  await assert.rejects(
    stageNativePrebuilt({
      target:'linux-x64',binaryPath:path.join(root,'missing'),sourceCommit,
      leanGithash:leanCommit,health,outDir:path.join(root,'missing-out'),
    }),
    /provider executable is missing/,
  );

  const exe=path.join(inputDir,'psc2_lean_kernel_provider.exe');
  await writeFile(exe,bytes);
  await assert.rejects(
    stageNativePrebuilt({
      target:'linux-x64',binaryPath:exe,sourceCommit,
      leanGithash:leanCommit,health,outDir:path.join(root,'wrong-name'),
    }),
    /executable name mismatch/,
  );
}finally{
  await rm(root,{recursive:true,force:true});
}

process.stdout.write('PSC2_LEAN_KERNEL_NATIVE_STAGE_TESTS: PASS\n');
