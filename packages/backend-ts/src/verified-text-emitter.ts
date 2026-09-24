import type {
  VerifiedIrExpr,
  VerifiedIrIntrinsicOperation,
} from '@proofscript/compiler-ir/verified';

type EmitExpr=(expr:VerifiedIrExpr)=>string;

function utf8WidthBody(charName:string):string {
  return 'const __ps_cp = '+charName+'.codePointAt(0) ?? 0; '+
    'const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : '+
    '__ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); ';
}

function emitUtf8ByteSize(value:string):string {
  return '((__ps_s: string) => { let __ps_n = 0n; '+
    'for (const __ps_c of __ps_s) { '+
    utf8WidthBody('__ps_c')+
    '__ps_n += __ps_w; } return __ps_n; })('+value+')';
}

function emitNext(value:string,pos:string):string {
  return '((__ps_s: string, __ps_p: bigint) => { let __ps_i = 0n; '+
    'for (const __ps_c of __ps_s) { '+
    utf8WidthBody('__ps_c')+
    'if (__ps_i === __ps_p) return __ps_p + __ps_w; '+
    'if (__ps_i > __ps_p) return __ps_p + 1n; '+
    '__ps_i += __ps_w; } return __ps_p + 1n; })('+
    value+', '+pos+')';
}

function emitGet(value:string,pos:string):string {
  return '((__ps_s: string, __ps_p: bigint) => { let __ps_i = 0n; '+
    'for (const __ps_c of __ps_s) { '+
    'if (__ps_i === __ps_p) return __ps_c; '+
    'if (__ps_i > __ps_p) return "A"; '+
    utf8WidthBody('__ps_c')+
    '__ps_i += __ps_w; } return "A"; })('+value+', '+pos+')';
}

function emitExtract(value:string,start:string,stop:string):string {
  return '((__ps_s: string, __ps_b: bigint, __ps_e: bigint) => { '+
    'if (__ps_b >= __ps_e) return ""; let __ps_i = 0n; '+
    'let __ps_started = false; let __ps_out = ""; '+
    'for (const __ps_c of __ps_s) { '+
    utf8WidthBody('__ps_c')+
    'if (!__ps_started) { if (__ps_i === __ps_b) __ps_started = true; '+
    'else { __ps_i += __ps_w; continue; } } '+
    'if (__ps_i === __ps_e) return __ps_out; '+
    '__ps_out += __ps_c; __ps_i += __ps_w; } return __ps_out; })('+
    value+', '+start+', '+stop+')';
}

export function emitVerifiedTextIntrinsic(
  operation:VerifiedIrIntrinsicOperation,
  args:readonly VerifiedIrExpr[],
  emit:EmitExpr,
):string|undefined {
  if(operation==='char.toNat'){
    return '((__ps_c: string) => BigInt(__ps_c.codePointAt(0) ?? 0))('+
      emit(args[0]!)+')';
  }
  if(operation==='string.singleton')return emit(args[0]!);
  if(operation==='string.length'){
    return '((__ps_s: string) => BigInt(Array.from(__ps_s).length))('+
      emit(args[0]!)+')';
  }
  if(operation==='string.utf8ByteSize'){
    return emitUtf8ByteSize(emit(args[0]!));
  }
  if(operation==='string.next'){
    return emitNext(emit(args[0]!),emit(args[1]!));
  }
  if(operation==='string.get'){
    return emitGet(emit(args[0]!),emit(args[1]!));
  }
  if(operation==='string.atEnd'){
    const value=emit(args[0]!);
    const pos=emit(args[1]!);
    return '('+pos+' >= '+emitUtf8ByteSize(value)+')';
  }
  if(operation==='string.extract'){
    return emitExtract(
      emit(args[0]!),
      emit(args[1]!),
      emit(args[2]!),
    );
  }
  if(operation==='string.push'||operation==='string.append'){
    return '('+emit(args[0]!)+' + '+emit(args[1]!)+')';
  }
  return undefined;
}
