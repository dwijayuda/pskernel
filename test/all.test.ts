import { Environment } from '../src/core/environment.js';
import { app, bvar, constant, consumeTypeAnnotations, exprEq, exprKernelMetadataEq,exprLeanEq, exprKey, forallE, fvar, hasFVar, hasLooseBVar, hasMVar, inferImplicit, instantiateExprLevels, lam, mkAppN, natLit, sort, strLit } from '../src/core/expr.js';
import { instantiateLevel, levelEqStructural, levelEquivalent, levelHasMVar, levelIMaxRaw, levelLe, levelMaxRaw, levelMVar, levelParam, levelParamNames, levelSucc, levelZero, mkIMax, mkMax, normalizesToZero } from '../src/core/level.js';
import { nameAppend, nameCmp, nameEq, nameFromDotted, nameIsPrefixOf, nameKey, nameReplacePrefix, nameToString, strName } from '../src/core/name.js';
import { LocalContext } from '../src/core/local-context.js';
import { abstractFVar, instantiate, lift } from '../src/core/instantiate.js';
import { Kernel } from '../src/kernel/kernel.js';
import { N } from '../src/kernel/names.js';
import { TypeChecker } from '../src/kernel/type-checker.js';
import { NativeEvaluator } from '../src/kernel/reduction/native.js';
import { asNat } from '../src/kernel/reduction/nat.js';
import { KernelState } from '../src/kernel/state.js';
import { addOrdinaryInductive, checkNoReservedNestedAux, checkUniformInductiveOccurrences, validateInstalledRecursorsByReduction } from '../src/kernel/inductive/ordinary.js';
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

test('Name numeric and string components remain distinct',()=>{const prefix=nameFromDotted('X'),a={kind:'str',prefix,value:'1'} as const,b={kind:'num',prefix,value:1n} as const;assert(JSON.stringify(a,(_k,v)=>typeof v==='bigint'?v.toString():v)!==JSON.stringify(b,(_k,v)=>typeof v==='bigint'?v.toString():v));assert(nameCmp(b,a)<0&&nameCmp(a,b)>0,'Lean Name order places numeral components before string components');const bmp={kind:'str',prefix,value:'\uE000'} as const,astral={kind:'str',prefix,value:'\u{10000}'} as const;assert(nameCmp(bmp,astral)<0&&nameCmp(astral,bmp)>0,'Lean Name string order follows UTF-8/scalar order rather than JavaScript UTF-16 code-unit order');const nested=nameFromDotted('_nested'),singleDot=strName(nameFromDotted(''),'_nested.fake');assert(nameIsPrefixOf(nested,nameFromDotted('_nested.real'))&&!nameIsPrefixOf(nested,singleDot),'Lean Name prefix checks are structural, not rendered-string prefixes');assert(nameEq(nameAppend(nested,nameFromDotted('Pkg.Box')),nameFromDotted('_nested.Pkg.Box')),'Lean Name concatenation preserves suffix components');});
test('deep Lean Name operations avoid the JavaScript call stack',()=>{
 let a:any=nameFromDotted(''),b:any=nameFromDotted(''),prefix:any=null;
 for(let i=0;i<12000;i++){a={kind:'str',prefix:a,value:'x'};b={kind:'str',prefix:b,value:'x'};if(i===5999)prefix=a;}
 assert(nameEq(a,b),'deep structural Name equality must be stack-safe');
 assert(nameCmp(a,b)===0,'deep Name comparison must be stack-safe');
 assert(nameKey(a).startsWith('a/s:1:x'),'deep Name key generation must be stack-safe');
 const r=nameReplacePrefix(a,prefix,nameFromDotted('R'));
 assert(r!==null&&nameToString(r).startsWith('R.'),'deep Name prefix replacement/component extraction must be stack-safe');
});
test('kernel admission freezes caller-owned declarations and expression DAGs',()=>{
 const env=baseEnv(),k=new Kernel(env),D=nameFromDotted('Immutable.def');
 const value:any=natLit(0),info:any={kind:'definition',name:D,levelParams:[],type:constant(N.Nat),value,hints:{kind:'regular',height:1n},safety:'safe'};
 k.addDefinition(info);
 assert(Object.isFrozen(info)&&Object.isFrozen(info.type)&&Object.isFrozen(info.value),'admitted declaration graph must be runtime immutable');
 assert(Reflect.set(info,'value',strLit('mutated'))===false,'caller must not be able to replace an admitted definition body');
 assert(Reflect.set(value.literal,'value',1n)===false,'caller must not be able to mutate an admitted expression leaf');
 const stored=env.get(D);assert(stored.kind==='definition'&&exprEq(stored.value,natLit(0)),'environment must retain the checked value after hostile mutation attempts');
});

test('kernel freezes declarations before native-evaluator callbacks can mutate them',()=>{
 const env=baseEnv(),Reduce=N.LeanReduceNat,C=nameFromDotted('Immutable.Native.C'),F=nameFromDotted('Immutable.Native.F'),X=nameFromDotted('Immutable.Native.X'),D=nameFromDotted('Immutable.Native.D');
 env.add({kind:'axiom',name:Reduce,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))});
 env.add({kind:'axiom',name:C,levelParams:[],type:constant(N.Nat)});
 env.add({kind:'axiom',name:F,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),sort(levelZero))});
 const reduced=app(constant(Reduce),constant(C));
 env.add({kind:'axiom',name:X,levelParams:[],type:app(constant(F),reduced)});
 const info:any={kind:'definition',name:D,levelParams:[],type:app(constant(F),natLit(0)),value:constant(X),hints:{kind:'regular',height:1n},safety:'safe'};
 let mutationResult:boolean|undefined;
 const native:NativeEvaluator={evaluate(_env,request){
   if(request.kind!=='nat'||!nameEq(request.constant,C))return null;
   mutationResult=Reflect.set(info,'value',strLit('hostile mutation'));
   return {kind:'nat',value:0n};
 }};
 new Kernel(env,native).addDefinition(info);
 assert(mutationResult===false,'declaration must already be frozen when native evaluation runs');
 const stored=env.get(D);assert(stored.kind==='definition'&&stored.value.kind==='const'&&nameEq(stored.value.name,X),'native callback must not alter the admitted body');
});

test('raw Environment storage deep-freezes nested kernel values',()=>{
 const env=new Environment(),A=nameFromDotted('Immutable.axiom'),type:any=sort(levelZero),info:any={kind:'axiom',name:A,levelParams:[],type};
 env.add(info);
 assert(Object.isFrozen(info)&&Object.isFrozen(type)&&Object.isFrozen(type.level));
 assert(Reflect.set(type,'level',levelSucc(levelZero))===false);
 assert(exprEq(env.get(A).type,sort(levelZero)));
});

test('Expr.Data caches and TypeChecker inputs are runtime immutable',()=>{
 const standalone:any=app(constant(N.Nat),constant(N.Nat));
 assert(!hasLooseBVar(standalone));
 assert(Object.isFrozen(standalone)&&Object.isFrozen(standalone.fn)&&Object.isFrozen(standalone.arg),'first Expr.Data cache must freeze the expression DAG');
 assert(Reflect.set(standalone,'fn',constant(N.String))===false,'cached expression identity must not become stale through mutation');

 const env=baseEnv(),A=nameFromDotted('Immutable.TypeChecker.A'),B=nameFromDotted('Immutable.TypeChecker.B');
 env.add({kind:'axiom',name:A,levelParams:[],type:constant(N.Nat)});
 env.add({kind:'axiom',name:B,levelParams:[],type:sort(levelZero)});
 const query:any=constant(A),localType:any=constant(N.Nat),lctx=new LocalContext();
 lctx.addLocal('immutable@0',nameFromDotted('x'),localType);
 const limits:any={maxRecDepth:512,maxNatBytes:1024n},allowed:any=[nameFromDotted('u')];
 const tc=new TypeChecker(env,lctx,undefined,limits,'safe',allowed);
 assert(exprEq(tc.infer(query),constant(N.Nat)),'initial cached inference mismatch');
 assert(Object.isFrozen(query)&&Reflect.set(query,'name',B)===false,'checker query must be immutable once cached');
 assert(Object.isFrozen(limits)&&Reflect.set(limits,'maxRecDepth',0)===false,'checker limits must not change after cache configuration is bound');
 assert(Object.isFrozen(allowed)&&Reflect.set(allowed,0,nameFromDotted('v'))===false,'allowed universe parameters must not change after cache configuration is bound');
 const local:any=lctx.get('immutable@0');
 assert(local&&Object.isFrozen(local)&&Object.isFrozen(localType)&&Reflect.set(localType,'name',N.String)===false,'shared local declarations/types must be immutable after checker construction');
});

test('Lean Expr equality memoizes repeated shared DAG pairs',()=>{
 let a:any=constant(N.Nat),b:any=constant(N.Nat);
 // Each level doubles the number of tree paths while retaining one shared child.
 // Lean 4.34 expr_eq_fn memoizes shared pointer pairs, so this remains linear in
 // DAG size instead of expanding all 2^28 paths.
 for(let i=0;i<28;i++){a=app(a,a);b=app(b,b);}
 assert(exprLeanEq(a,b),'shared structurally equal expression DAGs must compare successfully');
});
test('Lean replacement primitives preserve shared DAG structure and cached loose-bvar skips',()=>{
 let open:any=bvar(0),closed:any=constant(N.Nat);
 for(let i=0;i<24;i++){open=app(open,open);closed=app(closed,closed);}
 assert(hasLooseBVar(open)&&!hasLooseBVar(closed));
 const value=constant(N.Nat);
 const inst=instantiate(open,[value]);
 const lifted=lift(open,1,0);
 let a:any=inst,b:any=lifted;
 for(let i=0;i<24;i++){
   assert(a.kind==='app'&&a.fn===a.arg,'instantiate must preserve sharing for repeated source nodes');
   assert(b.kind==='app'&&b.fn===b.arg,'lift must preserve sharing for repeated source nodes');
   a=a.fn;b=b.fn;
 }
 assert(exprEq(a,value),'instantiate shared leaf result mismatch');
 assert(b.kind==='bvar'&&b.index===1,'lift shared leaf result mismatch');
 // Lean Expr.Data.looseBVarRange lets this return at the root; without the
 // cached range a tree walk would expand 2^24 closed paths.
 assert(instantiate(closed,[value])===closed,'closed shared DAG must be skipped by cached loose-bvar range');
});

test('Lean private names preserve numeric private-index components',()=>{assert(!exprEq(constant(N.NatBitwiseUnaryProof1),constant(nameFromDotted('_private.Init.Data.Nat.Bitwise.Basic.0.Nat.bitwise._unary._proof_1'))));});
test('LocalContext freshness never collides with reconstructed local IDs',()=>{const l=new LocalContext();l.addLocal('a@1',nameFromDotted('a'),sort(levelZero));assert(l.fresh('a')==='a@0');assert(l.fresh('a')==='a@2');});
test('deep structural traversals avoid the JavaScript call stack',()=>{
 let e:any=bvar(0);
 for(let i=0;i<12000;i++)e=lam(nameFromDotted('x'),constant(N.Nat),e);
 assert(!hasMVar(e));assert(!hasFVar(e));assert(!hasLooseBVar(e));
 const eClone=lift(e,0,0);assert(eClone===e,'zero lift must preserve Lean node identity');assert(exprEq(e,eClone),'deep strong expression equality must be stack-safe');assert(exprKernelMetadataEq(e,eClone),'deep generated-metadata equality must be stack-safe');
 const deepKey=exprKey(e);assert(deepKey.startsWith('L(')&&deepKey.endsWith('b0'+')'.repeat(12000)),'deep nested-inductive expression keys must be stack-safe');
 const lifted=lift(e,1,0);
 const inst=instantiate(lifted,[natLit(0)]);
 assert(lifted===e&&inst===e,'lift/instantiate must reuse a closed expression when no loose bvar changes');
 assert(abstractFVar(e,'absent@0')===e,'abstractFVar reconstruction must reuse an unchanged closed tree');

 const id='deep@0';let withFVar:any=fvar(id);
 for(let i=0;i<12000;i++)withFVar=lam(nameFromDotted('x'),constant(N.Nat),withFVar);
 assert(hasFVar(withFVar),'deep free-variable scan must find the leaf without recursion overflow');
 const tcScan:any=new TypeChecker(baseEnv());assert(tcScan.containsFVar(withFVar,id),'checker-specific deep free-variable scan must be stack-safe');assert(!tcScan.containsFVar(withFVar,'other@0'));
 const abstracted=abstractFVar(withFVar,id);
 assert(abstracted.kind==='lam'&&!hasFVar(abstracted),'deep abstraction must be stack-safe and close the free variable');

 const u=nameFromDotted('deep.level');let withLevel:any=sort(levelParam(u));
 for(let i=0;i<12000;i++)withLevel=lam(nameFromDotted('x'),constant(N.Nat),withLevel);
 const levelInst=instantiateExprLevels(withLevel,[u],[levelZero]);
 assert(levelInst.kind==='lam','deep expression-level universe instantiation must be stack-safe');

 const deepDecl:any={levelParams:[],numParams:0,types:[{name:nameFromDotted('DeepScan'),type:sort(levelZero),ctors:[{name:nameFromDotted('DeepScan.mk'),type:e}]}]};
 checkNoReservedNestedAux(deepDecl);checkUniformInductiveOccurrences(deepDecl);

 let annotated:any=constant(N.Nat),outParam=constant(nameFromDotted('outParam'));
 for(let i=0;i<12000;i++)annotated=app(outParam,annotated);
 assert(exprEq(consumeTypeAnnotations(annotated),constant(N.Nat)),'deep leading type annotations must be consumed without recursion overflow');

 let deepPi:any=constant(N.Nat);
 for(let i=0;i<2048;i++)deepPi=forallE(nameFromDotted('x'),constant(N.Nat),deepPi);
 const inferredPi=inferImplicit(deepPi,true,2048);
 assert(inferredPi===deepPi,'recursor implicit inference reuses an unchanged binder spine like Lean update_binding');
});
test('universe metavariables remain distinct symbolic atoms',()=>{
 const n=nameFromDotted('u'),u=levelMVar(n),v=levelMVar(nameFromDotted('v')),p=levelParam(n);
 assert(levelEquivalent(u,u),'a universe metavariable is equivalent to itself');
 assert(!levelEquivalent(u,v),'distinct universe metavariables must not collapse');
 assert(!levelEquivalent(u,p),'a metavariable and parameter with the same Name remain distinct kinds');
 assert(levelEquivalent(mkMax(u,v),mkMax(v,u)),'max remains commutative with universe metavariables');
});

test('mkMax matches Lean structural absorption shortcuts',()=>{
 const u=levelParam(nameFromDotted('absorb.u')),v=levelParam(nameFromDotted('absorb.v'));
 const uv=mkMax(u,v);
 assert(levelEqStructural(mkMax(u,uv),uv),'max u (max u v) must return the existing rhs node shape');
 assert(levelEqStructural(mkMax(uv,u),uv),'max (max u v) u must return the existing lhs node shape');
});

test('deep structural universe equality is stack-safe',()=>{
 let a:any=levelZero,b:any=levelZero;
 for(let i=0;i<20000;i++){a=levelSucc(a);b=levelSucc(b);}
 assert(levelEqStructural(a,b),'deep structural universe equality must not overflow the JavaScript stack');
 assert(levelEquivalent(a,b),'deep universe normalization/equivalence must not overflow the JavaScript stack');
 const deepLevelExprKey=exprKey(sort(a));
 assert(deepLevelExprKey.startsWith('Ss(')&&deepLevelExprKey.endsWith(')'.repeat(20000)),'expression keys must encode deep universe levels without recursive JSON serialization');

 const uN=nameFromDotted('deep.u');let p:any=levelParam(uN),m:any=levelMVar(nameFromDotted('deep.m'));
 for(let i=0;i<20000;i++){p=levelSucc(p);m=levelSucc(m);}
 assert(levelParamNames(p).some(n=>nameToString(n)==='deep.u'),'deep level parameter scan must reach the leaf');
 assert(!levelHasMVar(p)&&levelHasMVar(m),'deep universe metavariable scan must be stack-safe');
 assert(!normalizesToZero(p),'successor towers cannot normalize to zero');
 assert(levelEqStructural(instantiateLevel(p,[uN],[levelZero]),a),'deep universe instantiation must be stack-safe');

 const rawMax=levelMaxRaw(levelZero,levelZero),rawIMax=levelIMaxRaw(levelZero,levelZero);
 assert(instantiateLevel(rawMax,[],[])===rawMax,'empty universe substitution preserves raw max identity instead of simplifying it');
 assert(instantiateLevel(rawIMax,[nameFromDotted('unused')],[levelZero])===rawIMax,'unmatched universe substitution preserves raw imax identity instead of simplifying it');
 const rawExpr=sort(rawMax);
 assert(instantiateExprLevels(rawExpr,[],[])===rawExpr,'empty expression-level universe substitution preserves expression identity');
 const untouched=lam(nameFromDotted('x'),sort(rawMax),constant(N.Nat));
 assert(instantiateExprLevels(untouched,[nameFromDotted('unused')],[levelZero])===untouched,'unmatched expression-level universe substitution preserves the original tree');

 const st=new KernelState();st.infer.set(sort(a),constant(N.Nat));
 assert(st.infer.has(sort(b)),'structural expression caches must compare deep universe levels without recursion overflow');
});

test('universe max commutative semantically',()=>{const u=levelParam(nameFromDotted('u')),v=levelParam(nameFromDotted('v'));assert(levelEquivalent(mkMax(u,v),mkMax(v,u)));});
test('imax u 0 = 0',()=>{const u=levelParam(nameFromDotted('u'));assert(levelEquivalent(mkIMax(u,levelZero),levelZero));});
test('imax u (v+1) = max u (v+1)',()=>{const u=levelParam(nameFromDotted('u')),v=levelSucc(levelParam(nameFromDotted('v')));assert(levelEquivalent(mkIMax(u,v),mkMax(u,v)));});
test('Lean 4.34 Trans constructor field universe is below its inductive result universe',()=>{
 const u=levelParam(nameFromDotted('u')),v=levelParam(nameFromDotted('v')),w=levelParam(nameFromDotted('w'));
 const u1=levelParam(nameFromDotted('u_1')),u2=levelParam(nameFromDotted('u_2')),u3=levelParam(nameFromDotted('u_3'));
 const one=levelSucc(levelZero);
 const result=levelMaxRaw(levelMaxRaw(levelMaxRaw(levelMaxRaw(levelMaxRaw(levelMaxRaw(one,u),u1),u2),u3),v),w);
 assert(levelLe(mkIMax(u,v),levelMaxRaw(u,v)),'Lean max-geq shortcut must fall through before decomposing an imax target');
 const field=mkIMax(u1,mkIMax(u2,mkIMax(u3,mkIMax(u,mkIMax(v,w)))));
 for(const [name,x] of [['u',u],['v',v],['w',w],['u_1',u1],['u_2',u2],['u_3',u3]] as const){
   assert(levelLe(x,result),`Trans result universe must dominate ${name}`);
 }
 assert(levelLe(field,result),'Lean 4.34 accepts Trans.mk field universe under the Trans result universe');
});

test('Lean 4.34 universe equivalence preserves kernel incompleteness',()=>{const u=levelParam(nameFromDotted('u')),v=levelParam(nameFromDotted('v'));const lhs=mkMax(v,u),rhs=mkMax(mkIMax(u,v),u);assert(!levelEquivalent(lhs,rhs),'Lean 4.34 normalized structural equivalence remains intentionally incomplete on this pair');assert(levelLe(lhs,rhs)&&levelLe(rhs,lhs),'Lean 4.34 is_geq proves both directions after the max positive shortcut falls through to imax decomposition');});
test('Lean structural equality includes MData payload while defeq ignores it',()=>{
 const a={kind:'mdata',data:{tag:'a'},expr:natLit(0)} as const;
 const b={kind:'mdata',data:{tag:'b'},expr:natLit(0)} as const;
 assert(!exprLeanEq(a,b),'Lean Expr structural equality compares MData payloads');
 assert(!exprEq(a,b),'strong core expression equality compares MData payloads');
 assert(new TypeChecker(baseEnv()).isDefEq(a,b),'kernel definitional equality intentionally ignores MData payloads');
});

test('infer identity lambda',()=>{const tc=new TypeChecker(baseEnv());const id=lam(nameFromDotted('x'),constant(N.Nat),bvar(0));const ty=tc.check(id);eqExpr(ty,forallE(nameFromDotted('x'),constant(N.Nat),constant(N.Nat)));});
test('WHNF beta reduction consumes wide lambda spines in one substitution batch',()=>{
 const n=512;let fn:any=bvar(n-1);
 for(let i=0;i<n;i++)fn=lam(nameFromDotted('x'+i),constant(N.Nat),fn);
 const args=Array.from({length:n},(_,i)=>natLit(i+1));
 eqExpr(new TypeChecker(baseEnv()).whnf(mkAppN(fn,args)),args[0]);
});

test('beta reduction',()=>{const tc=new TypeChecker(baseEnv());const id=lam(nameFromDotted('x'),constant(N.Nat),bvar(0));eqExpr(tc.whnf(app(id,natLit(3))),natLit(3));});
test('kernel memo tables share entries across Lean-structurally equal clones',()=>{
 const st=new KernelState();
 const a=app(constant(N.NatSucc),natLit(0)),aClone=app(constant(N.NatSucc),natLit(0));
 st.whnf.set(a,natLit(1));
 assert(st.whnf.has(aClone),'expr_map cache lookup must use Lean structural equality, not object identity');
 eqExpr(st.whnf.get(aClone)!,natLit(1));
 const x=constant(nameFromDotted('CacheClone.x')),y=constant(nameFromDotted('CacheClone.y'));
 const xClone=constant(nameFromDotted('CacheClone.x')),yClone=constant(nameFromDotted('CacheClone.y'));
 st.success.add(st.pair(x,y));
 assert(st.success.has(st.pair(xClone,yClone)),'defeq success cache must recognize structurally equal cloned pairs');
 assert(st.success.has(st.pair(yClone,xClone)),'defeq pair cache remains symmetric like Lean hash-canonicalized pairs');
});

test('checker state is locked to one immutable environment revision',()=>{
 const env=baseEnv(),st=new KernelState(),tc=new TypeChecker(env,new LocalContext(),st),A=nameFromDotted('EnvRevision.A');
 eqExpr(tc.check(natLit(0)),constant(N.Nat));
 env.add({kind:'axiom',name:A,levelParams:[],type:constant(N.Nat)});
 throws(()=>tc.check(constant(A)));
 const fresh=new TypeChecker(env);
 eqExpr(fresh.check(constant(A)),constant(N.Nat));
 throws(()=>new TypeChecker(env.clone(),new LocalContext(),st));
});

test('type checker snapshots caller-owned local contexts',()=>{
 const env=baseEnv(),lctx=new LocalContext(),id='snapshot@0';
 lctx.addLocal(id,nameFromDotted('x'),constant(N.Nat));
 const tc=new TypeChecker(env,lctx);
 lctx.addLocal(id,nameFromDotted('x'),sort(levelZero));
 eqExpr(tc.check(fvar(id)),constant(N.Nat));
});

test('shared checker state rejects incompatible cache-affecting checker configuration',()=>{
 const env=baseEnv();
 const unsafeName=nameFromDotted('StateMode.unsafe');
 env.add({kind:'axiom',name:unsafeName,levelParams:[],type:constant(N.Nat),isUnsafe:true});

 const safetyState=new KernelState();
 new TypeChecker(env,new LocalContext(),safetyState,undefined,'unsafe').check(constant(unsafeName));
 throws(()=>new TypeChecker(env,new LocalContext(),safetyState,undefined,'safe'));

 const u=nameFromDotted('StateMode.u'),v=nameFromDotted('StateMode.v');
 const levelState=new KernelState();
 new TypeChecker(env,new LocalContext(),levelState,undefined,'safe',[u]);
 throws(()=>new TypeChecker(env,new LocalContext(),levelState,undefined,'safe',[v]));

 const limitsState=new KernelState();
 new TypeChecker(env,new LocalContext(),limitsState,{maxRecDepth:512,maxNatBytes:1024n});
 throws(()=>new TypeChecker(env,new LocalContext(),limitsState,{maxRecDepth:512,maxNatBytes:8n}));

 const nativeA:NativeEvaluator={evaluate(){return {kind:'nat',value:1n};}};
 const nativeB:NativeEvaluator={evaluate(){return {kind:'nat',value:1n};}};
 const nativeState=new KernelState();
 new TypeChecker(env,new LocalContext(),nativeState,undefined,'safe',undefined,false,nativeA);
 throws(()=>new TypeChecker(env,new LocalContext(),nativeState,undefined,'safe',undefined,false,nativeB));
});

test('shared checker state rejects incompatible FVar rebinding',()=>{
 const env=baseEnv(),st=new KernelState(),a=new LocalContext(),b=new LocalContext(),id='shared@0';
 a.addLocal(id,nameFromDotted('x'),constant(N.Nat));
 new TypeChecker(env,a,st);
 b.addLocal(id,nameFromDotted('x'),sort(levelZero));
 throws(()=>new TypeChecker(env,b,st));
});

test('checker-state local name generator stays unique across independent local contexts',()=>{
 const st=new KernelState(),a=new LocalContext(),b=new LocalContext();
 const x=st.freshLocal('x',a),y=st.freshLocal('x',b);
 assert(x!==y,'Lean-style checker state must never recycle fvar ids across sibling contexts');
 assert(x.startsWith('_kernel_fresh@')&&y.startsWith('_kernel_fresh@'),'kernel-generated fvars use a reserved internal namespace');
});

test('structural WHNF cache preserves Lean is_eqp progress distinction',()=>{
 const tc=new TypeChecker(baseEnv()),S=nameFromDotted('Eqp.Fake');
 const a={kind:'proj',typeName:S,index:0,expr:natLit(0)} as const;
 const b={kind:'proj',typeName:S,index:0,expr:natLit(0)} as const;
 const first=tc.whnfCore(a),second=tc.whnfCore(b);
 assert(first===a,'first unreduced projection is cached as its original object');
 assert(second===a&&second!==b,'structural cache hit may return another equal object, so defeq progress must use object identity like is_eqp');
});

test('Lean structural equality and cache lookup are stack-safe on deep clones',()=>{
 const ty=constant(N.Nat);let a:any=natLit(0),b:any=natLit(0);
 for(let i=0;i<12000;i++){
   a=lam(nameFromDotted('a'+i),ty,a,'default');
   b=lam(nameFromDotted('b'+i),ty,b,'implicit');
 }
 assert(exprLeanEq(a,b),'deep binder metadata-insensitive structural equality must not overflow the JS stack');
 const st=new KernelState();st.infer.set(a,ty);
 assert(st.infer.has(b),'deep structurally equal clones must hit Lean-style expression caches');
});

test('kernel structural cache keys ignore binder display metadata like Lean expr_map',()=>{
 const st=new KernelState(),ty=constant(N.Nat),body=bvar(0);
 const a=lam(nameFromDotted('left'),ty,body,'default');
 const b=lam(nameFromDotted('right'),ty,body,'implicit');
 st.infer.set(a,constant(N.Nat));
 assert(st.infer.has(b),'Lean expr_map equality ignores binder names and BinderInfo');
 eqExpr(st.infer.get(b)!,constant(N.Nat));
});

test('defeq success cache remains pair-local and never gains transitive closure',()=>{
 const st=new KernelState(),a=constant(nameFromDotted('Cache.a')),b=constant(nameFromDotted('Cache.b')),c=constant(nameFromDotted('Cache.c'));
 st.success.add(st.pair(a,b));st.success.add(st.pair(b,c));
 assert(!st.success.has(st.pair(a,c)),'Lean 4.34 defeq cache must not transitively close successful algorithmic comparisons');
});

test('cached public defeq still enters the Lean recursion guard',()=>{
 const env=baseEnv(),st=new KernelState(),a=natLit(0),b=natLit(0),tc=new TypeChecker(env,undefined,st,{maxRecDepth:1,maxNatBytes:134217728n});
 st.success.add(st.pair(a,b));
 st.recDepth=16;
 throws(()=>tc.isDefEq(a,b));
 st.recDepth=0;
 assert(tc.isDefEq(a,b),'cached success remains available once the guarded core can be entered');
});

test('internal defeq core success does not populate the public success cache',()=>{
 const env=baseEnv(),K=nameFromDotted('CoreCache.K'),uN=nameFromDotted('u'),u=levelParam(uN);
 env.add({kind:'axiom',name:K,levelParams:[uN],type:sort(u)});
 const a=constant(K,[mkMax(u,u)]),b=constant(K,[u]),tc=new TypeChecker(env),pair=tc.state.pair(a,b);
 assert((tc as any).isDefEqCore(a,b),'equivalent universe arguments on the same constant are core-definitionally equal');
 assert(!tc.state.success.has(pair),'core-only success must remain cache-neutral until the public wrapper is used');
 assert(tc.isDefEq(a,b),'public wrapper must preserve the same result');
 assert(tc.state.success.has(pair),'public successful query must populate the success cache');
});

test('lazy delta ignores definitions with malformed universe arity',()=>{
 const env=baseEnv(),uN=nameFromDotted('u'),u=levelParam(uN),A=nameFromDotted('DeltaArity.A'),B=nameFromDotted('DeltaArity.B');
 env.add({kind:'definition',name:A,levelParams:[uN],type:sort(u),value:sort(levelZero),hints:{kind:'abbrev'},safety:'safe'});
 env.add({kind:'definition',name:B,levelParams:[uN],type:sort(u),value:sort(levelZero),hints:{kind:'regular',height:1n},safety:'safe'});
 const tc=new TypeChecker(env),a=constant(A),b=constant(B);
 throws(()=>tc.isDefEq(a,b));
 assert((tc as any).deltaTarget(a)===null&&(tc as any).deltaTarget(b)===null,'Lean is_delta requires exact universe arity even though public defeq rejects the malformed constants earlier');
});

test('lazy delta reduction has no arbitrary 512-step semantic cap',()=>{
 const env=baseEnv(),count=600;
 for(let i=count;i>=0;i--){
   const n=nameFromDotted('LongDelta.D'+i),value=i===count?natLit(0):constant(nameFromDotted('LongDelta.D'+(i+1)));
   env.add({kind:'definition',name:n,levelParams:[],type:constant(N.Nat),value,hints:{kind:'regular',height:BigInt(count-i+1)},safety:'safe'});
 }
 const tc=new TypeChecker(env);
 assert(tc.isDefEq(constant(nameFromDotted('LongDelta.D0')),natLit(0)),'Lean lazy delta must continue past 512 definition steps');
});

test('public defeq failures do not populate Lean lazy-delta failure cache',()=>{
 const tc=new TypeChecker(baseEnv()),a=natLit(0),b=natLit(1),pair=tc.state.pair(a,b);
 assert(!tc.isDefEq(a,b),'distinct Nat literals are not definitionally equal');
 assert(!tc.state.failure.has(pair),'Lean 4.34 public defeq wrapper must not cache arbitrary failures');
});

test('defeq caches the original pair after delta proves equality',()=>{
 const env=baseEnv(),A=nameFromDotted('Cache.deltaA'),B=nameFromDotted('Cache.deltaB'),k=new Kernel(env);
 for(const n of [A,B])k.addDefinition({kind:'definition',name:n,levelParams:[],type:constant(N.Nat),value:natLit(7),hints:{kind:'regular',height:1n},safety:'safe'});
 const a=constant(A),b=constant(B),tc=new TypeChecker(env);
 assert(tc.isDefEq(a,b),'equal definitions should be definitionally equal');
 assert(tc.state.success.has(tc.state.pair(a,b)),'Lean 4.34 caches every successful public defeq query at the original pair');
});

test('defeq compares application heads before rejecting arity mismatch',()=>{
 const env=baseEnv(),F=nameFromDotted('Cache.curriedF'),fn=constant(F);
 env.add({kind:'axiom',name:F,levelParams:[],type:forallE(nameFromDotted('a'),constant(N.Nat),forallE(nameFromDotted('b'),constant(N.Nat),constant(N.Nat)))});
 const oneArg=app(fn,natLit(0)),twoArgs=app(app(fn,natLit(0)),natLit(1)),tc=new TypeChecker(env);
 assert(!tc.state.success.has(tc.state.pair(fn,fn)),'precondition: head pair must not already be cached');
 assert(!tc.isDefEq(oneArg,twoArgs),'different application arities are not definitionally equal');
 assert(tc.state.success.has(tc.state.pair(fn,fn)),'Lean 4.34 compares and caches equal heads before noticing the arity mismatch');
});

test('reducible Prop sort remains proof-only through inductive and projection checking',()=>{
 const env=baseEnv(),Gate=nameFromDotted('EnsureSort.Gate'),Carrier=nameFromDotted('EnsureSort.Carrier'),I=nameFromDotted('EnsureSort.Owner'),Mk=nameFromDotted('EnsureSort.Owner.mk'),p=nameFromDotted('EnsureSort.proof');
 const k=new Kernel(env);
 k.addDefinition({kind:'definition',name:Gate,levelParams:[],type:sort(levelSucc(levelZero)),value:sort(levelZero),hints:{kind:'abbrev'},safety:'safe'});
 k.addAxiom({kind:'axiom',name:Carrier,levelParams:[],type:constant(Gate)});
 assert(new TypeChecker(env).isProp(constant(Carrier)),'isProp must WHNF the inferred Gate type to Sort 0 before reading its universe level');
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:constant(Gate),ctors:[{name:Mk,type:forallE(nameFromDotted('bit'),constant(N.Bool),constant(I))}]}]});
 const ri=env.get(nameFromDotted('EnsureSort.Owner.rec'));
 assert(ri.kind==='recursor'&&ri.levelParams.length===0,'a reducible Prop result sort must not gain large elimination');
 env.add({kind:'axiom',name:p,levelParams:[],type:constant(I)});
 throws(()=>new TypeChecker(env).check({kind:'proj',typeName:I,index:0,expr:constant(p)}));
});

test('isProp requires the inferred type to reduce to a Sort',()=>{
 const tc=new TypeChecker(baseEnv());
 throws(()=>tc.isProp(natLit(0)));
});

test('Lean structural equality uses extensional KVMap MData equality',()=>{
 const x=natLit(0);
 const a={kind:'mdata',data:{alpha:1,beta:true},expr:x} as const;
 const same={kind:'mdata',data:{alpha:1,beta:true},expr:x} as const;
 const reordered={kind:'mdata',data:{beta:true,alpha:1},expr:x} as const;
 const different={kind:'mdata',data:{alpha:1,beta:false},expr:x} as const;
 assert(exprLeanEq(a,same),'identical metadata payloads remain structurally equal');
 assert(exprLeanEq(a,reordered),'Lean KVMap equality is extensional and ignores entry insertion order');
 assert(!exprLeanEq(a,different),'different MData bindings must remain structurally distinct');
 const st=new KernelState();st.infer.set(a,constant(N.Nat));assert(st.infer.has(reordered),'structural expression caches must share reordered but KVMap-equal metadata');
 assert(new TypeChecker(baseEnv()).isDefEq(a,reordered),'kernel defeq intentionally ignores MData placement/payloads too');
 assert(new TypeChecker(baseEnv()).isDefEq(a,different),'kernel defeq intentionally ignores MData payloads');
});

test('Lean structural equality preserves let nondep while defeq zeta-reduces it away',()=>{
 const name=nameFromDotted('x'),ty=sort(levelSucc(levelZero)),value=sort(levelZero),body=sort(levelZero);
 const dep={kind:'let',name,type:ty,value,body,nondep:false} as const;
 const nondep={kind:'let',name,type:ty,value,body,nondep:true} as const;
 assert(!exprLeanEq(dep,nondep),'Lean Expr == compares let_nondep');
 assert(new TypeChecker(baseEnv()).isDefEq(dep,nondep),'let_nondep is structural metadata, not a type-theoretic distinction after zeta');
});

test('lean4export opaque MData equality ids survive replay',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"MetaA"}}',
  '{"in":2,"str":{"pre":0,"str":"MetaB"}}',
  '{"ie":0,"sort":0}',
  '{"ie":1,"mdata":{"dataEq":0,"expr":0}}',
  '{"ie":2,"mdata":{"dataEq":1,"expr":0}}',
  '{"axiom":{"name":1,"levelParams":[],"type":1,"isUnsafe":false}}',
  '{"axiom":{"name":2,"levelParams":[],"type":2,"isUnsafe":false}}'
 ].join('\n');
 const r=new Lean4ExportReplay();r.replay(nd);
 const a=r.env.get(nameFromDotted('MetaA')),b=r.env.get(nameFromDotted('MetaB'));
 assert(a.kind==='axiom'&&b.kind==='axiom');
 assert(!exprLeanEq(a.type,b.type),'distinct exported KVMap equality ids remain structurally distinct');
 assert(new TypeChecker(r.env).isDefEq(a.type,b.type),'defeq still ignores metadata after replay');
});

test('Lean structural expression equality ignores binder annotations',()=>{
 const ty=constant(N.Nat),body=bvar(0);
 const a=lam(nameFromDotted('x'),ty,body,'default'),b=lam(nameFromDotted('y'),ty,body,'implicit');
 assert(!exprEq(a,b),'exact expression equality retains binder metadata');
 assert(exprLeanEq(a,b),'Lean kernel Expr == ignores binder names and BinderInfo');
 const tc=new TypeChecker(baseEnv());assert(tc.isDefEq(a,b),'defeq quick path must follow Lean structural equality');
});

test('binder defeq flattens wide Pi chains within Lean kernel depth budget',()=>{
 let a:any=constant(N.Nat),b:any=constant(N.Nat);
 for(let i=0;i<200;i++){
   a=forallE(nameFromDotted('left'+i),constant(N.Nat),a);
   b=forallE(nameFromDotted('right'+i),constant(N.Nat),b);
 }
 const tc=new TypeChecker(baseEnv(),undefined,undefined,{maxRecDepth:1,maxNatBytes:134217728n});
 assert(tc.isDefEq(a,b),'binder display names must not matter and wide binder chains must not consume one recursion frame each');
});

test('proof irrelevance compares arbitrary proofs of the same proposition',()=>{
 const env=baseEnv(),P=nameFromDotted('ProofIrrel.P');env.add({kind:'axiom',name:P,levelParams:[],type:sort(levelZero)});
 const lctx=new LocalContext();lctx.addLocal('p@0',nameFromDotted('p'),constant(P));lctx.addLocal('q@0',nameFromDotted('q'),constant(P));
 const tc=new TypeChecker(env,lctx);assert(tc.isDefEq(fvar('p@0'),fvar('q@0')));
});
test('Nat optimized reduction requires exact level-free primitive heads',()=>{
 const env=baseEnv(),tc=new TypeChecker(env);
 const malformedAdd=app(app(constant(N.NatAdd,[levelZero]),natLit(1)),natLit(2));
 eqExpr(tc.whnf(malformedAdd),malformedAdd);
 const malformedZero=constant(N.NatZero,[levelZero]);
 const malformedSucc=app(constant(N.NatSucc,[levelZero]),natLit(0));
 assert(!(tc as any).isNatZeroExpr(malformedZero),'Nat.zero with universe arguments is not Lean kernel zero');
 assert((tc as any).natPredExpr(malformedSucc)===null,'Nat.succ with universe arguments is not a Lean kernel successor');
 const ctorOne=app(constant(N.NatSucc),constant(N.NatZero));
 assert(asNat(ctorOne)===null,'the literal fast path itself must not reinterpret Nat.succ constructor syntax');
 const succOfCtorZero=app(constant(N.NatSucc),ctorOne);
 eqExpr(tc.whnf(succOfCtorZero),natLit(2),'Lean WHNF reduces the operand first, then the exact literal fast path consumes the resulting numeral');
 const addCtor=app(app(constant(N.NatAdd),ctorOne),natLit(2));
 eqExpr(tc.whnf(addCtor),natLit(3),'binary Nat reduction likewise WHNFs constructor-form operands before literal extraction');
});

test('Nat.add reduction uses exact bigint',()=>{const tc=new TypeChecker(baseEnv());const e=app(app(constant(N.NatAdd),natLit(9007199254740993n)),natLit(7));eqExpr(tc.whnf(e),natLit(9007199254741000n));});
test('Nat literal and count limits follow explicit Lean kernel limits',()=>{
 const env=baseEnv(),limits={maxRecDepth:512,maxNatBytes:8n},tc=new TypeChecker(env,undefined,undefined,limits);
 tc.check(natLit(0));tc.check(natLit((1n<<64n)-1n));throws(()=>tc.check(natLit(1n<<64n)));
 const belowWord=new TypeChecker(env,undefined,undefined,{maxRecDepth:512,maxNatBytes:7n});
 throws(()=>belowWord.check(natLit(0)));
 const normal=new TypeChecker(env);throws(()=>normal.whnf(app(app(constant(N.NatPow),natLit(2)),natLit(0x1_0000_0000n))));
 throws(()=>normal.whnf(app(app(constant(N.NatShiftLeft),natLit(1)),natLit(0x1_0000_0000n))));
});
test('Nat resource limits cover final-4.34 growth checkpoints',()=>{
 const env=baseEnv(),tc=new TypeChecker(env,undefined,undefined,{maxRecDepth:512,maxNatBytes:8n});
 const whnf=(name:any,a:bigint,b?:bigint)=>{
   const head=constant(name);
   return tc.whnf(b===undefined?app(head,natLit(a)):app(app(head,natLit(a)),natLit(b)));
 };
 // One 64-bit limb is still within the 8-byte budget.
 eqExpr(whnf(N.NatSucc,(1n<<63n)-1n),natLit(1n<<63n));
 eqExpr(whnf(N.NatAdd,1n<<62n,1n<<62n),natLit(1n<<63n));
 eqExpr(whnf(N.NatMul,1n<<31n,1n<<31n),natLit(1n<<62n));

 // Crossing into a second 64-bit limb is rejected at every v4.34 growth point.
 throws(()=>whnf(N.NatSucc,(1n<<64n)-1n));
 throws(()=>whnf(N.NatAdd,1n<<63n,1n<<63n));
 throws(()=>whnf(N.NatSub,1n<<65n,0n));
 throws(()=>whnf(N.NatMul,1n<<32n,1n<<32n));
 throws(()=>whnf(N.NatPow,2n,64n));
 throws(()=>whnf(N.NatShiftLeft,1n,64n));
});

test('Nat.pow reduction',()=>{const tc=new TypeChecker(baseEnv());eqExpr(tc.whnf(app(app(constant(N.NatPow),natLit(2)),natLit(20))),natLit(1048576));});
test('WHNF application spines do not consume one recursion frame per argument',()=>{
 const env=baseEnv(),F=nameFromDotted('WideApp.f');env.add({kind:'axiom',name:F,levelParams:[],type:sort(levelSucc(levelZero))});
 let term:any=constant(F);for(let i=0;i<1000;i++)term=app(term,natLit(i));
 const tc=new TypeChecker(env,undefined,undefined,{maxRecDepth:2,maxNatBytes:134217728n});
 eqExpr(tc.whnfCore(term),term);
});

test('WHNF recursion budget matches Lean core placement',()=>{
 const env=baseEnv(),zeroBudget=new TypeChecker(env,undefined,undefined,{maxRecDepth:0,maxNatBytes:134217728n}),oneBudget=new TypeChecker(env,undefined,undefined,{maxRecDepth:1,maxNatBytes:134217728n});
 eqExpr(zeroBudget.whnf(natLit(3)),natLit(3));
 eqExpr(zeroBudget.whnf(sort(levelZero)),sort(levelZero));
 eqExpr(oneBudget.whnf(constant(N.NatZero)),constant(N.NatZero));
});

test('kernel recursion budget matches Lean 4.34 unlimited and 16x semantics',()=>{
 const env=baseEnv();let deep:any=constant(N.NatZero);for(let i=0;i<24;i++)deep=app(constant(N.NatSucc),deep);
 const unlimited=new TypeChecker(env,undefined,undefined,{maxRecDepth:0,maxNatBytes:134217728n});eqExpr(unlimited.check(deep),constant(N.Nat));
 const low=new TypeChecker(env,undefined,undefined,{maxRecDepth:1,maxNatBytes:134217728n});let message='';try{low.check(deep);}catch(e){message=e instanceof Error?e.message:String(e);}
 assert(message.includes('deep recursion'),'configured maxRecDepth 1 must allow 16 kernel frames and then fail');
 const high=new TypeChecker(env,undefined,undefined,{maxRecDepth:2,maxNatBytes:134217728n});eqExpr(high.check(deep),constant(N.Nat));
});

test('inference binder spines share depth without charging one frame per binder',()=>{
 const env=baseEnv(),limits={maxRecDepth:1,maxNatBytes:134217728n},tc=new TypeChecker(env,undefined,undefined,limits);
 let lambda:any=natLit(0),pi:any=constant(N.Nat),letChain:any=natLit(0);
 for(let i=0;i<100;i++){
   lambda=lam(nameFromDotted('x'+i),constant(N.Nat),lambda);
   pi=forallE(nameFromDotted('p'+i),constant(N.Nat),pi);
   letChain={kind:'let',name:nameFromDotted('l'+i),type:constant(N.Nat),value:natLit(i),body:letChain};
 }
 tc.check(lambda);tc.check(pi);eqExpr(tc.check(letChain),constant(N.Nat));
});

test('infer-only application spine does not consume one recursion frame per argument',()=>{
 const env=baseEnv(),F=nameFromDotted('InferOnly.wide');let fType:any=constant(N.Nat);
 for(let i=0;i<1000;i++)fType=forallE(nameFromDotted('a'+i),constant(N.Nat),fType);
 env.add({kind:'axiom',name:F,levelParams:[],type:fType});
 let term:any=constant(F);for(let i=0;i<1000;i++)term=app(term,natLit(i));
 const tc=new TypeChecker(env,undefined,undefined,{maxRecDepth:1,maxNatBytes:134217728n});
 eqExpr(tc.infer(term,true),constant(N.Nat));
});
test('native reduction fails closed by default even when the logical body normalizes',()=>{
 const env=baseEnv(),vNat=nameFromDotted('Native.vNat'),vBool=nameFromDotted('Native.vBool');
 env.add({kind:'axiom',name:N.LeanReduceBool,levelParams:[],type:forallE(nameFromDotted('b'),constant(N.Bool),constant(N.Bool))});
 env.add({kind:'axiom',name:N.LeanReduceNat,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))});
 env.add({kind:'definition',name:vNat,levelParams:[],type:constant(N.Nat),value:natLit(1),hints:{kind:'regular',height:1n},safety:'safe'});
 env.add({kind:'definition',name:vBool,levelParams:[],type:constant(N.Bool),value:constant(N.BoolTrue),hints:{kind:'regular',height:1n},safety:'safe'});
 const tc=new TypeChecker(env);
 throws(()=>tc.whnf(app(constant(N.LeanReduceNat),constant(vNat))));
 throws(()=>tc.whnf(app(constant(N.LeanReduceBool),constant(vBool))));
});
test('explicit native evaluator controls Lean.reduceNat and Lean.reduceBool results',()=>{
 const env=baseEnv(),vNat=nameFromDotted('Native.vNatProvider'),vBool=nameFromDotted('Native.vBoolProvider');
 env.add({kind:'axiom',name:N.LeanReduceBool,levelParams:[],type:forallE(nameFromDotted('b'),constant(N.Bool),constant(N.Bool))});
 env.add({kind:'axiom',name:N.LeanReduceNat,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))});
 env.add({kind:'definition',name:vNat,levelParams:[],type:constant(N.Nat),value:natLit(1),hints:{kind:'regular',height:1n},safety:'safe'});
 env.add({kind:'definition',name:vBool,levelParams:[],type:constant(N.Bool),value:constant(N.BoolTrue),hints:{kind:'regular',height:1n},safety:'safe'});
 const evaluator:NativeEvaluator={evaluate(_env,request){const n=nameToString(request.constant);if(n==='Native.vNatProvider')return {kind:'nat',value:7n};if(n==='Native.vBoolProvider')return {kind:'bool',value:false};return null;}};
 const tc=new TypeChecker(env,undefined,undefined,undefined,'safe',undefined,false,evaluator);
 eqExpr(tc.whnf(app(constant(N.LeanReduceNat),constant(vNat))),natLit(7));
 eqExpr(tc.whnf(app(constant(N.LeanReduceBool),constant(vBool))),constant(N.BoolFalse));
});
test('native reduction matches Lean kernel1 defeq cases after delta unfolding',()=>{
 const env=baseEnv();
 env.add({kind:'axiom',name:N.LeanReduceBool,levelParams:[],type:forallE(nameFromDotted('b'),constant(N.Bool),constant(N.Bool))});
 env.add({kind:'axiom',name:N.LeanReduceNat,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))});
 const v1=nameFromDotted('Native.Kernel1.v1'),v2=nameFromDotted('Native.Kernel1.v2'),v3=nameFromDotted('Native.Kernel1.v3'),v4=nameFromDotted('Native.Kernel1.v4'),v5=nameFromDotted('Native.Kernel1.v5');
 for(const n of [v1,v2,v3,v5])env.add({kind:'axiom',name:n,levelParams:[],type:constant(N.Nat)});
 env.add({kind:'axiom',name:v4,levelParams:[],type:constant(N.Bool)});
 const c1=nameFromDotted('Native.Kernel1.c1'),c2=nameFromDotted('Native.Kernel1.c2'),c3=nameFromDotted('Native.Kernel1.c3'),c4=nameFromDotted('Native.Kernel1.c4'),c5=nameFromDotted('Native.Kernel1.c5');
 const def=(name:any,type:any,value:any)=>env.add({kind:'definition',name,levelParams:[],type,value,hints:{kind:'regular',height:1n},safety:'safe'});
 def(c1,constant(N.Nat),app(constant(N.LeanReduceNat),constant(v1)));
 def(c2,constant(N.Nat),app(constant(N.LeanReduceNat),constant(v2)));
 def(c3,constant(N.Nat),app(constant(N.LeanReduceNat),constant(v3)));
 def(c4,constant(N.Bool),app(constant(N.LeanReduceBool),constant(v4)));
 def(c5,constant(N.Nat),app(constant(N.LeanReduceNat),constant(v5)));
 const values=new Map([
  [nameToString(v1),{kind:'nat',value:200000000000n} as const],
  [nameToString(v2),{kind:'nat',value:200000000000n} as const],
  [nameToString(v3),{kind:'nat',value:200000000001n} as const],
  [nameToString(v4),{kind:'bool',value:false} as const],
  [nameToString(v5),{kind:'nat',value:0n} as const],
 ]);
 const evaluator:NativeEvaluator={evaluate(_env,request){return values.get(nameToString(request.constant))??null;}};
 const tc=new TypeChecker(env,undefined,undefined,undefined,'safe',undefined,false,evaluator);
 assert(tc.isDefEq(constant(c1),constant(c2)),'kernel1 c1/c2 native Nat values must be definitionally equal');
 assert(!tc.isDefEq(constant(c1),constant(c3)),'kernel1 c1/c3 native Nat values must differ');
 assert(tc.isDefEq(constant(c5),constant(N.NatZero)),'kernel1 native zero must equal Nat.zero');
 assert(tc.isDefEq(constant(N.NatZero),constant(c5)),'kernel1 Nat.zero equality must be symmetric');
 assert(!tc.isDefEq(constant(c4),constant(N.BoolTrue)),'kernel1 native false must not equal Bool.true');
});

test('native reduction marker must be the exact level-free Lean constant',()=>{
 const env=baseEnv(),v=nameFromDotted('Native.levelMarker');let calls=0;
 env.add({kind:'axiom',name:N.LeanReduceNat,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))});
 env.add({kind:'axiom',name:v,levelParams:[],type:constant(N.Nat)});
 const evaluator:NativeEvaluator={evaluate(){calls++;return {kind:'nat',value:9n};}};
 const malformed=app(constant(N.LeanReduceNat,[levelZero]),constant(v));
 const tc=new TypeChecker(env,undefined,undefined,undefined,'safe',undefined,false,evaluator);
 eqExpr(tc.whnf(malformed),malformed);
 assert(calls===0,'malformed universe arguments on the marker must not enter the native TCB provider');
});

test('native evaluator results are shape-checked at the kernel boundary',()=>{
 const env=baseEnv(),v=nameFromDotted('Native.badProvider');
 env.add({kind:'axiom',name:N.LeanReduceNat,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))});
 env.add({kind:'opaque',name:v,levelParams:[],type:constant(N.Nat),value:natLit(0)});
 const wrong:NativeEvaluator={evaluate(){return {kind:'bool',value:true};}};
 const negative:NativeEvaluator={evaluate(){return {kind:'nat',value:-1n};}};
 throws(()=>new TypeChecker(env,undefined,undefined,undefined,'safe',undefined,false,wrong).whnf(app(constant(N.LeanReduceNat),constant(v))));
 throws(()=>new TypeChecker(env,undefined,undefined,undefined,'safe',undefined,false,negative).whnf(app(constant(N.LeanReduceNat),constant(v))));
});
test('kernel admission threads native evaluator into definitional equality',()=>{
 const env=baseEnv(),one=levelSucc(levelZero);
 const v=nameFromDotted('Native.kernelV'),F=nameFromDotted('Native.F'),x=nameFromDotted('Native.x'),d=nameFromDotted('Native.d');
 env.add({kind:'axiom',name:N.LeanReduceNat,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat))});
 env.add({kind:'axiom',name:v,levelParams:[],type:constant(N.Nat)});
 env.add({kind:'axiom',name:F,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),sort(one))});
 env.add({kind:'axiom',name:x,levelParams:[],type:app(constant(F),natLit(7))});
 const info={kind:'definition',name:d,levelParams:[],type:app(constant(F),app(constant(N.LeanReduceNat),constant(v))),value:constant(x),hints:{kind:'regular',height:1n},safety:'safe'} as const;
 throws(()=>new Kernel(env.clone()).addDefinition(info));
 const evaluator:NativeEvaluator={evaluate(_env,request){return request.kind==='nat'&&nameToString(request.constant)==='Native.kernelV'?{kind:'nat',value:7n}:null;}};
 const work=env.clone();new Kernel(work,evaluator).addDefinition(info);assert(work.has(d),'kernel admission must preserve the configured native evaluator');
});
test('lean4export replay threads the explicit native evaluator into its kernel',()=>{
 const evaluator:NativeEvaluator={evaluate(){return null;}};
 const replay=new Lean4ExportReplay(baseEnv(),{nativeEvaluator:evaluator});
 assert(replay.kernel.nativeEvaluator===evaluator,'replay kernel must retain NativeEvaluator identity');
});

test('literal inference matches Lean trusted-prelude behavior',()=>{
 const env=new Environment(),tc=new TypeChecker(env);
 eqExpr(tc.check(natLit(0)),constant(N.Nat));
 eqExpr(tc.check(strLit('x')),constant(N.String));
 assert(!env.has(N.Nat)&&!env.has(N.String),'literal inference must not synthesize or require prelude declarations');
});

test('infer-only application does not inspect a closed ill-typed argument',()=>{
 const env=baseEnv(),F=nameFromDotted('InferOnly.f');
 env.add({kind:'axiom',name:F,levelParams:[],type:forallE(nameFromDotted('x'),constant(N.Nat),constant(N.Nat))});
 const badArg=app(natLit(0),natLit(1)),term=app(constant(F),badArg),tc=new TypeChecker(env);
 eqExpr(tc.infer(term,true),constant(N.Nat));
 throws(()=>tc.check(term));
});

test('infer-only let does not inspect its closed ill-typed value',()=>{
 const tc=new TypeChecker(baseEnv()),badValue=app(natLit(0),natLit(1));
 const term={kind:'let',name:nameFromDotted('x'),type:constant(N.Nat),value:badValue,body:natLit(0)} as const;
 eqExpr(tc.infer(term,true),constant(N.Nat));
 throws(()=>tc.check(term));
});

test('dependent let inference preserves the let in the resulting type',()=>{
 const env=baseEnv(),P=nameFromDotted('InferLet.P'),g=nameFromDotted('InferLet.g'),one=levelSucc(levelZero);
 env.add({kind:'axiom',name:P,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),sort(one))});
 env.add({kind:'axiom',name:g,levelParams:[],type:forallE(nameFromDotted('n'),constant(N.Nat),app(constant(P),bvar(0)))});
 const term={kind:'let',name:nameFromDotted('n'),type:constant(N.Nat),value:natLit(3),body:app(constant(g),bvar(0))} as const;
 const expected={kind:'let',name:nameFromDotted('n'),type:constant(N.Nat),value:natLit(3),body:app(constant(P),bvar(0))} as const;
 const tc=new TypeChecker(env);eqExpr(tc.infer(term,true),expected);eqExpr(tc.check(term),expected);
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
test('opaque admission rejects dangling free variables transactionally',()=>{
 const env=baseEnv(),k=new Kernel(env),nm=nameFromDotted('opaqueDanglingFVar');
 const natToNat=forallE(nameFromDotted('h'),constant(N.Nat),constant(N.Nat));
 const identity=lam(nameFromDotted('h'),constant(N.Nat),bvar(0));
 const cachePrimingType=app(lam(nameFromDotted('_'),natToNat,constant(N.Nat)),identity);
 throws(()=>k.addOpaque({kind:'opaque',name:nm,levelParams:[],type:cachePrimingType,value:fvar('_kernel_fresh@2')}));
 assert(!env.has(nm),'rejected opaque declaration must not mutate the environment');
});

test('opaque declarations do not delta unfold',()=>{const env=baseEnv(),k=new Kernel(env),nm=nameFromDotted('opaqueNat');k.addOpaque({kind:'opaque',name:nm,levelParams:[],type:constant(N.Nat),value:natLit(4)});const tc=new TypeChecker(env);eqExpr(tc.whnf(constant(nm)),constant(nm));});
test('loose bvars rejected',()=>{const tc=new TypeChecker(baseEnv());throws(()=>tc.check(bvar(0)));});
test('infer-only rejects loose bvars even inside skipped application arguments',()=>{
 const env=baseEnv(),F=nameFromDotted('InferLoose.f');
 env.add({kind:'axiom',name:F,levelParams:[],type:forallE(nameFromDotted('x'),constant(N.Nat),constant(N.Nat))});
 throws(()=>new TypeChecker(env).infer(app(constant(F),bvar(0)),true));
});


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
test('constructor result shape is structural like Lean 4.34',()=>{
 const env=baseEnv(),I=nameFromDotted('CtorShape.I'),Mk=nameFromDotted('CtorShape.I.mk'),T=sort(levelSucc(levelZero));
 const wrapped=app(lam(nameFromDotted('_'),constant(N.Nat),constant(I)),natLit(0));
 throws(()=>addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:T,ctors:[{name:Mk,type:wrapped}]}]}));
 assert(!env.has(I)&&!env.has(Mk),'beta-reducing a constructor result into the inductive type must not make an invalid structural result admissible');
});

test('inductive uniformity is checked before WHNF can erase a bad occurrence',()=>{
 const env=baseEnv(),I=nameFromDotted('BadUniform'),Mk=nameFromDotted('BadUniform.mk'),one=levelSucc(levelZero),Type=sort(one);
 const indTy=forallE(nameFromDotted('α'),Type,Type,'implicit');
 const badOccurrence=app(constant(I),constant(N.Nat));
 const erased=app(lam(nameFromDotted('_'),Type,constant(N.Nat)),badOccurrence);
 const ctorTy=forallE(nameFromDotted('α'),Type,forallE(nameFromDotted('hidden'),erased,app(constant(I),bvar(1))),'implicit');
 throws(()=>addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{name:I,type:indTy,ctors:[{name:Mk,type:ctorTy}]}]}));
 assert(!env.has(I)&&!env.has(Mk),'non-uniform occurrence rejection must be transactional');
});

test('nested fixed parameters are checked even when auxiliary preprocessing drops them',()=>{
 const env=baseEnv(),one=levelSucc(levelZero),Type=sort(one);
 const Box=nameFromDotted('NestedCheck.Box'),BoxMk=nameFromDotted('NestedCheck.Box.mk');
 addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{
   name:Box,
   type:forallE(nameFromDotted('α'),Type,Type,'implicit'),
   ctors:[{name:BoxMk,type:forallE(nameFromDotted('α'),Type,app(constant(Box),bvar(0)),'implicit')}]
 }]});

 const Bad=nameFromDotted('NestedCheck.Bad'),BadMk=nameFromDotted('NestedCheck.Bad.mk');
 const badFixed=app(lam(nameFromDotted('_'),constant(N.Nat),constant(Bad)),constant(N.BoolTrue));
 const ctorTy=forallE(nameFromDotted('field'),app(constant(Box),badFixed),constant(Bad));
 throws(()=>addInductive(env,{levelParams:[],numParams:0,types:[{name:Bad,type:Type,ctors:[{name:BadMk,type:ctorTy}]}]}));
 assert(!env.has(Bad)&&!env.has(BadMk),'ill-typed nested fixed parameter must be rejected transactionally');
});

test('nested auxiliary dedup follows Lean structural MData equality',()=>{
 const env=baseEnv(),Type=sort(levelSucc(levelZero));
 const Box=nameFromDotted('NestedMData.Box'),BoxMk=nameFromDotted('NestedMData.Box.mk');
 addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{
   name:Box,
   type:forallE(nameFromDotted('α'),Type,Type,'implicit'),
   ctors:[{name:BoxMk,type:forallE(nameFromDotted('α'),Type,app(constant(Box),bvar(0)),'implicit')}]
 }]});
 const I=nameFromDotted('NestedMData.I'),Mk=nameFromDotted('NestedMData.I.mk');
 const fixedA={kind:'mdata',data:{tag:'a'},expr:constant(I)} as const;
 const fixedB={kind:'mdata',data:{tag:'b'},expr:constant(I)} as const;
 const ctorTy=forallE(nameFromDotted('a'),app(constant(Box),fixedA),
   forallE(nameFromDotted('b'),app(constant(Box),fixedB),constant(I)));
 addInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:Type,ctors:[{name:Mk,type:ctorTy}]}]});
 const ii=env.get(I);
 assert(ii.kind==='inductive'&&ii.numNested===2,'Lean structural nested-family dedup must keep distinct MData payloads separate');
});

test('nested declarations reject FVars and MVars before preprocessing can erase them',()=>{
 const env=baseEnv(),one=levelSucc(levelZero),Type=sort(one);
 const Box=nameFromDotted('NestedClosed.Box'),BoxMk=nameFromDotted('NestedClosed.Box.mk');
 addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{
   name:Box,
   type:forallE(nameFromDotted('α'),Type,Type,'implicit'),
   ctors:[{name:BoxMk,type:forallE(nameFromDotted('α'),Type,app(constant(Box),bvar(0)),'implicit')}]
 }]});

 const checkBad=(suffix:string,payload:any)=>{
   const I=nameFromDotted('NestedClosed.'+suffix),Mk=nameFromDotted('NestedClosed.'+suffix+'.mk');
   const fixed=app(lam(nameFromDotted('_'),constant(N.Nat),constant(I)),payload);
   const ctorTy=forallE(nameFromDotted('field'),app(constant(Box),fixed),constant(I));
   throws(()=>addInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:Type,ctors:[{name:Mk,type:ctorTy}]}]}));
   assert(!env.has(I)&&!env.has(Mk),'invalid nested declaration must commit nothing');
 };
 checkBad('Free',fvar('dangling-nested-fvar'));
 checkBad('Meta',{kind:'mvar',id:'?nested'} as const);
});

test('nested inductive uniformity is checked before preprocessing can drop bad parameters',()=>{
 const env=baseEnv(),T=sort(levelSucc(levelZero));
 const W=nameFromDotted('UniformNested.W'),W0=nameFromDotted('UniformNested.W.zero');
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:W,type:T,ctors:[{name:W0,type:constant(W)}]}]});
 const L=nameFromDotted('UniformNested.L'),LMk=nameFromDotted('UniformNested.L.mk');
 const lTy=forallE(nameFromDotted('α'),T,T,'implicit'),l=(x:any)=>app(constant(L),x);
 addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{name:L,type:lTy,ctors:[{name:LMk,type:forallE(nameFromDotted('α'),T,l(bvar(0)),'implicit')}]}]});
 const E=nameFromDotted('UniformNested.E'),EMk=nameFromDotted('UniformNested.E.mk');
 const e=(w:any)=>app(constant(E),w);
 const eTy=forallE(nameFromDotted('w'),constant(W),T);
 const badNested=l(e(constant(W0)));
 const ctorTy=forallE(nameFromDotted('w'),constant(W),forallE(nameFromDotted('xs'),badNested,e(bvar(1))));
 throws(()=>addInductive(env,{levelParams:[],numParams:1,types:[{name:E,type:eTy,ctors:[{name:EMk,type:ctorTy}]}]}));
 assert(!env.has(E)&&!env.has(EMk),'nested non-uniform occurrence must be rejected before auxiliary preprocessing');
});

test('inductive uniformity requires exact declaration universe arguments',()=>{
 const env=baseEnv(),U=nameFromDotted('UniformLevels.U'),Mk=nameFromDotted('UniformLevels.U.mk');
 const uN=nameFromDotted('u'),vN=nameFromDotted('v'),u=levelParam(uN),v=levelParam(vN),T=sort(levelSucc(levelZero));
 const uTy=forallE(nameFromDotted('p'),T,T);
 const good=(p:any)=>app(constant(U,[u,v]),p),bad=(p:any)=>app(constant(U,[v,u]),p);
 const ctorTy=forallE(nameFromDotted('p'),T,forallE(nameFromDotted('hidden'),bad(bvar(0)),good(bvar(1))));
 throws(()=>addOrdinaryInductive(env,{levelParams:[uN,vN],numParams:1,types:[{name:U,type:uTy,ctors:[{name:Mk,type:ctorTy}]}]}));
 assert(!env.has(U)&&!env.has(Mk),'swapped recursive universe parameters must reject transactionally');
});

test('uniform occurrence accepts a constructor parameter whose type is definitionally equal',()=>{
 const env=baseEnv(),Alias=nameFromDotted('UniformDefeq.Alias'),V=nameFromDotted('UniformDefeq.V'),Mk=nameFromDotted('UniformDefeq.V.mk');
 const T=sort(levelSucc(levelZero)),k=new Kernel(env);
 k.addDefinition({kind:'definition',name:Alias,levelParams:[],type:sort(levelSucc(levelSucc(levelZero))),value:T,hints:{kind:'abbrev'},safety:'safe'});
 const vTy=forallE(nameFromDotted('p'),T,T),v=(p:any)=>app(constant(V),p);
 const ctorTy=forallE(nameFromDotted('p'),constant(Alias),forallE(nameFromDotted('self'),v(bvar(0)),v(bvar(1))));
 addOrdinaryInductive(env,{levelParams:[],numParams:1,types:[{name:V,type:vTy,ctors:[{name:Mk,type:ctorTy}]}]});
 assert(env.has(V)&&env.has(Mk),'definitionally equal constructor parameter domains must remain accepted');
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

test('imax-normalized Prop agrees with Sort 0 on K-target recursor metadata',()=>{
 const env=baseEnv(),P=nameFromDotted('ImaxK.Prop'),PMk=nameFromDotted('ImaxK.Prop.mk'),Q=nameFromDotted('ImaxK.Zero'),QMk=nameFromDotted('ImaxK.Zero.mk');
 const imaxProp=sort(mkIMax(levelSucc(levelZero),levelZero));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:P,type:imaxProp,ctors:[{name:PMk,type:constant(P)}]}]});
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:Q,type:sort(levelZero),ctors:[{name:QMk,type:constant(Q)}]}]});
 const pr=env.get(nameFromDotted('ImaxK.Prop.rec')),qr=env.get(nameFromDotted('ImaxK.Zero.rec'));
 assert(pr.kind==='recursor'&&qr.kind==='recursor');
 assert(pr.k===qr.k&&pr.k,'normalized-Prop and syntactic-Prop nullary structures must agree on K reduction');
 assert(pr.levelParams.length===qr.levelParams.length,'normalized-Prop and syntactic-Prop recursors must agree on elimination universes');
});

test('recursor structure eta never projects data from an imax-normalized proof',()=>{
 const env=baseEnv(),I=nameFromDotted('ImaxEta.ProofBox'),Mk=nameFromDotted('ImaxEta.ProofBox.mk'),p=nameFromDotted('ImaxEta.p'),R=nameFromDotted('ImaxEta.ProofBox.rec');
 const imaxProp=sort(mkIMax(levelSucc(levelZero),levelZero));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:imaxProp,ctors:[{name:Mk,type:forallE(nameFromDotted('b'),constant(N.Bool),constant(I))}]}]});
 env.add({kind:'axiom',name:p,levelParams:[],type:constant(I)});
 const ri=env.get(R);assert(ri.kind==='recursor'&&!ri.k&&ri.levelParams.length===0);
 const motive=lam(nameFromDotted('_'),constant(I),constant(I));
 const minor=lam(nameFromDotted('_b'),constant(N.Bool),constant(p));
 const term=mkAppN(constant(R),[motive,minor,constant(p)]);
 const tc=new TypeChecker(env);
 assert(tc.isDefEq(tc.check(term),constant(I)),'Lean infer_app may leave the motive application as a beta redex, but its type must be definitionally I');
 eqExpr(tc.whnf(term),term,'Prop-valued structure major must remain opaque; eta expansion would illegally project its Bool field');
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

test('defeq enters native-reduction hook and fails closed instead of returning false',()=>{
 const env=baseEnv(),closedNat=nameFromDotted('closedNatDefEq');
 env.add({kind:'axiom',name:N.LeanReduceNat,levelParams:[],type:forallE(nameFromDotted('x'),sort(levelSucc(levelZero)),constant(N.Nat))});
 env.add({kind:'axiom',name:closedNat,levelParams:[],type:sort(levelSucc(levelZero))});
 const tc=new TypeChecker(env);throws(()=>tc.isDefEq(app(constant(N.LeanReduceNat),constant(closedNat)),natLit(0)));
});

test('projection-headed application reduces through a functional structure field',()=>{
 const env=baseEnv(),I=nameFromDotted('FnBox'),mk=nameFromDotted('FnBox.mk'),box=nameFromDotted('fnBoxValue'),fnTy=forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Nat));
 const ctorTy=forallE(nameFromDotted('fn'),fnTy,constant(I));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:mk,type:ctorTy}]}]});
 const k=new Kernel(env);k.addDefinition({kind:'definition',name:box,levelParams:[],type:constant(I),value:app(constant(mk),lam(nameFromDotted('x'),constant(N.Nat),bvar(0))),hints:{kind:'regular',height:1n},safety:'safe'});
 const projected={kind:'proj',typeName:I,index:0,expr:constant(box)} as const;
 eqExpr(new TypeChecker(env).whnf(app(projected,natLit(3))),natLit(3));
});

test('string-literal expansion requires direct level-free String.ofList',()=>{
 const tc=new TypeChecker(baseEnv()),lit=strLit('x');
 const wrongLevel=app(constant(N.StringOfList,[levelZero]),natLit(0));
 const overapplied=app(app(constant(N.StringOfList),natLit(0)),natLit(1));
 assert((tc as any).tryStringLitExpansionCore(lit,wrongLevel)===null,'universe-instantiated String.ofList must not trigger expansion');
 assert((tc as any).tryStringLitExpansionCore(lit,overapplied)===null,'overapplied String.ofList must not trigger expansion');
});

test('string literal projection reduces through String.ofList like Lean strLitProj',()=>{
 const env=new Environment(),one=levelSucc(levelZero),uN=nameFromDotted('u'),u=levelParam(uN),TU=sort(levelSucc(u));
 env.add({kind:'axiom',name:N.Char,levelParams:[],type:sort(one)});
 env.add({kind:'inductive',name:N.List,levelParams:[uN],type:forallE(nameFromDotted('α'),TU,TU,'implicit'),numParams:1,numIndices:0,all:[N.List],ctors:[N.ListNil,N.ListCons],numNested:0,isRec:true,isReflexive:false});
 const listU=(x:any)=>app(constant(N.List,[u]),x);
 env.add({kind:'constructor',name:N.ListNil,levelParams:[uN],type:forallE(nameFromDotted('α'),TU,listU(bvar(0)),'implicit'),induct:N.List,cidx:0,numParams:1,numFields:0});
 env.add({kind:'constructor',name:N.ListCons,levelParams:[uN],type:forallE(nameFromDotted('α'),TU,forallE(nameFromDotted('a'),bvar(0),forallE(nameFromDotted('as'),listU(bvar(1)),listU(bvar(2)))),'implicit'),induct:N.List,cidx:1,numParams:1,numFields:2});
 const listChar=app(constant(N.List,[levelZero]),constant(N.Char)),StringMk=nameFromDotted('String.mk');
 env.add({kind:'inductive',name:N.String,levelParams:[],type:sort(one),numParams:0,numIndices:0,all:[N.String],ctors:[StringMk],numNested:0,isRec:false,isReflexive:false});
 env.add({kind:'constructor',name:StringMk,levelParams:[],type:forallE(nameFromDotted('data'),listChar,constant(N.String)),induct:N.String,cidx:0,numParams:0,numFields:1});
 env.add({kind:'definition',name:N.StringOfList,levelParams:[],type:forallE(nameFromDotted('data'),listChar,constant(N.String)),value:lam(nameFromDotted('data'),listChar,app(constant(StringMk),bvar(0))),hints:{kind:'regular',height:1n},safety:'safe'});
 const got=new TypeChecker(env).whnf({kind:'proj',typeName:N.String,index:0,expr:strLit('')});
 eqExpr(got,mkAppN(constant(N.ListNil,[levelZero]),[constant(N.Char)]),'empty string projection must reduce through String.ofList to List.nil Char');
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

test('eta probe returns false instead of throwing for a non-function rhs',()=>{
 const tc=new TypeChecker(baseEnv()),lhs=lam(nameFromDotted('x'),constant(N.Nat),bvar(0));
 assert(!tc.isDefEq(lhs,natLit(0)),'Lean eta probing must treat a non-function rhs as simply not definitionally equal');
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

test('recursor reduction fails closed on universe arity mismatch',()=>{
 const env=baseEnv(),I=nameFromDotted('RecLevel.I'),C=nameFromDotted('RecLevel.I.mk'),R=nameFromDotted('RecLevel.I.rec'),uN=nameFromDotted('u');
 env.add({kind:'inductive',name:I,levelParams:[],type:sort(levelSucc(levelZero)),numParams:0,numIndices:0,all:[I],ctors:[C],numNested:0,isRec:false,isReflexive:false});
 env.add({kind:'constructor',name:C,levelParams:[],type:constant(I),induct:I,cidx:0,numParams:0,numFields:0});
 env.add({kind:'recursor',name:R,levelParams:[uN],type:forallE(nameFromDotted('t'),constant(I),constant(N.Nat)),all:[I],numParams:0,numIndices:0,numMotives:0,numMinors:0,rules:[{ctor:C,nFields:0,rhs:natLit(7)}],k:false});
 const bad=app(constant(R),constant(C)),good=app(constant(R,[levelZero]),constant(C)),tc=new TypeChecker(env);
 eqExpr(tc.whnf(bad),bad,'wrong recursor universe arity must remain stuck');
 eqExpr(tc.whnf(good),natLit(7),'correct recursor universe arity must still reduce');
});

test('recursor reduction converts String literals through String.ofList',()=>{
 const env=baseEnv(),R=nameFromDotted('String.testRec'),xsTy=constant(N.Nat);
 env.add({kind:'recursor',name:R,levelParams:[],type:forallE(nameFromDotted('s'),constant(N.String),constant(N.Nat)),all:[N.String],numParams:0,numIndices:0,numMotives:0,numMinors:0,k:false,rules:[{ctor:N.StringOfList,nFields:1,rhs:lam(nameFromDotted('xs'),xsTy,natLit(77))}]});
 eqExpr(new TypeChecker(env).whnf(app(constant(R),strLit('A🙂'))),natLit(77));
});

test('independent recursor validation rejects corrupted field-count metadata',()=>{
 const env=baseEnv(),I=nameFromDotted('RecValidate.Nat'),Z=nameFromDotted('RecValidate.Nat.zero'),S=nameFromDotted('RecValidate.Nat.succ');
 const decl={levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[
   {name:Z,type:constant(I)},
   {name:S,type:forallE(nameFromDotted('n'),constant(I),constant(I))}
 ]}]} as const;
 addOrdinaryInductive(env,decl);
 validateInstalledRecursorsByReduction(env,decl);

 const rn=nameFromDotted('RecValidate.Nat.rec'),ri=env.get(rn);assert(ri.kind==='recursor');
 const bad=new Environment();bad.quotInitialized=env.quotInitialized;
 for(const info of env.entries())if(nameToString(info.name)!==nameToString(rn))bad.add(info);
 bad.add({...ri,rules:ri.rules.map(r=>nameToString(r.ctor)===nameToString(S)?{...r,nFields:0}:r)});
 const stored=bad.get(rn);assert(stored.kind==='recursor');
 const checker=new TypeChecker(bad);for(const rule of stored.rules)checker.check(rule.rhs);
 throws(()=>validateInstalledRecursorsByReduction(bad,decl));
});

test('independent recursor validation rejects a well-typed under-applied minor rule',()=>{
 const env=baseEnv(),I=nameFromDotted('RecValidate.Under'),Z=nameFromDotted('RecValidate.Under.zero'),S=nameFromDotted('RecValidate.Under.succ');
 const decl={levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[
   {name:Z,type:constant(I)},
   {name:S,type:forallE(nameFromDotted('n'),constant(I),constant(I))}
 ]}]} as const;
 addOrdinaryInductive(env,decl);
 const rn=nameFromDotted('RecValidate.Under.rec'),ri=env.get(rn);assert(ri.kind==='recursor');
 const stripFinalApp=(e:any):any=>{
   if(e.kind==='lam')return {...e,body:stripFinalApp(e.body)};
   if(e.kind==='app')return e.fn;
   throw new Error('expected generated recursive rule to end in an application');
 };
 const bad=new Environment();bad.quotInitialized=env.quotInitialized;
 for(const info of env.entries())if(nameToString(info.name)!==nameToString(rn))bad.add(info);
 bad.add({...ri,rules:ri.rules.map(r=>nameToString(r.ctor)===nameToString(S)?{...r,rhs:stripFinalApp(r.rhs)}:r)});
 const stored=bad.get(rn);assert(stored.kind==='recursor');
 const checker=new TypeChecker(bad);
 for(const rule of stored.rules)checker.check(rule.rhs);
 throws(()=>validateInstalledRecursorsByReduction(bad,decl));
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
test('Quot bootstrap accepts alpha-renamed Eq.refl universe parameter like Lean 4.34',()=>{
 const env=new Environment(),eqU=nameFromDotted('eqU'),reflU=nameFromDotted('reflU');
 const arrow=(a:any,b:any)=>forallE(nameFromDotted('_'),a,b);
 const eqType=forallE(nameFromDotted('DifferentEqBinder'),sort(levelParam(eqU)),arrow(bvar(0),arrow(bvar(1),sort(levelZero))),'default');
 const reflType=forallE(nameFromDotted('DifferentReflBinder'),sort(levelParam(reflU)),
   forallE(nameFromDotted('DifferentValueBinder'),bvar(0),mkAppN(constant(N.Eq,[levelParam(reflU)]),[bvar(1),bvar(0),bvar(0)])),'strictImplicit');
 env.add({kind:'inductive',name:N.Eq,levelParams:[eqU],type:eqType,numParams:0,numIndices:0,all:[N.Eq],ctors:[N.EqRefl],numNested:0,isRec:false,isReflexive:false});
 env.add({kind:'constructor',name:N.EqRefl,levelParams:[reflU],type:reflType,induct:N.Eq,cidx:0,numParams:0,numFields:0});
 addQuot(env);assert(env.quotInitialized,'Eq/Eq.refl universe names and Pi binder metadata are ignored by the same structural equality used by Lean 4.34');
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


test('Quot recursors reject over-applied Quot.mk majors',()=>{
 const env=baseEnv(),one=levelSucc(levelZero);
 // Reduction only depends on quotient initialization and the primitive names; use
 // compact declarations here to exercise malformed reduction directly.
 env.quotInitialized=true;
 const alpha=constant(N.Nat),rel=lam(nameFromDotted('a'),alpha,lam(nameFromDotted('b'),alpha,sort(levelZero)));
 const q=mkAppN(constant(N.QuotMk,[one]),[alpha,rel,natLit(3),natLit(99)]);
 const lift=mkAppN(constant(N.QuotLift,[one,one]),[alpha,rel,alpha,lam(nameFromDotted('x'),alpha,bvar(0)),constant(N.BoolTrue),q]);
 const ind=mkAppN(constant(N.QuotInd,[one]),[alpha,rel,lam(nameFromDotted('_'),alpha,sort(levelZero)),lam(nameFromDotted('x'),alpha,constant(N.BoolTrue)),q]);
 const tc=new TypeChecker(env);
 eqExpr(tc.whnf(lift),lift,'Quot.lift must not reduce an over-applied Quot.mk');
 eqExpr(tc.whnf(ind),ind,'Quot.ind must not reduce an over-applied Quot.mk');
});

test('Quot bootstrap rejects occupied primitive names without overwriting them',()=>{
 const env=baseEnv(),uN=nameFromDotted('u'),u=levelParam(uN),anon=nameFromDotted('_');const arrow=(a:any,b:any)=>forallE(anon,a,b);
 const eqTy=forallE(nameFromDotted('α'),sort(u),arrow(bvar(0),arrow(bvar(1),sort(levelZero))),'implicit');
 const reflTy=forallE(nameFromDotted('α'),sort(u),forallE(nameFromDotted('a'),bvar(0),app(app(app(constant(N.Eq,[u]),bvar(1)),bvar(0)),bvar(0))),'implicit');
 env.add({kind:'inductive',name:N.Eq,levelParams:[uN],type:eqTy,numParams:2,numIndices:1,all:[N.Eq],ctors:[N.EqRefl],numNested:0,isRec:false,isReflexive:false});
 env.add({kind:'constructor',name:N.EqRefl,levelParams:[uN],type:reflTy,induct:N.Eq,cidx:0,numParams:2,numFields:0});
 const plantedType=sort(levelZero);env.add({kind:'axiom',name:N.QuotLift,levelParams:[],type:plantedType});
 throws(()=>addQuot(env));
 assert(!env.quotInitialized,'failed quotient initialization must not flip the initialized flag');
 const planted=env.get(N.QuotLift);assert(planted.kind==='axiom'&&exprEq(planted.type,plantedType),'pre-existing Quot.lift must not be overwritten');
 assert(!env.has(N.Quot)&&!env.has(N.QuotMk)&&!env.has(N.QuotInd),'quotient bootstrap must reject collisions before inserting any primitive');
});

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

test('public ordinary admission rejects reserved _nested references but not sibling prefixes',()=>{
 const env=baseEnv(),I=nameFromDotted('ReservedOrdinary'),Mk=nameFromDotted('ReservedOrdinary.mk'),aux=nameFromDotted('_nested.KNHost_1');
 const badTy=forallE(nameFromDotted('x'),constant(aux),constant(I));
 throws(()=>addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:Mk,type:badTy}]}]}));
 assert(!env.has(I)&&!env.has(Mk),'public ordinary admission must reject reserved nested auxiliaries transactionally');

 const okEnv=baseEnv(),Payload=nameFromDotted('_nestedX.Payload'),DotPayload=strName(nameFromDotted(''),'_nested.fake'),J=nameFromDotted('ReservedSibling'),JMk=nameFromDotted('ReservedSibling.mk');
 okEnv.add({kind:'axiom',name:Payload,levelParams:[],type:sort(levelSucc(levelZero))});
 okEnv.add({kind:'axiom',name:DotPayload,levelParams:[],type:sort(levelSucc(levelZero))});
 const goodTy=forallE(nameFromDotted('x'),constant(Payload),forallE(nameFromDotted('y'),constant(DotPayload),constant(J)));
 addOrdinaryInductive(okEnv,{levelParams:[],numParams:0,types:[{name:J,type:sort(levelSucc(levelZero)),ctors:[{name:JMk,type:goodTy}]}]});
 assert(okEnv.has(J)&&okEnv.has(JMk),'only structural _nested descendants are reserved; _nestedX and a single string component containing a dot remain legal');
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



import { addPrimitiveDefinition, addPrimitiveInductive, addPrimitiveOpaque, canonicalNatAddValue } from '../src/kernel/primitive.js';
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
 const lctx=new LocalContext(),id=lctx.fresh('n');lctx.addLocal(id,nameFromDotted('n'),constant(N.Nat));const n=fvar(id),tc=new TypeChecker(env,lctx);
 assert(tc.isDefEq(app(app(constant(N.NatMod),natLit(0)),n),natLit(0)),'Lean nat_mod_defeq: 0 % n must reduce definitionally to 0 for a variable divisor');
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
 assert(tc.state.whnfCore.has(beta),'full beta WHNF should cache the original expression');

 const tc2=new TypeChecker(env);
 const motive=lam(nameFromDotted('_'),constant(N.Nat),constant(N.Nat));
 const step=lam(nameFromDotted('_n'),constant(N.Nat),lam(nameFromDotted('ih'),constant(N.Nat),bvar(0)));
 const rec=mkAppN(constant(nameFromDotted('Nat.rec'),[one]),[motive,natLit(17),step,constant(N.NatZero)]);
 eqExpr(tc2.whnfCore(rec),natLit(17));
 assert(!tc2.state.whnfCore.has(rec),'Lean 4.34 returns directly after recursor iota instead of caching the original recursor application');
});

test('whnfCore easy, stuck-app, and projection cache boundaries match Lean 4.34',()=>{
 const env=baseEnv(),F=nameFromDotted('WhnfBoundary.f'),D=nameFromDotted('WhnfBoundary.d'),Fake=nameFromDotted('WhnfBoundary.Fake');
 env.add({kind:'axiom',name:F,levelParams:[],type:forallE(nameFromDotted('x'),constant(N.Nat),constant(N.Nat))});
 env.add({kind:'definition',name:D,levelParams:[],type:constant(N.Nat),value:natLit(3),hints:{kind:'regular',height:1n},safety:'safe'});
 const tc=new TypeChecker(env),easy=constant(F),stuck=app(easy,natLit(1)),proj={kind:'proj',typeName:Fake,index:0,expr:constant(D)} as const;
 eqExpr(tc.whnfCore(easy),easy);
 assert(!tc.state.whnfCore.has(easy),'easy whnfCore cases bypass the cache');
 eqExpr(tc.whnfCore(stuck),stuck);
 assert(!tc.state.whnfCore.has(stuck),'stuck applications return directly without whnfCore caching');
 eqExpr(tc.whnfCore(proj),proj);
 assert(tc.state.whnfCore.has(proj),'unreduced projections are cached as the original projection node');
});

test('cheap projection WHNF never reuses a full-mode cache entry',()=>{
 const env=baseEnv(),I=nameFromDotted('CheapProjBox'),Mk=nameFromDotted('CheapProjBox.mk'),box=nameFromDotted('cheapProjBoxValue');
 const ctorTy=forallE(nameFromDotted('field'),constant(N.Nat),constant(I));
 addOrdinaryInductive(env,{levelParams:[],numParams:0,types:[{name:I,type:sort(levelSucc(levelZero)),ctors:[{name:Mk,type:ctorTy}]}]});
 const k=new Kernel(env);k.addDefinition({kind:'definition',name:box,levelParams:[],type:constant(I),value:app(constant(Mk),natLit(7)),hints:{kind:'regular',height:1n},safety:'safe'});
 const proj={kind:'proj',typeName:I,index:0,expr:constant(box)} as const,tc=new TypeChecker(env);
 eqExpr(tc.whnfCore(proj,false,false),natLit(7));
 assert(tc.state.whnfCore.has(proj),'full projection WHNF should cache its reduced field');
 const cheap=tc.whnfCore(proj,false,true);
 assert(cheap.kind==='proj'&&exprEq(cheap.expr,constant(box)),'cheap projection WHNF must ignore the full-mode cache and leave the hidden structure opaque');
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

test('eagerReduce primitive admission locks the polymorphic identity semantics',()=>{
 const env=new Environment(),u=nameFromDotted('u'),alpha=nameFromDotted('α'),a=nameFromDotted('a');
 const ty=forallE(alpha,sort(levelParam(u)),forallE(a,bvar(0),bvar(1),'default'),'implicit');
 const good=lam(alpha,sort(levelParam(u)),lam(a,bvar(0),bvar(0),'default'),'implicit');
 addPrimitiveDefinition(env,{kind:'definition',name:N.EagerReduce,levelParams:[u],type:ty,value:good,hints:{kind:'regular',height:1n},safety:'safe'});
 assert(env.has(N.EagerReduce));
 const badEnv=new Environment(),bad=lam(alpha,sort(levelParam(u)),lam(a,bvar(0),bvar(1),'default'),'implicit');
 throws(()=>addPrimitiveDefinition(badEnv,{kind:'definition',name:N.EagerReduce,levelParams:[u],type:ty,value:bad,hints:{kind:'regular',height:1n},safety:'safe'}));
 assert(!badEnv.has(N.EagerReduce));
});

test('native reduction marker opaques require canonical Bool/Nat endofunction types',()=>{
 const env=baseEnv(),n=nameFromDotted('n'),b=nameFromDotted('b');
 addPrimitiveOpaque(env,{kind:'opaque',name:N.LeanReduceNat,levelParams:[],type:forallE(n,constant(N.Nat),constant(N.Nat)),value:lam(n,constant(N.Nat),bvar(0)),isUnsafe:false});
 addPrimitiveOpaque(env,{kind:'opaque',name:N.LeanReduceBool,levelParams:[],type:forallE(b,constant(N.Bool),constant(N.Bool)),value:lam(b,constant(N.Bool),bvar(0)),isUnsafe:false});
 assert(env.has(N.LeanReduceNat)&&env.has(N.LeanReduceBool));
 const bad=baseEnv();
 throws(()=>addPrimitiveOpaque(bad,{kind:'opaque',name:N.LeanReduceNat,levelParams:[],type:forallE(b,constant(N.Bool),constant(N.Bool)),value:lam(b,constant(N.Bool),bvar(0)),isUnsafe:false}));
 assert(!bad.has(N.LeanReduceNat));
 const ordinary=baseEnv();
 throws(()=>new Kernel(ordinary).addOpaque({kind:'opaque',name:N.LeanReduceNat,levelParams:[],type:forallE(n,constant(N.Nat),constant(N.Nat)),value:lam(n,constant(N.Nat),bvar(0)),isUnsafe:false}));
 assert(!ordinary.has(N.LeanReduceNat));
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

test('Char.ofNat follows ordinary declaration admission like Lean 4.34',()=>{
 const env=primitiveNatEnv(),char0=nameFromDotted('char0');env.add({kind:'axiom',name:N.Char,levelParams:[],type:sort(levelSucc(levelZero))});env.add({kind:'axiom',name:char0,levelParams:[],type:constant(N.Char)});
 const ty=forallE(nameFromDotted('n'),constant(N.Nat),constant(N.Char)),value=lam(nameFromDotted('n'),constant(N.Nat),constant(char0));
 const info={kind:'definition' as const,name:N.CharOfNat,levelParams:[],type:ty,value,hints:{kind:'regular' as const,height:1n},safety:'safe' as const};
 throws(()=>addPrimitiveDefinition(env,info));
 new Kernel(env).addDefinition(info);
 assert(env.has(N.CharOfNat),'Char.ofNat must be admitted through the ordinary definition path');
});

test('String.ofList follows ordinary declaration admission without synthetic Char.ofNat dependency',()=>{
 const env=new Environment(),one=levelSucc(levelZero),uN=nameFromDotted('u'),u=levelParam(uN),TU=sort(levelSucc(u));
 env.add({kind:'axiom',name:N.Char,levelParams:[],type:sort(one)});env.add({kind:'axiom',name:N.String,levelParams:[],type:sort(one)});
 const listTy=forallE(nameFromDotted('α'),TU,TU,'implicit');env.add({kind:'axiom',name:N.List,levelParams:[uN],type:listTy});
 const listChar=app(constant(N.List,[levelZero]),constant(N.Char)),empty=nameFromDotted('emptyString');env.add({kind:'axiom',name:empty,levelParams:[],type:constant(N.String)});
 const ty=forallE(nameFromDotted('xs'),listChar,constant(N.String)),value=lam(nameFromDotted('xs'),listChar,constant(empty));
 const info={kind:'definition' as const,name:N.StringOfList,levelParams:[],type:ty,value,hints:{kind:'regular' as const,height:1n},safety:'safe' as const};
 throws(()=>addPrimitiveDefinition(env,info));
 new Kernel(env).addDefinition(info);
 assert(env.has(N.StringOfList),'String.ofList must not require Char.ofNat merely for declaration admission');
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

test('lean4export preserves raw max and imax level syntax',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"u"}}',
  '{"in":2,"str":{"pre":0,"str":"RawMax"}}',
  '{"in":3,"str":{"pre":0,"str":"RawIMax"}}',
  '{"il":1,"param":1}',
  '{"il":2,"max":[0,1]}',
  '{"il":3,"imax":[0,1]}',
  '{"ie":0,"sort":2}',
  '{"ie":1,"sort":3}',
  '{"axiom":{"name":2,"levelParams":[1],"type":0,"isUnsafe":false}}',
  '{"axiom":{"name":3,"levelParams":[1],"type":1,"isUnsafe":false}}'
 ].join('\n');
 const r=new Lean4ExportReplay(),st=r.replay(nd);
 assert(st.declarations===2);
 const a=r.env.get(nameFromDotted('RawMax')),b=r.env.get(nameFromDotted('RawIMax'));
 assert(a.type.kind==='sort'&&a.type.level.kind==='max','raw exported Level.max must not be simplified during replay');
 assert(b.type.kind==='sort'&&b.type.level.kind==='imax','raw exported Level.imax must not be simplified during replay');
});

test('lean4export replay admits a version-pinned axiom stream',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"A"}}',
  '{"il":1,"succ":0}',
  '{"ie":0,"sort":1}',
  '{"axiom":{"name":1,"levelParams":[],"type":0,"isUnsafe":false}}'
 ].join('\n');
 const r=new Lean4ExportReplay(),st=r.replay(nd);assert(st.declarations===1&&r.env.has(nameFromDotted('A')));assert(st.names===1&&st.levels===1&&st.expressions===1);
});



test('lean4export incremental line replay matches bulk replay',()=>{
 const lines=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
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

test('lean4export rejects wrong generated constructor and recursor universe metadata',()=>{
 const badCtor=lean434RealProbe.replace(
   '"levelParams":[],"name":6,"numFields":0',
   '"levelParams":[15],"name":6,"numFields":0'
 );
 assert(badCtor!==lean434RealProbe,'constructor mutation fixture marker must exist');
 throws(()=>new Lean4ExportReplay().replay(badCtor));

 const badRec=lean434RealProbe.replace(
   '"levelParams":[15],"name":23,"numIndices":0',
   '"levelParams":[],"name":23,"numIndices":0'
 );
 assert(badRec!==lean434RealProbe,'recursor mutation fixture marker must exist');
 throws(()=>new Lean4ExportReplay().replay(badRec));
});

test('lean4export treats safe DefinitionVal.all as informational, not a mutual kernel block',()=>{
 const meta='{"meta":{"exporter":{"name":"handcrafted","version":"0.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}';
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
 throws(()=>new Lean4ExportReplay().replay([...pre,a,b].join('\n')));
 const r=new Lean4ExportReplay();r.replay([...pre,b,a].join('\n'));
 assert(r.env.has(nameFromDotted('SafeAllA'))&&r.env.has(nameFromDotted('SafeAllB')),'dependency-first safe definitions must replay even when informational all metadata omits self or is empty');
});

test('lean4export reconstructs partial mutual definition blocks from all metadata',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"A"}}','{"in":2,"str":{"pre":0,"str":"B"}}',
  '{"ie":0,"sort":0}','{"ie":1,"const":{"name":1,"us":[]}}','{"ie":2,"const":{"name":2,"us":[]}}',
  '{"def":{"name":2,"levelParams":[],"type":0,"value":1,"hints":{"regular":1},"safety":"partial","all":[1,2]}}',
  '{"def":{"name":1,"levelParams":[],"type":0,"value":2,"hints":{"regular":1},"safety":"partial","all":[1,2]}}'
 ].join('\n');
 const r=new Lean4ExportReplay(),st=r.replay(nd);assert(st.declarations===2&&r.env.has(nameFromDotted('A'))&&r.env.has(nameFromDotted('B')));
});

test('lean4export rejects an incomplete mutual definition group',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"A"}}','{"in":2,"str":{"pre":0,"str":"B"}}',
  '{"ie":0,"sort":0}','{"ie":1,"const":{"name":1,"us":[]}}',
  '{"def":{"name":1,"levelParams":[],"type":0,"value":1,"hints":{"regular":1},"safety":"partial","all":[1,2]}}'
 ].join('\n');throws(()=>new Lean4ExportReplay().replay(nd));
});

test('kernel metadata equivalence matches Lean Expr BEq used by replay',()=>{
 const a=forallE(nameFromDotted('a'),sort(levelZero),bvar(0),'default');
 const renamedImplicit=forallE(nameFromDotted('x'),sort(levelZero),bvar(0),'implicit');
 assert(exprKernelMetadataEq(a,renamedImplicit),'Lean Expr BEq ignores binder names and annotations');
 const mdA={kind:'mdata',data:{tag:'a'},expr:a} as const;
 const mdSame={kind:'mdata',data:{tag:'a'},expr:renamedImplicit} as const;
 const mdDiff={kind:'mdata',data:{tag:'b'},expr:renamedImplicit} as const;
 assert(exprKernelMetadataEq(mdA,mdSame),'equal mdata payloads must preserve alpha-equivalence');
 assert(!exprKernelMetadataEq(mdA,a),'Lean Expr BEq observes mdata placement');
 assert(!exprKernelMetadataEq(mdA,mdDiff),'Lean Expr BEq observes mdata payloads');
});

test('lean4export replay accepts sparse and out-of-order intern indices',()=>{
 const meta='{"meta":{"exporter":{"name":"handcrafted","version":"0.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}';
 const sparse=[meta,'{"in":2,"str":{"pre":0,"str":"foo"}}','{"ie":4,"sort":0}','{"axiom":{"isUnsafe":false,"levelParams":[],"name":2,"type":4}}'].join('\n');
 const a=new Lean4ExportReplay();a.replay(sparse);assert(a.env.entries().length===1);
 const outOfOrder=[meta,'{"in":1,"str":{"pre":0,"str":"foo"}}','{"il":2,"succ":0}','{"il":1,"succ":2}','{"ie":0,"sort":1}','{"axiom":{"isUnsafe":false,"levelParams":[],"name":1,"type":0}}'].join('\n');
 const b=new Lean4ExportReplay();b.replay(outOfOrder);assert(b.env.entries().length===1);
 const duplicate=[meta,'{"in":2,"str":{"pre":0,"str":"foo"}}','{"in":2,"str":{"pre":0,"str":"bar"}}'].join('\n');
 throws(()=>new Lean4ExportReplay().replay(duplicate));
});

test('lean4export rejects negative Nat literals at the wire boundary',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"ie":0,"natVal":"-1"}'
 ].join('\n');
 throws(()=>new Lean4ExportReplay().replay(nd));
});

test('lean4export rejects projection indices above UInt32 before number conversion',()=>{
 const nd=[
  '{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"S"}}',
  '{"ie":0,"proj":{"typeName":1,"idx":4294967296,"struct":999}}'
 ].join('\n');
 throws(()=>new Lean4ExportReplay().replay(nd));
});

test('lean4export replay rejects version drift before declarations',()=>{
 const nd='{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.33.0"},"format":{"version":"3.1.0"}}}';throws(()=>new Lean4ExportReplay().replay(nd));
});
test('lean4export replay rejects git-hash drift before declarations',()=>{
 const nd='{"meta":{"exporter":{"name":"lean4export","version":"3.1.0"},"lean":{"githash":"0000000000000000000000000000000000000000","version":"4.34.0"},"format":{"version":"3.1.0"}}}';throws(()=>new Lean4ExportReplay().replay(nd));
});

console.log(`# pass ${pass}`);console.log(`# fail ${fail}`);if(fail)throw new Error(`${fail} tests failed`);
