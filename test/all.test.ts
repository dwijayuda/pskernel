import { Environment } from '../src/core/environment.js';
import { app, bvar, constant, exprEq, exprKernelMetadataEq, exprKey, forallE, fvar, hasMVar, lam, mkAppN, natLit, sort, strLit } from '../src/core/expr.js';
import { levelEquivalent, levelMVar, levelParam, levelSucc, levelZero, mkIMax, mkMax } from '../src/core/level.js';
import { nameFromDotted, nameToString } from '../src/core/name.js';
import { LocalContext } from '../src/core/local-context.js';
import { instantiate, lift } from '../src/core/instantiate.js';
import { Kernel } from '../src/kernel/kernel.js';
import { N } from '../src/kernel/names.js';
import { TypeChecker } from '../src/kernel/type-checker.js';
import { KernelState } from '../src/kernel/state.js';
import { addOrdinaryInductive } from '../src/kernel/inductive/ordinary.js';
import { addQuot } from '../src/kernel/quotient.js';
import { addInductive } from '../src/kernel/inductive/nested.js';

let pass=0,fail=0;
function test(name:string,f:()=>void){try{f();console.log(`ok ${++pass} - ${name}`);}catch(e){fail++;console.error(`not ok - ${name}`);console.error(e);}}
function assert(x:unknown,msg='assertion failed'):asserts x{if(!x)throw new Error(msg);}
function eqExpr(a:ReturnType<typeof sort>|any,b:any,msg='expressions differ'){assert(exprEq(a,b),msg);}
function throws(f:()=>void){let yes=false;try{f();}catch{yes=true;}assert(yes,'expected exception');}

function baseEnv():Environment{
 const e=new Environment();const one=levelSucc(levelZero);
 e.add({kind:'inductive',name:N.Nat,levelParams:[],type:sort(one),numParams:0,numIndices:0,all:[N.Nat],ctors:[N.NatZero,N.NatSucc],numNested:0,isRec:true,isReflexive:false});
 e.add({kind:'constructor',name:N.NatZero,levelParams:[],type:constant(N.Nat),induct:N.Nat,cidx:0,numParams:0,numFields:0});
 e.add({kind:'constructor',name:N.NatSucc,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat)),induct:N.Nat,cidx:1,numParams:0,numFields:1});
 e.add({kind:'inductive',name:N.Bool,levelParams:[],type:sort(one),numParams:0,numIndices:0,all:[N.Bool],ctors:[N.BoolFalse,N.BoolTrue],numNested:0,isRec:false,isReflexive:false});
 e.add({kind:'constructor',name:N.BoolFalse,levelParams:[],type:constant(N.Bool),induct:N.Bool,cidx:0,numParams:0,numFields:0});
 e.add({kind:'constructor',name:N.BoolTrue,levelParams:[],type:constant(N.Bool),induct:N.Bool,cidx:1,numParams:0,numFields:0});
 e.add({kind:'axiom',name:N.String,levelParams:[],type:sort(one)});
 for(const [n,t] of [[N.NatAdd,forallE(nameFromDotted('a'),constant(N.Nat),forallE(nameFromDotted('b'),constant(N.Nat),constant(N.Nat)))],[N.NatMul,forallE(nameFromDotted('a'),constant(N.Nat),forallE(nameFromDotted('b'),constant(N.Nat),constant(N.Nat)))],[N.NatPow,forallE(nameFromDotted('a'),constant(N.Nat),forallE(nameFromDotted('b'),constant(N.Nat),constant(N.Nat)))] ] as const)e.add({kind:'axiom',name:n,levelParams:[],type:t});
 return e;
}

test('Name numeric and string components remain distinct',()=>{const a={kind:'str',prefix:nameFromDotted('X'),value:'1'} as const,b={kind:'num',prefix:nameFromDotted('X'),value:1n} as const;assert(JSON.stringify(a,(_k,v)=>typeof v==='bigint'?v.toString():v)!==JSON.stringify(b,(_k,v)=>typeof v==='bigint'?v.toString():v));});
test('Lean private names preserve numeric private-index components',()=>{assert(!exprEq(constant(N.NatBitwiseUnaryProof1),constant(nameFromDotted('_private.Init.Data.Nat.Bitwise.Basic.0.Nat.bitwise._unary._proof_1'))));});
test('LocalContext freshness never collides with reconstructed local IDs',()=>{const l=new LocalContext();l.addLocal('a@1',nameFromDotted('a'),sort(levelZero));assert(l.fresh('a')==='a@0');assert(l.fresh('a')==='a@2');});
test('deep structural traversals avoid the JavaScript call stack',()=>{
 let e:any=bvar(0);
 for(let i=0;i<6000;i++)e=lam(nameFromDotted('x'),constant(N.Nat),e);
 assert(!hasMVar(e));
 const lifted=lift(e,1,0);
 const inst=instantiate(lifted,[natLit(0)]);
 assert(lifted.kind==='lam'&&inst.kind==='lam');
});
test('universe max commutative semantically',()=>{const u=levelParam(nameFromDotted('u')),v=levelParam(nameFromDotted('v'));assert(levelEquivalent(mkMax(u,v),mkMax(v,u)));});
test('imax u 0 = 0',()=>{const u=levelParam(nameFromDotted('u'));assert(levelEquivalent(mkIMax(u,levelZero),levelZero));});
test('imax u (v+1) = max u (v+1)',()=>{const u=levelParam(nameFromDotted('u')),v=levelSucc(levelParam(nameFromDotted('v')));assert(levelEquivalent(mkIMax(u,v),mkMax(u,v)));});
test('infer identity lambda',()=>{const tc=new TypeChecker(baseEnv());const id=lam(nameFromDotted('x'),constant(N.Nat),bvar(0));const ty=tc.check(id);eqExpr(ty,forallE(nameFromDotted('x'),constant(N.Nat),constant(N.Nat)));});
test('beta reduction',()=>{const tc=new TypeChecker(baseEnv());const id=lam(nameFromDotted('x'),constant(N.Nat),bvar(0));eqExpr(tc.whnf(app(id,natLit(3))),natLit(3));});
test('defeq success cache remains pair-local and never gains transitive closure',()=>{
 const st=new KernelState(),a=constant(nameFromDotted('Cache.a')),b=constant(nameFromDotted('Cache.b')),c=constant(nameFromDotted('Cache.c'));
 st.success.add(st.pair(a,b));st.success.add(st.pair(b,c));
 assert(!st.success.has(st.pair(a,c)),'Lean 4.34 defeq cache must not transitively close successful algorithmic comparisons');
});

test('proof irrelevance compares arbitrary proofs of the same proposition',()=>{
 const env=baseEnv(),P=nameFromDotted('ProofIrrel.P');env.add({kind:'axiom',name:P,levelParams:[],type:sort(levelZero)});
 const lctx=new LocalContext();lctx.addLocal('p@0',nameFromDotted('p'),constant(P));lctx.addLocal('q@0',nameFromDotted('q'),constant(P));
 const tc=new TypeChecker(env,lctx);assert(tc.isDefEq(fvar('p@0'),fvar('q@0')));
});
test('Nat.add reduction uses exact bigint',()=>{const tc=new TypeChecker(baseEnv());const e=app(app(constant(N.NatAdd),natLit(9007199254740993n)),natLit(7));eqExpr(tc.whnf(e),natLit(9007199254741000n));});
test('Nat literal and count limits follow explicit Lean kernel limits',()=>{
 const env=baseEnv(),limits={maxRecDepth:4096,maxNatBytes:2n},tc=new TypeChecker(env,undefined,undefined,limits);
 tc.check(natLit(65535));throws(()=>tc.check(natLit(65536)));
 const normal=new TypeChecker(env);throws(()=>normal.whnf(app(app(constant(N.NatPow),natLit(2)),natLit(0x1_0000_0000n))));
 throws(()=>normal.whnf(app(app(constant(N.NatShiftLeft),natLit(1)),natLit(0x1_0000_0000n))));
});
test('Nat.pow reduction',()=>{const tc=new TypeChecker(baseEnv());eqExpr(tc.whnf(app(app(constant(N.NatPow),natLit(2)),natLit(20))),natLit(1048576));});
test('kernel recursion budget fails deterministically and succeeds when raised',()=>{
 const env=baseEnv();let deep:any=constant(N.NatZero);for(let i=0;i<20;i++)deep=app(constant(N.NatSucc),deep);
 const low=new TypeChecker(env,undefined,undefined,{maxRecDepth:8,maxNatBytes:134217728n});let message='';try{low.check(deep);}catch(e){message=e instanceof Error?e.message:String(e);}
 assert(message.includes('deep recursion'),'low maxRecDepth must fail with deterministic kernel recursion error');
 const high=new TypeChecker(env,undefined,undefined,{maxRecDepth:64,maxNatBytes:134217728n});eqExpr(high.check(deep),constant(N.Nat));
});
test('Lean 4.34 profile removes deprecated in-kernel native-reduction declarations',()=>{
 const env=baseEnv();
 for(const n of ['Lean.reduceNat','Lean.reduceBool','Lean.ofReduceNat','Lean.ofReduceBool','Lean.trustCompiler'])
   assert(!env.has(nameFromDotted(n)),`${n} must not be part of the final Lean 4.34 profile`);
});
test('historical Lean.reduceNat name is not a kernel reduction opcode',()=>{
 const env=baseEnv(),reduceNat=nameFromDotted('Lean.reduceNat'),v=nameFromDotted('NativeCompat.userValue');
 env.add({kind:'axiom',name:reduceNat,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))});
 env.add({kind:'definition',name:v,levelParams:[],type:constant(N.Nat),value:natLit(7),hints:{kind:'regular',height:1n},safety:'safe'});
 const e=app(constant(reduceNat),constant(v)),w=new TypeChecker(env).whnf(e);
 eqExpr(w,e);
});
test('defeq treats historical native-reduction names as ordinary opaque applications',()=>{
 const env=baseEnv(),reduceBool=nameFromDotted('Lean.reduceBool'),v=nameFromDotted('NativeCompat.boolValue');
 env.add({kind:'axiom',name:reduceBool,levelParams:[],type:forallE(nameFromDotted('b'),constant(N.Bool),constant(N.Bool))});
 env.add({kind:'definition',name:v,levelParams:[],type:constant(N.Bool),value:constant(N.BoolTrue),hints:{kind:'regular',height:1n},safety:'safe'});
 const tc=new TypeChecker(env),e=app(constant(reduceBool),constant(v));
 assert(!tc.isDefEq(e,constant(N.BoolFalse)),'historical native-reduction application must remain opaque');
});
test('application checker rejects wrong argument',()=>{const tc=new TypeChecker(baseEnv());const id=lam(nameFromDotted('x'),constant(N.Nat),bvar(0));throws(()=>tc.check(app(id,constant(N.BoolTrue))));});
test('eagerReduce enables Lean 4.34 eager defeq for application arguments with syntactic fvars',()=>{
 const env=baseEnv(),one=levelSucc(levelZero),F=nameFromDotted('Eager.F');
 env.add({kind:'axiom',name:F,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),sort(one))});
 env.add({kind:'axiom',name:N.EagerReduce,levelParams:[],type:forallE(nameFromDotted('A'),sort(one),forallE(nameFromDotted('a'),bvar(0),bvar(1)))});
 const lctx=new LocalContext(),gid=lctx.fresh('ghost');lctx.addLocal(gid,nameFromDotted('ghost'),constant(N.Nat));
 const ignored={kind:'let',name:nameFromDotted('_g'),type:constant(N.Nat),value:fvar(gid),body:natLit(1)} as const;
 const red=app(app(constant(N.NatAdd),ignored),natLit(1)),p1=app(constant(F),red),p2=app(constant(F),natLit(2));
 const pid=lctx.fresh('p');lctx.addLocal(pid,nameFromDotted('p'),p1);const tc=new TypeChecker(env,lctx);
 const consume=lam(nameFromDotted('q'),p2,natLit(0));
 throws(()=>tc.check(app(consume,fvar(pid))));
 const wrapped=mkAppN(constant(N.EagerReduce),[p1,fvar(pid)]);eqExpr(tc.check(app(consume,wrapped)),constant(N.Nat));
});
test('definition admission and delta reduction',()=>{const env=baseEnv(),k=new Kernel(env),nm=nameFromDotted('idNat');const ty=forallE(nameFromDotted('x'),constant(N.Nat),constant(N.Nat)),val=lam(nameFromDotted('x'),constant(N.Nat),bvar(0));k.addDefinition({kind:'definition',name:nm,levelParams:[],type:ty,value:val,hints:{kind:'regular',height:1n},safety:'safe'});const tc=new TypeChecker(env);eqExpr(tc.whnf(app(constant(nm),natLit(9))),natLit(9));});
test('theorem declarations do not delta unfold in Lean 4.34',()=>{
 const env=baseEnv(),k=new Kernel(env),P=nameFromDotted('P'),pr=nameFromDotted('p'),th=nameFromDotted('theoremOpaque');
 k.addAxiom({kind:'axiom',name:P,levelParams:[],type:sort(levelZero)});k.addAxiom({kind:'axiom',name:pr,levelParams:[],type:constant(P)});
 k.addTheorem({kind:'theorem',name:th,levelParams:[],type:constant(P),value:constant(pr)});
 const tc=new TypeChecker(env);assert(tc.unfold(constant(th))===null,'theorem proof must not participate in delta reduction');
});
test('opaque declarations do not delta unfold',()=>{const env=baseEnv(),k=new Kernel(env),nm=nameFromDotted('opaqueNat');k.addOpaque({kind:'opaque',name:nm,levelParams:[],type:constant(N.Nat),value:natLit(4)});const tc=new TypeChecker(env);eqExpr(tc.whnf(constant(nm)),constant(nm));});
test('loose bvars rejected',()=>{const tc=new TypeChecker(baseEnv());throws(()=>tc.check(bvar(0)));});


test('Prop inductive only large-eliminates when non-Prop constructor fields occur as direct result arguments',()=>{
 const env=baseEnv(),A=nameFromDotted('Elim.A'),F=nameFromDotted('Elim.f'),P=nameFromDotted('Elim.P'),Mk=nameFromDotted('Elim.P.mk');
 env.add({kind:'axiom',name:A,levelParams:[],type:sort(levelSucc(levelZero))});
 env.add({kind:'axiom',name:F,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(A))});
 const pTy=forallE(nameFromDotted('i'),constant(A),sort(levelZero));
 const ctorTy=forallE(nameFromDotted('n'),constant(N.Nat),app(constant(P),app(constant(F),bvar(0))));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:P,type:pTy,ctors:[{name:Mk,type:ctorTy}]}]});
 const rec=env.get(nameFromDotted('Elim.P.rec'));assert(rec.kind==='recursor');assert(rec.levelParams.length===0,'non-Prop field hidden under an index expression must not enable large elimination');
});

test('ordinary recursive inductive synthesizes constructors and recursor',()=>{
 const env=baseEnv(),I=nameFromDotted('MyNat'),z=nameFromDotted('MyNat.zero'),s=nameFromDotted('MyNat.succ');
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:z,type:constant(I)},{name:s,type:forallE(nameFromDotted('n'),constant(I),constant(I))}]}]});
 const ii=env.get(I);assert(ii.kind==='inductive'&&ii.isRec);const ri=env.get(nameFromDotted('MyNat.rec'));assert(ri.kind==='recursor'&&ri.rules.length===2);
 const tc=new TypeChecker(env);tc.check(ri.type);
});
test('ordinary inductive rejects negative recursive occurrence',()=>{
 const env=baseEnv(),I=nameFromDotted('Bad'),c=nameFromDotted('Bad.mk');
 const neg=forallE(nameFromDotted('f'),forallE(nameFromDotted('x'),constant(I),constant(N.Nat)),constant(I));
 throws(()=>addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:c,type:neg}]}]}));
 assert(!env.has(I),'transaction must roll back failed inductive');
});


test('unsafe inductive uses unsafe checking mode while safe inductive rejects unsafe dependencies',()=>{
 const env=baseEnv(),U=nameFromDotted('UnsafePayload');env.add({kind:'axiom',name:U,levelParams:[],type:sort(levelSucc(levelZero)),isUnsafe:true});
 const S=nameFromDotted('SafeUsesUnsafe'),Smk=nameFromDotted('SafeUsesUnsafe.mk'),fieldTy=forallE(nameFromDotted('x'),constant(U),constant(S));
 throws(()=>addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:S,type:sort(levelSucc(levelZero)),ctors:[{name:Smk,type:fieldTy}]}]}));assert(!env.has(S));
 const I=nameFromDotted('UnsafeUsesUnsafe'),Imk=nameFromDotted('UnsafeUsesUnsafe.mk');
 addOrdinaryInductive(env,{levelParams:[],numParams:0,isUnsafe:true,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:Imk,type:forallE(nameFromDotted('x'),constant(U),constant(I))}]}]});
 const ii=env.get(I),ci=env.get(Imk),ri=env.get(nameFromDotted('UnsafeUsesUnsafe.rec'));assert(ii.kind==='inductive'&&ii.isUnsafe===true);assert(ci.kind==='constructor'&&ci.isUnsafe===true);assert(ri.kind==='recursor'&&ri.isUnsafe===true);
 const recConst=constant(nameFromDotted('UnsafeUsesUnsafe.rec'),ri.levelParams.map(()=>levelZero));
 throws(()=>new TypeChecker(env).check(recConst));
 new TypeChecker(env,undefined,undefined,undefined,'unsafe').check(recConst);
});

test('unsafe inductive skips positivity exactly at the unsafe boundary',()=>{
 const env=baseEnv(),I=nameFromDotted('UnsafeNegative'),mk=nameFromDotted('UnsafeNegative.mk'),T=sort(levelSucc(levelZero));
 const negative=forallE(nameFromDotted('f'),forallE(nameFromDotted('x'),constant(I),constant(N.Nat)),constant(I));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,isUnsafe:true,types:[{name:I,type:T,ctors:[{name:mk,type:negative}]}]});
 const ii=env.get(I),ri=env.get(nameFromDotted('UnsafeNegative.rec'));assert(ii.kind==='inductive'&&ii.isUnsafe===true);assert(ri.kind==='recursor'&&ri.isUnsafe===true);
});


test('parameterized recursive inductive List-like declaration',()=>{
 const env=baseEnv(),I=nameFromDotted('PList'),nil=nameFromDotted('PList.nil'),cons=nameFromDotted('PList.cons'),uN=nameFromDotted('u'),u=levelParam(uN),TU=sort(levelSucc(u));
 const list=(x:any)=>app(constant(I,[u]),x);
 const ty=forallE(nameFromDotted('α'),TU,TU,'implicit');
 const nilTy=forallE(nameFromDotted('α'),TU,list(bvar(0)),'implicit');
 const consTy=forallE(nameFromDotted('α'),TU,forallE(nameFromDotted('head'),bvar(0),forallE(nameFromDotted('tail'),list(bvar(1)),list(bvar(2)))),'implicit');
 addOrdinaryInductive(env,{levelParams:[uN],numParams:1,types:[{name:I,type:ty,ctors:[{name:nil,type:nilTy},{name:cons,type:consTy}]}]});
 const ii=env.get(I);assert(ii.kind==='inductive'&&ii.numParams===1&&ii.isRec);const ri=env.get(nameFromDotted('PList.rec'));assert(ri.kind==='recursor'&&ri.numParams===1&&ri.rules.length===2);
});
test('mutual recursive inductives synthesize paired motives',()=>{
 const env=baseEnv(),E=nameFromDotted('EvenT'),O=nameFromDotted('OddT'),ez=nameFromDotted('EvenT.zero'),es=nameFromDotted('EvenT.succ'),os=nameFromDotted('OddT.succ'),T=sort(levelSucc(levelZero));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[
  {name:E,type:T,ctors:[{name:ez,type:constant(E)},{name:es,type:forallE(nameFromDotted('o'),constant(O),constant(E))}]},
  {name:O,type:T,ctors:[{name:os,type:forallE(nameFromDotted('e'),constant(E),constant(O))}]}
 ]});
 const er=env.get(nameFromDotted('EvenT.rec')),or=env.get(nameFromDotted('OddT.rec'));assert(er.kind==='recursor'&&or.kind==='recursor');assert(er.numMotives===2&&or.numMotives===2&&er.numMinors===3);
});
test('indexed inductive records and recursor preserve index count',()=>{
 const env=baseEnv(),I=nameFromDotted('Tag'),mk=nameFromDotted('Tag.mk'),T=sort(levelSucc(levelZero));
 const ty=forallE(nameFromDotted('n'),constant(N.Nat),T);
 const ctor=forallE(nameFromDotted('n'),constant(N.Nat),app(constant(I),bvar(0)));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:ty,ctors:[{name:mk,type:ctor}]}]});
 const ii=env.get(I),ri=env.get(nameFromDotted('Tag.rec'));assert(ii.kind==='inductive'&&ii.numIndices===1);assert(ri.kind==='recursor'&&ri.numIndices===1);
});

test('imax-normalized Prop inductive keeps Prop-only elimination',()=>{
 const env=baseEnv(),I=nameFromDotted('ImaxPropData'),Mk=nameFromDotted('ImaxPropData.mk');
 const propViaImax=sort(mkIMax(levelSucc(levelZero),levelZero));
 const ctor=forallE(nameFromDotted('b'),constant(N.Bool),constant(I));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:propViaImax,ctors:[{name:Mk,type:ctor}]}]});
 const ri=env.get(nameFromDotted('ImaxPropData.rec'));assert(ri.kind==='recursor'&&ri.levelParams.length===0,'imax-normalized Prop must not gain large elimination');
});

test('Prop inductive cannot large-eliminate when data field occurs only inside an index expression',()=>{
 const env=baseEnv(),I=nameFromDotted('NestedIndexProp'),mk=nameFromDotted('NestedIndexProp.mk');
 const ty=forallE(nameFromDotted('n'),constant(N.Nat),sort(levelZero));
 const ctor=forallE(nameFromDotted('n'),constant(N.Nat),app(constant(I),app(constant(N.NatSucc),bvar(0))));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:ty,ctors:[{name:mk,type:ctor}]}]});
 const ri=env.get(nameFromDotted('NestedIndexProp.rec'));assert(ri.kind==='recursor'&&ri.levelParams.length===0,'Lean 4.34 restricts this recursor to Prop elimination');
});





test('projection checking validates the projected structure expression',()=>{
 const env=baseEnv(),FalseN=N.False,TrueN=nameFromDotted('True'),TrueIntro=nameFromDotted('True.intro'),Wrapper=nameFromDotted('Arena.Wrapper'),Mk=nameFromDotted('Arena.Wrapper.mk');
 env.add({kind:'axiom',name:FalseN,levelParams:[],type:sort(levelZero)});
 env.add({kind:'axiom',name:TrueN,levelParams:[],type:sort(levelZero)});
 env.add({kind:'axiom',name:TrueIntro,levelParams:[],type:constant(TrueN)});
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:Wrapper,type:sort(levelZero),ctors:[{name:Mk,type:forallE(nameFromDotted('p'),constant(FalseN),constant(Wrapper))}]}]});
 const badStruct=app(constant(Mk),constant(TrueIntro));
 const badProj={kind:'proj',typeName:Wrapper,index:0,expr:badStruct} as const;
 throws(()=>new TypeChecker(env).check(badProj));
});
test('projection typing forbids extracting data from a proof',()=>{
 const env=baseEnv(),I=nameFromDotted('ProofBox'),mk=nameFromDotted('ProofBox.mk'),p=nameFromDotted('proofBox');
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelZero),ctors:[{name:mk,type:forallE(nameFromDotted('n'),constant(N.Nat),constant(I))}]}]});
 env.add({kind:'axiom',name:p,levelParams:[],type:constant(I)});
 const tc=new TypeChecker(env);throws(()=>tc.check({kind:'proj',typeName:I,index:0,expr:constant(p)}));
});

test('projection indices reject negative, fractional, and uint32-overflow values',()=>{
 const env=baseEnv(),I=nameFromDotted('ProjIndexPair'),mk=nameFromDotted('ProjIndexPair.mk'),p=nameFromDotted('projIndexPairValue');
 const ctorTy=forallE(nameFromDotted('fst'),constant(N.Nat),forallE(nameFromDotted('snd'),constant(N.Nat),constant(I)));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:mk,type:ctorTy}]}]});
 env.add({kind:'axiom',name:p,levelParams:[],type:constant(I)});
 const tc=new TypeChecker(env);eqExpr(tc.check({kind:'proj',typeName:I,index:0,expr:constant(p)}),constant(N.Nat));
 for(const index of [-1,0.5,0x1_0000_0000])throws(()=>tc.check({kind:'proj',typeName:I,index,expr:constant(p)}));
});

test('projection reduction never crosses an unrelated structure name',()=>{
 const env=baseEnv(),A=nameFromDotted('ProjStructA'),AMk=nameFromDotted('ProjStructA.mk'),B=nameFromDotted('ProjStructB'),BMk=nameFromDotted('ProjStructB.mk');
 const T=sort(levelSucc(levelZero)),ctor=(mk:any,I:any)=>({name:mk,type:forallE(nameFromDotted('n'),constant(N.Nat),constant(I))});
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:A,type:T,ctors:[ctor(AMk,A)]}]});
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:B,type:T,ctors:[ctor(BMk,B)]}]});
 const bv=app(constant(BMk),natLit(7)),right={kind:'proj',typeName:B,index:0,expr:bv} as const,wrong={kind:'proj',typeName:A,index:0,expr:bv} as const;
 const tc=new TypeChecker(env);eqExpr(tc.whnf(right),natLit(7));
 const stuck=tc.whnf(wrong);assert(stuck.kind==='proj'&&nameToString(stuck.typeName)==='ProjStructA','wrong-structure projection must remain stuck');
 throws(()=>tc.check(wrong));
});

test('projection-headed application reduces through a functional structure field',()=>{
 const env=baseEnv(),I=nameFromDotted('FnBox'),mk=nameFromDotted('FnBox.mk'),box=nameFromDotted('fnBoxValue'),fnTy=forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat));
 const ctorTy=forallE(nameFromDotted('fn'),fnTy,constant(I));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:mk,type:ctorTy}]}]});
 const k=new Kernel(env);k.addDefinition({kind:'definition',name:box,levelParams:[],type:constant(I),value:app(constant(mk),lam(nameFromDotted('x'),constant(N.Nat),bvar(0))),hints:{kind:'regular',height:1n},safety:'safe'});
 const projected={kind:'proj',typeName:I,index:0,expr:constant(box)} as const;
 eqExpr(new TypeChecker(env).whnf(app(projected,natLit(3))),natLit(3));
});

test('defeq expands string literals exactly through String.ofList',()=>{
 const env=baseEnv(),one=levelSucc(levelZero),uN=nameFromDotted('u'),u=levelParam(uN),TU=sort(levelSucc(u));
 env.add({kind:'axiom',name:N.Char,levelParams:[],type:sort(one)});
 env.add({kind:'axiom',name:N.List,levelParams:[uN],type:forallE(nameFromDotted('α'),TU,TU,'implicit')});
 const listU=(x:any)=>app(constant(N.List,[u]),x);
 env.add({kind:'axiom',name:N.ListNil,levelParams:[uN],type:forallE(nameFromDotted('α'),TU,listU(bvar(0)),'implicit')});
 env.add({kind:'axiom',name:N.ListCons,levelParams:[uN],type:forallE(nameFromDotted('α'),TU,forallE(nameFromDotted('a'),bvar(0),forallE(nameFromDotted('as'),listU(bvar(1)),listU(bvar(2)))),'implicit')});
 env.add({kind:'axiom',name:N.CharOfNat,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Char))});
 const listChar=app(constant(N.List,[levelZero]),constant(N.Char));
 env.add({kind:'axiom',name:N.StringOfList,levelParams:[],type:forallE(nameFromDotted('xs'),listChar,constant(N.String))});
 const nil=app(constant(N.ListNil,[levelZero]),constant(N.Char));
 const a=app(constant(N.CharOfNat),natLit(65));
 const smile=app(constant(N.CharOfNat),natLit(0x1F642));
 const xs=mkAppN(constant(N.ListCons,[levelZero]),[constant(N.Char),a,mkAppN(constant(N.ListCons,[levelZero]),[constant(N.Char),smile,nil])]);
 const ctor=app(constant(N.StringOfList),xs);
 const tc=new TypeChecker(env);assert(tc.isDefEq(strLit('A🙂'),ctor),'string literal must equal its UTF-8/codepoint constructor expansion');
});

test('defeq treats zero-field single-constructor inductives as unit-like',()=>{
 const env=baseEnv(),I=nameFromDotted('UnitLike'),mk=nameFromDotted('UnitLike.mk'),u=nameFromDotted('unitLikeValue');
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:mk,type:constant(I)}]}]});
 env.add({kind:'axiom',name:u,levelParams:[],type:constant(I)});
 const tc=new TypeChecker(env);assert(tc.isDefEq(constant(mk),constant(u)),'unit-like inhabitants should be definitionally equal');
});


test('defeq compares projections after lazy delta even when other structure fields differ',()=>{
 const env=baseEnv(),I=nameFromDotted('ProjPair'),mk=nameFromDotted('ProjPair.mk'),a=nameFromDotted('projPairA'),b=nameFromDotted('projPairB');
 const ctorTy=forallE(nameFromDotted('fst'),constant(N.Nat),forallE(nameFromDotted('snd'),constant(N.Nat),constant(I)));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:mk,type:ctorTy}]}]});
 const k=new Kernel(env),ty=constant(I);
 k.addDefinition({kind:'definition',name:a,levelParams:[],type:ty,value:mkAppN(constant(mk),[natLit(1),natLit(2)]),hints:{kind:'regular',height:1n},safety:'safe'});
 k.addDefinition({kind:'definition',name:b,levelParams:[],type:ty,value:mkAppN(constant(mk),[natLit(1),natLit(3)]),hints:{kind:'regular',height:1n},safety:'safe'});
 const pa={kind:'proj',typeName:I,index:0,expr:constant(a)} as const,pb={kind:'proj',typeName:I,index:0,expr:constant(b)} as const;
 const tc=new TypeChecker(env);assert(tc.isDefEq(pa,pb),'equal projected fields should not require entire structures to be defeq');
 assert(!tc.isDefEq({kind:'proj',typeName:I,index:1,expr:constant(a)},{kind:'proj',typeName:I,index:1,expr:constant(b)}),'different projected fields must remain distinct');
});

test('defeq implements structure eta through projections',()=>{
 const env=baseEnv(),I=nameFromDotted('PairN'),mk=nameFromDotted('PairN.mk'),p=nameFromDotted('pairNValue');
 const ctorTy=forallE(nameFromDotted('fst'),constant(N.Nat),forallE(nameFromDotted('snd'),constant(N.Nat),constant(I)));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:mk,type:ctorTy}]}]});
 env.add({kind:'axiom',name:p,levelParams:[],type:constant(I)});
 const pv=constant(p);
 const rebuilt=mkAppN(constant(mk),[
  {kind:'proj',typeName:I,index:0,expr:pv},
  {kind:'proj',typeName:I,index:1,expr:pv}
 ]);
 const tc=new TypeChecker(env);assert(tc.isDefEq(pv,rebuilt),'structure eta should identify a value with reconstruction from its fields');
});

test('non-recursive structure recursor uses kernel eta expansion',()=>{
 const env=baseEnv(),I=nameFromDotted('RecPair'),mk=nameFromDotted('RecPair.mk'),p=nameFromDotted('recPairValue');
 const ctorTy=forallE(nameFromDotted('fst'),constant(N.Nat),forallE(nameFromDotted('snd'),constant(N.Nat),constant(I)));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:mk,type:ctorTy}]}]});
 env.add({kind:'axiom',name:p,levelParams:[],type:constant(I)});
 const motive=lam(nameFromDotted('_'),constant(I),constant(N.Nat));
 const minor=lam(nameFromDotted('fst'),constant(N.Nat),lam(nameFromDotted('snd'),constant(N.Nat),bvar(1)));
 const term=mkAppN(constant(nameFromDotted('RecPair.rec'),[levelSucc(levelZero)]),[motive,minor,constant(p)]);
 const expected={kind:'proj',typeName:I,index:0,expr:constant(p)} as const;
 eqExpr(new TypeChecker(env).whnf(term),expected);
});

test('recursor reduction converts String literals through String.ofList',()=>{
 const env=baseEnv(),R=nameFromDotted('String.testRec'),xsTy=constant(N.Nat);
 env.add({kind:'recursor',name:R,levelParams:[],type:forallE(nameFromDotted('s'),constant(N.String),constant(N.Nat)),all:[N.String],numParams:0,numIndices:0,numMotives:0,numMinors:0,k:false,rules:[{ctor:N.StringOfList,nFields:1,rhs:lam(nameFromDotted('xs'),xsTy,natLit(77))}]});
 eqExpr(new TypeChecker(env).whnf(app(constant(R),strLit('A🙂'))),natLit(77));
});

test('generated recursive recursor computes by iota',()=>{
 const env=baseEnv(),I=nameFromDotted('Count'),z=nameFromDotted('Count.zero'),s=nameFromDotted('Count.succ');
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:z,type:constant(I)},{name:s,type:forallE(nameFromDotted('n'),constant(I),constant(I))}]}]});
 const one=levelSucc(levelZero);const motive=lam(nameFromDotted('_'),constant(I),constant(N.Nat));
 const succMinor=lam(nameFromDotted('n'),constant(I),lam(nameFromDotted('ih'),constant(N.Nat),app(constant(N.NatSucc),bvar(0))));
 const major=app(constant(s),constant(z));
 const rec=constant(nameFromDotted('Count.rec'),[one]);
 const term=app(app(app(app(rec,motive),natLit(0)),succMinor),major);
 const tc=new TypeChecker(env);eqExpr(tc.whnf(term),natLit(1));
});
test('Quot bootstrap requires exact Eq shape and lift reduces',()=>{
 const env=baseEnv(),uN=nameFromDotted('u'),u=levelParam(uN),anon=nameFromDotted('_');const arrow=(a:any,b:any)=>forallE(anon,a,b);
 const eqTy=forallE(nameFromDotted('α'),sort(u),arrow(bvar(0),arrow(bvar(1),sort(levelZero))),'implicit');
 const reflTy=forallE(nameFromDotted('α'),sort(u),forallE(nameFromDotted('a'),bvar(0),app(app(app(constant(N.Eq,[u]),bvar(1)),bvar(0)),bvar(0))),'implicit');
 env.add({kind:'inductive',name:N.Eq,levelParams:[uN],type:eqTy,numParams:2,numIndices:1,all:[N.Eq],ctors:[N.EqRefl],numNested:0,isRec:false,isReflexive:false});
 env.add({kind:'constructor',name:N.EqRefl,levelParams:[uN],type:reflTy,induct:N.Eq,cidx:0,numParams:2,numFields:0});
 addQuot(env);assert(env.quotInitialized);
 const f=lam(nameFromDotted('x'),constant(N.Nat),bvar(0));const q=app(app(app(constant(N.QuotMk,[levelSucc(levelZero)]),constant(N.Nat)),constant(N.Nat)),natLit(7));
 const lift=constant(N.QuotLift,[levelSucc(levelZero),levelSucc(levelZero)]);const term=[constant(N.Nat),constant(N.Nat),constant(N.Nat),f,constant(N.BoolTrue),q].reduce((x,a)=>app(x,a),lift);
 eqExpr(new TypeChecker(env).whnf(term),natLit(7));
});
test('Quot bootstrap fails closed on malformed Eq',()=>{const env=baseEnv();env.add({kind:'axiom',name:N.Eq,levelParams:[],type:sort(levelSucc(levelZero))});throws(()=>addQuot(env));assert(!env.quotInitialized);});


test('nested inductive through Box is transformed and restored',()=>{
 const env=baseEnv(),Box=nameFromDotted('Box'),BoxMk=nameFromDotted('Box.mk'),Tree=nameFromDotted('Tree'),Node=nameFromDotted('Tree.node'),T=sort(levelSucc(levelZero));
 const boxTy=forallE(nameFromDotted('α'),T,T,'implicit');
 const box=(x:any)=>app(constant(Box),x);
 const boxMkTy=forallE(nameFromDotted('α'),T,forallE(nameFromDotted('x'),bvar(0),box(bvar(1))),'implicit');
 addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{name:Box,type:boxTy,ctors:[{name:BoxMk,type:boxMkTy}]}]});
 const treeCtor=forallE(nameFromDotted('children'),box(constant(Tree)),constant(Tree));
 addInductive(env,{levelParams:[],numParams:0,types:[{name:Tree,type:T,ctors:[{name:Node,type:treeCtor}]}]});
 const ti=env.get(Tree),ci=env.get(Node),ri=env.get(nameFromDotted('Tree.rec')),aux=env.get(nameFromDotted('Tree.rec_1'));
 assert(ti.kind==='inductive'&&ti.numNested>0);assert(ci.kind==='constructor'&&exprEq(ci.type,treeCtor));assert(ri.kind==='recursor');assert(aux.kind==='recursor');
 assert(!env.entries().some(x=>nameToString(x.name).startsWith('_nested')),'auxiliary nested declarations must not leak');
});


test('nested inductive preserves constructor-specific parameter BinderInfo through restoration',()=>{
 const env=baseEnv(),Box=nameFromDotted('ParamBox'),BoxMk=nameFromDotted('ParamBox.mk'),Tree=nameFromDotted('ParamTree'),Node=nameFromDotted('ParamTree.node'),T=sort(levelSucc(levelZero));
 const boxTy=forallE(nameFromDotted('α'),T,T,'implicit'),box=(x:any)=>app(constant(Box),x);
 const boxMkTy=forallE(nameFromDotted('α'),T,forallE(nameFromDotted('x'),bvar(0),box(bvar(1))),'implicit');
 addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{name:Box,type:boxTy,ctors:[{name:BoxMk,type:boxMkTy}]}]});
 // The inductive header parameter is explicit, but Lean preserves the constructor's own
 // inferred implicit BinderInfo while eliminating/restoring the nested occurrence.
 const treeTy=forallE(nameFromDotted('α'),T,T);
 const tree=(a:any)=>app(constant(Tree),a);
 const ctorTy=forallE(nameFromDotted('α'),T,forallE(nameFromDotted('children'),box(tree(bvar(0))),tree(bvar(1))),'implicit');
 addInductive(env,{levelParams:[],numParams:1,types:[{name:Tree,type:treeTy,ctors:[{name:Node,type:ctorTy}]}]});
 const ci=env.get(Node);assert(ci.kind==='constructor');assert(ci.type.kind==='forall'&&ci.type.binderInfo==='implicit');eqExpr(ci.type,ctorTy);
});

test('nested inductive admission rejects the reserved _nested auxiliary namespace',()=>{
 const env=baseEnv(),I=nameFromDotted('ReservedNested'),Mk=nameFromDotted('ReservedNested.mk'),aux=nameFromDotted('_nested.KNHost_1');
 const badConstTy=forallE(nameFromDotted('x'),constant(aux),constant(I));
 throws(()=>addInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelZero),ctors:[{name:Mk,type:badConstTy}]}]}));
 assert(!env.has(I)&&!env.has(Mk),'reserved-name rejection must be transactional');
 const J=nameFromDotted('ReservedNestedProj'),JMk=nameFromDotted('ReservedNestedProj.mk');
 const badProj={kind:'proj',typeName:aux,index:0,expr:bvar(0)} as const;
 const badProjTy=forallE(nameFromDotted('x'),constant(N.Nat),forallE(nameFromDotted('y'),badProj,constant(J)));
 throws(()=>addInductive(env,{levelParams:[],numParams:0,types:[{name:J,type:sort(levelZero),ctors:[{name:JMk,type:badProjTy}]}]}));
 assert(!env.has(J)&&!env.has(JMk),'reserved projection-name rejection must be transactional');
});

test('unsafe nested inductive preserves unsafe checking through restoration hardening',()=>{
 const env=baseEnv(),T=sort(levelSucc(levelZero)),U=nameFromDotted('NestedUnsafePayload');env.add({kind:'axiom',name:U,levelParams:[],type:T,isUnsafe:true});
 const Box=nameFromDotted('UnsafeBox'),BoxMk=nameFromDotted('UnsafeBox.mk'),Tree=nameFromDotted('UnsafeTree'),Node=nameFromDotted('UnsafeTree.node');
 const boxTy=forallE(nameFromDotted('α'),T,T,'implicit'),box=(x:any)=>app(constant(Box),x),boxMkTy=forallE(nameFromDotted('α'),T,forallE(nameFromDotted('x'),bvar(0),box(bvar(1))),'implicit');
 addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{name:Box,type:boxTy,ctors:[{name:BoxMk,type:boxMkTy}]}]});
 const ctorTy=forallE(nameFromDotted('payload'),constant(U),forallE(nameFromDotted('children'),box(constant(Tree)),constant(Tree)));
 addInductive(env,{levelParams:[],numParams:0,isUnsafe:true,types:[{name:Tree,type:T,ctors:[{name:Node,type:ctorTy}]}]});
 const ti=env.get(Tree),ci=env.get(Node),ri=env.get(nameFromDotted('UnsafeTree.rec')),aux=env.get(nameFromDotted('UnsafeTree.rec_1'));
 assert(ti.kind==='inductive'&&ti.isUnsafe===true&&ti.numNested>0);assert(ci.kind==='constructor'&&ci.isUnsafe===true);assert(ri.kind==='recursor'&&ri.isUnsafe===true);assert(aux.kind==='recursor'&&aux.isUnsafe===true);
});



import { addPrimitiveDefinition, addPrimitiveInductive, canonicalNatAddValue } from '../src/kernel/primitive.js';
import { closeLambda, inspectNatWellFounded, inspectNatWfOuter, probeNatWellFounded, probeNatWellFoundedRecursiveCall } from '../src/kernel/primitive/wf.js';
import { probeNatBitwiseEquation } from '../src/kernel/primitive/bitwise.js';
import { buildNatDecEqModel, checkBoolCondition, checkNatEqCondition, checkNatLeCondition } from '../src/kernel/primitive/condition.js';

function primitiveNatEnv():Environment{
 const env=new Environment(),T=sort(levelSucc(levelZero));
 addPrimitiveInductive(env,{levelParams:[],numParams:0,types:[{name:N.Nat,type:T,ctors:[
  {name:N.NatZero,type:constant(N.Nat)},
  {name:N.NatSucc,type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))}
 ]}]});
 return env;
}

function primitiveNatBoolEnv():Environment{
 const env=primitiveNatEnv(),T=sort(levelSucc(levelZero));
 addPrimitiveInductive(env,{levelParams:[],numParams:0,types:[{name:N.Bool,type:T,ctors:[
  {name:N.BoolFalse,type:constant(N.Bool)},
  {name:N.BoolTrue,type:constant(N.Bool)}
 ]}]});
 return env;
}

function addBoolConditionScaffold(env:Environment,swapIte=false):void{
 const uName=nameFromDotted('u'),u=levelParam(uName),one=levelSucc(levelZero);
 const FalseN=nameFromDotted('False'),D=nameFromDotted('Decidable'),DF=nameFromDotted('Decidable.isFalse'),DT=nameFromDotted('Decidable.isTrue');
 const Eq=(a:any,b:any)=>mkAppN(constant(N.Eq,[levelSucc(levelZero)]),[constant(N.Bool),a,b]);
 env.add({kind:'axiom',name:FalseN,levelParams:[],type:sort(levelZero)});
 env.add({kind:'axiom',name:N.Eq,levelParams:[uName],type:forallE(nameFromDotted('α'),sort(u),forallE(nameFromDotted('a'),bvar(0),forallE(nameFromDotted('b'),bvar(1),sort(levelZero))))});
 env.add({kind:'axiom',name:N.EqRefl,levelParams:[uName],type:forallE(nameFromDotted('α'),sort(u),forallE(nameFromDotted('a'),bvar(0),mkAppN(constant(N.Eq,[u]),[bvar(1),bvar(0),bvar(0)])))});
 addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{name:D,type:forallE(nameFromDotted('p'),sort(levelZero),sort(one)),ctors:[
  {name:DF,type:forallE(nameFromDotted('p'),sort(levelZero),forallE(nameFromDotted('h'),forallE(nameFromDotted('_'),bvar(0),constant(FalseN)),app(constant(D),bvar(1))),'implicit')},
  {name:DT,type:forallE(nameFromDotted('p'),sort(levelZero),forallE(nameFromDotted('h'),bvar(0),app(constant(D),bvar(1))),'implicit')}
 ]}]});
 const eqFF=nameFromDotted('Cond.eqFF'),eqTT=nameFromDotted('Cond.eqTT'),neFT=nameFromDotted('Cond.neFT'),neTF=nameFromDotted('Cond.neTF');
 env.add({kind:'axiom',name:eqFF,levelParams:[],type:Eq(constant(N.BoolFalse),constant(N.BoolFalse))});
 env.add({kind:'axiom',name:eqTT,levelParams:[],type:Eq(constant(N.BoolTrue),constant(N.BoolTrue))});
 env.add({kind:'axiom',name:neFT,levelParams:[],type:forallE(nameFromDotted('h'),Eq(constant(N.BoolFalse),constant(N.BoolTrue)),constant(FalseN))});
 env.add({kind:'axiom',name:neTF,levelParams:[],type:forallE(nameFromDotted('h'),Eq(constant(N.BoolTrue),constant(N.BoolFalse)),constant(FalseN))});
 const d=(p:any)=>app(constant(D),p),isT=(p:any,h:any)=>mkAppN(constant(DT),[p,h]),isF=(p:any,h:any)=>mkAppN(constant(DF),[p,h]);
 const brec=(m:any,f:any,t:any,b:any)=>mkAppN(constant(nameFromDotted('Bool.rec'),[one]),[m,f,t,b]);
 // fun a b => match a, b with false,false=>isTrue; false,true=>isFalse; true,false=>isFalse; true,true=>isTrue
 const ffP=Eq(constant(N.BoolFalse),constant(N.BoolFalse)),ftP=Eq(constant(N.BoolFalse),constant(N.BoolTrue)),tfP=Eq(constant(N.BoolTrue),constant(N.BoolFalse)),ttP=Eq(constant(N.BoolTrue),constant(N.BoolTrue));
 const falseBranch=brec(lam(nameFromDotted('y'),constant(N.Bool),d(Eq(constant(N.BoolFalse),bvar(0)))),isT(ffP,constant(eqFF)),isF(ftP,constant(neFT)),bvar(0));
 const trueBranch=brec(lam(nameFromDotted('y'),constant(N.Bool),d(Eq(constant(N.BoolTrue),bvar(0)))),isF(tfP,constant(neTF)),isT(ttP,constant(eqTT)),bvar(0));
 const outerMotive=lam(nameFromDotted('x'),constant(N.Bool),d(Eq(bvar(0),bvar(1))));
 const decVal=lam(nameFromDotted('a'),constant(N.Bool),lam(nameFromDotted('b'),constant(N.Bool),brec(outerMotive,falseBranch,trueBranch,bvar(1))));
 const decTy=forallE(nameFromDotted('a'),constant(N.Bool),forallE(nameFromDotted('b'),constant(N.Bool),d(Eq(bvar(1),bvar(0)))));
 env.add({kind:'definition',name:N.BoolDecEq,levelParams:[],type:decTy,value:decVal,hints:{kind:'regular',height:1n},safety:'safe'});
 const rec=constant(nameFromDotted('Decidable.rec'),[one]);
 const motive=lam(nameFromDotted('_d'),app(constant(D),bvar(3)),bvar(5));
 const mFalse=lam(nameFromDotted('_hn'),forallE(nameFromDotted('_hp'),bvar(3),constant(FalseN)),swapIte?bvar(2):bvar(1));
 const mTrue=lam(nameFromDotted('_hp'),bvar(3),swapIte?bvar(1):bvar(2));
 const iteVal=lam(nameFromDotted('α'),sort(one),lam(nameFromDotted('c'),sort(levelZero),lam(nameFromDotted('h'),app(constant(D),bvar(0)),lam(nameFromDotted('t'),bvar(2),lam(nameFromDotted('e'),bvar(3),mkAppN(rec,[bvar(3),motive,mFalse,mTrue,bvar(2)]))))));
 const iteTy=forallE(nameFromDotted('α'),sort(one),forallE(nameFromDotted('c'),sort(levelZero),forallE(nameFromDotted('h'),app(constant(D),bvar(0)),forallE(nameFromDotted('t'),bvar(2),forallE(nameFromDotted('e'),bvar(3),bvar(4)))),'instImplicit'));
 env.add({kind:'definition',name:N.Ite,levelParams:[uName],type:iteTy,value:iteVal,hints:{kind:'regular',height:1n},safety:'safe'});
}

function addNatLeConditionScaffold(env:Environment,swapDite=false):void{
 const one=levelSucc(levelZero),uN=nameFromDotted('u'),u=levelParam(uN),FalseN=N.False;
 const Nat=constant(N.Nat),Bool=constant(N.Bool),Prop=sort(levelZero),Type=sort(one);
 const D=(p:any)=>app(constant(N.Decidable),p),not=(p:any)=>app(constant(N.Not),p);
 const eqBool=(a:any,b:any)=>mkAppN(constant(N.Eq,[levelSucc(levelZero)]),[Bool,a,b]);
 const ble=(a:any,b:any)=>mkAppN(constant(N.NatBle),[a,b]);
 const leInst=()=>app(constant(N.LE,[levelZero]),Nat);
 const le=(a:any,b:any)=>mkAppN(constant(N.LELe,[levelZero]),[Nat,constant(N.InstLENat),a,b]);
 // Generic logical support used by the reflected condition certificate.
 env.add({kind:'axiom',name:N.LE,levelParams:[uN],type:forallE(nameFromDotted('α'),sort(levelSucc(u)),sort(levelSucc(u)))});
 env.add({kind:'axiom',name:N.LELe,levelParams:[uN],type:forallE(nameFromDotted('α'),sort(levelSucc(u)),forallE(nameFromDotted('_inst'),app(constant(N.LE,[u]),bvar(0)),forallE(nameFromDotted('a'),bvar(1),forallE(nameFromDotted('b'),bvar(2),Prop))))});
 env.add({kind:'axiom',name:N.InstLENat,levelParams:[],type:leInst()});
 env.add({kind:'definition',name:N.Not,levelParams:[],type:forallE(nameFromDotted('p'),Prop,Prop),value:lam(nameFromDotted('p'),Prop,forallE(nameFromDotted('_h'),bvar(0),constant(FalseN))),hints:{kind:'regular',height:1n},safety:'safe'});
 const diteTy=forallE(nameFromDotted('α'),sort(u),forallE(nameFromDotted('c'),Prop,forallE(nameFromDotted('h'),D(bvar(0)),forallE(nameFromDotted('t'),forallE(nameFromDotted('_hp'),bvar(1),bvar(3)),forallE(nameFromDotted('e'),forallE(nameFromDotted('_hn'),not(bvar(2)),bvar(4)),bvar(4)))),'instImplicit'));
 const rec=constant(nameFromDotted('Decidable.rec'),[u]);
 // Under α,c,h,t,e: motive ignores the decision proof and returns α.
 const motive=lam(nameFromDotted('_d'),D(bvar(3)),bvar(5));
 const mFalse=lam(nameFromDotted('hn'),not(bvar(3)),swapDite?app(bvar(2),bvar(0)):app(bvar(1),bvar(0)));
 const mTrue=lam(nameFromDotted('hp'),bvar(3),swapDite?app(bvar(1),bvar(0)):app(bvar(2),bvar(0)));
 const diteVal=lam(nameFromDotted('α'),sort(u),lam(nameFromDotted('c'),Prop,lam(nameFromDotted('h'),D(bvar(0)),lam(nameFromDotted('t'),forallE(nameFromDotted('_hp'),bvar(1),bvar(3)),lam(nameFromDotted('e'),forallE(nameFromDotted('_hn'),not(bvar(2)),bvar(4)),mkAppN(rec,[bvar(3),motive,mFalse,mTrue,bvar(2)]))))));
 env.add({kind:'definition',name:N.Dite,levelParams:[uN],type:diteTy,value:diteVal,hints:{kind:'regular',height:1n},safety:'safe'});
 const nat2Bool=forallE(nameFromDotted('n'),Nat,forallE(nameFromDotted('m'),Nat,Bool));
 env.add({kind:'axiom',name:N.NatBle,levelParams:[],type:nat2Bool});
 const reflTy=forallE(nameFromDotted('n'),Nat,
  forallE(nameFromDotted('m'),Nat,
   forallE(nameFromDotted('h'),eqBool(ble(bvar(1),bvar(0)),constant(N.BoolTrue)),le(bvar(2),bvar(1)))));
 env.add({kind:'axiom',name:N.NatLeOfBleTrue,levelParams:[],type:reflTy});
 const nreflTy=forallE(nameFromDotted('n'),Nat,
  forallE(nameFromDotted('m'),Nat,
   forallE(nameFromDotted('h'),not(eqBool(ble(bvar(1),bvar(0)),constant(N.BoolTrue))),not(le(bvar(2),bvar(1))))));
 env.add({kind:'axiom',name:N.NatNotLeOfNotBleTrue,levelParams:[],type:nreflTy});
 const decLeBody=lam(nameFromDotted('n'),Nat,lam(nameFromDotted('m'),Nat,(()=>{
   const n=bvar(1),m=bvar(0),b=ble(n,m),c=eqBool(b,constant(N.BoolTrue)),p=le(n,m);
   const t=lam(nameFromDotted('h'),c,mkAppN(constant(N.DecidableIsTrue),[lift(p),mkAppN(constant(N.NatLeOfBleTrue),[lift(n),lift(m),bvar(0)])]));
   const e=lam(nameFromDotted('h'),not(c),mkAppN(constant(N.DecidableIsFalse),[lift(p),mkAppN(constant(N.NatNotLeOfNotBleTrue),[lift(n),lift(m),bvar(0)])]));
   return mkAppN(constant(N.Dite,[one]),[D(p),c,mkAppN(constant(N.BoolDecEq),[b,constant(N.BoolTrue)]),t,e]);
 })()));
 const decLeTy=forallE(nameFromDotted('n'),Nat,forallE(nameFromDotted('m'),Nat,D(le(bvar(1),bvar(0)))));
 env.add({kind:'definition',name:N.NatDecLe,levelParams:[],type:decLeTy,value:decLeBody,hints:{kind:'regular',height:2n},safety:'safe'});
}



function addNatEqConditionScaffold(env:Environment,asAxiom=false):void{
 const Nat=constant(N.Nat),Bool=constant(N.Bool),D=(p:any)=>app(constant(N.Decidable),p),not=(p:any)=>app(constant(N.Not),p);
 const eq=(ty:any,a:any,b:any)=>mkAppN(constant(N.Eq,[levelSucc(levelZero)]),[ty,a,b]);
 const beq=(a:any,b:any)=>mkAppN(constant(N.NatBeq),[a,b]);
 const nat2Bool=forallE(nameFromDotted('n'),Nat,forallE(nameFromDotted('m'),Nat,Bool));
 env.add({kind:'axiom',name:N.NatBeq,levelParams:[],type:nat2Bool});
 const eqTrueTy=forallE(nameFromDotted('n'),Nat,forallE(nameFromDotted('m'),Nat,
  forallE(nameFromDotted('h'),eq(Bool,beq(bvar(1),bvar(0)),constant(N.BoolTrue)),eq(Nat,bvar(2),bvar(1)))));
 env.add({kind:'axiom',name:N.NatEqOfBeqTrue,levelParams:[],type:eqTrueTy});
 const neFalseTy=forallE(nameFromDotted('n'),Nat,forallE(nameFromDotted('m'),Nat,
  forallE(nameFromDotted('h'),eq(Bool,beq(bvar(1),bvar(0)),constant(N.BoolFalse)),not(eq(Nat,bvar(2),bvar(1))))));
 env.add({kind:'axiom',name:N.NatNeOfBeqFalse,levelParams:[],type:neFalseTy});
 const decEqTy=forallE(nameFromDotted('n'),Nat,forallE(nameFromDotted('m'),Nat,D(eq(Nat,bvar(1),bvar(0)))));
 if(asAxiom)env.add({kind:'axiom',name:N.NatDecEq,levelParams:[],type:decEqTy});
 else env.add({kind:'definition',name:N.NatDecEq,levelParams:[],type:decEqTy,value:buildNatDecEqModel(),hints:{kind:'regular',height:2n},safety:'safe'});
}

function boolRecBody(falseCase:any,trueCase:any,major:any):any{
 const one=levelSucc(levelZero),motive=lam(nameFromDotted('_'),constant(N.Bool),constant(N.Bool));
 return mkAppN(constant(nameFromDotted('Bool.rec'),[one]),[motive,falseCase,trueCase,major]);
}
function boolAndOp():any{return lam(nameFromDotted('a'),constant(N.Bool),lam(nameFromDotted('b'),constant(N.Bool),boolRecBody(constant(N.BoolFalse),bvar(0),bvar(1))));}
function boolOrOp():any{return lam(nameFromDotted('a'),constant(N.Bool),lam(nameFromDotted('b'),constant(N.Bool),boolRecBody(bvar(0),constant(N.BoolTrue),bvar(1))));}
function boolNot(x:any):any{return boolRecBody(constant(N.BoolTrue),constant(N.BoolFalse),x);}
function boolXorOp():any{return lam(nameFromDotted('a'),constant(N.Bool),lam(nameFromDotted('b'),constant(N.Bool),boolRecBody(bvar(0),boolNot(bvar(0)),bvar(1))));}
function addBitwiseSignature(env:Environment):void{
 const arrow=(a:any,b:any)=>forallE(nameFromDotted('_'),a,b),bool2=arrow(constant(N.Bool),arrow(constant(N.Bool),constant(N.Bool))),nat2=arrow(constant(N.Nat),arrow(constant(N.Nat),constant(N.Nat)));
 env.add({kind:'axiom',name:N.NatBitwise,levelParams:[],type:arrow(bool2,nat2)});
}



function natArrow(a:any,b:any):any{return forallE(nameFromDotted('_'),a,b);}
function addSyntheticNatWfScaffold(env:Environment,captureFunctional=false):{wrapper:any;measure:any}{
 const Nat=constant(N.Nat),P=nameFromDotted('Synthetic.Wf.P'),pf=nameFromDotted('Synthetic.Wf.pf');
 env.add({kind:'axiom',name:P,levelParams:[],type:sort(levelZero)});
 env.add({kind:'axiom',name:pf,levelParams:[],type:constant(P)});
 const nat1=natArrow(Nat,Nat);
 env.add({kind:'definition',name:N.WfNatEager,levelParams:[],type:nat1,value:lam(nameFromDotted('n'),Nat,bvar(0)),hints:{kind:'regular',height:1n},safety:'safe'});
 const goTy=natArrow(Nat,natArrow(Nat,natArrow(nat1,natArrow(Nat,natArrow(Nat,natArrow(Nat,natArrow(constant(P),Nat)))))));
 env.add({kind:'axiom',name:N.WfNatFixGo,levelParams:[],type:goTy});
 const fixTy=natArrow(Nat,natArrow(Nat,natArrow(nat1,natArrow(Nat,natArrow(Nat,Nat)))));
 const fixVal=lam(nameFromDotted('alpha'),Nat,
  lam(nameFromDotted('motive'),Nat,
   lam(nameFromDotted('measure'),nat1,
    lam(nameFromDotted('functional'),Nat,
     lam(nameFromDotted('a'),Nat,
      mkAppN(constant(N.WfNatFixGo),[
       bvar(4),bvar(3),bvar(2),bvar(1),
       app(constant(N.WfNatEager),app(constant(N.NatSucc),app(bvar(2),bvar(0)))),
       bvar(0),constant(pf)
      ]))))));
 env.add({kind:'definition',name:N.WfNatFix,levelParams:[],type:fixTy,value:fixVal,hints:{kind:'regular',height:2n},safety:'safe'});
 const wrapper=nameFromDotted(captureFunctional?'Synthetic.Wf.capture':'Synthetic.Wf.good');
 const measure=lam(nameFromDotted('m'),Nat,lam(nameFromDotted('n'),Nat,bvar(1)));
 // Within the nested `measureFn` lambda: a=#0, n=#1, m=#2.
 const body=lam(nameFromDotted('m'),Nat,lam(nameFromDotted('n'),Nat,
  mkAppN(constant(N.WfNatFix),[
   natLit(0),natLit(0),lam(nameFromDotted('a'),Nat,bvar(2)),captureFunctional?bvar(1):natLit(0),bvar(0)
  ])));
 env.add({kind:'definition',name:wrapper,levelParams:[],type:natArrow(Nat,natArrow(Nat,Nat)),value:body,hints:{kind:'regular',height:3n},safety:'safe'});
 return {wrapper,measure};
}



function addBoundedNatFuelFixture(env:Environment,kind:'mod'|'div',badRule=false):any{
 const Nat=constant(N.Nat),zero=constant(N.NatZero),succ=(x:any)=>app(constant(N.NatSucc),x),one=succ(zero);
 const le=(a:any,b:any)=>mkAppN(constant(N.LELe,[levelZero]),[Nat,constant(N.InstLENat),a,b]);
 const dec=(a:any,b:any)=>mkAppN(constant(N.NatDecLe),[a,b]);
 const not=(p:any)=>app(constant(N.Not),p),sub=(a:any,b:any)=>mkAppN(constant(N.NatSub),[a,b]);
 const nat2=forallE(nameFromDotted('_'),Nat,forallE(nameFromDotted('_'),Nat,Nat));
 if(!env.has(N.NatSub))env.add({kind:'axiom',name:N.NatSub,levelParams:[],type:nat2});
 const goName=kind==='mod'?N.NatModCoreGo:N.NatDivGo;
 const goTy=forallE(nameFromDotted('y'),Nat,
  forallE(nameFromDotted('hy'),le(one,bvar(0)),
   forallE(nameFromDotted('fuel'),Nat,
    forallE(nameFromDotted('x'),Nat,
     forallE(nameFromDotted('h'),le(succ(bvar(0)),bvar(1)),Nat)))));
 const ltSelfTy=forallE(nameFromDotted('x'),Nat,le(succ(bvar(0)),succ(bvar(0))));
 env.add({kind:'axiom',name:N.NatLtSuccSelf,levelParams:[],type:ltSelfTy});
 const fuelLemmaTy=forallE(nameFromDotted('x'),Nat,forallE(nameFromDotted('y'),Nat,forallE(nameFromDotted('fuel'),Nat,
  forallE(nameFromDotted('hy'),le(one,bvar(1)),forallE(nameFromDotted('hle'),le(bvar(2),bvar(3)),
   forallE(nameFromDotted('h'),le(succ(bvar(4)),succ(bvar(2))),le(succ(sub(bvar(5),bvar(4))),bvar(3))))))));
 env.add({kind:'axiom',name:N.NatDivRecFuelLemma,levelParams:[],type:fuelLemmaTy});

 // A bounded recursor-style model for generated `go`: major argument is `fuel` (index 2).
 // Succ rule context after application: y, hy, fuelPred, x, h.
 const ry=bvar(4),rhy=bvar(3),rfuel=bvar(2),rx=bvar(1),rh=bvar(0),p=le(ry,rx);
 const branchP=lift(p),by= bvar(5),bhy=bvar(4),bfuel=bvar(3),bx=bvar(2),bh=bvar(1),hle=bvar(0);
 const pf=mkAppN(constant(N.NatDivRecFuelLemma),[bx,by,bfuel,bhy,hle,bh]);
 let recCall=mkAppN(constant(goName),[by,bhy,bfuel,sub(bx,by),pf]);
 if(kind==='div')recCall=succ(recCall);
 if(badRule)recCall=kind==='div'?zero:succ(zero);
 const stop=kind==='div'?zero:bvar(2);
 const succBody=mkAppN(constant(N.Dite,[levelSucc(levelZero)]),[
  Nat,p,dec(ry,rx),
  lam(nameFromDotted('hle'),p,recCall),
  lam(nameFromDotted('hnle'),not(p),stop)
 ]);
 const succRule=lam(nameFromDotted('y'),Nat,
  lam(nameFromDotted('hy'),le(one,bvar(0)),
   lam(nameFromDotted('fuel'),Nat,
    lam(nameFromDotted('x'),Nat,
     lam(nameFromDotted('h'),le(succ(bvar(0)),succ(bvar(1))),succBody)))));
 const zeroRule=lam(nameFromDotted('y'),Nat,
  lam(nameFromDotted('hy'),le(one,bvar(0)),
   lam(nameFromDotted('x'),Nat,
    lam(nameFromDotted('h'),le(succ(bvar(0)),zero),kind==='div'?zero:bvar(1)))));
 env.add({kind:'recursor',name:goName,levelParams:[],type:goTy,all:[N.Nat],numParams:2,numIndices:0,numMotives:0,numMinors:0,k:false,rules:[
  {ctor:N.NatZero,nFields:0,rhs:zeroRule},{ctor:N.NatSucc,nFields:1,rhs:succRule}
 ]});

 let value:any;
 if(kind==='div'){
  const x=bvar(1),y=bvar(0),pp=le(one,y);
  const t=lam(nameFromDotted('hy'),pp,mkAppN(constant(goName),[lift(y),bvar(0),succ(lift(x)),lift(x),app(constant(N.NatLtSuccSelf),lift(x))]));
  const e=lam(nameFromDotted('_'),not(pp),zero);
  value=lam(nameFromDotted('x'),Nat,lam(nameFromDotted('y'),Nat,mkAppN(constant(N.Dite,[levelSucc(levelZero)]),[Nat,pp,dec(one,y),t,e])));
 }else{
  const motive=lam(nameFromDotted('_'),Nat,Nat);
  // step context under outer n,y: x=#1, ih=#0, y=#2
  const x=bvar(1),y=bvar(2),sx=succ(x),pp=le(one,y);
  const it=lam(nameFromDotted('hy'),pp,mkAppN(constant(goName),[lift(y),bvar(0),succ(lift(sx)),lift(sx),app(constant(N.NatLtSuccSelf),lift(sx))]));
  const ie=lam(nameFromDotted('_'),not(pp),lift(sx));
  const inner=mkAppN(constant(N.Dite,[levelSucc(levelZero)]),[Nat,pp,dec(one,y),it,ie]);
  const top=mkAppN(constant(N.Ite,[levelSucc(levelZero)]),[Nat,le(y,sx),dec(y,sx),inner,sx]);
  const step=lam(nameFromDotted('x'),Nat,lam(nameFromDotted('_ih'),Nat,top));
  value=lam(nameFromDotted('n'),Nat,lam(nameFromDotted('y'),Nat,mkAppN(constant(nameFromDotted('Nat.rec'),[levelSucc(levelZero)]),[motive,zero,step,bvar(1)])));
 }
 return {kind:'definition',name:kind==='mod'?N.NatMod:N.NatDiv,levelParams:[],type:nat2,value,hints:{kind:'regular',height:4n},safety:'safe'};
}

test('boolean primitive condition verifier checks true/false ite behavior',()=>{
 const env=primitiveNatBoolEnv();addBoolConditionScaffold(env);checkBoolCondition(env);
 const bad=primitiveNatBoolEnv();addBoolConditionScaffold(bad,true);throws(()=>checkBoolCondition(bad));
});

test('Nat ≤ primitive condition verifier checks reflected decider and dependent-if behavior',()=>{
 const env=primitiveNatBoolEnv();addBoolConditionScaffold(env);addNatLeConditionScaffold(env);checkNatLeCondition(env);
 const bad=primitiveNatBoolEnv();addBoolConditionScaffold(bad);addNatLeConditionScaffold(bad,true);throws(()=>checkNatLeCondition(bad));
});



test('Nat = primitive condition verifier checks reflection plus ite/dite control',()=>{
 const env=primitiveNatBoolEnv();addBoolConditionScaffold(env);addNatLeConditionScaffold(env);addNatEqConditionScaffold(env);checkNatEqCondition(env);
 const badDec=primitiveNatBoolEnv();addBoolConditionScaffold(badDec);addNatLeConditionScaffold(badDec);addNatEqConditionScaffold(badDec,true);throws(()=>checkNatEqCondition(badDec));
 const badDite=primitiveNatBoolEnv();addBoolConditionScaffold(badDite);addNatLeConditionScaffold(badDite,true);addNatEqConditionScaffold(badDite);throws(()=>checkNatEqCondition(badDite));
});



test('primitive Nat.mod checks bounded wrapper and go fuel equations',()=>{
 const env=primitiveNatBoolEnv();addBoolConditionScaffold(env);addNatLeConditionScaffold(env);const v=addBoundedNatFuelFixture(env,'mod');addPrimitiveDefinition(env,v);assert(env.has(N.NatMod));
 const bad=primitiveNatBoolEnv();addBoolConditionScaffold(bad);addNatLeConditionScaffold(bad);const bv=addBoundedNatFuelFixture(bad,'mod',true);throws(()=>addPrimitiveDefinition(bad,bv));
});

test('primitive Nat.div checks bounded top and go fuel equations',()=>{
 const env=primitiveNatBoolEnv();addBoolConditionScaffold(env);addNatLeConditionScaffold(env);const v=addBoundedNatFuelFixture(env,'div');addPrimitiveDefinition(env,v);assert(env.has(N.NatDiv));
 const bad=primitiveNatBoolEnv();addBoolConditionScaffold(bad);addNatLeConditionScaffold(bad);const bv=addBoundedNatFuelFixture(bad,'div',true);throws(()=>addPrimitiveDefinition(bad,bv));
});

test('whnfCore separates cheap recursor-major reduction from cheap projection reduction',()=>{
 const env=primitiveNatEnv(),D=nameFromDotted('CheapRec.major'),one=levelSucc(levelZero);
 env.add({kind:'definition',name:D,levelParams:[],type:constant(N.Nat),value:natLit(0),hints:{kind:'regular',height:1n},safety:'safe'});
 const motive=lam(nameFromDotted('_'),constant(N.Nat),constant(N.Nat));
 const step=lam(nameFromDotted('_n'),constant(N.Nat),lam(nameFromDotted('ih'),constant(N.Nat),bvar(0)));
 const rec=mkAppN(constant(nameFromDotted('Nat.rec'),[one]),[motive,natLit(11),step,constant(D)]),tc=new TypeChecker(env);
 const cheap=tc.whnfCore(rec,true,true);
 assert(!exprEq(cheap,natLit(11)),'cheap_rec must not delta-reduce the major premise');
 eqExpr(tc.whnfCore(rec,false,false),natLit(11));
});

test('whnfCore cache follows Lean 4.34 cheap/full and direct-iota boundaries',()=>{
 const env=primitiveNatEnv(),tc=new TypeChecker(env),one=levelSucc(levelZero);
 const beta=app(lam(nameFromDotted('x'),constant(N.Nat),bvar(0)),natLit(3));
 tc.whnfCore(beta,true,true);
 assert(Number(tc.state.whnfCore.size)===0,'cheap WHNF must not populate the full whnfCore cache');
 eqExpr(tc.whnfCore(beta),natLit(3));
 assert(tc.state.whnfCore.has(tc.state.exprId(beta)),'full beta WHNF should cache the original expression');

 const tc2=new TypeChecker(env);
 const motive=lam(nameFromDotted('_'),constant(N.Nat),constant(N.Nat));
 const step=lam(nameFromDotted('_n'),constant(N.Nat),lam(nameFromDotted('ih'),constant(N.Nat),bvar(0)));
 const rec=mkAppN(constant(nameFromDotted('Nat.rec'),[one]),[motive,natLit(17),step,constant(N.NatZero)]);
 eqExpr(tc2.whnfCore(rec),natLit(17));
 assert(!tc2.state.whnfCore.has(tc2.state.exprId(rec)),'Lean 4.34 returns directly after recursor iota instead of caching the original recursor application');
});

test('well-founded primitive outer recognizer validates Lean fix/fix.go skeleton',()=>{
 const env=primitiveNatEnv(),{wrapper,measure}=addSyntheticNatWfScaffold(env);
 const r=inspectNatWfOuter(env,constant(wrapper),measure);
 assert(nameToString(r.fixGo)==='WellFounded.Nat.fix.go');
});

test('well-founded primitive outer recognizer rejects captured recursion variables',()=>{
 const env=primitiveNatEnv(),{wrapper,measure}=addSyntheticNatWfScaffold(env,true);
 throws(()=>inspectNatWfOuter(env,constant(wrapper),measure));
});


function addSyntheticNatWfCompleteScaffold(env:Environment,badInner=false,recursiveFunctional=false):{wrapper:any;measure:any}{
 const Nat=constant(N.Nat),P=nameFromDotted('Synthetic.Wf2.P'),pf=nameFromDotted('Synthetic.Wf2.pf'),one=levelSucc(levelZero);
 env.add({kind:'axiom',name:P,levelParams:[],type:sort(levelZero)});env.add({kind:'axiom',name:pf,levelParams:[],type:constant(P)});
 const nat1=natArrow(Nat,Nat),recDom=natArrow(Nat,natArrow(constant(P),Nat));
 const FTy=natArrow(Nat,natArrow(recDom,Nat));
 env.add({kind:'definition',name:N.WfNatEager,levelParams:[],type:nat1,value:lam(nameFromDotted('n'),Nat,bvar(0)),hints:{kind:'regular',height:1n},safety:'safe'});
 const goTy=natArrow(Nat,natArrow(Nat,natArrow(nat1,natArrow(FTy,natArrow(Nat,natArrow(Nat,natArrow(constant(P),Nat)))))));
 // At the body of these five lambdas: fuel=#0, F=#1, measure=#2, motive=#3, alpha=#4.
 const motiveFuel=lam(nameFromDotted('_fuel'),Nat,recDom);
 const base=lam(nameFromDotted('x'),Nat,lam(nameFromDotted('hfuel'),constant(P),natLit(0)));
 const step=lam(nameFromDotted('n'),Nat,
  lam(nameFromDotted('ih'),recDom,
   lam(nameFromDotted('x'),Nat,
    lam(nameFromDotted('hfuel'),constant(P),
     app(app(bvar(5),bvar(1)),lam(nameFromDotted('y'),Nat,lam(nameFromDotted('hy'),constant(P),app(app(bvar(4),bvar(1)),bvar(0)))))
    ))));
 const natRec=mkAppN(constant(nameFromDotted('Nat.rec'),[one]),[motiveFuel,base,step]);
 const recFn=badInner?app(lam(nameFromDotted('_'),Nat,natRec),bvar(0)):natRec;
 const goVal=lam(nameFromDotted('alpha'),Nat,
  lam(nameFromDotted('motive'),Nat,
   lam(nameFromDotted('measure'),nat1,
    lam(nameFromDotted('F'),FTy,
     lam(nameFromDotted('fuel'),Nat,app(recFn,bvar(0)))))));
 env.add({kind:'definition',name:N.WfNatFixGo,levelParams:[],type:goTy,value:goVal,hints:{kind:'regular',height:1n},safety:'safe'});
 const fixTy=natArrow(Nat,natArrow(Nat,natArrow(nat1,natArrow(FTy,natArrow(Nat,Nat)))));
 const fixVal=lam(nameFromDotted('alpha'),Nat,
  lam(nameFromDotted('motive'),Nat,
   lam(nameFromDotted('measure'),nat1,
    lam(nameFromDotted('F'),FTy,
     lam(nameFromDotted('a'),Nat,
      mkAppN(constant(N.WfNatFixGo),[
       bvar(4),bvar(3),bvar(2),bvar(1),app(constant(N.WfNatEager),app(constant(N.NatSucc),app(bvar(2),bvar(0)))),bvar(0),constant(pf)
      ]))))));
 env.add({kind:'definition',name:N.WfNatFix,levelParams:[],type:fixTy,value:fixVal,hints:{kind:'regular',height:2n},safety:'safe'});
 const functional=lam(nameFromDotted('x'),Nat,lam(nameFromDotted('ih'),recDom,recursiveFunctional?app(app(bvar(0),bvar(1)),constant(pf)):natLit(0)));
 const wrapper=nameFromDotted(badInner?'Synthetic.Wf2.bad':'Synthetic.Wf2.good'),measure=lam(nameFromDotted('m'),Nat,lam(nameFromDotted('n'),Nat,bvar(1)));
 const value=lam(nameFromDotted('m'),Nat,lam(nameFromDotted('n'),Nat,
  mkAppN(constant(N.WfNatFix),[natLit(0),natLit(0),lam(nameFromDotted('a'),Nat,bvar(2)),functional,bvar(0)])));
 env.add({kind:'definition',name:wrapper,levelParams:[],type:natArrow(Nat,natArrow(Nat,Nat)),value,hints:{kind:'regular',height:3n},safety:'safe'});
 return {wrapper,measure};
}

test('full well-founded primitive recognizer validates fix.go Nat.rec equation',()=>{
 const env=primitiveNatEnv(),{wrapper,measure}=addSyntheticNatWfCompleteScaffold(env);
 inspectNatWellFounded(env,constant(wrapper),measure);
});

test('full well-founded primitive recognizer rejects fuel captured by Nat.rec function',()=>{
 const env=primitiveNatEnv(),{wrapper,measure}=addSyntheticNatWfCompleteScaffold(env,true);
 throws(()=>inspectNatWellFounded(env,constant(wrapper),measure));
});


test('well-founded probe validates recursive equation independently of fixpoint scaffolding',()=>{
 const env=primitiveNatEnv(),{wrapper,measure}=addSyntheticNatWfCompleteScaffold(env),P=inspectNatWellFounded(env,constant(wrapper),measure),tc=new TypeChecker(env);
 probeNatWellFounded(tc,P,[natLit(4),natLit(7)],()=>natLit(0));
 throws(()=>probeNatWellFounded(tc,P,[natLit(4),natLit(7)],()=>natLit(1)));
});

test('well-founded recursive-call probe validates target and decrease proof structurally',()=>{
 const env=primitiveNatEnv(),{wrapper,measure}=addSyntheticNatWfCompleteScaffold(env,false,true),P=inspectNatWellFounded(env,constant(wrapper),measure),tc=new TypeChecker(env);
 // This synthetic pack returns its second argument, so both sides designate 7.
 probeNatWellFoundedRecursiveCall(tc,P,[natLit(4),natLit(7)],[natLit(99),natLit(7)]);
 throws(()=>probeNatWellFoundedRecursiveCall(tc,P,[natLit(4),natLit(7)],[natLit(99),natLit(8)]));
});


function makeBitwiseEquationProbe(bad=false):{env:Environment;tc:TypeChecker;P:any;f:any;n:any;m:any}{
 const env=primitiveNatBoolEnv();addBoolConditionScaffold(env);addNatLeConditionScaffold(env);addNatEqConditionScaffold(env);
 const Nat=constant(N.Nat),Bool=constant(N.Bool),arrow=(a:any,b:any)=>forallE(nameFromDotted('_'),a,b);
 const nat2=arrow(Nat,arrow(Nat,Nat));
 for(const nm of [N.NatAdd,N.NatMod,N.NatDiv])env.add({kind:'axiom',name:nm,levelParams:[],type:nat2});
 const DecPred=nameFromDotted('Synthetic.BitwiseDecrease');
 env.add({kind:'axiom',name:DecPred,levelParams:[],type:arrow(Nat,sort(levelZero))});
 const eqNat=(a:any,b:any)=>mkAppN(constant(N.Eq,[levelSucc(levelZero)]),[Nat,a,b]),not=(p:any)=>app(constant(N.Not),p);
 env.add({kind:'axiom',name:N.NatBitwiseUnaryProof1,levelParams:[],type:forallE(nameFromDotted('n'),Nat,
  forallE(nameFromDotted('m'),Nat,forallE(nameFromDotted('h'),not(eqNat(bvar(1),constant(N.NatZero))),app(constant(DecPred),bvar(2)))))});
 const lctx=new LocalContext(),bool2=arrow(Bool,arrow(Bool,Bool));
 const fid=lctx.fresh('f');lctx.addLocal(fid,nameFromDotted('f'),bool2);const f=fvar(fid);
 const nid=lctx.fresh('n');lctx.addLocal(nid,nameFromDotted('n'),Nat);const n=fvar(nid);
 const mid=lctx.fresh('m');lctx.addLocal(mid,nameFromDotted('m'),Nat);const m=fvar(mid);
 const tc=new TypeChecker(env,lctx);
 const pack=lam(nameFromDotted('n'),Nat,lam(nameFromDotted('_m'),Nat,bvar(1)));
 const domain=lam(nameFromDotted('a'),Nat,forallE(nameFromDotted('y'),Nat,
  forallE(nameFromDotted('_dec'),app(constant(DecPred),bvar(1)),Nat)));
 const aid=lctx.fresh('a');lctx.addLocal(aid,nameFromDotted('a'),Nat);const a=fvar(aid);
 const ihTy=app(domain,a),iid=lctx.fresh('ih');lctx.addLocal(iid,nameFromDotted('ih'),ihTy);const ih=fvar(iid);
 const ttc=new TypeChecker(env,lctx,tc.state,tc.limits);
 const zero=constant(N.NatZero),one=app(constant(N.NatSucc),zero),two=app(constant(N.NatSucc),one),tru=constant(N.BoolTrue),fal=constant(N.BoolFalse);
 const app2=(g:any,x:any,y:any)=>app(app(g,x),y),decEq=(x:any,y:any)=>mkAppN(constant(N.NatDecEq),[x,y]);
 const ite=(A:any,p:any,d:any,t:any,e:any)=>mkAppN(constant(N.Ite,[levelSucc(levelZero)]),[A,p,d,t,e]);
 const eqIte=(A:any,x:any,y:any,t:any,e:any)=>ite(A,eqNat(x,y),decEq(x,y),t,e);
 const boolEq=(x:any)=>mkAppN(constant(N.Eq,[levelSucc(levelZero)]),[Bool,x,tru]);
 const boolIte=(x:any,t:any,e:any)=>ite(Nat,boolEq(x),mkAppN(constant(N.BoolDecEq),[x,tru]),t,e);
 const n2=app2(constant(N.NatDiv),n,two),m2=app2(constant(N.NatDiv),m,two);
 const decide=(x:any,y:any)=>eqIte(Bool,x,y,tru,fal),b1=decide(app2(constant(N.NatMod),n,two),one),b2=decide(app2(constant(N.NatMod),m,two),one);
 const nZero=boolIte(app2(f,fal,tru),m,zero),pN=eqNat(n,zero);
 const falseBranch=lam(nameFromDotted('hNe'),not(pN),(()=>{
   const h=bvar(0),proof=mkAppN(constant(N.NatBitwiseUnaryProof1),[n,m,h]);
   const r=app(app(ih,mkAppN(pack,[n2,m2])),proof),rr=app2(constant(N.NatAdd),r,r);
   const rec=boolIte(app2(f,b1,b2),app2(constant(N.NatAdd),rr,bad?two:one),rr);
   const mZero=boolIte(app2(f,tru,fal),n,zero);
   return eqIte(Nat,m,zero,mZero,rec);
 })());
 const trueBranch=lam(nameFromDotted('_h'),pN,nZero);
 const rhs=mkAppN(constant(N.Dite,[levelSucc(levelZero)]),[Nat,pN,decEq(n,zero),trueBranch,falseBranch]);
 const functional=closeLambda(ttc,[a,ih],rhs);
 const P={functional,pack,domain,measure:lam(nameFromDotted('x'),Nat,bvar(0)),fixGo:N.WfNatFixGo};
 return {env,tc,P,f,n,m};
}

test('Nat.bitwise equation probe checks nested conditions and recursive target',()=>{
 const good=makeBitwiseEquationProbe(false);checkNatEqCondition(good.env);checkBoolCondition(good.env);probeNatBitwiseEquation(good.tc,good.P,good.f,good.n,good.m);
 const bad=makeBitwiseEquationProbe(true);throws(()=>probeNatBitwiseEquation(bad.tc,bad.P,bad.f,bad.n,bad.m));
});

test('reserved primitive names cannot enter through ordinary declaration paths',()=>{
 const env=new Environment(),T=sort(levelSucc(levelZero));
 throws(()=>addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:N.Nat,type:T,ctors:[{name:N.NatZero,type:constant(N.Nat)},{name:N.NatSucc,type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))}]}]}));
 assert(!env.has(N.Nat));
});

test('primitive Nat exact-shape bootstrap synthesizes Nat.rec',()=>{
 const env=primitiveNatEnv();const i=env.get(N.Nat),r=env.get(nameFromDotted('Nat.rec'));
 assert(i.kind==='inductive'&&i.ctors.length===2);assert(r.kind==='recursor'&&r.rules.length===2);
});

test('primitive Nat rejects a malformed constructor shape transactionally',()=>{
 const env=new Environment(),T=sort(levelSucc(levelZero));
 throws(()=>addPrimitiveInductive(env,{levelParams:[],numParams:0,types:[{name:N.Nat,type:T,ctors:[{name:N.NatZero,type:constant(N.Nat)},{name:N.NatSucc,type:constant(N.Nat)}]}]}));
 assert(!env.has(N.Nat));
});

test('ordinary Kernel path rejects Nat.add even when well typed',()=>{
 const env=primitiveNatEnv(),k=new Kernel(env),ty=forallE(nameFromDotted('x'),constant(N.Nat),forallE(nameFromDotted('y'),constant(N.Nat),constant(N.Nat)));
 throws(()=>k.addDefinition({kind:'definition',name:N.NatAdd,levelParams:[],type:ty,value:lam(nameFromDotted('x'),constant(N.Nat),lam(nameFromDotted('y'),constant(N.Nat),bvar(1))),hints:{kind:'regular',height:1n},safety:'safe'}));
 assert(!env.has(N.NatAdd));
});

test('primitive Nat.add rejects malicious well-typed semantics',()=>{
 const env=primitiveNatEnv(),ty=forallE(nameFromDotted('x'),constant(N.Nat),forallE(nameFromDotted('y'),constant(N.Nat),constant(N.Nat)));
 const bad=lam(nameFromDotted('x'),constant(N.Nat),lam(nameFromDotted('y'),constant(N.Nat),bvar(1)));
 throws(()=>addPrimitiveDefinition(env,{kind:'definition',name:N.NatAdd,levelParams:[],type:ty,value:bad,hints:{kind:'regular',height:1n},safety:'safe'}));
 assert(!env.has(N.NatAdd));
});

test('primitive Nat.add recognizes canonical Nat.rec semantics',()=>{
 const env=primitiveNatEnv(),ty=forallE(nameFromDotted('x'),constant(N.Nat),forallE(nameFromDotted('y'),constant(N.Nat),constant(N.Nat)));
 addPrimitiveDefinition(env,{kind:'definition',name:N.NatAdd,levelParams:[],type:ty,value:canonicalNatAddValue(),hints:{kind:'regular',height:1n},safety:'safe'});
 assert(env.has(N.NatAdd));const tc=new TypeChecker(env);eqExpr(tc.whnf(app(app(constant(N.NatAdd),natLit(23)),natLit(19))),natLit(42));
});


test('primitive Nat.land/lor/xor recognize exact Nat.bitwise operator laws',()=>{
 const env=primitiveNatBoolEnv();addBitwiseSignature(env);
 const ty=forallE(nameFromDotted('x'),constant(N.Nat),forallE(nameFromDotted('y'),constant(N.Nat),constant(N.Nat)));
 addPrimitiveDefinition(env,{kind:'definition',name:N.NatLand,levelParams:[],type:ty,value:app(constant(N.NatBitwise),boolAndOp()),hints:{kind:'regular',height:1n},safety:'safe'});
 addPrimitiveDefinition(env,{kind:'definition',name:N.NatLor,levelParams:[],type:ty,value:app(constant(N.NatBitwise),boolOrOp()),hints:{kind:'regular',height:1n},safety:'safe'});
 addPrimitiveDefinition(env,{kind:'definition',name:N.NatXor,levelParams:[],type:ty,value:app(constant(N.NatBitwise),boolXorOp()),hints:{kind:'regular',height:1n},safety:'safe'});
 assert(env.has(N.NatLand)&&env.has(N.NatLor)&&env.has(N.NatXor));
 const tc=new TypeChecker(env);eqExpr(tc.whnf(app(app(constant(N.NatLand),natLit(6)),natLit(3))),natLit(2));eqExpr(tc.whnf(app(app(constant(N.NatLor),natLit(6)),natLit(3))),natLit(7));eqExpr(tc.whnf(app(app(constant(N.NatXor),natLit(6)),natLit(3))),natLit(5));
});

test('primitive Nat.land rejects a malicious Nat.bitwise operator',()=>{
 const env=primitiveNatBoolEnv();addBitwiseSignature(env);const ty=forallE(nameFromDotted('x'),constant(N.Nat),forallE(nameFromDotted('y'),constant(N.Nat),constant(N.Nat)));
 const bad=lam(nameFromDotted('a'),constant(N.Bool),lam(nameFromDotted('b'),constant(N.Bool),bvar(1)));
 throws(()=>addPrimitiveDefinition(env,{kind:'definition',name:N.NatLand,levelParams:[],type:ty,value:app(constant(N.NatBitwise),bad),hints:{kind:'regular',height:1n},safety:'safe'}));assert(!env.has(N.NatLand));
});

test('primitive Char.ofNat checks the exact type and Char prerequisite',()=>{
 const env=primitiveNatEnv(),char0=nameFromDotted('char0');env.add({kind:'axiom',name:N.Char,levelParams:[],type:sort(levelSucc(levelZero))});env.add({kind:'axiom',name:char0,levelParams:[],type:constant(N.Char)});
 const ty=forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Char)),value=lam(nameFromDotted('n'),constant(N.Nat),constant(char0));
 addPrimitiveDefinition(env,{kind:'definition',name:N.CharOfNat,levelParams:[],type:ty,value,hints:{kind:'regular',height:1n},safety:'safe'});assert(env.has(N.CharOfNat));
});

test('primitive String.ofList validates List Char constructor prerequisites',()=>{
 const env=new Environment(),one=levelSucc(levelZero),uN=nameFromDotted('u'),u=levelParam(uN),TU=sort(levelSucc(u));
 env.add({kind:'axiom',name:N.Char,levelParams:[],type:sort(one)});env.add({kind:'axiom',name:N.String,levelParams:[],type:sort(one)});
 const listTy=forallE(nameFromDotted('α'),TU,TU,'implicit');env.add({kind:'axiom',name:N.List,levelParams:[uN],type:listTy});
 const listU=(x:any)=>app(constant(N.List,[u]),x);
 env.add({kind:'axiom',name:N.ListNil,levelParams:[uN],type:forallE(nameFromDotted('α'),TU,listU(bvar(0)),'implicit')});
 env.add({kind:'axiom',name:N.ListCons,levelParams:[uN],type:forallE(nameFromDotted('α'),TU,forallE(nameFromDotted('a'),bvar(0),forallE(nameFromDotted('as'),listU(bvar(1)),listU(bvar(2)))),'implicit')});
 const listChar=app(constant(N.List,[levelZero]),constant(N.Char)),empty=nameFromDotted('emptyString');env.add({kind:'axiom',name:empty,levelParams:[],type:constant(N.String)});
 const ty=forallE(nameFromDotted('xs'),listChar,constant(N.String)),value=lam(nameFromDotted('xs'),listChar,constant(empty));
 addPrimitiveDefinition(env,{kind:'definition',name:N.StringOfList,levelParams:[],type:ty,value,hints:{kind:'regular',height:1n},safety:'safe'});assert(env.has(N.StringOfList));
});





test('mutual partial definitions are checked together and may refer to block members',()=>{
 const env=baseEnv(),k=new Kernel(env),a=nameFromDotted('partialA'),b=nameFromDotted('partialB'),ty=constant(N.Nat);
 k.addMutualDefinitions([
  {kind:'definition',name:a,levelParams:[],type:ty,value:constant(b),hints:{kind:'regular',height:1n},safety:'partial'},
  {kind:'definition',name:b,levelParams:[],type:ty,value:constant(a),hints:{kind:'regular',height:1n},safety:'partial'}
 ]);
 assert(env.has(a)&&env.has(b));
});

test('mutual definitions reject safe, mixed, duplicate, and non-transactional blocks',()=>{
 const ty=constant(N.Nat),mk=(name:string,safety:'safe'|'unsafe'|'partial',value:any=natLit(0))=>({kind:'definition' as const,name:nameFromDotted(name),levelParams:[],type:ty,value,hints:{kind:'regular' as const,height:1n},safety});
 {const env=baseEnv(),k=new Kernel(env);throws(()=>k.addMutualDefinitions([mk('safeMutual','safe')]));assert(!env.has(nameFromDotted('safeMutual')));}
 {const env=baseEnv(),k=new Kernel(env);throws(()=>k.addMutualDefinitions([mk('mixedA','partial'),mk('mixedB','unsafe')]));assert(!env.has(nameFromDotted('mixedA'))&&!env.has(nameFromDotted('mixedB')));}
 {const env=baseEnv(),k=new Kernel(env),d=mk('dupMutual','partial');throws(()=>k.addMutualDefinitions([d,d]));assert(!env.has(d.name));}
 {const env=baseEnv(),k=new Kernel(env),a=mk('txnA','partial'),bad=mk('txnB','partial',constant(N.BoolTrue));throws(()=>k.addMutualDefinitions([a,bad]));assert(!env.has(a.name)&&!env.has(bad.name),'failed mutual block must commit nothing');}
});

test('declaration rejects undefined universe parameters and accepts declared ones',()=>{
 const env=baseEnv(),k=new Kernel(env),uN=nameFromDotted('u'),u=levelParam(uN);
 throws(()=>k.addAxiom({kind:'axiom',name:nameFromDotted('BadU'),levelParams:[],type:sort(u)}));
 k.addAxiom({kind:'axiom',name:nameFromDotted('GoodU'),levelParams:[uN],type:sort(u)});assert(env.has(nameFromDotted('GoodU')));
});

test('declaration rejects expression and universe metavariables transactionally',()=>{
 const env=baseEnv(),k=new Kernel(env),em=nameFromDotted('BadExprMVar'),um=nameFromDotted('BadLevelMVar');
 throws(()=>k.addAxiom({kind:'axiom',name:em,levelParams:[],type:{kind:'mvar',id:'?m.1'}}));
 throws(()=>k.addAxiom({kind:'axiom',name:um,levelParams:[],type:sort(levelMVar(nameFromDotted('u?')))}));
 assert(!env.has(em)&&!env.has(um),'metavariable rejection must commit nothing');
});

test('mutual inductive duplicate names reject transactionally',()=>{
 const env=baseEnv(),I=nameFromDotted('DupInd'),Mk=nameFromDotted('DupInd.mk'),T=sort(levelSucc(levelZero));
 throws(()=>addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[
  {name:I,type:T,ctors:[{name:Mk,type:constant(I)}]},
  {name:I,type:T,ctors:[{name:nameFromDotted('DupInd.mk2'),type:constant(I)}]}
 ]}));
 assert(!env.has(I)&&!env.has(Mk)&&!env.has(nameFromDotted('DupInd.mk2')),'duplicate mutual inductive rejection must commit nothing');
});

test('theorem admission requires a proposition',()=>{
 const env=baseEnv(),k=new Kernel(env);throws(()=>k.addTheorem({kind:'theorem',name:nameFromDotted('notATheorem'),levelParams:[],type:constant(N.Nat),value:natLit(0)}));
});

test('safe definition cannot use unsafe declaration but unsafe definition can',()=>{
 const env=baseEnv(),k=new Kernel(env),u=nameFromDotted('unsafeNat');k.addAxiom({kind:'axiom',name:u,levelParams:[],type:constant(N.Nat),isUnsafe:true});
 const safe=nameFromDotted('safeUsesUnsafe');throws(()=>k.addDefinition({kind:'definition',name:safe,levelParams:[],type:constant(N.Nat),value:constant(u),hints:{kind:'regular',height:1n},safety:'safe'}));assert(!env.has(safe));
 const un=nameFromDotted('unsafeUsesUnsafe');k.addDefinition({kind:'definition',name:un,levelParams:[],type:constant(N.Nat),value:constant(u),hints:{kind:'regular',height:1n},safety:'unsafe'});assert(env.has(un));
});

test('safe definition cannot contain partial definition',()=>{
 const env=baseEnv(),k=new Kernel(env),pname=nameFromDotted('partialNat');k.addDefinition({kind:'definition',name:pname,levelParams:[],type:constant(N.Nat),value:natLit(0),hints:{kind:'regular',height:1n},safety:'partial'});
 const sname=nameFromDotted('safeFromPartial');throws(()=>k.addDefinition({kind:'definition',name:sname,levelParams:[],type:constant(N.Nat),value:constant(pname),hints:{kind:'regular',height:1n},safety:'safe'}));assert(!env.has(sname));
});




import { parseExactJson } from '../src/integration/exact-json.js';
import { Lean4ExportReplay } from '../src/integration/lean4export.js';
import { lean434RealProbe } from './fixtures/lean434-real-probe.js';

test('exact JSON parser preserves integers beyond JavaScript safe range',()=>{
 const v=parseExactJson('{"n":9007199254740993123456789}');assert(typeof v==='object'&&v!==null&&!Array.isArray(v));assert((v as any).n===9007199254740993123456789n);
});

test('lean4export replay admits a version-pinned axiom stream',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"test","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"A"}}',
  '{"il":1,"succ":0}',
  '{"ie":0,"sort":1}',
  '{"axiom":{"name":1,"levelParams":[],"type":0,"isUnsafe":false}}'
 ].join('\n');
 const r=new Lean4ExportReplay(),st=r.replay(nd);assert(st.declarations===1&&r.env.has(nameFromDotted('A')));assert(st.names===1&&st.levels===1&&st.expressions===1);
});



test('lean4export incremental line replay matches bulk replay',()=>{
 const lines=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"test","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"A"}}',
  '{"il":1,"succ":0}',
  '{"ie":0,"sort":1}',
  '{"axiom":{"name":1,"levelParams":[],"type":0,"isUnsafe":false}}'
 ];
 const bulk=new Lean4ExportReplay(),a=bulk.replay(lines.join('\n'));
 const streaming=new Lean4ExportReplay();for(const line of lines)streaming.replayLine(line);const b=streaming.finish();
 assert(JSON.stringify(a)===JSON.stringify(b));
 assert(streaming.env.has(nameFromDotted('A')));
});

test('real Lean 4.34 olean probe replays polymorphic inductives and definitions end to end',()=>{
 const r=new Lean4ExportReplay(),st=r.replay(lean434RealProbe);
 assert(st.declarations===8&&st.expressions===180&&r.env.entries().length===17);
 for(const n of ['ReplayProbe.A','ReplayProbe.id','ReplayProbe.MiniNat','ReplayProbe.MiniNat.zero','ReplayProbe.MiniNat.succ','ReplayProbe.MiniNat.rec','ReplayProbe.one','ReplayProbe.MiniList','ReplayProbe.MiniList.nil','ReplayProbe.MiniList.cons','ReplayProbe.MiniList.rec','ReplayProbe.singleton','ReplayProbe.MiniVec','ReplayProbe.MiniVec.nil','ReplayProbe.MiniVec.cons','ReplayProbe.MiniVec.rec','ReplayProbe.vecOne'])assert(r.env.has(nameFromDotted(n)),`missing ${n}`);
 const ci=r.env.get(nameFromDotted('ReplayProbe.singleton'));assert(ci.kind==='definition');
});

test('Lean 4.34 recursor synthesis performs strict implicit inference',()=>{
 const r=new Lean4ExportReplay();r.replay(lean434RealProbe);
 const rec=r.env.get(nameFromDotted('ReplayProbe.MiniNat.rec'));assert(rec.kind==='recursor'&&rec.type.kind==='forall');
 assert(rec.type.binderInfo==='implicit','recursor motive must be inferred implicit');
});


test('Lean 4.34 recursor fresh elimination universe uses appendIndexAfter naming',()=>{
 const r=new Lean4ExportReplay();r.replay(lean434RealProbe);
 const rec=r.env.get(nameFromDotted('ReplayProbe.MiniList.rec'));assert(rec.kind==='recursor'&&rec.levelParams.length===2&&rec.type.kind==='forall');
 assert(nameToString(rec.levelParams[0]!)==='u_1','fresh elimination universe must be u_1');
 assert(rec.type.binderInfo==='implicit','parameter α must become implicit in recursor type');
});


test('real Lean 4.34 indexed recursor metadata matches exactly',()=>{
 const r=new Lean4ExportReplay();r.replay(lean434RealProbe);
 const ind=r.env.get(nameFromDotted('ReplayProbe.MiniVec')),rec=r.env.get(nameFromDotted('ReplayProbe.MiniVec.rec'));
 assert(ind.kind==='inductive'&&ind.numParams===1&&ind.numIndices===1&&ind.isRec);
 assert(rec.kind==='recursor'&&rec.numParams===1&&rec.numIndices===1&&rec.rules.length===2);
});

test('lean4export treats safe DefinitionVal.all as informational, not a mutual kernel block',()=>{
 const meta='{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"test","version":"4.34.0"},"format":{"version":"3.1.0"}}}';
 const pre=[
  meta,
  '{"in":1,"str":{"pre":0,"str":"SafeAllA"}}',
  '{"in":2,"str":{"pre":0,"str":"SafeAllB"}}',
  '{"il":1,"succ":0}',
  '{"ie":0,"sort":1}',
  '{"ie":1,"sort":0}',
  '{"ie":2,"const":{"name":2,"us":[]}}'
 ];
 const a='{"def":{"name":1,"levelParams":[],"type":0,"value":2,"hints":{"regular":1},"safety":"safe","all":[2]}}';
 const b='{"def":{"name":2,"levelParams":[],"type":0,"value":1,"hints":{"regular":1},"safety":"safe","all":[]}}';
 throws(()=>new Lean4ExportReplay().replay([...pre,a,b].join('\n')),'safe all-list must not defer A until B arrives');
 const r=new Lean4ExportReplay();r.replay([...pre,b,a].join('\n'));
 assert(r.env.has(nameFromDotted('SafeAllA'))&&r.env.has(nameFromDotted('SafeAllB')),'dependency-first safe definitions must replay even when informational all metadata omits self or is empty');
});

test('lean4export reconstructs partial mutual definition blocks from all metadata',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"test","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"A"}}','{"in":2,"str":{"pre":0,"str":"B"}}',
  '{"ie":0,"sort":0}','{"ie":1,"const":{"name":1,"us":[]}}','{"ie":2,"const":{"name":2,"us":[]}}',
  '{"def":{"name":2,"levelParams":[],"type":0,"value":1,"hints":{"regular":1},"safety":"partial","all":[1,2]}}',
  '{"def":{"name":1,"levelParams":[],"type":0,"value":2,"hints":{"regular":1},"safety":"partial","all":[1,2]}}'
 ].join('\n');
 const r=new Lean4ExportReplay(),st=r.replay(nd);assert(st.declarations===2&&r.env.has(nameFromDotted('A'))&&r.env.has(nameFromDotted('B')));
});

test('lean4export rejects an incomplete mutual definition group',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"test","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"A"}}','{"in":2,"str":{"pre":0,"str":"B"}}',
  '{"ie":0,"sort":0}','{"ie":1,"const":{"name":1,"us":[]}}',
  '{"def":{"name":1,"levelParams":[],"type":0,"value":1,"hints":{"regular":1},"safety":"partial","all":[1,2]}}'
 ].join('\n');throws(()=>new Lean4ExportReplay().replay(nd));
});

test('kernel metadata equivalence ignores binder display names but retains annotations',()=>{
 const a=forallE(nameFromDotted('a'),sort(levelZero),bvar(0),'default');
 const renamed=forallE(nameFromDotted('x'),sort(levelZero),bvar(0),'default');
 const implicit=forallE(nameFromDotted('x'),sort(levelZero),bvar(0),'implicit');
 assert(exprKernelMetadataEq(a,renamed),'binder display names are non-semantic');
 assert(!exprKernelMetadataEq(a,implicit),'binder annotations must remain significant');
});

test('lean4export replay accepts sparse and out-of-order intern indices',()=>{
 const meta='{"meta":{"exporter":{"name":"handcrafted","version":"0.1.0"},"lean":{"githash":"test","version":"4.34.0"},"format":{"version":"3.1.0"}}}';
 const sparse=[meta,'{"in":2,"str":{"pre":0,"str":"foo"}}','{"ie":4,"sort":0}','{"axiom":{"isUnsafe":false,"levelParams":[],"name":2,"type":4}}'].join('\n');
 const a=new Lean4ExportReplay();a.replay(sparse);assert(a.env.entries().length===1);
 const outOfOrder=[meta,'{"in":1,"str":{"pre":0,"str":"foo"}}','{"il":2,"succ":0}','{"il":1,"succ":2}','{"ie":0,"sort":1}','{"axiom":{"isUnsafe":false,"levelParams":[],"name":1,"type":0}}'].join('\n');
 const b=new Lean4ExportReplay();b.replay(outOfOrder);assert(b.env.entries().length===1);
 const duplicate=[meta,'{"in":2,"str":{"pre":0,"str":"foo"}}','{"in":2,"str":{"pre":0,"str":"bar"}}'].join('\n');
 throws(()=>new Lean4ExportReplay().replay(duplicate));
});

test('lean4export replay rejects version drift before declarations',()=>{
 const nd='{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"test","version":"4.33.0"},"format":{"version":"3.1.0"}}}';throws(()=>new Lean4ExportReplay().replay(nd));
});

console.log(`# pass ${pass}`);console.log(`# fail ${fail}`);if(fail)throw new Error(`${fail} tests failed`);
