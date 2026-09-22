import {spawn} from 'node:child_process';

const heap=Number(process.env.PSKERNEL_STD_HEAP_MIB??'12288');
if(!Number.isSafeInteger(heap)||heap<2048)throw new Error('PSKERNEL_STD_HEAP_MIB must be an integer >= 2048');
console.error(`[full-std] canonical module stream; Node heap=${heap} MiB`);
const child=spawn(process.execPath,['--expose-gc',`--max-old-space-size=${heap}`,'scripts/module-stream-oracle.mjs','Std','114029'],{stdio:'inherit',env:process.env});
child.on('close',(code,signal)=>{
  if(signal)console.error(`[full-std] terminated by ${signal}`);
  process.exit(code??1);
});
