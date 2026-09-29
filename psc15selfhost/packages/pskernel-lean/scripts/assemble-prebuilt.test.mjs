import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {
  cp,
  mkdir,
  mkdtemp,
  readFile,
  rm,
  stat,
  writeFile,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {assemblePrebuilt} from './assemble-prebuilt.mjs';

const leanCommit='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';
const targets=[
  'linux-x64',
  'linux-arm64',
  'darwin-x64',
  'darwin-arm64',
  'win32-x64',
];
const executableName=target=>target.startsWith('win32-')
  ? 'psc2_lean_kernel_provider.exe'
  : 'psc2_lean_kernel_provider';

async function makeArtifact(root,target,{metadataTarget=target,overrides={}}={}){
  const dir=path.join(root,target);
  await mkdir(dir,{recursive:true});
  const executable=executableName(target);
  const bytes=Buffer.from(`provider-${target}`);
  await writeFile(path.join(dir,executable),bytes);
  const metadata={
    target:metadataTarget,
    sourceCommit:'1234567890abcdef1234567890abcdef12345678',
    packageVersion:'4.34.0',
    protocol:'pskernel-lean/1',
    provider:'lean4-cpp',
    profile:'lean4.34-core',
    leanVersion:'4.34.0',
    leanCommit,
    executable,
    sha256:createHash('sha256').update(bytes).digest('hex'),
    size:bytes.length,
    ...overrides,
  };
  await writeFile(path.join(dir,'artifact.json'),`${JSON.stringify(metadata,null,2)}\n`);
  return dir;
}

async function makeSet(root){
  for(const target of targets){
    await makeArtifact(root,target);
  }
}

const root=await mkdtemp(path.join(os.tmpdir(),'psc2-assemble-prebuilt-'));
try{
  const artifacts=path.join(root,'artifacts');
  const packageRoot=path.join(root,'package');
  await mkdir(artifacts,{recursive:true});
  await mkdir(packageRoot,{recursive:true});
  await makeSet(artifacts);

  const manifest=await assemblePrebuilt({artifactsDir:artifacts,packageRoot});
  assert.equal(manifest.schema,1);
  assert.equal(manifest.package,'@proofscript/pskernel-lean');
  assert.equal(manifest.packageVersion,'4.34.0');
  assert.equal(manifest.protocol,'pskernel-lean/1');
  assert.equal(manifest.provider,'lean4-cpp');
  assert.equal(manifest.leanVersion,'4.34.0');
  assert.equal(manifest.leanCommit,leanCommit);
  assert.equal(manifest.profile,'lean4.34-core');
  assert.deepEqual(Object.keys(manifest.targets),targets);

  for(const target of targets){
    const expectedPath=`prebuilt/${target}/${executableName(target)}`;
    assert.equal(manifest.targets[target].path,expectedPath);
    assert.match(manifest.targets[target].sha256,/^[0-9a-f]{64}$/u);
    const original=await readFile(path.join(artifacts,target,executableName(target)));
    const assembledPath=path.join(packageRoot,expectedPath);
    const assembled=await readFile(assembledPath);
    assert.deepEqual(assembled,original);
    if(!target.startsWith('win32-')){
      assert.equal(
        (await stat(assembledPath)).mode&0o777,
        0o755,
        `${target} provider must be executable after assembly`,
      );
    }
  }
  const manifestOnDisk=JSON.parse(
    await readFile(path.join(packageRoot,'PREBUILT_MANIFEST.json'),'utf8'),
  );
  assert.deepEqual(manifestOnDisk,manifest);

  const secondPackage=path.join(root,'package-second');
  await mkdir(secondPackage,{recursive:true});
  const second=await assemblePrebuilt({artifactsDir:artifacts,packageRoot:secondPackage});
  assert.equal(JSON.stringify(second),JSON.stringify(manifest));

  const missing=path.join(root,'missing');
  await cp(artifacts,missing,{recursive:true});
  await rm(path.join(missing,'darwin-arm64'),{recursive:true,force:true});
  await assert.rejects(
    assemblePrebuilt({artifactsDir:missing,packageRoot:path.join(root,'missing-out')}),
    /artifact target set mismatch/,
  );

  const unexpected=path.join(root,'unexpected');
  await cp(artifacts,unexpected,{recursive:true});
  await makeArtifact(unexpected,'linux-extra',{metadataTarget:'linux-riscv64'});
  await assert.rejects(
    assemblePrebuilt({artifactsDir:unexpected,packageRoot:path.join(root,'unexpected-out')}),
    /unsupported staged target|artifact target set mismatch/,
  );

  const duplicate=path.join(root,'duplicate');
  await cp(artifacts,duplicate,{recursive:true});
  const duplicateDir=path.join(duplicate,'duplicate-linux');
  await cp(path.join(duplicate,'linux-x64'),duplicateDir,{recursive:true});
  await assert.rejects(
    assemblePrebuilt({artifactsDir:duplicate,packageRoot:path.join(root,'duplicate-out')}),
    /duplicate staged target: linux-x64/,
  );

  const mismatch=path.join(root,'mismatch');
  await cp(artifacts,mismatch,{recursive:true});
  const mismatchMetadata=JSON.parse(
    await readFile(path.join(mismatch,'linux-x64','artifact.json'),'utf8'),
  );
  mismatchMetadata.leanVersion='4.35.0';
  await writeFile(
    path.join(mismatch,'linux-x64','artifact.json'),
    `${JSON.stringify(mismatchMetadata,null,2)}\n`,
  );
  await assert.rejects(
    assemblePrebuilt({artifactsDir:mismatch,packageRoot:path.join(root,'mismatch-out')}),
    /leanVersion mismatch/,
  );

  const oversized=path.join(root,'oversized');
  await cp(artifacts,oversized,{recursive:true});
  const oversizedMetadata=JSON.parse(
    await readFile(path.join(oversized,'linux-x64','artifact.json'),'utf8'),
  );
  oversizedMetadata.size=100*1024*1024;
  await writeFile(
    path.join(oversized,'linux-x64','artifact.json'),
    `${JSON.stringify(oversizedMetadata,null,2)}\n`,
  );
  await assert.rejects(
    assemblePrebuilt({artifactsDir:oversized,packageRoot:path.join(root,'oversized-out')}),
    /repository size limit/,
  );

  const corrupt=path.join(root,'corrupt');
  await cp(artifacts,corrupt,{recursive:true});
  await writeFile(
    path.join(corrupt,'linux-x64','psc2_lean_kernel_provider'),
    'corrupted-bytes',
  );
  await assert.rejects(
    assemblePrebuilt({artifactsDir:corrupt,packageRoot:path.join(root,'corrupt-out')}),
    /checksum mismatch/,
  );

  const unsafe=path.join(root,'unsafe');
  await cp(artifacts,unsafe,{recursive:true});
  const unsafeMetadata=JSON.parse(
    await readFile(path.join(unsafe,'linux-x64','artifact.json'),'utf8'),
  );
  unsafeMetadata.executable='../provider';
  await writeFile(
    path.join(unsafe,'linux-x64','artifact.json'),
    `${JSON.stringify(unsafeMetadata,null,2)}\n`,
  );
  await assert.rejects(
    assemblePrebuilt({artifactsDir:unsafe,packageRoot:path.join(root,'unsafe-out')}),
    /executable name mismatch|unsafe executable/,
  );
}finally{
  await rm(root,{recursive:true,force:true});
}

process.stdout.write('PSC2_LEAN_KERNEL_PREBUILT_ASSEMBLY_TESTS: PASS\n');
