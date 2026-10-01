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
    return '(<T>(__ps_a: T[], __ps_i: bigint): T => '+
      '__ps_a[Number(__ps_i)]!)('+
      emit(args[0]!)+', '+emit(args[1]!)+')';
  }
  if(operation==='array.getD'){
    return '(<T>(__ps_a: T[], __ps_i: bigint, '+
      '__ps_fallback: T): T => '+
      '(__ps_i < BigInt(__ps_a.length) '+
      '? __ps_a[Number(__ps_i)]! : __ps_fallback))('+
      emit(args[0]!)+', '+emit(args[1]!)+', '+emit(args[2]!)+')';
  }
  if(operation==='array.set'){
    return '(<T>(__ps_a: T[], __ps_i: bigint, __ps_v: T): T[] => {'+
      ' const __ps_out = [...__ps_a]; __ps_out[Number(__ps_i)] = __ps_v; '+
      'return __ps_out; })('+
      emit(args[0]!)+', '+emit(args[1]!)+', '+emit(args[2]!)+')';
  }
  if(operation==='array.setIfInBounds'){
    return '(<T>(__ps_a: T[], __ps_i: bigint, __ps_v: T): '+
      'T[] => { if (__ps_i >= BigInt(__ps_a.length)) return __ps_a; '+
      'const __ps_out = [...__ps_a]; __ps_out[Number(__ps_i)] = __ps_v; '+
      'return __ps_out; })('+
      emit(args[0]!)+', '+emit(args[1]!)+', '+emit(args[2]!)+')';
  }
  if(operation==='array.map'){
    return '(<A, B>(__ps_f: (__ps_x: A) => B, __ps_a: A[]): B[] => '+
      '__ps_a.map((__ps_x) => __ps_f(__ps_x)))('+
      emit(args[0]!)+', '+emit(args[1]!)+')';
  }
  if(operation==='array.foldl'){
    return '(<A, B>(__ps_f: (__ps_b: B, __ps_x: A) => B, __ps_init: B, '+
      '__ps_a: A[], __ps_start: bigint, __ps_stop: bigint): B => {'+
      ' const __ps_size = BigInt(__ps_a.length); '+
      'const __ps_end = __ps_stop <= __ps_size ? __ps_stop : __ps_size; '+
      'let __ps_acc = __ps_init; '+
      'for (let __ps_i = __ps_start; __ps_i < __ps_end; __ps_i += 1n) {'+
      ' __ps_acc = __ps_f(__ps_acc, __ps_a[Number(__ps_i)]!); } '+
      'return __ps_acc; })('+
      emit(args[0]!)+', '+emit(args[1]!)+', '+emit(args[2]!)+', '+
      emit(args[3]!)+', '+emit(args[4]!)+')';
  }
  return undefined;
}
