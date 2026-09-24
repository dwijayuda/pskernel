import type {V061TypeExpr} from '@proofscript/syntax';
import {
  type Expr,
  forallE,
  fvar,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
  TypeChecker,
  hasMVar,
  exprToString,
  natLit,
  abstractFVar,
} from 'lean-ts-kernel';
import {elaborateApplication} from './application.js';
import {elaborateV061Constant} from './v061-constant-elab.js';
import type {V061CoreElabContext} from './v061-context.js';
import {v061LocalInstanceTerms} from './v061-context.js';
import {
  elaborateV061NatArithmeticTerms,
  elaborateV061NatRelationTerms,
  isV061NatRelation,
} from './v061-nat-notation-elab.js';
import {
  elaborateV061BoolBinaryTerms,
  elaborateV061BoolNotTerm,
  elaborateV061PrimitiveBooleanEqualityTerms,
  isV061BoolBinary,
} from './v061-bool-notation-elab.js';

function elaborateTypePositionApplication(
  fn:Expr,
  args:readonly V061TypeExpr[],
  context:V061CoreElabContext,
  expected?:Expr,
):Expr {
  const source={
    length:args.length,
    elaborate:(index:number,expectedType:Expr)=>({
      term:elaborateV061TypePositionTerm(
        args[index]!,
        context,
        expectedType,
      ),
      type:expectedType,
      allowUnresolvedMVar:true,
    }),
  };
  const applied=elaborateApplication({
    environment:context.environment,
    metaContext:context.metaContext,
    fn,
    args:source,
    ...(expected===undefined?{}:{expectedType:expected}),
    localContext:context.localContext,
    localInstances:v061LocalInstanceTerms(context),
    globalInstances:context.globalInstances,
    classNames:context.classes,
  });
  const term=context.metaContext.instantiate(applied.term);
  const resultType=context.metaContext.instantiate(applied.type);
  if(hasMVar(term)||hasMVar(resultType)){
    if(expected!==undefined){
      // The enclosing Pi binder has already constrained this application's
      // result. Keep shared metas postponed so later sibling arguments can
      // finish solving them; elaborateV061Type still requires a ground term
      // before a declaration type is admitted.
      return term;
    }
    throw new Error(
      'PS_ELAB_TYPE_APPLICATION_STUCK: unresolved implicit/instance '+
      'arguments in '+exprToString(term),
    );
  }
  return term;
}

function elaborateV061TypePositionTerm(
  syntax:V061TypeExpr,
  context:V061CoreElabContext,
  expected?:Expr,
):Expr {
  switch(syntax.kind){
    case 'nat':
      return natLit(BigInt(syntax.text.replaceAll('_','')));
    case 'bool':
      return elaborateV061Constant(
        nameFromDotted(syntax.value?'Bool.true':'Bool.false'),
        context,
      );
    case 'group':
      return elaborateV061TypePositionTerm(syntax.value,context,expected);
    case 'named':{
      if(syntax.name==='Prop')return sort(levelZero);
      if(syntax.name==='Type')return sort(levelSucc(levelZero));
      const local=context.locals.get(syntax.name);
      if(local!==undefined)return fvar(local);
      const name=nameFromDotted(syntax.name);
      if(context.environment.find(name)===undefined){
        throw new Error(
          "PS_ELAB_UNKNOWN_TYPE_TERM: unknown name '"+syntax.name+"'",
        );
      }
      const reference=elaborateV061Constant(name,context);
      if(expected===undefined)return reference;
      return elaborateTypePositionApplication(
        reference,
        [],
        context,
        expected,
      );
    }
    case 'application':
      return elaborateTypePositionApplication(
        elaborateV061TypePositionTerm(syntax.fn,context),
        syntax.args,
        context,
        expected,
      );
    case 'unary':{
      const checker=new TypeChecker(
        context.environment,
        context.localContext.clone(),
      );
      const operand=elaborateV061TypePositionTerm(
        syntax.operand,
        context,
      );
      return elaborateV061BoolNotTerm(
        {term:operand,type:checker.check(operand)},
        context,
      ).term;
    }
    case 'binary':{
      const checker=new TypeChecker(
        context.environment,
        context.localContext.clone(),
      );
      const left=elaborateV061TypePositionTerm(syntax.left,context);
      const right=elaborateV061TypePositionTerm(syntax.right,context);
      const lhs={term:left,type:checker.check(left)};
      const rhs={term:right,type:checker.check(right)};
      if(isV061NatRelation(syntax.operator)){
        return elaborateV061NatRelationTerms(
          syntax.operator,
          lhs,
          rhs,
          context,
        ).term;
      }
      if(isV061BoolBinary(syntax.operator)){
        return elaborateV061BoolBinaryTerms(
          syntax.operator,
          lhs,
          rhs,
          context,
        ).term;
      }
      if(syntax.operator==='=='||syntax.operator==='!='){
        return elaborateV061PrimitiveBooleanEqualityTerms(
          syntax.operator,
          lhs,
          rhs,
          context,
        ).term;
      }
      return elaborateV061NatArithmeticTerms(
        syntax.operator,
        lhs,
        rhs,
        context,
      ).term;
    }
    case 'equality':
      return elaborateTypePositionApplication(
        elaborateV061Constant(nameFromDotted('Eq'),context),
        [syntax.left,syntax.right],
        context,
        expected,
      );
    case 'dependentArrow':{
      const domain=elaborateV061Type(syntax.domain,context);
      const nextLocalContext=context.localContext.clone();
      const id=nextLocalContext.fresh(syntax.name);
      const binderName=nameFromDotted(syntax.name);
      nextLocalContext.addLocal(
        id,
        binderName,
        domain,
        'default',
      );
      const locals=new Map(context.locals);
      locals.set(syntax.name,id);
      const codomain=elaborateV061Type(
        syntax.codomain,
        {...context,localContext:nextLocalContext,locals},
      );
      return forallE(
        binderName,
        domain,
        abstractFVar(codomain,id),
        'default',
      );
    }
    case 'arrow':{
      const domain=elaborateV061Type(syntax.domain,context);
      const codomain=elaborateV061Type(syntax.codomain,context);
      return forallE(
        nameFromDotted('_'),
        domain,
        codomain,
        'default',
      );
    }
  }
}

export function elaborateV061Type(
  syntax:V061TypeExpr,
  context:V061CoreElabContext,
):Expr {
  const term=context.metaContext.instantiate(
    elaborateV061TypePositionTerm(syntax,context),
  );
  if(hasMVar(term)){
    throw new Error(
      'PS_ELAB_TYPE_STUCK: type contains unresolved expression metavariables',
    );
  }
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  checker.ensureSort(checker.check(term),term);
  return term;
}
