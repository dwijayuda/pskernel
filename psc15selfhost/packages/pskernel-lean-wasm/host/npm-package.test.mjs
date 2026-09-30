import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {existsSync} from 'node:fs';
import {mkdtemp,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const hostDir=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(hostDir,'..');
const npm=process.platform==='win32'?'npm.cmd':'npm';
const tempRoot=await mkdtemp(path.join(os.tmpdir(),'psc2-lean-wasm-npm-'));
let tarballPath;

function run(command,args,options={}){
  const result=spawnSync(command,args,{
    encoding:'utf8',
    windowsHide:true,
    ...options,
  });
  assert.equal(
    result.status,
    0,
    `${command} ${args.join(' ')} failed\nstdout:\n${result.stdout??''}\nstderr:\n${result.stderr??''}`,
  );
  return result;
}

const acceptedRequest=JSON.stringify({
  protocol:'pskernel-lean/1',
  format:'proofscript-checked-admissions',
  version:2,
  admissions:[{
    kind:'constant',
    declaration:{
      h:{h:'1',k:'regular'},
      k:'definition',
      lp:[],
      n:{k:'s',p:{k:'a'},v:'Test.PackedTrue'},
      s:'safe',
      t:{k:'const',ls:[],n:{k:'s',p:{k:'a'},v:'Nat'}},
      v:{k:'nat',v:'1'},
    },
  }],
});

const rejectedRequest=JSON.stringify({
  protocol:'pskernel-lean/1',
  format:'proofscript-checked-admissions',
  version:2,
  admissions:[{
    kind:'constant',
    declaration:{
      h:{h:'1',k:'regular'},
      k:'definition',
      lp:[],
      n:{k:'s',p:{k:'a'},v:'Test.PackedBad'},
      s:'safe',
      t:{k:'const',ls:[],n:{k:'s',p:{k:'a'},v:'Nat'}},
      v:{k:'sort',l:{k:'z'}},
    },
  }],
});

try{
  const pack=run(npm,['pack','--json'],{cwd:packageRoot});
  const packed=JSON.parse(pack.stdout);
  assert.equal(Array.isArray(packed),true);
  assert.equal(packed.length,1);
  tarballPath=path.join(packageRoot,packed[0].filename);
  assert.equal(existsSync(tarballPath),true,'npm pack must produce the tarball');

  await writeFile(
    path.join(tempRoot,'package.json'),
    JSON.stringify({private:true,type:'module'},null,2)+'\n',
    'utf8',
  );
  const installedTarball=path.relative(tempRoot,tarballPath);
  run(
    npm,
    [
      'install',
      '--ignore-scripts',
      '--no-package-lock',
      '--no-audit',
      '--no-fund',
      installedTarball,
    ],
    {cwd:tempRoot},
  );

  const installedRoot=path.join(
    tempRoot,
    'node_modules',
    '@proofscript',
    'pskernel-lean-wasm',
  );
  for(const [relativePath,label] of [
    ['wasm/pskernel-lean.cjs','generated Node launcher'],
    ['wasm/pskernel-lean.wasm','generated WASM module'],
    ['LEAN_LICENSE','upstream Lean license'],
    ['KERNEL_SOURCE_MANIFEST.json','kernel source manifest'],
    ['kernel/type_checker.cpp','vendored Lean kernel source'],
    ['provider/PsKernelLeanWasm/Api.lean','WASM provider source'],
    ['source/proofscript/foundation/Ps/Foundation/Name.lean','ProofScript foundation source'],
    ['source/proofscript/provider/PsKernelLean/Admission.lean','native provider semantic source'],
    ['scripts/build-wasm.sh','WASM rebuild script'],
    ['scripts/apply-wasm-abi.mjs','typed-WASM ABI rewrite script'],
    ['patches/lean4-4.34.0-emscripten-uv-stubs.patch','Lean/Emscripten compatibility patch'],
  ]){
    assert.equal(
      existsSync(path.join(installedRoot,...relativePath.split('/'))),
      true,
      `packed package must contain ${label}: ${relativePath}`,
    );
  }

  const verifyPath=path.join(tempRoot,'verify.mjs');
  await writeFile(verifyPath,`
import assert from 'node:assert/strict';
import {
  checkCanonicalAdmissions,
  createKernel,
  leanKernelProviderCommit,
  leanKernelProviderName,
  leanKernelProviderProtocol,
  leanKernelProviderVersion,
} from '@proofscript/pskernel-lean-wasm';

assert.equal(leanKernelProviderProtocol,'pskernel-lean/1');
assert.equal(leanKernelProviderName,'lean4-cpp');
assert.equal(leanKernelProviderVersion,'4.34.0');
assert.equal(leanKernelProviderCommit,'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');

const kernel=await createKernel();
assert.equal(kernel.metadata.status,'ok');
assert.equal(kernel.metadata.protocol,leanKernelProviderProtocol);
assert.equal(kernel.metadata.provider,leanKernelProviderName);
assert.equal(kernel.metadata.leanVersion,leanKernelProviderVersion);
assert.equal(kernel.metadata.leanCommit,leanKernelProviderCommit);

const accepted=await kernel.checkCanonicalAdmissions(${JSON.stringify(acceptedRequest)});
assert.equal(accepted.accepted,true);
const rejected=await checkCanonicalAdmissions(${JSON.stringify(rejectedRequest)});
assert.equal(rejected.accepted,false);
assert.equal(rejected.errorKind,'kernel-rejection');
assert.equal(rejected.declarationIndex,0);
console.log('PSC2_LEAN_KERNEL_WASM_PACKED_CONSUMER: PASS');
`,'utf8');

  const verify=run(process.execPath,[verifyPath],{cwd:tempRoot});
  assert.match(verify.stdout,/PSC2_LEAN_KERNEL_WASM_PACKED_CONSUMER: PASS/);
  console.log('PSC2_LEAN_KERNEL_WASM_NPM_PACKAGE: PASS');
}finally{
  await rm(tempRoot,{recursive:true,force:true});
  if(tarballPath!==undefined){
    await rm(tarballPath,{force:true});
  }
}
