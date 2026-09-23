import type {V061Expr,V061Module} from '@proofscript/syntax';
import type {
  CheckedSoftwareExpr,
  CheckedSoftwareModule,
  SoftwareSignature,
  SoftwareType,
} from './types.js';

const PRIMITIVES=new Set<SoftwareType>(['Nat','Int','Bool','String','Unit']);

function asType(name:string):SoftwareType {
  if(!PRIMITIVES.has(name as SoftwareType)){
    throw new Error("PS_CHECK_UNKNOWN_TYPE: unsupported software type '"+name+"'");
  }
  return name as SoftwareType;
}

function checkNumericBinary(
  operator:string,
  leftExpr:V061Expr,
  rightExpr:V061Expr,
  locals:ReadonlyMap<string,SoftwareType>,
  signatures:ReadonlyMap<string,SoftwareSignature>,
  expected?:SoftwareType,
):CheckedSoftwareExpr {
  const numeric:SoftwareType=expected==='Int'?'Int':'Nat';
  const left=checkExpr(leftExpr,locals,signatures,numeric);
  const right=checkExpr(rightExpr,locals,signatures,left.resultType);
  if((left.resultType!=='Nat'&&left.resultType!=='Int')||left.resultType!==right.resultType){
    throw new Error('PS_CHECK_BINARY_TYPE: '+operator+' expects matching numeric operands');
  }
  return {kind:'binary',operator,left,right,resultType:left.resultType};
}

function checkExpr(
  expr:V061Expr,
  locals:ReadonlyMap<string,SoftwareType>,
  signatures:ReadonlyMap<string,SoftwareSignature>,
  expected?:SoftwareType,
):CheckedSoftwareExpr {
  switch(expr.kind){
    case 'nat':{
      const resultType:SoftwareType=expected==='Int'?'Int':'Nat';
      return {kind:'nat',value:BigInt(expr.text.replaceAll('_','')),resultType};
    }
    case 'string':return {kind:'string',value:expr.value,resultType:'String'};
    case 'bool':return {kind:'bool',value:expr.value,resultType:'Bool'};
    case 'unit':return {kind:'unit',resultType:'Unit'};
    case 'group':return checkExpr(expr.value,locals,signatures,expected);
    case 'reference':{
      const local=locals.get(expr.name);
      if(local!==undefined)return {kind:'reference',name:expr.name,resultType:local};
      const signature=signatures.get(expr.name);
      if(signature!==undefined&&signature.params.length===0){
        return {kind:'reference',name:expr.name,resultType:signature.result};
      }
      throw new Error("PS_CHECK_UNKNOWN_IDENTIFIER: unknown identifier '"+expr.name+"'");
    }
    case 'call':{
      const signature=signatures.get(expr.callee);
      if(signature===undefined)throw new Error("PS_CHECK_UNKNOWN_CALL: unknown function '"+expr.callee+"'");
      if(signature.params.length!==expr.args.length){
        throw new Error("PS_CHECK_CALL_ARITY: '"+expr.callee+"' expects "+signature.params.length+" arguments, got "+expr.args.length);
      }
      const args=expr.args.map((arg,index)=>{
        const wanted=signature.params[index]!;
        const checked=checkExpr(arg,locals,signatures,wanted);
        if(checked.resultType!==wanted){
          throw new Error("PS_CHECK_CALL_TYPE: argument "+(index+1)+" of '"+expr.callee+"' expects "+wanted+", got "+checked.resultType);
        }
        return checked;
      });
      return {kind:'call',callee:expr.callee,args,resultType:signature.result};
    }
    case 'unary':{
      const operand=checkExpr(expr.operand,locals,signatures,'Bool');
      if(operand.resultType!=='Bool')throw new Error('PS_CHECK_UNARY_TYPE: ! expects Bool');
      return {kind:'unary',operator:'!',operand,resultType:'Bool'};
    }
    case 'binary':{
      const op=expr.operator;
      if(op==='&&'||op==='||'){
        const left=checkExpr(expr.left,locals,signatures,'Bool');
        const right=checkExpr(expr.right,locals,signatures,'Bool');
        if(left.resultType!=='Bool'||right.resultType!=='Bool'){
          throw new Error('PS_CHECK_BINARY_TYPE: '+op+' expects Bool operands');
        }
        return {kind:'binary',operator:op,left,right,resultType:'Bool'};
      }
      if(op==='=='||op==='!='){
        const left=checkExpr(expr.left,locals,signatures);
        const right=checkExpr(expr.right,locals,signatures,left.resultType);
        if(left.resultType!==right.resultType){
          throw new Error('PS_CHECK_EQUALITY_TYPE: '+op+' operands must have the same type');
        }
        return {kind:'binary',operator:op,left,right,resultType:'Bool'};
      }
      if(op==='<'||op==='<='||op==='>'||op==='>='){
        const left=checkExpr(expr.left,locals,signatures);
        if(left.resultType!=='Nat'&&left.resultType!=='Int'){
          throw new Error('PS_CHECK_BINARY_TYPE: '+op+' expects numeric operands');
        }
        const right=checkExpr(expr.right,locals,signatures,left.resultType);
        if(left.resultType!==right.resultType){
          throw new Error('PS_CHECK_BINARY_TYPE: '+op+' expects matching numeric operands');
        }
        return {kind:'binary',operator:op,left,right,resultType:'Bool'};
      }
      if(op==='+'||op==='-'||op==='*'||op==='/'||op==='%'){
        return checkNumericBinary(op,expr.left,expr.right,locals,signatures,expected);
      }
      throw new Error("PS_CHECK_UNKNOWN_OPERATOR: unsupported operator '"+op+"'");
    }
    case 'if':{
      const condition=checkExpr(expr.condition,locals,signatures,'Bool');
      if(condition.resultType!=='Bool')throw new Error('PS_CHECK_IF_CONDITION: if condition must be Bool');
      const thenBranch=checkExpr(expr.thenBranch,locals,signatures,expected);
      const elseBranch=checkExpr(expr.elseBranch,locals,signatures,thenBranch.resultType);
      if(thenBranch.resultType!==elseBranch.resultType){
        throw new Error('PS_CHECK_IF_BRANCH: if branches must have the same type');
      }
      return {kind:'if',condition,thenBranch,elseBranch,resultType:thenBranch.resultType};
    }
    case 'let':{
      const declaredType=expr.declaredType===undefined?undefined:asType(expr.declaredType);
      const value=checkExpr(expr.value,locals,signatures,declaredType);
      if(declaredType!==undefined&&value.resultType!==declaredType){
        throw new Error('PS_CHECK_LET_TYPE: let '+expr.name+' expects '+declaredType+', got '+value.resultType);
      }
      const bindingType=declaredType??value.resultType;
      const bodyLocals=new Map(locals);
      bodyLocals.set(expr.name,bindingType);
      const body=checkExpr(expr.body,bodyLocals,signatures,expected);
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

export function checkV061SoftwareModule(module:V061Module):CheckedSoftwareModule {
  const signatures=new Map<string,SoftwareSignature>();
  for(const decl of module.declarations){
    if(signatures.has(decl.name)){
      throw new Error("PS_CHECK_DUPLICATE_DECL: duplicate declaration '"+decl.name+"'");
    }
    signatures.set(decl.name,{
      params:decl.params.map((param)=>asType(param.type)),
      result:asType(decl.resultType),
    });
  }

  const declarations=module.declarations.map((decl)=>{
    const locals=new Map<string,SoftwareType>();
    const params=decl.params.map((param)=>{
      if(locals.has(param.name)){
        throw new Error("PS_CHECK_DUPLICATE_PARAM: duplicate parameter '"+param.name+"'");
      }
      const type=asType(param.type);
      locals.set(param.name,type);
      return {name:param.name,type};
    });
    const resultType=asType(decl.resultType);
    const body=checkExpr(decl.body,locals,signatures,resultType);
    if(body.resultType!==resultType){
      throw new Error('PS_CHECK_DECL_TYPE: '+decl.name+' expects '+resultType+', got '+body.resultType);
    }
    return {kind:decl.kind,name:decl.name,params,resultType,body};
  });

  return {kind:'checked-v061-software-module',declarations};
}
