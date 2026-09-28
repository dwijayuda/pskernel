import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {mkdtemp,readFile,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const scriptsDir=path.dirname(fileURLToPath(import.meta.url));
const workspaceRoot=path.resolve(scriptsDir,'..');
const packageRoot=path.join(workspaceRoot,'packages','pskernel-lean');
const consumerRoot=await mkdtemp(path.join(os.tmpdir(),'psc2-pskernel-lean-consumer-'));
const packRoot=await mkdtemp(path.join(os.tmpdir(),'psc2-pskernel-lean-pack-'));
const npm=process.platform==='win32'?'npm.cmd':'npm';

const workspaceManifest=JSON.parse(
  await readFile(path.join(workspaceRoot,'package.json'),'utf8'),
);
assert.equal(
  workspaceManifest.optionalDependencies?.['@proofscript/pskernel-lean'],
  '4.34.0',
);

const cliManifest=JSON.parse(
  await readFile(path.join(workspaceRoot,'packages','cli','package.json'),'utf8'),
);
assert.equal(
  cliManifest.optionalDependencies?.['@proofscript/pskernel-lean'],
  '4.34.0',
);

try{
  const packed=spawnSync(
    npm,
    [
      'pack',
      '--json',
      '--pack-destination',
      packRoot,
    ],
    {cwd:packageRoot,encoding:'utf8'},
  );
  assert.equal(packed.status,0,`${packed.stdout}\n${packed.stderr}`);
  const packResult=JSON.parse(packed.stdout);
  assert.equal(packResult.length,1);
  assert.equal(packResult[0].name,'@proofscript/pskernel-lean');
  assert.equal(packResult[0].version,'4.34.0');
  const tarball=path.join(packRoot,packResult[0].filename);

  await writeFile(
    path.join(consumerRoot,'package.json'),
    JSON.stringify({name:'psc2-kernel-consumer-test',private:true,type:'module'},null,2),
  );

  const install=spawnSync(
    npm,
    [
      'install',
      '--ignore-scripts',
      '--no-audit',
      '--no-fund',
      '--package-lock=false',
      tarball,
    ],
    {cwd:consumerRoot,encoding:'utf8'},
  );
  assert.equal(install.status,0,`${install.stdout}\n${install.stderr}`);

  const consume=spawnSync(
    process.execPath,
    [
      '--input-type=module',
      '-e',
      [
        "const p=await import('@proofscript/pskernel-lean');",
        "if(p.leanKernelProviderVersion!=='4.34.0')process.exit(2);",
        "if(typeof p.checkCanonicalAdmissions!=='function')process.exit(3);",
        "process.stdout.write(p.leanKernelProviderCommit);",
      ].join(''),
    ],
    {cwd:consumerRoot,encoding:'utf8'},
  );
  assert.equal(consume.status,0,consume.stderr);
  assert.equal(
    consume.stdout,
    '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  );
}finally{
  await rm(consumerRoot,{recursive:true,force:true});
  await rm(packRoot,{recursive:true,force:true});
}

const generatedChecker=await readFile(
  path.join(scriptsDir,'check-with-generated.mjs'),
  'utf8',
);
assert.doesNotMatch(
  generatedChecker,
  /packages\/pskernel-lean\/host\/node-provider\.mjs/u,
);
assert.match(generatedChecker,/@proofscript\/pskernel-lean/u);

process.stdout.write('PSC2_LEAN_KERNEL_NPM_CONSUMER_TESTS: PASS\n');
