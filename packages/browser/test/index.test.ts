import {CancellationController,CancellationError,verifyStream} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
{
  const progress:number[]=[];
  const result=await verifyStream([1,2,3],{
    createState:()=>({sum:0}),
    push:(state,chunk)=>{state.sum+=chunk;},
    finish:state=>state.sum,
  },{onProgress:p=>progress.push(p.chunks)});
  equal(result,6);
  equal(progress.join(','),'1,2,3');
}
{
  const controller=new CancellationController();
  let caught=false;
  try{
    await verifyStream([1,2,3],{
      createState:()=>({count:0}),
      push:state=>{state.count+=1;},
      finish:state=>state.count,
    },{signal:controller.signal,onProgress:p=>{if(p.chunks===1)controller.abort();}});
  }catch(error){caught=error instanceof CancellationError;}
  equal(caught,true);
}
console.log('ok - @proofscript/browser foundation');
