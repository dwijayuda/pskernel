import type {
  VerifiedIrExpr,
} from '@proofscript/compiler-ir/verified';
import {
  unsupported,
} from './errors.js';
import type {
  RuntimeType,
  Signature,
} from './type-lowering.js';

export function expressionRuntimeType(
  expr:VerifiedIrExpr,
  locals:ReadonlyMap<string,RuntimeType>,
  signatures:ReadonlyMap<string,Signature>,
):RuntimeType {
  switch(expr.kind){
    case 'literal':
      if(typeof expr.value==='boolean')return 'bool';
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
      if(signatures.has(expr.name)){
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
      if(expr.operation.startsWith('bool.'))return 'bool';
      switch(expr.operation){
        case 'uint8.add':return 'uint8';
        case 'uint16.add':return 'uint16';
        case 'uint32.add':return 'uint32';
        case 'uint64.add':return 'uint64';
        default:
          return unsupported(
            'PS_WASM_UNSUPPORTED_INTRINSIC',
            "intrinsic '"+expr.operation+"' is not supported in W2",
          );
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
      return signature.result;
    }

    case 'let':{
      const valueType=expressionRuntimeType(
        expr.value,
        locals,
        signatures,
      );
      if(valueType===null){
        return unsupported(
          'PS_WASM_UNSUPPORTED_UNIT_LOCAL',
          'Unit-valued let bindings are not lowered in W1',
        );
      }
      const next=new Map(locals);
      next.set(expr.name,valueType);
      return expressionRuntimeType(expr.body,next,signatures);
    }

    case 'if':
      return expressionRuntimeType(expr.thenBranch,locals,signatures);

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
