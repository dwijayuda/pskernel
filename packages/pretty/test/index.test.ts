import {concat,group,indent,line,render,renderDiagnostic,text} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
{
  const doc=group(concat(text('f('),indent(2,concat(line,text('x,'),line,text('y'))),line,text(')')));
  equal(render(doc,80),'f( x, y )');
  equal(render(doc,5),'f(\n  x,\n  y\n)');
}
equal(renderDiagnostic({severity:'error',message:'bad term',line:2,column:4}),'ERROR:2:4: bad term');
console.log('ok - @proofscript/pretty foundation');
