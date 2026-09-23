import type {V061Expr,V061Tactic} from '@proofscript/syntax';
import {
  LocalContext,
  TypeChecker,
  type Expr,
  abstractFVar,
  app,
  fvar,
  instantiate1,
  lam,
  nameFromDotted,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';

export type V061TermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

function elaborateTactic(
  tactic:V061Tactic,
  context:V061CoreElabContext,
  expected:Expr,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );

  if(tactic.kind==='exact'){
    const proof=elaborate(tactic.proof,context,expected);
    if(
      !checker.isDefEq(
        context.metaContext.instantiate(proof.type),
        context.metaContext.instantiate(expected),
      )
    ){
      throw new Error(
        'PS_ELAB_TACTIC_EXACT: proof term does not match the goal',
      );
    }
    return proof;
  }

  if(tactic.kind==='assumption'){
    const candidates=[...context.locals.entries()].reverse();
    for(const [,id] of candidates){
      const declaration=context.localContext.get(id);
      if(
        declaration!==undefined
        &&checker.isDefEq(
          context.metaContext.instantiate(declaration.type),
          context.metaContext.instantiate(expected),
        )
      ){
        return {term:fvar(id),type:declaration.type};
      }
    }
    throw new Error(
      'PS_ELAB_TACTIC_ASSUMPTION: no local hypothesis matches the goal',
    );
  }

  if(tactic.kind==='apply'){
    const candidate=elaborate(tactic.proof,context);
    const functionType=checker.whnf(
      context.metaContext.instantiate(candidate.type),
    );
    if(functionType.kind!=='forall'){
      throw new Error(
        'PS_ELAB_TACTIC_APPLY: candidate is not a forall/function type',
      );
    }
    if(functionType.binderInfo!=='default'){
      throw new Error(
        'PS_ELAB_TACTIC_APPLY: bounded apply requires one explicit premise',
      );
    }
    const premise=elaborateTactic(
      tactic.next,
      context,
      context.metaContext.instantiate(functionType.type),
      elaborate,
    );
    const term=app(candidate.term,premise.term);
    const type=checker.check(term);
    if(
      !checker.isDefEq(
        context.metaContext.instantiate(type),
        context.metaContext.instantiate(expected),
      )
    ){
      throw new Error(
        'PS_ELAB_TACTIC_APPLY: applying one premise does not solve the goal',
      );
    }
    return {term,type};
  }

  const functionType=checker.whnf(
    context.metaContext.instantiate(expected),
  );
  if(functionType.kind!=='forall'){
    throw new Error(
      'PS_ELAB_TACTIC_INTRO: goal is not a forall/function type',
    );
  }

  const nextLocalContext=context.localContext.clone();
  const id=nextLocalContext.fresh(tactic.name);
  const userName=nameFromDotted(tactic.name);
  nextLocalContext.addLocal(
    id,
    userName,
    functionType.type,
    functionType.binderInfo,
  );
  const locals=new Map(context.locals);
  locals.set(tactic.name,id);
  const nextContext={
    ...context,
    localContext:nextLocalContext,
    locals,
  };
  const nextExpected=instantiate1(functionType.body,fvar(id));
  const body=elaborateTactic(
    tactic.next,
    nextContext,
    nextExpected,
    elaborate,
  );

  const term=lam(
    userName,
    functionType.type,
    abstractFVar(body.term,id),
    functionType.binderInfo,
  );
  const type=checker.check(term);
  if(
    !checker.isDefEq(
      context.metaContext.instantiate(type),
      context.metaContext.instantiate(expected),
    )
  ){
    throw new Error(
      'PS_ELAB_TACTIC_INTRO: generated lambda does not match the goal',
    );
  }
  return {term,type};
}

export function elaborateV061ByExpression(
  expr:Extract<V061Expr,{kind:'by'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  if(expected===undefined){
    throw new Error(
      'PS_ELAB_TACTIC_EXPECTED_TYPE: tactic blocks require an expected goal type',
    );
  }
  return elaborateTactic(expr.tactic,context,expected,elaborate);
}
