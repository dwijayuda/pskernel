import type {VerifiedIrIntrinsicOperation} from './verified-model.js';

export const VERIFIED_IR_INTRINSIC_ARITY={
  'nat.add':2,
  'nat.sub':2,
  'nat.mul':2,
  'nat.div':2,
  'nat.mod':2,
  'nat.eq':2,
  'nat.ne':2,
  'nat.le':2,
  'nat.lt':2,
  'bool.not':1,
  'bool.and':2,
  'bool.or':2,
  'bool.eq':2,
  'bool.ne':2,
  'char.ofNat':1,
  'char.toNat':1,
  'string.push':2,
  'string.singleton':1,
  'string.length':1,
  'string.append':2,
  'string.utf8ByteSize':1,
  'string.next':2,
  'string.get':2,
  'string.atEnd':2,
  'string.extract':3,
} as const satisfies Readonly<Record<VerifiedIrIntrinsicOperation,1|2|3>>;

export function verifiedIrIntrinsicArity(
  operation:VerifiedIrIntrinsicOperation,
):1|2|3 {
  return VERIFIED_IR_INTRINSIC_ARITY[operation];
}
