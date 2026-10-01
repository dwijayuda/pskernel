import {
  LocalContext,
  type Expr,
  app,
} from 'lean-ts-kernel';

export function asMVarId(meta:Expr|string):string {
  if(typeof meta==='string')return meta;
  if(meta.kind!=='mvar')throw new Error('expected metavariable expression');
  return meta.id;
}

export function containsMVarId(expr:Expr,id:string):boolean {
  switch(expr.kind){
    case 'mvar':return expr.id===id;
    case 'app':return containsMVarId(expr.fn,id)||containsMVarId(expr.arg,id);
    case 'lam':
    case 'forall':
      return containsMVarId(expr.type,id)||containsMVarId(expr.body,id);
    case 'let':
      return containsMVarId(expr.type,id)
        ||containsMVarId(expr.value,id)
        ||containsMVarId(expr.body,id);
    case 'mdata':return containsMVarId(expr.expr,id);
    case 'proj':return containsMVarId(expr.expr,id);
    default:return false;
  }
}

export function collectMVarIds(
  expr:Expr,
  out:Set<string>=new Set(),
):ReadonlySet<string> {
  switch(expr.kind){
    case 'mvar':
      out.add(expr.id);
      break;
    case 'app':
      collectMVarIds(expr.fn,out);
      collectMVarIds(expr.arg,out);
      break;
    case 'lam':
    case 'forall':
      collectMVarIds(expr.type,out);
      collectMVarIds(expr.body,out);
      break;
    case 'let':
      collectMVarIds(expr.type,out);
      collectMVarIds(expr.value,out);
      collectMVarIds(expr.body,out);
      break;
    case 'mdata':
    case 'proj':
      collectMVarIds(expr.expr,out);
      break;
    default:
      break;
  }
  return out;
}

export function assertFVarsInScope(expr:Expr,lctx:LocalContext):void {
  const visit=(value:Expr):void=>{
    switch(value.kind){
      case 'fvar':
        if(lctx.get(value.id)===undefined){
          throw new Error(
            "metavariable assignment references out-of-scope free variable '"+value.id+"'",
          );
        }
        return;
      case 'app':
        visit(value.fn);
        visit(value.arg);
        return;
      case 'lam':
      case 'forall':
        visit(value.type);
        visit(value.body);
        return;
      case 'let':
        visit(value.type);
        visit(value.value);
        visit(value.body);
        return;
      case 'mdata':
      case 'proj':
        visit(value.expr);
        return;
      default:
        return;
    }
  };
  visit(expr);
}

export function rebuildExprWith(
  expr:Expr,
  instantiate:(expr:Expr,active:ReadonlySet<string>)=>Expr,
  active:ReadonlySet<string>,
):Expr {
  switch(expr.kind){
    case 'app':return app(
      instantiate(expr.fn,active),
      instantiate(expr.arg,active),
    );
    case 'lam':return {
      ...expr,
      type:instantiate(expr.type,active),
      body:instantiate(expr.body,active),
    };
    case 'forall':return {
      ...expr,
      type:instantiate(expr.type,active),
      body:instantiate(expr.body,active),
    };
    case 'let':return {
      ...expr,
      type:instantiate(expr.type,active),
      value:instantiate(expr.value,active),
      body:instantiate(expr.body,active),
    };
    case 'mdata':return {...expr,expr:instantiate(expr.expr,active)};
    case 'proj':return {...expr,expr:instantiate(expr.expr,active)};
    default:return expr;
  }
}
