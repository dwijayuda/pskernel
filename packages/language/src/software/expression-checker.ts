import type {V061Expr} from '@proofscript/syntax';
import type {
  CheckedSoftwareExpr,
  PrimitiveSoftwareType,
  SoftwareType,
} from './types.js';
import {
  makeFunctionSoftwareType,
  softwareTypeEquals,
  softwareTypeToString,
} from './types.js';
import {
  asSoftwareType,
  requirePrimitiveSoftwareType,
} from './type-conversion.js';
import type {SoftwareExpressionContext} from './check-context.js';
import {nominalTypeNames,withSoftwareLocal} from './check-context.js';
import {checkRecordExpression,tryCheckProjectionReference} from './structure-checker.js';
import {
  tryCheckConstructorCall,
  tryCheckConstructorReference,
} from './inductive-checker.js';
import {checkMatchExpression} from './match-checker.js';

function checkNumericBinary(
  operator:string,
  leftExpr:V061Expr,
  rightExpr:V061Expr,
  context:SoftwareExpressionContext,
  expected?:SoftwareType,
):CheckedSoftwareExpr {
  const numeric:PrimitiveSoftwareType=expected==='Int'?'Int':'Nat';
  const left=checkSoftwareExpr(leftExpr,context,numeric);
  const leftType=requirePrimitiveSoftwareType(left.resultType,'PS_CHECK_BINARY_TYPE: '+operator);
  const right=checkSoftwareExpr(rightExpr,context,leftType);
  if(
    (leftType!=='Nat'&&leftType!=='Int')
    ||!softwareTypeEquals(left.resultType,right.resultType)
  ){
    throw new Error('PS_CHECK_BINARY_TYPE: '+operator+' expects matching numeric operands');
  }
  return {kind:'binary',operator,left,right,resultType:leftType};
}

function checkCall(
  expr:Extract<V061Expr,{kind:'call'}>,
  context:SoftwareExpressionContext,
):CheckedSoftwareExpr {
  const localType=context.locals.get(expr.callee);
  if(localType!==undefined){
    let current=localType;
    const args:CheckedSoftwareExpr[]=[];
    for(let index=0;index<expr.args.length;index+=1){
      if(typeof current==='string'||current.kind!=='function'){
        throw new Error("PS_CHECK_NOT_CALLABLE: local '"+expr.callee+"' has type "+softwareTypeToString(current));
      }
      const checked=checkSoftwareExpr(expr.args[index]!,context,current.parameter);
      if(!softwareTypeEquals(checked.resultType,current.parameter)){
        throw new Error(
          "PS_CHECK_CALL_TYPE: argument "+(index+1)+" of '"+expr.callee+"' expects "+
          softwareTypeToString(current.parameter)+", got "+softwareTypeToString(checked.resultType),
        );
      }
      args.push(checked);
      current=current.result;
    }
    return {kind:'call',callee:expr.callee,args,callStyle:'curried',resultType:current};
  }

  const constructor=tryCheckConstructorCall(expr,context,checkSoftwareExpr);
  if(constructor!==undefined)return constructor;

  const signature=context.signatures.get(expr.callee);
  if(signature===undefined){
    throw new Error("PS_CHECK_UNKNOWN_CALL: unknown function '"+expr.callee+"'");
  }

  if(signature.params.length>0){
    if(signature.params.length!==expr.args.length){
      throw new Error(
        "PS_CHECK_CALL_ARITY: '"+expr.callee+"' expects "+
        signature.params.length+" arguments, got "+expr.args.length,
      );
    }
    const args=expr.args.map((arg,index)=>{
      const wanted=signature.params[index]!;
      const checked=checkSoftwareExpr(arg,context,wanted);
      if(!softwareTypeEquals(checked.resultType,wanted)){
        throw new Error(
          "PS_CHECK_CALL_TYPE: argument "+(index+1)+" of '"+expr.callee+"' expects "+
          softwareTypeToString(wanted)+", got "+softwareTypeToString(checked.resultType),
        );
      }
      return checked;
    });
    return {kind:'call',callee:expr.callee,args,callStyle:'direct',resultType:signature.result};
  }

  let current=signature.result;
  const args:CheckedSoftwareExpr[]=[];
  for(let index=0;index<expr.args.length;index+=1){
    if(typeof current==='string'||current.kind!=='function'){
      throw new Error(
        "PS_CHECK_NOT_CALLABLE: declaration '"+expr.callee+"' has type "+softwareTypeToString(current),
      );
    }
    const checked=checkSoftwareExpr(expr.args[index]!,context,current.parameter);
    if(!softwareTypeEquals(checked.resultType,current.parameter)){
      throw new Error(
        "PS_CHECK_CALL_TYPE: argument "+(index+1)+" of '"+expr.callee+"' expects "+
        softwareTypeToString(current.parameter)+", got "+softwareTypeToString(checked.resultType),
      );
    }
    args.push(checked);
    current=current.result;
  }
  return {kind:'call',callee:expr.callee,args,callStyle:'curried',resultType:current};
}

function checkLambda(
  expr:Extract<V061Expr,{kind:'lambda'}>,
  context:SoftwareExpressionContext,
  expected?:SoftwareType,
):CheckedSoftwareExpr {
  let expectedCursor=expected;
  let bodyContext=context;
  const binders:{name:string;type:SoftwareType}[]=[];

  for(const binder of expr.binders){
    const declared=binder.type===undefined?undefined:asSoftwareType(
      binder.type,
      nominalTypeNames(context),
    );
    let binderType:SoftwareType;
    if(expectedCursor!==undefined&&typeof expectedCursor!=='string'&&expectedCursor.kind==='function'){
      if(declared!==undefined&&!softwareTypeEquals(declared,expectedCursor.parameter)){
        throw new Error(
          'PS_CHECK_LAMBDA_BINDER_TYPE: '+binder.name+' expects '+
          softwareTypeToString(expectedCursor.parameter)+', got '+softwareTypeToString(declared),
        );
      }
      binderType=declared??expectedCursor.parameter;
      expectedCursor=expectedCursor.result;
    }else if(declared!==undefined){
      binderType=declared;
      expectedCursor=undefined;
    }else{
      throw new Error(
        "PS_CHECK_LAMBDA_BINDER_TYPE: cannot infer type of lambda binder '"+binder.name+
        "' without an expected function type",
      );
    }
    bodyContext=withSoftwareLocal(bodyContext,binder.name,binderType);
    binders.push({name:binder.name,type:binderType});
  }

  const body=checkSoftwareExpr(expr.body,bodyContext,expectedCursor);
  const resultType=makeFunctionSoftwareType(binders.map((binder)=>binder.type),body.resultType);
  if(expected!==undefined&&!softwareTypeEquals(resultType,expected)){
    throw new Error(
      'PS_CHECK_LAMBDA_TYPE: expected '+softwareTypeToString(expected)+
      ', got '+softwareTypeToString(resultType),
    );
  }
  return {kind:'lambda',binders,body,resultType};
}

export function checkSoftwareExpr(
  expr:V061Expr,
  context:SoftwareExpressionContext,
  expected?:SoftwareType,
):CheckedSoftwareExpr {
  switch(expr.kind){
    case 'nat':{
      const resultType:PrimitiveSoftwareType=expected==='Int'?'Int':'Nat';
      return {kind:'nat',value:BigInt(expr.text.replaceAll('_','')),resultType};
    }
    case 'string':return {kind:'string',value:expr.value,resultType:'String'};
    case 'bool':return {kind:'bool',value:expr.value,resultType:'Bool'};
    case 'unit':return {kind:'unit',resultType:'Unit'};
    case 'syntheticHole':
      throw new Error(
        'PS_CHECK_SYNTHETIC_HOLE: ?_ is proof-tactic syntax and is not executable software',
      );
    case 'by':
      throw new Error(
        'PS_CHECK_PROOF_TERM: theorem proof blocks are verified by the pskernel elaboration path, not the legacy software checker',
      );
    case 'group':return checkSoftwareExpr(expr.value,context,expected);
    case 'reference':{
      const local=context.locals.get(expr.name);
      if(local!==undefined)return {kind:'reference',name:expr.name,resultType:local};
      const signature=context.signatures.get(expr.name);
      if(signature!==undefined&&signature.params.length===0){
        return {kind:'reference',name:expr.name,resultType:signature.result};
      }
      const constructor=tryCheckConstructorReference(expr.name,context);
      if(constructor!==undefined)return constructor;
      const projection=tryCheckProjectionReference(expr.name,context);
      if(projection!==undefined)return projection;
      throw new Error("PS_CHECK_UNKNOWN_IDENTIFIER: unknown identifier '"+expr.name+"'");
    }
    case 'record':
      return checkRecordExpression(expr,context,checkSoftwareExpr);
    case 'call':return checkCall(expr,context);
    case 'lambda':return checkLambda(expr,context,expected);
    case 'match':return checkMatchExpression(expr,context,expected,checkSoftwareExpr);
    case 'unary':{
      const operand=checkSoftwareExpr(expr.operand,context,'Bool');
      if(operand.resultType!=='Bool')throw new Error('PS_CHECK_UNARY_TYPE: ! expects Bool');
      return {kind:'unary',operator:'!',operand,resultType:'Bool'};
    }
    case 'binary':{
      const op=expr.operator;
      if(op==='&&'||op==='||'){
        const left=checkSoftwareExpr(expr.left,context,'Bool');
        const right=checkSoftwareExpr(expr.right,context,'Bool');
        if(left.resultType!=='Bool'||right.resultType!=='Bool'){
          throw new Error('PS_CHECK_BINARY_TYPE: '+op+' expects Bool operands');
        }
        return {kind:'binary',operator:op,left,right,resultType:'Bool'};
      }
      if(op==='=='||op==='!='){
        const left=checkSoftwareExpr(expr.left,context);
        const right=checkSoftwareExpr(expr.right,context,left.resultType);
        if(!softwareTypeEquals(left.resultType,right.resultType)){
          throw new Error('PS_CHECK_EQUALITY_TYPE: '+op+' operands must have the same type');
        }
        requirePrimitiveSoftwareType(left.resultType,'PS_CHECK_EQUALITY_TYPE: '+op);
        return {kind:'binary',operator:op,left,right,resultType:'Bool'};
      }
      if(op==='<'||op==='<='||op==='>'||op==='>='){
        const left=checkSoftwareExpr(expr.left,context);
        const leftType=requirePrimitiveSoftwareType(left.resultType,'PS_CHECK_BINARY_TYPE: '+op);
        if(leftType!=='Nat'&&leftType!=='Int'){
          throw new Error('PS_CHECK_BINARY_TYPE: '+op+' expects numeric operands');
        }
        const right=checkSoftwareExpr(expr.right,context,leftType);
        if(!softwareTypeEquals(left.resultType,right.resultType)){
          throw new Error('PS_CHECK_BINARY_TYPE: '+op+' expects matching numeric operands');
        }
        return {kind:'binary',operator:op,left,right,resultType:'Bool'};
      }
      if(op==='+'||op==='-'||op==='*'||op==='/'||op==='%'){
        return checkNumericBinary(op,expr.left,expr.right,context,expected);
      }
      throw new Error("PS_CHECK_UNKNOWN_OPERATOR: unsupported operator '"+op+"'");
    }
    case 'if':{
      const condition=checkSoftwareExpr(expr.condition,context,'Bool');
      if(condition.resultType!=='Bool')throw new Error('PS_CHECK_IF_CONDITION: if condition must be Bool');
      const thenBranch=checkSoftwareExpr(expr.thenBranch,context,expected);
      const elseBranch=checkSoftwareExpr(expr.elseBranch,context,thenBranch.resultType);
      if(!softwareTypeEquals(thenBranch.resultType,elseBranch.resultType)){
        throw new Error('PS_CHECK_IF_BRANCH: if branches must have the same type');
      }
      return {kind:'if',condition,thenBranch,elseBranch,resultType:thenBranch.resultType};
    }
    case 'let':{
      const declaredType=expr.declaredType===undefined?undefined:asSoftwareType(
        expr.declaredType,
        nominalTypeNames(context),
      );
      const value=checkSoftwareExpr(expr.value,context,declaredType);
      if(declaredType!==undefined&&!softwareTypeEquals(value.resultType,declaredType)){
        throw new Error(
          'PS_CHECK_LET_TYPE: let '+expr.name+' expects '+softwareTypeToString(declaredType)+
          ', got '+softwareTypeToString(value.resultType),
        );
      }
      const bindingType=declaredType??value.resultType;
      const body=checkSoftwareExpr(
        expr.body,
        withSoftwareLocal(context,expr.name,bindingType),
        expected,
      );
      return {
        kind:'let',
        name:expr.name,
        ...(declaredType===undefined?{}:{declaredType}),
        value,
        body,
        resultType:body.resultType,
      };
    }
  }
}
