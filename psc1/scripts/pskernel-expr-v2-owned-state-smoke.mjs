import {pathToFileURL} from "node:url";
import path from "node:path";

// Diagnostic marker hashes are outside the valid hash modulus. They cannot
// produce a semantic cache hit; they observe complete state transport only.
// The separate V1 matrix uses genuine expressions and checked declarations.
const filename=process.argv[2];
if(!filename)throw Error("PSC1_OWNED_STATE_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_OWNED_STATE_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_OWNED_STATE_FAIL "+label);assertions++;};
const accepted=(x,label)=>{
 if(x&&typeof x==="object"&&Object.hasOwn(x,"value"))return x.value;
 throw Error("PSC1_OWNED_STATE_UNEXPECTED_REJECTION "+label);
};
const rejected=x=>Boolean(x&&typeof x==="object"&&Object.hasOwn(x,"error"));
const same=(left,right)=>{
 if(left===right)return true;
 if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
 const keys=Reflect.ownKeys(left),others=Reflect.ownKeys(right);
 return keys.length===others.length&&keys.every(key=>Object.hasOwn(right,key)&&same(left[key],right[key]));
};
const List=get("List"),nil=unit(List.nil),Option=get("Option"),none=unit(Option.none),Ex=get("Except");
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(xs&&Object.hasOwn(xs,"head")){out.push(xs.head);xs=xs.tail;}return out;};
const attempt=(x,label)=>accepted(accepted(x,label+"-some"),label+"-ok");
const ok=(state,value)=>Option.some(Ex.ok({fst:state,snd:value}));
const error=message=>Option.some(Ex.error(message));
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),S=get("PsKernelDefinitionSafety");
const Request=get("PsKernelDeclarationRequest"),D=get("PsKernelDagDeclarationRequest"),C=get("PsKernelDagCommand");
const name=text=>N.str(unit(N.anonymous),text),one=L.succ(unit(L.zero));
const exact=(left,right)=>get("psKernelExprEqual")(left)(right);
const modulus=BigInt(get("psKernelCacheHashModulus"));
const markerHash=tag=>modulus+tag;
const cacheMark=(rows,tag)=>{const a=array(rows);return a.length===1&&BigInt(a[0].hash)===markerHash(tag);};
const outerMark=(state,tag,fresh)=>state.nextFresh===fresh&&
 cacheMark(state.checkedInfer,tag)&&cacheMark(state.success,tag)&&
 cacheMark(state.inferOnly,tag)&&cacheMark(state.unfold,tag)&&cacheMark(state.failure,tag);
const stamp=(key,state,tag)=>{
 const built=accepted(get("psKernelExprV2PagedMkLit")(state.whnf.arena,Literal.nat(9000n+tag)),"stamp-build");
 const cache={source:key,result:key,hash:markerHash(tag)},pair={left:key,right:key,hash:markerHash(tag)};
 const whnf={arena:built.fst,coreCache:List.cons(cache,state.whnf.coreCache),
  publicCache:List.cons(cache,state.whnf.publicCache),declarations:state.whnf.declarations};
 return {whnf,nextFresh:tag,checkedInfer:list([cache]),success:list([pair]),
  inferOnly:list([cache]),unfold:list([cache]),failure:list([pair])};
};
const advance=(key,state,tag,fresh,next)=>
 outerMark(state,tag,fresh)?Ex.ok(stamp(key,state,next)):Ex.error("carrier callback received stale state");
const whnfStep=(key,tag,fresh,next,result)=>_context=>state=>_root=>{
 const updated=advance(key,state,tag,fresh,next);
 return rejected(updated)?Option.some(updated):ok(updated.value,result);
};
const decode=(state,root)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(state.whnf.arena),"decode"),root),"decoded-root");
const marked=(label,tag,fresh,value)=>{
 const result=attempt(value,label);
 must(outerMark(result.fst,tag,fresh),label+"-all-six-outer-fields");
 must(array(result.fst.whnf.coreCache).some(entry=>BigInt(entry.hash)===markerHash(tag)),label+"-core-marker");
 must(array(result.fst.whnf.publicCache).some(entry=>BigInt(entry.hash)===markerHash(tag)),label+"-public-marker");
 must(!same(get("psKernelExprV2DeclarationRefFind")(result.fst.whnf.declarations)(
  get("psKernelSimpleRecName")(get("psKernelNatName"))),none),label+"-declaration-owner");
 accepted(get("psKernelExprV2PagedValidate")(result.fst.whnf.arena),label+"-valid-arena");
 accepted(get("psKernelExprV2PagedRequire")(result.fst.whnf.arena,result.snd),label+"-owned-result");
 return result;
};
const reduction=value=>{
 if(same(value,none))return none;
 const result=accepted(value,"reduction-some");
 if(rejected(result))return Option.some(result);
 const pair=accepted(result,"reduction-ok");
 return same(pair.snd,none)?error("carrier expected reduction"):ok(pair.fst,accepted(pair.snd,"reduction-root"));
};
const compareWhnf=(label,original,observed)=>{
 const value=accepted(observed,label+"-owned");
 if(rejected(original)){
  must(rejected(value)&&value.error===original.error,label+"-exact-error");return;
 }
 const expected=accepted(original,label+"-reference"),actual=accepted(value,label+"-result");
 must(exact(expected.fst,decode(actual.fst,actual.snd)),label+"-expression");
};
const propagation=(label,declined,value)=>{
 if(same(value,none)){must(declined,label+"-outer-None");return;}
 const result=accepted(value,label+"-some");
 must(!declined&&rejected(result)&&result.error==="carrier injected",label+"-exact-propagation");
};
const errorIs=(label,message,value)=>{
 const result=accepted(value,label+"-some");
 must(rejected(result)&&result.error===message,label);
};

let arena=unit(get("psKernelExprV2PagedEmpty"));
const build=(kind,term,...args)=>{
 const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
 arena=result.fst;return {term,id:result.snd};
};
const sort=level=>build("Sort",E.sort(level),level);
const cn=(n,levels=[])=>build("Const",E.const(n,list(levels)),n,list(levels));
const lit=n=>build("Lit",E.lit(Literal.nat(n)),Literal.nat(n));
const fv=n=>build("FVar",E.fvar(name(n)),name(n));
const bv=n=>build("BVar",E.bvar(n),n);
const md=(tag,x)=>build("MData",E.mdata(tag,x.term),tag,x.id);
const app=(f,a)=>build("App",E.app(f.term,a.term),f.id,a.id);
const apps=(f,args)=>args.reduce((x,y)=>app(x,y),f);
const lam=(n,t,b)=>build("Lam",E.lam(name(n),t.term,b.term,unit(B.default)),name(n),t.id,b.id,unit(B.default));
const forall=(n,t,b)=>build("Forall",E.forallE(name(n),t.term,b.term,unit(B.default)),name(n),t.id,b.id,unit(B.default));
const letE=(n,t,v,b)=>build("Let",E.letE(name(n),t.term,v.term,b.term,false),name(n),t.id,v.id,b.id,false);
const proj=(n,index,value)=>build("Proj",E.proj(n,index,value.term),n,index,value.id);
const s0=sort(unit(L.zero)),s1=sort(one),natName=get("psKernelNatName"),nat=cn(natName);
const succType=forall("n",nat,nat),universe=name("u");
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty");
const natDecl={levelParams:nil,name:natName,type:s1.term,
 ctors:list([{name:get("psKernelNatZeroName"),type:nat.term},
  {name:get("psKernelNatSuccName"),type:succType.term}]),isUnsafe:false,numParams:0n};
const withNat=accepted(get("psKernelV1AdmitDeclaration")(empty,Request.ordinaryInductive(natDecl)),"checked-Nat");
const eqDecl={levelParams:list([universe]),name:get("psKernelEqName"),
 type:get("psKernelExpectedEqType")(universe),
 ctors:list([{name:N.str(get("psKernelEqName"),"refl"),type:get("psKernelExpectedEqReflType")(universe)}]),
 isUnsafe:false,numParams:2n};
const withEq=accepted(get("psKernelV1AdmitDeclaration")(withNat.session,Request.ordinaryInductive(eqDecl)),"checked-Eq");
const session=accepted(get("psKernelV1AdmitDeclaration")(withEq.session,unit(Request.quot)),"checked-Quot").session;
const scalar=get("psKernelKernelSessionChecker")(session,nil,unit(S.safe)).context;
const request=D.ordinaryInductive(nil,0n,{name:natName,type:s1.id,
 ctors:list([{name:get("psKernelNatZeroName"),type:nat.id},
  {name:get("psKernelNatSuccName"),type:succType.id}])},false);
const zero=lit(0n),oneLit=lit(1n),two=lit(2n),wrappedSort=md(61n,s0);
const aType=fv("A"),aValue=fv("a"),fn=fv("f"),bound=bv(0n);
const fnType=forall("x",aType,aType),wrappedFn=md(62n,fnType),application=app(fn,aValue);
const lambda=lam("x",aType,bound),forallType=forall("x",aType,aType);
const letTerm=letE("x",aType,aValue,bound),dependentForall=forall("x",nat,bound);
const relation=apps(cn(get("psKernelEqName"),[one]),[nat]),identity=lam("x",nat,bound);
const respect=lam("a",nat,lam("b",nat,lam("h",apps(relation,[bv(1n),bound]),bound)));
const quotientMajor=apps(cn(get("psKernelQuotMkName"),[one]),[nat,relation,zero]);
const quotientLift=apps(cn(get("psKernelQuotLiftName"),[one,one]),[nat,relation,nat,identity,respect,quotientMajor]);
const recursorName=get("psKernelSimpleRecName")(natName);
const recursor=apps(cn(recursorName,[one]),[lam("n",nat,nat),two,lam("n",nat,lam("ih",nat,bound)),zero]);
const projectionMajor=app(cn(get("psKernelNatSuccName")),oneLit),projection=proj(natName,0n,projectionMajor);
const differential=[
 ["metadata",md(71n,s0)],["beta",app(identity,oneLit)],
 ["zeta",letE("x",nat,two,bound)],
 ["nat",apps(cn(N.str(natName,"add")),[oneLit,two])],
 ["quot",quotientLift],["iota",recursor]
];
const input=arena,built=accepted(get("psKernelExprV2DecodeChecked")(input),"input-decode");
const declarations=get("psKernelDagDeclarationsAfterAdmission")(request,nil);
const generated=accepted(get("psKernelDagGeneratedAfterCommand")(C.admit(request),session.environment,
 {arena:input,built,declarations}),"install-checked-generated");
const initial=get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(generated.arena),
 get("psKernelExprV2WhnfStateForDeclarations")(generated.arena,generated.declarations));
const bare=get("psKernelExprV2CheckContextEmpty")(scalar);
let context=get("psKernelExprV2CheckContextWithLocal")(bare,name("A"),name("A"),wrappedSort.id,unit(B.default));
context=get("psKernelExprV2CheckContextWithLocal")(context,name("a"),name("a"),aType.id,unit(B.default));
context=get("psKernelExprV2CheckContextWithLocal")(context,name("f"),name("f"),wrappedFn.id,unit(B.default));
const forbidden=_c=>_s=>_r=>error("unexpected carrier callback");
const forbiddenEq=_c=>_s=>_l=>_r=>error("unexpected carrier DefEq callback");
const noCore=_c=>_s=>_r=>_cheapRec=>_cheapProj=>error("unexpected carrier core callback");
const localValue=c=>n=>get("psKernelExprV2CheckLocalValue")(c,n);
const infer=(fuel,whnf,defeq,c,s,r,only)=>
 get("psKernelExprV2TryInferCoreOwnedWithFuel")(fuel)(whnf)(defeq)(c)(s)(r)(only);
const publicWith=(fuel,reducer,c,s,r)=>
 get("psKernelExprV2TryWhnfOwnedWithReducerFuel")(fuel)(reducer)(localValue)(c)(s)(r);
const coreWith=(fuel,cheapRec,cheapProj,whnf,reducer,c,s,r)=>
 get("psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel")(fuel)(cheapRec)(cheapProj)(
  localValue)(whnf)(reducer)(c)(s)(r);
let probes=0,propagated=0,comparisons=0;
for(const seed of [2n,11n]){
 const state=stamp(zero.id,initial,seed);
 const first=result=>whnfStep(zero.id,seed,seed,seed+1n,result);
 const second=result=>whnfStep(zero.id,seed+1n,seed+1n,seed+2n,result);
 const natSucc=marked("nat-successor",seed+1n,seed+1n,reduction(
  get("psKernelExprV2TryReduceNatSuccOwnedWith")(first(oneLit.id),context,state,oneLit.id)));
 must(exact(decode(natSucc.fst,natSucc.snd),E.lit(Literal.nat(2n))),"nat-successor-value");probes++;
 const binary=c=>s=>r=>r===oneLit.id?first(oneLit.id)(c)(s)(r):
  r===two.id?second(two.id)(c)(s)(r):error("unexpected Nat operand");
 const natBinary=marked("nat-binary-second-sees-first",seed+2n,seed+2n,reduction(
  get("psKernelExprV2TryReduceNatBinaryOwnedWith")(binary,context,state,N.str(natName,"add"),oneLit.id,two.id)));
 must(exact(decode(natBinary.fst,natBinary.snd),E.lit(Literal.nat(3n))),"nat-binary-value");probes++;
 marked("quot-major-state",seed+1n,seed+1n,reduction(
  get("psKernelExprV2TryReduceQuotOwnedWith")(first(quotientMajor.id),context,state,quotientLift.id)));probes++;
 marked("recursor-public-major",seed+1n,seed+1n,reduction(
  get("psKernelExprV2TryReduceRecursorOwnedWith")(
   first(zero.id),noCore,forbidden,forbiddenEq,context,state,recursor.id,false,false)));probes++;
 const cheapCore=c=>s=>r=>cheapRec=>cheapProj=>cheapRec&&cheapProj?
  first(zero.id)(c)(s)(r):error("recursor flags were changed");
 marked("recursor-cheap-major",seed+1n,seed+1n,reduction(
  get("psKernelExprV2TryReduceRecursorOwnedWith")(
   forbidden,cheapCore,forbidden,forbiddenEq,context,state,recursor.id,true,true)));probes++;
 const projected=marked("projection-selected-state",seed+2n,seed+2n,
  get("psKernelExprV2TryWhnfProjectionOwnedWith")(second(oneLit.id),first(projectionMajor.id),
   context,state,projection.id,natName,0n,projectionMajor.id,false));
 must(exact(decode(projected.fst,projected.snd),E.lit(Literal.nat(1n))),"projection-field");probes++;
 const recurse=c=>s=>r=>r===fn.id?first(fn.id)(c)(s)(r):r===zero.id?
  whnfStep(zero.id,seed+2n,seed+2n,seed+3n,zero.id)(c)(s)(r):
  error("application recursion order changed");
 const reduced=_c=>s=>r=>cheapRec=>cheapProj=>{
  if(r!==application.id||cheapRec||cheapProj)return error("application reducer flags changed");
  const updated=advance(zero.id,s,seed+1n,seed+1n,seed+2n);
  return rejected(updated)?Option.some(updated):ok(updated.value,Option.some(zero.id));
 };
 marked("app-function-reducer-result-chain",seed+3n,seed+3n,
  get("psKernelExprV2TryWhnfAppOwnedWithReducer")(recurse,reduced,context,state,application.id,false,false));probes++;
 const rootReducer=_c=>s=>r=>cheapRec=>cheapProj=>{
  if(r!==application.id||cheapRec||cheapProj)return error("root reducer arguments changed");
  const updated=advance(zero.id,s,seed,seed,seed+1n);
  return rejected(updated)?Option.some(updated):ok(updated.value,Option.some(zero.id));
 };
 marked("whole-public-reducer-state",seed+1n,seed+1n,publicWith(8n,rootReducer,context,state,application.id));probes++;
 marked("whole-core-reducer-state",seed+1n,seed+1n,
  coreWith(8n,false,false,forbidden,rootReducer,context,state,application.id));probes++;
 const sorted=attempt(get("psKernelExprV2CheckEnsureSortOwnedWith")(
  first(s0.id),context,state,wrappedSort.id),"ensure-sort");
 must(get("psKernelLevelNormalizesToZero")(sorted.snd),"ensure-sort-universe");
 marked("ensure-sort-state",seed+1n,seed+1n,ok(sorted.fst,s0.id));probes++;
 const functionType=attempt(get("psKernelExprV2CheckEnsureForallOwnedWith")(
  first(fnType.id),context,state,wrappedFn.id),"ensure-forall");
 must(functionType.snd.domain===aType.id,"ensure-forall-domain");
 marked("ensure-forall-state",seed+1n,seed+1n,ok(functionType.fst,functionType.snd.body));probes++;
 const typedWhnf=c=>s=>r=>r===wrappedSort.id?first(s0.id)(c)(s)(r):
  r===wrappedFn.id?first(fnType.id)(c)(s)(r):error("unexpected typed WHNF root");
 const lambdaResult=marked("inference-lambda-restores-updated-parent",seed+1n,seed+2n,
  infer(8n,typedWhnf,forbiddenEq,context,state,lambda.id,false));
 must(lambdaResult.fst.whnf.arena.size>state.whnf.arena.size,"lambda-returned-type-owned");probes++;
 const checkedApp=marked("checked-application-retains-whnf-state",seed+1n,seed+1n,
  infer(8n,typedWhnf,forbiddenEq,context,state,application.id,false));
 must(checkedApp.snd===aType.id,"checked-application-type");probes++;
 const letDefEq=_c=>s=>left=>right=>{
  if(left!==aType.id||right!==aType.id)return error("let comparison arguments changed");
  const updated=advance(zero.id,s,seed+1n,seed+1n,seed+2n);
  return rejected(updated)?Option.some(updated):ok(updated.value,true);
 };
 const letResult=marked("let-defeq-and-local-scope-state",seed+2n,seed+3n,
  infer(8n,typedWhnf,letDefEq,context,state,letTerm.id,false));
 must(letResult.snd===aType.id,"let-returned-type");probes++;
 const forallWhnf=c=>s=>r=>r!==wrappedSort.id?error("forall callback root changed"):
  s.nextFresh===seed?first(s0.id)(c)(s)(r):
  whnfStep(zero.id,seed+1n,seed+2n,seed+3n,s0.id)(c)(s)(r);
 const forallResult=marked("forall-close-keeps-child-arena-and-restores-parent",seed+1n,seed+3n,
  infer(8n,forallWhnf,forbiddenEq,context,state,forallType.id,false));
 let retained=false;
 for(let i=0n;i<forallResult.fst.whnf.arena.size;i++){
  const entry=accepted(get("psKernelExprV2PagedRequire")(forallResult.fst.whnf.arena,i),"child-arena-entry");
  if(same(entry.node,get("PsKernelExprV2Node").lit(Literal.nat(9000n+seed+3n))))retained=true;
 }
 must(retained,"forall-child-arena-retained");probes++;
 const parameter=marked("projection-parameter-instantiation-state",seed+1n,seed+1n,
  get("psKernelExprV2CheckProjectionApplyParamsOwnedWithFuel")(2n)(first(dependentForall.id))(
   context)(state)(list([two.id]))(0n)(1n)(dependentForall.id));
 must(parameter.snd===two.id,"projection-parameter-value");probes++;
 marked("projection-field-instantiation-state",seed+1n,seed+1n,
  get("psKernelExprV2CheckProjectionSkipFieldsOwnedWithFuel")(2n)(forbidden)(first(dependentForall.id))(
   context)(state)(natName)(projectionMajor.id)(false)(1n)(0n)(dependentForall.id));probes++;
 const projectedSort=attempt(get("psKernelExprV2CheckProjectionSortOwnedWith")(
  first(s0.id),context,state,s0.id),"projection-sort");
 must(get("psKernelLevelNormalizesToZero")(projectedSort.snd),"projection-sort-universe");
 marked("projection-sort-always-calls-whnf",seed+1n,seed+1n,ok(projectedSort.fst,s0.id));probes++;
 const projectedProp=attempt(get("psKernelExprV2CheckProjectionIsPropOwnedWith")(
  first(s0.id),second(s0.id),context,state,aType.id),"projection-prop");
 must(projectedProp.snd,"projection-prop-decision");
 marked("projection-prop-callback-chain",seed+2n,seed+2n,ok(projectedProp.fst,s0.id));probes++;
 const field=marked("projection-final-domain-state",seed+1n,seed+1n,
  get("psKernelExprV2CheckProjectionFinalOwnedWith")(
   forbidden,first(dependentForall.id),context,state,false,dependentForall.id));
 must(field.snd===nat.id,"projection-final-domain");probes++;
 const inferredApp=marked("inference-only-application-retains-whnf-state",seed+1n,seed+1n,
  infer(8n,typedWhnf,forbiddenEq,context,state,application.id,true));
 must(inferredApp.snd===aType.id,"inference-only-application-type");probes++;
 for(const declined of [false,true]){
  const failing=_c=>_s=>_r=>declined?none:error("carrier injected");
  const failingReducer=_c=>_s=>_r=>_cheapRec=>_cheapProj=>declined?none:error("carrier injected");
  const failingCore=c=>s=>r=>_cheapRec=>_cheapProj=>failing(c)(s)(r);
  const failures=[
   ["nat-succ",reduction(get("psKernelExprV2TryReduceNatSuccOwnedWith")(failing,context,state,oneLit.id))],
   ["nat-binary",reduction(get("psKernelExprV2TryReduceNatBinaryOwnedWith")(
    failing,context,state,N.str(natName,"add"),oneLit.id,two.id))],
   ["quot",reduction(get("psKernelExprV2TryReduceQuotOwnedWith")(failing,context,state,quotientLift.id))],
   ["recursor",reduction(get("psKernelExprV2TryReduceRecursorOwnedWith")(
    failing,failingCore,forbidden,forbiddenEq,context,state,recursor.id,false,false))],
   ["projection",get("psKernelExprV2TryWhnfProjectionOwnedWith")(
    failing,failing,context,state,projection.id,natName,0n,projectionMajor.id,false)],
   ["application",get("psKernelExprV2TryWhnfAppOwnedWithReducer")(
    failing,failingReducer,context,state,application.id,false,false)],
   ["public",publicWith(8n,failingReducer,context,state,application.id)],
   ["core",coreWith(8n,false,false,failing,failingReducer,context,state,application.id)],
   ["lambda",infer(8n,failing,forbiddenEq,context,state,lambda.id,false)],
   ["checked-app",infer(8n,failing,forbiddenEq,context,state,application.id,false)],
   ["infer-app",infer(8n,failing,forbiddenEq,context,state,application.id,true)]
  ];
  for(const [label,value]of failures){propagation(label,declined,value);propagated++;}
  propagation("ensure-sort",declined,get("psKernelExprV2CheckEnsureSortOwnedWith")(
   failing,context,state,wrappedSort.id));
  propagation("ensure-forall",declined,get("psKernelExprV2CheckEnsureForallOwnedWith")(
   failing,context,state,wrappedFn.id));propagated+=2;
  const failRight=c=>s=>r=>r===oneLit.id?first(oneLit.id)(c)(s)(r):
   r===two.id&&outerMark(s,seed+1n,seed+1n)?failing(c)(s)(r):
   error("carrier callback received stale state");
  propagation("Nat-right-failure-after-left-effects",declined,
   get("psKernelExprV2TryReduceNatBinaryOwnedWith")(
    failRight,context,state,N.str(natName,"add"),oneLit.id,two.id));propagated++;
 }
}
const oldEmpty=get("psKernelCheckerStateEmpty");
const oldEq=get("psKernelIsDefEqWithFuel"),dagEq=get("psKernelExprV2TryDefEqStateWithFuel");
for(const [label,term]of differential){
 for(const fuel of [0n,1n,2n,3n,8n,64n])for(const [maxRecDepth,recDepth]of [[0n,0n],[1n,15n],[1n,16n]]){
  const limited={...scalar,maxRecDepth,recDepth},c=get("psKernelExprV2CheckContextEmpty")(limited);
  const originalDefEq=oldEq(fuel),ownedDefEq=dagEq(fuel);
  compareWhnf(label+"-public",
   get("psKernelWhnfWithRecursorFuel")(fuel,originalDefEq,limited,oldEmpty,term.term),
   get("psKernelExprV2CheckWhnfOwnedWithFuel")(fuel,ownedDefEq,c,initial,term.id));comparisons++;
  for(const cheapRec of [false,true])for(const cheapProj of [false,true]){
   compareWhnf(label+"-core",
    get("psKernelWhnfCoreWithRecursorFuel")(fuel,originalDefEq,limited,oldEmpty,term.term,cheapRec,cheapProj),
    get("psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel")(
     fuel,ownedDefEq,localValue,c,initial,term.id,cheapRec,cheapProj));comparisons++;
  }
 }
}
must(probes===42&&propagated===56&&comparisons===540,"complete-matrices");
const rootDefEq=dagEq(32n),beta=differential.find(([label])=>label==="beta")[1];
const warmed=attempt(get("psKernelExprV2CheckWhnfOwnedWithFuel")(
 32n,rootDefEq,bare,initial,beta.id),"warm-public");
must(array(warmed.fst.whnf.publicCache).length>0,"public-cache-really-warm");
errorIs("public-zero-before-warm-cache","kernel reduction budget exhausted",
 get("psKernelExprV2CheckWhnfOwnedWithFuel")(0n,rootDefEq,bare,warmed.fst,beta.id));
errorIs("core-zero-before-warm-cache","kernel reduction budget exhausted",
 get("psKernelExprV2CheckWhnfCoreOwnedWithFuel")(0n,rootDefEq,bare,warmed.fst,beta.id,false));
const exhausted={...bare,scalar:{...scalar,maxRecDepth:1n,recDepth:get("psKernelRecDepthFactor")}};
errorIs("core-depth-before-warm-cache","deep recursion detected, use maxRecDepth to increase the limit",
 get("psKernelExprV2CheckWhnfCoreOwnedWithFuel")(32n,rootDefEq,exhausted,warmed.fst,beta.id,false));
const inferred=attempt(infer(8n,forbidden,forbiddenEq,bare,initial,wrappedSort.id,false),"warm-inference");
must(array(inferred.fst.checkedInfer).length>0,"inference-cache-really-warm");
errorIs("inference-zero-before-cache","kernel inference budget exhausted",
 infer(0n,forbidden,forbiddenEq,bare,inferred.fst,wrappedSort.id,false));
errorIs("inference-depth-before-cache","deep recursion detected, use maxRecDepth to increase the limit",
 infer(8n,forbidden,forbiddenEq,exhausted,inferred.fst,wrappedSort.id,false));
errorIs("recursor-zero-before-syntax","kernel recursor budget exhausted",
 get("psKernelExprV2TryReduceRecursorOwnedWithFuel")(0n)(forbiddenEq)(localValue)(
  bare)(initial)(initial.whnf.arena.size+1n)(false)(false));
const shadowName=name("ownedShadow");
const shadowBuilt=accepted(get("psKernelExprV2PagedMkFVar")(initial.whnf.arena,shadowName),"shadow-build");
const shadowState=get("psKernelExprV2CheckStateWithArena")(initial,shadowBuilt.fst),shadowId=shadowBuilt.snd;
const oldLocal=get("psKernelExprV2CheckContextWithLet")(bare,shadowName,shadowName,nat.id,oneLit.id);
const newLocal=get("psKernelExprV2CheckContextWithLet")(oldLocal,shadowName,shadowName,nat.id,two.id);
const noValue=get("psKernelExprV2CheckContextWithLocal")(oldLocal,shadowName,shadowName,nat.id,unit(B.default));
for(const [label,c,expected]of [["old",oldLocal,oneLit.id],["new",newLocal,two.id],["no-value",noValue,shadowId]]){
 const value=attempt(get("psKernelExprV2CheckWhnfOwnedWithFuel")(
  8n,rootDefEq,c,shadowState,shadowId),"context-aware-local-"+label);
 must(value.snd===expected,"context-aware-local-result-"+label);
}
const legacy=get("psKernelLocalContextAddLet")(
 get("psKernelLocalContextEmpty"),shadowName,shadowName,nat.term,oneLit.term);
const mixed={...noValue,scalar:{...scalar,localContext:legacy}};
for(const fuel of [0n,1n,8n]){
 must(same(get("psKernelExprV2CheckWhnfOwnedWithFuel")(
  fuel,rootDefEq,mixed,shadowState,shadowId),none),"owned-legacy-refusal-precedes-fuel");
 must(same(get("psKernelExprV2CheckWhnfWithFuel")(
  fuel,mixed,shadowState.whnf,shadowId),none),"raw-legacy-refusal-precedes-fuel");
 for(const cheapProj of [false,true]){
  must(same(get("psKernelExprV2CheckWhnfCoreOwnedWithFuel")(
   fuel,rootDefEq,mixed,shadowState,shadowId,cheapProj),none),"owned-core-legacy-refusal");
  must(same(get("psKernelExprV2CheckWhnfCoreWithFuel")(
   fuel,mixed,shadowState.whnf,shadowId,cheapProj),none),"raw-core-legacy-refusal");
 }
}
must(get("psKernelResourcePolicyDefault").fuel===4096n,"published-fuel-unchanged");
console.log("PSC1_V2_OWNED_STATE_JS_PASS carrier=42 propagated=56 differential=540 assertions="+assertions);
