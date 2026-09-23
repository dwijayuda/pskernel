import {assumption,exact,intro} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
const kernel={inferType:(term:string)=>term.startsWith('proof:')?term.slice(6):'?',isDefEq:(a:string,b:string)=>a===b};
{
  const state={goals:[{target:'P',locals:[]}],proofs:[] as string[]};
  const next=exact(state,'proof:P',kernel);
  equal(next.goals.length,0);equal(next.proofs[0],'proof:P');
}
{
  const state={goals:[{target:'P',locals:[{name:'h',type:'P',value:'proof:P'}]}],proofs:[] as string[]};
  equal(assumption(state,kernel).goals.length,0);
}
{
  const state={goals:[{target:'A->B',locals:[]}],proofs:[] as string[]};
  const next=intro(state,{intro:t=>t==='A->B'?{name:'a',type:'A',body:'B'}:undefined});
  equal(next.goals[0]?.target,'B');equal(next.goals[0]?.locals[0]?.name,'a');
}
console.log('ok - @proofscript/tactic foundation');
