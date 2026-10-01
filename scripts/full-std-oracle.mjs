import {spawn} from 'node:child_process';

const heap=Number(process.env.PSKERNEL_STD_HEAP_MIB??'12288');
const stackKiB=Number(process.env.PSKERNEL_STD_STACK_KIB??'65500');
if(!Number.isSafeInteger(heap)||heap<2048||!Number.isSafeInteger(stackKiB)||stackKiB<1024)throw new Error('invalid Full Std runtime limits');
console.error(`[full-std] canonical module stream; Node heap=${heap} MiB stack=${stackKiB} KiB`);
const child=spawn(process.execPath,['--expose-gc',`--max-old-space-size=${heap}`,`--stack-size=${stackKiB}`,'scripts/module-stream-oracle.mjs','Std','114029'],{stdio:'inherit',env:process.env});
child.on('close',(code,signal)=>{
  if(signal)console.error(`[full-std] terminated by ${signal}`);
  process.exit(code??1);
});
