import type {
  VerifiedIrDeclaration,
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';
import type {WasmValueType} from '@proofscript/wasm-ir';
import {unsupported} from './errors.js';

export type RuntimeType=WasmValueType|null;

export interface Signature {
  readonly parameters:readonly WasmValueType[];
  readonly result:RuntimeType;
}

export function lowerRuntimeType(
  type:VerifiedIrType,
  position:'parameter'|'result',
):RuntimeType {
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

export function signatureOf(
  declaration:VerifiedIrDeclaration,
):Signature {
  if(declaration.typeParameters.length!==0){
    return unsupported(
      'PS_WASM_UNSUPPORTED_GENERIC_DECLARATION',
      "declaration '"+declaration.name+"' has erased type parameters",
    );
  }

  const parameters=declaration.parameters.map((parameter)=>{
    const type=lowerRuntimeType(parameter.type,'parameter');
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
    result:lowerRuntimeType(declaration.resultType,'result'),
  };
}
