import type {V061Expr,V061Module,V061TypeExpr} from '@proofscript/syntax';
import type {
  CheckedSoftwareExpr,
  CheckedSoftwareModule,
  PrimitiveSoftwareType,
  SoftwareSignature,
  SoftwareType,
} from './types.js';
import {makeFunctionSoftwareType,softwareTypeEquals,softwareTypeToString} from './types.js';

const PRIMITIVES=new Set<PrimitiveSoftwareType>(['Nat','Int','Bool','String','Unit']);

function asType(type:V061TypeExpr):SoftwareType {
  switch(type.kind){
    case 'group':return asType(type.value);
    case 'named':
      if(!PRIMITIVES.has(type.name as PrimitiveSoftwareType)){
        throw new Error("PS_CHECK_UNKNOWN_TYPE: unsupported software type '"+type.name+"'");
      }
      return type.name as PrimitiveSoftwareType;
    case 'arrow':
      return {kind:'function',parameter:asType(type.domain),result:asType(type.codomain)};
  }
}

function requirePrimitive(type:SoftwareType,context:string):PrimitiveSoftwareType {
  if(typeof type!=='string')throw new Error(context+' expects a primitive software type, got '+softwareTypeToString(type));
  return type;
}

function checkNumericBinary(
  operator:string,
  leftExpr:V061Expr,
  rightExpr:V061Expr,
  locals:ReadonlyMap<string,SoftwareType>,
  signatures:ReadonlyMap<string,SoftwareSignature>,
  expected?:SoftwareType,
):CheckedSoftwareExpr {
  const numeric:PrimitiveSoftwareType=expected==='Int'?'Int':'Nat';
  const left=checkExpr(leftExpr,locals,signatures,numeric);
  const leftType=requirePrimitive(left.resultType,'PS_CHECK_BINARY_TYPE: '+operator);
  const right=checkExpr(rightExpr,locals,signatures,leftType);
  if((leftType!=='Nat'&&leftType!=='Int')||!softwareTypeEquals(left.resultType,right.resultType)){
    throw new Error('PS_CHECK_BINARY_TYPE: '+operator+' expects matching numeric operands');
  }
  return {kind:'binary',operator,left,right,resultType:leftType};
}

function checkExpr(
  expr:V061Expr,
  locals:ReadonlyMap<string,SoftwareType>,
  signatures:ReadonlyMap<string,SoftwareSignature>,
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
      const localType=locals.get(expr.callee);
      if(localType!==undefined){
        let current=localType;
        const args:CheckedSoftwareExpr[]=[];
        for(let index=0;index<expr.args.length;index+=1){
          if(typeof current==='string'){
            throw new Error("PS_CHECK_NOT_CALLABLE: local '"+expr.callee+"' has type "+softwareTypeToString(current));
          }
          const checked=checkExpr(expr.args[index]!,locals,signatures,current.parameter);
          if(!softwareTypeEquals(checked.resultType,current.parameter)){
            throw new Error("PS_CHECK_CALL_TYPE: argument "+(index+1)+" of '"+expr.callee+"' expects "+softwareTypeToString(current.parameter)+", got "+softwareTypeToString(checked.resultType));
          }
          args.push(checked);
          current=current.result;
        }
        return {kind:'call',callee:expr.callee,args,callStyle:'curried',resultType:current};
      }

      const signature=signatures.get(expr.callee);
      if(signature===undefined)throw new Error("PS_CHECK_UNKNOWN_CALL: unknown function '"+expr.callee+"'");

      if(signature.params.length>0){
        if(signature.params.length!==expr.args.length){
          throw new Error("PS_CHECK_CALL_ARITY: '"+expr.callee+"' expects "+signature.params.length+" arguments, got "+expr.args.length);
        }
        const args=expr.args.map((arg,index)=>{
          const wanted=signature.params[index]!;
          const checked=checkExpr(arg,locals,signatures,wanted);
          if(!softwareTypeEquals(checked.resultType,wanted)){
            throw new Error("PS_CHECK_CALL_TYPE: argument "+(index+1)+" of '"+expr.callee+"' expects "+softwareTypeToString(wanted)+", got "+softwareTypeToString(checked.resultType));
          }
          return checked;
        });
        return {kind:'call',callee:expr.callee,args,callStyle:'direct',resultType:signature.result};
      }

      let current=signature.result;
      const args:CheckedSoftwareExpr[]=[];
      for(let index=0;index<expr.args.length;index+=1){
        if(typeof current==='string'){
          throw new Error("PS_CHECK_NOT_CALLABLE: declaration '"+expr.callee+"' has type "+softwareTypeToString(current));
        }
        const checked=checkExpr(expr.args[index]!,locals,signatures,current.parameter);
        if(!softwareTypeEquals(checked.resultType,current.parameter)){
          throw new Error("PS_CHECK_CALL_TYPE: argument "+(index+1)+" of '"+expr.callee+"' expects "+softwareTypeToString(current.parameter)+", got "+softwareTypeToString(checked.resultType));
        }
        args.push(checked);
        current=current.result;
      }
      return {kind:'call',callee:expr.callee,args,callStyle:'curried',resultType:current};
    }
    case 'match':{
      const scrutinee=checkExpr(expr.scrutinee,locals,signatures,'Bool');
      if(scrutinee.resultType!=='Bool'){
        throw new Error('PS_CHECK_MATCH_SCRUTINEE: initial executable match subset requires Bool');
      }

      const alternatives:{pattern:{kind:'bool';value:boolean}|{kind:'wildcard'};body:CheckedSoftwareExpr}[]=[];
      let seenTrue=false;
      let seenFalse=false;
      let wildcard=false;
      let branchType:SoftwareType|undefined;

      for(const alternative of expr.alternatives){
        let pattern:{kind:'bool';value:boolean}|{kind:'wildcard'};
        if(alternative.pattern.kind==='constructor'){
          throw new Error(
            'PS_CHECK_MATCH_PATTERN_UNSUPPORTED: constructor patterns require inductive-type elaboration',
          );
        }
        if(alternative.pattern.kind==='wildcard'){
          if(wildcard||alternatives.length>0){
            throw new Error('PS_CHECK_MATCH_PATTERN: wildcard must be the only alternative in the initial executable subset');
          }
          wildcard=true;
          pattern={kind:'wildcard'};
        }else{
          if(wildcard){
            throw new Error('PS_CHECK_MATCH_PATTERN: no alternatives may follow wildcard');
          }
          if(alternative.pattern.value){
            if(seenTrue)throw new Error('PS_CHECK_MATCH_DUPLICATE: duplicate true alternative');
            seenTrue=true;
          }else{
            if(seenFalse)throw new Error('PS_CHECK_MATCH_DUPLICATE: duplicate false alternative');
            seenFalse=true;
          }
          pattern={kind:'bool',value:alternative.pattern.value};
        }

        const body=checkExpr(alternative.body,locals,signatures,branchType??expected);
        if(branchType!==undefined&&!softwareTypeEquals(body.resultType,branchType)){
          throw new Error('PS_CHECK_MATCH_BRANCH: match alternatives must have the same type');
        }
        branchType=body.resultType;
        alternatives.push({pattern,body});
      }

      if(!wildcard&&(!seenTrue||!seenFalse)){
        throw new Error('PS_CHECK_MATCH_EXHAUSTIVE: Bool match requires true and false alternatives');
      }
      if(branchType===undefined)throw new Error('PS_CHECK_MATCH_EMPTY: match has no alternatives');
      return {kind:'match',scrutinee,alternatives,resultType:branchType};
    }
    case 'lambda':{
      let expectedCursor=expected;
      const bodyLocals=new Map(locals);
      const binders:{name:string;type:SoftwareType}[]=[];

      for(const binder of expr.binders){
        const declared=binder.type===undefined?undefined:asType(binder.type);
        let binderType:SoftwareType;
        if(expectedCursor!==undefined&&typeof expectedCursor!=='string'){
          if(declared!==undefined&&!softwareTypeEquals(declared,expectedCursor.parameter)){
            throw new Error(
              'PS_CHECK_LAMBDA_BINDER_TYPE: '+binder.name+' expects '+softwareTypeToString(expectedCursor.parameter)+
              ', got '+softwareTypeToString(declared),
            );
          }
          binderType=declared??expectedCursor.parameter;
          expectedCursor=expectedCursor.result;
        }else if(declared!==undefined){
          binderType=declared;
          expectedCursor=undefined;
        }else{
          throw new Error(
            "PS_CHECK_LAMBDA_BINDER_TYPE: cannot infer type of lambda binder '"+binder.name+"' without an expected function type",
          );
        }
        bodyLocals.set(binder.name,binderType);
        binders.push({name:binder.name,type:binderType});
      }

      const body=checkExpr(expr.body,bodyLocals,signatures,expectedCursor);
      const resultType=makeFunctionSoftwareType(binders.map((binder)=>binder.type),body.resultType);
      if(expected!==undefined&&!softwareTypeEquals(resultType,expected)){
        throw new Error(
          'PS_CHECK_LAMBDA_TYPE: expected '+softwareTypeToString(expected)+', got '+softwareTypeToString(resultType),
        );
      }
      return {kind:'lambda',binders,body,resultType};
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
        if(!softwareTypeEquals(left.resultType,right.resultType)){
          throw new Error('PS_CHECK_EQUALITY_TYPE: '+op+' operands must have the same type');
        }
        requirePrimitive(left.resultType,'PS_CHECK_EQUALITY_TYPE: '+op);
        return {kind:'binary',operator:op,left,right,resultType:'Bool'};
      }
      if(op==='<'||op==='<='||op==='>'||op==='>='){
        const left=checkExpr(expr.left,locals,signatures);
        const leftType=requirePrimitive(left.resultType,'PS_CHECK_BINARY_TYPE: '+op);
        if(leftType!=='Nat'&&leftType!=='Int'){
          throw new Error('PS_CHECK_BINARY_TYPE: '+op+' expects numeric operands');
        }
        const right=checkExpr(expr.right,locals,signatures,leftType);
        if(!softwareTypeEquals(left.resultType,right.resultType)){
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
      if(!softwareTypeEquals(thenBranch.resultType,elseBranch.resultType)){
        throw new Error('PS_CHECK_IF_BRANCH: if branches must have the same type');
      }
      return {kind:'if',condition,thenBranch,elseBranch,resultType:thenBranch.resultType};
    }
    case 'let':{
      const declaredType=expr.declaredType===undefined?undefined:asType(expr.declaredType);
      const value=checkExpr(expr.value,locals,signatures,declaredType);
      if(declaredType!==undefined&&!softwareTypeEquals(value.resultType,declaredType)){
        throw new Error('PS_CHECK_LET_TYPE: let '+expr.name+' expects '+softwareTypeToString(declaredType)+', got '+softwareTypeToString(value.resultType));
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
    if(!softwareTypeEquals(body.resultType,resultType)){
      throw new Error('PS_CHECK_DECL_TYPE: '+decl.name+' expects '+softwareTypeToString(resultType)+', got '+softwareTypeToString(body.resultType));
    }
    return {kind:decl.kind,name:decl.name,params,resultType,body};
  });

  return {kind:'checked-v061-software-module',declarations};
}
