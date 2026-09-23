import {offsetAt,positionAt,toLspDiagnostics} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
const text='ab\ncd';
const pos=positionAt(text,4);
equal(pos.line,1);equal(pos.character,1);equal(offsetAt(text,pos),4);
const [d]=toLspDiagnostics(text,[{severity:'error',message:'bad',start:3,end:5}]);
equal(d?.severity,1);equal(d?.range.start.line,1);
console.log('ok - @proofscript/lsp foundation');
