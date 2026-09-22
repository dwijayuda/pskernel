import { DefinitionInfo } from '../../core/declaration.js';
import { Environment, KernelError } from '../../core/environment.js';
import { Expr, app, bvar, constant, forallE, fvar, lam, mkAppN } from '../../core/expr.js';
import { levelSucc, levelZero } from '../../core/level.js';
import { LocalContext } from '../../core/local-context.js';
import { nameFromDotted } from '../../core/name.js';
import { N } from '../names.js';
import { TypeChecker } from '../type-checker.js';
import { checkBoolCondition, checkNatEqCondition } from './condition.js';
import { inspectNatWellFoundedIn, NatWfProbe, probeNatWellFounded } from './wf.js';

const Nat=()=>constant(N.Nat);
const Bool=()=>constant(N.Bool);
const zero=()=>constant(N.NatZero);
const succ=(x:Expr)=>app(constant(N.NatSucc),x);
const one=()=>succ(zero());
const two=()=>succ(one());
const tru=()=>constant(N.BoolTrue);
const fal=()=>constant(N.BoolFalse);
const arrow=(a:Expr,b:Expr)=>forallE(nameFromDotted('_'),a,b);
const bool2=()=>arrow(Bool(),arrow(Bool(),Bool()));
const nat2=()=>arrow(Nat(),arrow(Nat(),Nat()));
const bitwiseType=()=>arrow(bool2(),nat2());
const app2=(f:Expr,a:Expr,b:Expr)=>app(app(f,a),b);
const natEq=(a:Expr,b:Expr)=>mkAppN(constant(N.Eq,[levelSucc(levelZero)]),[Nat(),a,b]);
const natDecEq=(a:Expr,b:Expr)=>mkAppN(constant(N.NatDecEq),[a,b]);
const boolEqTrue=(b:Expr)=>mkAppN(constant(N.Eq,[levelSucc(levelZero)]),[Bool(),b,tru()]);
const boolDecTrue=(b:Expr)=>mkAppN(constant(N.BoolDecEq),[b,tru()]);
const not=(p:Expr)=>app(constant(N.Not),p);

function ite(resultType:Expr,p:Expr,d:Expr,t:Expr,e:Expr):Expr{
  return mkAppN(constant(N.Ite,[levelSucc(levelZero)]),[resultType,p,d,t,e]);
}
function natEqIte(resultType:Expr,a:Expr,b:Expr,t:Expr,e:Expr):Expr{
  const p=natEq(a,b);return ite(resultType,p,natDecEq(a,b),t,e);
}
function natEqDecide(a:Expr,b:Expr):Expr{return natEqIte(Bool(),a,b,tru(),fal());}
function boolIteNat(b:Expr,t:Expr,e:Expr):Expr{return ite(Nat(),boolEqTrue(b),boolDecTrue(b),t,e);}

/**
 * Build the proof-carrying outer `if n = 0 then ... else ...` used by Lean 4.34 Nat.bitwise.
 * The false branch receives the proof `n ≠ 0`; the recursive decrease proof must be derived from it.
 */
function natEqDiteNat(a:Expr,b:Expr,t:Expr,mkFalse:(hNe:Expr)=>Expr):Expr{
  const p=natEq(a,b),np=not(p);
  const tFn=lam(nameFromDotted('_h'),p,t);
  const eFn=lam(nameFromDotted('hNe'),np,mkFalse(bvar(0)));
  return mkAppN(constant(N.Dite,[levelSucc(levelZero)]),[Nat(),p,natDecEq(a,b),tFn,eFn]);
}

function recursiveResult(P:NatWfProbe,f:Expr,n:Expr,m:Expr,ih:Expr,hNe:Expr):Expr{
  const n2=app2(constant(N.NatDiv),n,two()),m2=app2(constant(N.NatDiv),m,two());
  const b1=natEqDecide(app2(constant(N.NatMod),n,two()),one());
  const b2=natEqDecide(app2(constant(N.NatMod),m,two()),one());
  const packed=mkAppN(P.pack,[n2,m2]);
  // Match Lean 4.34's compiled well-founded body exactly.  This private proof has a
  // numeric Name component (`...Basic.<num 0>...`), so it must not be reconstructed from a dotted string.
  const decrease=mkAppN(constant(N.NatBitwiseUnaryProof1),[n,m,hNe]);
  const r=app(app(ih,packed),decrease),rr=app2(constant(N.NatAdd),r,r);
  return boolIteNat(app2(f,b1,b2),app2(constant(N.NatAdd),rr,one()),rr);
}

/**
 * Check the universally quantified defining equation after the generic well-founded skeleton
 * has already been certified. Exported for a bounded equation-level regression test; production
 * admission reaches it only through `checkNatBitwise` below.
 */
export function probeNatBitwiseEquation(tc:TypeChecker,P:NatWfProbe,f:Expr,n:Expr,m:Expr):void{
  probeNatWellFounded(tc,P,[n,m],(ih)=>{
    const nZero=boolIteNat(app2(f,fal(),tru()),m,zero());
    return natEqDiteNat(n,zero(),nZero,(hNe)=>{
      const mZero=boolIteNat(app2(f,tru(),fal()),n,zero());
      return natEqIte(Nat(),m,zero(),mZero,recursiveResult(P,f,n,m,ih,hNe));
    });
  });
}

/** Lean 4.34 semantic recognizer for the primitive `Nat.bitwise` definition. */
export function checkNatBitwise(env:Environment,v:DefinitionInfo):void{
  for(const dep of [N.Nat,N.Bool,N.NatAdd,N.NatMod,N.NatDiv,N.NatBitwiseUnaryProof1]){
    if(!env.has(dep))throw new KernelError('Nat.bitwise primitive dependency is missing');
  }
  if(v.levelParams.length!==0||v.safety!=='safe')throw new KernelError('Nat.bitwise must be safe and monomorphic');
  if(!new TypeChecker(env).isDefEq(v.type,bitwiseType()))throw new KernelError('Nat.bitwise has the wrong type');
  checkNatEqCondition(env);checkBoolCondition(env);

  const lctx=new LocalContext();
  const fid=lctx.fresh('f');lctx.addLocal(fid,nameFromDotted('f'),bool2());const f=fvar(fid);
  const tcF=new TypeChecker(env,lctx);
  const measure=lam(nameFromDotted('n'),Nat(),lam(nameFromDotted('_m'),Nat(),bvar(1)));
  const P=inspectNatWellFoundedIn(tcF,app(v.value,f),measure);
  const nid=lctx.fresh('n');lctx.addLocal(nid,nameFromDotted('n'),Nat());const n=fvar(nid);
  const mid=lctx.fresh('m');lctx.addLocal(mid,nameFromDotted('m'),Nat());const m=fvar(mid);
  probeNatBitwiseEquation(new TypeChecker(env,lctx,tcF.state,tcF.limits),P,f,n,m);
}
