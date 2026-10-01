import {existsSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {join, resolve} from 'node:path';

const expected=/^Lean \(version 4\.34\.0(?:,|\)).*Release\)?$/;
const expectedGitHash='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';
const bins=[process.env.LEAN434_BIN,'/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin'].filter(Boolean).map(p=>resolve(p));
const bin=bins.find(p=>existsSync(join(p,'lean')));
if(!bin){console.error('adversarial-oracle: SKIP/FAIL: set LEAN434_BIN to Lean 4.34.0 bin');process.exit(2);}
const srcCandidates=[process.env.LEAN434_SRC,resolve(bin,'../../../..')].filter(Boolean).map(p=>resolve(p));
const src=srcCandidates.find(p=>existsSync(join(p,'tests/elab/kernelProjIdx.lean')));
if(!src){console.error('adversarial-oracle: SKIP/FAIL: set LEAN434_SRC to the Lean 4.34.0 source tree');process.exit(2);}
const env={...process.env,PATH:`${bin}:${process.env.PATH??''}`};
const run=(args,timeout=12000)=>spawnSync(join(bin,'lean'),args,{cwd:src,env,encoding:'utf8',timeout});
const ver=run(['--version'],5000);
if(ver.error||ver.status!==0||!expected.test(ver.stdout.trim())){console.error(`adversarial-oracle: version mismatch/failure: ${ver.error?.message??ver.stderr??ver.stdout}`);process.exit(1);}
const gh=run(['--githash'],5000);
if(gh.error||gh.status!==0||gh.stdout.trim()!==expectedGitHash){console.error(`adversarial-oracle: git hash mismatch/failure: expected ${expectedGitHash}, got ${gh.error?.message??gh.stderr??gh.stdout}`);process.exit(1);}
const successFiles=[
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
 'tests/elab/kernel_is_prop_ensure_sort.lean',
 'tests/elab/kernel_is_prop_issue.lean',
 'tests/elab/string_neq_kernel_cost.lean',
 'tests/elab/finFoldKernelReduce.lean',
 'tests/elab/decideTacticKernel.lean',
 'tests/elab/skipKernelTC.lean',
 'tests/elab/kernel_maxheartbeats.lean',
 'tests/elab/kernelInterrupt.lean',
];
const rejectionFiles=[
 ['tests/elab_fail/kernelQuotNameCollision.lean', "constant has already been declared 'Quot.lift'"],
];
for(const file of successFiles){
 const r=run([file]);
 if(r.error?.code==='ETIMEDOUT'){console.error(`adversarial-oracle: timeout: ${file}`);process.exit(1);}
 if(r.error||r.status!==0){console.error(`adversarial-oracle: FAIL ${file}\n${r.error?.message??''}\n${r.stdout}\n${r.stderr}`);process.exit(1);}
}
for(const [file,needle] of rejectionFiles){
 const r=run([file]);
 if(r.error?.code==='ETIMEDOUT'){console.error(`adversarial-oracle: timeout: ${file}`);process.exit(1);}
 const output=`${r.stdout}\n${r.stderr}`;
 if(r.error||r.status===0||!output.includes(needle)){
   console.error(`adversarial-oracle: expected rejection mismatch ${file}\n${r.error?.message??''}\n${output}`);
   process.exit(1);
 }
}
console.log(`adversarial-oracle: PASS (${successFiles.length} expected-success + ${rejectionFiles.length} expected-rejection Lean 4.34 kernel regressions)`);
