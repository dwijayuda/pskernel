import type {
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';

export type VerifiedPrimitiveName=
  Extract<VerifiedIrType,{kind:'primitive'}>['name'];

function uintBits(
  name:VerifiedPrimitiveName,
):bigint|undefined {
  switch(name){
    case 'UInt8':return 8n;
    case 'UInt16':return 16n;
    case 'UInt32':return 32n;
    case 'UInt64':return 64n;
    default:return undefined;
  }
}

function uintLimit(name:VerifiedPrimitiveName):bigint|undefined {
  const bits=uintBits(name);
  return bits===undefined?undefined:1n<<bits;
}

function parseInteger(text:string,label:string):bigint {
  try{return BigInt(text);}
  catch{
    throw new Error(
      "PS_RUN_ARG: "+label+
      " argument must be an integer, got '"+text+"'",
    );
  }
}

export function parseVerifiedPrimitiveArgument(
  value:string,
  name:VerifiedPrimitiveName,
):unknown {
  switch(name){
    case 'Nat':{
      const parsed=parseInteger(value,name);
      if(parsed<0n){
        throw new Error('PS_RUN_ARG: Nat argument cannot be negative');
      }
      return parsed;
    }
    case 'Int':
      return parseInteger(value,name);
    case 'UInt8':
    case 'UInt16':
    case 'UInt32':
    case 'UInt64':{
      const parsed=parseInteger(value,name);
      const limit=uintLimit(name)!;
      if(parsed<0n||parsed>=limit){
        throw new Error(
          'PS_RUN_ARG: '+name+
          ' argument is outside [0, '+(limit-1n).toString()+']',
        );
      }
      return name==='UInt64'?parsed:Number(parsed);
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

export function decodeVerifiedJsonPrimitive(
  value:unknown,
  name:VerifiedPrimitiveName,
  fail:(message:string)=>never,
):unknown {
  if(name==='Nat'){
    if(typeof value!=='string'||!/^\d+$/u.test(value)){
      fail('nested Nat values must be decimal JSON strings');
    }
    return BigInt(value);
  }
  if(name==='Int'){
    if(typeof value!=='string'||!(/^-?\d+$/u).test(value)){
      fail('nested Int values must be decimal JSON strings');
    }
    return BigInt(value);
  }
  if(name==='UInt8'||name==='UInt16'||name==='UInt32'){
    const limit=uintLimit(name)!;
    if(
      typeof value!=='number'||
      !Number.isInteger(value)||
      value<0||
      BigInt(value)>=limit
    ){
      fail(
        'nested '+name+' values must be in-range JSON integers',
      );
    }
    return value;
  }
  if(name==='UInt64'){
    if(typeof value!=='string'||!/^\d+$/u.test(value)){
      fail('nested UInt64 values must be decimal JSON strings');
    }
    const parsed=BigInt(value);
    if(parsed>=uintLimit(name)!){
      fail('nested UInt64 value is outside its 64-bit range');
    }
    return parsed;
  }
  if(name==='Bool'){
    if(typeof value!=='boolean'){
      fail('nested Bool values must be JSON booleans');
    }
    return value;
  }
  if(name==='String'){
    if(typeof value!=='string'){
      fail('nested String values must be JSON strings');
    }
    return value;
  }
  if(value!==null)fail('nested Unit values must be JSON null');
  return undefined;
}

export function encodeVerifiedPrimitiveResult(
  value:unknown,
  name:VerifiedPrimitiveName,
  fail:(message:string)=>never,
):unknown {
  if(name==='Nat'||name==='Int'){
    if(typeof value!=='bigint'){
      fail(
        name+
        ' result did not use the verified bigint runtime representation',
      );
    }
    return value.toString();
  }
  if(name==='UInt8'||name==='UInt16'||name==='UInt32'){
    const limit=uintLimit(name)!;
    if(
      typeof value!=='number'||
      !Number.isInteger(value)||
      value<0||
      BigInt(value)>=limit
    ){
      fail(name+' result is outside its verified unsigned range');
    }
    return value;
  }
  if(name==='UInt64'){
    const limit=uintLimit(name)!;
    if(
      typeof value!=='bigint'||
      value<0n||
      value>=limit
    ){
      fail('UInt64 result is outside its verified unsigned range');
    }
    return value.toString();
  }
  if(name==='Bool'){
    if(typeof value!=='boolean')fail('Bool result is not a boolean');
    return value;
  }
  if(name==='String'){
    if(typeof value!=='string')fail('String result is not a string');
    return value;
  }
  if(value!==undefined)fail('Unit result is not undefined');
  return null;
}
