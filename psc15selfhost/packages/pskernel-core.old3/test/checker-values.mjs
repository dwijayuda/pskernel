// Test adapters only. All semantic transitions execute PSC-generated code.
import { k, tag, nil, list, expression, pname, naturalValue } from './binding-values.mjs';
import { runtimeName } from './fixture-values.mjs';
import { decodeLevel, decodeName } from './universe-values.mjs';
export { k, tag, nil, list, expression, pname };
export const B=i=>['b',String(i)], Z=['zero'], S=l=>['succ',l];
export const level=n=>n===0?Z:S(level(n-1));
export const U=n=>['sort',level(n)];
export const Pi=(n,a,b,bi='explicit')=>['pi',pname(n),a,b,bi];
export const Lam=(n,a,b,bi='explicit')=>['lam',pname(n),a,b,bi];
export const App=(f,...as)=>as.reduce((x,a)=>['app',x,a],f);
export const Let=(n,t,v,b)=>['let',pname(n),t,v,b];
export const C=n=>['const',pname(n),[]];
export const def=(name,type,value)=>({name,type,value});
export const definition=d=>k.PsKernelDefinition.definition(runtimeName(k,pname(d.name)),expression(d.type),expression(d.value));
export function drive(step,state,budget=200000){
  if(!Number.isSafeInteger(budget)||budget<0)throw Error('INVALID_TEST_BUDGET');
  for(let i=0;i<budget;i++){
    const out=step(state);
    if(tag(out)==='final')return{status:tag(out.result),error:out.result.error&&tag(out.result.error),result:out.result,steps:i+1};
    if(tag(out)!=='next')throw Error('INVALID_MACHINE_STEP');
    state=out.state;
  }
  return{status:'outOfFuel',steps:budget};
}
export const infer=(value,env=nil(),budget=200000)=>drive(k.psKernelTypeStep,k.psKernelInferStart(env,expression(value)),budget);
export const check=(value,type,env=nil(),budget=200000)=>drive(k.psKernelTypeStep,k.psKernelCheckStart(env,expression(value),expression(type)),budget);
export const admit=(defs,budget=200000)=>drive(k.psKernelAdmissionStep,k.psKernelAdmissionStart(list(defs.map(definition))),budget);
export const normal=(value,env=nil(),budget=200000)=>drive(k.psKernelReduceStep,k.psKernelNormalStart(env,expression(value)),budget);
export const convert=(a,b,env=nil(),budget=200000)=>drive(k.psKernelConversionStep,k.psKernelConversionStart(env,expression(a),expression(b)),budget);
export function decodeExpr(x){switch(tag(x)){
  case'bvar':return B(naturalValue(x.index));
  case'fvar':return['f',String(naturalValue(x.id))];
  case'sortE':return['sort',decodeLevel(x.level)];
  case'constE':{const levels=[];let q=x.levels;while(tag(q)!=='nil'){levels.push(decodeLevel(q.head));q=q.tail;}return['const',decodeName(x.name),levels];}
  case'app':return['app',decodeExpr(x.fn),decodeExpr(x.arg)];
  case'lam':case'forallE':return[tag(x)==='lam'?'lam':'pi',decodeName(x.name),decodeExpr(x.type),decodeExpr(x.body),tag(x.binder)];
  case'letE':return['let',decodeName(x.name),decodeExpr(x.type),decodeExpr(x.value),decodeExpr(x.body)];
  default:throw Error('UNSUPPORTED_TEST_DECODE:'+tag(x));
}}
export const identityType=n=>Pi('A',U(n),Pi('x',B(0),B(1)));
export const identity=n=>Lam('A',U(n),Lam('x',B(0),B(0)));
