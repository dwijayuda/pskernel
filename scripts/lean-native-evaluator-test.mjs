import {createLeanNativeEvaluator} from './lean-native-evaluator.mjs';
import {nameFromDotted} from '../dist/src/core/name.js';

function assert(x,msg='assertion failed'){if(!x)throw new Error(msg);}
function throws(f){let ok=false;try{f();}catch{ok=true;}assert(ok,'expected exception');}

const calls=[];
const runner=(exe,args,options)=>{
  calls.push({exe,args,options});
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
assert(calls[0].options.timeout===60000,'native runner must be bounded by default');
assert(calls[0].options.killSignal==='SIGKILL','native runner timeout must terminate decisively');

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

const timedOut=createLeanNativeEvaluator({
  lean:'/fake/lean',
  moduleName:'Std',
  timeoutMs:1234,
  runner:(_exe,_args,options)=>{
    assert(options.timeout===1234,'explicit native timeout must reach spawnSync');
    const error=new Error('spawnSync /fake/lean ETIMEDOUT'); error.code='ETIMEDOUT';
    return {error,status:null,signal:'SIGKILL',stdout:'',stderr:''};
  },
});
let timeoutMessage='';
try{timedOut.evaluate(null,{kind:'nat',constant:nameFromDotted('Demo.slow')});}catch(e){timeoutMessage=String(e?.message??e);}
assert(timeoutMessage.includes('nat:Demo.slow')&&timeoutMessage.includes('ETIMEDOUT'),'native timeout must fail closed with the exact request key');
throws(()=>createLeanNativeEvaluator({lean:'/fake/lean',moduleName:'Std',timeoutMs:999,runner}));

console.log('ok - cached bounded Lean native oracle provider');
