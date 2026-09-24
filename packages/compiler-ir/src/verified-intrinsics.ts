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
} as const satisfies Readonly<Record<VerifiedIrIntrinsicOperation,1|2>>;

export function verifiedIrIntrinsicArity(
  operation:VerifiedIrIntrinsicOperation,
):1|2 {
  return VERIFIED_IR_INTRINSIC_ARITY[operation];
}
