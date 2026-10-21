import { pathToFileURL } from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_FINAL_RULES_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{
 if(!(name in k))throw Error("PSC1_FINAL_RULES_MISSING_EXPORT "+name);
 return k[name];
};
let assertions=0;
const must=(value,label)=>{
 if(value!==true)throw Error("PSC1_FINAL_RULES_FAILED "+label);
 assertions++;
};
const accepted=(result,label)=>{
 if(result&&typeof result==="object"&&"value" in result)return result.value;
 throw Error("PSC1_FINAL_RULES_UNEXPECTED_REJECTION "+label);
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

const Ex=get("Except"),H=get("PsKernelReducibilityHints");
const attempt=result=>accepted(accepted(result,"some-attempt"),"successful-attempt");
const err=(attempted,message,label)=>{
 const result=accepted(attempted,label+"-some");
 must(rejected(result)&&result.error===message,label);
};
const str=value=>build("Lit",E.lit(Literal.str(value)),Literal.str(value));
const proj=(n,index,value)=>build("Proj",E.proj(n,index,value.term),n,index,value.id);
const app2=(f,a,b)=>app(app(f,a),b);
const s1=sort(L.succ(L.zero)),nat=cn(natName);
const pairName=name("terminalPair"),pairCtor=N.str(pairName,"mk"),pairType=cn(pairName);
const pair=(a,b)=>app2(cn(pairCtor),a,b);
const field=(index,value)=>proj(pairName,index,value);
const unitName=name("terminalUnit"),unitType=cn(unitName),unitValue=cn(N.str(unitName,"mk"));
const tokenName=name("terminalToken"),token=type=>app(cn(tokenName),type);
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty-session");
let session=empty,declarations=nil;
const requests=[];
const record=request=>{
 declarations=get("psKernelDagDeclarationsAfterAdmission")(request,declarations);
 requests.push(C.admit(request));
};
const admitInductive=(n,type,ctors,numParams)=>{
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request.ordinaryInductive({
  levelParams:nil,name:n,type:type.term,numParams,isUnsafe:false,
  ctors:list(ctors.map(([ctorName,ctorType])=>({name:ctorName,type:ctorType.term})))
 })),"checked-inductive").session;
 record(D.ordinaryInductive(nil,numParams,{name:n,type:type.id,
  ctors:list(ctors.map(([ctorName,ctorType])=>({name:ctorName,type:ctorType.id})))},false));
};
const admitAxiom=(text,type)=>{
 const n=name(text);
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request.axiomDecl({
  base:{name:n,levelParams:nil,type:type.term},isUnsafe:false})),"checked-axiom-"+text).session;
 record(D.axiomDecl({name:n,levelParams:nil,type:type.id},false));
};
const admitAlias=(text,value)=>{
 const n=name(text),hint=H.regular(1n);
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request.definitionDecl({
  base:{name:n,levelParams:nil,type:pairType.term},value:value.term,hints:hint,safety:S.safe
 })),"checked-alias-"+text).session;
 record(D.definitionDecl({base:{name:n,levelParams:nil,type:pairType.id},
  value:value.id,hints:hint,safety:S.safe}));
};
admitInductive(natName,s1,[
 [get("psKernelNatZeroName"),nat],[get("psKernelNatSuccName"),forall(name("n"),nat,nat)]],0n);
admitInductive(pairName,s1,[[pairCtor,forall(name("first"),nat,
 forall(name("second"),nat,pairType))]],0n);
admitInductive(unitName,s1,[[N.str(unitName,"mk"),unitType]],0n);
const otherUnitName=name("terminalOtherUnit"),otherUnit=cn(otherUnitName);
admitInductive(otherUnitName,s1,[[N.str(otherUnitName,"mk"),otherUnit]],0n);
admitInductive(tokenName,forall(name("alpha"),s1,s1),[
 [N.str(tokenName,"mk"),forall(name("alpha"),s1,token(bv(0n)))]],1n);
const loopName=name("terminalLoop"),loopType=cn(loopName);
admitInductive(loopName,s1,[[N.str(loopName,"mk"),forall(name("tail"),loopType,loopType)]],0n);
const choiceName=name("terminalChoice"),choiceType=cn(choiceName);
admitInductive(choiceName,s1,[[N.str(choiceName,"first"),choiceType],
 [N.str(choiceName,"second"),choiceType]],0n);
const indexedName=name("terminalIndexed"),indexedType=app(cn(indexedName),lit(0n));
admitInductive(indexedName,forall(name("index"),nat,s1),
 [[N.str(indexedName,"zero"),indexedType]],0n);
for(const [text,type] of [
 ["terminalUnitA",unitType],["terminalUnitB",unitType],["terminalUnitOther",otherUnit],
 ["terminalPairA",pairType],["terminalPairB",pairType],
 ["terminalNatA",nat],["terminalNatB",nat],
 ["terminalTokenA",token(nat)],["terminalTokenB",token(nat)],["terminalTokenOther",token(pairType)],
 ["terminalLoopA",loopType],["terminalLoopB",loopType],
 ["terminalChoiceA",choiceType],["terminalChoiceB",choiceType],
 ["terminalIndexedA",indexedType],["terminalIndexedB",indexedType]])admitAxiom(text,type);
admitAlias("terminalAlias1",cn(name("terminalPairA")));
admitAlias("terminalAlias2",cn(name("terminalAlias1")));
admitAlias("terminalAlias3",cn(name("terminalAlias2")));
admitAlias("terminalAlias4",cn(name("terminalAlias3")));
must(requests.length===28,"complete-checked-fixture-environment");
const base=get("psKernelKernelSessionChecker")(session,nil,S.safe);
const ctx=scalar=>get("psKernelExprV2CheckContextEmpty")(scalar),context=ctx(base.context);
const initial=(owned=arena,refs=declarations)=>get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(owned),
 get("psKernelExprV2WhnfStateForDeclarations")(owned,refs));
const raw=(fuel,c,s,l,r)=>get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(c)(s)(l)(r);
const original=(fuel,c,s,l,r)=>get("psKernelIsDefEqWithFuel")(fuel)(c)(s)(l)(r);
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
const compareOptional=(expected,attempted,label)=>{
 const actual=accepted(attempted,label+"-direct");
 if(rejected(expected)){
  must(rejected(actual)&&actual.error===expected.error,label+"-exact-error");
 }else{
  const a=accepted(expected,label+"-original"),b=accepted(actual,label+"-result");
  must(same(a.fst,b.snd),label+"-optional-decision");
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
const originalFinal=(fuel,c,s,l,r)=>{
 const defeq=get("psKernelIsDefEqWithFuel")(fuel);
 const infer=c0=>s0=>r0=>get("psKernelInferWithRecursorFuel")(fuel,defeq,c0,s0,r0);
 const whnf=c0=>s0=>r0=>get("psKernelWhnfWithRecursorFuel")(fuel,defeq,c0,s0,r0);
 return get("psKernelIsDefEqAfterFullShape")(defeq,infer,whnf,c,s,l,r,l,r);
};
const directFinal=(fuel,c,s,l,r)=>{
 const defeq=get("psKernelExprV2TryDefEqStateWithFuel")(fuel),whnf=whnfWith(fuel);
 const infer=c0=>s0=>r0=>get("psKernelExprV2TryInferCoreWithFuel")(fuel)(whnf)(defeq)(c0)(s0)(r0)(true);
 return get("psKernelExprV2DefEqFinalRulesWith")(defeq,infer,whnf,c,s,l,r);
};
const decoded=(owned,root)=>{
 const canonical=accepted(get("psKernelExprV2PagedValidate")(owned),"decode-validated-arena");
 const graph=accepted(get("psKernelExprV2DecodeChecked")(canonical),"decode-graph");
 return accepted(get("psKernelExprV2DecodedRequire")(graph,root),"decode-root");
};
const contains=(state,l,r)=>accepted(get("psKernelExprV2DefEqPairContains")(
 state.whnf.arena,state.success,l,r),"success-cache-lookup");
const pairA=cn(name("terminalPairA")),pairB=cn(name("terminalPairB"));
const unitA=cn(name("terminalUnitA")),unitB=cn(name("terminalUnitB"));
const tokenA=cn(name("terminalTokenA"));
const eta=pair(field(0n,pairA),field(1n,pairA)),wrongEta=pair(field(0n,pairA),lit(0n));
const alias=cn(name("terminalAlias1"));
const fixtures=[
 ["unit-axioms",unitA,unitB,true],
 ["unit-constructor-right",unitA,unitValue,true],
 ["unit-constructor-left",unitValue,unitA,true],
 ["unit-types-differ",unitA,cn(name("terminalUnitOther")),false],
 ["parameter-unit-equal",tokenA,cn(name("terminalTokenB")),true],
 ["parameter-unit-different",tokenA,cn(name("terminalTokenOther")),false],
 ["structure-eta-right",pairA,eta,true],
 ["structure-eta-left",eta,pairA,true],
 ["metadata-structure-eta",md(31n,pairA),eta,true],
 ["pair-axioms-different",pairA,pairB,false],
 ["structure-eta-field-different",pairA,wrongEta,false],
 ["matching-projection-alias-right",field(0n,pairA),field(0n,alias),true],
 ["matching-projection-alias-left",field(0n,alias),field(0n,pairA),true],
 ["matching-projection-different",field(0n,pairA),field(0n,pairB),false],
 ["nat-axioms-different",cn(name("terminalNatA")),cn(name("terminalNatB")),false],
 ["recursive-type-different",cn(name("terminalLoopA")),cn(name("terminalLoopB")),false],
 ["projection-index-different",field(0n,pairA),field(1n,pairA),false],
 ["unit-versus-nat",unitA,lit(0n),false],
 ["structure-type-different",pairA,app(cn(N.str(tokenName,"mk")),nat),false],
 ["multiple-constructors-different",cn(name("terminalChoiceA")),cn(name("terminalChoiceB")),false],
 ["indexed-type-different",cn(name("terminalIndexedA")),cn(name("terminalIndexedB")),false],
 ["unknown-constant",cn(name("terminalMissing")),unitA,null],
 ["invalid-projection-index",field(2n,pairA),lit(0n),null],
 ["invalid-projection-name",proj(unitName,0n,pairA),lit(0n),null]
];
let owners=0,checkedBatches=0;
for(const [label,left,right,decision] of fixtures){
 for(const fuel of [0n,1n,2n,3n,4n,6n,8n,16n,64n])
  for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
   const scalar={...base.context,maxRecDepth,recDepth};
   compare(original(fuel,scalar,oldEmpty,left.term,right.term),
    raw(fuel,ctx(scalar),initial(),left.id,right.id),label);
   owners++;
  }
 const high=accepted(get("psKernelExprV2TryDefEqWithDeclarationsFuel")(
  64n,base.context,arena,declarations,left.id,right.id),label+"-high-direct");
 if(decision===null)must(rejected(high),label+"-high-error");
 else must(accepted(high,label+"-high-value")===decision,label+"-high-decision");
 for(const fuel of [0n,1n,2n,4n,8n,64n]){
  const limited={...session,resources:{...session.resources,fuel}};
  comparePublic(get("psKernelV1IsDefEq")(limited,nil,S.safe,left.term,right.term),
   run(limited,nil,S.safe,arena,list([C.isDefEq(left.id,right.id)])),label);
 }
 if(decision!==null){
  const batch=accepted(run(empty,nil,S.safe,arena,
   list([...requests,C.isDefEq(left.id,right.id)])),label+"-checked-batch"),replies=array(batch.replies);
  must(replies.length===requests.length+1&&replies.at(-1).value===decision,label+"-checked-decision");
  checkedBatches++;
 }
}
must(owners===648&&checkedBatches===21,"complete-owner-matrix");
const finalFixtures=[
 [unitA,unitB],[unitA,unitValue],[unitA,cn(name("terminalUnitOther"))],
 [tokenA,cn(name("terminalTokenB"))],[tokenA,cn(name("terminalTokenOther"))],
 [pairA,eta],[eta,pairA],[pairA,wrongEta],[pairA,pairB],
 [cn(name("terminalChoiceA")),cn(name("terminalChoiceB"))],
 [cn(name("terminalIndexedA")),cn(name("terminalIndexedB"))],
 [cn(name("terminalNatA")),cn(name("terminalNatB"))]
];
let finals=0;
for(const [left,right] of finalFixtures)for(const fuel of [0n,1n,2n,4n,8n,64n])
 for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
  const scalar={...base.context,maxRecDepth,recDepth};
  compare(originalFinal(fuel,scalar,oldEmpty,left.term,right.term),
   directFinal(fuel,ctx(scalar),initial(),left.id,right.id),"full-final-stage");
  finals++;
 }
must(finals===216,"complete-final-stage-matrix");
const projectionFixtures=[
 [pairA,alias,0n],[alias,pairA,0n],
 [pair(lit(0n),lit(1n)),pair(lit(0n),lit(2n)),0n],
 [pair(lit(0n),lit(1n)),pair(lit(0n),lit(2n)),1n],
 [pairA,pairB,0n],[pair(lit(0n),lit(1n)),lit(0n),0n],
 [cn(name("terminalAlias4")),pairA,0n]
];
let projections=0;
for(const [left,right,index] of projectionFixtures)for(const callbackFuel of [0n,1n,2n,4n,64n])
 for(const fuel of [0n,1n,2n,3n,4n]){
  const expected=get("psKernelDefEqLazyProjReductionWithFuel")(fuel)
   (get("psKernelIsDefEqWithFuel")(callbackFuel))(oldCoreWith(callbackFuel))
   (base.context)(oldEmpty)(left.term)(right.term)(pairName)(index);
  const actual=get("psKernelExprV2DefEqLazyProjReductionWithFuel")(fuel)
   (get("psKernelExprV2TryDefEqStateWithFuel")(callbackFuel))(coreWith(callbackFuel))
   (context)(initial())(left.id)(right.id)(pairName)(index);
  compare(expected,actual,"lazy-projection-stage");projections++;
 }
must(projections===175,"complete-projection-stage-matrix");

// Constructor translation and callback order are qualified separately from
// whole-checker String execution, whose WHNF still has recursor dependencies.
const strings=["","abc","é","é","漢字","🧪","\0",String.fromCodePoint(65521)];
const charType=cn(get("psKernelCharName"));
const listNil=app(cn(get("psKernelListNilName"),list([L.zero])),charType);
const listCons=app(cn(get("psKernelListConsName"),list([L.zero])),charType);
const charOfNat=cn(get("psKernelCharOfNatName"));
const independentStringTerm=value=>{
 let tail=listNil.term;
 for(const scalar of [...value].reverse())
  tail=E.app(E.app(listCons.term,E.app(charOfNat.term,
   E.lit(Literal.nat(BigInt(scalar.codePointAt(0)))))),tail);
 return E.app(E.const(get("psKernelStringOfListName"),nil),tail);
};
const constructorFor=value=>{
 const built=accepted(get("psKernelExprV2StringLitToConstructorOnCanonical")(arena,value),
  "string-constructor");
 arena=built.fst;
 return {id:built.snd,term:get("psKernelStringLitToConstructor")(value)};
};
const oldEq=_c=>s=>l=>r=>Ex.ok({
 fst:get("psKernelExprEq")(l)(r),snd:{...s,nextFresh:s.nextFresh+1n}});
const dagEq=_c=>s=>l=>r=>{
 const decision=get("psKernelExprV2PagedEqOnCanonical")(s.whnf.arena,l,r);
 return rejected(decision)?Option.some(Ex.error(decision.error)):
  Option.some(Ex.ok({fst:{...s,nextFresh:s.nextFresh+1n},snd:accepted(decision,"string-eq")}));
};
const oldIdentityWhnf=_c=>s=>r=>Ex.ok({fst:r,snd:s});
const identityWhnf=_c=>s=>r=>Option.some(Ex.ok({fst:s,snd:r}));
let stringBuilds=0,stringStages=0;
for(const value of strings){
 const built=accepted(get("psKernelExprV2StringLitToConstructorOnCanonical")(arena,value),
  "whole-string-constructor"),term=decoded(built.fst,built.snd);
 must(get("psKernelExprEqual")(term)(get("psKernelStringLitToConstructor")(value))===true,
  "string-whole-constructor-exact");
 must(get("psKernelExprEqual")(term)(independentStringTerm(value))===true,
  "string-constructor-independent-unicode-scalars");
 const byteSize=BigInt(Buffer.byteLength(value,"utf8"));
 for(const fuel of [0n,1n,2n,4n,8n,64n])for(const position of [0n,byteSize,byteSize+1n]){
  const result=accepted(get("psKernelExprV2StringConstructorDataWithFuel")(fuel)
   (arena)(value)(position)(listNil.id)(listCons.id)(charOfNat.id),"string-prefix");
  const expected=get("psKernelStringConstructorDataWithFuel")(fuel)(value)(position)
   (listNil.term)(listCons.term)(charOfNat.term);
  must(get("psKernelExprEqual")(decoded(result.fst,result.snd))(expected)===true,
   "string-prefix-budget-exact");
  stringBuilds++;
 }
 for(const sameValue of [true,false]){
  const other=sameValue?value:value+"!",left=str(value),right=constructorFor(other);
  for(const [l,r] of [[left,right],[right,left]]){
   const result=get("psKernelExprV2DefEqStringLitExpansionWith")(
    dagEq,identityWhnf,context,initial(),l.id,r.id);
   compareOptional(get("psKernelDefEqStringLitExpansionWith")(
    oldEq,oldIdentityWhnf,base.context,oldEmpty,l.term,r.term),result,
    "string-stage-both-orientations");
   const observed=attempt(result);
   must(same(observed.snd,Option.some(sameValue))&&observed.fst.nextFresh===1n,
    "string-false-is-a-decision-not-fallthrough");
   stringStages++;
  }
 }
}
must(stringBuilds===144&&stringStages===32,"complete-string-matrix");

const zero=lit(0n),one=lit(1n),field0=field(0n,pairA),field1=field(1n,pairA);
const metadata=md(31n,pairA),alias4=cn(name("terminalAlias4")),aliasProjection=field(0n,alias4);
const pair01=pair(zero,one),pair02=pair(zero,lit(2n));
const succZero=app(cn(get("psKernelNatSuccName")),zero);
const loopCtor=app(cn(N.str(loopName,"mk")),cn(name("terminalLoopA")));
const owning=arena,cold=initial(owning);
const badDefEq=_c=>_s=>_l=>_r=>Option.some(Ex.error("TERMINAL_DEFEQ_CALLED"));
const oldBadDefEq=_c=>_s=>_l=>_r=>Ex.error("TERMINAL_DEFEQ_CALLED");
const noInfer=_c=>_s=>_r=>Option.some(Ex.error("TERMINAL_INFER_CALLED"));
const noWhnf=_c=>_s=>_r=>Option.some(Ex.error("TERMINAL_WHNF_CALLED"));
const noCore=_c=>_s=>_r=>_cheap=>Option.some(Ex.error("TERMINAL_CORE_CALLED"));
const projectionStage=get("psKernelExprV2DefEqLazyProjReductionWithFuel");
const etaFields=get("psKernelExprV2DefEqEtaStructFieldsWithFuel");
err(projectionStage(0n)(badDefEq)(noCore)(context)(cold)
 (owning.size+1n)(owning.size+2n)(pairName)(0n),
 "kernel lazy-projection budget exhausted","projection-zero-before-roots");
err(etaFields(0n)(badDefEq)(context)(cold)(pairName)(owning.size+1n)(nil)(0n)(0n),
 "kernel structure eta budget exhausted","eta-fields-zero-before-empty-and-roots");
err(projectionStage(1n)(badDefEq)(noCore)(context)(cold)(succZero.id)(one.id)(pairName)(0n),
 "TERMINAL_DEFEQ_CALLED","projection-loop-has-no-eager-nat-stage");
const shortcut=get("psKernelExprV2DefEqProjectionShortcutWith");
const budgetProjection=shortcut(badDefEq,context,cold,aliasProjection.id,field0.id);
compareOptional(get("psKernelDefEqProjectionShortcut")(
 oldBadDefEq,base.context,oldEmpty,aliasProjection.term,field0.term),
 budgetProjection,"derived-projection-budget");
err(budgetProjection,"kernel lazy-projection budget exhausted",
 "derived-projection-budget-is-not-default-fuel");
compare(original(64n,base.context,oldEmpty,aliasProjection.term,field0.term),
 raw(64n,context,cold,aliasProjection.id,field0.id),"whole-owner-preserves-derived-projection-exhaustion");
must(same(shortcut(badDefEq,context,initial(owning,nil),aliasProjection.id,field0.id),none),
 "missing-body-does-not-run-projection-finish");
const selectedFields=_c=>s=>l=>r=>l===zero.id&&r===zero.id?
 Option.some(Ex.ok({fst:{...s,nextFresh:s.nextFresh+1n},snd:true})):
 Option.some(Ex.error("WRONG_SELECTED_FIELDS"));
const selected=attempt(get("psKernelExprV2DefEqLazyProjFinishWith")(
 selectedFields,context,cold,pair01.id,pair02.id,pairName,0n));
must(selected.snd===true&&selected.fst.nextFresh===1n,"projection-finish-compares-selected-fields");
const wholeValues=_c=>_s=>l=>r=>Option.some(Ex.error(
 l===pair01.id&&r===zero.id?"WHOLE_VALUES":"MIXED_FIELD_AND_VALUE"));
err(get("psKernelExprV2DefEqLazyProjFinishWith")(
 wholeValues,context,cold,pair01.id,zero.id,pairName,0n),"WHOLE_VALUES",
 "one-missing-field-compares-original-values");
const sameNode=(s,l,r)=>accepted(get("psKernelExprV2PagedEqOnCanonical")(
 s.whnf.arena,l,r),"callback-structural-equality")===true;
const traceFields=c=>s=>l=>r=>{
 const expectedLeft=s.nextFresh===0n?field0.id:field1.id,expectedRight=s.nextFresh===0n?zero.id:one.id;
 return sameNode(s,l,expectedLeft)&&r===expectedRight&&c.scalar.recDepth===context.scalar.recDepth?
  Option.some(Ex.ok({fst:{...s,nextFresh:s.nextFresh+1n},snd:true})):
  Option.some(Ex.error("ETA_FIELD_ORDER"));
};
const fields=attempt(etaFields(3n)(traceFields)(context)(cold)(pairName)(pairA.id)
 (list([zero.id,one.id]))(0n)(0n));
must(fields.snd===true&&fields.fst.nextFresh===2n,"eta-fields-left-to-right-fixed-context");
err(etaFields(2n)(traceFields)(context)(cold)(pairName)(pairA.id)
 (list([zero.id,one.id]))(0n)(0n),"kernel structure eta budget exhausted",
 "eta-fields-terminal-iteration-spends-own-fuel");
const recursiveEta=attempt(get("psKernelExprV2DefEqEtaStructCoreWith")(
 badDefEq,noInfer,context,cold,pairA.id,loopCtor.id));
must(recursiveEta.snd===false&&recursiveEta.fst.nextFresh===0n,
 "recursive-constructor-refuses-before-inference");
const traceInfer=c=>s=>r=>
 c.scalar.recDepth===context.scalar.recDepth&&
 ((s.nextFresh===0n&&r===pairA.id)||(s.nextFresh===1n&&r===eta.id))?
 Option.some(Ex.ok({fst:{...s,nextFresh:s.nextFresh+1n},snd:pairType.id})):
 Option.some(Ex.error("ETA_INFERENCE_ORDER"));
const traceEta=c=>s=>l=>r=>{
 const expected=s.nextFresh===2n?pairType.id:s.nextFresh===3n?field0.id:field1.id;
 return c.scalar.recDepth===context.scalar.recDepth&&sameNode(s,l,expected)&&sameNode(s,r,expected)?
  Option.some(Ex.ok({fst:{...s,nextFresh:s.nextFresh+1n},snd:true})):
  Option.some(Ex.error("ETA_TYPE_OR_FIELD_ORDER"));
};
const tracedEta=attempt(get("psKernelExprV2DefEqEtaStructWith")(
 traceEta,traceInfer,context,cold,pairA.id,eta.id));
must(tracedEta.snd===true&&tracedEta.fst.nextFresh===5n,"eta-types-before-fields-and-state-preserved");
const unitInfer=c=>s=>r=>
 c.scalar.recDepth===context.scalar.recDepth&&
 ((s.nextFresh===0n&&r===unitA.id)||(s.nextFresh===1n&&r===unitB.id))?
 Option.some(Ex.ok({fst:{...s,nextFresh:s.nextFresh+1n},snd:unitType.id})):
 Option.some(Ex.error("UNIT_INFERENCE_ORDER"));
const unitWhnf=c=>s=>r=>c.scalar.recDepth===context.scalar.recDepth&&r===unitType.id?
 Option.some(Ex.ok({fst:s,snd:r})):Option.some(Ex.error("UNIT_WHNF_ORDER"));
const unitDefEq=_c=>s=>l=>r=>s.nextFresh===2n&&l===unitType.id&&r===unitType.id?
 Option.some(Ex.ok({fst:{...s,nextFresh:s.nextFresh+1n},snd:true})):
 Option.some(Ex.error("UNIT_TYPE_ORDER"));
const unitStage=get("psKernelExprV2DefEqUnitLikeWith");
const tracedUnit=attempt(unitStage(unitDefEq,unitInfer,unitWhnf,context,cold,unitA.id,unitB.id));
must(tracedUnit.snd===true&&tracedUnit.fst.nextFresh===3n,
 "unit-left-whnf-before-right-and-state-preserved");
err(unitStage(unitDefEq,unitInfer,noWhnf,context,cold,unitA.id,unitB.id),
 "TERMINAL_WHNF_CALLED","unit-whnf-error-precedes-right-inference");
const declineInfer=_c=>_s=>_r=>none,finalStage=get("psKernelExprV2DefEqFinalRulesWith");
must(same(finalStage(badDefEq,declineInfer,noWhnf,context,cold,pairA.id,eta.id),none),
 "unsupported-eta-inference-propagates");
must(same(finalStage(badDefEq,declineInfer,noWhnf,context,cold,unitA.id,unitB.id),none),
 "unsupported-unit-inference-propagates");
const stageUnit=attempt(directFinal(64n,context,cold,unitA.id,unitB.id));
must(stageUnit.snd===true&&contains(stageUnit.fst,unitA.id,unitB.id)===false,
 "terminal-helper-does-not-publish-original-success");
const warm=attempt(raw(64n,context,cold,metadata.id,eta.id));
const oldWarm=accepted(original(64n,base.context,oldEmpty,metadata.term,eta.term),"old-warm");
must(warm.snd===true&&contains(warm.fst,metadata.id,eta.id)===true,
 "whole-owner-publishes-original-metadata-pair");
must(contains(warm.fst,pairA.id,eta.id)===false,"whole-owner-does-not-publish-residual-pair");
must(array(warm.fst.inferOnly).length>0&&same(warm.fst.checkedInfer,nil),
 "terminal-inference-stays-infer-only");
for(const fuel of [0n,1n,64n])for(const recDepth of [0n,15n,16n]){
 const scalar={...base.context,maxRecDepth:1n,recDepth};
 compare(original(fuel,scalar,oldWarm.snd,metadata.term,eta.term),
  raw(fuel,ctx(scalar),warm.fst,metadata.id,eta.id),"warm-terminal-entry-guards");
}
must(same(get("psKernelExprV2TryDefEqWithDeclarationsFuel")(
 64n,base.context,owning,nil,metadata.id,eta.id),none),
 "missing-owner-index-never-authorized-by-terminal-rules");

const stringLeft=str("left"),stringRight=constructorFor("right"),stringCold=initial();
const falseDefEq=_c=>s=>_l=>_r=>Option.some(Ex.ok({
 fst:{...s,nextFresh:s.nextFresh+1n},snd:false}));
const stringFinal=attempt(finalStage(
 falseDefEq,noInfer,identityWhnf,context,stringCold,stringLeft.id,stringRight.id));
must(stringFinal.snd===false&&stringFinal.fst.nextFresh===1n,"string-false-stops-before-unit-inference");
const stringStage=get("psKernelExprV2DefEqStringLitExpansionWith");
err(stringStage(badDefEq,noWhnf,context,stringCold,stringLeft.id,stringRight.id),
 "TERMINAL_WHNF_CALLED","string-whnf-error-before-defeq");
const declineWhnf=_c=>_s=>_r=>none,declineDefEq=_c=>_s=>_l=>_r=>none;
must(same(finalStage(badDefEq,noInfer,declineWhnf,context,stringCold,stringLeft.id,stringRight.id),none),
 "unsupported-string-whnf-propagates");
must(same(finalStage(declineDefEq,noInfer,identityWhnf,context,stringCold,stringLeft.id,stringRight.id),none),
 "unsupported-string-defeq-propagates");
for(const wrongShape of [
 cn(get("psKernelStringOfListName")),
 app(cn(get("psKernelStringOfListName"),list([L.zero])),listNil),
 app(app(cn(get("psKernelStringOfListName")),listNil),zero)]){
 const refused=attempt(stringStage(badDefEq,noWhnf,context,initial(),stringLeft.id,wrongShape.id));
 must(same(refused.snd,none)&&refused.fst.nextFresh===0n,"string-shape-refusal-precedes-callbacks");
}
const invalid=pair(s1,zero);
const invalidResult=run(empty,nil,S.safe,arena,list([...requests,C.check(invalid.id)]));
must(rejected(invalidResult)&&same(invalidResult.error,
 get("PsKernelError").rejectedInvalid(invalidResult.error.message)),
 "checked-batch-rejects-invalid-constructor-argument");
const badName=name("terminalInvalidType"),badRequest=D.axiomDecl({
 name:badName,levelParams:nil,type:zero.id},false);
const badResult=run(empty,nil,S.safe,arena,list([...requests,C.admit(badRequest)]));
must(rejected(badResult)&&same(badResult.error,
 get("PsKernelError").rejectedInvalid(badResult.error.message)),
 "checked-batch-rejects-nonsort-axiom-type");
must(same(get("psKernelEnvironmentFind")(session.environment,badName),none),
 "failed-batch-does-not-publish");

// String-literal projection follows the same full-state callback sequence as V1.
// These raw probes redirect expansion to an independently checked pair; they
// test callbacks, not admission of a String as that pair.
const spModulus=BigInt(get("psKernelCacheHashModulus"));
const spMark=(s,root,tag)=>{
 const built=accepted(get("psKernelExprV2PagedMkLit")(s.whnf.arena,Literal.nat(10000n+tag)),"projection-owner-marker");
 const row={source:root,result:built.snd,hash:spModulus+tag};
 const pair={left:root,right:built.snd,hash:spModulus+tag};
 return {...s,nextFresh:tag,checkedInfer:list([row]),inferOnly:list([row]),unfold:list([row]),
  success:list([pair]),failure:list([pair]),
  whnf:{...s.whnf,arena:built.fst,coreCache:list([row]),publicCache:list([row])}};
};
const spMarked=(s,tag)=>{
 const rowMarked=rows=>{
  const a=array(rows);if(a.length!==1||a[0].hash!==spModulus+tag)return false;
  const entry=accepted(get("psKernelExprV2PagedRequire")(s.whnf.arena,a[0].result),"projection-marker-present");
  return same(entry.node,get("PsKernelExprV2Node").lit(Literal.nat(10000n+tag)));
 };
 const pairMarked=rows=>{const a=array(rows);return a.length===1&&a[0].hash===spModulus+tag;};
 return s.nextFresh===tag&&rowMarked(s.checkedInfer)&&rowMarked(s.inferOnly)&&rowMarked(s.unfold)&&
  rowMarked(s.whnf.publicCache)&&pairMarked(s.success)&&pairMarked(s.failure);
};
const spError=message=>Option.some(Ex.error(message));
const spOk=(s,r)=>Option.some(Ex.ok({fst:s,snd:r}));
const spProjection=get("psKernelExprV2TryWhnfProjectionOwnedWith");
const spSameNode=(s,a,b)=>accepted(get("psKernelExprV2PagedEqOnCanonical")(s.whnf.arena,a,b),"projection-node-equality");
const spCompare=(expected,actual,label)=>{
 const observed=accepted(actual,label+"-direct");
 if(rejected(expected)){
  must(rejected(observed)&&observed.error===expected.error,label+"-exact-error");
 }else{
  const a=accepted(expected,label+"-V1"),b=accepted(observed,label+"-V2");
  must(get("psKernelExprEqual")(a.fst)(decoded(b.fst.whnf.arena,b.snd)),label+"-term");
  must(a.snd.nextFresh===b.fst.nextFresh,label+"-fresh");
 }
};
const spPositive=field(0n,pair(lit(7n),lit(8n)));
must(get("psKernelExprEqual")(accepted(get("psKernelV1Whnf")(session,nil,S.safe,spPositive.term),"projection-valid-V1"))(
 E.lit(Literal.nat(7n))),"string-projection-public-valid-pair-control");
const spPositiveBatch=accepted(run(empty,nil,S.safe,arena,
 list([...requests,C.whnf(spPositive.id)])),"projection-valid-checked-DAG");
must(get("psKernelExprEqual")(array(spPositiveBatch.replies).at(-1).value)(E.lit(Literal.nat(7n))),
 "string-projection-checked-DAG-valid-pair-control");
let spDifferential=0,spOwners=0,spFailures=0;
for(const value of strings){
 const literal=str(value),expanded=constructorFor(value),p=pair(lit(7n),lit(8n)),selected=lit(7n);
 const root=proj(pairName,0n,literal),cold=initial();
 const invalidV1=get("psKernelV1Whnf")(session,nil,S.safe,root.term);
 const invalidDAG=run(empty,nil,S.safe,arena,list([...requests,C.whnf(root.id)]));
 must(rejected(invalidV1)&&same(invalidV1.error,get("PsKernelError").rejectedInvalid(invalidV1.error.message)),
  "string-projection-public-invalid-pair-rejected");
 must(rejected(invalidDAG)&&same(invalidDAG.error,get("PsKernelError").rejectedInvalid(invalidDAG.error.message)),
  "string-projection-checked-DAG-invalid-pair-rejected");
 for(const cheap of [false,true]){
  const seeded=spMark(cold,root.id,40n);
  const recurse=c=>s=>r=>{
   if(c.scalar.recDepth!==context.scalar.recDepth)return spError("STRING_PROJECTION_CONTEXT");
   if(cheap&&r===literal.id&&spMarked(s,40n))return spOk(spMark(s,root.id,41n),literal.id);
   if(r===selected.id&&spMarked(s,42n))return spOk(spMark(s,root.id,43n),selected.id);
   return spError("STRING_PROJECTION_RECURSE_ORDER");
  };
  const publicWhnf=c=>s=>r=>{
   if(c.scalar.recDepth!==context.scalar.recDepth)return spError("STRING_PROJECTION_CONTEXT");
   if(!cheap&&r===literal.id&&spMarked(s,40n))return spOk(spMark(s,root.id,41n),literal.id);
   if(spSameNode(s,r,expanded.id)&&spMarked(s,41n))return spOk(spMark(s,root.id,42n),p.id);
   return spError("STRING_PROJECTION_PUBLIC_ORDER");
  };
  const result=attempt(spProjection(recurse,publicWhnf,context,seeded,root.id,pairName,0n,literal.id,cheap));
  must(result.snd===selected.id,"string-projection-selected-field");
  must(spMarked(result.fst,43n),"string-projection-complete-owner-and-appended-arena");
  must(array(result.fst.whnf.coreCache).length===(cheap?1:2),"string-projection-core-cache-mode");
  spOwners++;
  for(const declined of [false,true]){
   const stopPublic=_c=>s=>r=>
    !cheap&&r===literal.id?spOk(s,literal.id):
     declined?none:spError("STRING_PROJECTION_EXPANSION_FAILURE");
   const majorOnly=_c=>s=>r=>r===literal.id?spOk(s,literal.id):
    spError("STRING_PROJECTION_FIELD_MUST_NOT_RUN");
   const failed=spProjection(majorOnly,stopPublic,context,cold,root.id,pairName,0n,literal.id,cheap);
   if(declined)must(same(failed,none),"string-projection-expansion-refusal-propagates");
   else err(failed,"STRING_PROJECTION_EXPANSION_FAILURE","string-projection-expansion-error-propagates");
   spFailures++;
  }
 }
 for(const [typeName,index]of [[name("String"),0n],[name("String"),2n],[pairName,0n]]){
  const term=proj(typeName,index,literal);
  for(const fuel of [0n,1n,2n,4n,16n,64n])for(const depth of [0n,15n,16n]){
   const scalar={...base.context,maxRecDepth:1n,recDepth:depth},c=ctx(scalar);
   const oldEq=get("psKernelIsDefEqWithFuel")(fuel),dagEq=get("psKernelExprV2TryDefEqStateWithFuel")(fuel);
   spCompare(get("psKernelWhnfWithRecursorFuel")(fuel,oldEq,scalar,oldEmpty,term.term),
    get("psKernelExprV2CheckWhnfOwnedWithFuel")(fuel,dagEq,c,initial(),term.id),"string-projection-public");
   spDifferential++;
   for(const cheap of [false,true]){
    spCompare(get("psKernelWhnfCoreWithRecursorFuel")(fuel,oldEq,scalar,oldEmpty,term.term,false,cheap),
     get("psKernelExprV2CheckWhnfCoreOwnedWithFuel")(fuel,dagEq,c,initial(),term.id,cheap),"string-projection-core");
    spDifferential++;
   }
  }
 }
}
must(spDifferential===1296&&spOwners===16&&spFailures===32,"string-projection-complete-matrix");
console.log("PSC1_V2_STRING_PROJECTION_JS: PASS differential=1296 owners=16 failures=32");

console.log("PSC1_V2_DAG_JS_FINAL_RULES: PASS owner="+owners+" final="+finals+
 " projection="+projections+" stringBuild="+stringBuilds+" stringStage="+stringStages+
 " checkedBatches="+checkedBatches+" assertions="+assertions);

