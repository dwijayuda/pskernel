import {spawnSync} from 'node:child_process';

const ranges=[
  [16484,16],
  [18843,16],
  [20000,15],
  [22640,16],
  [25000,15],
  [27515,16],
  [33015,16],
  [36452,16],
  [37609,16],
];

const env={
  ...process.env,
  PSKERNEL_WORKER_HEAP_MIB:process.env.PSKERNEL_WORKER_HEAP_MIB??'2048',
  PSKERNEL_WORKER_TIMEOUT_MS:process.env.PSKERNEL_WORKER_TIMEOUT_MS??'60000',
};

let roots=0;
for(const [start,count] of ranges){
  console.error(`[std-hot] range start=${start} count=${count}`);
  const r=spawnSync(
    process.execPath,
    [
      'scripts/adaptive-root-oracle.mjs',
      'Std',
      '114029',
      String(start),
      String(count),
      String(count),
      '1',
    ],
    {stdio:'inherit',env},
  );
  if(r.error)throw r.error;
  if(r.status!==0||r.signal){
    throw new Error(
      `Std hot range ${start}+${count} failed code=${r.status} signal=${r.signal??'none'}`,
    );
  }
  roots+=count;
}

console.log(JSON.stringify({
  ok:true,
  module:'Std',
  diagnostic:'known-hot-root-ranges',
  ranges:ranges.length,
  directRoots:roots,
},null,2));
