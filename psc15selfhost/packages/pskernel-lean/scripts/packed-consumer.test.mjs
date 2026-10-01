import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {mkdtemp,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

function parseArgs(argv){
  const values={};
  for(let index=0;index<argv.length;index+=2){
    const flag=argv[index];
    const value=argv[index+1];
    if(!flag?.startsWith('--')||value===undefined){
      throw new Error(`invalid argument sequence near ${String(flag)}`);
    }
    values[flag.slice(2)]=value;
  }
  return values;
}

const args=parseArgs(process.argv.slice(2));
if(!args.tarball)throw new Error('missing --tarball');
const tarball=path.resolve(args.tarball);
const consumerRoot=await mkdtemp(path.join(os.tmpdir(),'psc2-packed-kernel-consumer-'));
const npm=process.platform==='win32'?'npm.cmd':'npm';

try{
  await writeFile(
    path.join(consumerRoot,'package.json'),
    JSON.stringify({name:'psc2-packed-kernel-consumer',private:true,type:'module'},null,2),
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
    {
      cwd:consumerRoot,
      encoding:'utf8',
      shell:process.platform==='win32',
    },
  );
  assert.equal(
    install.status,
    0,
    `${install.error?.stack??''}\n${install.stdout??''}\n${install.stderr??''}`,
  );

  const consumerScript=path.join(consumerRoot,'consume.mjs');
  await writeFile(consumerScript,`
import assert from 'node:assert/strict';
import {
  checkCanonicalAdmissions,
  defaultLeanKernelProviderBinary,
  leanKernelProviderCommit,
} from '@proofscript/pskernel-lean';

const binaryPath=defaultLeanKernelProviderBinary();
const normalized=binaryPath.replaceAll('\\\\','/');
const target=process.platform+'-'+process.arch;
assert.ok(
  normalized.includes('/prebuilt/'+target+'/'),
  'expected bundled provider path, got '+binaryPath,
);

const rootName=value=>({k:'s',p:{k:'a'},v:value});
const natType={k:'const',ls:[],n:rootName('Nat')};
const definition=(name,value)=>({
  kind:'constant',
  declaration:{
    h:{h:'1',k:'regular'},
    k:'definition',
    lp:[],
    n:rootName(name),
    s:'safe',
    t:natType,
    v:value,
  },
});
const payload=admissions=>JSON.stringify({
  admissions,
  format:'proofscript-checked-admissions',
  version:2,
});

const accepted=checkCanonicalAdmissions(
  payload([definition('packedAccepted',{k:'nat',v:'1'})]),
);
assert.equal(accepted.accepted,true);
assert.equal(accepted.leanCommit,leanKernelProviderCommit);

const rejected=checkCanonicalAdmissions(
  payload([definition('packedRejected',{k:'sort',l:{k:'z'}})]),
);
assert.equal(rejected.accepted,false);
assert.equal(rejected.errorKind,'kernel-rejection');
assert.equal(rejected.declarationIndex,0);

process.stdout.write('PSC2_PACKED_LEAN_KERNEL_CONSUMER_INNER: PASS\\n');
`);

  const env={...process.env};
  delete env.PSC_LEAN_KERNEL_PROVIDER_BIN;
  const consume=spawnSync(
    process.execPath,
    [consumerScript],
    {cwd:consumerRoot,encoding:'utf8',env},
  );
  assert.equal(
    consume.status,
    0,
    `${consume.error?.stack??''}\n${consume.stdout??''}\n${consume.stderr??''}`,
  );
  assert.match(consume.stdout,/PSC2_PACKED_LEAN_KERNEL_CONSUMER_INNER: PASS/u);
}finally{
  await rm(consumerRoot,{recursive:true,force:true});
}

process.stdout.write('PSC2_PACKED_LEAN_KERNEL_CONSUMER_TESTS: PASS\n');
