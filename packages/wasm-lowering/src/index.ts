import type {
  VerifiedIrDeclaration,
  VerifiedIrExpr,
  VerifiedIrModule,
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';
import {
  validateWasmIrModule,
  type WasmIrExpr,
  type WasmIrFunction,
  type WasmIrModule,
  type WasmValueType,
} from '@proofscript/wasm-ir';

export const PROOFSCRIPT_WASM_PROFILE=
  'proofscript-wasm32-gc-js-v1' as const;

export class WasmLoweringError extends Error {
  readonly code:string;
  constructor(code:string,message:string){
    super(code+': '+message);
    this.name='WasmLoweringError';
    this.code=code;
  }
}

type RuntimeType=WasmValueType|null;

interface Signature {
  readonly parameters:readonly WasmValueType[];
  readonly result:RuntimeType;
}

function unsupported(code:string,message:string):never {
  throw new WasmLoweringError(code,message);
}

function lowerType(type:VerifiedIrType,position:'parameter'|'result'):RuntimeType {
  switch(type.kind){
    case 'primitive':
      switch(type.name){
        case 'Bool':
          return 'i32';
        case 'Unit':
          if(position==='parameter'){
            return unsupported(
              'PS_WASM_UNSUPPORTED_UNIT_PARAMETER',
              'Unit parameters are not lowered in W1',
            );
          }
          return null;
        case 'Nat':
          return unsupported(
            'PS_WASM_UNSUPPORTED_NAT_RUNTIME',
            'Nat is arbitrary precision and must not be narrowed to i64',
          );
        case 'Int':
          return unsupported(
            'PS_WASM_UNSUPPORTED_INT_RUNTIME',
            'Int is arbitrary precision and must not be narrowed to i64',
          );
        case 'String':
          return unsupported(
            'PS_WASM_UNSUPPORTED_STRING_RUNTIME',
            'String ABI is not implemented in W1',
          );
      }
    case 'unknown':
      return unsupported(
        'PS_WASM_UNSUPPORTED_UNKNOWN_TYPE',
        'unknown runtime types cannot be represented safely',
      );
    case 'typeParameter':
      return unsupported(
        'PS_WASM_UNSUPPORTED_GENERIC_RUNTIME_TYPE',
        "runtime type parameter '"+type.name+"' requires a representation policy",
      );
    case 'named':
      return unsupported(
        'PS_WASM_UNSUPPORTED_NAMED_RUNTIME_TYPE',
        "named runtime type '"+type.name+"' requires structure/ADT lowering",
      );
    case 'function':
      return unsupported(
        'PS_WASM_UNSUPPORTED_FUNCTION_VALUE',
        'function values require closure/function-reference lowering',
      );
  }
}

function expressionType(
  expr:VerifiedIrExpr,
  locals:ReadonlyMap<string,RuntimeType>,
  signatures:ReadonlyMap<string,Signature>,
):RuntimeType {
  switch(expr.kind){
    case 'literal':
      if(typeof expr.value==='boolean')return 'i32';
      if(expr.value===undefined)return null;
      if(typeof expr.value==='bigint'){
        return unsupported(
          'PS_WASM_UNSUPPORTED_NAT_INT_LITERAL',
          'arbitrary-precision integer literals require the Nat/Int runtime',
        );
      }
      return unsupported(
        'PS_WASM_UNSUPPORTED_STRING_LITERAL',
        'String literals require the String runtime ABI',
      );
    case 'var':{
      const local=locals.get(expr.name);
      if(local!==undefined)return local;
      const fn=signatures.get(expr.name);
      if(fn!==undefined){
        return unsupported(
          'PS_WASM_UNSUPPORTED_FUNCTION_VALUE',
          "function '"+expr.name+"' may only appear as a direct call target in W1",
        );
      }
      return unsupported(
        'PS_WASM_UNKNOWN_RUNTIME_NAME',
        "unknown runtime name '"+expr.name+"'",
      );
    }
    case 'intrinsic':
      if(expr.operation.startsWith('bool.'))return 'i32';
      return unsupported(
        'PS_WASM_UNSUPPORTED_INTRINSIC',
        "intrinsic '"+expr.operation+"' is not supported in W1",
      );
    case 'call':{
      if(expr.fn.kind!=='var'){
        return unsupported(
          'PS_WASM_UNSUPPORTED_INDIRECT_CALL',
          'W1 supports direct first-order call targets only',
        );
      }
      const signature=signatures.get(expr.fn.name);
      if(signature===undefined){
        return unsupported(
          'PS_WASM_UNKNOWN_CALL_TARGET',
          "unknown call target '"+expr.fn.name+"'",
        );
      }
      return signature.result;
    }
    case 'let':{
      const valueType=expressionType(expr.value,locals,signatures);
      if(valueType===null){
        return unsupported(
          'PS_WASM_UNSUPPORTED_UNIT_LOCAL',
          'Unit-valued let bindings are not lowered in W1',
        );
      }
      const next=new Map(locals);
      next.set(expr.name,valueType);
      return expressionType(expr.body,next,signatures);
    }
    case 'if':
      return expressionType(expr.thenBranch,locals,signatures);
    case 'lambda':
      return unsupported(
        'PS_WASM_UNSUPPORTED_LAMBDA',
        'lambdas require function-reference/closure lowering',
      );
    case 'record':
    case 'projection':
      return unsupported(
        'PS_WASM_UNSUPPORTED_STRUCTURE',
        'structures require the Wasm GC/layout checkpoint',
      );
    case 'constructor':
    case 'match':
      return unsupported(
        'PS_WASM_UNSUPPORTED_ADT',
        'inductive runtime values require the Wasm GC/layout checkpoint',
      );
  }
}

function requireType(
  actual:RuntimeType,
  expected:RuntimeType,
  label:string,
):void {
  if(actual!==expected){
    throw new WasmLoweringError(
      'PS_WASM_TYPE_MISMATCH',
      label+' expected '+String(expected)+' but got '+String(actual),
    );
  }
}

function lowerExpr(
  expr:VerifiedIrExpr,
  expected:RuntimeType,
  locals:ReadonlyMap<string,RuntimeType>,
  signatures:ReadonlyMap<string,Signature>,
):WasmIrExpr {
  requireType(expressionType(expr,locals,signatures),expected,'expression');

  switch(expr.kind){
    case 'literal':
      if(typeof expr.value==='boolean'){
        return {kind:'i32.const',value:expr.value?1:0};
      }
      if(expr.value===undefined)return {kind:'nop'};
      return unsupported(
        'PS_WASM_UNSUPPORTED_LITERAL',
        'literal is outside the W1 Bool/Unit subset',
      );
    case 'var':{
      const type=locals.get(expr.name);
      if(type===undefined||type===null){
        return unsupported(
          'PS_WASM_UNKNOWN_RUNTIME_LOCAL',
          "runtime local '"+expr.name+"' is unavailable",
        );
      }
      return {kind:'local',name:expr.name,type};
    }
    case 'intrinsic':{
      if(expr.operation==='bool.not'){
        return {
          kind:'i32.unary',
          operation:'eqz',
          operand:lowerExpr(expr.args[0]!,'i32',locals,signatures),
        };
      }
      const operation={
        'bool.and':'and',
        'bool.or':'or',
        'bool.eq':'eq',
        'bool.ne':'ne',
      }[expr.operation];
      if(operation===undefined){
        return unsupported(
          'PS_WASM_UNSUPPORTED_INTRINSIC',
          "intrinsic '"+expr.operation+"' is not supported in W1",
        );
      }
      return {
        kind:'i32.binary',
        operation:operation as 'and'|'or'|'eq'|'ne',
        left:lowerExpr(expr.args[0]!,'i32',locals,signatures),
        right:lowerExpr(expr.args[1]!,'i32',locals,signatures),
      };
    }
    case 'call':{
      if(expr.fn.kind!=='var'){
        return unsupported(
          'PS_WASM_UNSUPPORTED_INDIRECT_CALL',
          'W1 supports direct first-order call targets only',
        );
      }
      const signature=signatures.get(expr.fn.name);
      if(signature===undefined){
        return unsupported(
          'PS_WASM_UNKNOWN_CALL_TARGET',
          "unknown call target '"+expr.fn.name+"'",
        );
      }
      if(expr.args.length!==signature.parameters.length){
        throw new WasmLoweringError(
          'PS_WASM_CALL_ARITY',
          "call '"+expr.fn.name+"' has the wrong number of arguments",
        );
      }
      return {
        kind:'call',
        target:expr.fn.name,
        args:expr.args.map((arg,index)=>
          lowerExpr(arg,signature.parameters[index]!,locals,signatures)
        ),
        result:signature.result,
      };
    }
    case 'let':{
      const valueType=expressionType(expr.value,locals,signatures);
      if(valueType===null){
        return unsupported(
          'PS_WASM_UNSUPPORTED_UNIT_LOCAL',
          'Unit-valued let bindings are not lowered in W1',
        );
      }
      const next=new Map(locals);
      next.set(expr.name,valueType);
      return {
        kind:'let',
        name:expr.name,
        type:valueType,
        value:lowerExpr(expr.value,valueType,locals,signatures),
        body:lowerExpr(expr.body,expected,next,signatures),
        result:expected,
      };
    }
    case 'if':
      return {
        kind:'if',
        condition:lowerExpr(expr.condition,'i32',locals,signatures),
        thenBranch:lowerExpr(expr.thenBranch,expected,locals,signatures),
        elseBranch:lowerExpr(expr.elseBranch,expected,locals,signatures),
        result:expected,
      };
    case 'lambda':
      return unsupported(
        'PS_WASM_UNSUPPORTED_LAMBDA',
        'lambdas require function-reference/closure lowering',
      );
    case 'record':
    case 'projection':
      return unsupported(
        'PS_WASM_UNSUPPORTED_STRUCTURE',
        'structures require the Wasm GC/layout checkpoint',
      );
    case 'constructor':
    case 'match':
      return unsupported(
        'PS_WASM_UNSUPPORTED_ADT',
        'inductive runtime values require the Wasm GC/layout checkpoint',
      );
  }
}

function signatureOf(declaration:VerifiedIrDeclaration):Signature {
  if(declaration.typeParameters.length!==0){
    return unsupported(
      'PS_WASM_UNSUPPORTED_GENERIC_DECLARATION',
      "declaration '"+declaration.name+"' has erased type parameters",
    );
  }
  const parameters=declaration.parameters.map((parameter)=>{
    const type=lowerType(parameter.type,'parameter');
    if(type===null){
      return unsupported(
        'PS_WASM_UNSUPPORTED_UNIT_PARAMETER',
        "parameter '"+parameter.name+"' cannot use Unit in W1",
      );
    }
    return type;
  });
  return {
    parameters,
    result:lowerType(declaration.resultType,'result'),
  };
}

export function lowerVerifiedIrToWasm(
  module:VerifiedIrModule,
):WasmIrModule {
  if((module.structures??[]).length!==0){
    return unsupported(
      'PS_WASM_UNSUPPORTED_STRUCTURE',
      'W1 does not yet lower runtime structures',
    );
  }
  if((module.inductives??[]).length!==0){
    return unsupported(
      'PS_WASM_UNSUPPORTED_ADT',
      'W1 does not yet lower runtime inductive types',
    );
  }

  const signatures=new Map<string,Signature>();
  for(const declaration of module.declarations){
    signatures.set(declaration.name,signatureOf(declaration));
  }

  const functions:WasmIrFunction[]=module.declarations.map((declaration)=>{
    const signature=signatures.get(declaration.name)!;
    const locals=new Map<string,RuntimeType>();
    const parameters=declaration.parameters.map((parameter,index)=>{
      const type=signature.parameters[index]!;
      locals.set(parameter.name,type);
      return {name:parameter.name,type};
    });
    return {
      name:declaration.name,
      parameters,
      result:signature.result,
      exportName:declaration.name,
      body:lowerExpr(
        declaration.body,
        signature.result,
        locals,
        signatures,
      ),
    };
  });

  const wasm:WasmIrModule={
    kind:'proofscript-wasm-ir',
    profile:PROOFSCRIPT_WASM_PROFILE,
    functions,
  };
  validateWasmIrModule(wasm);
  return wasm;
}
