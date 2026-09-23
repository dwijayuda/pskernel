import {createLeanNativeEvaluator} from './lean-native-evaluator.mjs';
import {nameFromDotted} from '../dist/src/core/name.js';

function assert(x,msg='assertion failed'){if(!x)throw new Error(msg);}
function throws(f){let ok=false;try{f();}catch{ok=true;}assert(ok,'expected exception');}

const calls=[];
const runner=(exe,args)=>{
  calls.push({exe,args});
  const kind=args[3];
  const constant=args[4];
  if(kind==='nat'&&constant==='Demo.n')return {status:0,signal:null,stdout:'{"kind":"nat","value":"42"}\n',stderr:''};
  if(kind==='bool'&&constant==='Demo.b')return {status:0,signal:null,stdout:'{"kind":"bool","value":false}\n',stderr:''};
  return {status:1,signal:null,stdout:'',stderr:'missing synthetic value'};
};
const evaluator=createLeanNativeEvaluator({lean:'/fake/lean',moduleName:'Std',runner});
const n=evaluator.evaluate(null,{kind:'nat',constant:nameFromDotted('Demo.n')});
assert(n.kind==='nat'&&n.value===42n,'Nat result mismatch');
const n2=evaluator.evaluate(null,{kind:'nat',constant:nameFromDotted('Demo.n')});
assert(n2.kind==='nat'&&n2.value===42n,'cached Nat result mismatch');
assert(calls.length===1,'native result must be cached by kind/name');
const b=evaluator.evaluate(null,{kind:'bool',constant:nameFromDotted('Demo.b')});
assert(b.kind==='bool'&&b.value===false,'Bool result mismatch');
assert(calls.length===2,'Bool request must execute once');

const malformed=createLeanNativeEvaluator({
  lean:'/fake/lean',
  moduleName:'Std',
  runner:()=>({status:0,signal:null,stdout:'{"kind":"nat","value":42}\n',stderr:''}),
});
throws(()=>malformed.evaluate(null,{kind:'nat',constant:nameFromDotted('Demo.bad')}));

const failed=createLeanNativeEvaluator({
  lean:'/fake/lean',
  moduleName:'Std',
  runner:()=>({status:1,signal:null,stdout:'',stderr:'boom'}),
});
throws(()=>failed.evaluate(null,{kind:'bool',constant:nameFromDotted('Demo.fail')}));

console.log('ok - cached Lean native oracle provider');
