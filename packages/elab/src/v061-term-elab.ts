import type {V061Expr} from '@proofscript/syntax';
import {
  LocalContext,
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
import {v061LocalInstanceTerms} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';
import {elaborateV061ByExpression} from './v061-tactic-elab.js';
import {
  elaborateV061BinaryNotation,
  elaborateV061UnaryNotation,
} from './v061-notation-elab.js';
import {elaborateV061IfExpression} from './v061-if-elab.js';
import {elaborateV061Record} from './v061-structure-term-elab.js';
import {tryElaborateV061ProjectionReference} from './v061-reference-elab.js';
import {elaborateV061MatchExpression} from './v061-match-elab.js';
import {tryElaborateStructuralSelfCall} from './v061-structural-recursion.js';
import {elaborateV061LambdaExpression} from './v061-lambda-elab.js';
import {elaborateV061LetExpression} from './v061-let-elab.js';


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
      const projection=tryElaborateV061ProjectionReference(
        expr.name,
        context,
      );
      if(projection!==undefined)return projection;
      const reference=resolveReference(expr.name,context);
      if(reference.kind==='fvar'){
        return {term:reference,type:checker.check(reference)};
      }
      const applied=elaborateApplication({
        environment:context.environment,
        metaContext:context.metaContext,
        fn:reference,
        args:[],
        ...(expected===undefined?{}:{expectedType:expected}),
        localContext:context.localContext,
        localInstances:v061LocalInstanceTerms(context),
        globalInstances:context.globalInstances,
        classNames:context.classes,
      });
      const elaboratedTerm=context.metaContext.instantiate(applied.term);
      const elaboratedType=context.metaContext.instantiate(applied.type);
      if(hasMVar(elaboratedTerm)||hasMVar(elaboratedType)){
        if(expected===undefined){
          return {term:reference,type:checker.check(reference)};
        }
        throw new Error(
          'PS_ELAB_REFERENCE_STUCK: unresolved implicit or instance arguments',
        );
      }
      return {term:elaboratedTerm,type:elaboratedType};
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
    case 'syntheticHole':
      throw new Error(
        'PS_ELAB_SYNTHETIC_HOLE_OUTSIDE_REFINE: ?_ is accepted only by refine',
      );
    case 'call':{
      const recursive=tryElaborateStructuralSelfCall(
        expr,
        context,
        expected,
      );
      if(recursive!==undefined)return recursive;
      const fn=resolveReference(expr.callee,context);
      const args=expr.args.map(
        (arg)=>elaborateV061Term(arg,context).term,
      );
      const result=elaborateApplication({
        environment:context.environment,
        metaContext:context.metaContext,
        fn,
        args,
        ...(expected===undefined?{}:{expectedType:expected}),
        localContext:context.localContext,
        localInstances:v061LocalInstanceTerms(context),
        globalInstances:context.globalInstances,
        classNames:context.classes,
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
      return elaborateV061UnaryNotation(
        expr,
        context,
        expected,
        elaborateV061Term,
      );
    case 'binary':
      return elaborateV061BinaryNotation(
        expr,
        context,
        expected,
        elaborateV061Term,
      );
    case 'lambda':
      return elaborateV061LambdaExpression(
        expr,
        context,
        expected,
        elaborateV061Term,
      );
    case 'by':
      return elaborateV061ByExpression(expr,context,expected,elaborateV061Term);
    case 'let':
      return elaborateV061LetExpression(
        expr,
        context,
        expected,
        elaborateV061Term,
      );
    case 'if':
      return elaborateV061IfExpression(
        expr,
        context,
        expected,
        elaborateV061Term,
      );
    case 'record':
      return elaborateV061Record(
        expr,
        context,
        expected,
        elaborateV061Term,
      );
    case 'match':
      return elaborateV061MatchExpression(
        expr,
        context,
        expected,
        elaborateV061Term,
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
