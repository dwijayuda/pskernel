import type {
  VerifiedIrIntrinsicOperation,
} from '@proofscript/compiler-ir/verified';

const binaryRuntimeIntrinsics=
  new Map<string,VerifiedIrIntrinsicOperation>([
    ['Nat.add','nat.add'],
    ['Nat.sub','nat.sub'],
    ['Nat.mul','nat.mul'],
    ['Nat.div','nat.div'],
    ['Nat.mod','nat.mod'],
    ['Nat.beq','nat.eq'],
    ['UInt8.add','uint8.add'],
    ['UInt16.add','uint16.add'],
    ['UInt32.add','uint32.add'],
    ['UInt64.add','uint64.add'],
  ]);

export function verifiedBinaryRuntimeIntrinsic(
  constantName:string,
):VerifiedIrIntrinsicOperation|undefined {
  return binaryRuntimeIntrinsics.get(constantName);
}
