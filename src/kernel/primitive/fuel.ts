import { DefinitionInfo } from '../../core/declaration.js';
import { Environment, KernelError } from '../../core/environment.js';
import { Expr, app, bvar, constant, forallE, fvar, lam, mkAppN } from '../../core/expr.js';
import { abstractFVar } from '../../core/instantiate.js';
import { levelSucc, levelZero } from '../../core/level.js';
import { LocalContext } from '../../core/local-context.js';
import { Name, nameFromDotted, nameToString } from '../../core/name.js';
import { N } from '../names.js';
import { TypeChecker } from '../type-checker.js';
import { checkNatLeCondition } from './condition.js';

const Nat=()=>constant(N.Nat);
const zero=()=>constant(N.NatZero);
const succ=(x:Expr)=>app(constant(N.NatSucc),x);
const one=()=>succ(zero());
const sub=(a:Expr,b:Expr)=>mkAppN(constant(N.NatSub),[a,b]);
const le=(a:Expr,b:Expr)=>mkAppN(constant(N.LELe,[levelZero]),[Nat(),constant(N.InstLENat),a,b]);
const decLe=(a:Expr,b:Expr)=>mkAppN(constant(N.NatDecLe),[a,b]);
const not=(p:Expr)=>app(constant(N.Not),p);

function requireDep(env:Environment,n:Name):void{if(!env.has(n))throw new KernelError(`Nat fuel-recursion primitive dependency '${nameToString(n)}' is missing`);}
function app2(f:Expr,a:Expr,b:Expr):Expr{return mkAppN(f,[a,b]);}
function app5(f:Expr,a:Expr,b:Expr,c:Expr,d:Expr,e:Expr):Expr{return mkAppN(f,[a,b,c,d,e]);}
function app6(f:Expr,a:Expr,b:Expr,c:Expr,d:Expr,e:Expr,g:Expr):Expr{return mkAppN(f,[a,b,c,d,e,g]);}

function iteLe(a:Expr,b:Expr,t:Expr,e:Expr):Expr{
  return mkAppN(constant(N.Ite,[levelSucc(levelZero)]),[Nat(),le(a,b),decLe(a,b),t,e]);
}

/** Build a dependent Nat conditional and abstract only its branch proof. */
function diteLe(lctx:LocalContext,a:Expr,b:Expr,
  onTrue:(h:Expr)=>Expr,onFalse:(h:Expr)=>Expr):Expr{
  const p=le(a,b),tctx=lctx.clone(),tid=tctx.fresh('hle');
  tctx.addLocal(tid,nameFromDotted('hle'),p);const th=fvar(tid),tb=onTrue(th);
  const fctx=lctx.clone(),np=not(p),fid=fctx.fresh('hnle');
  fctx.addLocal(fid,nameFromDotted('hnle'),np);const fh=fvar(fid),fb=onFalse(fh);
  return mkAppN(constant(N.Dite,[levelSucc(levelZero)]),[
    Nat(),p,decLe(a,b),
    lam(nameFromDotted('hle'),p,abstractFVar(tb,tid)),
    lam(nameFromDotted('hnle'),np,abstractFVar(fb,fid))
  ]);
}

function expectedGoType():Expr{
  // ∀ y, 1 ≤ y → ∀ fuel x, succ x ≤ fuel → Nat
  return forallE(nameFromDotted('y'),Nat(),
    forallE(nameFromDotted('hy'),le(one(),bvar(0)),
      forallE(nameFromDotted('fuel'),Nat(),
        forallE(nameFromDotted('x'),Nat(),
          forallE(nameFromDotted('h'),le(succ(bvar(0)),bvar(1)),Nat())))));
}

export interface NatFuelRecConfig {
  readonly goName: Name;
  readonly topUsesSuccInput: boolean;
  readonly topUsesOuterIte: boolean;
  readonly recursiveResult: (x:Expr)=>Expr;
  readonly stopResult: (x:Expr)=>Expr;
}

/**
 * Certify the fuel recursion shared by Lean 4.34 `Nat.mod` and `Nat.div`.
 *
 * This mirrors the two universal equations checked by Lean4Lean's
 * `checkNatFuelRec`: the public wrapper equation and the generated `go`
 * equation.  All proof arguments are checked by the TypeChecker; only proof
 * identity is ignored through Lean proof irrelevance.
 */
export function checkNatFuelRec(env:Environment,v:DefinitionInfo,cfg:NatFuelRecConfig):void{
  const required=[N.Nat,N.NatZero,N.NatSucc,N.NatSub,N.Bool,N.LE,N.LELe,N.InstLENat,N.NatDecLe,N.Dite,N.Not,cfg.goName,N.NatDivRecFuelLemma,N.NatLtSuccSelf];
  if(cfg.topUsesOuterIte)required.push(N.Ite);
  for(const n of required)requireDep(env,n);
  checkNatLeCondition(env);
  const tc0=new TypeChecker(env);
  const go=constant(cfg.goName),goTy=tc0.check(go);
  if(!tc0.isDefEq(goTy,expectedGoType()))throw new KernelError('Nat fuel-recursion go declaration has the wrong type');

  const lctx=new LocalContext();
  const xid=lctx.fresh('x');lctx.addLocal(xid,nameFromDotted('x'),Nat());const x=fvar(xid);
  const yid=lctx.fresh('y');lctx.addLocal(yid,nameFromDotted('y'),Nat());const y=fvar(yid);
  const tc=new TypeChecker(env,lctx),sx=succ(x);

  let top:Expr;
  if(cfg.topUsesOuterIte){
    const inner=diteLe(lctx,one(),y,
      hy=>app5(go,y,hy,succ(sx),sx,app(constant(N.NatLtSuccSelf),sx)),
      _=>sx);
    top=iteLe(y,sx,inner,sx);
  }else{
    top=diteLe(lctx,one(),y,
      hy=>app5(go,y,hy,succ(x),x,app(constant(N.NatLtSuccSelf),x)),
      _=>zero());
  }
  const lhsInput=cfg.topUsesSuccInput?sx:x;
  const topLhs=app2(v.value,lhsInput,y);
  tc.check(top);if(!tc.isDefEq(topLhs,top))throw new KernelError('Nat fuel-recursion wrapper equation failed');

  const hyid=lctx.fresh('hy');lctx.addLocal(hyid,nameFromDotted('hy'),le(one(),y));const hy=fvar(hyid);
  const fuelid=lctx.fresh('fuel');lctx.addLocal(fuelid,nameFromDotted('fuel'),Nat());const fuel=fvar(fuelid);
  const hid=lctx.fresh('h');lctx.addLocal(hid,nameFromDotted('h'),le(succ(x),succ(fuel)));const h=fvar(hid);
  const gtc=new TypeChecker(env,lctx);
  const rhs=diteLe(lctx,y,x,
    hle=>{
      const pf=app6(constant(N.NatDivRecFuelLemma),x,y,fuel,hy,hle,h);
      const rec=app5(go,y,hy,fuel,sub(x,y),pf);
      return cfg.recursiveResult(rec);
    },
    _=>cfg.stopResult(x));
  const goLhs=app5(go,y,hy,succ(fuel),x,h);
  gtc.check(rhs);if(!gtc.isDefEq(goLhs,rhs))throw new KernelError('Nat fuel-recursion go equation failed');
}
