import {freeVariables,validateIrModule} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
{
  const expr={kind:'lambda',params:['x'],body:{kind:'call',fn:{kind:'var',name:'f'},args:[{kind:'var',name:'x'},{kind:'var',name:'y'}]}} as const;
  equal(freeVariables(expr).join(','),'f,y');
}
equal(validateIrModule({name:'M',bindings:[{name:'main',value:{kind:'literal',value:1}}]}),true);
let threw=false;try{validateIrModule({name:'M',bindings:[{name:'x',value:{kind:'literal',value:1}},{name:'x',value:{kind:'literal',value:2}}]});}catch{threw=true;}
equal(threw,true);
console.log('ok - @proofscript/compiler-ir foundation');
