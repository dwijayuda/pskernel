import type {V061Expr} from '@proofscript/syntax';
import {
  LocalContext,
  TypeChecker,
  abstractFVar,
  constant,
  exprToString,
  fvar,
  forallE,
  hasMVar,
  instantiate1,
  lam,
  nameFromDotted,
  natLit,
  strLit,
} from 'lean-ts-kernel';
import {elaborateApplication} from './application.js';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';
import {elaborateV061ByExpression} from './v061-tactic-elab.js';

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
  expected?:import('lean-ts-kernel').Expr,
):ElaboratedCoreTerm {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  switch(expr.kind){
    case 'group':
      return elaborateV061Term(expr.value,context,expected);
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
    case 'lambda':{
      let bodyContext=context;
      let expectedCursor=expected;
      const binders:{
        readonly id:string;
        readonly name:ReturnType<typeof nameFromDotted>;
        readonly type:import('lean-ts-kernel').Expr;
      }[]=[];

      for(const binder of expr.binders){
        const expectedForall=expectedCursor===undefined
          ? undefined
          : checker.whnf(context.metaContext.instantiate(expectedCursor));
        if(
          expectedForall!==undefined
          &&expectedForall.kind!=='forall'
        ){
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
          ? expectedForall?.type
          : elaborateV061Type(binder.type,bodyContext);
        if(binderType===undefined){
          throw new Error(
            "PS_ELAB_LAMBDA_BINDER_TYPE: cannot infer binder '"+binder.name+
            "' without an expected function type",
          );
        }
        if(
          expectedForall!==undefined
          &&!new TypeChecker(
            bodyContext.environment,
            bodyContext.localContext.clone(),
          ).isDefEq(
            bodyContext.metaContext.instantiate(binderType),
            bodyContext.metaContext.instantiate(expectedForall.type),
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
          ? undefined
          : instantiate1(expectedForall.body,fvar(id));
      }

      const body=elaborateV061Term(expr.body,bodyContext,expectedCursor);
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
        &&!checker.isDefEq(
          context.metaContext.instantiate(resultType),
          context.metaContext.instantiate(expected),
        )
      ){
        throw new Error(
          'PS_ELAB_LAMBDA_TYPE: elaborated lambda does not match expected type',
        );
      }
      return {term:resultTerm,type:resultType};
    }
    case 'by':
      return elaborateV061ByExpression(expr,context,expected,elaborateV061Term);
    case 'let':{
      const declaredType=expr.declaredType===undefined
        ? undefined
        : elaborateV061Type(expr.declaredType,context);
      const value=elaborateV061Term(expr.value,context,declaredType);
      const bindingType=declaredType??value.type;
      if(
        declaredType!==undefined
        &&!checker.isDefEq(
          context.metaContext.instantiate(value.type),
          context.metaContext.instantiate(declaredType),
        )
      ){
        throw new Error(
          'PS_ELAB_LET_TYPE: let value does not match its declared type',
        );
      }

      const next=context.localContext.clone();
      const id=next.fresh(expr.name);
      const userName=nameFromDotted(expr.name);
      next.addLet(id,userName,bindingType,value.term);
      const locals=new Map(context.locals);
      locals.set(expr.name,id);
      const bodyContext={...context,localContext:next,locals};
      const body=elaborateV061Term(expr.body,bodyContext,expected);
      const term={
        kind:'let' as const,
        name:userName,
        type:bindingType,
        value:value.term,
        body:abstractFVar(body.term,id),
      };
      const resultType=checker.check(term);
      if(
        expected!==undefined
        &&!checker.isDefEq(
          context.metaContext.instantiate(resultType),
          context.metaContext.instantiate(expected),
        )
      ){
        throw new Error(
          'PS_ELAB_LET_RESULT_TYPE: let expression does not match expected type',
        );
      }
      return {term,type:resultType};
    }
    case 'if':
    case 'record':
    case 'match':
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
