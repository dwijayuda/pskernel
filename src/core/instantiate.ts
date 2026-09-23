import { Expr } from './expr.js';

export function lift(e: Expr, amount = 1, cutoff = 0): Expr {
  // Lean lift_loose_bvars returns the original node when d = 0 or no child changes.
  if(amount===0)return e;
  type Frame={e:Expr;cutoff:number;done:boolean};
  const todo:Frame[]=[{e,cutoff,done:false}],out:Expr[]=[];
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      switch(x.kind){
        case'bvar':out.push(x.index>=f.cutoff?{kind:'bvar',index:x.index+amount}:x);break;
        case'app':todo.push({...f,done:true},{e:x.arg,cutoff:f.cutoff,done:false},{e:x.fn,cutoff:f.cutoff,done:false});break;
        case'lam':case'forall':todo.push({...f,done:true},{e:x.body,cutoff:f.cutoff+1,done:false},{e:x.type,cutoff:f.cutoff,done:false});break;
        case'let':todo.push({...f,done:true},{e:x.body,cutoff:f.cutoff+1,done:false},{e:x.value,cutoff:f.cutoff,done:false},{e:x.type,cutoff:f.cutoff,done:false});break;
        case'mdata':case'proj':todo.push({...f,done:true},{e:x.expr,cutoff:f.cutoff,done:false});break;
        default:out.push(x);break;
      }
      continue;
    }
    switch(x.kind){
      case'app':{const arg=out.pop()!,fn=out.pop()!;out.push(fn===x.fn&&arg===x.arg?x:{...x,fn,arg});break;}
      case'lam':case'forall':{const body=out.pop()!,type=out.pop()!;out.push(type===x.type&&body===x.body?x:{...x,type,body});break;}
      case'let':{const body=out.pop()!,value=out.pop()!,type=out.pop()!;out.push(type===x.type&&value===x.value&&body===x.body?x:{...x,type,value,body});break;}
      case'mdata':case'proj':{const inner=out.pop()!;out.push(inner===x.expr?x:{...x,expr:inner});break;}
      default:throw new Error('internal lift frame');
    }
  }
  if(out.length!==1)throw new Error('internal lift result');
  return out[0]!;
}
export function instantiate(e: Expr, subst: readonly Expr[], depth=0): Expr {
  // Lean instantiate returns the input unchanged for an empty substitution and
  // reuses every composite node whose children were not rewritten.
  if(subst.length===0)return e;
  type Frame={e:Expr;depth:number;done:boolean};
  const todo:Frame[]=[{e,depth,done:false}],out:Expr[]=[];
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      switch(x.kind){
        case'bvar':{
          if(x.index<f.depth){out.push(x);break;}
          const j=x.index-f.depth;
          if(j<subst.length)out.push(lift(subst[j]!,f.depth,0));
          else out.push({kind:'bvar',index:x.index-subst.length});
          break;
        }
        case'app':todo.push({...f,done:true},{e:x.arg,depth:f.depth,done:false},{e:x.fn,depth:f.depth,done:false});break;
        case'lam':case'forall':todo.push({...f,done:true},{e:x.body,depth:f.depth+1,done:false},{e:x.type,depth:f.depth,done:false});break;
        case'let':todo.push({...f,done:true},{e:x.body,depth:f.depth+1,done:false},{e:x.value,depth:f.depth,done:false},{e:x.type,depth:f.depth,done:false});break;
        case'mdata':case'proj':todo.push({...f,done:true},{e:x.expr,depth:f.depth,done:false});break;
        default:out.push(x);break;
      }
      continue;
    }
    switch(x.kind){
      case'app':{const arg=out.pop()!,fn=out.pop()!;out.push(fn===x.fn&&arg===x.arg?x:{...x,fn,arg});break;}
      case'lam':case'forall':{const body=out.pop()!,type=out.pop()!;out.push(type===x.type&&body===x.body?x:{...x,type,body});break;}
      case'let':{const body=out.pop()!,value=out.pop()!,type=out.pop()!;out.push(type===x.type&&value===x.value&&body===x.body?x:{...x,type,value,body});break;}
      case'mdata':case'proj':{const inner=out.pop()!;out.push(inner===x.expr?x:{...x,expr:inner});break;}
      default:throw new Error('internal instantiate frame');
    }
  }
  if(out.length!==1)throw new Error('internal instantiate result');
  return out[0]!;
}
export const instantiate1=(e:Expr,v:Expr)=>instantiate(e,[v]);
export function abstractFVar(e:Expr,id:string,depth=0):Expr{
  type Frame={e:Expr;depth:number;done:boolean};
  const todo:Frame[]=[{e,depth,done:false}],out:Expr[]=[];
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      switch(x.kind){
        case'fvar':out.push(x.id===id?{kind:'bvar',index:f.depth}:x);break;
        case'bvar':out.push(x.index>=f.depth?{kind:'bvar',index:x.index+1}:x);break;
        case'app':todo.push({...f,done:true},{e:x.arg,depth:f.depth,done:false},{e:x.fn,depth:f.depth,done:false});break;
        case'lam':case'forall':todo.push({...f,done:true},{e:x.body,depth:f.depth+1,done:false},{e:x.type,depth:f.depth,done:false});break;
        case'let':todo.push({...f,done:true},{e:x.body,depth:f.depth+1,done:false},{e:x.value,depth:f.depth,done:false},{e:x.type,depth:f.depth,done:false});break;
        case'mdata':case'proj':todo.push({...f,done:true},{e:x.expr,depth:f.depth,done:false});break;
        default:out.push(x);break;
      }
      continue;
    }
    switch(x.kind){
      case'app':{const arg=out.pop()!,fn=out.pop()!;out.push(fn===x.fn&&arg===x.arg?x:{...x,fn,arg});break;}
      case'lam':case'forall':{const body=out.pop()!,type=out.pop()!;out.push(type===x.type&&body===x.body?x:{...x,type,body});break;}
      case'let':{const body=out.pop()!,value=out.pop()!,type=out.pop()!;out.push(type===x.type&&value===x.value&&body===x.body?x:{...x,type,value,body});break;}
      case'mdata':case'proj':{const inner=out.pop()!;out.push(inner===x.expr?x:{...x,expr:inner});break;}
      default:throw new Error('internal abstractFVar frame');
    }
  }
  if(out.length!==1)throw new Error('internal abstractFVar result');
  return out[0]!;
}
