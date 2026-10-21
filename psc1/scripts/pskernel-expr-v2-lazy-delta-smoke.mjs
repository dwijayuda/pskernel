import { pathToFileURL } from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_LAZY_DELTA_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{
 if(!(name in k))throw Error("PSC1_LAZY_DELTA_MISSING_EXPORT "+name);
 return k[name];
};
let assertions=0;
const must=(value,label)=>{
 if(value!==true)throw Error("PSC1_LAZY_DELTA_FAILED "+label);
 assertions++;
};
const accepted=(result,label)=>{
 if(result&&typeof result==="object"&&"value" in result)return result.value;
 throw Error("PSC1_LAZY_DELTA_UNEXPECTED_REJECTION "+label);
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
const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),Literal=get("PsKernelLiteral");
const B=get("PsKernelBinderInfo"),S=get("PsKernelDefinitionSafety");
const D=get("PsKernelDagDeclarationRequest"),Request=get("PsKernelDeclarationRequest");
const C=get("PsKernelDagCommand"),Delta=get("PsKernelDeltaResult");
const name=text=>N.str(N.anonymous,text),natName=get("psKernelNatName");
let arena=get("psKernelExprV2PagedEmpty");
const build=(kind,term,...args)=>{
 const r=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
 arena=r.fst;return {id:r.snd,term};
};
const sort=level=>build("Sort",E.sort(level),level);
const bv=index=>build("BVar",E.bvar(index),index);
const cn=(n,levels=nil)=>build("Const",E.const(n,levels),n,levels);
const app=(f,a)=>build("App",E.app(f.term,a.term),f.id,a.id);
const lit=value=>build("Lit",E.lit(Literal.nat(value)),Literal.nat(value));
const lam=(n,t,b)=>build("Lam",E.lam(n,t.term,b.term,B.default),n,t.id,b.id,B.default);
const forall=(n,t,b)=>build("Forall",E.forallE(n,t.term,b.term,B.default),n,t.id,b.id,B.default);
const letE=(n,t,v,b)=>build("Let",E.letE(n,t.term,v.term,b.term,false),n,t.id,v.id,b.id,false);
const md=(tag,b)=>build("MData",E.mdata(tag,b.term),tag,b.id);

const Ex=get("Except"),H=get("PsKernelReducibilityHints"),Node=get("PsKernelExprV2Node");
const OldStep=get("PsKernelDeltaStepResult"),Step=get("PsKernelExprV2DeltaStepResult");
const unit=v=>typeof v==="function"?v():v;
const stepEqual=unit(Step.equal),oldStepEqual=unit(OldStep.equal);
const attempt=result=>accepted(accepted(result,"some-attempt"),"successful-attempt");
const err=(attempted,message,label)=>{
 const result=accepted(attempted,label+"-some");
 must(rejected(result)&&result.error===message,label);
};
const s1=sort(L.succ(L.zero)),nat=cn(natName),fnType=forall(name("x"),nat,nat),b0=bv(0n);
const identity=lam(name("x"),nat,b0),constant=lam(name("x"),nat,lit(0n));
const apply=(text,arg)=>app(cn(name(text)),arg);
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty-session");
let session=accepted(get("psKernelV1AdmitDeclaration")(empty,Request.ordinaryInductive({
 levelParams:nil,name:natName,type:s1.term,numParams:0n,isUnsafe:false,
 ctors:list([{name:get("psKernelNatZeroName"),type:nat.term},
  {name:get("psKernelNatSuccName"),type:fnType.term}])
})),"real-Nat-admission").session;
const natRequest=D.ordinaryInductive(nil,0n,{
 name:natName,type:s1.id,ctors:list([
  {name:get("psKernelNatZeroName"),type:nat.id},
  {name:get("psKernelNatSuccName"),type:fnType.id}])},false);
let declarations=get("psKernelDagDeclarationsAfterAdmission")(natRequest,nil);
const requests=[C.admit(natRequest)];
const hints=[["Abbrev",H.abbrevHint],["Low",H.regular(1n)],["High",H.regular(7n)],["Opaque",H.opaqueHint]];
const specifications=[];
for(const [label,hint] of hints)for(const value of [0n,1n])
 specifications.push(["delta"+label+value,nil,nat,lit(value),hint]);
specifications.push(
 ["deltaAlias1",nil,nat,cn(name("deltaAbbrev0")),H.regular(8n)],
 ["deltaAlias2",nil,nat,cn(name("deltaAlias1")),H.regular(9n)],
 ["deltaConst",nil,fnType,constant,H.regular(1n)],
 ["deltaId",nil,fnType,identity,H.regular(1n)],
 ["deltaPoly",list([name("u")]),fnType,constant,H.regular(1n)]
);
for(const [text,levelParams,type,value,hint] of specifications){
 const n=name(text),base={name:n,levelParams,type:type.term};
 session=accepted(get("psKernelV1AdmitDeclaration")(session,
  Request.definitionDecl({base,value:value.term,hints:hint,safety:S.safe})),"real-definition-"+text).session;
 const request=D.definitionDecl({base:{name:n,levelParams,type:type.id},
  value:value.id,hints:hint,safety:S.safe});
 declarations=get("psKernelDagDeclarationsAfterAdmission")(request,declarations);
 requests.push(C.admit(request));
}
const base=get("psKernelKernelSessionChecker")(session,nil,S.safe);
const ctx=scalar=>get("psKernelExprV2CheckContextEmpty")(scalar);
const initial=(owned=arena,refs=declarations)=>get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(owned),
 get("psKernelExprV2WhnfStateForDeclarations")(owned,refs));
const raw=(fuel,context,state,left,right)=>
 get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(context)(state)(left)(right);
const original=(fuel,scalar,state,left,right)=>
 get("psKernelIsDefEqWithFuel")(fuel)(scalar)(state)(left)(right);
const oldEmpty=get("psKernelCheckerStateEmpty"),run=get("psKernelV1RunDag");
const compare=(expected,attempted,label)=>{
 const actual=accepted(attempted,label+"-direct");
 if(rejected(expected)){
  must(rejected(actual)&&actual.error===expected.error,label+"-exact-error");
 }else{
  const a=accepted(expected,label+"-original"),b=accepted(actual,label+"-result");
  must(typeof a.fst==="boolean"&&typeof b.snd==="boolean"&&a.fst===b.snd,label+"-decision");
  must(typeof a.snd.nextFresh==="bigint"&&a.snd.nextFresh===b.fst.nextFresh,label+"-fresh-owner");
 }
};
const comparePublic=(expected,actual,label)=>{
 if(rejected(expected))must(rejected(actual)&&same(expected.error,actual.error),label+"-public-error");
 else{
  const a=accepted(expected,label+"-original"),b=accepted(actual,label+"-public"),replies=array(b.replies);
  must(typeof a==="boolean"&&replies.length===1&&replies[0].value===a,label+"-public-decision");
 }
};
const oldCoreWith=fuel=>{
 const defeq=get("psKernelIsDefEqWithFuel")(fuel);
 return c=>s=>r=>cheapRec=>cheapProj=>
  get("psKernelWhnfCoreWithRecursorFuel")(fuel,defeq,c,s,r,cheapRec,cheapProj);
};
const coreWith=fuel=>c=>s=>r=>cheap=>
 get("psKernelExprV2CheckWhnfCoreWithFuel")(fuel,c,s,r,cheap);
const whnfWith=fuel=>c=>s=>r=>get("psKernelExprV2CheckWhnfWithFuel")(fuel,c,s,r);
const oldLazy=(fuel,callbackFuel,scalar,state,left,right)=>{
 const defeq=get("psKernelIsDefEqWithFuel")(callbackFuel);
 const whnf=c=>s=>r=>get("psKernelWhnfWithRecursorFuel")(callbackFuel,defeq,c,s,r);
 return get("psKernelDefEqLazyReductionWithFuel")(fuel)(defeq)(whnf)(oldCoreWith(callbackFuel))
  (scalar)(state)(left)(right);
};
const directLazy=(fuel,callbackFuel,context,state,left,right)=>
 get("psKernelExprV2DefEqLazyDeltaWithFuel")(
  fuel,get("psKernelExprV2TryDefEqStateWithFuel")(callbackFuel),whnfWith(callbackFuel),
  coreWith(callbackFuel),context,state,left,right);
const oldStep=(fuel,scalar,state,left,right)=>get("psKernelDefEqLazyStep")(
 get("psKernelIsDefEqWithFuel")(fuel),oldCoreWith(fuel),scalar,state,left,right);
const directStep=(fuel,context,state,left,right)=>get("psKernelExprV2DefEqLazyStepWith")(
 get("psKernelExprV2TryDefEqStateWithFuel")(fuel),coreWith(fuel),context,state,left,right);
const compareLazy=(expected,attempted,label)=>{
 if(rejected(expected)){err(attempted,expected.error,label+"-exact-error");return;}
 const a=accepted(expected,label+"-original");
 if(a.fst&&typeof a.fst.value==="boolean"&&same(a.fst,Delta.decided(a.fst.value))){
  const b=attempt(attempted);
  must(typeof b.snd==="boolean"&&b.snd===a.fst.value,label+"-decision");
  must(a.snd.nextFresh===b.fst.nextFresh,label+"-fresh");return;
 }
 must(a.fst&&"left" in a.fst&&"right" in a.fst&&
  same(a.fst,Delta.residual(a.fst.left,a.fst.right))&&same(attempted,none),label+"-explicit-fallback");
};
const compareStep=(expected,attempted,label)=>{
 if(rejected(expected)){err(attempted,expected.error,label+"-step-error");return;}
 const a=accepted(expected,label+"-original"),b=attempt(attempted);
 must(a.snd.nextFresh===b.fst.nextFresh,label+"-step-fresh");
 if(same(a.fst,oldStepEqual)){must(same(b.snd,stepEqual),label+"-equal-tag");return;}
 const kind=["different","continue","unknown"].find(tag=>
  a.fst&&"left" in a.fst&&"right" in a.fst&&same(a.fst,OldStep[tag](a.fst.left,a.fst.right)));
 must(typeof kind==="string",label+"-reference-tag");
 must(b.snd&&"left" in b.snd&&"right" in b.snd&&same(b.snd,Step[kind](b.snd.left,b.snd.right)),
  label+"-matching-step-tag");
 const decoded=accepted(get("psKernelExprV2DecodeChecked")(b.fst.whnf.arena),label+"-decode");
 const left=accepted(get("psKernelExprV2DecodedRequire")(decoded,b.snd.left),label+"-left");
 const right=accepted(get("psKernelExprV2DecodedRequire")(decoded,b.snd.right),label+"-right");
 must(get("psKernelExprEqual")(a.fst.left)(left)===true&&
  get("psKernelExprEqual")(a.fst.right)(right)===true,label+"-step-residual-ids");
};
const poly=(level,arg)=>app(cn(name("deltaPoly"),list([level])),arg);
const fixtures=[
 ["left-definition",cn(name("deltaAbbrev0")),lit(0n),true],
 ["right-definition",lit(0n),cn(name("deltaAbbrev0")),true],
 ["left-negative",cn(name("deltaAbbrev0")),lit(1n),false],
 ["greater-left-height",cn(name("deltaHigh0")),cn(name("deltaLow0")),true],
 ["greater-right-height",cn(name("deltaLow0")),cn(name("deltaHigh0")),true],
 ["abbrev-before-opaque",cn(name("deltaAbbrev0")),cn(name("deltaOpaque0")),true],
 ["opaque-after-abbrev",cn(name("deltaOpaque0")),cn(name("deltaAbbrev0")),true],
 ["three-step-chain",cn(name("deltaAlias2")),lit(0n),true],
 ["three-step-negative",cn(name("deltaAlias2")),lit(1n),false],
 ["failed-args-still-equal",apply("deltaConst",lit(0n)),apply("deltaConst",lit(1n)),true],
 ["failed-args-different",apply("deltaId",lit(0n)),apply("deltaId",lit(1n)),false],
 ["one-sided-beta",apply("deltaId",lit(1n)),lit(1n),true],
 ["original-metadata-pair",md(7n,cn(name("deltaAlias2"))),lit(0n),true],
 ["zeta-chain",letE(name("v"),nat,cn(name("deltaAlias2")),b0),lit(0n),true],
 ["beta-chain",app(identity,cn(name("deltaAlias2"))),lit(0n),true],
 ["equivalent-universes",poly(L.zero,lit(0n)),poly(L.max(L.zero,L.zero),lit(1n)),true],
 ["different-universes",poly(L.zero,lit(0n)),poly(L.succ(L.zero),lit(0n)),true],
 ["two-hints-negative",cn(name("deltaHigh1")),cn(name("deltaOpaque0")),false],
 ["unknown-definition",cn(name("deltaMissing")),lit(0n),null],
 ["invalid-level-arity",apply("deltaPoly",lit(0n)),lit(0n),null]
];
let comparisons=0;
for(const [label,left,right,decision] of fixtures){
 for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,16n,64n])
  for(const maxRecDepth of [0n,1n,2n])for(const recDepth of [0n,15n,16n]){
   const scalar={...base.context,maxRecDepth,recDepth};
   compare(original(fuel,scalar,oldEmpty,left.term,right.term),
    raw(fuel,ctx(scalar),initial(),left.id,right.id),label+"-"+fuel+"-"+maxRecDepth+"-"+recDepth);
   comparisons++;
  }
 const direct=accepted(get("psKernelExprV2TryDefEqWithDeclarationsFuel")(
  64n,base.context,arena,declarations,left.id,right.id),label+"-selected");
 if(decision===null)must(rejected(direct),label+"-high-budget-error");
 else must(accepted(direct,label+"-high-budget")===decision,label+"-high-budget-direct");
 for(const fuel of [0n,1n,2n,4n,8n,64n]){
  const limited={...session,resources:{...session.resources,fuel}};
  comparePublic(get("psKernelV1IsDefEq")(limited,nil,S.safe,left.term,right.term),
   run(limited,nil,S.safe,arena,list([C.isDefEq(left.id,right.id)])),label+"-"+fuel);
 }
 if(decision!==null){
  const batch=accepted(run(empty,nil,S.safe,arena,list([...requests,C.isDefEq(left.id,right.id)])),
   label+"-checked-same-batch");
  const replies=array(batch.replies);
  must(replies.length===requests.length+1&&replies.at(-1).value===decision,label+"-checked-batch-decision");
 }
}
must(comparisons===1800,"complete-raw-matrix");
let stageComparisons=0,stepComparisons=0;
for(const [leftHint] of hints)for(const [rightHint] of hints)for(const orientation of [false,true]){
 const left=cn(name("delta"+leftHint+(orientation?"1":"0")));
 const right=cn(name("delta"+rightHint+(orientation?"0":"1")));
 for(const callbackFuel of [0n,1n,4n,64n]){
  compareStep(oldStep(callbackFuel,base.context,oldEmpty,left.term,right.term),
   directStep(callbackFuel,ctx(base.context),initial(),left.id,right.id),"all-hint-single-step");
  stepComparisons++;
  for(const fuel of [0n,1n,2n,4n])for(const eagerReduce of [false,true]){
   const scalar={...base.context,eagerReduce};
   compareLazy(oldLazy(fuel,callbackFuel,scalar,oldEmpty,left.term,right.term),
    directLazy(fuel,callbackFuel,ctx(scalar),initial(),left.id,right.id),"all-hint-loop");
   stageComparisons++;
  }
 }
}
must(stageComparisons===1024&&stepComparisons===128,"complete-stage-matrix");

const context=ctx(base.context),left=apply("deltaConst",lit(0n)),right=apply("deltaConst",lit(1n));
const zero=lit(0n),one=lit(1n),cold=initial();
const warm=attempt(raw(64n,context,cold,left.id,right.id));
const oldWarm=accepted(original(64n,base.context,oldEmpty,left.term,right.term),"old-warm");
must(warm.snd===true&&oldWarm.fst===true,"failed-args-do-not-mean-inequality");
must(!same(warm.fst.inferOnly,nil)&&same(warm.fst.checkedInfer,nil)&&
 !same(warm.fst.unfold,nil)&&!same(warm.fst.failure,nil),"nonprop-state-survives-full-delta");
const contains=(state,cache,l,r)=>accepted(get("psKernelExprV2DefEqPairContains")(
 state.whnf.arena,state[cache],l,r),"pair-contains");
for(const [l,r] of [[left.id,right.id],[right.id,left.id]])
 must(contains(warm.fst,"failure",l,r)===true,"failure-pair-is-symmetric");
must(get("psKernelExprPairSetContains")(oldWarm.snd.failure,left.term,right.term)===true&&
 get("psKernelExprPairSetContains")(oldWarm.snd.failure,right.term,left.term)===true,
 "original-failure-pair-is-symmetric");
must(contains(warm.fst,"success",left.id,right.id)===true,"original-success-published");
must(contains(warm.fst,"success",zero.id,one.id)===false,"unequal-arguments-never-success");
for(const root of [left.id,right.id]){
 const entry=accepted(get("psKernelExprV2PagedRequire")(warm.fst.whnf.arena,root),"unfold-entry");
 const found=accepted(get("psKernelExprV2WhnfCacheFindIn")(warm.fst.unfold)
  (warm.fst.whnf.arena)(root)(entry.hash),"unfold-cache");
 must(!same(found,none),"unfold-cache-published-both-sides");
}
for(const fuel of [0n,1n,64n])for(const recDepth of [0n,15n,16n]){
 const scalar={...base.context,maxRecDepth:1n,recDepth};
 compare(original(fuel,scalar,oldWarm.snd,left.term,right.term),
  raw(fuel,ctx(scalar),warm.fst,left.id,right.id),"warm-entry-guards");
}
const badDefEq=_c=>_s=>_l=>_r=>Option.some(Ex.error("arguments-called"));
const oldBadDefEq=_c=>_s=>_l=>_r=>Ex.error("arguments-called");
const core=coreWith(64n),oldCore=oldCoreWith(64n);
const step=get("psKernelExprV2DefEqLazyStepWith"),originalStep=get("psKernelDefEqLazyStep");
const coldError=step(badDefEq,core,context,cold,left.id,right.id);
compareStep(originalStep(oldBadDefEq,oldCore,base.context,oldEmpty,left.term,right.term),
 coldError,"cold-argument-callback-error");
err(coldError,"arguments-called","cold-callback-ran");
for(const [l,r] of [[left,right],[right,left]]){
 const hit=step(badDefEq,core,context,warm.fst,l.id,r.id);
 compareStep(originalStep(oldBadDefEq,oldCore,base.context,oldWarm.snd,l.term,r.term),
  hit,"failure-hit-skips-only-args");
 must(same(attempt(hit).snd,stepEqual),"failure-hit-still-unfolds-equal");
}
const child=get("psKernelExprV2CheckStateFreshName")(warm.fst,name("scope")).snd;
const restored=get("psKernelExprV2CheckStateExitLocalScope")(cold,child);
must(same(restored.unfold,nil)&&same(restored.failure,nil)&&
 restored.whnf.arena.size===child.whnf.arena.size&&restored.nextFresh===child.nextFresh,
 "scope-restores-delta-caches");
err(step(badDefEq,core,context,restored,left.id,right.id),"arguments-called",
 "scope-cannot-reuse-child-failure");
const preserved=get("psKernelExprV2CheckStateWithInferOnly")(
 get("psKernelExprV2CheckStateWithArena")(
  get("psKernelExprV2CheckStateWithSuccess")(child,child.success),child.whnf.arena),child.inferOnly);
must(array(preserved.unfold).length===array(child.unfold).length&&
 contains(preserved,"failure",left.id,right.id)===true,"setters-preserve-delta-caches");

// Continue the same arena owner before constructing further collision/adversarial roots.
arena=warm.fst.whnf.arena;
must(same(get("psKernelExprV2DefEqUnfold")(context,initial(arena,nil),left.id),none),
 "missing-selected-body-declines");
must(same(attempt(directStep(64n,context,initial(arena,nil),left.id,left.id)).snd,stepEqual),
 "same-args-shortcut-does-not-preflight-body");
const selectedLeft=cn(name("deltaAbbrev0")),selectedRight=cn(name("deltaHigh1"));
const selectedRef=accepted(get("psKernelExprV2DeclarationRefFind")(declarations)(name("deltaAbbrev0")),
 "selected-reference");
const selected=directStep(64n,context,initial(arena,list([selectedRef])),selectedLeft.id,selectedRight.id);
compareStep(oldStep(64n,base.context,oldEmpty,selectedLeft.term,selectedRight.term),
 selected,"unselected-missing-body-is-not-preflighted");
const selectedResult=attempt(selected).snd;
must(same(selectedResult,Step.continue(selectedResult.left,selectedResult.right)),
 "selected-one-side-continues");
const corruptRef={...selectedRef,kind:get("PsKernelExprV2DeclarationRefKind").axiomDecl};
must(same(get("psKernelExprV2DefEqUnfold")(
 context,initial(arena,list([corruptRef])),selectedLeft.id),none),"mismatched-owning-ref-declines");
const badArity=apply("deltaPoly",lit(0n));
const arityResult=attempt(directStep(64n,context,initial(),badArity.id,zero.id)).snd;
must(same(arityResult,Step.unknown(badArity.id,zero.id)),"raw-invalid-arity-no-definition");
must(same(directLazy(4n,64n,context,initial(),badArity.id,zero.id),none),
 "raw-arity-residual-explicit-fallback");

const collision=apply("deltaConst",lit(65521n));
const collisionState=get("psKernelExprV2CheckStateWithArena")(warm.fst,arena);
const first=accepted(get("psKernelExprV2PagedRequire")(arena,left.id),"collision-left");
const second=accepted(get("psKernelExprV2PagedRequire")(arena,collision.id),"collision-right");
must(first.hash===second.hash&&
 accepted(get("psKernelExprV2PagedEqOnCanonical")(arena,left.id,collision.id),"collision-eq")===false,
 "real-failure-key-hash-collision");
err(step(badDefEq,core,context,collisionState,collision.id,right.id),"arguments-called",
 "failure-collision-does-not-suppress-args");
const idZero=apply("deltaId",lit(0n)),idCollision=apply("deltaId",lit(65521n));
const primed=attempt(get("psKernelExprV2DefEqUnfold")(context,initial(),idZero.id));
const collided=attempt(get("psKernelExprV2DefEqUnfold")(context,primed.fst,idCollision.id));
const unfoldedId=accepted(collided.snd,"collided-unfold-root");
const decoded=accepted(get("psKernelExprV2DecodeChecked")(collided.fst.whnf.arena),"collision-decode");
const observed=accepted(get("psKernelExprV2DecodedRequire")(decoded,unfoldedId),"collision-read");
const oldPrimed=get("psKernelDefEqUnfold")(base.context,oldEmpty,idZero.term);
const oldCollided=get("psKernelDefEqUnfold")(base.context,oldPrimed.snd,idCollision.term);
must(get("psKernelExprEqual")(observed)(accepted(oldCollided.fst,"old-collision"))===true,
 "unfold-collision-miss-exact-result");
must(accepted(get("psKernelExprV2PagedRequire")(arena,idZero.id),"id-first").hash===
 accepted(get("psKernelExprV2PagedRequire")(arena,idCollision.id),"id-second").hash,
 "real-unfold-key-hash-collision");
must(array(collided.fst.unfold).length===array(primed.fst.unfold).length+1,
 "collision-inserts-distinct-unfold");
arena=collided.fst.whnf.arena;

const localL=name("openLeft"),localR=name("openRight");
const openLeft=apply("deltaConst",build("FVar",E.fvar(localL),localL));
const openRight=apply("deltaConst",build("FVar",E.fvar(localR),localR));
const falseDefEq=_c=>s=>_l=>_r=>Option.some(Ex.ok({fst:{...s,nextFresh:s.nextFresh+1n},snd:false}));
const oldFalseDefEq=_c=>s=>_l=>_r=>Ex.ok({fst:false,snd:{...s,nextFresh:s.nextFresh+1n}});
const opened=step(falseDefEq,core,context,initial(),openLeft.id,openRight.id);
compareStep(originalStep(oldFalseDefEq,oldCore,base.context,oldEmpty,openLeft.term,openRight.term),
 opened,"open-argument-state");
const openedResult=attempt(opened);
must(same(openedResult.fst.failure,nil)&&same(openedResult.fst.unfold,nil)&&
 openedResult.fst.nextFresh===1n,"open-inputs-do-not-publish-delta-caches");
must(same(openedResult.snd,stepEqual),"open-failed-args-still-unfold-equal");
const argLeft=app(left,lit(1n));
const inner=name("inner"),argRight=app(apply("deltaConst",build("MVar",E.mvar(inner),inner)),lit(2n));
const orderDefEq=_c=>s=>l=>_r=>{
 const entry=get("psKernelExprV2PagedRequire")(s.whnf.arena,l);
 if(rejected(entry))return Option.some(Ex.error(entry.error));
 return Option.some(Ex.error(same(accepted(entry,"argument-order").node,Node.lit(Literal.nat(1n)))?
  "rightmost-first":"wrong-inner-order"));
};
const oldOrderDefEq=_c=>_s=>l=>_r=>Ex.error(
 same(l,E.lit(Literal.nat(1n)))?"rightmost-first":"wrong-inner-order");
for(const other of [argRight,right]){
 const actual=get("psKernelExprV2DefEqArgs")(orderDefEq,context,initial(),argLeft.id,other.id);
 compare(get("psKernelDefEqArgs")(oldOrderDefEq,base.context,oldEmpty,argLeft.term,other.term),
  actual,"rightmost-before-inner-or-arity");
 err(actual,"rightmost-first","rightmost-callback-was-first");
}
err(get("psKernelExprV2DefEqArgsWithFuel")(0n)(badDefEq)(context)(cold)
 (cold.whnf.arena.size+1n)(cold.whnf.arena.size+2n),"kernel defeq argument budget exhausted",
 "argument-zero-before-roots-and-callback");

const projName=name("unownedProjection");
const projection=app(build("Proj",E.proj(projName,0n,zero.term),projName,0n,zero.id),one);
const projectionCore=_c=>_s=>_r=>cheap=>
 Option.some(Ex.error(cheap?"definition-too-early":"projection-first"));
const oldProjectionCore=_c=>_s=>_r=>cheapRec=>cheapProj=>
 Ex.error(cheapRec?"wrong-recursor-mode":cheapProj?"definition-too-early":"projection-first");
for(const [l,r] of [[selectedLeft,projection],[projection,selectedLeft]]){
 const actual=step(badDefEq,projectionCore,context,initial(),l.id,r.id);
 compareStep(originalStep(oldBadDefEq,oldProjectionCore,base.context,oldEmpty,l.term,r.term),
  actual,"projection-peer-first");
 err(actual,"projection-first","projection-core-mode");
}
const low0=cn(name("deltaLow0")),low1=cn(name("deltaLow1"));
const leftFirstCore=_c=>s=>root=>cheap=>{
 const entry=get("psKernelExprV2PagedRequire")(s.arena,root);
 if(rejected(entry))return Option.some(Ex.error(entry.error));
 const message=cheap?(same(accepted(entry,"left-order").node,Node.lit(Literal.nat(0n)))?
  "left-unfold-first":"right-unfold-too-early"):"wrong-projection-mode";
 return Option.some(Ex.error(message));
};
const oldLeftFirstCore=_c=>_s=>expr=>cheapRec=>cheapProj=>
 Ex.error(cheapRec?"wrong-recursor-mode":cheapProj?
  (same(expr,E.lit(Literal.nat(0n)))?"left-unfold-first":"right-unfold-too-early"):"wrong-projection-mode");
const ordered=step(badDefEq,leftFirstCore,context,initial(),low0.id,low1.id);
compareStep(originalStep(oldBadDefEq,oldLeftFirstCore,base.context,oldEmpty,low0.term,low1.term),
 ordered,"both-definition-left-before-right");
err(ordered,"left-unfold-first","left-unfold-callback-was-first");

const alias=cn(name("deltaAlias2"));
for(const fuel of [0n,1n,2n,3n,4n])
 compareLazy(oldLazy(fuel,1n,base.context,oldEmpty,alias.term,zero.term),
  directLazy(fuel,1n,context,initial(),alias.id,zero.id),"fixed-callback-across-three-steps");
must(attempt(directLazy(3n,1n,context,initial(),alias.id,zero.id)).snd===true,
 "three-steps-use-fixed-callback-fuel");
err(directLazy(2n,1n,context,initial(),alias.id,zero.id),"kernel lazy-delta budget exhausted",
 "two-loop-steps-exhaust-own-budget");
err(directLazy(0n,64n,context,cold,cold.whnf.arena.size+1n,cold.whnf.arena.size+2n),
 "kernel lazy-delta budget exhausted","lazy-zero-before-invalid-roots");
const blocked={...base.context,maxRecDepth:1n,recDepth:16n};
compareLazy(oldLazy(1n,0n,blocked,oldEmpty,zero.term,zero.term),
 directLazy(1n,0n,ctx(blocked),cold,zero.id,zero.id),"lazy-helper-no-extra-depth-entry");
must(same(directLazy(1n,64n,context,cold,zero.id,one.id),none),"unknown-residual-is-not-negative");
must(same(directLazy(4n,64n,context,initial(arena,nil),alias.id,zero.id),none),
 "missing-reference-propagates-through-loop");
const continueLazy=get("psKernelExprV2DefEqLazyDeltaContinueWithFuel");
const declined=continueLazy(4n,_c=>_s=>_l=>_r=>Option.some(Ex.ok({fst:cold,snd:true})),
 get("psKernelExprV2TryDefEqStateWithFuel")(64n),whnfWith(64n),core,
 context,initial(arena,nil),alias.id,zero.id);
must(same(declined,none),"outer-none-does-not-run-success-continuation");
err(continueLazy(1n,_c=>_s=>_l=>_r=>Option.some(Ex.error("residual-reached")),
 get("psKernelExprV2TryDefEqStateWithFuel")(64n),whnfWith(64n),core,context,cold,zero.id,one.id),
 "residual-reached","only-residual-runs-later-stage");
const metadata=md(7n,alias);
const metadataResult=attempt(raw(64n,context,initial(),metadata.id,zero.id));
must(metadataResult.snd===true&&contains(metadataResult.fst,"success",metadata.id,zero.id)===true,
 "delta-success-publishes-original-metadata-pair");
must(contains(metadataResult.fst,"success",alias.id,zero.id)===false,
 "delta-success-does-not-publish-normalized-pair");

const invalid=apply("deltaId",s1);
const invalidResult=run(empty,nil,S.safe,arena,list([...requests,C.check(invalid.id)]));
must(rejected(invalidResult)&&same(invalidResult.error,
 get("PsKernelError").rejectedInvalid(invalidResult.error.message)),
 "checked-api-rejects-invalid-definition-argument");
const badName=name("deltaRejectedBody");
const badRequest=D.definitionDecl({
 base:{name:badName,levelParams:nil,type:nat.id},value:s1.id,hints:H.regular(1n),safety:S.safe});
const badResult=run(empty,nil,S.safe,arena,list([...requests,C.admit(badRequest)]));
must(rejected(badResult)&&same(badResult.error,
 get("PsKernelError").rejectedInvalid(badResult.error.message)),
 "checked-api-rejects-invalid-definition-body");
must(same(get("psKernelEnvironmentFind")(session.environment,badName),none),
 "failed-batch-does-not-publish");

/* Direct cache-lookup regressions use internal observations only. They never
   enter the untrusted checked boundary as proof certificates. */
{
 const pairArena=arena,pairRoot=zero.id,pairMarked=metadata.id;
 const pairHit={left:pairRoot,right:pairMarked,hash:0n};
 const pairCollision={left:one.id,right:one.id,hash:0n};
 const pairList=list([pairCollision,pairHit]);
 const find=get("psKernelExprV2DefEqPairFindIn");
 const query=(left,right,hash=0n)=>accepted(find(pairList)(pairArena)(left)(right)(hash),"pair-scan");
 must(query(pairRoot,pairMarked)===true,"pair-scan-collision-then-hit");
 must(query(pairMarked,pairRoot)===true,"pair-scan-reversed");
 must(query(pairRoot,one.id)===false,"pair-scan-collision-miss");
 must(query(pairRoot,pairMarked,1n)===false,"pair-scan-hash-miss");
 must(accepted(find(nil)(pairArena)(pairArena.size+1n)(0n)(0n),"pair-empty")===false,
  "pair-scan-empty-invalid-is-miss");
 const bad=list([{left:pairArena.size+1n,right:one.id,hash:0n}]);
 const badResult=find(bad)(pairArena)(pairRoot)(one.id)(0n);
 must(rejected(badResult)&&badResult.error==="PSKERNEL_V2_PAIR_CHECK_INVALID_RIGHT",
  "pair-scan-invalid-matching-candidate-preserves-error");
 const parent=get("psKernelExprV2CheckStateWithSuccess")(initial(pairArena,nil),list([pairHit]));
 const child=get("psKernelExprV2CheckStateWithSuccess")(parent,pairList);
 const restored=get("psKernelExprV2CheckStateExitLocalScope")(parent,child);
 must(array(restored.success).length===1&&same(array(restored.success)[0],pairHit),
  "pair-scan-scope-restores-parent");
 const localBuilt=accepted(get("psKernelExprV2PagedMkFVar")(pairArena,name("pair-scope")),"pair-local");
 const localResult=accepted(get("psKernelExprV2CheckStateDefEqFinish")(
  initial(localBuilt.fst,nil),localBuilt.snd,localBuilt.snd,true),"pair-local-finish");
 must(array(localResult.fst.success).length===0,"pair-scan-free-variable-not-cached");
 err(get("psKernelExprV2TryDefEqStateWithFuel")(0n)(context)(parent)(pairArena.size+1n)(pairRoot),
  "kernel definitional equality budget exhausted","pair-scan-zero-before-cache-invalid");
 // Isolated current-implementation timing. A generated before/after comparison
 // must run this same file against the parent and candidate generated modules.
 const scanPairs=list(Array.from({length:1024},(_,i)=>({left:pairRoot,right:pairRoot,hash:BigInt(i+1)})));
 let checksum=0;
 const started=performance.now();
 for(let i=0;i<200;i++){
  const value=accepted(find(scanPairs)(pairArena)(pairRoot)(pairRoot)(2000n+BigInt(i%3)),"pair-bench");
  if(value===false)checksum++;
 }
 must(checksum===200,"pair-scan-benchmark-values");
 console.log("PSC1_V2_PAIR_SCAN_JS_SAMPLE "+JSON.stringify({
  entries:1024,calls:200,elapsed_ms:performance.now()-started,checksum,
  scope:"isolated hash-miss cache scan; whole-kernel speedup not inferred"}));
 console.log("PSC1_V2_PAIR_SCAN_JS: PASS");
}

console.log("PSC1_V2_DAG_JS_LAZY_DELTA: PASS comparisons="+comparisons+
 " stage="+stageComparisons+" steps="+stepComparisons+" assertions="+assertions);
