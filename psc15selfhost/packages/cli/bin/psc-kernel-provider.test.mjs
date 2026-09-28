import assert from 'node:assert/strict';
import {mkdtemp, mkdir, rm, writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const testDir=path.dirname(fileURLToPath(import.meta.url));
const pscPath=path.join(testDir,'psc.mjs');
const tempRoot=await mkdtemp(path.join(os.tmpdir(),'psc2-cli-kernel-'));

function runPsc(args){
  return spawnSync(process.execPath,[pscPath,...args],{
    encoding:'utf8',
    windowsHide:true,
  });
}

try{
  await mkdir(path.join(tempRoot,'packages'),{recursive:true});
  await mkdir(path.join(tempRoot,'stdlib'),{recursive:true});

  const compilerPath=path.join(tempRoot,'compiler.mjs');
  await writeFile(compilerPath,String.raw`
export const PsCompilerSourceKind={lean:'lean',proofScript:'proofScript'};
const exceptTag=Symbol('except');
const ok=value=>({[exceptTag]:'ok',value});
export function psCompilerTranslateSource(_from,_to,source){return ok(source);}
const rootName=value=>({k:'s',p:{k:'a'},v:value});
const natType={k:'const',ls:[],n:rootName('Nat')};
export function psCompilerAdmissionsSource(_kind,source){
  const bad=source.includes('BAD_KERNEL_BODY');
  return ok(JSON.stringify({
    admissions:[{
      kind:'constant',
      declaration:{
        h:{h:'1',k:'regular'},
        k:'definition',
        lp:[],
        n:rootName(bad?'cliRejected':'cliAccepted'),
        s:'safe',
        t:natType,
        v:bad?{k:'sort',l:{k:'z'}}:{k:'nat',v:'1'},
      },
    }],
    format:'proofscript-checked-admissions',
    version:2,
  })+String.fromCharCode(10));
}
`,'utf8');

  const acceptedEntry=path.join(tempRoot,'Accepted.ps');
  const rejectedEntry=path.join(tempRoot,'Rejected.ps');
  await writeFile(acceptedEntry,'def marker : Nat := 1;\n','utf8');
  await writeFile(rejectedEntry,'BAD_KERNEL_BODY\n','utf8');

  const help=runPsc(['--help']);
  assert.equal(help.status,0,help.stderr);
  assert.match(help.stdout,/psc check <entry\.lean\|entry\.ps> --kernel lean434/);

  const accepted=runPsc([
    'check',acceptedEntry,
    '--kernel','lean434',
    '--compiler',compilerPath,
  ]);
  assert.equal(accepted.status,0,accepted.stderr);
  assert.match(accepted.stdout,/PSC2_KERNEL_CHECK: PASS \(lean4-cpp 4\.34\.0/);

  const rejected=runPsc([
    'check',rejectedEntry,
    '--kernel','lean434',
    '--compiler',compilerPath,
  ]);
  assert.notEqual(rejected.status,0);
  assert.match(
    `${rejected.stdout}\n${rejected.stderr}`,
    /PSC2_KERNEL_REJECTED: kernel-rejection at declaration 0/,
  );

  console.log('PSC2_SELFHOST_CLI_KERNEL_CHECK_TESTS: PASS');
} finally {
  await rm(tempRoot,{recursive:true,force:true});
}
