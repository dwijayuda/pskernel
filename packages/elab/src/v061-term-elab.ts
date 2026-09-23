import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  constant,
  exprToString,
  fvar,
  hasMVar,
  nameFromDotted,
  natLit,
  strLit,
} from 'lean-ts-kernel';
import {elaborateApplication} from './application.js';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';

function resolveReference(
  name:string,
  context:V061CoreElabContext,
):ReturnType<typeof constant>|ReturnType<typeof fvar> {
  const local=context.locals.get(name);
  if(local!==undefined)return fvar(local);
  const full=nameFromDotted(name);
  if(context.environment.find(full)===undefined){
    throw new Error("PS_ELAB_UNKNOWN_NAME: unknown name '"+name+"'");
  }
  return constant(full);
}

export function elaborateV061Term(
  expr:V061Expr,
  context:V061CoreElabContext,
):ElaboratedCoreTerm {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  switch(expr.kind){
    case 'group':
      return elaborateV061Term(expr.value,context);
    case 'reference':{
      const term=resolveReference(expr.name,context);
      return {term,type:checker.check(term)};
    }
    case 'nat':{
      const term=natLit(BigInt(expr.text.replaceAll('_','')));
      return {term,type:checker.check(term)};
    }
    case 'string':{
      const term=strLit(expr.value);
      return {term,type:checker.check(term)};
    }
    case 'bool':{
      const term=resolveReference(
        expr.value?'Bool.true':'Bool.false',
        context,
      );
      return {term,type:checker.check(term)};
    }
    case 'unit':{
      const term=resolveReference('Unit.unit',context);
      return {term,type:checker.check(term)};
    }
    case 'call':{
      const fn=resolveReference(expr.callee,context);
      const args=expr.args.map(
        (arg)=>elaborateV061Term(arg,context).term,
      );
      const result=elaborateApplication({
        environment:context.environment,
        metaContext:context.metaContext,
        fn,
        args,
        localContext:context.localContext,
      });
      const term=context.metaContext.instantiate(result.term);
      const type=context.metaContext.instantiate(result.type);
      if(hasMVar(term)||hasMVar(type)){
        throw new Error(
          'PS_ELAB_UNSOLVED_METAVARS: application leaves unresolved implicit or instance obligations',
        );
      }
      return {term,type};
    }
    case 'unary':
    case 'binary':
      throw new Error(
        'PS_ELAB_NOTATION_UNSUPPORTED: operators require Lean-compatible notation/typeclass elaboration',
      );
    case 'if':
    case 'lambda':
    case 'record':
    case 'match':
    case 'let':
      throw new Error(
        "PS_ELAB_TERM_UNSUPPORTED: term form '"+expr.kind+
        "' is not yet implemented by the kernel-facing elaborator",
      );
  }
}

export function checkElaboratedTerm(
  result:ElaboratedCoreTerm,
  expected:import('lean-ts-kernel').Expr,
  context:V061CoreElabContext,
):void {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  if(!checker.isDefEq(result.type,expected)){
    throw new Error(
      'PS_ELAB_TYPE_MISMATCH: expected '+exprToString(expected)+
      ', got '+exprToString(result.type),
    );
  }
}
