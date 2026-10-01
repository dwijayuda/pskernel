export type Nat=bigint;
export type Int=bigint;
export type UInt8=number;

export function nat(value:bigint|number|string):Nat{
  const result=typeof value==='bigint'?value:BigInt(value);
  if(result<0n)throw new RangeError('Nat cannot be negative');
  return result;
}
export const int=(value:bigint|number|string):Int=>typeof value==='bigint'?value:BigInt(value);
export const natAdd=(a:Nat,b:Nat):Nat=>a+b;
export const natMul=(a:Nat,b:Nat):Nat=>a*b;
export const natSub=(a:Nat,b:Nat):Nat=>a>=b?a-b:0n;

export function uint8(value:number|bigint):UInt8{
  const n=typeof value==='bigint'?Number(value%256n):value;
  if(!Number.isFinite(n)||!Number.isInteger(n))throw new RangeError('UInt8 input must be an integer');
  return ((n%256)+256)%256;
}

export interface RuntimeCtor {
  readonly tag:string;
  readonly fields:readonly unknown[];
}
export function ctor(tag:string,...fields:readonly unknown[]):RuntimeCtor{
  if(tag.length===0)throw new Error('constructor tag must be non-empty');
  return {tag,fields};
}
