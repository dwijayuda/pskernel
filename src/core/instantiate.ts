import { Expr, looseBVarRange } from './expr.js';

type OffsetCache=WeakMap<object,Map<number,Expr>>;
function cacheGet(cache:OffsetCache,e:Expr,offset:number):Expr|undefined{return cache.get(e as object)?.get(offset);}
function cacheSet(cache:OffsetCache,e:Expr,offset:number,result:Expr):Expr{
  let byOffset=cache.get(e as object);
  if(byOffset===undefined){byOffset=new Map<number,Expr>();cache.set(e as object,byOffset);}
  byOffset.set(offset,result);return result;
}

export function lift(e: Expr, amount = 1, cutoff = 0): Expr {
  // Lean lift_loose_bvars uses cached Expr.Data.looseBVarRange to return closed
  // or cutoff-insensitive subtrees immediately, and replace() memoizes shared
  // source nodes by (pointer, binder offset).
  if(amount===0||cutoff>=looseBVarRange(e))return e;
  type Frame={e:Expr;cutoff:number;done:boolean};
  const todo:Frame[]=[{e,cutoff,done:false}],out:Expr[]=[],cache:OffsetCache=new WeakMap();
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      const cached=cacheGet(cache,x,f.cutoff);if(cached!==undefined){out.push(cached);continue;}
      if(f.cutoff>=looseBVarRange(x)){out.push(cacheSet(cache,x,f.cutoff,x));continue;}
      switch(x.kind){
        case'bvar':out.push(cacheSet(cache,x,f.cutoff,x.index>=f.cutoff?{kind:'bvar',index:x.index+amount}:x));break;
        case'app':todo.push({...f,done:true},{e:x.arg,cutoff:f.cutoff,done:false},{e:x.fn,cutoff:f.cutoff,done:false});break;
        case'lam':case'forall':todo.push({...f,done:true},{e:x.body,cutoff:f.cutoff+1,done:false},{e:x.type,cutoff:f.cutoff,done:false});break;
        case'let':todo.push({...f,done:true},{e:x.body,cutoff:f.cutoff+1,done:false},{e:x.value,cutoff:f.cutoff,done:false},{e:x.type,cutoff:f.cutoff,done:false});break;
        case'mdata':case'proj':todo.push({...f,done:true},{e:x.expr,cutoff:f.cutoff,done:false});break;
        default:out.push(cacheSet(cache,x,f.cutoff,x));break;
      }
      continue;
    }
    let result:Expr;
    switch(x.kind){
      case'app':{const arg=out.pop()!,fn=out.pop()!;result=fn===x.fn&&arg===x.arg?x:{...x,fn,arg};break;}
      case'lam':case'forall':{const body=out.pop()!,type=out.pop()!;result=type===x.type&&body===x.body?x:{...x,type,body};break;}
      case'let':{const body=out.pop()!,value=out.pop()!,type=out.pop()!;result=type===x.type&&value===x.value&&body===x.body?x:{...x,type,value,body};break;}
      case'mdata':case'proj':{const inner=out.pop()!;result=inner===x.expr?x:{...x,expr:inner};break;}
      default:throw new Error('internal lift frame');
    }
    out.push(cacheSet(cache,x,f.cutoff,result));
  }
  if(out.length!==1)throw new Error('internal lift result');
  return out[0]!;
}
export function instantiate(e: Expr, subst: readonly Expr[], depth=0): Expr {
  // Lean instantiate delegates to replace(..., use_cache=true) and skips a
  // subtree whenever its cached loose-bvar range cannot intersect the current
  // substitution offset.
  if(subst.length===0||depth>=looseBVarRange(e))return e;
  type Frame={e:Expr;depth:number;done:boolean};
  const todo:Frame[]=[{e,depth,done:false}],out:Expr[]=[],cache:OffsetCache=new WeakMap();
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      const cached=cacheGet(cache,x,f.depth);if(cached!==undefined){out.push(cached);continue;}
      if(f.depth>=looseBVarRange(x)){out.push(cacheSet(cache,x,f.depth,x));continue;}
      switch(x.kind){
        case'bvar':{
          let result:Expr;
          if(x.index<f.depth)result=x;
          else{
            const j=x.index-f.depth;
            result=j<subst.length?lift(subst[j]!,f.depth,0):{kind:'bvar',index:x.index-subst.length};
          }
          out.push(cacheSet(cache,x,f.depth,result));
          break;
        }
        case'app':todo.push({...f,done:true},{e:x.arg,depth:f.depth,done:false},{e:x.fn,depth:f.depth,done:false});break;
        case'lam':case'forall':todo.push({...f,done:true},{e:x.body,depth:f.depth+1,done:false},{e:x.type,depth:f.depth,done:false});break;
        case'let':todo.push({...f,done:true},{e:x.body,depth:f.depth+1,done:false},{e:x.value,depth:f.depth,done:false},{e:x.type,depth:f.depth,done:false});break;
        case'mdata':case'proj':todo.push({...f,done:true},{e:x.expr,depth:f.depth,done:false});break;
        default:out.push(cacheSet(cache,x,f.depth,x));break;
      }
      continue;
    }
    let result:Expr;
    switch(x.kind){
      case'app':{const arg=out.pop()!,fn=out.pop()!;result=fn===x.fn&&arg===x.arg?x:{...x,fn,arg};break;}
      case'lam':case'forall':{const body=out.pop()!,type=out.pop()!;result=type===x.type&&body===x.body?x:{...x,type,body};break;}
      case'let':{const body=out.pop()!,value=out.pop()!,type=out.pop()!;result=type===x.type&&value===x.value&&body===x.body?x:{...x,type,value,body};break;}
      case'mdata':case'proj':{const inner=out.pop()!;result=inner===x.expr?x:{...x,expr:inner};break;}
      default:throw new Error('internal instantiate frame');
    }
    out.push(cacheSet(cache,x,f.depth,result));
  }
  if(out.length!==1)throw new Error('internal instantiate result');
  return out[0]!;
}
export const instantiate1=(e:Expr,v:Expr)=>instantiate(e,[v]);
export function abstractFVar(e:Expr,id:string,depth=0):Expr{
  // Lean's replace traversal memoizes shared source nodes by binder offset.
  type Frame={e:Expr;depth:number;done:boolean};
  const todo:Frame[]=[{e,depth,done:false}],out:Expr[]=[],cache:OffsetCache=new WeakMap();
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      const cached=cacheGet(cache,x,f.depth);if(cached!==undefined){out.push(cached);continue;}
      switch(x.kind){
        case'fvar':out.push(cacheSet(cache,x,f.depth,x.id===id?{kind:'bvar',index:f.depth}:x));break;
        case'bvar':out.push(cacheSet(cache,x,f.depth,x.index>=f.depth?{kind:'bvar',index:x.index+1}:x));break;
        case'app':todo.push({...f,done:true},{e:x.arg,depth:f.depth,done:false},{e:x.fn,depth:f.depth,done:false});break;
        case'lam':case'forall':todo.push({...f,done:true},{e:x.body,depth:f.depth+1,done:false},{e:x.type,depth:f.depth,done:false});break;
        case'let':todo.push({...f,done:true},{e:x.body,depth:f.depth+1,done:false},{e:x.value,depth:f.depth,done:false},{e:x.type,depth:f.depth,done:false});break;
        case'mdata':case'proj':todo.push({...f,done:true},{e:x.expr,depth:f.depth,done:false});break;
        default:out.push(cacheSet(cache,x,f.depth,x));break;
      }
      continue;
    }
    let result:Expr;
    switch(x.kind){
      case'app':{const arg=out.pop()!,fn=out.pop()!;result=fn===x.fn&&arg===x.arg?x:{...x,fn,arg};break;}
      case'lam':case'forall':{const body=out.pop()!,type=out.pop()!;result=type===x.type&&body===x.body?x:{...x,type,body};break;}
      case'let':{const body=out.pop()!,value=out.pop()!,type=out.pop()!;result=type===x.type&&value===x.value&&body===x.body?x:{...x,type,value,body};break;}
      case'mdata':case'proj':{const inner=out.pop()!;result=inner===x.expr?x:{...x,expr:inner};break;}
      default:throw new Error('internal abstractFVar frame');
    }
    out.push(cacheSet(cache,x,f.depth,result));
  }
  if(out.length!==1)throw new Error('internal abstractFVar result');
  return out[0]!;
}
