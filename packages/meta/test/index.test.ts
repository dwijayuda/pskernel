import {MetaVarContext,checkExpectedType,createGoal} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
{
  const context=new MetaVarContext<string>();
  const goal=createGoal(context,'Nat',[{name:'x',type:'Nat'}]);
  equal(goal.mvar.id,0);
  context.assign(goal.mvar,'x');
  equal(context.getAssignment(goal.mvar),'x');
  let threw=false;
  try{context.assign(goal.mvar,'y');}catch{threw=true;}
  equal(threw,true);
}
{
  const kernel={inferType:(term:string)=>term==='zero'?'Nat':'Unknown',isDefEq:(a:string,b:string)=>a===b};
  equal(checkExpectedType(kernel,'zero','Nat'),true);
}
console.log('ok - @proofscript/meta foundation');
