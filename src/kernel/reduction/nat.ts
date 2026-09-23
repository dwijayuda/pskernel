import { Environment, KernelError } from '../../core/environment.js';
import { Expr, appView, constant, mkAppN, natLit } from '../../core/expr.js';
import { nameEq } from '../../core/name.js';
import { N } from '../names.js';

export const LEAN_NAT_MAX_SIZE_DEFAULT = 128n * 1024n * 1024n;
export const UINT32_MAX = 0xffff_ffffn;

/** Lean 4.34's 64-bit runtime storage metric (lean_nat_size_in_bytes).
 * Scalar Nats occupy one machine word. Heap MPZ values are rounded to whole
 * 64-bit limbs, not to the mathematical minimum byte length. */
export const LEAN_RUNTIME_WORD_BYTES=8n;
export const LEAN_MAX_SMALL_NAT=(1n<<63n)-1n;
export function natSizeInBytes(n:bigint):bigint{
  if(n<0n)throw new KernelError('Nat cannot be negative');
  if(n<=LEAN_MAX_SMALL_NAT)return LEAN_RUNTIME_WORD_BYTES;
  const bits=BigInt(n.toString(2).length);
  const limbs=(bits+63n)/64n;
  return limbs*LEAN_RUNTIME_WORD_BYTES;
}
export function checkNatSize(n:bigint,maxBytes:bigint,op='Nat numeral'):void{
  if(natSizeInBytes(n)>maxBytes)throw new KernelError(`the kernel refused a \`${op}\` numeral because its size exceeds the maximum; increase the LEAN_NAT_MAX_SIZE environment variable to allow it`);
}
/** Final Lean 4.34 `is_nat_lit_ext` / `get_nat_val` boundary:
 * optimized Nat evaluation recognizes only literal numerals and the level-free
 * constant `Nat.zero`. Constructor syntax such as `Nat.succ Nat.zero` is not
 * reinterpreted as a literal by this fast path. */
export function asNat(e:Expr):bigint|null{
  if(e.kind==='lit'&&e.literal.kind==='nat')return e.literal.value;
  if(e.kind==='const'&&e.levels.length===0&&nameEq(e.name,N.NatZero))return 0n;
  return null;
}
function boolExpr(v:boolean):Expr{return constant(v?N.BoolTrue:N.BoolFalse);}
function gcd(a:bigint,b:bigint):bigint{while(b!==0n){const t=a%b;a=b;b=t;}return a;}
function getCountArg(count:bigint,op:string):bigint{if(count>UINT32_MAX)throw new KernelError(`the kernel refused to evaluate \`${op}\` because its second argument does not fit in a 32-bit unsigned integer`);return count;}
function powChecked(base:bigint,exp:bigint,maxBytes:bigint):bigint{
  const k=getCountArg(exp,'Nat.pow');
  if(base>1n&&k!==0n&&natSizeInBytes(base)>maxBytes/k)throw new KernelError('the kernel refused to evaluate `Nat.pow` because the result would exceed the maximum numeral size; increase the LEAN_NAT_MAX_SIZE environment variable to allow it');
  let r=1n,x=base,n=exp;while(n>0n){if(n&1n)r*=x;n>>=1n;if(n)x*=x;}return r;
}
function shiftLeftChecked(v:bigint,shift:bigint,maxBytes:bigint):bigint{
  if(v===0n)return 0n;
  const k=getCountArg(shift,'Nat.shiftLeft');
  if(natSizeInBytes(v)+k/8n+1n>maxBytes)throw new KernelError('the kernel refused a `Nat` numeral because its size exceeds the maximum; increase the LEAN_NAT_MAX_SIZE environment variable to allow it');
  return v<<k;
}
function shiftRight(v:bigint,shift:bigint):bigint{
  if(v===0n)return 0n;
  // Avoid asking the JS engine to materialize an enormous shift count; mathematically it is zero
  // once the shift exceeds the value's bit length.
  const bits=BigInt(v.toString(2).length);return shift>=bits?0n:v>>shift;
}

export function reduceNatApp(_env:Environment,e:Expr,whnf:(x:Expr)=>Expr,maxBytes:bigint=LEAN_NAT_MAX_SIZE_DEFAULT):Expr|null{
  const {fn,args}=appView(e);if(fn.kind!=='const'||fn.levels.length!==0)return null;
  const unarySucc=():Expr|null=>{if(args.length!==1)return null;const a=asNat(whnf(args[0]!));if(a===null)return null;const r=a+1n;checkNatSize(r,maxBytes,'Nat.succ');return natLit(r);};
  const binary=(f:(a:bigint,b:bigint)=>bigint,op:string,checkResult=false):Expr|null=>{if(args.length!==2)return null;const a=asNat(whnf(args[0]!)),b=asNat(whnf(args[1]!));if(a===null||b===null)return null;const r=f(a,b);if(checkResult)checkNatSize(r,maxBytes,op);return natLit(r);};
  if(nameEq(fn.name,N.NatSucc))return unarySucc();
  if(nameEq(fn.name,N.NatAdd))return binary((a,b)=>a+b,'Nat.add',true);
  if(nameEq(fn.name,N.NatSub))return binary((a,b)=>a>b?a-b:0n,'Nat.sub',true);
  if(nameEq(fn.name,N.NatMul))return binary((a,b)=>a*b,'Nat.mul',true);
  if(nameEq(fn.name,N.NatPow)){
    if(args.length!==2)return null;const a=asNat(whnf(args[0]!)),b=asNat(whnf(args[1]!));return a===null||b===null?null:natLit(powChecked(a,b,maxBytes));
  }
  if(nameEq(fn.name,N.NatGcd))return binary(gcd,'Nat.gcd');
  if(nameEq(fn.name,N.NatMod))return binary((a,b)=>b===0n?a:a%b,'Nat.mod');
  if(nameEq(fn.name,N.NatDiv))return binary((a,b)=>b===0n?0n:a/b,'Nat.div');
  if(nameEq(fn.name,N.NatLand))return binary((a,b)=>a&b,'Nat.land');
  if(nameEq(fn.name,N.NatLor))return binary((a,b)=>a|b,'Nat.lor');
  if(nameEq(fn.name,N.NatXor))return binary((a,b)=>a^b,'Nat.xor');
  if(nameEq(fn.name,N.NatShiftLeft)){
    if(args.length!==2)return null;const a=asNat(whnf(args[0]!)),b=asNat(whnf(args[1]!));return a===null||b===null?null:natLit(shiftLeftChecked(a,b,maxBytes));
  }
  if(nameEq(fn.name,N.NatShiftRight))return binary(shiftRight,'Nat.shiftRight');
  if(nameEq(fn.name,N.NatBeq)&&args.length===2){const a=asNat(whnf(args[0]!)),b=asNat(whnf(args[1]!));return a===null||b===null?null:boolExpr(a===b);}
  if(nameEq(fn.name,N.NatBle)&&args.length===2){const a=asNat(whnf(args[0]!)),b=asNat(whnf(args[1]!));return a===null||b===null?null:boolExpr(a<=b);}
  return null;
}
export function natToCtor(n:bigint):Expr{return n===0n?constant(N.NatZero):mkAppN(constant(N.NatSucc),[natLit(n-1n)]);}
