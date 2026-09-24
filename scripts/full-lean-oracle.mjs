import {spawn} from 'node:child_process';

const heap=Number(process.env.PSKERNEL_LEAN_HEAP_MIB??'12288');
const stackKiB=Number(process.env.PSKERNEL_LEAN_STACK_KIB??'65500');
if(!Number.isSafeInteger(heap)||heap<2048||!Number.isSafeInteger(stackKiB)||stackKiB<1024)throw new Error('invalid Full Lean runtime limits');
console.error(`[full-lean] canonical module stream; Node heap=${heap} MiB stack=${stackKiB} KiB`);
const child=spawn(process.execPath,['--expose-gc',`--max-old-space-size=${heap}`,`--stack-size=${stackKiB}`,'scripts/module-stream-oracle.mjs','Lean','207969'],{stdio:'inherit',env:process.env});
child.on('close',(code,signal)=>{
  if(signal)console.error(`[full-lean] terminated by ${signal}`);
  process.exit(code??1);
});
