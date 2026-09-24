/**
 * Lean 4.34 JavaScript runtime compatibility primitives.
 *
 * This module is untrusted executable support. It must never be used as proof
 * authority: declarations are checked by pskernel before executable lowering.
 */

export type LeanNat=bigint;
export type LeanInt=bigint;
export type LeanUInt8=number;
export type LeanUInt16=number;
export type LeanUInt32=number;
export type LeanUInt64=bigint;
export type LeanUSize=bigint;
export type LeanChar=string;
export type LeanString=string;
export type LeanArray<T>=readonly T[];

export const LEAN434_JS_RUNTIME_VERSION='0.1.0';
export const LEAN434_SOURCE_VERSION='4.34.0';
export const LEAN434_SOURCE_GITHASH='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';
export const LEAN434_USIZE_BITS=64 as const;

function assertNat(value:bigint,name:string):void{
  if(value<0n)throw new RangeError(name+' must be a Nat');
}

function natIndex(index:bigint,length:number,name:string):number{
  assertNat(index,name);
  if(index>=BigInt(length))throw new RangeError(name+' is out of bounds');
  const n=Number(index);
  if(!Number.isSafeInteger(n))throw new RangeError(name+' exceeds JavaScript safe index range');
  return n;
}

function uintMask(bits:number):bigint{
  return (1n<<BigInt(bits))-1n;
}

function normalizeUIntNumber(value:bigint,bits:8|16|32):number{
  return Number(value&uintMask(bits));
}

export function lean_nat_add(a:LeanNat,b:LeanNat):LeanNat{
  assertNat(a,'lean_nat_add lhs');
  assertNat(b,'lean_nat_add rhs');
  return a+b;
}

export function lean_nat_mul(a:LeanNat,b:LeanNat):LeanNat{
  assertNat(a,'lean_nat_mul lhs');
  assertNat(b,'lean_nat_mul rhs');
  return a*b;
}

export function lean_nat_sub(a:LeanNat,b:LeanNat):LeanNat{
  assertNat(a,'lean_nat_sub lhs');
  assertNat(b,'lean_nat_sub rhs');
  return a>=b?a-b:0n;
}

export function lean_nat_div(a:LeanNat,b:LeanNat):LeanNat{
  assertNat(a,'lean_nat_div lhs');
  assertNat(b,'lean_nat_div rhs');
  return b===0n?0n:a/b;
}

export function lean_nat_mod(a:LeanNat,b:LeanNat):LeanNat{
  assertNat(a,'lean_nat_mod lhs');
  assertNat(b,'lean_nat_mod rhs');
  return b===0n?a:a%b;
}

export const lean_nat_dec_eq=(a:LeanNat,b:LeanNat):boolean=>a===b;
export const lean_nat_dec_le=(a:LeanNat,b:LeanNat):boolean=>a<=b;
export const lean_nat_dec_lt=(a:LeanNat,b:LeanNat):boolean=>a<b;

export const lean_uint8_of_nat=(value:LeanNat):LeanUInt8=>
  normalizeUIntNumber(value,8);
export const lean_uint16_of_nat=(value:LeanNat):LeanUInt16=>
  normalizeUIntNumber(value,16);
export const lean_uint32_of_nat=(value:LeanNat):LeanUInt32=>
  normalizeUIntNumber(value,32);
export const lean_uint64_of_nat=(value:LeanNat):LeanUInt64=>
  value&uintMask(64);
export const lean_usize_of_nat=(value:LeanNat):LeanUSize=>
  value&uintMask(LEAN434_USIZE_BITS);

export const lean_uint32_to_nat=(value:LeanUInt32):LeanNat=>
  BigInt(value>>>0);
export const lean_uint64_to_nat=(value:LeanUInt64):LeanNat=>
  value&uintMask(64);
export const lean_usize_to_nat=(value:LeanUSize):LeanNat=>
  value&uintMask(LEAN434_USIZE_BITS);

export const lean_uint8_dec_eq=(a:LeanUInt8,b:LeanUInt8):boolean=>a===b;
export const lean_uint8_dec_lt=(a:LeanUInt8,b:LeanUInt8):boolean=>a<b;
export const lean_uint8_dec_le=(a:LeanUInt8,b:LeanUInt8):boolean=>a<=b;
export const lean_uint16_dec_eq=(a:LeanUInt16,b:LeanUInt16):boolean=>a===b;
export const lean_uint32_dec_eq=(a:LeanUInt32,b:LeanUInt32):boolean=>a===b;
export const lean_uint32_dec_lt=(a:LeanUInt32,b:LeanUInt32):boolean=>a<b;
export const lean_uint32_dec_le=(a:LeanUInt32,b:LeanUInt32):boolean=>a<=b;
export const lean_uint64_dec_eq=(a:LeanUInt64,b:LeanUInt64):boolean=>a===b;
export const lean_usize_dec_eq=(a:LeanUSize,b:LeanUSize):boolean=>a===b;

/**
 * Lean arrays have value semantics. The native runtime uses copy-on-write as an
 * optimization; this compatibility layer always returns fresh arrays for
 * mutating-looking pure operations.
 */
export function lean_mk_empty_array_with_capacity<T>(_capacity:LeanNat):T[]{
  return [];
}

export function lean_array_get_size<T>(array:LeanArray<T>):LeanNat{
  return BigInt(array.length);
}

export function lean_array_push<T>(array:LeanArray<T>,value:T):T[]{
  return [...array,value];
}

export function lean_array_fget<T>(array:LeanArray<T>,index:LeanNat):T{
  return array[natIndex(index,array.length,'lean_array_fget index')]!;
}

export const lean_array_fget_borrowed=lean_array_fget;

export function lean_array_fset<T>(
  array:LeanArray<T>,
  index:LeanNat,
  value:T,
):T[]{
  const i=natIndex(index,array.length,'lean_array_fset index');
  const out=[...array];
  out[i]=value;
  return out;
}

export function lean_array_set<T>(
  array:LeanArray<T>,
  index:LeanNat,
  value:T,
):LeanArray<T>{
  assertNat(index,'lean_array_set index');
  if(index>=BigInt(array.length))return array;
  return lean_array_fset(array,index,value);
}

function utf8Width(char:LeanChar):bigint{
  const cp=char.codePointAt(0)??0;
  if(cp<=0x7f)return 1n;
  if(cp<=0x7ff)return 2n;
  if(cp<=0xffff)return 3n;
  return 4n;
}

function charAtUtf8BytePos(value:LeanString,pos:LeanNat):LeanChar|undefined{
  assertNat(pos,'UTF-8 byte position');
  let offset=0n;
  for(const char of value){
    if(offset===pos)return char;
    if(offset>pos)return undefined;
    offset+=utf8Width(char);
  }
  return undefined;
}

export function lean_string_length(value:LeanString):LeanNat{
  return BigInt(Array.from(value).length);
}

export function lean_string_utf8_byte_size(value:LeanString):LeanNat{
  let size=0n;
  for(const char of value)size+=utf8Width(char);
  return size;
}

export const lean_string_dec_eq=(a:LeanString,b:LeanString):boolean=>a===b;

export function lean_string_append(a:LeanString,b:LeanString):LeanString{
  return a+b;
}

export function lean_string_utf8_get(value:LeanString,pos:LeanNat):LeanChar{
  // Lean's documented fallback for an invalid raw position is default Char = 'A'.
  return charAtUtf8BytePos(value,pos)??'A';
}

export function lean_string_utf8_next(value:LeanString,pos:LeanNat):LeanNat{
  assertNat(pos,'lean_string_utf8_next position');
  let offset=0n;
  for(const char of value){
    const width=utf8Width(char);
    if(offset===pos)return pos+width;
    if(offset>pos)return pos+1n;
    offset+=width;
  }
  return pos+1n;
}

export function lean_string_utf8_prev(value:LeanString,pos:LeanNat):LeanNat{
  assertNat(pos,'lean_string_utf8_prev position');
  if(pos===0n)return 0n;
  let offset=0n;
  let previous=0n;
  for(const char of value){
    const next=offset+utf8Width(char);
    if(pos<=next)return offset;
    previous=offset;
    offset=next;
  }
  return pos>offset?pos-1n:previous;
}

export function lean_string_utf8_at_end(value:LeanString,pos:LeanNat):boolean{
  assertNat(pos,'lean_string_utf8_at_end position');
  return pos>=lean_string_utf8_byte_size(value);
}

export function lean_string_is_valid_pos(value:LeanString,pos:LeanNat):boolean{
  assertNat(pos,'lean_string_is_valid_pos position');
  const end=lean_string_utf8_byte_size(value);
  if(pos===end)return true;
  if(pos>end)return false;
  let offset=0n;
  for(const char of value){
    if(offset===pos)return true;
    if(offset>pos)return false;
    offset+=utf8Width(char);
  }
  return false;
}

export function lean_string_utf8_extract(
  value:LeanString,
  begin:LeanNat,
  end:LeanNat,
):LeanString{
  assertNat(begin,'lean_string_utf8_extract begin');
  assertNat(end,'lean_string_utf8_extract end');
  if(begin>=end)return '';
  let offset=0n;
  let started=false;
  let out='';
  for(const char of value){
    const width=utf8Width(char);
    if(!started){
      if(offset===begin)started=true;
      else{
        offset+=width;
        continue;
      }
    }
    if(offset===end)return out;
    out+=char;
    offset+=width;
  }
  return out;
}

const REF_EMPTY=Symbol('lean-st-ref-empty');

export class LeanRefEmptyError extends Error{
  constructor(operation:string){
    super(operation+' attempted to access an empty Lean ST.Ref');
    this.name='LeanRefEmptyError';
  }
}

/**
 * Single-threaded bootstrap representation of Lean ST.Ref.
 *
 * Native Lean may block a thread that reads/takes an empty multi-threaded ref.
 * The first JS runtime has no implicit blocking scheduler, so empty access
 * fails closed. Task-aware blocking can be introduced with the scheduler layer.
 */
export class LeanRef<T>{
  private slot:T|typeof REF_EMPTY;
  constructor(value:T){this.slot=value;}
  get():T{
    if(this.slot===REF_EMPTY)throw new LeanRefEmptyError('get');
    return this.slot;
  }
  set(value:T):void{this.slot=value;}
  swap(value:T):T{
    const previous=this.get();
    this.slot=value;
    return previous;
  }
  take():T{
    const previous=this.get();
    this.slot=REF_EMPTY;
    return previous;
  }
  get isEmpty():boolean{return this.slot===REF_EMPTY;}
}

export const lean_st_mk_ref=<T>(value:T):LeanRef<T>=>new LeanRef(value);
export const lean_st_ref_get=<T>(ref:LeanRef<T>):T=>ref.get();
export const lean_st_ref_set=<T>(ref:LeanRef<T>,value:T):void=>ref.set(value);
export const lean_st_ref_swap=<T>(ref:LeanRef<T>,value:T):T=>ref.swap(value);
export const lean_st_ref_take=<T>(ref:LeanRef<T>):T=>ref.take();
export const lean_st_ref_ptr_eq=<T,U>(a:LeanRef<T>,b:LeanRef<U>):boolean=>
  (a as unknown)===(b as unknown);

export type Lean434ExternCategory=
  |'pure-primitive'
  |'persistent-value'
  |'mutable-state';

export interface Lean434ExternDescriptor{
  readonly leanSymbol:string;
  readonly jsExport:string;
  readonly category:Lean434ExternCategory;
  readonly upstreamSource:string;
}

/**
 * Implemented externs only. Planned/unsupported symbols do not appear here and
 * must fail closed in the compiler until an explicit mapping is added.
 */
export const LEAN434_JS_EXTERN_MANIFEST:readonly Lean434ExternDescriptor[]=[
  {leanSymbol:'lean_nat_add',jsExport:'lean_nat_add',category:'pure-primitive',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_nat_mul',jsExport:'lean_nat_mul',category:'pure-primitive',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_nat_sub',jsExport:'lean_nat_sub',category:'pure-primitive',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_nat_div',jsExport:'lean_nat_div',category:'pure-primitive',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_nat_mod',jsExport:'lean_nat_mod',category:'pure-primitive',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_nat_dec_eq',jsExport:'lean_nat_dec_eq',category:'pure-primitive',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_nat_dec_le',jsExport:'lean_nat_dec_le',category:'pure-primitive',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_nat_dec_lt',jsExport:'lean_nat_dec_lt',category:'pure-primitive',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_mk_empty_array_with_capacity',jsExport:'lean_mk_empty_array_with_capacity',category:'persistent-value',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_array_get_size',jsExport:'lean_array_get_size',category:'persistent-value',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_array_push',jsExport:'lean_array_push',category:'persistent-value',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_array_fget',jsExport:'lean_array_fget',category:'persistent-value',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_array_fget_borrowed',jsExport:'lean_array_fget_borrowed',category:'persistent-value',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_array_fset',jsExport:'lean_array_fset',category:'persistent-value',upstreamSource:'Init/Data/Array/Set.lean'},
  {leanSymbol:'lean_array_set',jsExport:'lean_array_set',category:'persistent-value',upstreamSource:'Init/Data/Array/Set.lean'},
  {leanSymbol:'lean_string_length',jsExport:'lean_string_length',category:'persistent-value',upstreamSource:'Init/Data/String/Length.lean'},
  {leanSymbol:'lean_string_dec_eq',jsExport:'lean_string_dec_eq',category:'persistent-value',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_string_utf8_byte_size',jsExport:'lean_string_utf8_byte_size',category:'persistent-value',upstreamSource:'Init/Prelude.lean'},
  {leanSymbol:'lean_string_utf8_get',jsExport:'lean_string_utf8_get',category:'persistent-value',upstreamSource:'Init/Data/String/Basic.lean'},
  {leanSymbol:'lean_string_utf8_next',jsExport:'lean_string_utf8_next',category:'persistent-value',upstreamSource:'Init/Data/String/Basic.lean'},
  {leanSymbol:'lean_string_utf8_prev',jsExport:'lean_string_utf8_prev',category:'persistent-value',upstreamSource:'Init/Data/String/Basic.lean'},
  {leanSymbol:'lean_string_utf8_at_end',jsExport:'lean_string_utf8_at_end',category:'persistent-value',upstreamSource:'Init/Data/String/Basic.lean'},
  {leanSymbol:'lean_string_is_valid_pos',jsExport:'lean_string_is_valid_pos',category:'persistent-value',upstreamSource:'Init/Data/String/Basic.lean'},
  {leanSymbol:'lean_string_utf8_extract',jsExport:'lean_string_utf8_extract',category:'persistent-value',upstreamSource:'Init/Data/String/Basic.lean'},
  {leanSymbol:'lean_st_mk_ref',jsExport:'lean_st_mk_ref',category:'mutable-state',upstreamSource:'Init/System/ST.lean'},
  {leanSymbol:'lean_st_ref_get',jsExport:'lean_st_ref_get',category:'mutable-state',upstreamSource:'Init/System/ST.lean'},
  {leanSymbol:'lean_st_ref_set',jsExport:'lean_st_ref_set',category:'mutable-state',upstreamSource:'Init/System/ST.lean'},
  {leanSymbol:'lean_st_ref_swap',jsExport:'lean_st_ref_swap',category:'mutable-state',upstreamSource:'Init/System/ST.lean'},
  {leanSymbol:'lean_st_ref_take',jsExport:'lean_st_ref_take',category:'mutable-state',upstreamSource:'Init/System/ST.lean'},
  {leanSymbol:'lean_st_ref_ptr_eq',jsExport:'lean_st_ref_ptr_eq',category:'mutable-state',upstreamSource:'Init/System/ST.lean'},
] as const;

const externBySymbol=new Map(
  LEAN434_JS_EXTERN_MANIFEST.map((entry)=>[entry.leanSymbol,entry] as const),
);

export function findLean434JsExtern(
  leanSymbol:string,
):Lean434ExternDescriptor|undefined{
  return externBySymbol.get(leanSymbol);
}


export type Lean434ExternEffect='pure'|'st-action';

export interface Lean434DeclarationExternBinding {
  readonly leanDeclaration:string;
  readonly leanSymbol:string;
  /** Full kernel-expression arity, including erased type/proof arguments. */
  readonly arity:number;
  /**
   * ST primitives are compiled as direct runtime calls in native Lean because
   * the world token is erased. The source evaluator must re-wrap them as state
   * actions so Lean-written ST/IO bind code observes the correct semantics.
   */
  readonly effect?:Lean434ExternEffect;
  /**
   * Indices from the full application argument list forwarded to the JS
   * extern. Omitted means every argument is runtime-relevant.
   */
  readonly runtimeArgs?:readonly number[];
  readonly upstreamSource:string;
}

/**
 * High-level declaration bindings that are representation-compatible with the
 * bootstrap JS evaluator today.
 *
 * This is intentionally stricter than LEAN434_JS_EXTERN_MANIFEST. A low-level
 * Lean extern may use a native calling convention or optimized representation
 * that is not yet identical to the evaluator's high-level runtime value.
 */
export const LEAN434_JS_DECL_EXTERN_BINDINGS:
readonly Lean434DeclarationExternBinding[]=[
  {
    leanDeclaration:'Nat.add',
    leanSymbol:'lean_nat_add',
    arity:2,
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Nat.mul',
    leanSymbol:'lean_nat_mul',
    arity:2,
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Nat.sub',
    leanSymbol:'lean_nat_sub',
    arity:2,
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Nat.div',
    leanSymbol:'lean_nat_div',
    arity:2,
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Nat.modCore',
    leanSymbol:'lean_nat_mod',
    arity:2,
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Nat.beq',
    leanSymbol:'lean_nat_dec_eq',
    arity:2,
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Nat.ble',
    leanSymbol:'lean_nat_dec_le',
    arity:2,
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Array.mkEmpty',
    leanSymbol:'lean_mk_empty_array_with_capacity',
    arity:2,
    runtimeArgs:[1],
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Array.emptyWithCapacity',
    leanSymbol:'lean_mk_empty_array_with_capacity',
    arity:2,
    runtimeArgs:[1],
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Array.size',
    leanSymbol:'lean_array_get_size',
    arity:2,
    runtimeArgs:[1],
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Array.getInternalBorrowed',
    leanSymbol:'lean_array_fget_borrowed',
    arity:4,
    runtimeArgs:[1,2],
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Array.getInternal',
    leanSymbol:'lean_array_fget',
    arity:4,
    runtimeArgs:[1,2],
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Array.push',
    leanSymbol:'lean_array_push',
    arity:3,
    runtimeArgs:[1,2],
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'Array.set',
    leanSymbol:'lean_array_fset',
    arity:5,
    runtimeArgs:[1,2,3],
    upstreamSource:'Init/Data/Array/Set.lean',
  },
  {
    leanDeclaration:'Array.set!',
    leanSymbol:'lean_array_set',
    arity:4,
    runtimeArgs:[1,2,3],
    upstreamSource:'Init/Data/Array/Set.lean',
  },
  {
    leanDeclaration:'String.length',
    leanSymbol:'lean_string_length',
    arity:1,
    upstreamSource:'Init/Data/String/Length.lean',
  },
  {
    leanDeclaration:'String.utf8ByteSize',
    leanSymbol:'lean_string_utf8_byte_size',
    arity:1,
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'ST.Prim.mkRef',
    leanSymbol:'lean_st_mk_ref',
    arity:3,
    runtimeArgs:[2],
    effect:'st-action',
    upstreamSource:'Init/System/ST.lean',
  },
  {
    leanDeclaration:'ST.Prim.Ref.get',
    leanSymbol:'lean_st_ref_get',
    arity:3,
    runtimeArgs:[2],
    effect:'st-action',
    upstreamSource:'Init/System/ST.lean',
  },
  {
    leanDeclaration:'ST.Prim.Ref.set',
    leanSymbol:'lean_st_ref_set',
    arity:4,
    runtimeArgs:[2,3],
    effect:'st-action',
    upstreamSource:'Init/System/ST.lean',
  },
  {
    leanDeclaration:'ST.Prim.Ref.swap',
    leanSymbol:'lean_st_ref_swap',
    arity:4,
    runtimeArgs:[2,3],
    effect:'st-action',
    upstreamSource:'Init/System/ST.lean',
  },
  {
    leanDeclaration:'ST.Prim.Ref.take',
    leanSymbol:'lean_st_ref_take',
    arity:3,
    runtimeArgs:[2],
    effect:'st-action',
    upstreamSource:'Init/System/ST.lean',
  },
  {
    leanDeclaration:'ST.Prim.Ref.ptrEq',
    leanSymbol:'lean_st_ref_ptr_eq',
    arity:4,
    runtimeArgs:[2,3],
    effect:'st-action',
    upstreamSource:'Init/System/ST.lean',
  },
] as const;

const declarationExternByName=new Map(
  LEAN434_JS_DECL_EXTERN_BINDINGS.map(
    (entry)=>[entry.leanDeclaration,entry] as const,
  ),
);

export function findLean434JsExternForDeclaration(
  leanDeclaration:string,
):Lean434DeclarationExternBinding|undefined{
  return declarationExternByName.get(leanDeclaration);
}

type Lean434JsExternImplementation=
  (...args:readonly unknown[])=>unknown;

const jsExternImplementations:
ReadonlyMap<string,Lean434JsExternImplementation>=
new Map<string,Lean434JsExternImplementation>([
  ['lean_nat_add',(a,b)=>lean_nat_add(a as LeanNat,b as LeanNat)],
  ['lean_nat_mul',(a,b)=>lean_nat_mul(a as LeanNat,b as LeanNat)],
  ['lean_nat_sub',(a,b)=>lean_nat_sub(a as LeanNat,b as LeanNat)],
  ['lean_nat_div',(a,b)=>lean_nat_div(a as LeanNat,b as LeanNat)],
  ['lean_nat_mod',(a,b)=>lean_nat_mod(a as LeanNat,b as LeanNat)],
  ['lean_nat_dec_eq',(a,b)=>lean_nat_dec_eq(a as LeanNat,b as LeanNat)],
  ['lean_nat_dec_le',(a,b)=>lean_nat_dec_le(a as LeanNat,b as LeanNat)],
  ['lean_mk_empty_array_with_capacity',(capacity)=>
    lean_mk_empty_array_with_capacity(capacity as LeanNat)],
  ['lean_array_get_size',(array)=>
    lean_array_get_size(array as LeanArray<unknown>)],
  ['lean_array_push',(array,value)=>
    lean_array_push(array as LeanArray<unknown>,value)],
  ['lean_array_fget',(array,index)=>
    lean_array_fget(array as LeanArray<unknown>,index as LeanNat)],
  ['lean_array_fget_borrowed',(array,index)=>
    lean_array_fget_borrowed(array as LeanArray<unknown>,index as LeanNat)],
  ['lean_array_fset',(array,index,value)=>
    lean_array_fset(
      array as LeanArray<unknown>,
      index as LeanNat,
      value,
    )],
  ['lean_array_set',(array,index,value)=>
    lean_array_set(
      array as LeanArray<unknown>,
      index as LeanNat,
      value,
    )],
  ['lean_string_length',(value)=>
    lean_string_length(value as LeanString)],
  ['lean_string_utf8_byte_size',(value)=>
    lean_string_utf8_byte_size(value as LeanString)],
]);

export function invokeLean434JsExtern(
  leanSymbol:string,
  args:readonly unknown[],
):unknown{
  const descriptor=findLean434JsExtern(leanSymbol);
  if(descriptor===undefined){
    throw new Error(
      "Lean 4.34 JS extern is not in the pinned manifest: '"+leanSymbol+"'",
    );
  }
  const implementation=jsExternImplementations.get(leanSymbol);
  if(implementation===undefined){
    throw new Error(
      "Lean 4.34 JS extern has no high-level evaluator adapter: '"+
      leanSymbol+"'",
    );
  }
  return implementation(...args);
}


export type Lean434ImplementedByAdapter='identity';

export interface Lean434ImplementedByBinding {
  readonly leanDeclaration:string;
  readonly implementation:string;
  readonly arity:number;
  readonly adapter:Lean434ImplementedByAdapter;
  readonly upstreamSource:string;
}

/**
 * Selected high-level @[implemented_by] bindings whose runtime representation
 * is understood by the JS bootstrap evaluator.
 *
 * These bindings affect execution only. The logical declaration admitted by
 * pskernel is unchanged.
 */
export const LEAN434_JS_IMPLEMENTED_BY_BINDINGS:
readonly Lean434ImplementedByBinding[]=[
  {
    leanDeclaration:'TSyntaxArray.raw',
    implementation:'TSyntaxArray.rawImpl',
    arity:1,
    adapter:'identity',
    upstreamSource:'Init/Prelude.lean',
  },
  {
    leanDeclaration:'TSyntaxArray.mk',
    implementation:'TSyntaxArray.mkImpl',
    arity:1,
    adapter:'identity',
    upstreamSource:'Init/Prelude.lean',
  },
] as const;

const implementedByByDeclaration=new Map(
  LEAN434_JS_IMPLEMENTED_BY_BINDINGS.map(
    (entry)=>[entry.leanDeclaration,entry] as const,
  ),
);

export function findLean434JsImplementedBy(
  leanDeclaration:string,
):Lean434ImplementedByBinding|undefined{
  return implementedByByDeclaration.get(leanDeclaration);
}

export function invokeLean434JsImplementedBy(
  binding:Lean434ImplementedByBinding,
  args:readonly unknown[],
):unknown{
  if(args.length!==binding.arity){
    throw new Error(
      "Lean 4.34 implemented_by arity mismatch for '"+
      binding.leanDeclaration+"'",
    );
  }
  switch(binding.adapter){
    case 'identity':
      return args[0];
  }
}
