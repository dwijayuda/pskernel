import { Environment, KernelError } from '../../core/environment.js';
import { Expr, app, appView, constant, exprEq, exprToString, fvar, mkAppN } from '../../core/expr.js';
import { abstractFVar, instantiate1 } from '../../core/instantiate.js';
import { LocalContext } from '../../core/local-context.js';
import { Name, nameEq, nameFromDotted } from '../../core/name.js';
import { N } from '../names.js';
import { TypeChecker } from '../type-checker.js';

function child(tc:TypeChecker,lctx:LocalContext):TypeChecker {
  return new TypeChecker(tc.env,lctx,tc.state,tc.limits,tc.definitionSafety,tc.allowedLevelParams,false);
}

function containsFVarId(e:Expr,id:string):boolean {
  switch(e.kind){
    case'fvar':return e.id===id;
    case'app':return containsFVarId(e.fn,id)||containsFVarId(e.arg,id);
    case'lam':case'forall':return containsFVarId(e.type,id)||containsFVarId(e.body,id);
    case'let':return containsFVarId(e.type,id)||containsFVarId(e.value,id)||containsFVarId(e.body,id);
    case'mdata':return containsFVarId(e.expr,id);
    case'proj':return containsFVarId(e.expr,id);
    default:return false;
  }
}

export interface OpenLambdaTelescope {
  readonly fvars:readonly Expr[];
  readonly body:Expr;
  readonly tc:TypeChecker;
}

/** Open a lambda telescope without changing the caller's local context. */
export function openLambdaTelescope(tc0:TypeChecker,e0:Expr):OpenLambdaTelescope {
  const lctx=tc0.lctx.clone();let tc=child(tc0,lctx),e=e0;const fvars:Expr[]=[];
  while(e.kind==='lam'){
    const id=lctx.fresh('wf');lctx.addLocal(id,e.name,e.type,e.binderInfo);const fv=fvar(id);fvars.push(fv);e=instantiate1(e.body,fv);tc=child(tc0,lctx);
  }
  return {fvars,body:e,tc};
}

/** Close an expression over a list of free variables, preserving dependency order. */
export function closeLambda(tc:TypeChecker,fvars:readonly Expr[],body:Expr):Expr {
  let out=body;
  for(let i=fvars.length-1;i>=0;i--){
    const fv=fvars[i]!;if(fv.kind!=='fvar')throw new KernelError('closeLambda expected free variables');
    const d=tc.lctx.get(fv.id);if(!d)throw new KernelError(`missing local ${fv.id}`);
    out={kind:'lam',name:d.userName,type:d.type,body:abstractFVar(out,fv.id),binderInfo:d.kind==='local'?d.binderInfo:'default'};
  }
  return out;
}

export interface NatWfOuter {
  /** The closed recursive functional used by WellFounded.Nat.fix. */
  readonly functional:Expr;
  /** The packed argument `a₀`, closed over the primitive's recursion variables. */
  readonly pack:Expr;
  readonly measure:Expr;
  readonly fixGo:Name;
}

export interface NatWfProbe extends NatWfOuter {
  /** Domain of the induction hypothesis as a function `a ↦ Dom a`. */
  readonly domain:Expr;
}

/**
 * Validate the outer, compatibility-critical skeleton emitted for Lean's Nat-measure
 * well-founded recursion. This is the first half of Lean4Lean's `unfoldNatWellFounded`:
 * it deliberately does not yet certify the internal `fix.go` Nat.rec equation.
 *
 * Keeping this isolated prevents the gcd/bitwise recognizers from duplicating brittle
 * telescope and fixpoint inspection logic. Callers must not admit a primitive based on
 * this function alone; the inner-go equation is a separate required gate.
 */
export function inspectNatWfOuterIn(root:TypeChecker,e:Expr,measureLambda:Expr):NatWfOuter {
  const env=root.env;const opened=openLambdaTelescope(root,measureLambda);const {fvars,body:measure,tc}=opened;
  tc.check(mkAppN(e,fvars));

  let outer=tc.whnfCore(mkAppN(e,fvars));const unfolded=tc.unfold(outer);
  if(!unfolded)throw new KernelError('well-founded primitive did not expose its unary wrapper');
  outer=tc.whnfCore(unfolded);
  const fv=appView(outer);
  if(fv.fn.kind!=='const'||!nameEq(fv.fn.name,N.WfNatFix)||fv.args.length!==5)
    throw new KernelError('well-founded primitive is not a WellFounded.Nat.fix application');
  const [alpha,motive,measureFn,functional,a0]=fv.args as [Expr,Expr,Expr,Expr,Expr];
  const aTy=tc.infer(a0);const lctx=tc.lctx.clone(),aid=lctx.fresh('a');lctx.addLocal(aid,nameFromDotted('a'),aTy);const a=fvar(aid),atc=child(tc,lctx);
  const measured=app(measureFn,a);if(!atc.isDefEq(atc.check(measured),constant(N.Nat)))throw new KernelError('well-founded measure does not return Nat');
  if(!tc.isDefEq(app(measureFn,a0),measure))throw new KernelError('well-founded measure does not match the primitive termination measure');

  const fixFn=mkAppN(fv.fn,[alpha,motive,measureFn,functional]);
  const fixAtA=app(fixFn,a);const fixUnfold=atc.unfold(fixAtA);
  if(!fixUnfold)throw new KernelError('WellFounded.Nat.fix failed to unfold');
  const goView=appView(atc.whnfCore(fixUnfold));
  if(goView.fn.kind!=='const'||!nameEq(goView.fn.name,N.WfNatFixGo)||goView.args.length!==7)
    throw new KernelError('WellFounded.Nat.fix did not reduce to fix.go');
  const [alpha2,motive2,measure2,functional2,fuel,a2,proof]=goView.args as [Expr,Expr,Expr,Expr,Expr,Expr,Expr];
  if(!exprEq(alpha,alpha2)||!exprEq(motive,motive2)||!exprEq(measureFn,measure2)||!exprEq(functional,functional2)||!atc.isDefEq(a,a2))
    throw new KernelError('WellFounded.Nat.fix.go arguments drifted during unfolding');
  const fuelView=appView(fuel);
  if(fuelView.fn.kind!=='const'||!nameEq(fuelView.fn.name,N.WfNatEager)||fuelView.args.length!==1)
    throw new KernelError('WellFounded.Nat.fix fuel is not guarded by WellFounded.Nat.eager');
  const expectedFuel=app(constant(N.NatSucc),measured);
  if(!atc.isDefEq(fuelView.args[0]!,expectedFuel))throw new KernelError('WellFounded.Nat.fix fuel does not equal succ of the measure');
  if(!atc.isProp(atc.check(proof)))throw new KernelError('WellFounded.Nat.fix fuel witness is not a proof');

  for(const x of fvars)if(x.kind==='fvar'&&containsFVarId(functional,x.id))throw new KernelError('well-founded functional captures primitive recursion variables');

  return {functional,pack:closeLambda(tc,fvars,a0),measure:measureLambda,fixGo:goView.fn.name};
}

/** Environment-only convenience wrapper for primitives without surrounding local variables. */
export function inspectNatWfOuter(env:Environment,e:Expr,measureLambda:Expr):NatWfOuter {
  return inspectNatWfOuterIn(new TypeChecker(env),e,measureLambda);
}


/**
 * Validate the internal equation generated for `WellFounded.Nat.fix.go`.
 *
 * Lean's implementation is a five-lambda prefix ending in a `Nat.rec ... fuel`.
 * On `succ fuel`, the recursor must expose `F x` and an induction hypothesis
 * whose recursive target is precisely the same recursor at the predecessor.
 * This is the second half of Lean4Lean's `unfoldNatWellFounded` certificate.
 */
export function validateNatFixGoEquation(env:Environment,fixGoName:Name=N.WfNatFixGo):void {
  const info=env.get(fixGoName);
  if(info.kind!=='definition')throw new KernelError('WellFounded.Nat.fix.go is not a definition');
  const root=new TypeChecker(env),opened=openLambdaTelescope(root,info.value);
  if(opened.fvars.length!==5)throw new KernelError('WellFounded.Nat.fix.go does not have the expected five-binder prefix');
  const F=opened.fvars[3]!,t=opened.fvars[4]!;
  if(F.kind!=='fvar'||t.kind!=='fvar')throw new KernelError('invalid fix.go telescope');
  if(opened.body.kind!=='app'||!exprEq(opened.body.arg,t))throw new KernelError('WellFounded.Nat.fix.go body is not Nat.rec applied to fuel');
  const natRec=opened.body.fn;
  if(containsFVarId(natRec,t.id))throw new KernelError('WellFounded.Nat.fix.go recursor depends on fuel outside its major premise');

  // This also certifies that the fifth binder really is Nat.
  opened.tc.check(app(constant(N.NatSucc),t));
  const gor=opened.tc.whnfCore(app(natRec,app(constant(N.NatSucc),t)));
  const step=openLambdaTelescope(opened.tc,gor);
  if(step.fvars.length!==2)throw new KernelError('WellFounded.Nat.fix.go successor branch does not bind x and fuel proof');
  const x=step.fvars[0]!;
  if(step.body.kind!=='app'||!exprEq(step.body.fn,app(F,x)))throw new KernelError('WellFounded.Nat.fix.go successor branch is not F x ih');
  const ih=step.body.arg;
  const ihOpen=openLambdaTelescope(step.tc,ih);
  if(ihOpen.fvars.length!==2)throw new KernelError('WellFounded.Nat.fix.go induction hypothesis does not bind y and decrease proof');
  const y=ihOpen.fvars[0]!;
  if(ihOpen.body.kind!=='app')throw new KernelError('WellFounded.Nat.fix.go induction hypothesis has invalid body');
  const recursiveTarget=ihOpen.body.fn;
  const expected=app(app(natRec,t),y);
  if(!exprEq(recursiveTarget,expected))throw new KernelError('WellFounded.Nat.fix.go induction hypothesis does not recurse at predecessor fuel');
}

/** Full structural certificate used by complex Nat primitive recognizers. */
export function inspectNatWellFoundedIn(tc:TypeChecker,e:Expr,measureLambda:Expr):NatWfProbe {
  const outer=inspectNatWfOuterIn(tc,e,measureLambda);
  validateNatFixGoEquation(tc.env,outer.fixGo);
  // F : (a : A) → Dom a → motive a. Extract Dom only at the full-certificate layer.
  const fTy=tc.whnf(tc.infer(outer.functional));
  if(fTy.kind!=='forall')throw new KernelError('well-founded functional is not a function of the packed argument');
  const lctx=tc.lctx.clone(),id=lctx.fresh('dom.a');lctx.addLocal(id,fTy.name,fTy.type,fTy.binderInfo);const a=fvar(id),dtc=child(tc,lctx);
  const cod=dtc.whnf(instantiate1(fTy.body,a));
  if(cod.kind!=='forall')throw new KernelError('well-founded functional does not accept an induction hypothesis');
  const domain={kind:'lam',name:fTy.name,type:fTy.type,body:abstractFVar(cod.type,id),binderInfo:'default'} as Expr;
  return {...outer,domain};
}

export function inspectNatWellFounded(env:Environment,e:Expr,measureLambda:Expr):NatWfProbe {
  return inspectNatWellFoundedIn(new TypeChecker(env),e,measureLambda);
}

/**
 * Universally test one defining equation of a certified well-founded primitive.
 * The caller supplies the pattern substitution and constructs the expected RHS from
 * the fresh induction-hypothesis variable.  Both the RHS and the equality are checked.
 */
export function probeNatWellFounded(tc0:TypeChecker,P:NatWfProbe,subst:readonly Expr[],mkRhs:(ih:Expr,tc:TypeChecker)=>Expr):void {
  const a=mkAppN(P.pack,subst),lctx=tc0.lctx.clone();
  // Typechecking `domain a` prevents malformed pack/domain combinations from entering the probe.
  const ihTy=app(P.domain,a);tc0.ensureSort(tc0.whnf(tc0.infer(ihTy)),ihTy);
  const id=lctx.fresh('ih');lctx.addLocal(id,nameFromDotted('ih'),ihTy);const ih=fvar(id),tc=child(tc0,lctx);
  const rhs=mkRhs(ih,tc);tc.check(rhs);
  const lhs=app(app(P.functional,a),ih);if(!tc.isDefEq(lhs,rhs)){const lw=exprToString(tc.whnf(lhs)).slice(0,800),rw=exprToString(tc.whnf(rhs)).slice(0,800);throw new KernelError(`well-founded primitive defining equation probe failed\nactual: ${lw}\nexpected: ${rw}`);}
}

/**
 * Certify that one branch of a well-founded functional makes exactly one recursive
 * call through its induction hypothesis to `P.pack recursiveSubst`.  The proof of
 * decrease is intentionally taken from the candidate body itself: the kernel checks
 * that proof against the IH domain, and proof irrelevance means its private/generated
 * theorem name is not part of the compatibility contract.
 */
export function probeNatWellFoundedRecursiveCall(
  tc0:TypeChecker,P:NatWfProbe,subst:readonly Expr[],recursiveSubst:readonly Expr[]
):void {
  const a=mkAppN(P.pack,subst),lctx=tc0.lctx.clone();
  const ihTy=app(P.domain,a);tc0.ensureSort(tc0.whnf(tc0.infer(ihTy)),ihTy);
  const id=lctx.fresh('ih');lctx.addLocal(id,nameFromDotted('ih'),ihTy);const ih=fvar(id),tc=child(tc0,lctx);
  const lhs=app(app(P.functional,a),ih);
  // Checking before reduction prevents an ill-typed candidate from being accepted
  // merely because reduction happens to expose an IH-shaped application.
  tc.check(lhs);
  const reduced=tc.whnf(lhs),rv=appView(reduced);
  if(rv.fn.kind!=='fvar'||rv.fn.id!==id||rv.args.length!==2)
    throw new KernelError('well-founded primitive branch is not a direct induction-hypothesis call');
  const expectedArg=mkAppN(P.pack,recursiveSubst),actualArg=rv.args[0]!,decreaseProof=rv.args[1]!;
  if(!tc.isDefEq(actualArg,expectedArg))
    throw new KernelError('well-founded primitive recurses on the wrong packed argument');
  const ihAtExpected=app(ih,expectedArg),proofFnTy=tc.whnf(tc.infer(ihAtExpected));
  if(proofFnTy.kind!=='forall')throw new KernelError('well-founded induction hypothesis has no decrease-proof argument');
  const proofTy=tc.infer(decreaseProof);
  if(!tc.isDefEq(proofTy,proofFnTy.type))throw new KernelError('well-founded primitive decrease proof has the wrong type');
  const expected=app(ihAtExpected,decreaseProof);tc.check(expected);
  if(!tc.isDefEq(reduced,expected))throw new KernelError('well-founded primitive recursive branch has an unexpected result');
}
