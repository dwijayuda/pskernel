import { Environment, KernelError } from '../../core/environment.js';
import { Expr, app, bvar, constant, forallE, fvar, lam, mkAppN, sort } from '../../core/expr.js';
import { levelSucc, levelZero } from '../../core/level.js';
import { LocalContext } from '../../core/local-context.js';
import { lift } from '../../core/instantiate.js';
import { nameFromDotted } from '../../core/name.js';
import { N } from '../names.js';
import { TypeChecker } from '../type-checker.js';

const Nat=()=>constant(N.Nat);
const Bool=()=>constant(N.Bool);
const tru=()=>constant(N.BoolTrue);

/** Build `Eq Bool a b` at universe 0. */
function boolEq(a:Expr,b:Expr):Expr{return mkAppN(constant(N.Eq,[levelSucc(levelZero)]),[Bool(),a,b]);}

/** Build `Bool.decEq b true`. */
function boolDecTrue(b:Expr):Expr{return mkAppN(constant(N.BoolDecEq),[b,tru()]);}

/** Build `@ite Nat (b = true) (Bool.decEq b true) t e`. */
function boolIteNat(b:Expr,t:Expr,e:Expr):Expr{
  return mkAppN(constant(N.Ite,[levelSucc(levelZero)]),[Nat(),boolEq(b,tru()),boolDecTrue(b),t,e]);
}

/**
 * Certify the Boolean condition machinery used by Lean's primitive recognizers.
 *
 * This mirrors the observable obligations in Lean4Lean `Condition.bool.check`:
 * the specialized `ite` must typecheck as a Nat choice and must select the
 * first/second branch for `true`/`false`.  We intentionally prove these through
 * the current kernel's own defeq rather than trusting the declaration names.
 */
export function checkBoolCondition(env:Environment):void{
  for(const n of [N.Nat,N.Bool,N.BoolFalse,N.BoolTrue,N.Eq,N.BoolDecEq,N.Ite]){
    if(!env.has(n))throw new KernelError(`boolean primitive condition dependency is missing`);
  }
  const lctx=new LocalContext();
  const bid=lctx.fresh('b');lctx.addLocal(bid,nameFromDotted('b'),Bool());
  const tid=lctx.fresh('t');lctx.addLocal(tid,nameFromDotted('t'),Nat());
  const eid=lctx.fresh('e');lctx.addLocal(eid,nameFromDotted('e'),Nat());
  const b=fvar(bid),t=fvar(tid),e=fvar(eid),tc=new TypeChecker(env,lctx);
  const symbolic=boolIteNat(b,t,e);
  const ty=tc.check(symbolic);
  if(!tc.isDefEq(ty,Nat()))throw new KernelError('boolean primitive condition ite has the wrong result type');
  if(!tc.isDefEq(boolIteNat(constant(N.BoolTrue),t,e),t))throw new KernelError('boolean primitive condition does not select the true branch');
  if(!tc.isDefEq(boolIteNat(constant(N.BoolFalse),t,e),e))throw new KernelError('boolean primitive condition does not select the false branch');
}


/** Independently certify the generic `ite` / `dite` eliminators used by reflected conditions. */
function checkGenericConditionControl(env:Environment,{ite=false,dite=false}:{ite?:boolean;dite?:boolean}):void{
  const required=[N.Nat,N.Decidable,N.DecidableIsTrue,N.DecidableIsFalse,N.Not];
  if(ite)required.push(N.Ite);if(dite)required.push(N.Dite);
  for(const n of required)if(!env.has(n))throw new KernelError('primitive condition control dependency is missing');
  const lctx=new LocalContext();
  const pid=lctx.fresh('p');lctx.addLocal(pid,nameFromDotted('p'),sort(levelZero));
  const p=fvar(pid),np=not(p);
  const hpId=lctx.fresh('hp');lctx.addLocal(hpId,nameFromDotted('hp'),p);
  const hnId=lctx.fresh('hn');lctx.addLocal(hnId,nameFromDotted('hn'),np);
  const tId=lctx.fresh('t');lctx.addLocal(tId,nameFromDotted('t'),Nat());
  const eId=lctx.fresh('e');lctx.addLocal(eId,nameFromDotted('e'),Nat());
  const hp=fvar(hpId),hn=fvar(hnId),t=fvar(tId),e=fvar(eId),tc=new TypeChecker(env,lctx);
  if(ite){
    const it=(d:Expr)=>mkAppN(constant(N.Ite,[levelSucc(levelZero)]),[Nat(),p,d,t,e]);
    if(!tc.isDefEq(it(isTrue(p,hp)),t))throw new KernelError('ite does not select a certified true branch');
    if(!tc.isDefEq(it(isFalse(p,hn)),e))throw new KernelError('ite does not select a certified false branch');
  }
  if(dite){
    const tf=lam(nameFromDotted('_hp'),p,lift(t));
    const ef=lam(nameFromDotted('_hn'),np,lift(e));
    const dt=(d:Expr)=>mkAppN(constant(N.Dite,[levelSucc(levelZero)]),[Nat(),p,d,tf,ef]);
    if(!tc.isDefEq(dt(isTrue(p,hp)),t))throw new KernelError('dite does not select a certified true branch');
    if(!tc.isDefEq(dt(isFalse(p,hn)),e))throw new KernelError('dite does not select a certified false branch');
  }
}

/** Build `LE.le (α := Nat) instLENat a b`. */
function natLe(a:Expr,b:Expr):Expr{
  return mkAppN(constant(N.LELe,[levelZero]),[Nat(),constant(N.InstLENat),a,b]);
}
function decidable(p:Expr):Expr{return app(constant(N.Decidable),p);}
function not(p:Expr):Expr{return app(constant(N.Not),p);}
function isTrue(p:Expr,h:Expr):Expr{return mkAppN(constant(N.DecidableIsTrue),[p,h]);}
function isFalse(p:Expr,h:Expr):Expr{return mkAppN(constant(N.DecidableIsFalse),[p,h]);}
function natBle(a:Expr,b:Expr):Expr{return mkAppN(constant(N.NatBle),[a,b]);}
function natDecLe(a:Expr,b:Expr):Expr{return mkAppN(constant(N.NatDecLe),[a,b]);}

/**
 * Build the logical model of `Nat.decLe` from `Nat.ble` and the two reflection lemmas.
 * This is the definition in Lean 4.34 `Init.Prelude` rather than a finite sample of inputs.
 */
function expectedNatDecLe():Expr{
  const n=bvar(1),m=bvar(0),b=natBle(n,m),c=boolEq(b,tru()),p=natLe(n,m);
  const t=lam(nameFromDotted('h'),c,isTrue(lift(p),mkAppN(constant(N.NatLeOfBleTrue),[lift(n),lift(m),bvar(0)])));
  const nc=not(c);
  const e=lam(nameFromDotted('h'),nc,isFalse(lift(p),mkAppN(constant(N.NatNotLeOfNotBleTrue),[lift(n),lift(m),bvar(0)])));
  const body=mkAppN(constant(N.Dite,[levelSucc(levelZero)]),[decidable(p),c,boolDecTrue(b),t,e]);
  return lam(nameFromDotted('n'),Nat(),lam(nameFromDotted('m'),Nat(),body));
}

/**
 * Certify Lean 4.34's reflected Nat `≤` condition machinery.
 *
 * Obligations:
 *  - the reflected relation and decision procedure are well typed,
 *  - `Nat.decLe` is definitionally equal to the logical model using `Nat.ble`,
 *  - `dite` actually selects its proof-carrying true/false branches.
 *
 * The last check prevents a malicious `dite` from making the first equality vacuous.
 */
export function checkNatLeCondition(env:Environment):void{
  for(const n of [N.Nat,N.Bool,N.BoolFalse,N.BoolTrue,N.Eq,N.BoolDecEq,N.NatBle,N.LE,N.LELe,N.InstLENat,N.Decidable,N.DecidableIsTrue,N.DecidableIsFalse,N.Not,N.Dite,N.NatDecLe,N.NatLeOfBleTrue,N.NatNotLeOfNotBleTrue]){
    if(!env.has(n))throw new KernelError('Nat ≤ primitive condition dependency is missing');
  }
  const tc=new TypeChecker(env);
  const expected=expectedNatDecLe();
  const expectedTy=tc.check(expected);
  const actualTy=tc.check(constant(N.NatDecLe));
  if(!tc.isDefEq(expectedTy,actualTy)||!tc.isDefEq(constant(N.NatDecLe),expected))
    throw new KernelError('Nat.decLe does not implement the Lean 4.34 Nat.ble reflection model');

  // Independently certify dependent-if computation for arbitrary propositions/proofs.
  const lctx=new LocalContext();
  const pid=lctx.fresh('p');lctx.addLocal(pid,nameFromDotted('p'),sort(levelZero));
  const p=fvar(pid),np=not(p);
  const hpId=lctx.fresh('hp');lctx.addLocal(hpId,nameFromDotted('hp'),p);
  const hnId=lctx.fresh('hn');lctx.addLocal(hnId,nameFromDotted('hn'),np);
  const tId=lctx.fresh('t');lctx.addLocal(tId,nameFromDotted('t'),forallE(nameFromDotted('_'),p,Nat()));
  const eId=lctx.fresh('e');lctx.addLocal(eId,nameFromDotted('e'),forallE(nameFromDotted('_'),np,Nat()));
  const hp=fvar(hpId),hn=fvar(hnId),t=fvar(tId),e=fvar(eId),ltc=new TypeChecker(env,lctx);
  const dt=(d:Expr)=>mkAppN(constant(N.Dite,[levelSucc(levelZero)]),[Nat(),p,d,t,e]);
  if(!ltc.isDefEq(dt(isTrue(p,hp)),app(t,hp)))throw new KernelError('dite does not select the Nat ≤ true branch correctly');
  if(!ltc.isDefEq(dt(isFalse(p,hn)),app(e,hn)))throw new KernelError('dite does not select the Nat ≤ false branch correctly');
}


/** Build `Eq Nat a b`. */
function natEq(a:Expr,b:Expr):Expr{return mkAppN(constant(N.Eq,[levelSucc(levelZero)]),[Nat(),a,b]);}
function natBeq(a:Expr,b:Expr):Expr{return mkAppN(constant(N.NatBeq),[a,b]);}
function eqRefl(type:Expr,value:Expr):Expr{return mkAppN(constant(N.EqRefl,[levelSucc(levelZero)]),[type,value]);}

/**
 * Lean 4.34 logical model of `Nat.decEq`.
 *
 * This is the dependent `match h : Nat.beq n m` from `Init.Prelude`, represented
 * directly with `Bool.rec`.  Keeping the equality motive explicit makes the check
 * independent of concrete test numerals and certifies the open-term equation.
 */
export function buildNatDecEqModel():Expr{
  return lam(nameFromDotted('n'),Nat(),lam(nameFromDotted('m'),Nat(),(()=>{
    const n=bvar(1),m=bvar(0),b=natBeq(n,m),p=natEq(n,m);
    // motive b' := Nat.beq n m = b' -> Decidable (n = m)
    const motive=lam(nameFromDotted('b'),Bool(),forallE(
      nameFromDotted('h'),boolEq(lift(b),bvar(0)),decidable(lift(p,2))));
    const falseCase=lam(nameFromDotted('h'),boolEq(b,constant(N.BoolFalse)),
      isFalse(lift(p),mkAppN(constant(N.NatNeOfBeqFalse),[lift(n),lift(m),bvar(0)])));
    const trueCase=lam(nameFromDotted('h'),boolEq(b,constant(N.BoolTrue)),
      isTrue(lift(p),mkAppN(constant(N.NatEqOfBeqTrue),[lift(n),lift(m),bvar(0)])));
    const rec=mkAppN(constant(N.BoolRec,[levelSucc(levelZero)]),[motive,falseCase,trueCase,b]);
    return app(rec,eqRefl(Bool(),b));
  })()));
}

/** Certify Lean 4.34's reflected natural-number equality decision procedure. */
export function checkNatEqCondition(env:Environment):void{
  for(const n of [N.Nat,N.Bool,N.BoolFalse,N.BoolTrue,N.BoolRec,N.Eq,N.EqRefl,N.Decidable,N.DecidableIsTrue,N.DecidableIsFalse,N.Not,N.NatBeq,N.NatDecEq,N.NatEqOfBeqTrue,N.NatNeOfBeqFalse]){
    if(!env.has(n))throw new KernelError('Nat = primitive condition dependency is missing');
  }
  const tc=new TypeChecker(env),expected=buildNatDecEqModel();
  const expectedTy=tc.check(expected),actualTy=tc.check(constant(N.NatDecEq));
  if(!tc.isDefEq(expectedTy,actualTy)||!tc.isDefEq(constant(N.NatDecEq),expected))
    throw new KernelError('Nat.decEq does not implement the Lean 4.34 Nat.beq reflection model');
  // Lean 4.34's bitwise recognizer consumes both reflected `ite` and proof-carrying `dite`.
  // Certify those eliminators independently so a malicious control operator cannot make the
  // reflected equality equation vacuously pass.
  checkGenericConditionControl(env,{ite:true,dite:true});
}
