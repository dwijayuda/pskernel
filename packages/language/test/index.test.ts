import {applyTextEdits,checkV061SoftwareModule,processDocument} from '../src/index.js';
import type {V061Module} from '@proofscript/syntax';
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
    kind:'function',name:'add',terminatedBySemicolon:true,resultType:'Nat',
    params:[{name:'x',type:'Nat',span:s},{name:'y',type:'Nat',span:s}],
    body:{kind:'binary',operator:'+',left:{kind:'reference',name:'x',span:s},right:{kind:'reference',name:'y',span:s},span:s},
    span:s,
  }]};
  const checked=checkV061SoftwareModule(module);
  equal(checked.declarations[0]?.resultType,'Nat');
  equal(checked.declarations[0]?.body.kind,'binary');
}
console.log('ok - @proofscript/language v0.6.1 software checker');
