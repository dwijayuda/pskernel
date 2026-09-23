import {applyTextEdits,processDocument} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
const processor={process:(text:string,previous:number|undefined)=>({state:(previous??0)+1,diagnostics:text.includes('!')?[{severity:'error' as const,message:'bang',start:0,end:1}]:[]})};
const first=processDocument('file.ps',1,'abc',processor);
equal(first.state,1);equal(first.reused,false);
const second=processDocument('file.ps',2,'abc',processor,first);
equal(second.state,1);equal(second.reused,true);
equal(applyTextEdits('abcdef',[{start:1,end:3,text:'X'},{start:5,end:6,text:'Y'}]),'aXdeY');
console.log('ok - @proofscript/language foundation');
