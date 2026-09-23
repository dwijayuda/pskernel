import {freeVariables,lowerCheckedSoftwareModule,validateIrModule} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
{
  const expr={kind:'lambda',params:['x'],body:{kind:'call',fn:{kind:'var',name:'f'},args:[{kind:'var',name:'x'},{kind:'var',name:'y'}]}} as const;
  equal(freeVariables(expr).join(','),'f,y');
}
equal(validateIrModule({name:'M',bindings:[{name:'main',value:{kind:'literal',value:1}}]}),true);
let threw=false;try{validateIrModule({name:'M',bindings:[{name:'x',value:{kind:'literal',value:1}},{name:'x',value:{kind:'literal',value:2}}]});}catch{threw=true;}
equal(threw,true);
console.log('ok - @proofscript/compiler-ir foundation');

{
  const ir=lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    declarations:[{
      kind:'function',
      name:'incTwice',
      params:[{name:'x',type:'Nat'}],
      resultType:'Nat',
      body:{
        kind:'let',name:'y',declaredType:'Nat',resultType:'Nat',
        value:{kind:'binary',operator:'+',resultType:'Nat',left:{kind:'reference',name:'x',resultType:'Nat'},right:{kind:'nat',value:1n,resultType:'Nat'}},
        body:{kind:'binary',operator:'+',resultType:'Nat',left:{kind:'reference',name:'y',resultType:'Nat'},right:{kind:'nat',value:1n,resultType:'Nat'}},
      },
    }],
  });
  equal(ir.kind,'proofscript-software-ir');
  equal(ir.declarations[0]?.body.kind,'let');
}
console.log('ok - @proofscript/compiler-ir software lowering');

{
  const ir=lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    declarations:[{
      kind:'const',name:'increment',params:[],
      resultType:{kind:'function',parameter:'Nat',result:'Nat'},
      body:{
        kind:'lambda',
        binders:[{name:'x',type:'Nat'}],
        resultType:{kind:'function',parameter:'Nat',result:'Nat'},
        body:{
          kind:'binary',operator:'+',resultType:'Nat',
          left:{kind:'reference',name:'x',resultType:'Nat'},
          right:{kind:'nat',value:1n,resultType:'Nat'},
        },
      },
    }],
  });
  equal(ir.declarations[0]?.body.kind,'lambda');
}
console.log('ok - @proofscript/compiler-ir software lambda lowering');
