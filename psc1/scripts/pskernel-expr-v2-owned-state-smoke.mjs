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

const boolRoot=(root,expected,value)=>{
 if(same(value,none))return none;
 const attempted=accepted(value,"bool-some");
 if(rejected(attempted))return Option.some(attempted);
 const result=accepted(attempted,"bool-ok");
 return result.snd===expected?ok(result.fst,root):error("carrier Boolean decision changed");
};
const optionalBoolRoot=(root,expected,value)=>{
 if(same(value,none))return none;
 const attempted=accepted(value,"optional-bool-some");
 if(rejected(attempted))return Option.some(attempted);
 const result=accepted(attempted,"optional-bool-ok");
 return same(result.snd,expected)?ok(result.fst,root):error("carrier optional decision changed");
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
const withQuot=accepted(get("psKernelV1AdmitDeclaration")(withEq.session,unit(Request.quot)),"checked-Quot");
const unitName=name("CarrierUnit"),unitCtorName=N.str(unitName,"mk");
const unitDecl={levelParams:nil,name:unitName,type:s1.term,
 ctors:list([{name:unitCtorName,type:E.const(unitName,nil)}]),isUnsafe:false,numParams:0n};
const withUnit=accepted(get("psKernelV1AdmitDeclaration")(
 withQuot.session,Request.ordinaryInductive(unitDecl)),"checked-Unit");
const aliasName=name("carrierAlias"),aliasHints=get("PsKernelReducibilityHints").regular(1n);
const aliasInfo={base:{name:aliasName,levelParams:nil,type:nat.term},
 value:E.lit(Literal.nat(2n)),hints:aliasHints,safety:unit(S.safe)};
const session=accepted(get("psKernelV1AdmitDeclaration")(
 withUnit.session,Request.definitionDecl(aliasInfo)),"checked-alias").session;
const scalar=get("psKernelKernelSessionChecker")(session,nil,unit(S.safe)).context;
const request=D.ordinaryInductive(nil,0n,{name:natName,type:s1.id,
 ctors:list([{name:get("psKernelNatZeroName"),type:nat.id},
  {name:get("psKernelNatSuccName"),type:succType.id}])},false);
const zero=lit(0n),oneLit=lit(1n),two=lit(2n),wrappedSort=md(61n,s0);
const alias=cn(aliasName),unitType=cn(unitName),unitLeft=fv("unitLeft"),unitRight=fv("unitRight");
const boolTrue=cn(get("psKernelBoolTrueName"));
const str=build("Lit",E.lit(Literal.str("λ😀")),Literal.str("λ😀"));
const strOutput=accepted(get("psKernelExprV2StringLitToConstructorOnCanonical")(arena,"λ😀"),"string-build");
arena=strOutput.fst;const strBuilt={id:strOutput.snd};
const addTerm=apps(cn(N.str(natName,"add")),[oneLit,two]);
const aType=fv("A"),aValue=fv("a"),bValue=fv("b"),fn=fv("f"),bound=bv(0n);
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
const unitRequest=D.ordinaryInductive(nil,0n,
 {name:unitName,type:s1.id,ctors:list([{name:unitCtorName,type:unitType.id}])},false);
const aliasRequest=D.definitionDecl({base:{name:aliasName,levelParams:nil,type:nat.id},
 value:two.id,hints:aliasHints,safety:unit(S.safe)});
const declarations=get("psKernelDagDeclarationsAfterAdmission")(aliasRequest,
 get("psKernelDagDeclarationsAfterAdmission")(unitRequest,
  get("psKernelDagDeclarationsAfterAdmission")(request,nil)));
const generated=accepted(get("psKernelDagGeneratedAfterCommand")(C.admit(request),session.environment,
 {arena:input,built,declarations}),"install-checked-generated");
const initial=get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(generated.arena),
 get("psKernelExprV2WhnfStateForDeclarations")(generated.arena,generated.declarations));
const bare=get("psKernelExprV2CheckContextEmpty")(scalar);
let context=get("psKernelExprV2CheckContextWithLocal")(bare,name("A"),name("A"),wrappedSort.id,unit(B.default));
context=get("psKernelExprV2CheckContextWithLocal")(context,name("a"),name("a"),aType.id,unit(B.default));
context=get("psKernelExprV2CheckContextWithLocal")(context,name("f"),name("f"),wrappedFn.id,unit(B.default));
context=get("psKernelExprV2CheckContextWithLocal")(context,name("b"),name("b"),aType.id,unit(B.default));
context=get("psKernelExprV2CheckContextWithLocal")(context,name("unitLeft"),name("unitLeft"),unitType.id,unit(B.default));
context=get("psKernelExprV2CheckContextWithLocal")(context,name("unitRight"),name("unitRight"),unitType.id,unit(B.default));
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
let probes=0,propagated=0,comparisons=0,defeqProbes=0,defeqPropagation=0;
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
 const eqStep=(tag,fresh,next,answer)=>_c=>s=>_l=>_r=>{
  const updated=advance(zero.id,s,tag,fresh,next);
  return rejected(updated)?Option.some(updated):ok(updated.value,answer);
 };
 const assertBool=(label,tag,answer,value)=>marked(label,tag,tag,boolRoot(zero.id,answer,value));
 const assertOptional=(label,tag,answer,value)=>marked(label,tag,tag,optionalBoolRoot(zero.id,answer,value));
 assertOptional("reflection-whnf-state",seed+1n,Option.some(true),
  get("psKernelExprV2DefEqReflectionOwnedWith")(first(boolTrue.id),context,state,boolTrue.id,boolTrue.id));defeqProbes++;
 const orderedCore=c=>s=>r=>r===fn.id?first(fn.id)(c)(s)(r):
  r===bValue.id?second(bValue.id)(c)(s)(r):error("DefEq core operand order changed");
 assertBool("prefix-left-right-continuation-state",seed+3n,false,
  get("psKernelExprV2DefEqCoreQuickContinueOwnedWith")(
   eqStep(seed+2n,seed+2n,seed+3n,false),forbiddenEq,orderedCore,context,state,fn.id,bValue.id));defeqProbes++;
 assertBool("is-prop-inference-whnf-state",seed+2n,true,
  get("psKernelExprV2DefEqIsPropOwnedWith")(first(s0.id),second(s0.id),context,state,aType.id));defeqProbes++;
 const proofInfer=c=>s=>r=>r===aValue.id?first(aType.id)(c)(s)(r):
  r===aType.id?second(s0.id)(c)(s)(r):r===bValue.id?
   whnfStep(zero.id,seed+3n,seed+3n,seed+4n,aType.id)(c)(s)(r):
   error("proof irrelevance inference order changed");
 assertBool("proof-irrelevance-all-callback-state",seed+5n,true,
  get("psKernelExprV2DefEqProofIrrelevanceContinueOwnedWith")(
   forbiddenEq,eqStep(seed+4n,seed+4n,seed+5n,true),proofInfer,
   whnfStep(zero.id,seed+2n,seed+2n,seed+3n,s0.id),context,state,aValue.id,bValue.id));defeqProbes++;
 const nonPropInfer=c=>s=>r=>r===oneLit.id?first(nat.id)(c)(s)(r):
  r===nat.id?second(s1.id)(c)(s)(r):error("non-proposition inference order changed");
 assertBool("non-proposition-continuation-state",seed+4n,false,
  get("psKernelExprV2DefEqProofIrrelevanceContinueOwnedWith")(
   eqStep(seed+3n,seed+3n,seed+4n,false),forbiddenEq,nonPropInfer,
   whnfStep(zero.id,seed+2n,seed+2n,seed+3n,s1.id),context,state,oneLit.id,two.id));defeqProbes++;
 assertBool("lazy-nat-left-retains-both-operands",seed+3n,false,
  get("psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith")(
   forbiddenEq,eqStep(seed+2n,seed+2n,seed+3n,false),binary,context,state,addTerm.id,zero.id));defeqProbes++;
 assertBool("lazy-nat-right-retains-both-operands",seed+3n,false,
  get("psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith")(
   forbiddenEq,eqStep(seed+2n,seed+2n,seed+3n,false),binary,context,state,zero.id,addTerm.id));defeqProbes++;
 const aliasEntry=accepted(get("psKernelExprV2PagedRequire")(state.whnf.arena,alias.id),"alias-entry");
 const unfoldedMark=(s,r)=>{
  const rows=array(s.unfold);
  return outerMark({...s,unfold:state.unfold},seed,seed)&&rows.length===2&&
   cacheMark(list(rows.slice(1)),seed)&&rows[0].source===alias.id&&
   rows[0].result===r&&rows[0].hash===aliasEntry.hash;
 };
 const deltaCore=_c=>s=>r=>cheapProj=>{
  if(!cheapProj||!unfoldedMark(s,r))return error("delta unfolding publication or callback owner changed");
  const equal=get("psKernelExprV2PagedEqOnCanonical")(s.whnf.arena,r,two.id);
  if(rejected(equal))return Option.some(equal);
  return accepted(equal,"delta-body")?ok(stamp(zero.id,s,seed+1n),two.id):error("delta callback body changed");
 };
 marked("delta-once-retains-full-core-state",seed+1n,seed+1n,
  get("psKernelExprV2DefEqDeltaOnceOwnedWith")(deltaCore,context,state,alias.id));defeqProbes++;
 const projectionCore=c=>s=>r=>cheapProj=>r===projection.id&&!cheapProj?
  first(oneLit.id)(c)(s)(r):error("projection core flags changed");
 marked("delta-projection-core-state",seed+1n,seed+1n,reduction(
  get("psKernelExprV2DefEqTryUnfoldProjAppOwnedWith")(projectionCore,context,state,projection.id)));defeqProbes++;
 assertBool("lazy-delta-loop-retains-core-state",seed+1n,true,
  get("psKernelExprV2DefEqLazyDeltaContinueOwnedWithFuel")(
   2n,forbiddenEq,forbiddenEq,forbidden,deltaCore,context,state,alias.id,two.id));defeqProbes++;
 assertBool("lazy-projection-loop-retains-core-state",seed+1n,true,
  get("psKernelExprV2DefEqLazyProjReductionOwnedWithFuel")(2n)(forbiddenEq)(deltaCore)(
   context)(state)(alias.id)(two.id)(natName)(0n));defeqProbes++;
 for(const lambdaOnLeft of [false,true]){
  assertOptional("function-eta-retains-infer-whnf-defeq-state",seed+3n,none,
   get("psKernelExprV2DefEqFullShapeEtaOwnedWith")(
    lambdaOnLeft,eqStep(seed+2n,seed+2n,seed+3n,false),first(wrappedFn.id),second(fnType.id),
    context,state,lambda.id,fn.id));defeqProbes++;
 }
 const changedCore=c=>s=>r=>cheapProj=>cheapProj?error("residual core must disable cheap projection"):
  r===wrappedSort.id?first(s0.id)(c)(s)(r):r===s1.id?second(s1.id)(c)(s)(r):error("residual core order changed");
 assertBool("residual-full-whnf-changed-state",seed+3n,false,
  get("psKernelExprV2DefEqResidualOwnedWith")(
   eqStep(seed+2n,seed+2n,seed+3n,false),forbidden,forbidden,changedCore,context,state,wrappedSort.id,s1.id));defeqProbes++;
 const unchangedCore=c=>s=>r=>cheapProj=>cheapProj?
  error("residual core must disable cheap projection"):orderedCore(c)(s)(r);
 assertBool("residual-final-unit-negative-keeps-whnf-state",seed+4n,false,
  get("psKernelExprV2DefEqResidualOwnedWith")(forbiddenEq,
   whnfStep(zero.id,seed+2n,seed+2n,seed+3n,wrappedFn.id),
   whnfStep(zero.id,seed+3n,seed+3n,seed+4n,fnType.id),
   unchangedCore,context,state,fn.id,bValue.id));defeqProbes++;
 for(const reverse of [false,true]){
  const left=reverse?strBuilt.id:str.id,right=reverse?str.id:strBuilt.id;
  assertOptional("string-expansion-keeps-whnf-defeq-state",seed+2n,Option.some(true),
   get("psKernelExprV2DefEqStringLitExpansionOwnedWith")(
    eqStep(seed+1n,seed+1n,seed+2n,true),first(strBuilt.id),context,state,left,right));defeqProbes++;
 }
 const unitInfer=c=>s=>r=>r===unitLeft.id?first(unitType.id)(c)(s)(r):r===unitRight.id?
  whnfStep(zero.id,seed+2n,seed+2n,seed+3n,unitType.id)(c)(s)(r):error("unit-like inference order changed");
 assertBool("unit-like-all-callback-state",seed+4n,true,
  get("psKernelExprV2DefEqUnitLikeOwnedWith")(
   eqStep(seed+3n,seed+3n,seed+4n,true),unitInfer,second(unitType.id),
   context,state,unitLeft.id,unitRight.id));defeqProbes++;
 assertBool("final-rules-all-callback-state",seed+4n,true,
  get("psKernelExprV2DefEqFinalRulesOwnedWith")(
   eqStep(seed+3n,seed+3n,seed+4n,true),unitInfer,second(unitType.id),
   context,state,unitLeft.id,unitRight.id));defeqProbes++;
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
  const afterOneFail=c=>s=>r=>outerMark(s,seed+1n,seed+1n)?
   failing(c)(s)(r):error("DefEq failure callback received stale first state");
  const afterTwoFail=c=>s=>r=>outerMark(s,seed+2n,seed+2n)?
   failing(c)(s)(r):error("DefEq failure callback received stale second state");
  const coreFailRight=c=>s=>r=>r===fn.id?first(fn.id)(c)(s)(r):
   r===bValue.id?afterOneFail(c)(s)(r):error("DefEq failure core order changed");
  const failDeltaCore=c=>s=>r=>cheapProj=>cheapProj&&unfoldedMark(s,r)?
   failing(c)(s)(r):error("DefEq failure lost unfolding state");
  const failProjectionCore=c=>s=>r=>cheapProj=>r===projection.id&&!cheapProj&&outerMark(s,seed,seed)?
   failing(c)(s)(r):error("DefEq projection failure flags changed");
  const failResidualCore=c=>s=>r=>cheapProj=>cheapProj?
   error("DefEq residual failure flags changed"):coreFailRight(c)(s)(r);
  const defeqFailures=[
   ["prefix-right",boolRoot(zero.id,false,get("psKernelExprV2DefEqCoreQuickContinueOwnedWith")(
    forbiddenEq,forbiddenEq,coreFailRight,context,state,fn.id,bValue.id))],
   ["proof-whnf",boolRoot(zero.id,false,get("psKernelExprV2DefEqProofIrrelevanceContinueOwnedWith")(
    forbiddenEq,forbiddenEq,proofInfer,afterTwoFail,context,state,aValue.id,bValue.id))],
   ["lazy-nat-right",boolRoot(zero.id,false,get("psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith")(
    forbiddenEq,forbiddenEq,failRight,context,state,addTerm.id,zero.id))],
   ["delta-core",get("psKernelExprV2DefEqDeltaOnceOwnedWith")(failDeltaCore,context,state,alias.id)],
   ["projection-core",reduction(get("psKernelExprV2DefEqTryUnfoldProjAppOwnedWith")(
    failProjectionCore,context,state,projection.id))],
   ["eta-whnf",optionalBoolRoot(zero.id,none,get("psKernelExprV2DefEqFullShapeEtaOwnedWith")(
    true,forbiddenEq,first(wrappedFn.id),afterOneFail,context,state,lambda.id,fn.id))],
   ["residual-right",boolRoot(zero.id,false,get("psKernelExprV2DefEqResidualOwnedWith")(
    forbiddenEq,forbidden,forbidden,failResidualCore,context,state,fn.id,bValue.id))],
   ["string-whnf",optionalBoolRoot(zero.id,none,get("psKernelExprV2DefEqStringLitExpansionOwnedWith")(
    forbiddenEq,failing,context,state,str.id,strBuilt.id))],
   ["unit-whnf",boolRoot(zero.id,false,get("psKernelExprV2DefEqUnitLikeOwnedWith")(
    forbiddenEq,unitInfer,afterOneFail,context,state,unitLeft.id,unitRight.id))],
   ["lazy-projection-core",boolRoot(zero.id,false,get("psKernelExprV2DefEqLazyProjReductionOwnedWithFuel")(2n)(
    forbiddenEq)(failDeltaCore)(context)(state)(alias.id)(two.id)(natName)(0n))],
   ["lazy-delta-core",boolRoot(zero.id,false,get("psKernelExprV2DefEqLazyDeltaContinueOwnedWithFuel")(
    2n,forbiddenEq,forbiddenEq,forbidden,failDeltaCore,context,state,alias.id,two.id))]
  ];
  for(const [label,value]of defeqFailures){propagation("DefEq-"+label,declined,value);defeqPropagation++;}
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
must(defeqProbes===38&&defeqPropagation===44,"complete-DefEq-carrier-matrices");
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
console.log("PSC1_V2_OWNED_STATE_JS_PASS carrier=42 propagated=56 differential=540 defeqCarrier=38 defeqPropagated=44 assertions="+assertions);
