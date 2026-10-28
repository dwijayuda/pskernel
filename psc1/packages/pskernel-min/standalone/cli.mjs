#!/usr/bin/env node
import fs from 'node:fs/promises';
import {constants} from 'node:fs';
import crypto from 'node:crypto';
import {Worker} from 'node:worker_threads';
import {fileURLToPath} from 'node:url';
import build from './metadata.mjs';

const maxBytes=2*1024*1024,workerOldSpaceMiB=256,workerTimeoutMs=120000;
const usage='pskernel-min check <packet.json|-> [--transport-lf]\npskernel-min info\npskernel-min examples\n';
const emit=value=>process.stdout.write(JSON.stringify(value)+'\n');
const failure=(code,detail)=>({schema:'pskernel-min/check/1',profile:'psc1-min-core-regular/1',
 accepted:false,code,delegated:false,...(detail?{detail}:{})});
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function readBounded(file,cap){
 const chunks=[];let count=0;
 const add=chunk=>{count+=chunk.length;if(count>cap)throw Object.assign(Error('input exceeds byte budget'),{budget:true,observedBytesAtLeast:count});chunks.push(Buffer.from(chunk));};
 if(file==='-'){for await(const chunk of process.stdin)add(chunk);}
 else{
  const handle=await fs.open(file,constants.O_RDONLY|constants.O_NONBLOCK);
  try{
   const stat=await handle.stat();if(!stat.isFile())throw Error('input must be a regular file');
   if(stat.size>cap)throw Object.assign(Error('input exceeds byte budget'),{budget:true,observedBytesAtLeast:stat.size});
   const buffer=Buffer.alloc(65536);
   while(true){const {bytesRead}=await handle.read(buffer,0,buffer.length,null);if(bytesRead===0)break;add(buffer.subarray(0,bytesRead));}
  }finally{await handle.close();}
 }
 return Buffer.concat(chunks,count);
}
async function runCheck(bytes){
 return new Promise(resolve=>{
  const worker=new Worker(new URL('./worker.mjs',import.meta.url),{
   workerData:bytes,resourceLimits:{maxOldGenerationSizeMb:workerOldSpaceMiB}});
  let done=false;
  const finish=value=>{if(done)return;done=true;clearTimeout(timer);worker.terminate().catch(()=>{});resolve(value);};
  const timer=setTimeout(()=>finish(failure('PSC1_MIN_RESOURCE_TIMEOUT','checker exceeded 120 seconds')),workerTimeoutMs);
  worker.once('message',finish);
  worker.once('error',error=>finish(failure(error.code==='ERR_WORKER_OUT_OF_MEMORY'?'PSC1_MIN_RESOURCE_MEMORY':'PSC1_MIN_CLI_WORKER_ERROR',error.message)));
  worker.once('exit',code=>{if(!done)finish(failure('PSC1_MIN_CLI_WORKER_EXIT',String(code)));});
 });
}
async function main(){
 const args=process.argv.slice(2);
 if(args.length===1&&(args[0]==='--help'||args[0]==='-h')){process.stdout.write(usage);return;}
 if(args.length===1&&args[0]==='--version'){process.stdout.write(build.version+'\n');return;}
 if(args.length===1&&args[0]==='info'){emit({...build,workerOldSpaceMiB,workerTimeoutMs,maxBytes});return;}
 if(args.length===1&&args[0]==='examples'){
  emit({examples:['nat-definition','regular-tree-fold','negative-self'].map(name=>({
   name,file:fileURLToPath(new URL('./examples/'+name+'.json',import.meta.url))}))});return;
 }
 if(args[0]!=='check'||args.length<2||args.length>3||args[1].startsWith('--')||
   (args.length===3&&args[2]!=='--transport-lf')){
  emit(failure('PSC1_MIN_CLI_USAGE',usage));process.exitCode=2;return;
 }
 let input;
 try{input=await readBounded(args[1],maxBytes+(args[2]==='--transport-lf'?1:0));}
 catch(error){emit(failure(error.budget?'PSC1_MIN_CORE_BYTE_BUDGET':'PSC1_MIN_CLI_IO',
  error.budget?'observed at least '+error.observedBytesAtLeast+' input bytes':error.message));
  process.exitCode=error.budget?1:2;return;}
 let checked=input,removedTerminalLF=false;
 if(args[2]==='--transport-lf'&&input.at(-1)===10){checked=input.subarray(0,-1);removedTerminalLF=true;}
 const result=await runCheck(new Uint8Array(checked));
 emit({...result,input:{byteLength:input.length,sha256:hash(input)},
  checked:{byteLength:checked.length,sha256:hash(checked)},removedTerminalLF});
 process.exitCode=result.accepted?0:result.code.startsWith('PSC1_MIN_CLI_')?2:1;
}
main().catch(error=>{emit(failure('PSC1_MIN_CLI_IO',error.message));process.exitCode=2;});
