import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  abstractFVar,
  forallE,
  fvar,
  instantiate1,
  lam,
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';

export type LambdaTermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

export function elaborateV061LambdaExpression(
  expr:Extract<V061Expr,{kind:'lambda'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:LambdaTermElaborator,
):ElaboratedCoreTerm {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  let bodyContext=context;
  let expectedCursor=expected;
  const binders:{
    readonly id:string;
    readonly name:ReturnType<typeof nameFromDotted>;
    readonly type:Expr;
  }[]=[];

  for(const binder of expr.binders){
    const expectedForall=expectedCursor===undefined
      ?undefined
      :checker.whnf(context.metaContext.instantiate(expectedCursor));
    if(expectedForall!==undefined&&expectedForall.kind!=='forall'){
      throw new Error(
        'PS_ELAB_LAMBDA_EXPECTED_FUNCTION: lambda expected type is not a Pi/function type',
      );
    }
    if(
      expectedForall!==undefined
      &&expectedForall.binderInfo!=='default'
    ){
      throw new Error(
        'PS_ELAB_LAMBDA_BINDER_INFO: current lambda syntax only introduces explicit binders',
      );
    }

    const binderType=binder.type===undefined
      ?expectedForall?.type
      :importType(binder.type,bodyContext);
    if(binderType===undefined){
      throw new Error(
        "PS_ELAB_LAMBDA_BINDER_TYPE: cannot infer binder '"+binder.name+
        "' without an expected function type",
      );
    }
    if(
      expectedForall!==undefined
      &&!bodyContext.metaContext.unify(
        bodyContext.metaContext.instantiate(binderType),
        bodyContext.metaContext.instantiate(expectedForall.type),
        bodyContext.localContext,
      )
    ){
      throw new Error(
        "PS_ELAB_LAMBDA_BINDER_TYPE: binder '"+binder.name+
        "' disagrees with the expected Pi domain",
      );
    }

    const next=bodyContext.localContext.clone();
    const id=next.fresh(binder.name);
    const userName=nameFromDotted(binder.name);
    next.addLocal(id,userName,binderType,'default');
    const locals=new Map(bodyContext.locals);
    locals.set(binder.name,id);
    bodyContext={...bodyContext,localContext:next,locals};
    binders.push({id,name:userName,type:binderType});
    expectedCursor=expectedForall===undefined
      ?undefined
      :instantiate1(expectedForall.body,fvar(id));
  }

  const body=elaborate(expr.body,bodyContext,expectedCursor);
  let resultTerm=body.term;
  let resultType=body.type;
  for(let index=binders.length-1;index>=0;index-=1){
    const binder=binders[index]!;
    resultTerm=lam(
      binder.name,
      binder.type,
      abstractFVar(resultTerm,binder.id),
      'default',
    );
    resultType=forallE(
      binder.name,
      binder.type,
      abstractFVar(resultType,binder.id),
      'default',
    );
  }
  if(
    expected!==undefined
    &&!context.metaContext.unify(
      context.metaContext.instantiate(resultType),
      context.metaContext.instantiate(expected),
      context.localContext,
    )
  ){
    throw new Error(
      'PS_ELAB_LAMBDA_TYPE: elaborated lambda does not match expected type',
    );
  }
  return {term:resultTerm,type:resultType};
}

import {elaborateV061Type as importType} from './v061-type-elab.js';
