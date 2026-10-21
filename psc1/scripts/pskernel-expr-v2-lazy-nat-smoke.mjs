import { pathToFileURL } from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_LAZY_NAT_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{
 if(!(name in k))throw Error("PSC1_LAZY_NAT_MISSING_EXPORT "+name);
 return k[name];
};
let assertions=0;
const must=(value,label)=>{
 if(value!==true)throw Error("PSC1_LAZY_NAT_FAILED "+label);
 assertions++;
};
const accepted=(result,label)=>{
 if(result&&typeof result==="object"&&"value" in result)return result.value;
 throw Error("PSC1_LAZY_NAT_UNEXPECTED_REJECTION "+label);
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
const s1=sort(L.succ(L.zero)),nat=cn(natName),zero=cn(get("psKernelNatZeroName"));
const succFn=cn(get("psKernelNatSuccName")),succ=value=>app(succFn,value);
const succType=forall(name("n"),nat,nat);
const binaryType=forall(name("a"),nat,forall(name("b"),nat,nat));
const binary=(text,left,right)=>app(app(cn(N.str(natName,text)),left),right);
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty-session");
let session=accepted(get("psKernelV1AdmitDeclaration")(empty,Request.ordinaryInductive({
 levelParams:nil,name:natName,type:s1.term,numParams:0n,isUnsafe:false,
 ctors:list([{name:get("psKernelNatZeroName"),type:nat.term},
  {name:get("psKernelNatSuccName"),type:succType.term}])
})),"real-Nat-admission").session;
const natRequest=D.ordinaryInductive(nil,0n,{
 name:natName,type:s1.id,ctors:list([
  {name:get("psKernelNatZeroName"),type:nat.id},
  {name:get("psKernelNatSuccName"),type:succType.id}])},false);
let declarations=get("psKernelDagDeclarationsAfterAdmission")(natRequest,nil);
const requests=[C.admit(natRequest)];
for(const text of ["add","shiftLeft"]){
 const n=N.str(natName,text);
 session=accepted(get("psKernelV1AdmitDeclaration")(session,
  Request.axiomDecl({base:{name:n,levelParams:nil,type:binaryType.term},isUnsafe:false})),
  "primitive-type-admission").session;
 const request=D.axiomDecl({name:n,levelParams:nil,type:binaryType.id},false);
 declarations=get("psKernelDagDeclarationsAfterAdmission")(request,declarations);
 requests.push(C.admit(request));
}
const add=binary("add",lit(1n),lit(2n)),three=lit(3n),b0=bv(0n);
const identity=lam(name("x"),nat,b0),metadata=md(7n,add);
const fixtures=[
 ["zero-literal",zero,lit(0n),true],["literal-zero",lit(0n),zero,true],
 ["successor-literal",succ(lit(4n)),lit(5n),true],
 ["literal-successor",lit(5n),succ(lit(4n)),true],
 ["successor-mismatch",succ(lit(4n)),lit(6n),false],
 ["predecessors-mismatch",succ(lit(4n)),succ(lit(5n)),false],
 ["left-add",add,three,true],["right-add",three,add,true],
 ["left-add-mismatch",add,lit(4n),false],
 ["both-add",add,binary("add",lit(2n),lit(1n)),true],
 ["metadata-left",metadata,three,true],["beta-left",app(identity,add),three,true],
 ["zeta-left",letE(name("x"),nat,add,b0),three,true],
 ["metadata-arguments",binary("add",md(7n,lit(1n)),md(8n,lit(2n))),three,true],
 ["count-overflow",binary("shiftLeft",lit(1n),lit(4294967296n)),lit(0n),null]
];
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
const oldLazy=(fuel,callbackFuel,scalar,state,left,right)=>{
 const defeq=get("psKernelIsDefEqWithFuel")(callbackFuel);
 const whnf=c=>s=>r=>get("psKernelWhnfWithRecursorFuel")(callbackFuel,defeq,c,s,r);
 const core=c=>s=>r=>cheapRec=>cheapProj=>
  get("psKernelWhnfCoreWithRecursorFuel")(callbackFuel,defeq,c,s,r,cheapRec,cheapProj);
 return get("psKernelDefEqLazyReductionWithFuel")(fuel)(defeq)(whnf)(core)(scalar)(state)(left)(right);
};
const directLazy=(fuel,callbackFuel,context,state,left,right)=>
 get("psKernelExprV2DefEqLazyNatWithFuel")(
  fuel,get("psKernelExprV2TryDefEqStateWithFuel")(callbackFuel),
  c=>s=>r=>get("psKernelExprV2CheckWhnfWithFuel")(callbackFuel,c,s,r),
  context,state,left,right);
const compareLazy=(expected,attempted,label)=>{
 if(rejected(expected)){
  const actual=accepted(attempted,label+"-some");
  must(rejected(actual)&&actual.error===expected.error,label+"-exact-error");return;
 }
 const a=accepted(expected,label+"-original");
 if(a.fst&&typeof a.fst.value==="boolean"&&same(a.fst,Delta.decided(a.fst.value))){
  const b=accepted(accepted(attempted,label+"-some"),label+"-actual");
  must(typeof b.snd==="boolean"&&b.snd===a.fst.value,label+"-decision");
  must(a.snd.nextFresh===b.fst.nextFresh,label+"-fresh");return;
 }
 must(a.fst&&"left" in a.fst&&"right" in a.fst&&
  same(a.fst,Delta.residual(a.fst.left,a.fst.right))&&same(attempted,none),label+"-explicit-fallback");
};
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
must(comparisons===1350,"complete-raw-matrix");
let stageComparisons=0;
const stageCases=[fixtures[0],fixtures[2],fixtures[6],fixtures[7],fixtures[8],fixtures[9]];
for(const [label,left,right] of stageCases)
 for(const fuel of [0n,1n])for(const callbackFuel of [0n,1n,4n,64n])
  for(const eagerReduce of [false,true])for(const maxNatSize of [0n,get("psKernelLeanNatMaxSizeDefault")]){
   const scalar={...base.context,eagerReduce,maxNatSize};
   compareLazy(oldLazy(fuel,callbackFuel,scalar,oldEmpty,left.term,right.term),
    directLazy(fuel,callbackFuel,ctx(scalar),initial(),left.id,right.id),
    label+"-stage-"+fuel+"-"+callbackFuel+"-"+eagerReduce+"-"+maxNatSize);
   stageComparisons++;
  }
must(stageComparisons===192,"complete-stage-matrix");
// Literal WHNF is deliberately uncached; these nonterminal operands test
// actual public-cache publication through the proof-to-Nat continuation.
const warmAdd=binary("add",binary("add",lit(1n),lit(0n)),binary("add",lit(2n),lit(0n)));
const warmMetadata=md(7n,warmAdd);
const context=ctx(base.context),cold=initial();
const warm=accepted(accepted(raw(64n,context,cold,warmMetadata.id,three.id),"warm-some"),"warm-result");
const oldWarm=accepted(original(64n,base.context,oldEmpty,warmMetadata.term,three.term),"old-warm");
must(!same(get("psKernelExprV2WhnfCacheEntries")(warm.fst.inferOnly),nil)&&same(get("psKernelExprV2WhnfCacheEntries")(warm.fst.checkedInfer),nil)&&
 !same(get("psKernelExprV2WhnfCacheEntries")(warm.fst.whnf.publicCache),nil),"nonprop-state-survives-nat-continuation");
const contains=(left,right)=>accepted(get("psKernelExprV2DefEqPairContains")(
 warm.fst.whnf.arena,warm.fst.success,left,right),"success-contains");
must(contains(warmMetadata.id,three.id)===true,"original-pair-published");
must(contains(warmAdd.id,three.id)===false,"normalized-pair-not-published");
const rightReduced=accepted(accepted(directLazy(1n,64n,context,cold,three.id,add.id),
 "right-reduced-some"),"right-reduced-result");
must(rightReduced.snd===true&&rightReduced.fst.whnf.arena.size===cold.whnf.arena.size+1n,
 "unused-predecessor-not-retained-by-eager-reduction");
const addEntry=accepted(get("psKernelExprV2PagedRequire")(warm.fst.whnf.arena,warmAdd.id),"Nat-root");
const firstEntry=accepted(get("psKernelExprV2PagedRequire")(warm.fst.whnf.arena,addEntry.node.fn),"Nat-head");
for(const argument of [firstEntry.node.arg,addEntry.node.arg]){
 const entry=accepted(get("psKernelExprV2PagedRequire")(warm.fst.whnf.arena,argument),"Nat-argument");
 const cached=accepted(get("psKernelExprV2WhnfPublicCacheFind")(warm.fst.whnf,argument,entry),"Nat-cache");
 must(!same(cached,none),"Nat-operand-whnf-state-published");
}
for(const fuel of [0n,1n,64n])for(const recDepth of [0n,15n,16n]){
 const scalar={...base.context,maxRecDepth:1n,recDepth};
 compare(original(fuel,scalar,oldWarm.snd,warmMetadata.term,three.term),
  raw(fuel,ctx(scalar),warm.fst,warmMetadata.id,three.id),"warm-entry-"+fuel+"-"+recDepth);
}
const literalZero=lit(0n),blocked={...base.context,maxRecDepth:1n,recDepth:16n};
compareLazy(oldLazy(1n,0n,blocked,oldEmpty,zero.term,literalZero.term),
 directLazy(1n,0n,ctx(blocked),initial(),zero.id,literalZero.id),"lazy-no-extra-depth-entry");
const guard=accepted(directLazy(0n,64n,context,initial(),arena.size+1n,arena.size+2n),"lazy-zero-some");
must(rejected(guard)&&guard.error==="kernel lazy-delta budget exhausted","lazy-zero-before-root-access");
const localName=name("natLocal"),local=build("FVar",E.fvar(localName),localName);
const openAdd=binary("add",letE(name("unused"),nat,local,lit(1n)),lit(2n));
const localSucc=succ(local);
const oldLocals=get("psKernelLocalContextAddLocal")(
 base.context.localContext,localName,localName,nat.term,B.default);
for(const eagerReduce of [false,true]){
 const scalar={...base.context,eagerReduce};
 const oldContext=get("psKernelCheckerContextWithLocalContext")(scalar,oldLocals);
 const typed=get("psKernelExprV2CheckContextWithLocal")(ctx(scalar),localName,localName,nat.id,B.default);
 const attempt=directLazy(1n,64n,typed,initial(),openAdd.id,three.id);
 compareLazy(oldLazy(1n,64n,oldContext,oldEmpty,openAdd.term,three.term),attempt,"eager-open-syntax");
 must(eagerReduce?accepted(accepted(attempt,"open-some"),"open-result").snd===true:
  same(attempt,none),"open-syntax-obeys-eager-policy");
 compareLazy(oldLazy(1n,1n,oldContext,oldEmpty,localSucc.term,localSucc.term),
  directLazy(1n,1n,typed,initial(),localSucc.id,localSucc.id),"predecessor-before-eager");
}
const predecessorTerms=[
 lit(0n),lit(1n),lit(18446744073709551616n),
 build("Lit",E.lit(Literal.str("x")),Literal.str("x")),
 succ(lit(0n)),succ(local),succFn,
 app(cn(get("psKernelNatSuccName"),list([L.zero])),lit(1n)),
 app(succ(lit(1n)),lit(2n)),md(7n,succ(lit(1n))),app(md(7n,succFn),lit(1n))
];
for(const term of predecessorTerms){
 const expected=get("psKernelExprNatPred")(term.term);
 const actual=accepted(get("psKernelExprV2DefEqNatPred")(initial(),term.id),"pred-result");
 if(same(expected,none))must(same(actual.snd,none),"pred-shape-none");
 else{
  const root=accepted(actual.snd,"pred-root");
  const decoded=accepted(get("psKernelExprV2DecodeChecked")(actual.fst.whnf.arena),"pred-arena");
  const observed=accepted(get("psKernelExprV2DecodedRequire")(decoded,root),"pred-read");
  must(get("psKernelExprEqual")(accepted(expected,"pred-original"))(observed)===true,"exact-syntactic-predecessor");
 }
}
const unsupported=app(app(cn(name("nonPrimitive")),lit(1n)),lit(2n));
must(same(directLazy(1n,64n,context,initial(),unsupported.id,three.id),none),
 "definition-selection-remains-unsupported");
const invalid=binary("add",s1,lit(2n));
const invalidResult=run(empty,nil,S.safe,arena,list([...requests,C.isDefEq(invalid.id,three.id)]));
must(rejected(invalidResult)&&same(invalidResult.error,
 get("PsKernelError").rejectedInvalid(invalidResult.error.message)),
 "checked-api-rejects-invalid-primitive-argument");
console.log("PSC1_V2_DAG_JS_LAZY_NAT: PASS comparisons="+comparisons+" stage="+stageComparisons+" assertions="+assertions);
