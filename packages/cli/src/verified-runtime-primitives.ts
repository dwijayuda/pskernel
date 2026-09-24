import type {VerifiedIrType} from '@proofscript/compiler-ir/verified';

type PrimitiveName=Extract<
  VerifiedIrType,
  {kind:'primitive'}
>['name'];

export function failVerifiedAbi(message:string):never {
  throw new Error('PS_RUN_VERIFIED_ABI: '+message);
}

function assertChar(value:unknown,label:string):string {
  if(typeof value!=='string')failVerifiedAbi(label+' must be a JSON string');
  const codePoint=value.codePointAt(0);
  if(
    codePoint===undefined
    ||[...value].length!==1
    ||(codePoint>=0xd800&&codePoint<=0xdfff)
    ||codePoint>0x10ffff
  ){
    failVerifiedAbi(label+' must contain exactly one Unicode scalar value');
  }
  return value;
}

export function decodeVerifiedPrimitive(
  value:unknown,
  name:PrimitiveName,
):unknown {
  if(name==='Nat'){
    if(typeof value!=='string'||!/^\d+$/u.test(value)){
      failVerifiedAbi('nested Nat values must be decimal JSON strings');
    }
    return BigInt(value);
  }
  if(name==='Int'){
    if(typeof value!=='string'||! /-?\d+/u.test(value)){
      failVerifiedAbi('nested Int values must be decimal JSON strings');
    }
    return BigInt(value);
  }
  if(name==='Bool'){
    if(typeof value!=='boolean'){
      failVerifiedAbi('nested Bool values must be JSON booleans');
    }
    return value;
  }
  if(name==='Char')return assertChar(value,'nested Char values');
  if(name==='String'){
    if(typeof value!=='string'){
      failVerifiedAbi('nested String values must be JSON strings');
    }
    return value;
  }
  if(value!==null)failVerifiedAbi('nested Unit values must be JSON null');
  return undefined;
}

export function encodeVerifiedPrimitive(
  value:unknown,
  name:PrimitiveName,
):unknown {
  if(name==='Nat'||name==='Int'){
    if(typeof value!=='bigint'){
      failVerifiedAbi(
        name+' result did not use the verified bigint runtime representation',
      );
    }
    return value.toString();
  }
  if(name==='Bool'){
    if(typeof value!=='boolean')failVerifiedAbi('Bool result is not a boolean');
    return value;
  }
  if(name==='Char')return assertChar(value,'Char result');
  if(name==='String'){
    if(typeof value!=='string')failVerifiedAbi('String result is not a string');
    return value;
  }
  if(value!==undefined)failVerifiedAbi('Unit result is not undefined');
  return null;
}
