import type {Expr} from 'lean-ts-kernel';
import type {V061CoreElabContext} from './v061-context.js';

function containsFVar(expr:Expr,id:string):boolean {
  switch(expr.kind){
    case 'fvar':return expr.id===id;
    case 'app':
      return containsFVar(expr.fn,id)||containsFVar(expr.arg,id);
    case 'lam':
    case 'forall':
      return containsFVar(expr.type,id)||containsFVar(expr.body,id);
    case 'let':
      return containsFVar(expr.type,id)
        ||containsFVar(expr.value,id)
        ||containsFVar(expr.body,id);
    case 'mdata':
    case 'proj':
      return containsFVar(expr.expr,id);
    default:return false;
  }
}

function assertElimContextIndependent(
  context:V061CoreElabContext,
  majorId:string,
  tactic:'CASES'|'INDUCTION',
):void {
  for(const id of context.locals.values()){
    if(id===majorId)continue;
    const declaration=context.localContext.get(id);
    if(declaration===undefined)continue;
    const depends=containsFVar(declaration.type,majorId)
      ||(
        declaration.kind==='let'
        &&containsFVar(declaration.value,majorId)
      );
    if(depends){
      throw new Error(
        'PS_ELAB_TACTIC_'+tactic+'_DEPENDENT_CONTEXT: another local depends on '+
        'the scrutinee; dependent context substitution is not yet supported',
      );
    }
  }
}

export function assertCasesContextIndependent(
  context:V061CoreElabContext,
  majorId:string,
):void {
  assertElimContextIndependent(context,majorId,'CASES');
}

export function assertInductionContextIndependent(
  context:V061CoreElabContext,
  majorId:string,
):void {
  assertElimContextIndependent(context,majorId,'INDUCTION');
}
