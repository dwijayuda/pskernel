import type {V061Expr} from '@proofscript/syntax';
import type {Expr} from 'lean-ts-kernel';
import {
  LocalContext,
  TypeChecker,
  app,
  appView,
  constant,
  exprToString,
  fvar,
  hasMVar,
  nameFromDotted,
  nameToString,
  natLit,
  strLit,
} from 'lean-ts-kernel';
import {elaborateApplication} from './application.js';
import {elaborateV061Constant} from './v061-constant-elab.js';
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
  expected?:Expr,
):ReturnType<typeof constant>|ReturnType<typeof fvar> {
  const local=context.locals.get(name);
  if(local!==undefined)return fvar(local);

  if(name.startsWith('.')){
    if(expected===undefined){
      throw new Error(
        "PS_ELAB_CONSTRUCTOR_SHORTHAND_EXPECTED: constructor shorthand '"+
        name+"' requires an expected inductive type",
      );
    }
    const checker=new TypeChecker(
      context.environment,
      context.localContext.clone(),
    );
    const resolvedExpected=context.metaContext.instantiate(expected);
    const view=appView(checker.whnf(resolvedExpected));
    if(view.fn.kind!=='const'){
      throw new Error(
        "PS_ELAB_CONSTRUCTOR_SHORTHAND_EXPECTED: expected type is not inductive for '"+
        name+"'",
      );
    }
    const inductive=context.environment.find(view.fn.name);
    if(inductive?.kind!=='inductive'){
      throw new Error(
        "PS_ELAB_CONSTRUCTOR_SHORTHAND_EXPECTED: expected type is not inductive for '"+
        name+"'",
      );
    }
    const suffix=name.slice(1);
    const constructor=inductive.ctors.find((candidate)=>{
      const rendered=nameToString(candidate);
      const parts=rendered.split('.');
      return parts[parts.length-1]===suffix;
    });
    if(constructor===undefined){
      throw new Error(
        "PS_ELAB_CONSTRUCTOR_SHORTHAND: no constructor '"+
        name+"' for "+nameToString(inductive.name),
      );
    }
    return elaborateV061Constant(constructor,context);
  }

  const full=nameFromDotted(name);
  if(context.environment.find(full)===undefined){
    throw new Error("PS_ELAB_UNKNOWN_NAME: unknown name '"+name+"'");
  }
  return elaborateV061Constant(full,context);
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
      const reference=resolveReference(expr.name,context,expected);
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
        // An enclosing application may legitimately solve a nullary generic
        // constructor's inserted metas from a later explicit argument/result.
        // Keep them in the shared Meta context; the enclosing application and
        // declaration still require full grounding before admission.
        return {term:elaboratedTerm,type:elaboratedType};
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
    case 'char':{
      const codePoint=expr.value.codePointAt(0);
      if(codePoint===undefined||[...expr.value].length!==1){
        throw new Error(
          'PS_ELAB_CHAR_LITERAL: expected exactly one Unicode scalar value',
        );
      }
      const term=app(
        resolveReference('Char.ofNat',context),
        natLit(BigInt(codePoint)),
      );
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
      const fn=resolveReference(expr.callee,context,expected);
      const args={
        length:expr.args.length,
        elaborate:(index:number,expectedType:import('lean-ts-kernel').Expr)=>{
          const argument=elaborateV061Term(
            expr.args[index]!,
            context,
            expectedType,
          );
          return {
            term:argument.term,
            type:argument.type,
            allowUnresolvedMVar:true,
          };
        },
      };
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
        if(expected!==undefined){
          // Nested calls may be constrained further by later sibling arguments
          // in the enclosing application. Shared Meta assignments preserve
          // those constraints; top-level applications still require grounding.
          return {term,type};
        }
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
