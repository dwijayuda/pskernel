import { pathToFileURL } from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_PROOF_IRREL_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{
  if(!(name in k))throw Error("PSC1_PROOF_IRREL_MISSING_EXPORT "+name);
  return k[name];
};
let assertions=0;
const must=(value,label)=>{
  if(value!==true)throw Error("PSC1_PROOF_IRREL_FAILED "+label);
  assertions++;
};
const accepted=(result,label)=>{
  if(result&&typeof result==="object"&&"value" in result)return result.value;
  throw Error("PSC1_PROOF_IRREL_UNEXPECTED_REJECTION "+label);
};
const rejected=result=>Boolean(result&&typeof result==="object"&&"error" in result);
const same=(left,right)=>{
  if(left===right)return true;
  if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
  const keys=Reflect.ownKeys(left),others=Reflect.ownKeys(right);
  return keys.length===others.length&&keys.every(key=>Object.hasOwn(right,key)&&same(left[key],right[key]));
};
const List=get("List"),nil=typeof List.nil==="function"?List.nil():List.nil;
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(xs&&typeof xs==="object"&&"head" in xs){out.push(xs.head);xs=xs.tail;}return out;};
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel");
const B=get("PsKernelBinderInfo"),S=get("PsKernelDefinitionSafety");
const D=get("PsKernelDagDeclarationRequest"),Request=get("PsKernelDeclarationRequest");
const C=get("PsKernelDagCommand"),name=text=>N.str(N.anonymous,text);
const Option=get("Option");
const none=typeof Option.none==="function"?Option.none():Option.none;
let arena=get("psKernelExprV2PagedEmpty");
const build=(kind,term,...args)=>{
  const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
  arena=result.fst;return {id:result.snd,term};
};
const sort=level=>build("Sort",E.sort(level),level);
const bv=index=>build("BVar",E.bvar(index),index);
const mv=n=>build("MVar",E.mvar(n),n);
const cn=text=>build("Const",E.const(name(text),nil),name(text),nil);
const app=(f,a)=>build("App",E.app(f.term,a.term),f.id,a.id);
const lam=(n,t,b)=>build("Lam",E.lam(n,t.term,b.term,B.default),n,t.id,b.id,B.default);
const forall=(n,t,b)=>build("Forall",E.forallE(n,t.term,b.term,B.default),n,t.id,b.id,B.default);
const letE=(n,t,v,b)=>build("Let",E.letE(n,t.term,v.term,b.term,false),n,t.id,v.id,b.id,false);
const md=(tag,b)=>build("MData",E.mdata(tag,b.term),tag,b.id);
const s0=sort(L.zero),s1=sort(L.succ(L.zero)),b0=bv(0n);
const universal=forall(name("p"),s0,b0);
const otherUniversal=forall(name("A"),s1,universal);
const prop=cn("proofP"),maxProp=cn("proofMax");
const specifications=[
 ["proofP",s0,false],["proofMax",sort(L.max(L.zero,L.zero)),false],
 ["proofLeft",prop,false],["proofRight",prop,false],
 ["proofMaxLeft",maxProp,false],["proofMaxRight",maxProp,false],
 ["proofAllLeft",universal,false],["proofAllRight",universal,false],
 ["proofOther",otherUniversal,false],["proofUnsafe",prop,true],
 ["proofFunction",forall(name("x"),prop,prop),false],
 ["proofQ",s0,false],["proofQRight",cn("proofQ"),false],
 ["nonProofLeft",s1,false],["nonProofRight",s1,false]
];
const empty=accepted(get("psKernelKernelSessionEmpty")(
  get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty-session");
let session=empty,declarations=nil;
const requests=[];
for(const [text,type,isUnsafe] of specifications){
 const n=name(text);
 session=accepted(get("psKernelV1AdmitDeclaration")(session,
   Request.axiomDecl({base:{name:n,levelParams:nil,type:type.term},isUnsafe})),"fixture-admission").session;
 const request=D.axiomDecl({name:n,levelParams:nil,type:type.id},isUnsafe);
 declarations=get("psKernelDagDeclarationsAfterAdmission")(request,declarations);
 requests.push(C.admit(request));
}
const p=cn("proofLeft"),q=cn("proofRight"),mvar=mv(name("untrusted"));
const unchecked=app(cn("proofFunction"),mvar);
const identity=lam(name("x"),prop,b0);
const metadata=md(7n,p);
const fixtures=[
 ["proof-constants",p,q,true],
 ["metadata-left",metadata,q,true],
 ["metadata-both",metadata,md(8n,q),true],
 ["beta-left",app(identity,p),q,true],
 ["zeta-left",letE(name("x"),prop,p,b0),q,true],
 ["normalized-zero",cn("proofMaxLeft"),cn("proofMaxRight"),true],
 ["forall-proofs",cn("proofAllLeft"),cn("proofAllRight"),true],
 ["different-propositions",cn("proofAllLeft"),cn("proofOther"),false],
 ["right-metavariable",p,mvar,null],
 ["left-metavariable",mvar,p,null],
 ["loose-variable",b0,p,null],
 ["illtyped-left",app(s0,s0),p,null],
 ["unknown-left-before-right",cn("notAdmitted"),mvar,null],
 ["unsafe-inference-only",p,cn("proofUnsafe"),true],
 ["unchecked-argument-is-not-admission",p,unchecked,true]
];
const nonLeft=cn("nonProofLeft"),nonRight=cn("nonProofRight"),distinct=cn("proofQRight");
const base=get("psKernelKernelSessionChecker")(session,nil,S.safe);
const ctx=scalar=>get("psKernelExprV2CheckContextEmpty")(scalar);
const initial=()=>get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(arena),
 get("psKernelExprV2WhnfStateForDeclarations")(arena,declarations));
const raw=(fuel,context,state,left,right)=>
 get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(context)(state)(left)(right);
const original=(fuel,scalar,state,left,right)=>
 get("psKernelIsDefEqWithFuel")(fuel)(scalar)(state)(left)(right);
const oldEmpty=get("psKernelCheckerStateEmpty");
const run=get("psKernelV1RunDag");
const compare=(expected,attempted,label)=>{
 const actual=accepted(attempted,label+"-direct");
 if(rejected(expected)){
  must(rejected(actual)&&actual.error===expected.error,label+"-exact-error");
 }else{
  const a=accepted(expected,label+"-original"),b=accepted(actual,label+"-result");
  must(a.fst===b.snd,label+"-decision");
  must(a.snd.nextFresh===b.fst.nextFresh,label+"-fresh-owner");
 }
};
const comparePublic=(expected,actual,label)=>{
 if(rejected(expected)){
  must(rejected(actual)&&same(expected.error,actual.error),label+"-public-error");
 }else{
  const a=accepted(expected,label+"-public-original"),b=accepted(actual,label+"-public");
  const replies=array(b.replies);
  must(replies.length===1&&replies[0].value===a,label+"-public-decision");
 }
};
let comparisons=0;
for(const [label,left,right,decision] of fixtures){
 for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,16n,64n]){
  for(const maxRecDepth of [0n,1n,2n])for(const recDepth of [0n,15n,16n]){
   const scalar={...base.context,maxRecDepth,recDepth};
   compare(original(fuel,scalar,oldEmpty,left.term,right.term),
    raw(fuel,ctx(scalar),initial(),left.id,right.id),label+"-"+fuel+"-"+maxRecDepth+"-"+recDepth);
   comparisons++;
  }
 }
 const selected=accepted(get("psKernelExprV2TryDefEqWithDeclarationsFuel")(
  64n,base.context,arena,declarations,left.id,right.id),label+"-selected");
 if(decision===null)must(rejected(selected),label+"-high-budget-error");
 else must(accepted(selected,label+"-high-budget")===decision,label+"-high-budget-decision");
 for(const fuel of [0n,1n,2n,4n,8n,64n]){
  const limited={...session,resources:{...session.resources,fuel}};
  comparePublic(get("psKernelV1IsDefEq")(limited,nil,S.safe,left.term,right.term),
   run(limited,nil,S.safe,arena,list([C.isDefEq(left.id,right.id)])),label+"-"+fuel);
 }
 if(label==="unsafe-inference-only"||label==="unchecked-argument-is-not-admission"){
  const result=run(session,nil,S.safe,arena,list([C.isDefEq(left.id,right.id)]));
  must(rejected(result),label+"-mandatory-public-check");
 }
}
must(comparisons===1350,"complete-raw-matrix");
const context=ctx(base.context),cold=initial();
const oldWarm=accepted(original(64n,base.context,oldEmpty,p.term,q.term),"warm-original");
const warm=accepted(accepted(raw(64n,context,cold,p.id,q.id),"warm-some"),"warm-result");
must(!same(warm.fst.inferOnly,nil)&&same(warm.fst.checkedInfer,nil),"infer-only-not-checked");
for(const fuel of [0n,1n,64n])for(const recDepth of [0n,15n,16n]){
 const scalar={...base.context,maxRecDepth:1n,recDepth};
 compare(original(fuel,scalar,oldWarm.snd,p.term,q.term),
  raw(fuel,ctx(scalar),warm.fst,p.id,q.id),"warm-entry-"+fuel+"-"+recDepth);
}
const coldOne=accepted(raw(1n,context,cold,p.id,q.id),"cold-one-some");
must(rejected(coldOne)&&coldOne.error==="kernel reduction budget exhausted",
 "cold-one-preserves-core-predecessor");
const normalized=accepted(accepted(raw(64n,context,cold,metadata.id,q.id),
 "normalized-some"),"normalized-result");
const contains=(left,right)=>accepted(get("psKernelExprV2DefEqPairContains")(
 normalized.fst.whnf.arena,normalized.fst.success,left,right),"success-contains");
must(contains(metadata.id,q.id)===true,"success-publishes-original-pair");
must(contains(p.id,q.id)===false,"success-does-not-publish-normalized-proof-pair");
const rawUnchecked=accepted(accepted(raw(64n,context,cold,p.id,unchecked.id),
 "unchecked-some"),"unchecked-result");
const checked=accepted(get("psKernelExprV2TryCheckStateWithFuel")(
 64n,context,rawUnchecked.fst,unchecked.id),"mandatory-check-some");
const oldCheck=get("psKernelCheckerCheck")(64n,base.context,oldEmpty,unchecked.term);
must(rejected(checked)&&rejected(oldCheck)&&checked.error===oldCheck.error,
 "inference-only-cannot-authorize-checked-judgment");
let terminalComparisons=0;
for(const [label,left,right] of [
 ["non-proposition-terminal-false",nonLeft,nonRight],
 ["different-proposition-terminal-false",p,distinct]]){
 const terminal=accepted(accepted(raw(64n,context,cold,left.id,right.id),
  label+"-some"),label+"-result");
 must(terminal.snd===false,label);
 for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,16n,64n])
  for(const maxRecDepth of [0n,1n,2n])for(const recDepth of [0n,15n,16n]){
   const scalar={...base.context,maxRecDepth,recDepth};
   compare(original(fuel,scalar,oldEmpty,left.term,right.term),
    raw(fuel,ctx(scalar),cold,left.id,right.id),label+"-fixed-resource-parity");
   terminalComparisons++;
  }
}
must(terminalComparisons===180,"terminal-comparison-matrix-count");
console.log("PSC1_V2_DAG_JS_PROOF_IRRELEVANCE_TERMINAL: PASS comparisons=180");
comparePublic(get("psKernelV1IsDefEq")(session,nil,S.safe,p.term,distinct.term),
 run(session,nil,S.safe,arena,list([C.isDefEq(p.id,distinct.id)])),
 "different-proposition-public-negative");
must(same(get("psKernelExprV2TryDefEqWithDeclarationsFuel")(
 64n,base.context,arena,nil,p.id,q.id),none),"missing-owner-retains-fallback");
const inferType=c=>s=>r=>get("psKernelExprV2TryInferStateWithFuel")(64n,c,s,r);
const noWhnf=c=>s=>r=>get("psKernelExprV2CheckWhnfWithFuel")(0n,c,s,r);
const mandatory=accepted(get("psKernelExprV2DefEqIsPropWith")(
 inferType,noWhnf,context,cold,prop.id),"isprop-mandatory-some");
must(rejected(mandatory)&&mandatory.error==="kernel reduction budget exhausted",
 "isprop-whnf-remains-mandatory");
const localLeftName=name("proofLocalLeft"),localRightName=name("proofLocalRight");
const localLeft=build("FVar",E.fvar(localLeftName),localLeftName);
const localRight=build("FVar",E.fvar(localRightName),localRightName);
let oldLocals=get("psKernelLocalContextAddLocal")(
 base.context.localContext,localLeftName,localLeftName,prop.term,B.default);
oldLocals=get("psKernelLocalContextAddLocal")(
 oldLocals,localRightName,localRightName,prop.term,B.default);
const oldContext=get("psKernelCheckerContextWithLocalContext")(base.context,oldLocals);
must(same(get("psKernelExprV2TryDefEqWithDeclarationsFuel")(
 64n,oldContext,arena,declarations,localLeft.id,localRight.id),none),
 "external-scalar-locals-decline-before-typed-inference");
must(same(get("psKernelExprV2TryQuickDefEqWithFuel")(64n)(oldContext)(arena)(localLeft.id)(localRight.id),none),
 "external-locals-compatibility-wrapper-declines");
const externalZero=accepted(get("psKernelExprV2TryQuickDefEqWithFuel")(0n)(
 oldContext)(arena)(localLeft.id)(localRight.id),"external-locals-zero-some");
must(rejected(externalZero)&&externalZero.error==="kernel definitional equality budget exhausted",
 "external-locals-zero-fuel-keeps-entry-error");
const depthContext={...oldContext,maxRecDepth:1n,recDepth:16n};
const depthExpected=get("psKernelCheckerContextEnterRecDepth")(depthContext);
const depthActual=accepted(get("psKernelExprV2TryQuickDefEqWithFuel")(64n)(
 depthContext)(arena)(localLeft.id)(localRight.id),"external-depth-some");
must(rejected(depthExpected)&&same(depthActual,depthExpected),
 "external-locals-depth-error-precedes-fallback");
let typed=get("psKernelExprV2CheckContextWithLocal")(
 context,localLeftName,localLeftName,prop.id,B.default);
typed=get("psKernelExprV2CheckContextWithLocal")(
 typed,localRightName,localRightName,prop.id,B.default);
const localAttempt=raw(64n,typed,initial(),localLeft.id,localRight.id);
compare(original(64n,oldContext,oldEmpty,localLeft.term,localRight.term),
 localAttempt,"local-proof-irrelevance");
const localResult=accepted(accepted(localAttempt,"local-some"),"local-result");
must(accepted(get("psKernelExprV2DefEqPairContains")(
 localResult.fst.whnf.arena,localResult.fst.success,localLeft.id,localRight.id),
 "local-pair-membership")===false,"local-proof-pair-never-published");
const batch=accepted(run(empty,nil,S.safe,arena,list([...requests,C.isDefEq(p.id,q.id)])),
 "real-batch");
const replies=array(batch.replies);
must(replies.length===requests.length+1&&replies.at(-1).value===true,
 "real-batch-admission-and-proof-comparison");
console.log("PSC1_V2_DAG_JS_PROOF_IRRELEVANCE: PASS comparisons="+comparisons+" assertions="+assertions);
