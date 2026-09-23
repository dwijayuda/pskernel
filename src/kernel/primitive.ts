import { DefinitionInfo, OpaqueInfo } from '../core/declaration.js';
import { ensureClosed } from '../core/checks.js';
import { Environment, KernelError } from '../core/environment.js';
import { Expr, app, appView, bvar, constant, exprEq, forallE, fvar, lam, mkAppN, sort } from '../core/expr.js';
import { levelParam, levelSucc, levelZero } from '../core/level.js';
import { LocalContext } from '../core/local-context.js';
import { Name, nameEq, nameFromDotted, nameToString } from '../core/name.js';
import { InductiveDecl, addOrdinaryInductiveInternal } from './inductive/ordinary.js';
import { N } from './names.js';
import { isPrimitiveName } from './primitive-names.js';
import { TypeChecker } from './type-checker.js';
import { checkBoolCondition } from './primitive/condition.js';
import { inspectNatWellFounded, probeNatWellFounded, probeNatWellFoundedRecursiveCall } from './primitive/wf.js';
import { checkNatFuelRec } from './primitive/fuel.js';
import { checkNatBitwise } from './primitive/bitwise.js';

const anon=nameFromDotted('_');
const one=levelSucc(levelZero);
const Nat=()=>constant(N.Nat);
const Bool=()=>constant(N.Bool);
const arrow=(a:Expr,b:Expr)=>forallE(anon,a,b);
const nat1=()=>arrow(Nat(),Nat());
const nat2=()=>arrow(Nat(),arrow(Nat(),Nat()));
const natNatBool=()=>arrow(Nat(),arrow(Nat(),Bool()));
const bool2=()=>arrow(Bool(),arrow(Bool(),Bool()));
const natBitwiseType=()=>arrow(bool2(),nat2());
const zero=()=>constant(N.NatZero);
const succ=(x:Expr)=>app(constant(N.NatSucc),x);
const tru=()=>constant(N.BoolTrue);
const fal=()=>constant(N.BoolFalse);

function safeMono(v:DefinitionInfo):boolean{return v.safety==='safe'&&v.levelParams.length===0;}
function requireDep(env:Environment,n:Name):void{if(!env.has(n))throw new KernelError(`primitive '${nameToString(n)}' dependency is missing`);}
function exactType(env:Environment,v:DefinitionInfo,t:Expr):void{if(!new TypeChecker(env).isDefEq(v.type,t))throw new KernelError(`invalid type for primitive '${nameToString(v.name)}'`);}
function local(lctx:LocalContext,label:string,type:Expr):Expr{const id=lctx.fresh(label);lctx.addLocal(id,nameFromDotted(label),type);return fvar(id);}
function eq(tc:TypeChecker,a:Expr,b:Expr,v:DefinitionInfo,what:string):void{if(!tc.isDefEq(a,b))throw new KernelError(`primitive '${nameToString(v.name)}' violates ${what}`);}
function app2(f:Expr,a:Expr,b:Expr):Expr{return app(app(f,a),b);}

/** Exact recognizer for the two inductives with kernel/runtime primitive status. */
export function addPrimitiveInductive(env:Environment,d:InductiveDecl):void{
 if(d.isUnsafe||d.levelParams.length!==0||d.numParams!==0||d.types.length!==1||d.numNested)
   throw new KernelError('invalid primitive inductive declaration shape');
 const it=d.types[0]!;
 if(!exprEq(it.type,sort(one)))throw new KernelError(`primitive inductive '${nameToString(it.name)}' must have type Sort 1`);
 if(nameEq(it.name,N.Bool)){
   if(it.ctors.length!==2||!nameEq(it.ctors[0]!.name,N.BoolFalse)||!nameEq(it.ctors[1]!.name,N.BoolTrue)||
      !exprEq(it.ctors[0]!.type,constant(N.Bool))||!exprEq(it.ctors[1]!.type,constant(N.Bool)))
     throw new KernelError('invalid form for primitive inductive Bool');
 }else if(nameEq(it.name,N.Nat)){
   const succTy=arrow(constant(N.Nat),constant(N.Nat));
   if(it.ctors.length!==2||!nameEq(it.ctors[0]!.name,N.NatZero)||!nameEq(it.ctors[1]!.name,N.NatSucc)||
      !exprEq(it.ctors[0]!.type,constant(N.Nat))||!exprEq(it.ctors[1]!.type,succTy))
     throw new KernelError('invalid form for primitive inductive Nat');
 }else throw new KernelError(`'${nameToString(it.name)}' is not a primitive inductive`);
 addOrdinaryInductiveInternal(env,d,{allowPrimitiveNames:true});
}

function validateBody(env:Environment,v:DefinitionInfo):void{
 if(!safeMono(v))throw new KernelError(`primitive '${nameToString(v.name)}' must be safe and monomorphic`);
 ensureClosed(v.type,`type of ${nameToString(v.name)}`);ensureClosed(v.value,`value of ${nameToString(v.name)}`);
 const tc=new TypeChecker(env);tc.ensureSort(tc.check(v.type),v.type);const got=tc.check(v.value);if(!tc.isDefEq(got,v.type))throw new KernelError(`primitive '${nameToString(v.name)}' value has wrong type`);
}

function checkEagerReduce(env:Environment,v:DefinitionInfo):void{
 if(v.safety!=='safe'||v.levelParams.length!==1)throw new KernelError("primitive 'eagerReduce' must be safe with exactly one universe parameter");
 const u=v.levelParams[0]!,alpha=nameFromDotted('α'),a=nameFromDotted('a');
 const expectedType=forallE(alpha,sort(levelParam(u)),forallE(a,bvar(0),bvar(1),'default'),'implicit');
 const expectedValue=lam(alpha,sort(levelParam(u)),lam(a,bvar(0),bvar(0),'default'),'implicit');
 ensureClosed(v.type,`type of ${nameToString(v.name)}`);ensureClosed(v.value,`value of ${nameToString(v.name)}`);
 const tc=new TypeChecker(env,new LocalContext(),undefined,undefined,'safe',v.levelParams);
 tc.ensureSort(tc.check(v.type),v.type);const got=tc.check(v.value);
 if(!tc.isDefEq(got,v.type)||!tc.isDefEq(v.type,expectedType)||!tc.isDefEq(v.value,expectedValue))throw new KernelError("primitive 'eagerReduce' must be the polymorphic identity");
}

/** Admit final-Lean native-reduction marker declarations without allowing an
 * arbitrary opaque declaration to acquire their name-sensitive kernel meaning. */
export function addPrimitiveOpaque(env:Environment,v:OpaqueInfo):void{
 const isNat=nameEq(v.name,N.LeanReduceNat),isBool=nameEq(v.name,N.LeanReduceBool);
 if(!isNat&&!isBool)throw new KernelError(`primitive opaque recognizer for '${nameToString(v.name)}' is not implemented; refusing declaration`);
 if(env.has(v.name))throw new KernelError(`already declared '${nameToString(v.name)}'`);
 if(v.isUnsafe||v.levelParams.length!==0)throw new KernelError(`primitive '${nameToString(v.name)}' must be safe and monomorphic`);
 const base=isNat?N.Nat:N.Bool;requireDep(env,base);
 const expectedType=arrow(constant(base),constant(base));
 ensureClosed(v.type,`type of ${nameToString(v.name)}`);ensureClosed(v.value,`opaque value of ${nameToString(v.name)}`);
 const tc=new TypeChecker(env);tc.ensureSort(tc.check(v.type),v.type);
 if(!tc.isDefEq(v.type,expectedType))throw new KernelError(`invalid type for primitive '${nameToString(v.name)}'`);
 const got=tc.check(v.value);if(!tc.isDefEq(got,v.type))throw new KernelError(`primitive '${nameToString(v.name)}' value has wrong type`);
 env.add(v);
}

function checkNatAdd(env:Environment,v:DefinitionInfo):void{requireDep(env,N.Nat);exactType(env,v,nat2());const l=new LocalContext(),x=local(l,'x',Nat()),y=local(l,'y',Nat()),tc=new TypeChecker(env,l),f=v.value;eq(tc,app2(f,x,zero()),x,v,'Nat.add x 0 = x');eq(tc,app2(f,x,succ(y)),succ(app2(f,x,y)),v,'Nat.add x (succ y) = succ (Nat.add x y)');}
function checkNatPred(env:Environment,v:DefinitionInfo):void{requireDep(env,N.Nat);exactType(env,v,nat1());const l=new LocalContext(),x=local(l,'x',Nat()),tc=new TypeChecker(env,l),f=v.value;eq(tc,app(f,zero()),zero(),v,'Nat.pred 0 = 0');eq(tc,app(f,succ(x)),x,v,'Nat.pred (succ x) = x');}
function checkNatSub(env:Environment,v:DefinitionInfo):void{requireDep(env,N.NatPred);exactType(env,v,nat2());const l=new LocalContext(),x=local(l,'x',Nat()),y=local(l,'y',Nat()),tc=new TypeChecker(env,l),f=v.value;eq(tc,app2(f,x,zero()),x,v,'Nat.sub x 0 = x');eq(tc,app2(f,x,succ(y)),app(constant(N.NatPred),app2(f,x,y)),v,'Nat.sub x (succ y) = pred (Nat.sub x y)');}
function checkNatMul(env:Environment,v:DefinitionInfo):void{requireDep(env,N.NatAdd);exactType(env,v,nat2());const l=new LocalContext(),x=local(l,'x',Nat()),y=local(l,'y',Nat()),tc=new TypeChecker(env,l),f=v.value;eq(tc,app2(f,x,zero()),zero(),v,'Nat.mul x 0 = 0');eq(tc,app2(f,x,succ(y)),app2(constant(N.NatAdd),app2(f,x,y),x),v,'Nat.mul x (succ y) = Nat.add (Nat.mul x y) x');}
function checkNatPow(env:Environment,v:DefinitionInfo):void{requireDep(env,N.NatMul);exactType(env,v,nat2());const l=new LocalContext(),x=local(l,'x',Nat()),y=local(l,'y',Nat()),tc=new TypeChecker(env,l),f=v.value,oneNat=succ(zero());eq(tc,app2(f,x,zero()),oneNat,v,'Nat.pow x 0 = 1');eq(tc,app2(f,x,succ(y)),app2(constant(N.NatMul),app2(f,x,y),x),v,'Nat.pow x (succ y) = Nat.mul (Nat.pow x y) x');}
function checkNatMod(env:Environment,v:DefinitionInfo):void{
 requireDep(env,N.NatSub);requireDep(env,N.Bool);exactType(env,v,nat2());
 const l=new LocalContext(),x=local(l,'x',Nat()),tc=new TypeChecker(env,l);
 eq(tc,app2(v.value,zero(),x),zero(),v,'Nat.mod 0 x = 0');
 checkNatFuelRec(env,v,{goName:N.NatModCoreGo,topUsesSuccInput:true,topUsesOuterIte:true,recursiveResult:x=>x,stopResult:x=>x});
}
function checkNatDiv(env:Environment,v:DefinitionInfo):void{
 requireDep(env,N.NatSub);requireDep(env,N.Bool);exactType(env,v,nat2());
 checkNatFuelRec(env,v,{goName:N.NatDivGo,topUsesSuccInput:false,topUsesOuterIte:false,recursiveResult:succ,stopResult:_=>zero()});
}
function checkNatGcd(env:Environment,v:DefinitionInfo):void{
 requireDep(env,N.NatMod);requireDep(env,N.Bool);exactType(env,v,nat2());checkBoolCondition(env);
 // Lean 4 compiles `termination_by m` to a Nat-measure well-founded fixpoint.
 const measure=lam(nameFromDotted('m'),Nat(),lam(nameFromDotted('_n'),Nat(),bvar(1)));
 const P=inspectNatWellFounded(env,v.value,measure),l=new LocalContext();
 const n=local(l,'n',Nat()),tcN=new TypeChecker(env,l);
 probeNatWellFounded(tcN,P,[zero(),n],()=>n);
 const m=local(l,'m',Nat()),tc=new TypeChecker(env,l),sm=succ(m);
 probeNatWellFoundedRecursiveCall(tc,P,[sm,n],[app2(constant(N.NatMod),n,sm),sm]);
}
function checkNatBoolCases(env:Environment,v:DefinitionInfo,b0s:Expr):void{requireDep(env,N.Nat);requireDep(env,N.Bool);exactType(env,v,natNatBool());const l=new LocalContext(),x=local(l,'x',Nat()),y=local(l,'y',Nat()),tc=new TypeChecker(env,l),f=v.value;eq(tc,app2(f,zero(),zero()),tru(),v,'zero/zero case');eq(tc,app2(f,zero(),succ(x)),b0s,v,'zero/succ case');eq(tc,app2(f,succ(x),zero()),fal(),v,'succ/zero case');eq(tc,app2(f,succ(x),succ(y)),app2(f,x,y),v,'succ/succ case');}
function checkNatShiftLeft(env:Environment,v:DefinitionInfo):void{requireDep(env,N.NatMul);exactType(env,v,nat2());const l=new LocalContext(),x=local(l,'x',Nat()),y=local(l,'y',Nat()),tc=new TypeChecker(env,l),f=v.value,two=succ(succ(zero()));eq(tc,app2(f,x,zero()),x,v,'shiftLeft x 0 = x');eq(tc,app2(f,x,succ(y)),app2(f,app2(constant(N.NatMul),two,x),y),v,'shiftLeft recursive equation');}
function checkNatShiftRight(env:Environment,v:DefinitionInfo):void{requireDep(env,N.NatDiv);exactType(env,v,nat2());const l=new LocalContext(),x=local(l,'x',Nat()),y=local(l,'y',Nat()),tc=new TypeChecker(env,l),f=v.value,two=succ(succ(zero()));eq(tc,app2(f,x,zero()),x,v,'shiftRight x 0 = x');eq(tc,app2(f,x,succ(y)),app2(constant(N.NatDiv),app2(f,x,y),two),v,'shiftRight recursive equation');}
function bitwiseOperator(v:DefinitionInfo):Expr{
 const view=appView(v.value);
 if(view.fn.kind!=='const'||!nameEq(view.fn.name,N.NatBitwise)||view.fn.levels.length!==0||view.args.length!==1)
   throw new KernelError(`primitive '${nameToString(v.name)}' must be Nat.bitwise applied to one boolean operator`);
 return view.args[0]!;
}
function checkNatLand(env:Environment,v:DefinitionInfo):void{
 requireDep(env,N.NatBitwise);exactType(env,v,nat2());const op=bitwiseOperator(v),l=new LocalContext(),x=local(l,'x',Bool()),tc=new TypeChecker(env,l);
 eq(tc,app2(op,fal(),x),fal(),v,'land operator false x = false');eq(tc,app2(op,tru(),x),x,v,'land operator true x = x');
}
function checkNatLor(env:Environment,v:DefinitionInfo):void{
 requireDep(env,N.NatBitwise);exactType(env,v,nat2());const op=bitwiseOperator(v),l=new LocalContext(),x=local(l,'x',Bool()),tc=new TypeChecker(env,l);
 eq(tc,app2(op,fal(),x),x,v,'lor operator false x = x');eq(tc,app2(op,tru(),x),tru(),v,'lor operator true x = true');
}
function checkNatXor(env:Environment,v:DefinitionInfo):void{
 requireDep(env,N.NatBitwise);exactType(env,v,nat2());const op=bitwiseOperator(v),tc=new TypeChecker(env);
 eq(tc,app2(op,fal(),fal()),fal(),v,'xor false false = false');eq(tc,app2(op,tru(),fal()),tru(),v,'xor true false = true');
 eq(tc,app2(op,fal(),tru()),tru(),v,'xor false true = true');eq(tc,app2(op,tru(),tru()),fal(),v,'xor true true = false');
}
function checkCharOfNat(env:Environment,v:DefinitionInfo):void{
 requireDep(env,N.Nat);requireDep(env,N.Char);exactType(env,v,arrow(Nat(),constant(N.Char)));
 const tc=new TypeChecker(env);tc.ensureSort(tc.check(constant(N.Char)),constant(N.Char));
}
function checkStringOfList(env:Environment,v:DefinitionInfo):void{
 requireDep(env,N.List);requireDep(env,N.ListNil);requireDep(env,N.ListCons);requireDep(env,N.Char);requireDep(env,N.String);
 const tc=new TypeChecker(env),u0=levelZero,chars=app(constant(N.List,[u0]),constant(N.Char));
 tc.ensureSort(tc.check(chars),chars);tc.ensureSort(tc.check(constant(N.Char)),constant(N.Char));
 const nilTy=app(constant(N.List,[u0]),constant(N.Char));
 const consTy=arrow(constant(N.Char),arrow(chars,chars));
 const nilGot=tc.check(mkAppN(constant(N.ListNil,[u0]),[constant(N.Char)]));
 const consGot=tc.check(mkAppN(constant(N.ListCons,[u0]),[constant(N.Char)]));
 if(!tc.isDefEq(nilGot,nilTy)||!tc.isDefEq(consGot,consTy))throw new KernelError(`primitive '${nameToString(v.name)}' List Char prerequisites have unexpected types`);
 exactType(env,v,arrow(chars,constant(N.String)));
}

/**
 * Recognize and admit a primitive definition. Unsupported primitive recognizers fail closed.
 * This function deliberately validates the body *before* inserting the primitive name, so native
 * reduction keyed by that name cannot make a malicious body pass its own equations.
 */
export function addPrimitiveDefinition(env:Environment,v:DefinitionInfo):void{
 if(!isPrimitiveName(v.name))throw new KernelError(`'${nameToString(v.name)}' is not a reserved primitive`);
 if(env.has(v.name))throw new KernelError(`already declared '${nameToString(v.name)}'`);
 if(nameEq(v.name,N.EagerReduce)){checkEagerReduce(env,v);env.add(v);return;}
 validateBody(env,v);
 if(nameEq(v.name,N.NatAdd))checkNatAdd(env,v);
 else if(nameEq(v.name,N.NatPred))checkNatPred(env,v);
 else if(nameEq(v.name,N.NatSub))checkNatSub(env,v);
 else if(nameEq(v.name,N.NatMul))checkNatMul(env,v);
 else if(nameEq(v.name,N.NatPow))checkNatPow(env,v);
 else if(nameEq(v.name,N.NatMod))checkNatMod(env,v);
 else if(nameEq(v.name,N.NatDiv))checkNatDiv(env,v);
 else if(nameEq(v.name,N.NatGcd))checkNatGcd(env,v);
 else if(nameEq(v.name,N.NatBitwise))checkNatBitwise(env,v);
 else if(nameEq(v.name,N.NatBeq))checkNatBoolCases(env,v,fal());
 else if(nameEq(v.name,N.NatBle))checkNatBoolCases(env,v,tru());
 else if(nameEq(v.name,N.NatLand))checkNatLand(env,v);
 else if(nameEq(v.name,N.NatLor))checkNatLor(env,v);
 else if(nameEq(v.name,N.NatXor))checkNatXor(env,v);
 else if(nameEq(v.name,N.NatShiftLeft))checkNatShiftLeft(env,v);
 else if(nameEq(v.name,N.NatShiftRight))checkNatShiftRight(env,v);
 else if(nameEq(v.name,N.CharOfNat))checkCharOfNat(env,v);
 else if(nameEq(v.name,N.StringOfList))checkStringOfList(env,v);
 else throw new KernelError(`primitive recognizer for '${nameToString(v.name)}' is not implemented; refusing declaration`);
 env.add(v);
}

/** Helper used by tests/bootstrap to build the canonical recursive Nat.add body from Nat.rec. */
export function canonicalNatAddValue():Expr{
 const motive=lam(anon,Nat(),Nat());
 const step=lam(nameFromDotted('n'),Nat(),lam(nameFromDotted('ih'),Nat(),succ(bvar(0))));
 // fun x y => Nat.rec.{1} (fun _ => Nat) x (fun _ ih => succ ih) y
 const rec=constant(nameFromDotted('Nat.rec'),[one]);
 return lam(nameFromDotted('x'),Nat(),lam(nameFromDotted('y'),Nat(),mkAppN(rec,[motive,bvar(1),step,bvar(0)])));
}
