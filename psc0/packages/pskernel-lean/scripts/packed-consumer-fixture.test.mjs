import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {
  chmod,
  copyFile,
  cp,
  mkdir,
  mkdtemp,
  rm,
  writeFile,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {assemblePrebuilt} from './assemble-prebuilt.mjs';
import {stageNativePrebuilt} from './stage-native-prebuilt.mjs';

if(process.platform!=='linux'||process.arch!=='x64'){
  throw new Error('Task 4 fixture harness is intentionally linux-x64 only');
}

const scriptDir=path.dirname(fileURLToPath(import.meta.url));
const sourcePackageRoot=path.resolve(scriptDir,'..');
const workspaceRoot=path.resolve(sourcePackageRoot,'../..');
const nativeBinary=path.join(
  workspaceRoot,'.lake','build','bin','psc2_lean_kernel_provider',
);
const root=await mkdtemp(path.join(os.tmpdir(),'psc2-packed-fixture-'));
const packageRoot=path.join(root,'package');
const artifactsRoot=path.join(root,'artifacts');
const inputsRoot=path.join(root,'inputs');
const packRoot=path.join(root,'pack');
const npm=process.platform==='win32'?'npm.cmd':'npm';
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

try{
  await cp(sourcePackageRoot,packageRoot,{recursive:true});
  await rm(path.join(packageRoot,'prebuilt'),{recursive:true,force:true});
  await rm(path.join(packageRoot,'PREBUILT_MANIFEST.json'),{force:true});
  await mkdir(artifactsRoot,{recursive:true});
  await mkdir(inputsRoot,{recursive:true});
  await mkdir(packRoot,{recursive:true});

  const head=spawnSync('git',['rev-parse','HEAD'],{
    cwd:workspaceRoot,
    encoding:'utf8',
  });
  assert.equal(head.status,0,head.stderr);
  const sourceCommit=head.stdout.trim();
  assert.match(sourceCommit,/^[0-9a-f]{40}$/u);

  const healthRun=spawnSync(nativeBinary,['--health'],{encoding:'utf8'});
  assert.equal(healthRun.status,0,healthRun.stderr);
  const health=JSON.parse(healthRun.stdout);
  assert.equal(health.status,'ok');
  assert.equal(health.leanCommit,leanCommit);

  for(const target of targets){
    const inputDir=path.join(inputsRoot,target);
    await mkdir(inputDir,{recursive:true});
    const inputBinary=path.join(inputDir,executableName(target));
    if(target==='linux-x64'){
      await copyFile(nativeBinary,inputBinary);
      await chmod(inputBinary,0o755);
      const stripped=spawnSync('strip',['--strip-all',inputBinary],{encoding:'utf8'});
      assert.equal(stripped.status,0,`${stripped.stdout}\n${stripped.stderr}`);
    }else{
      await writeFile(inputBinary,Buffer.from(`synthetic-prebuilt-${target}\n`));
      if(!target.startsWith('win32-')){
        await chmod(inputBinary,0o755);
      }
    }
    await stageNativePrebuilt({
      target,
      binaryPath:inputBinary,
      sourceCommit,
      leanGithash:leanCommit,
      health,
      outDir:path.join(artifactsRoot,target),
    });
  }

  await assemblePrebuilt({artifactsDir:artifactsRoot,packageRoot});

  const packed=spawnSync(
    npm,
    ['pack','--json','--pack-destination',packRoot],
    {cwd:packageRoot,encoding:'utf8'},
  );
  assert.equal(packed.status,0,`${packed.stdout}\n${packed.stderr}`);
  const packResult=JSON.parse(packed.stdout);
  assert.equal(packResult.length,1);
  const files=packResult[0].files.map(file=>file.path).sort();
  const executablePaths=files.filter(file=>
    /^prebuilt\/(?:linux-x64|linux-arm64|darwin-x64|darwin-arm64|win32-x64)\/psc2_lean_kernel_provider(?:\.exe)?$/u.test(file),
  );
  assert.equal(executablePaths.length,5,JSON.stringify(executablePaths));
  assert.ok(files.includes('PREBUILT_MANIFEST.json'));
  for(const forbidden of ['.lake/','kernel/','runtime/','util/']){
    assert.equal(
      files.some(file=>file===forbidden.slice(0,-1)||file.startsWith(forbidden)),
      false,
      `tarball unexpectedly contains ${forbidden}`,
    );
  }

  const tarball=path.join(packRoot,packResult[0].filename);
  const consume=spawnSync(
    process.execPath,
    [path.join(scriptDir,'packed-consumer.test.mjs'),'--tarball',tarball],
    {cwd:workspaceRoot,encoding:'utf8'},
  );
  assert.equal(consume.status,0,`${consume.stdout}\n${consume.stderr}`);
  assert.match(consume.stdout,/PSC2_PACKED_LEAN_KERNEL_CONSUMER_TESTS: PASS/u);
}finally{
  await rm(root,{recursive:true,force:true});
}

process.stdout.write('PSC2_LEAN_KERNEL_PACKED_FIXTURE_TESTS: PASS\n');
