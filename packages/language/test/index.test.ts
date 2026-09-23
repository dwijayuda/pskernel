import {applyTextEdits,checkV061SoftwareModule,processDocument} from '../src/index.js';
import {parseV061Module,type V061Module} from '@proofscript/syntax';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
const processor={process:(text:string,previous:number|undefined)=>({state:(previous??0)+1,diagnostics:text.includes('!')?[{severity:'error' as const,message:'bang',start:0,end:1}]:[]})};
const first=processDocument('file.ps',1,'abc',processor);
equal(first.state,1);equal(first.reused,false);
const second=processDocument('file.ps',2,'abc',processor,first);
equal(second.state,1);equal(second.reused,true);
equal(applyTextEdits('abcdef',[{start:1,end:3,text:'X'},{start:5,end:6,text:'Y'}]),'aXdeY');
console.log('ok - @proofscript/language foundation');

{
  const z={offset:0,line:1,column:1};
  const s={start:z,end:z};
  const module:V061Module={kind:'v061-module',featureIds:[],declarations:[{
    kind:'function',name:'add',terminatedBySemicolon:true,resultType:{kind:'named',name:'Nat',span:s},
    params:[{name:'x',type:{kind:'named',name:'Nat',span:s},span:s},{name:'y',type:{kind:'named',name:'Nat',span:s},span:s}],
    body:{kind:'binary',operator:'+',left:{kind:'reference',name:'x',span:s},right:{kind:'reference',name:'y',span:s},span:s},
    span:s,
  }]};
  const checked=checkV061SoftwareModule(module);
  equal(checked.declarations[0]?.resultType,'Nat');
  equal(checked.declarations[0]?.body.kind,'binary');
}
console.log('ok - @proofscript/language v0.6.1 software checker');

{
  const z={offset:0,line:1,column:1};
  const s={start:z,end:z};
  const module:V061Module={kind:'v061-module',featureIds:[],declarations:[{
    kind:'function',name:'incTwice',terminatedBySemicolon:true,resultType:{kind:'named',name:'Nat',span:s},
    params:[{name:'x',type:{kind:'named',name:'Nat',span:s},span:s}],
    body:{
      kind:'let',name:'y',declaredType:{kind:'named',name:'Nat',span:s},
      value:{kind:'binary',operator:'+',left:{kind:'reference',name:'x',span:s},right:{kind:'nat',text:'1',span:s},span:s},
      body:{kind:'binary',operator:'+',left:{kind:'reference',name:'y',span:s},right:{kind:'nat',text:'1',span:s},span:s},
      span:s,
    },
    span:s,
  }]};
  const checked=checkV061SoftwareModule(module);
  const body=checked.declarations[0]?.body;
  equal(body?.kind,'let');
  if(body?.kind==='let'){
    equal(body.value.resultType,'Nat');
    equal(body.body.resultType,'Nat');
  }
}
{
  const z={offset:0,line:1,column:1};
  const s={start:z,end:z};
  const bad:V061Module={kind:'v061-module',featureIds:[],declarations:[{
    kind:'const',name:'bad',terminatedBySemicolon:true,resultType:{kind:'named',name:'Nat',span:s},params:[],
    body:{kind:'let',name:'y',declaredType:{kind:'named',name:'Bool',span:s},value:{kind:'nat',text:'1',span:s},body:{kind:'nat',text:'2',span:s},span:s},
    span:s,
  }]};
  let threw=false;
  try{checkV061SoftwareModule(bad);}catch(error){threw=/PS_CHECK_LET_TYPE/.test(String(error));}
  equal(threw,true);
}
console.log('ok - @proofscript/language lexical let checker');

{
  const z={offset:0,line:1,column:1};
  const s={start:z,end:z};
  const module:V061Module={kind:'v061-module',featureIds:[],declarations:[{
    kind:'const',name:'f',terminatedBySemicolon:true,params:[],
    resultType:{kind:'arrow',domain:{kind:'named',name:'Nat',span:s},codomain:{kind:'named',name:'Nat',span:s},span:s},
    body:{kind:'nat',text:'1',span:s},
    span:s,
  }]};
  let threw=false;
  try{checkV061SoftwareModule(module);}catch(error){threw=/PS_CHECK_DECL_TYPE/.test(String(error));}
  equal(threw,true);
}
console.log('ok - @proofscript/language function type HIR conversion');

{
  const checked=checkV061SoftwareModule(parseV061Module(
    'const increment : Nat -> Nat := fun x => x + 1; function main(x : Nat) : Nat := increment(x);',
  ));
  const increment=checked.declarations[0]?.body;
  equal(increment?.kind,'lambda');
  if(increment?.kind==='lambda'){
    equal(increment.binders[0]?.type,'Nat');
    equal(typeof increment.resultType,'object');
  }
  const call=checked.declarations[1]?.body;
  equal(call?.kind,'call');
  if(call?.kind==='call')equal(call.callStyle,'curried');
}
{
  const checked=checkV061SoftwareModule(parseV061Module(
    'const addFn : Nat -> Nat -> Nat := fun (x : Nat) (y : Nat) => x + y;',
  ));
  equal(checked.declarations[0]?.body.kind,'lambda');
}
{
  let threw=false;
  try{
    checkV061SoftwareModule(parseV061Module(
      'const bad : Nat -> Nat := fun (x : Bool) => 1;',
    ));
  }catch(error){threw=/PS_CHECK_LAMBDA_BINDER_TYPE/.test(String(error));}
  equal(threw,true);
}
console.log('ok - @proofscript/language reference-backed lambda checker');

{
  const checked=checkV061SoftwareModule(parseV061Module(
    'const run : Unit -> Nat := fun u => 7; const answer : Nat := run();',
  ));
  const call=checked.declarations[1]?.body;
  equal(call?.kind,'call');
  if(call?.kind==='call'){
    equal(call.args.length,1);
    equal(call.args[0]?.kind,'unit');
    equal(call.callStyle,'curried');
  }
}
console.log('ok - @proofscript/language empty D-CALL Unit semantics');
