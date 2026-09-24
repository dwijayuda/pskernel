import { Environment, KernelError } from '../core/environment.js';
import { Expr, app, bvar, constant, exprLeanEq, forallE, mkAppN, sort } from '../core/expr.js';
import { levelParam, levelZero } from '../core/level.js';
import { nameFromDotted } from '../core/name.js';
import { N } from './names.js';

const anon=nameFromDotted('_'), uN=nameFromDotted('u'),vN=nameFromDotted('v');
const arrow=(a:Expr,b:Expr)=>forallE(anon,a,b);
function expectedEqType(param:import('../core/name.js').Name):Expr{
 const u=levelParam(param);return forallE(nameFromDotted('α'),sort(u),arrow(bvar(0),arrow(bvar(1),sort(levelZero))),'implicit');
}
function expectedReflType(param:import('../core/name.js').Name):Expr{
 const u=levelParam(param);const Eq=constant(N.Eq,[u]);return forallE(nameFromDotted('α'),sort(u),forallE(nameFromDotted('a'),bvar(0),mkAppN(Eq,[bvar(1),bvar(0),bvar(0)])),'implicit');
}
export function checkEqShape(env:Environment):void{
 const eq=env.find(N.Eq);if(!eq||eq.kind!=='inductive'||eq.levelParams.length!==1||eq.ctors.length!==1)throw new KernelError('failed to initialize Quot: unexpected Eq declaration');
 const eqParam=eq.levelParams[0]!;
 if(!exprLeanEq(eq.type,expectedEqType(eqParam)))throw new KernelError('failed to initialize Quot: Eq has unexpected type');
 const r=env.find(eq.ctors[0]!);if(!r||r.kind!=='constructor'||r.levelParams.length!==1||!exprLeanEq(r.type,expectedReflType(r.levelParams[0]!)))throw new KernelError('failed to initialize Quot: Eq.refl has unexpected type');
}
export function addQuot(env:Environment):void{
 if(env.quotInitialized)return;checkEqShape(env);for(const n of [N.Quot,N.QuotMk,N.QuotLift,N.QuotInd])if(env.has(n))throw new KernelError('failed to initialize Quot: name already declared');
 const u=levelParam(uN),v=levelParam(vN);
 // Types below use de Bruijn indices exactly as Lean constants; admission is guarded by exact Eq validation.
 // Quot.{u} {α : Sort u} (r : α → α → Prop) : Sort u
 const quotType=forallE(nameFromDotted('α'),sort(u),forallE(nameFromDotted('r'),arrow(bvar(0),arrow(bvar(1),sort(levelZero))),sort(u)),'implicit');
 env.add({kind:'quot',quotKind:'type',name:N.Quot,levelParams:[uN],type:quotType});
 // Building remaining types directly with bvars is compact and keeps the trusted definition explicit.
 const alpha=bvar(2), r=bvar(1), a=bvar(0); const quot=mkAppN(constant(N.Quot,[u]),[alpha,r]);
 const mkType=forallE(nameFromDotted('α'),sort(u),forallE(nameFromDotted('r'),arrow(bvar(0),arrow(bvar(1),sort(levelZero))),forallE(nameFromDotted('a'),bvar(1),mkAppN(constant(N.Quot,[u]),[bvar(2),bvar(1)]))),'implicit');
 env.add({kind:'quot',quotKind:'ctor',name:N.QuotMk,levelParams:[uN],type:mkType});
 // Quot.lift / Quot.ind use the exact Lean 4.34 de Bruijn layouts.
 // Do not use `arrow` for open codomains here: introducing a Pi shifts outer bvars.
 const liftFType=forallE(anon,bvar(2),bvar(1));
 const liftRespects=forallE(nameFromDotted('a'),bvar(3),
   forallE(nameFromDotted('b'),bvar(4),
     forallE(anon,mkAppN(bvar(4),[bvar(1),bvar(0)]),
       mkAppN(constant(N.Eq,[v]),[bvar(4),app(bvar(3),bvar(2)),app(bvar(3),bvar(1))]))));
 const liftAfterF=forallE(anon,liftRespects,
   forallE(anon,mkAppN(constant(N.Quot,[u]),[bvar(4),bvar(3)]),bvar(3)));
 const liftType:Expr=forallE(nameFromDotted('α'),sort(u),
   forallE(nameFromDotted('r'),arrow(bvar(0),arrow(bvar(1),sort(levelZero))),
     forallE(nameFromDotted('β'),sort(v),
       forallE(nameFromDotted('f'),liftFType,liftAfterF),
       'implicit'),
     'implicit'),
   'implicit');
 env.add({kind:'quot',quotKind:'lift',name:N.QuotLift,levelParams:[uN,vN],type:liftType});

 const indMotive=forallE(anon,mkAppN(constant(N.Quot,[u]),[bvar(1),bvar(0)]),sort(levelZero));
 const indMinor=forallE(nameFromDotted('a'),bvar(2),
   app(bvar(1),mkAppN(constant(N.QuotMk,[u]),[bvar(3),bvar(2),bvar(0)])));
 const indAfterMotive=forallE(nameFromDotted('mk'),indMinor,
   forallE(nameFromDotted('q'),mkAppN(constant(N.Quot,[u]),[bvar(3),bvar(2)]),app(bvar(2),bvar(0))));
 const indType:Expr=forallE(nameFromDotted('α'),sort(u),
   forallE(nameFromDotted('r'),arrow(bvar(0),arrow(bvar(1),sort(levelZero))),
     forallE(nameFromDotted('β'),indMotive,indAfterMotive,'implicit'),
     'implicit'),
   'implicit');
 env.add({kind:'quot',quotKind:'ind',name:N.QuotInd,levelParams:[uN],type:indType});env.quotInitialized=true;
 void alpha;void r;void a;void quot;
}
