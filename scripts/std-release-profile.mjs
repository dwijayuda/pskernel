import {spawn} from 'node:child_process';
import {resolve,join,delimiter} from 'node:path';
import fs from 'node:fs';

const expected=114029;
const leanExe=process.platform==='win32'?'lean.exe':'lean';
const candidates=[process.env.LEAN434_BIN,...(process.env.PATH??'').split(delimiter)].filter(Boolean).map(resolve);
const bin=candidates.find(p=>fs.existsSync(join(p,leanExe)));
if(!bin)throw new Error('std-release-profile: Lean 4.34 not found');
const lean=join(bin,leanExe);
const baseEnv={...process.env,LEAN434_BIN:bin,PATH:`${bin}${delimiter}${process.env.PATH??''}`};

const windows=[
  [0,64],[10000,64],[20000,64],[30000,64],[40000,64],[50000,64],
  [60000,64],[70000,64],[80000,64],[90000,64],[100000,64],[110000,64]
];
const fullModule=[22197,957];

function run(cmd,args,extraEnv={}){
  return new Promise((resolveRun,reject)=>{
    console.error(`[std-release] RUN ${cmd} ${args.join(' ')}`);
    const p=spawn(cmd,args,{stdio:'inherit',env:{...baseEnv,...extraEnv}});
    p.on('close',(code,signal)=>code===0&&!signal?resolveRun():reject(new Error(`${cmd} failed code=${code} signal=${signal??'none'}`)));
  });
}

await run(process.execPath,['scripts/adaptive-root-oracle.mjs','Std',String(expected),String(fullModule[0]),String(fullModule[1]),'32','1'],{
  PSKERNEL_WORKER_TIMEOUT_MS:'30000',
  PSKERNEL_WORKER_HEAP_MIB:'2048'
});

for(const [start,count] of windows){
  await run(process.execPath,['scripts/adaptive-root-oracle.mjs','Std',String(expected),String(start),String(count),'32','1'],{
    PSKERNEL_WORKER_TIMEOUT_MS:'30000',
    PSKERNEL_WORKER_HEAP_MIB:'2048'
  });
}
console.log(JSON.stringify({
  ok:true,
  profile:'std-release-assurance-v1',
  corpusConstants:expected,
  exhaustiveModule:{name:'Init.Data.Int.DivMod.Lemmas',start:fullModule[0],count:fullModule[1]},
  stratifiedWindows:windows
},null,2));
