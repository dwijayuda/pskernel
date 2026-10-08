import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const expectedCommit='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';
const expectedVersion='4.34.0';
const executable=process.platform==='win32'
  ? 'psc2_lean_kernel_provider.exe'
  : 'psc2_lean_kernel_provider';
const binaryPath=path.join(packageRoot,'.lake','build','bin',executable);

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

assert.equal(run('lean',['--githash']).stdout.trim(),expectedCommit,'Lean source commit must match package pin');
assert.equal(run('lean',['--short-version']).stdout.trim(),expectedVersion,'Lean version must match package pin');
run(process.execPath,[path.join(here,'build-native-slim.mjs')]);

const health=JSON.parse(run(binaryPath,['--health']).stdout.trim());
assert.equal(health.status,'ok');
assert.equal(health.protocol,'pskernel-lean/1');
assert.equal(health.provider,'lean4-cpp');
assert.equal(health.leanVersion,expectedVersion);
assert.equal(health.leanCommit,expectedCommit);
assert.equal(health.profile,'lean4.34-core');

const acceptedRequest=JSON.stringify({
  protocol:'pskernel-lean/1',
  format:'proofscript-checked-admissions',
  version:2,
  admissions:[{kind:'constant',declaration:{
    h:{h:'1',k:'regular'},k:'definition',lp:[],
    n:{k:'s',p:{k:'a'},v:'PackageBuild.True'},s:'safe',
    t:{k:'const',ls:[],n:{k:'s',p:{k:'a'},v:'Nat'}},
    v:{k:'nat',v:'1'},
  }}],
});
const accepted=JSON.parse(run(binaryPath,['--check'],{input:acceptedRequest}).stdout.trim());
assert.equal(accepted.accepted,true,'source-built provider must accept valid admission');

const rejectedRequest=JSON.stringify({
  protocol:'pskernel-lean/1',
  format:'proofscript-checked-admissions',
  version:2,
  admissions:[{kind:'constant',declaration:{
    h:{h:'1',k:'regular'},k:'definition',lp:[],
    n:{k:'s',p:{k:'a'},v:'PackageBuild.Bad'},s:'safe',
    t:{k:'const',ls:[],n:{k:'s',p:{k:'a'},v:'Nat'}},
    v:{k:'sort',l:{k:'z'}},
  }}],
});
const rejected=JSON.parse(run(binaryPath,['--check'],{input:rejectedRequest}).stdout.trim());
assert.equal(rejected.accepted,false,'source-built provider must reject ill-typed admission');
assert.equal(rejected.errorKind,'kernel-rejection');
assert.equal(rejected.declarationIndex,0);
console.log(`PSC2_LEAN_KERNEL_NATIVE_BUILD: PASS ${binaryPath}`);
