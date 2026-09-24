import type {
  VerifiedIrExpr,
  VerifiedIrIntrinsicOperation,
} from '@proofscript/compiler-ir/verified';

type EmitExpr=(expr:VerifiedIrExpr)=>string;

export function emitVerifiedArrayIntrinsic(
  operation:VerifiedIrIntrinsicOperation,
  args:readonly VerifiedIrExpr[],
  emit:EmitExpr,
):string|undefined {
  if(operation==='array.emptyWithCapacity'){
    return '(() => { void ('+emit(args[0]!)+'); return []; })()';
  }
  if(operation==='array.size'){
    return 'BigInt(('+emit(args[0]!)+').length)';
  }
  if(operation==='array.push'){
    return '[...('+emit(args[0]!)+'), '+emit(args[1]!)+']';
  }
  if(operation==='array.get'){
    return '(<T>(__ps_a: readonly T[], __ps_i: bigint): T => '+
      '__ps_a[Number(__ps_i)]!)('+
      emit(args[0]!)+', '+emit(args[1]!)+')';
  }
  if(operation==='array.getD'){
    return '(<T>(__ps_a: readonly T[], __ps_i: bigint, '+
      '__ps_fallback: T): T => '+
      '(__ps_i < BigInt(__ps_a.length) '+
      '? __ps_a[Number(__ps_i)]! : __ps_fallback))('+
      emit(args[0]!)+', '+emit(args[1]!)+', '+emit(args[2]!)+')';
  }
  return undefined;
}
