import {
  bvar,
  exprEq,
  hasLooseBVar,
  type Expr,
} from 'lean-ts-kernel';

export interface RewriteAbstraction {
  readonly body:Expr;
  readonly found:boolean;
}

export function abstractExactRewriteOccurrences(
  expr:Expr,
  pattern:Expr,
):RewriteAbstraction {
  if(hasLooseBVar(pattern)){
    throw new Error(
      'PS_ELAB_TACTIC_RW_PATTERN: rewrite pattern contains a loose bound variable',
    );
  }

  let found=false;
  const go=(value:Expr,depth:number):Expr=>{
    if(exprEq(value,pattern)){
      found=true;
      return bvar(depth);
    }
    switch(value.kind){
      case 'app':
        return {
          ...value,
          fn:go(value.fn,depth),
          arg:go(value.arg,depth),
        };
      case 'lam':
      case 'forall':
        return {
          ...value,
          type:go(value.type,depth),
          body:go(value.body,depth+1),
        };
      case 'let':
        return {
          ...value,
          type:go(value.type,depth),
          value:go(value.value,depth),
          body:go(value.body,depth+1),
        };
      case 'mdata':
      case 'proj':
        return {...value,expr:go(value.expr,depth)};
      default:return value;
    }
  };

  return {body:go(expr,0),found};
}

export function rewriteExprSize(expr:Expr):number {
  switch(expr.kind){
    case 'app':
      return 1+rewriteExprSize(expr.fn)+rewriteExprSize(expr.arg);
    case 'lam':
    case 'forall':
      return 1+rewriteExprSize(expr.type)+rewriteExprSize(expr.body);
    case 'let':
      return 1+rewriteExprSize(expr.type)
        +rewriteExprSize(expr.value)
        +rewriteExprSize(expr.body);
    case 'mdata':
    case 'proj':
      return 1+rewriteExprSize(expr.expr);
    default:return 1;
  }
}

export function exactRewritePatternsOverlap(
  left:Expr,
  right:Expr,
):boolean {
  return abstractExactRewriteOccurrences(left,right).found
    ||abstractExactRewriteOccurrences(right,left).found;
}
