import { Expr } from './expr.js';

export function lift(e: Expr, amount = 1, cutoff = 0): Expr {
  switch(e.kind){
    case'bvar':return e.index>=cutoff?{kind:'bvar',index:e.index+amount}:e;
    case'app':return {...e,fn:lift(e.fn,amount,cutoff),arg:lift(e.arg,amount,cutoff)};
    case'lam':return {...e,type:lift(e.type,amount,cutoff),body:lift(e.body,amount,cutoff+1)};
    case'forall':return {...e,type:lift(e.type,amount,cutoff),body:lift(e.body,amount,cutoff+1)};
    case'let':return {...e,type:lift(e.type,amount,cutoff),value:lift(e.value,amount,cutoff),body:lift(e.body,amount,cutoff+1)};
    case'mdata':return {...e,expr:lift(e.expr,amount,cutoff)};case'proj':return {...e,expr:lift(e.expr,amount,cutoff)};default:return e;
  }
}
export function instantiate(e: Expr, subst: readonly Expr[], depth=0): Expr {
  switch(e.kind){
    case'bvar': { if(e.index<depth)return e; const j=e.index-depth; if(j<subst.length)return lift(subst[j]!,depth,0); return {kind:'bvar',index:e.index-subst.length}; }
    case'app':return {...e,fn:instantiate(e.fn,subst,depth),arg:instantiate(e.arg,subst,depth)};
    case'lam':return {...e,type:instantiate(e.type,subst,depth),body:instantiate(e.body,subst,depth+1)};
    case'forall':return {...e,type:instantiate(e.type,subst,depth),body:instantiate(e.body,subst,depth+1)};
    case'let':return {...e,type:instantiate(e.type,subst,depth),value:instantiate(e.value,subst,depth),body:instantiate(e.body,subst,depth+1)};
    case'mdata':return {...e,expr:instantiate(e.expr,subst,depth)};case'proj':return {...e,expr:instantiate(e.expr,subst,depth)};default:return e;
  }
}
export const instantiate1=(e:Expr,v:Expr)=>instantiate(e,[v]);
export function abstractFVar(e:Expr,id:string,depth=0):Expr{
  switch(e.kind){
    case'fvar':return e.id===id?{kind:'bvar',index:depth}:e;
    case'bvar':return e.index>=depth?{kind:'bvar',index:e.index+1}:e;
    case'app':return {...e,fn:abstractFVar(e.fn,id,depth),arg:abstractFVar(e.arg,id,depth)};
    case'lam':return {...e,type:abstractFVar(e.type,id,depth),body:abstractFVar(e.body,id,depth+1)};
    case'forall':return {...e,type:abstractFVar(e.type,id,depth),body:abstractFVar(e.body,id,depth+1)};
    case'let':return {...e,type:abstractFVar(e.type,id,depth),value:abstractFVar(e.value,id,depth),body:abstractFVar(e.body,id,depth+1)};
    case'mdata':return {...e,expr:abstractFVar(e.expr,id,depth)};case'proj':return {...e,expr:abstractFVar(e.expr,id,depth)};default:return e;
  }
}
