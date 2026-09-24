import {spawnSync} from 'node:child_process';

const start=Number(process.argv[2]??'0');
const count=Number(process.argv[3]??'250');
const minCount=Number(process.argv[4]??'1');
for(const [name,value] of Object.entries({start,count,minCount})){
  if(!Number.isSafeInteger(value)||value<0||(name!=='start'&&value===0)){
    throw new Error(`std-bisect-oracle: invalid ${name}=${value}`);
  }
}
if(minCount>count)throw new Error('std-bisect-oracle: minCount must be <= count');

const adaptiveScript=process.env.PSKERNEL_ADAPTIVE_ORACLE??'scripts/adaptive-root-oracle.mjs';

const env={
  ...process.env,
  PSKERNEL_WORKER_HEAP_MIB:process.env.PSKERNEL_WORKER_HEAP_MIB??'2048',
  PSKERNEL_WORKER_TIMEOUT_MS:process.env.PSKERNEL_WORKER_TIMEOUT_MS??'60000',
};

const tail=(s,n=12000)=>s.length<=n?s:s.slice(s.length-n);

function check(rangeStart,rangeCount){
  console.error(`[std-bisect] check start=${rangeStart} count=${rangeCount}`);
  const r=spawnSync(
    process.execPath,
    [
      adaptiveScript,
      'Std',
      '114029',
      String(rangeStart),
      String(rangeCount),
      String(rangeCount),
      '1',
    ],
    {
      env,
      encoding:'utf8',
      maxBuffer:32*1024*1024,
    },
  );
  if(r.error)throw r.error;
  return {
    ok:r.status===0&&!r.signal,
    status:r.status,
    signal:r.signal,
    stdout:r.stdout??'',
    stderr:r.stderr??'',
  };
}

function failSummary(rangeStart,rangeCount,result,kind){
  console.error(tail(result.stderr));
  console.log(JSON.stringify({
    ok:false,
    module:'Std',
    diagnostic:'semantic-range-bisection',
    kind,
    start:rangeStart,
    count:rangeCount,
    status:result.status,
    signal:result.signal??null,
    stderrTail:tail(result.stderr,8000),
    stdoutTail:tail(result.stdout,4000),
  },null,2));
  process.exitCode=1;
}

function bisect(rangeStart,rangeCount,knownFailure){
  if(rangeCount<=minCount){
    failSummary(rangeStart,rangeCount,knownFailure,'minimal-failing-range');
    return;
  }

  const leftCount=Math.floor(rangeCount/2);
  const rightCount=rangeCount-leftCount;
  const left=check(rangeStart,leftCount);
  if(!left.ok){
    bisect(rangeStart,leftCount,left);
    return;
  }

  const rightStart=rangeStart+leftCount;
  const right=check(rightStart,rightCount);
  if(!right.ok){
    bisect(rightStart,rightCount,right);
    return;
  }

  failSummary(
    rangeStart,
    rangeCount,
    knownFailure,
    'interaction-failure-not-reproduced-by-halves',
  );
}

const initial=check(start,count);
if(initial.ok){
  console.log(JSON.stringify({
    ok:true,
    module:'Std',
    diagnostic:'semantic-range-bisection',
    start,
    count,
    message:'range passes; no failing root to bisect',
  },null,2));
}else{
  bisect(start,count,initial);
}
