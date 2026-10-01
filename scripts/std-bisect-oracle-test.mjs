import {mkdtempSync,rmSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {spawnSync} from 'node:child_process';

const tmp=mkdtempSync(join(tmpdir(),'pskernel-std-bisect-test-'));
const fake=join(tmp,'fake-adaptive.mjs');
writeFileSync(fake,`
const mode=process.env.PSKERNEL_TEST_MODE;
const start=Number(process.argv[4]);
const count=Number(process.argv[5]);
const containsFive=start<=5&&5<start+count;
if(mode==='single'&&containsFive){
  console.error('synthetic semantic failure at root 5');
  process.exit(1);
}
if(mode==='interaction'&&start===0&&count===8){
  console.error('synthetic interaction failure');
  process.exit(1);
}
console.log(JSON.stringify({ok:true,start,count}));
`);

function run(mode){
  return spawnSync(
    process.execPath,
    [resolve('scripts/std-bisect-oracle.mjs'),'0','8','1'],
    {
      env:{
        ...process.env,
        PSKERNEL_ADAPTIVE_ORACLE:fake,
        PSKERNEL_TEST_MODE:mode,
      },
      encoding:'utf8',
      maxBuffer:4*1024*1024,
    },
  );
}

function summary(result){
  const text=(result.stdout??'').trim();
  if(!text)throw new Error('missing bisector summary');
  return JSON.parse(text);
}

try{
  {
    const r=run('single');
    if(r.status!==1)throw new Error(`single failure exit ${r.status}`);
    const s=summary(r);
    if(
      s.kind!=='minimal-failing-range'
      ||s.start!==5
      ||s.count!==1
    ){
      throw new Error('single-root bisection did not isolate root 5');
    }
  }

  {
    const r=run('interaction');
    if(r.status!==1)throw new Error(`interaction exit ${r.status}`);
    const s=summary(r);
    if(
      s.kind!=='interaction-failure-not-reproduced-by-halves'
      ||s.start!==0
      ||s.count!==8
    ){
      throw new Error('interaction failure was incorrectly attributed');
    }
  }

  {
    const r=run('pass');
    if(r.status!==0)throw new Error(`passing range exit ${r.status}`);
    const s=summary(r);
    if(s.ok!==true||s.start!==0||s.count!==8){
      throw new Error('passing range summary mismatch');
    }
  }

  console.log('ok - Std semantic bisection tool');
} finally {
  rmSync(tmp,{recursive:true,force:true});
}
