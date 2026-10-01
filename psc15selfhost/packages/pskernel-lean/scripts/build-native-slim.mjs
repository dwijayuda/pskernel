import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {
  cpSync,
  existsSync,
  mkdirSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const sourceRoot=path.join(packageRoot,'source','proofscript');
const buildRoot=path.resolve(
  process.env.PSC_LEAN_NATIVE_BUILD_ROOT ??
  path.join(packageRoot,'.native-slim-build'),
);
const overlayRoot=path.join(buildRoot,'provider-overlay');
const providerRoot=path.join(overlayRoot,'src');
const oleanRoot=path.join(overlayRoot,'olean');
const cRoot=path.join(overlayRoot,'c');
const objRoot=path.join(buildRoot,'obj');
const outputDir=path.join(packageRoot,'.lake','build','bin');
const executable=process.platform==='win32'
  ? 'psc2_lean_kernel_provider.exe'
  : 'psc2_lean_kernel_provider';
const outputPath=path.join(outputDir,executable);
const expectedCommit='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';

function run(command,args,options={}){
  const result=spawnSync(command,args,{
    cwd:packageRoot,
    encoding:'utf8',
    windowsHide:true,
    maxBuffer:64*1024*1024,
    ...options,
  });
  assert.equal(
    result.status,
    0,
    `${command} ${args.join(' ')} failed\nstdout:\n${result.stdout??''}\nstderr:\n${result.stderr??''}`,
  );
  return result;
}

function leanTool(prefix,name){
  const suffix=process.platform==='win32'?'.exe':'';
  const local=path.join(prefix,'bin',name+suffix);
  return existsSync(local)?local:name;
}

assert.equal(
  run('lean',['--githash']).stdout.trim(),
  expectedCommit,
  'Lean source commit must match the native kernel profile',
);
const leanPrefix=run('lean',['--print-prefix']).stdout.trim();
const leanLib=path.join(leanPrefix,'lib','lean');
const leanc=leanTool(leanPrefix,'leanc');
for(const library of ['libleancpp.a','libInit.a','libStd.a','libLean.a','libleanrt.a']){
  assert.equal(
    existsSync(path.join(leanLib,library)),
    true,
    `Lean static library is missing: ${library}`,
  );
}

const sourceDirs={
  foundation:path.join(sourceRoot,'foundation'),
  core:path.join(sourceRoot,'core'),
  environment:path.join(sourceRoot,'environment'),
  bridge:path.join(sourceRoot,'bridge'),
  provider:path.join(sourceRoot,'provider'),
};
for(const [name,dir] of Object.entries(sourceDirs)){
  assert.equal(existsSync(dir),true,`packaged ProofScript source missing: ${name}`);
}

rmSync(buildRoot,{recursive:true,force:true});
mkdirSync(path.join(providerRoot,'Ps'),{recursive:true});
mkdirSync(path.join(providerRoot,'PsKernelLean'),{recursive:true});
mkdirSync(oleanRoot,{recursive:true});
mkdirSync(cRoot,{recursive:true});
mkdirSync(objRoot,{recursive:true});
mkdirSync(outputDir,{recursive:true});

for(const name of ['foundation','core','environment','bridge']){
  cpSync(path.join(sourceDirs[name],'Ps'),path.join(providerRoot,'Ps'),{
    recursive:true,
    force:true,
  });
}
cpSync(
  path.join(sourceDirs.provider,'PsKernelLean'),
  path.join(providerRoot,'PsKernelLean'),
  {recursive:true,force:true},
);

const modules=[
  'Ps/Foundation/Name',
  'PsKernelLean/Error',
  'Ps/Core/Builtin',
  'Ps/Core/Level',
  'Ps/Bridge/Json',
  'Ps/Core/Expr',
  'Ps/Core/Declaration',
  'Ps/Environment/Basic',
  'Ps/Bridge/CheckedAdmissions',
  'Ps/Environment/Prelude',
  'PsKernelLean/Convert',
  'Ps/Bridge/Codec',
  'Ps/Environment/SelfHostPrelude',
  'Ps/Environment/SelfHostProd',
  'PsKernelLean/Protocol',
  'PsKernelLean/Prelude',
  'PsKernelLean/Admission',
  'PsKernelLean/Response',
  'PsKernelLean/Main',
];

const leanEnv={
  ...process.env,
  LEAN_PATH:[oleanRoot,leanLib].join(path.delimiter),
  LEAN_ABORT_ON_PANIC:'1',
};

const cFiles=[];
for(const module of modules){
  const source=module+'.lean';
  const olean=path.join(oleanRoot,module+'.olean');
  const ilean=path.join(oleanRoot,module+'.ilean');
  const cFile=path.join(cRoot,module+'.c');
  const cTmp=cFile+'.tmp';
  mkdirSync(path.dirname(olean),{recursive:true});
  mkdirSync(path.dirname(cFile),{recursive:true});
  run('lean',[
    '-o',olean,
    '-i',ilean,
    `--c=${cTmp}`,
    source,
  ],{cwd:providerRoot,env:leanEnv});
  renameSync(cTmp,cFile);
  cFiles.push(cFile);
}

const objects=[];
for(let index=0;index<cFiles.length;index++){
  const object=path.join(objRoot,`${index}.o`);
  run(leanc,['-Os','-DNDEBUG','-c',cFiles[index],'-o',object]);
  objects.push(object);
}

const shim=path.join(buildRoot,'minimal-initialize.cpp');
const shimObject=path.join(objRoot,'minimal-initialize.o');
writeFileSync(shim,`
#include "runtime/stackinfo.h"
#include "util/init_module.h"
#include "kernel/init_module.h"

namespace lean {
static bool g_pskernel_native_initialized = false;
extern "C" LEAN_EXPORT void lean_initialize() {
    if (g_pskernel_native_initialized)
        return;
    g_pskernel_native_initialized = true;
    save_stack_info();
    initialize_util_module();
    initialize_kernel_module();
}
}
`,'utf8');
run(leanc,[
  '-Os',
  '-DNDEBUG',
  `-I${packageRoot}`,
  '-c',shim,
  '-o',shimObject,
]);

const linkArgs=[...objects,shimObject,`-L${leanLib}`];
if(process.platform==='darwin'){
  linkArgs.push(
    '-lleancpp',
    '-lInit',
    '-lStd',
    '-lLean',
    '-lleanrt',
    '-lc++',
  );
}else{
  if(process.platform==='win32'){
    linkArgs.push(
      '-Wl,--whole-archive',
      '-lleanmanifest',
      '-Wl,--no-whole-archive',
    );
  }
  linkArgs.push(
    '-Wl,--start-group',
    '-lleancpp',
    '-lLean',
    '-Wl,--end-group',
    '-lStd',
    '-Wl,--start-group',
    '-lInit',
    '-lleanrt',
    '-Wl,--end-group',
    '-lstdc++',
  );
}
linkArgs.push('-Os','-o',outputPath);
run(leanc,linkArgs);

assert.equal(existsSync(outputPath),true,'slim native provider was not produced');
const bytes=statSync(outputPath).size;
assert.ok(bytes>0,'slim native provider is empty');
console.log(`PSC2_LEAN_KERNEL_NATIVE_SLIM_LINK: PASS ${bytes} bytes ${outputPath}`);
