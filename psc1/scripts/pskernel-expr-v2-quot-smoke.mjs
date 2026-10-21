import {pathToFileURL} from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_QUOT_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_QUOT_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_QUOT_FAIL "+label);assertions++;};
const accepted=(x,label)=>{
 if(x&&typeof x==="object"&&Object.hasOwn(x,"value"))return x.value;
 throw Error("PSC1_QUOT_UNEXPECTED_REJECTION "+label);
};
const rejected=x=>Boolean(x&&typeof x==="object"&&Object.hasOwn(x,"error"));
const same=(left,right)=>{
 if(left===right)return true;
 if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
 const keys=Reflect.ownKeys(left),others=Reflect.ownKeys(right);
 return keys.length===others.length&&keys.every(key=>Object.hasOwn(right,key)&&same(left[key],right[key]));
};
const invalid=(result,label)=>must(rejected(result)&&typeof result.error.message==="string"&&
 same(result.error,get("PsKernelError").rejectedInvalid(result.error.message)),label);
const List=get("List"),nil=unit(List.nil),Option=get("Option"),none=unit(Option.none),Ex=get("Except");
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(xs&&Object.hasOwn(xs,"head")){out.push(xs.head);xs=xs.tail;}return out;};
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),S=get("PsKernelDefinitionSafety");
const Request=get("PsKernelDeclarationRequest"),D=get("PsKernelDagDeclarationRequest"),C=get("PsKernelDagCommand");
const name=text=>N.str(N.anonymous,text),one=L.succ(L.zero);
let arena=get("psKernelExprV2PagedEmpty");
const build=(kind,term,...args)=>{
 const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
 arena=result.fst;return {term,id:result.snd};
};
const cn=(n,levels=[])=>build("Const",E.const(n,list(levels)),n,list(levels));
const sort=level=>build("Sort",E.sort(level),level);
const bv=index=>build("BVar",E.bvar(index),index);
const app=(f,a)=>build("App",E.app(f.term,a.term),f.id,a.id);
const apps=(f,args)=>args.reduce((x,y)=>app(x,y),f);
const lam=(n,t,b,info=B.default)=>build("Lam",E.lam(name(n),t.term,b.term,info),name(n),t.id,b.id,info);
const forall=(n,t,b,info=B.default)=>build("Forall",E.forallE(name(n),t.term,b.term,info),name(n),t.id,b.id,info);
const lit=n=>build("Lit",E.lit(Literal.nat(n)),Literal.nat(n));
const md=(tag,x)=>build("MData",E.mdata(tag,x.term),tag,x.id);
const letE=(n,t,v,b)=>build("Let",E.letE(name(n),t.term,v.term,b.term,false),name(n),t.id,v.id,b.id,false);
const natName=get("psKernelNatName"),eqName=get("psKernelEqName"),reflName=N.str(eqName,"refl");
const nat=cn(natName),s1=sort(one),zero=sort(L.zero),u=name("u"),universe=L.param(u);
const eqType=forall("alpha",sort(universe),forall("a",bv(0n),forall("b",bv(1n),zero)),B.implicit);
const eqReflResult=apps(cn(eqName,[universe]),[bv(1n),bv(0n),bv(0n)]);
const eqReflType=forall("alpha",sort(universe),forall("a",bv(0n),eqReflResult),B.implicit);
const exprEq=(a,b)=>get("psKernelExprEq")(a)(b);
must(exprEq(eqType.term,get("psKernelExpectedEqType")(u)),"independent-Eq-type-shape");
must(exprEq(eqReflType.term,get("psKernelExpectedEqReflType")(u)),"independent-refl-type-shape");
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty");
invalid(get("psKernelV1AdmitDeclaration")(empty,unit(Request.quot)),"quot-needs-Eq");
let session=empty;
let declarations=nil;
const requests=[];
const inductive=(n,levels,type,ctors,numParams)=>{
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request.ordinaryInductive({
  levelParams:list(levels),name:n,type:type.term,ctors:list(ctors.map(([name,type])=>({name,type:type.term}))),
  isUnsafe:false,numParams})),"checked-inductive").session;
 const request=D.ordinaryInductive(list(levels),numParams,
  {name:n,type:type.id,ctors:list(ctors.map(([name,type])=>({name,type:type.id})))},false);
 declarations=get("psKernelDagDeclarationsAfterAdmission")(request,declarations);
 requests.push(C.admit(request));
};
inductive(natName,[],s1,[[get("psKernelNatZeroName"),nat],
 [get("psKernelNatSuccName"),forall("n",nat,nat)]],0n);
inductive(eqName,[u],eqType,[[reflName,eqReflType]],2n);
const beforeQuot=session;
session=accepted(get("psKernelV1AdmitDeclaration")(session,unit(Request.quot)),"checked-quot").session;
requests.push(C.admit(unit(D.quot)));
must(session.environment.quotInitialized===true,"quot-enabled-after-checked-Eq");
const scalar=get("psKernelKernelSessionChecker")(session,nil,S.safe).context;
const relation=app(cn(eqName,[one]),nat);
const equality=(a,b)=>apps(relation,[a,b]);
const quotient=apps(cn(get("psKernelQuotName"),[one]),[nat,relation]);
const refl=(type,value)=>apps(cn(reflName,[one]),[type,value]);
const major=value=>apps(cn(get("psKernelQuotMkName"),[one]),[nat,relation,value]);
const identity=lam("x",nat,bv(0n));
const respectIdentity=lam("a",nat,lam("b",nat,lam("h",apps(relation,[bv(1n),bv(0n)]),bv(0n))));
const respectConstant=(type,value)=>lam("a",nat,lam("b",nat,
 lam("h",apps(relation,[bv(1n),bv(0n)]),refl(type,value))));
const lift=(type,fn,respect,value)=>apps(cn(get("psKernelQuotLiftName"),[one,one]),
 [nat,relation,type,fn,respect,value]);
const liftIdentity=value=>lift(nat,identity,respectIdentity,value);
const induction=(motive,minor,value)=>apps(cn(get("psKernelQuotIndName"),[one]),
 [nat,relation,motive,minor,value]);
const seven=lit(7n),major7=major(seven),result7=refl(nat,seven);
const motive=lam("q",quotient,equality(seven,seven)),minor=lam("a",nat,result7);
const nestedMajor=lift(quotient,lam("a",nat,major7),respectConstant(quotient,major7),major7);
const fnType=forall("x",nat,nat),constantFn=lam("a",nat,identity);
const liftFn=lift(fnType,constantFn,respectConstant(fnType,identity),major7);
const motiveFn=lam("q",quotient,forall("x",nat,equality(seven,seven)));
const minorFn=lam("a",nat,lam("x",nat,result7));
const partialLift=apps(cn(get("psKernelQuotLiftName"),[one,one]),[nat,relation,nat,identity]);
const partialInd=apps(cn(get("psKernelQuotIndName"),[one]),[nat,relation,motive]);
const fixtures=[
 ["lift",liftIdentity(major7),seven],
 ["ind",induction(motive,minor,major7),result7],
 ["major-beta",liftIdentity(app(lam("q",quotient,bv(0n)),major7)),seven],
 ["major-zeta",liftIdentity(letE("q",quotient,major7,bv(0n))),seven],
 ["major-metadata",liftIdentity(md(31n,major7)),seven],
 ["major-nested-quot",liftIdentity(nestedMajor),seven],
 ["ind-trailing",app(induction(motiveFn,minorFn,major7),lit(9n)),result7],
 ["lift-trailing",app(liftFn,lit(9n)),lit(9n)],
 ["unsaturated-lift",partialLift,partialLift],
 ["unsaturated-ind",partialInd,partialInd]
];
const oldEmpty=get("psKernelCheckerStateEmpty"),initial=()=>get("psKernelExprV2WhnfStateEmpty")(arena);
const noLocal=get("psKernelExprV2NoLocalValue"),oldEq=get("psKernelIsDefEqWithFuel");
const decoded=(owned,id)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(owned),"decode"),id),"decoded-root");
const compare=(old,actual,label)=>{
 const value=accepted(actual,label+"-owned");
 if(rejected(old)){must(rejected(value)&&value.error===old.error,label+"-exact-error");return;}
 const left=accepted(old,label+"-reference"),right=accepted(value,label+"-result");
 must(get("psKernelExprEqual")(left.fst)(decoded(right.fst.arena,right.snd)),label+"-exact-term");
};
const compareReduction=(old,actual,label)=>{
 const value=accepted(actual,label+"-owned");
 if(rejected(old)){must(rejected(value)&&value.error===old.error,label+"-exact-error");return;}
 const left=accepted(old,label+"-reference"),right=accepted(value,label+"-result");
 const a=left.fst,b=right.snd;
 if(same(a,none)){
  must(same(b,none),label+"-no-reduction");
 }else{
  const expr=accepted(a,label+"-reference-some"),id=accepted(b,label+"-result-some");
  must(get("psKernelExprEqual")(expr)(decoded(right.fst.arena,id)),label+"-exact-term");
 }
};
const raw=(fuel,c,s,r)=>get("psKernelExprV2TryWhnfStateWithFuel")(fuel)(c)(s)(r);
const reducer=fuel=>get("psKernelExprV2TryReduceRecursorWithLocalValuesFuel")(fuel)(noLocal);
let publicCases=0,coreCases=0,owners=0,reducers=0;
for(const [label,term,expected] of fixtures){
 for(const fuel of [0n,1n,2n,3n,4n,6n,8n,32n])for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
  const c={...scalar,maxRecDepth,recDepth};
  compare(get("psKernelWhnfWithRecursorFuel")(fuel,oldEq(fuel),c,oldEmpty,term.term),
   raw(fuel,c,initial(),term.id),label+"-public");
  publicCases++;
  for(const cheapProj of [false,true]){
   compare(get("psKernelWhnfCoreWithRecursorFuel")(fuel,oldEq(fuel),c,oldEmpty,term.term,false,cheapProj),
    get("psKernelExprV2CheckWhnfCoreWithFuel")(fuel,get("psKernelExprV2CheckContextEmpty")(c),
     initial(),term.id,cheapProj),label+"-core");
   coreCases++;
  }
 }
 for(const fuel of [0n,1n,2n,3n,6n,16n])for(const recFuel of [0n,1n,2n,8n])
  for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
   const c={...scalar,maxRecDepth,recDepth};
   const oldReducer=get("psKernelReduceRecursorBoundedWithFuel")(recFuel)(oldEq(64n));
   compare(get("psKernelWhnfWithFuel")(fuel)(oldReducer)(c)(oldEmpty)(term.term),
    get("psKernelExprV2TryWhnfStateWithReducerFuel")(fuel)(reducer(recFuel))(noLocal)(c)(initial())(term.id),
    label+"-fixed-owner");
   owners++;
  }
 for(const fuel of [0n,1n,2n,3n,8n,32n]){
  compareReduction(get("psKernelReduceRecursorBoundedWithFuel")(fuel)(oldEq(64n))
   (scalar)(oldEmpty)(term.term)(false)(false),reducer(fuel)(scalar)(initial())(term.id)(false),
   label+"-reducer");reducers++;
 }
 must(exprEq(accepted(get("psKernelV1Whnf")(session,nil,S.safe,term.term),label+"-checked-V1"),
  expected.term),label+"-checked-reference");
 const result=accepted(get("psKernelV1RunDag")(empty,nil,S.safe,arena,list([...requests,C.whnf(term.id)])),
  label+"-complete-batch");
 const replies=array(result.replies);
 must(replies.length===requests.length+1&&exprEq(replies.at(-1).value,expected.term),label+"-batch");
}
must(publicCases===240&&coreCases===480&&owners===720&&reducers===60,"complete-matrix");
const invalids=[
 liftIdentity(apps(cn(get("psKernelQuotMkName"),[one]),[nat,relation])),
 liftIdentity(apps(cn(get("psKernelQuotMkName"),[one]),[nat,relation,seven,lit(8n)])),
 liftIdentity(seven),lift(nat,s1,respectIdentity,major7),
 apps(cn(get("psKernelQuotLiftName")),[nat,relation,nat,identity,respectIdentity,major7])
];
for(const term of invalids){
 const a=get("psKernelV1Whnf")(session,nil,S.safe,term.term);
 const b=get("psKernelV1RunDag")(empty,nil,S.safe,arena,list([...requests,C.whnf(term.id)]));
 invalid(a,"reference-invalid");invalid(b,"batch-invalid");
 must(same(a.error,b.error),"invalid-exact-error");
 const oldWhnf=c=>s=>r=>Ex.ok({fst:r,snd:s});
 const newWhnf=c=>s=>r=>Option.some(Ex.ok({fst:s,snd:r}));
 compareReduction(get("psKernelReduceQuotWith")(oldWhnf,scalar,oldEmpty,term.term),
  get("psKernelExprV2TryReduceQuotWith")(newWhnf,scalar,initial(),term.id),
  "raw-invalid-shape-not-public-admission");
}
const expression=fixtures[0][1],badRoot=arena.size+1n;
const expectError=(attempt,message,label)=>{
 const value=accepted(attempt,label+"-some");
 must(rejected(value)&&value.error===message,label);
};
expectError(raw(0n,scalar,initial(),badRoot),"kernel reduction budget exhausted","zero-before-root");
expectError(reducer(0n)(scalar)(initial())(badRoot)(false),"kernel recursor budget exhausted",
 "recursor-zero-before-root");
const badWhnf=c=>s=>r=>Option.some(Ex.error("QUOT_MAJOR_CALLBACK"));
expectError(get("psKernelExprV2TryReduceQuotWith")(badWhnf,scalar,initial(),expression.id),
 "QUOT_MAJOR_CALLBACK","major-error");
const missingWhnf=c=>s=>r=>none;
must(same(get("psKernelExprV2TryReduceQuotWith")(missingWhnf,scalar,initial(),expression.id),none),
 "major-unsupported");
const cold=get("psKernelKernelSessionChecker")(beforeQuot,nil,S.safe).context;
const disabled=accepted(accepted(get("psKernelExprV2TryReduceQuotWith")(badWhnf,cold,initial(),badRoot),
 "disabled-some"),"disabled-ok");
must(same(disabled.snd,none)&&disabled.fst.arena.size===arena.size,"disabled-before-root");
const short=accepted(accepted(get("psKernelExprV2TryReduceQuotWith")(badWhnf,scalar,initial(),partialLift.id),
 "short-some"),"short-ok");
must(same(short.snd,none),"unsaturated-before-callback");
const warm=accepted(accepted(raw(32n,scalar,initial(),expression.id),"warm-some"),"warm-ok");
must(array(get("psKernelExprV2WhnfCacheEntries")(warm.fst.publicCache)).length>0,"owned-public-cache");
expectError(raw(0n,scalar,warm.fst,expression.id),"kernel reduction budget exhausted","warm-zero");
console.log("PSC1_V2_DAG_QUOT: PASS public=240 core=480 owners=720 reducer=60 assertions="+assertions);
