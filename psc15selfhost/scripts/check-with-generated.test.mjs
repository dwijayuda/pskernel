import assert from 'node:assert/strict';
import {mkdtemp, mkdir, rm, writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {checkGeneratedProjectWithKernel} from './check-with-generated.mjs';

const tempRoot=await mkdtemp(path.join(os.tmpdir(),'psc2-kernel-check-'));
try{
  await mkdir(path.join(tempRoot,'packages'),{recursive:true});
  await mkdir(path.join(tempRoot,'stdlib'),{recursive:true});

  const compilerPath=path.join(tempRoot,'compiler.mjs');
  const compilerSource=String.raw`
export const PsCompilerSourceKind={lean:'lean',proofScript:'proofScript'};
const exceptTag=Symbol('except');
const ok=value=>({[exceptTag]:'ok',value});
export function psCompilerTranslateSource(_from,_to,source){return ok(source);}
const rootName=value=>({k:'s',p:{k:'a'},v:value});
const natType={k:'const',ls:[],n:rootName('Nat')};
export function psCompilerAdmissionsSource(_kind,source){
  const bad=source.includes('BAD_KERNEL_BODY');
  const admission={
    kind:'constant',
    declaration:{
      h:{h:'1',k:'regular'},
      k:'definition',
      lp:[],
      n:rootName(bad?'generatedRejected':'generatedAccepted'),
      s:'safe',
      t:natType,
      v:bad?{k:'sort',l:{k:'z'}}:{k:'nat',v:'1'},
    },
  };
  return ok(JSON.stringify({
    admissions:[admission],
    format:'proofscript-checked-admissions',
    version:2,
  })+'\\n');
}
`;
  await writeFile(compilerPath,compilerSource,'utf8');

  const acceptedEntry=path.join(tempRoot,'Accepted.ps');
  await writeFile(acceptedEntry,'def marker : Nat := 1;\n','utf8');
  const accepted=await checkGeneratedProjectWithKernel({
    compilerPath,
    entryPath:acceptedEntry,
    kernel:'lean434',
  });
  assert.equal(accepted.accepted,true);
  assert.equal(accepted.provider,'lean4-cpp');
  assert.equal(accepted.leanVersion,'4.34.0');
  assert.equal(
    accepted.leanCommit,
    '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  );

  const rejectedEntry=path.join(tempRoot,'Rejected.ps');
  await writeFile(rejectedEntry,'BAD_KERNEL_BODY\n','utf8');
  await assert.rejects(
    ()=>checkGeneratedProjectWithKernel({
      compilerPath,
      entryPath:rejectedEntry,
      kernel:'lean434',
    }),
    /PSC2_KERNEL_REJECTED: kernel-rejection at declaration 0/,
  );

  await assert.rejects(
    ()=>checkGeneratedProjectWithKernel({
      compilerPath,
      entryPath:acceptedEntry,
      kernel:'unknown',
    }),
    /PSC2_KERNEL_PROVIDER: expected lean434/,
  );

  await assert.rejects(
    ()=>checkGeneratedProjectWithKernel({
      compilerPath:path.join(tempRoot,'missing-compiler.mjs'),
      entryPath:acceptedEntry,
      kernel:'lean434',
    }),
    /PSC2_SELFHOST_COMPILER_MISSING/,
  );

  console.log('PSC2_GENERATED_KERNEL_CHECK_TESTS: PASS');
} finally {
  await rm(tempRoot,{recursive:true,force:true});
}
