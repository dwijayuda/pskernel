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

export type {VerifiedRuntimeAbiContext};

export function parseVerifiedRuntimeArg(
  value:string,
  type:VerifiedIrType,
  context?:VerifiedRuntimeAbiContext,
):unknown {
  if(type.kind==='primitive'){
    switch(type.name){
      case 'Nat':{
        let parsed:bigint;
        try{parsed=BigInt(value);}
        catch{
          throw new Error(
            "PS_RUN_ARG: Nat argument must be an integer, got '"+value+"'",
          );
        }
        if(parsed<0n)throw new Error('PS_RUN_ARG: Nat argument cannot be negative');
        return parsed;
      }
      case 'Int':
        try{return BigInt(value);}
        catch{
          throw new Error(
            "PS_RUN_ARG: Int argument must be an integer, got '"+value+"'",
          );
        }
      case 'UInt8':
      case 'UInt16':
      case 'UInt32':
      case 'UInt64':{
        let parsed:bigint;
        try{parsed=BigInt(value);}
        catch{
          throw new Error(
            'PS_RUN_ARG: '+type.name+
            " argument must be an integer, got '"+value+"'",
          );
        }
        const bits={
          UInt8:8n,
          UInt16:16n,
          UInt32:32n,
          UInt64:64n,
        }[type.name];
        const limit=1n<<bits;
        if(parsed<0n||parsed>=limit){
          throw new Error(
            'PS_RUN_ARG: '+type.name+
            ' argument is outside [0, '+(limit-1n).toString()+']',
          );
        }
        return type.name==='UInt64'?parsed:Number(parsed);
      }
      case 'Bool':
        if(value==='true')return true;
        if(value==='false')return false;
        throw new Error("PS_RUN_ARG: Bool argument must be 'true' or 'false'");
      case 'String':
        return value;
      case 'Unit':
        if(value==='()'||value==='unit')return undefined;
        throw new Error("PS_RUN_ARG: Unit argument must be '()' or 'unit'");
    }
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
