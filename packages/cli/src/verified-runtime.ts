import type {
  VerifiedIrDeclaration,
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';

export function parseVerifiedRuntimeArg(
  value:string,
  type:VerifiedIrType,
):unknown {
  if(type.kind!=='primitive'){
    throw new Error(
      'PS_RUN_VERIFIED_ARG_TYPE: verified main arguments currently support '+
      'only Nat, Int, Bool, String, and Unit',
    );
  }

  switch(type.name){
    case 'Nat':{
      let parsed:bigint;
      try{parsed=BigInt(value);}
      catch{
        throw new Error(
          "PS_RUN_ARG: Nat argument must be an integer, got '"+value+"'",
        );
      }
      if(parsed<0n){
        throw new Error('PS_RUN_ARG: Nat argument cannot be negative');
      }
      return parsed;
    }
    case 'Int':
      try{return BigInt(value);}
      catch{
        throw new Error(
          "PS_RUN_ARG: Int argument must be an integer, got '"+value+"'",
        );
      }
    case 'Bool':
      if(value==='true')return true;
      if(value==='false')return false;
      throw new Error(
        "PS_RUN_ARG: Bool argument must be 'true' or 'false'",
      );
    case 'String':
      return value;
    case 'Unit':
      if(value==='()'||value==='unit')return undefined;
      throw new Error(
        "PS_RUN_ARG: Unit argument must be '()' or 'unit'",
      );
  }
}

export function prepareVerifiedMainArguments(
  declaration:VerifiedIrDeclaration,
  values:readonly string[],
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
    parseVerifiedRuntimeArg(values[index]!,parameter.type)
  );
}
