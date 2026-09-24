import type {
  VerifiedIrDeclaration,
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';
import type {WasmValueType} from '@proofscript/wasm-ir';
import {unsupported} from './errors.js';

export type RuntimeValueType=
  |'bool'
  |'uint8'|'uint16'|'uint32'|'uint64'
  |'nat'|'int';
export type RuntimeType=RuntimeValueType|null;

export interface Signature {
  readonly parameters:readonly RuntimeValueType[];
  readonly result:RuntimeType;
}

export function wasmValueType(
  type:RuntimeValueType,
):WasmValueType {
  switch(type){
    case 'bool':
    case 'uint8':
    case 'uint16':
    case 'uint32':
      return 'i32';
    case 'uint64':
      return 'i64';
    case 'nat':
    case 'int':
      return 'externref';
  }
}

export function wasmResultType(
  type:RuntimeType,
):WasmValueType|null {
  return type===null?null:wasmValueType(type);
}

export function lowerRuntimeType(
  type:VerifiedIrType,
  position:'parameter'|'result',
):RuntimeType {
  switch(type.kind){
    case 'primitive':
      switch(type.name){
        case 'Bool':
          return 'bool';
        case 'UInt8':
          return 'uint8';
        case 'UInt16':
          return 'uint16';
        case 'UInt32':
          return 'uint32';
        case 'UInt64':
          return 'uint64';
        case 'Unit':
          if(position==='parameter'){
            return unsupported(
              'PS_WASM_UNSUPPORTED_UNIT_PARAMETER',
              'Unit parameters are not lowered in W1',
            );
          }
          return null;
        case 'Nat':
          return 'nat';
        case 'Int':
          return 'int';
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
