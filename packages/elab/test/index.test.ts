import {ElaborationError,admitElaborated,elaborateChecked} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
{
  const term=elaborateChecked({elaborate:(surface:string)=>({term:surface.toUpperCase(),diagnostics:[]})},'x');
  equal(term,'X');
}
{
  let threw=false;
  try{elaborateChecked({elaborate:()=>({diagnostics:[{severity:'error',message:'bad'}]})},'x');}
  catch(error){threw=error instanceof ElaborationError;}
  equal(threw,true);
}
equal(admitElaborated({admit:(e:number,d:number)=>e+d},1,2),3);
console.log('ok - @proofscript/elab foundation');
