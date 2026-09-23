import type {
  VerifiedIrDeclaration,
  VerifiedIrModule,
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';
import {
  decodeVerifiedJsonArgument,
  encodeVerifiedRuntimeValue,
  type VerifiedRuntimeAbiContext,
} from './verified-runtime-json.js';
import {
  parseVerifiedPrimitiveArgument,
} from './verified-runtime-primitives.js';

export type {VerifiedRuntimeAbiContext};

export function parseVerifiedRuntimeArg(
  value:string,
  type:VerifiedIrType,
  context?:VerifiedRuntimeAbiContext,
):unknown {
  if(type.kind==='primitive'){
    return parseVerifiedPrimitiveArgument(value,type.name);
  }

  if(context===undefined){
    throw new Error(
      'PS_RUN_VERIFIED_ARG_TYPE: structured verified main arguments require '+
      'the checked module runtime ABI context',
    );
  }
  return decodeVerifiedJsonArgument(value,type,context);
}

export function prepareVerifiedMainArguments(
  declaration:VerifiedIrDeclaration,
  values:readonly string[],
  context?:VerifiedRuntimeAbiContext,
):readonly unknown[] {
  if(declaration.typeParameters.length!==0){
    throw new Error(
      'PS_RUN_VERIFIED_GENERIC_MAIN: main may not have compile-time type parameters',
    );
  }
  if(declaration.parameters.length!==values.length){
    throw new Error(
      'PS_RUN_ARITY: main expects '+declaration.parameters.length+
      ' arguments, got '+values.length,
    );
  }
  return declaration.parameters.map((parameter,index)=>
    parseVerifiedRuntimeArg(values[index]!,parameter.type,context)
  );
}

export function encodeVerifiedRuntimeResult(
  value:unknown,
  type:VerifiedIrType,
  module:VerifiedIrModule,
):unknown {
  return encodeVerifiedRuntimeValue(value,type,module);
}
