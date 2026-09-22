import { Expr, appView, mkAppN } from '../../core/expr.js';
import { nameEq } from '../../core/name.js';
import { N } from '../names.js';
export function reduceQuot(e:Expr,whnf:(x:Expr)=>Expr):Expr|null{
  const {fn,args}=appView(e);if(fn.kind!=='const')return null;
  if(nameEq(fn.name,N.QuotLift)){
    if(args.length<6)return null;const q=whnf(args[5]!);const qv=appView(q);if(qv.fn.kind!=='const'||!nameEq(qv.fn.name,N.QuotMk)||qv.args.length<3)return null;
    return mkAppN(args[3]!,[qv.args[2]!,...args.slice(6)]);
  }
  if(nameEq(fn.name,N.QuotInd)){
    if(args.length<5)return null;const q=whnf(args[4]!);const qv=appView(q);if(qv.fn.kind!=='const'||!nameEq(qv.fn.name,N.QuotMk)||qv.args.length<3)return null;
    return mkAppN(args[3]!,[qv.args[2]!,...args.slice(5)]);
  }
  return null;
}
