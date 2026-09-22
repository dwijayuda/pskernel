import {existsSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {join, resolve} from 'node:path';

const expected='Lean (version 4.34.0, Release)';
const bins=[process.env.LEAN434_BIN,'/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin'].filter(Boolean).map(p=>resolve(p));
const bin=bins.find(p=>existsSync(join(p,'lean')));
if(!bin){console.error('adversarial-oracle: SKIP/FAIL: set LEAN434_BIN to Lean 4.34.0 bin');process.exit(2);}
const srcCandidates=[process.env.LEAN434_SRC,resolve(bin,'../../../..')].filter(Boolean).map(p=>resolve(p));
const src=srcCandidates.find(p=>existsSync(join(p,'tests/elab/kernelProjIdx.lean')));
if(!src){console.error('adversarial-oracle: SKIP/FAIL: set LEAN434_SRC to the Lean 4.34.0 source tree');process.exit(2);}
const env={...process.env,PATH:`${bin}:${process.env.PATH??''}`};
const run=(args,timeout=12000)=>spawnSync(join(bin,'lean'),args,{cwd:src,env,encoding:'utf8',timeout});
const ver=run(['--version'],5000);
if(ver.error||ver.status!==0||ver.stdout.trim()!==expected){console.error(`adversarial-oracle: version mismatch/failure: ${ver.error?.message??ver.stderr??ver.stdout}`);process.exit(1);}
const files=[
 'tests/elab/kernelProjIdx.lean',
 'tests/elab/kernelProjSname.lean',
 'tests/elab/kernelNestedAuxName.lean',
 'tests/elab/kernelMutualDupName.lean',
 'tests/elab/kernelImaxPropInductive.lean',
 'tests/elab/kernel_is_def_eq_equiv_manager_1.lean',
 'tests/elab/kernel_is_def_eq_equiv_manager_2.lean',
 'tests/elab/kernel1.lean',
 'tests/elab/kernel2.lean',
 'tests/elab/kernelImaxProp.lean',
 'tests/elab/kernelMaxRecDepth.lean',
 'tests/elab/kernelErrorFollowup.lean',
 'tests/elab/kernelBacktrack.lean',
];
for(const file of files){
 const r=run([file]);
 if(r.error?.code==='ETIMEDOUT'){console.error(`adversarial-oracle: timeout: ${file}`);process.exit(1);}
 if(r.error||r.status!==0){console.error(`adversarial-oracle: FAIL ${file}\n${r.error?.message??''}\n${r.stdout}\n${r.stderr}`);process.exit(1);}
}
console.log(`adversarial-oracle: PASS (${files.length}/${files.length} Lean 4.34 kernel regression files)`);
