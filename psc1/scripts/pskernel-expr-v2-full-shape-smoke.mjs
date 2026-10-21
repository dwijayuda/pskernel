import { pathToFileURL } from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_FULL_SHAPE_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{
  if(!(name in k))throw Error("PSC1_FULL_SHAPE_MISSING_EXPORT "+name);
  return k[name];
};
let assertions=0;
const must=(value,label)=>{
  if(value!==true)throw Error("PSC1_FULL_SHAPE_FAILED "+label);
  assertions++;
};
const accepted=(result,label)=>{
  if(result&&typeof result==="object"&&"value" in result)return result.value;
  throw Error("PSC1_FULL_SHAPE_UNEXPECTED_REJECTION "+label);
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
const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
const Except=get("Except");
const ok=(state,value)=>Option.some(Except.ok({fst:state,snd:value}));
const error=text=>Option.some(Except.error(text));
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
const lam=(n,t,b,info=B.default)=>build("Lam",E.lam(n,t.term,b.term,info),n,t.id,b.id,info);
const forall=(n,t,b,info=B.default)=>build("Forall",E.forallE(n,t.term,b.term,info),n,t.id,b.id,info);
const md=(tag,b)=>build("MData",E.mdata(tag,b.term),tag,b.id);
const lit=value=>build("Lit",E.lit(value),value);
const proj=(n,i,b)=>build("Proj",E.proj(n,i,b.term),n,i,b.id);
const s0=sort(L.zero),s1=sort(L.succ(L.zero)),b0=bv(0n),u=cn("shapeU");
const functionType=forall(name("argument"),u,u,B.implicit);
const specifications=[
 ["shapeU",s1],["shapeA",u],["shapeB",u],["shapeF",functionType],
 ["shapeH",forall(name("x"),u,functionType)]
];
const empty=accepted(get("psKernelKernelSessionEmpty")(
  get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty-session");
let session=empty,declarations=nil;
for(const [text,type] of specifications){
 const n=name(text);
 session=accepted(get("psKernelV1AdmitDeclaration")(session,
  Request.axiomDecl({base:{name:n,levelParams:nil,type:type.term},isUnsafe:false})),"fixture-admission").session;
 declarations=get("psKernelDagDeclarationsAfterAdmission")(
  D.axiomDecl({name:n,levelParams:nil,type:type.id},false),declarations);
}
const f=cn("shapeF"),a=cn("shapeA"),h=cn("shapeH");
const eta=lam(name("eta"),u,app(f,b0));
const etaOtherName=lam(name("other"),u,app(f,b0),B.strictImplicit);
const identity=lam(name("x"),u,b0),identityOtherName=lam(name("y"),u,b0,B.implicit);
const appLeft=app(app(h,s0),s1),appRight=app(app(h,s0),s1);
const Literal=get("PsKernelLiteral"),n7=lit(Literal.nat(7n)),n8=lit(Literal.nat(8n));
const invalid=app(f,s0),invalidRight=app(f,s1);
const stageFixtures=[
 ["sort-equal",s0,s0],["sort-different",s0,s1],
 ["nat-equal",n7,n7],["nat-different",n7,n8],
 ["string-different",lit(Literal.str("a")),lit(Literal.str("b"))],
 ["shape-mismatch",s0,n7],["terminal-undecided",f,a],
 ["lambda-alpha",identity,identityOtherName],
 ["lambda-domain-different",lam(name("x"),s0,b0),lam(name("x"),s1,b0)],
 ["forall-alpha",functionType,forall(name("other"),u,u)],
 ["forall-domain-different",forall(name("x"),s0,s0),forall(name("x"),s1,s0)],
 ["app-equal",appLeft,appRight],["app-argument-different",invalid,invalidRight],
 ["app-arity-different",invalid,app(invalid,s1)],
 ["eta-left",eta,f],["eta-right",f,eta],["eta-nonfunction",eta,a],
 ["eta-unknown",eta,cn("shapeMissing")],["eta-metavariable",mv(name("untrusted")),eta]
];
const metadata=md(17n,eta),metadataRight=md(19n,eta);
const ownerFixtures=[
 ["eta-left",eta,f],["eta-right",f,eta],["eta-alpha",etaOtherName,f],
 ["eta-metadata-left",metadata,f],["eta-metadata-right",f,metadataRight],
 ["eta-applied",app(eta,a),app(f,a)]
];
const shortApp=app(h,s0),projection=proj(name("unadmittedStruct"),0n,a);
const base=get("psKernelKernelSessionChecker")(session,nil,S.safe);
const ctx=scalar=>get("psKernelExprV2CheckContextEmpty")(scalar);
const initial=()=>get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(arena),
 get("psKernelExprV2WhnfStateForDeclarations")(arena,declarations));
const raw=(fuel,context,state,left,right)=>
 get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(context)(state)(left)(right);
const original=(fuel,scalar,state,left,right)=>
 get("psKernelIsDefEqWithFuel")(fuel)(scalar)(state)(left)(right);
const oldEmpty=get("psKernelCheckerStateEmpty"),run=get("psKernelV1RunDag");
const compare=(expected,attempted,label,stage=false)=>{
 const actual=accepted(attempted,label+"-direct");
 if(rejected(expected)){
  must(rejected(actual)&&actual.error===expected.error,label+"-exact-error");
 }else{
  const a=accepted(expected,label+"-original"),b=accepted(actual,label+"-result");
  must(stage?same(a.fst,b.snd):a.fst===b.snd,label+"-decision");
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
const shape=get("psKernelExprV2DefEqFullShapeWith");
const residual=get("psKernelExprV2DefEqResidualWith");
let stageComparisons=0;
for(const [label,left,right] of stageFixtures)
 for(const fuel of [0n,1n,2n,4n,8n,64n])
  for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
   const scalar={...base.context,maxRecDepth,recDepth};
   const defeq=get("psKernelIsDefEqWithFuel")(fuel);
   const whnf=c=>s=>r=>get("psKernelWhnfWithRecursorFuel")(fuel,defeq,c,s,r);
   const infer=c=>s=>r=>get("psKernelInferWithRecursorFuel")(fuel,defeq,c,s,r);
   const dagDefEq=get("psKernelExprV2TryDefEqStateWithFuel")(fuel);
   const dagWhnf=c=>s=>r=>get("psKernelExprV2CheckWhnfWithFuel")(fuel,c,s,r);
   const dagInfer=c=>s=>r=>get("psKernelExprV2TryInferCoreWithFuel")(fuel)(
    dagWhnf)(dagDefEq)(c)(s)(r)(true);
   compare(get("psKernelDefEqFullShapeWith")(
    defeq,infer,whnf,scalar,oldEmpty,left.term,right.term),
    shape(dagDefEq,dagInfer,dagWhnf,ctx(scalar),initial(),left.id,right.id),
    label+"-stage-"+fuel+"-"+maxRecDepth+"-"+recDepth,true);
   stageComparisons++;
  }
must(stageComparisons===342,"complete-stage-matrix");
let ownerComparisons=0;
for(const [label,left,right] of ownerFixtures){
 for(const fuel of [0n,1n,2n,4n,8n,64n])
  for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
   const scalar={...base.context,maxRecDepth,recDepth};
   compare(original(fuel,scalar,oldEmpty,left.term,right.term),
    raw(fuel,ctx(scalar),initial(),left.id,right.id),
    label+"-owner-"+fuel+"-"+maxRecDepth+"-"+recDepth);
   ownerComparisons++;
  }
 for(const fuel of [0n,1n,2n,4n,8n,64n]){
  const limited={...session,resources:{...session.resources,fuel}};
  comparePublic(get("psKernelV1IsDefEq")(limited,nil,S.safe,left.term,right.term),
   run(limited,nil,S.safe,arena,list([C.isDefEq(left.id,right.id)])),label+"-"+fuel);
 }
 const high=accepted(accepted(raw(64n,ctx(base.context),initial(),left.id,right.id),
  label+"-high-some"),label+"-high-result");
 must(high.snd===true,label+"-official-fixture-positive");
}
must(ownerComparisons===108,"complete-owner-matrix");
const context=ctx(base.context),cold=initial();
const noInfer=c=>s=>r=>error("FULL_SHAPE_UNEXPECTED_INFER");
const noWhnf=c=>s=>r=>error("FULL_SHAPE_UNEXPECTED_WHNF");
const noDefEq=c=>s=>l=>r=>error("FULL_SHAPE_HEAD_FIRST");
const expectError=(attempt,expected,label)=>{
 const result=accepted(attempt,label+"-some");
 must(rejected(result)&&result.error===expected,label);
};
const expectStage=(attempt,value,fresh,label)=>{
 const result=accepted(accepted(attempt,label+"-some"),label+"-result");
 must(same(result.snd,value)&&result.fst.nextFresh===fresh,label);
};
expectError(shape(noDefEq,noInfer,noWhnf,context,cold,appLeft.id,shortApp.id),
 "FULL_SHAPE_HEAD_FIRST","app-head-before-arity");
const trace=c=>s=>l=>r=>{
 const expected=s.nextFresh===0n?h.id:s.nextFresh===1n?s0.id:s1.id;
 return l===expected&&r===expected&&c.scalar.recDepth===context.scalar.recDepth
  ?ok({...s,nextFresh:s.nextFresh+1n},true):error("FULL_SHAPE_ARGUMENT_ORDER");
};
expectStage(shape(trace,noInfer,noWhnf,context,cold,appLeft.id,appLeft.id),
 Option.some(true),3n,"app-left-to-right-and-no-extra-depth");
const falseAfterHead=c=>s=>l=>r=>ok({...s,nextFresh:s.nextFresh+1n},s.nextFresh===0n);
expectStage(shape(falseAfterHead,noInfer,noWhnf,context,cold,appLeft.id,appLeft.id),
 none,2n,"failed-argument-is-undecided");
const decline=c=>s=>l=>r=>none;
must(same(shape(decline,noInfer,noWhnf,context,cold,appLeft.id,appLeft.id),none),
 "unsupported-child-escapes-no-state");
expectError(get("psKernelExprV2DefEqFullShapeListsWithFuel")(0n)(trace)(context)(cold)(nil)(nil),
 "kernel defeq argument-list budget exhausted","argument-list-zero-fuel-before-empty");
const sameWhnf=c=>s=>r=>ok(s,r);
const coreError=c=>s=>r=>cheap=>error(cheap?"FULL_SHAPE_CHEAP_PROJECTION":
 r===s0.id?"FULL_SHAPE_LEFT_CORE":"FULL_SHAPE_RIGHT_CORE");
expectError(residual(noDefEq,noInfer,sameWhnf,coreError,context,cold,s0.id,s1.id),
 "FULL_SHAPE_LEFT_CORE","full-core-left-error-first");
const coreIdentity=c=>s=>r=>cheap=>cheap?error("FULL_SHAPE_CHEAP_PROJECTION"):ok(s,r);
must(same(residual(noDefEq,noInfer,noWhnf,coreError,context,cold,
 projection.id,projection.id),none),"matching-projection-declines-before-full-core");
must(same(residual(noDefEq,noInfer,sameWhnf,coreIdentity,context,cold,f.id,a.id),none),
 "residual-terminal-rule-remains-unsupported");
must(accepted(accepted(residual(noDefEq,noInfer,sameWhnf,coreIdentity,
 context,cold,s0.id,s1.id),"sort-negative-some"),"sort-negative").snd===false,
 "sort-negative-is-final");
const changedCore=c=>s=>r=>cheap=>cheap?error("FULL_SHAPE_CHEAP_PROJECTION"):ok(s,s1.id);
const changedCompare=c=>s=>l=>r=>l===s1.id&&r===s1.id?ok(s,false):error("FULL_SHAPE_CHANGED_PAIR");
must(accepted(accepted(residual(changedCompare,noInfer,sameWhnf,changedCore,
 context,cold,s0.id,s1.id),"changed-some"),"changed-result").snd===false,
 "changed-full-roots-use-owning-callback");
const warm=accepted(accepted(raw(64n,context,cold,metadata.id,f.id),"warm-some"),"warm-result");
must(warm.snd===true,"warm-eta-is-true");
const contains=(left,right)=>accepted(get("psKernelExprV2DefEqPairContains")(
 warm.fst.whnf.arena,warm.fst.success,left,right),"success-membership");
must(contains(metadata.id,f.id)===true,"success-original-pair");
must(contains(eta.id,f.id)===false,"success-not-residual-pair");
const oldWarm=accepted(original(64n,base.context,oldEmpty,metadata.term,f.term),"old-warm");
for(const fuel of [0n,1n,64n])for(const recDepth of [0n,15n,16n]){
 const scalar={...base.context,maxRecDepth:1n,recDepth};
 compare(original(fuel,scalar,oldWarm.snd,metadata.term,f.term),
  raw(fuel,ctx(scalar),warm.fst,metadata.id,f.id),"warm-fuel-depth-guards");
}
must(same(get("psKernelExprV2TryDefEqWithDeclarationsFuel")(
 64n,base.context,arena,nil,metadata.id,f.id),none),"missing-owner-index-is-not-authorized-by-eta");
const invalidResult=run(session,nil,S.safe,arena,list([C.isDefEq(invalid.id,invalid.id)]));
const expectedInvalid=get("psKernelV1IsDefEq")(session,nil,S.safe,invalid.term,invalid.term);
must(rejected(invalidResult)&&rejected(expectedInvalid)&&same(invalidResult.error,expectedInvalid.error),
 "public-rejects-illtyped-application");
console.log("PSC1_V2_DAG_JS_FULL_SHAPE: PASS stageComparisons="+stageComparisons+
 " ownerComparisons="+ownerComparisons+" assertions="+assertions);
