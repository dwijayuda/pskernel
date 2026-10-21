import {pathToFileURL} from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_RECURSOR_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_RECURSOR_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_RECURSOR_FAIL "+label);assertions++;};
const accepted=(x,label)=>{
 if(x&&typeof x==="object"&&Object.hasOwn(x,"value"))return x.value;
 const error=x&&typeof x==="object"&&Object.hasOwn(x,"error")?x.error:null;
 const detail=typeof error==="string"?error:
  error&&typeof error.message==="string"?error.message:"missing accepted value";
 throw Error("PSC1_RECURSOR_UNEXPECTED_REJECTION "+label+": "+detail);
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
const name=text=>N.str(unit(N.anonymous),text),one=L.succ(unit(L.zero));
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
const lam=(n,t,b,info=unit(B.default))=>build("Lam",E.lam(name(n),t.term,b.term,info),name(n),t.id,b.id,info);
const forall=(n,t,b,info=unit(B.default))=>build("Forall",E.forallE(name(n),t.term,b.term,info),name(n),t.id,b.id,info);
const lit=n=>build("Lit",E.lit(Literal.nat(n)),Literal.nat(n));
const md=(tag,x)=>build("MData",E.mdata(tag,x.term),tag,x.id);
const letE=(n,t,v,b)=>build("Let",E.letE(name(n),t.term,v.term,b.term,false),name(n),t.id,v.id,b.id,false);
const safe=unit(S.safe),hints=unit(get("PsKernelReducibilityHints").abbrevHint);
const natName=get("psKernelNatName"),natRecName=get("psKernelSimpleRecName")(natName);
const boxName=name("IotaBox"),boxCtorName=N.str(boxName,"mk"),boxRecName=get("psKernelSimpleRecName")(boxName);
const nat=cn(natName),s1=sort(one),zero=sort(unit(L.zero)),u=name("u"),universe=L.param(u);
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty");
let session=empty,declarations=nil;
const commands=[];
const inductive=(label,n,levels,type,ctors,numParams)=>{
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request.ordinaryInductive({
  levelParams:list(levels),name:n,type:type.term,ctors:list(ctors.map(([name,type])=>({name,type:type.term}))),
  isUnsafe:false,numParams})),"checked-inductive-"+label).session;
 const request=D.ordinaryInductive(list(levels),numParams,
  {name:n,type:type.id,ctors:list(ctors.map(([name,type])=>({name,type:type.id})))},false);
 declarations=get("psKernelDagDeclarationsAfterAdmission")(request,declarations);
 commands.push(C.admit(request));
};
inductive("Nat",natName,[],s1,[[get("psKernelNatZeroName"),nat],
 [get("psKernelNatSuccName"),forall("n",nat,nat)]],0n);
// The data box must live in a provably nonzero universe for Nat-valued elimination.
const boxType=forall("A",sort(L.succ(universe)),sort(L.succ(universe)));
const boxCtorType=forall("A",sort(L.succ(universe)),forall("value",bv(0n),
 apps(cn(boxName,[universe]),[bv(1n)])));
inductive("IotaBox",boxName,[u],boxType,[[boxCtorName,boxCtorType]],1n);
const kName=name("IotaK"),kCtorName=N.str(kName,"mk"),kType=cn(kName);
inductive("IotaK",kName,[],zero,[[kCtorName,kType]],0n);
const CI=get("PsKernelConstantInfo");
const recursorInfo=n=>{
 const info=accepted(get("psKernelEnvironmentFind")(session.environment,n),"recursor-info");
 must(info&&same(info,CI.recInfo(info.value)),"checked-recursor-kind");
 return info.value;
};
const natInfo=recursorInfo(natRecName),boxInfo=recursorInfo(boxRecName);
const kInfo=recursorInfo(get("psKernelSimpleRecName")(kName));
must(natInfo.k===false&&boxInfo.k===false&&kInfo.k===true,"actual-checked-K-policy");
must(array(boxInfo.base.levelParams).length===2,"data-box-independent-elimination-universe");
const ctorZero=cn(get("psKernelNatZeroName"));
const ctorTwo=app(cn(get("psKernelNatSuccName")),app(cn(get("psKernelNatSuccName")),ctorZero));
const box=app(cn(boxName,[unit(L.zero)]),nat);
const five=lit(5n),seven=lit(7n),nine=lit(9n);
const boxMajor=apps(cn(boxCtorName,[unit(L.zero)]),[nat,five]);
const natMotive=lam("n",nat,nat),natStep=lam("n",nat,lam("ih",nat,bv(0n)));
const natRec=major=>apps(cn(natRecName,[one]),[natMotive,seven,natStep,major]);
const boxRec=(motive,minor)=>apps(cn(boxRecName,[one,unit(L.zero)]),[nat,motive,minor,boxMajor]);
const fnType=forall("x",nat,nat);
const natFn=apps(cn(natRecName,[one]),[
 lam("n",nat,fnType),lam("x",nat,bv(0n)),lam("n",nat,lam("ih",fnType,bv(0n))),lit(3n)]);
const partialNat=apps(cn(natRecName,[one]),[natMotive,seven,natStep]);
const fixtures=[
 ["zero-constructor",natRec(ctorZero),seven],
 ["two-constructors",natRec(ctorTwo),seven],
 ["zero-literal",natRec(lit(0n)),seven],
 ["three-literal",natRec(lit(3n)),seven],
 ["major-beta",natRec(app(lam("n",nat,bv(0n)),ctorTwo)),seven],
 ["major-zeta",natRec(letE("n",nat,ctorTwo,bv(0n))),seven],
 ["major-metadata",natRec(md(53n,ctorTwo)),seven],
 ["nat-trailing",app(natFn,nine),nine],
 ["unsaturated",partialNat,partialNat],
 ["parameter-field",boxRec(lam("box",box,nat),lam("a",nat,bv(0n))),five],
 ["trailing-field",app(boxRec(lam("box",box,fnType),lam("a",nat,lam("x",nat,bv(1n)))),nine),five],
 ["trailing-argument",app(boxRec(lam("box",box,fnType),lam("a",nat,lam("x",nat,bv(0n)))),nine),nine]
];
const invalids=[
 natRec(cn(get("psKernelNatSuccName"))),natRec(boxMajor),
 apps(cn(natRecName),[natMotive,seven,natStep,ctorZero]),
 apps(cn(boxRecName,[one,unit(L.zero)]),[nat,lam("box",box,nat),s1,boxMajor])
];
const literal=natRec(lit(0n)),constructor=natRec(ctorZero),missingFields=invalids[0];
const noRule=invalids[1],wrongLevels=invalids[2];
const kExpr=apps(cn(kInfo.base.name),[lam("k",kType,kType),cn(kCtorName),cn(kCtorName)]);
const input=arena,built=accepted(get("psKernelExprV2DecodeChecked")(input),"input-decode");
let generated={arena:input,built,declarations};
for(const command of commands)generated=accepted(get("psKernelDagGeneratedAfterCommand")(
 command,session.environment,generated),"install-checked-generated");
accepted(get("psKernelExprV2PagedValidate")(generated.arena),"generated-arena-valid");
must(generated.arena.size===generated.built.size&&generated.arena.size>input.size,"private-owning-size");
const exprEq=(a,b)=>get("psKernelExprEq")(a)(b);
const exact=(a,b)=>get("psKernelExprEqual")(a)(b);
const decoded=(owned,id)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(owned),"decode"),id),"decoded-root");
for(let index=0n;index<input.size;index++){
 const before=accepted(get("psKernelExprV2DecodedRequire")(built,index),"old-input-ID");
 const after=accepted(get("psKernelExprV2DecodedRequire")(generated.built,index),"new-input-ID");
 must(exact(before,after),"original-ID-stable");
}
for(const info of [natInfo,boxInfo,kInfo]){
 const owner=accepted(get("psKernelExprV2DeclarationRefFind")(generated.declarations)(info.base.name),"owner");
 must(exact(info.base.type,decoded(generated.arena,owner.type)),"generated-type-exact");
 must(get("psKernelExprV2DeclarationRefMatches")(owner,CI.recInfo(info)),"generated-live-kind");
 for(const rule of array(info.rules)){
  const rhs=accepted(get("psKernelExprV2RecursorRuleOwner")(generated.declarations,info,rule),"rule-owner");
  must(exact(rule.rhs,decoded(generated.arena,rhs)),"generated-rule-exact");
 }
}
must(!same(get("psKernelExprV2DeclarationRefFind")(generated.declarations)(kInfo.base.name),none),"checked-K-owner-installed");
const scalar=get("psKernelKernelSessionChecker")(session,nil,safe).context;
const oldEmpty=get("psKernelCheckerStateEmpty"),oldEq=get("psKernelIsDefEqWithFuel");
const noLocal=get("psKernelExprV2NoLocalValue");
const initial=()=>get("psKernelExprV2WhnfStateForDeclarations")(generated.arena,generated.declarations);
const raw=(fuel,c,s,r)=>get("psKernelExprV2TryWhnfStateWithFuel")(fuel)(c)(s)(r);
const reducer=fuel=>get("psKernelExprV2TryReduceRecursorWithLocalValuesFuel")(fuel)(noLocal);
const compare=(old,actual,label)=>{
 const value=accepted(actual,label+"-owned");
 if(rejected(old)){must(rejected(value)&&value.error===old.error,label+"-exact-error");return;}
 const left=accepted(old,label+"-reference"),right=accepted(value,label+"-result");
 must(exact(left.fst,decoded(right.fst.arena,right.snd)),label+"-exact-term");
};
const compareReduction=(old,actual,label)=>{
 const value=accepted(actual,label+"-owned");
 if(rejected(old)){must(rejected(value)&&value.error===old.error,label+"-exact-error");return;}
 const left=accepted(old,label+"-reference"),right=accepted(value,label+"-result");
 if(same(left.fst,none)){must(same(right.snd,none),label+"-no-reduction");}
 else{
  const expression=accepted(left.fst,label+"-reference-some"),id=accepted(right.snd,label+"-result-some");
  must(exact(expression,decoded(right.fst.arena,id)),label+"-exact-term");
 }
};
let publicCases=0,coreCases=0,owners=0,reducers=0;
for(const [label,term,expected] of fixtures){
 for(const fuel of [0n,1n,2n,3n,6n,16n,64n])for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
  const c={...scalar,maxRecDepth,recDepth};
  compare(get("psKernelWhnfWithRecursorFuel")(fuel,oldEq(fuel),c,oldEmpty,term.term),
   raw(fuel,c,initial(),term.id),label+"-public");publicCases++;
  for(const cheapProj of [false,true]){
   compare(get("psKernelWhnfCoreWithRecursorFuel")(fuel,oldEq(fuel),c,oldEmpty,term.term,false,cheapProj),
    get("psKernelExprV2CheckWhnfCoreWithFuel")(fuel,get("psKernelExprV2CheckContextEmpty")(c),
     initial(),term.id,cheapProj),label+"-core");coreCases++;
  }
 }
 for(const fuel of [0n,1n,2n,4n,16n])for(const recFuel of [0n,1n,2n,8n])
  for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
   const c={...scalar,maxRecDepth,recDepth};
   compare(get("psKernelWhnfWithFuel")(fuel)(
    get("psKernelReduceRecursorBoundedWithFuel")(recFuel)(oldEq(64n)))(c)(oldEmpty)(term.term),
    get("psKernelExprV2TryWhnfStateWithReducerFuel")(fuel)(reducer(recFuel))(noLocal)(c)(initial())(term.id),
    label+"-fixed-owner");owners++;
  }
 for(const fuel of [0n,1n,2n,3n,8n,32n]){
  compareReduction(get("psKernelReduceRecursorBoundedWithFuel")(fuel)(oldEq(64n))
   (scalar)(oldEmpty)(term.term)(false)(false),reducer(fuel)(scalar)(initial())(term.id)(false),
   label+"-reducer");reducers++;
 }
 const checked=accepted(get("psKernelV1Whnf")(session,nil,safe,term.term),label+"-checked-V1");
 must(exprEq(checked,expected.term),label+"-checked-reference");
 const owned=accepted(accepted(raw(4096n,scalar,initial(),term.id),label+"-owned-some"),label+"-owned-ok");
 must(exprEq(decoded(owned.fst.arena,owned.snd),expected.term),label+"-owned-complete");
}
must(publicCases===252&&coreCases===504&&owners===720&&reducers===72,"complete-matrix");

const run=extra=>get("psKernelV1RunDag")(empty,nil,safe,input,list([...commands,...extra]));
const replay=accepted(run(fixtures.map(([,term])=>C.whnf(term.id))),"complete-public-batch");
const answers=array(replay.replies).slice(commands.length),Reply=get("PsKernelDagReply");
must(answers.length===fixtures.length,"public-batch-reply-count");
answers.forEach((answer,i)=>must(same(answer,Reply.normalized(answer.value))&&
 exprEq(answer.value,fixtures[i][2].term),"public-batch-decision"));
const def={base:{name:name("iotaChecked"),levelParams:nil,type:nat.id},
 value:literal.id,hints,safety:safe};
const admitted=accepted(run([C.admit(D.definitionDecl(def)),C.check(literal.id),C.isDefEq(literal.id,seven.id)]),
 "real-definition-check-defeq");
const admittedReplies=array(admitted.replies);
must(same(admittedReplies.at(-1),Reply.equal(true)),"real-definition-batch-true");
must(admittedReplies.length===commands.length+3,"real-definition-batch-count");
const badDef={...def,base:{name:name("iotaWrong"),levelParams:nil,type:literal.id}};
invalid(run([C.admit(D.definitionDecl(badDef))]),"bad-definition-batch-rejected");
for(const term of invalids){
 const a=get("psKernelV1Whnf")(session,nil,safe,term.term),b=run([C.whnf(term.id)]);
 invalid(a,"V1-invalid-recursor");invalid(b,"public-invalid-recursor");
 must(same(a.error,b.error),"invalid-exact-error");
}
const privateId=input.size,privateHeader={name:name("privateHeader"),levelParams:nil,type:privateId};
const publicHeader={name:name("privateBody"),levelParams:nil,type:nat.id};
const privateDefinition={base:publicHeader,value:privateId,hints,safety:safe};
const privateCommands=[
 C.check(privateId),C.whnf(privateId),C.isDefEq(privateId,nat.id),C.isDefEq(nat.id,privateId),
 C.admit(D.axiomDecl(privateHeader,false)),C.admit(D.definitionDecl(privateDefinition)),
 C.admit(D.theoremDecl(publicHeader,privateId)),C.admit(D.opaqueDecl(publicHeader,privateId,false)),
 C.admit(D.mutualDefinitions(list([privateDefinition])))
];
const privateRefused=(result,label)=>{
 invalid(result,label);
 must(result.error.message==="PSKERNEL_V2_DECODE_INVALID_REFERENCE",label+"-exact-ID-error");
};
for(const command of privateCommands){
 privateRefused(run([command]),"private-generated-ID-never-public");
 privateRefused(get("psKernelDagRunCommandWithSource")(built,{session,declarations:generated.declarations},
  nil,safe,generated.arena,generated.built,command),"source-worker-private-ID-never-public");
}
const beforePrivate=run([C.admit(D.unsupported("IOTA_ORDER_SENTINEL")),C.check(privateId)]);
must(rejected(beforePrivate)&&same(beforePrivate.error,
 get("PsKernelError").declinedUnsupported("IOTA_ORDER_SENTINEL")),"sequential-error-precedence");
must(same(get("psKernelEnvironmentFind")(empty.environment,natName),none),"failed-batch-atomic");
accepted(run([]),"valid-admission-after-private-ID-refusals");
const expectError=(attempt,message,label)=>{
 const value=accepted(attempt,label+"-some");
 must(rejected(value)&&value.error===message,label);
};
const badWhnf=c=>s=>r=>Option.some(Ex.error("IOTA_MAJOR_CALLBACK"));
const missingWhnf=c=>s=>r=>none;
const direct=(whnf,state,root)=>get("psKernelExprV2TryReduceInductiveRecursor")(whnf,scalar,state,root);
const unowned=()=>get("psKernelExprV2WhnfStateForDeclarations")(generated.arena,declarations);
const ctorResult=accepted(accepted(direct(badWhnf,initial(),constructor.id),"ctor-some"),"ctor-ok");
must(!same(ctorResult.snd,none),"constructor-skips-major-WHNF");
expectError(direct(badWhnf,initial(),literal.id),"IOTA_MAJOR_CALLBACK","literal-calls-WHNF");
must(same(direct(missingWhnf,initial(),literal.id),none),"literal-callback-fallback");
must(same(direct(badWhnf,unowned(),constructor.id),none),"missing-owner-fallback");
for(const term of [partialNat,missingFields,noRule,wrongLevels]){
 const result=accepted(accepted(direct(badWhnf,unowned(),term.id),"inert-some"),"inert-ok");
 must(same(result.snd,none)&&result.fst.arena.size===generated.arena.size,"inert-before-owner-and-callback");
}
must(same(direct(badWhnf,initial(),kExpr.id),none),"K-no-temporary-checker");
expectError(reducer(0n)(scalar)(initial())(generated.arena.size+1n)(false),
 "kernel recursor budget exhausted","zero-recursor-before-root");
expectError(reducer(1n)(scalar)(initial())(literal.id)(false),
 "kernel reduction budget exhausted","literal-predecessor-zero-budget");
const oneBudget=accepted(accepted(reducer(1n)(scalar)(initial())(constructor.id)(false),
 "constructor-fuel-one-some"),"constructor-fuel-one-ok");
must(!same(oneBudget.snd,none),"constructor-no-predecessor-WHNF-charge");
const markWhnf=c=>s=>r=>{
 const entry=accepted(get("psKernelExprV2PagedRequire")(s.arena,r),"mark-valid-source");
 return Option.some(Ex.ok({fst:{...s,publicCache:get("psKernelExprV2WhnfCacheFromList")(list([{source:r,result:r,hash:entry.hash}]))},snd:r}));
};
const marked=accepted(accepted(direct(markWhnf,initial(),literal.id),"marked-some"),"marked-ok");
must(!same(marked.snd,none)&&array(get("psKernelExprV2WhnfCacheEntries")(marked.fst.publicCache)).length===1,"callback-state-preserved");
const warm=accepted(accepted(raw(4096n,scalar,initial(),constructor.id),"warm-some"),"warm-ok");
expectError(raw(0n,scalar,warm.fst,constructor.id),"kernel reduction budget exhausted","warm-guard");
// Preserve the old Sort-u fixture as explicit public rejection controls.
const restrictedName=name("IotaSortBox"),restrictedCtor=N.str(restrictedName,"mk");
const restrictedRec=get("psKernelSimpleRecName")(restrictedName);
const restrictedType=forall("A",sort(universe),sort(universe));
const restrictedCtorType=forall("A",sort(universe),forall("value",bv(0n),
 apps(cn(restrictedName,[universe]),[bv(1n)])));
const restrictedSession=accepted(get("psKernelV1AdmitDeclaration")(session,Request.ordinaryInductive({
 levelParams:list([u]),name:restrictedName,type:restrictedType.term,
 ctors:list([{name:restrictedCtor,type:restrictedCtorType.term}]),isUnsafe:false,numParams:1n
})),"checked-inductive-IotaSortBox").session;
const restrictedRequest=D.ordinaryInductive(list([u]),1n,{
 name:restrictedName,type:restrictedType.id,ctors:list([{name:restrictedCtor,type:restrictedCtorType.id}])
},false);
const restrictedTagged=accepted(get("psKernelEnvironmentFind")(
 restrictedSession.environment,restrictedRec),"Sort-u-recursor");
must(same(restrictedTagged,CI.recInfo(restrictedTagged.value)),"Sort-u-checked-recursor-kind");
must(array(restrictedTagged.value.base.levelParams).length===1,"Sort-u-Prop-only-recursor");
const restrictedBox=app(cn(restrictedName,[one]),nat);
const restrictedMajor=apps(cn(restrictedCtor,[one]),[nat,five]);
const restrictedArgs=[nat,lam("box",restrictedBox,nat),lam("a",nat,bv(0n)),restrictedMajor];
for(const [label,levels,message] of [
 ["wrong-universe-arity",[one,one],"incorrect number of universe levels"],
 ["forbidden-data-elimination",[one],"application type mismatch"]
]){
 const term=apps(cn(restrictedRec,levels),restrictedArgs);
 const reference=get("psKernelV1Whnf")(restrictedSession,nil,safe,term.term);
 const actual=get("psKernelV1RunDag")(empty,nil,safe,arena,
  list([...commands,C.admit(restrictedRequest),C.whnf(term.id)]));
 invalid(reference,"Sort-u-"+label+"-V1");invalid(actual,"Sort-u-"+label+"-public-DAG");
 must(reference.error.message===message&&same(reference.error,actual.error),"Sort-u-"+label+"-exact-error");
}

// Complete non-K major normalization: fresh checked declarations and owners.
{
 const savedArena=arena;
 arena=input;
 let majorSession=session,majorDeclarations=declarations;
 const majorCommands=[...commands];
 const axiom=(n,type)=>{
  majorSession=accepted(get("psKernelV1AdmitDeclaration")(
   majorSession,Request.axiomDecl({base:{name:n,levelParams:nil,type:type.term},isUnsafe:false})),"major-neutral-axiom").session;
  const request=D.axiomDecl({name:n,levelParams:nil,type:type.id},false);
  majorDeclarations=get("psKernelDagDeclarationsAfterAdmission")(request,majorDeclarations);
  majorCommands.push(C.admit(request));
 };
 const natNeutralName=name("iotaNeutralNat"),boxNeutralName=name("iotaNeutralBox");
 axiom(natNeutralName,nat);axiom(boxNeutralName,box);
 const natNeutral=cn(natNeutralName),boxNeutral=cn(boxNeutralName);
 const projection=build("Proj",E.proj(boxName,0n,boxNeutral.term),boxName,0n,boxNeutral.id);
 const recOn=(major,motive,minor)=>apps(cn(boxRecName,[one,unit(L.zero)]),[nat,motive,minor,major]);
 const motive=lam("box",box,nat),minor=lam("value",nat,bv(0n));
 const stuck=natRec(natNeutral);
 const majorCases=[
  ["stuck-recursive-major",stuck,stuck],
  ["neutral-structure-field",recOn(boxNeutral,motive,minor),projection],
  ["neutral-structure-constant",recOn(boxNeutral,motive,lam("value",nat,lit(11n))),lit(11n)],
  ["structure-major-beta",recOn(app(lam("box",box,bv(0n)),boxNeutral),motive,minor),projection],
  ["structure-major-zeta",recOn(letE("box",box,boxNeutral,bv(0n)),motive,minor),projection],
  ["structure-trailing",app(recOn(boxNeutral,lam("box",box,fnType),
   lam("value",nat,lam("x",nat,bv(1n)))),nine),projection]
 ];
 // The motive returns Type, so its recursor elimination level is two.
 const dependentType=forall("box",box,apps(cn(boxRecName,[L.succ(one),unit(L.zero)]),
  [nat,lam("box",box,s1),lam("value",nat,nat),bv(0n)]));
 const dependentValue=lam("box",box,lit(0n));
 const majorDefinitions=[
  ["majorDependent",dependentType,dependentValue,true],
  ["majorProjected",nat,recOn(boxNeutral,motive,minor),true],
  ["majorWrongType",s1,recOn(boxNeutral,motive,minor),false],
  ["majorWrongDependent",dependentType,lam("box",box,s1),false]
 ];
 const orderRoot=recOn(boxNeutral,motive,minor);
 const majorInput=arena,majorBuilt=accepted(get("psKernelExprV2DecodeChecked")(majorInput),"major-input");
 let owned={arena:majorInput,built:majorBuilt,declarations:majorDeclarations};
 for(const command of majorCommands)owned=accepted(get("psKernelDagGeneratedAfterCommand")(
  command,majorSession.environment,owned),"major-checked-generated");
 const majorScalar=get("psKernelKernelSessionChecker")(majorSession,nil,safe).context;
 const context=c=>get("psKernelExprV2CheckContextEmpty")(c);
 const initial=()=>get("psKernelExprV2CheckStateFromWhnf")(
  get("psKernelExprV2WhnfStateForDeclarations")(owned.arena,owned.declarations));
 const local=c=>n=>get("psKernelExprV2CheckLocalValue")(c,n);
 const dagEq=get("psKernelExprV2TryDefEqStateWithFuel");
 const majorReducer=fuel=>get("psKernelExprV2TryReduceRecursorOwnedWithFuel")(fuel)(dagEq(64n))(local);
 const attempt=(value,label)=>accepted(accepted(value,label+"-some"),label+"-ok");
 const ok=(s,r)=>Option.some(Ex.ok({fst:s,snd:r}));
 const error=message=>Option.some(Ex.error(message));
 const compareMajor=(old,actual,label,reduction=false)=>{
  const attempted=accepted(actual,label+"-owned");
  if(rejected(old)){must(rejected(attempted)&&attempted.error===old.error,label+"-exact-error");return;}
  const a=accepted(old,label+"-reference"),b=accepted(attempted,label+"-result");
  must(a.snd.nextFresh===b.fst.nextFresh,label+"-fresh-counter");
  if(reduction){
   if(same(a.fst,none)){must(same(b.snd,none),label+"-inert");return;}
   must(exact(accepted(a.fst,label+"-old-root"),decoded(b.fst.whnf.arena,
    accepted(b.snd,label+"-new-root"))),label+"-exact-term");
  }else must(exact(a.fst,decoded(b.fst.whnf.arena,b.snd)),label+"-exact-term");
 };
 let publics=0,cores=0,ownerCases=0,reducerCases=0;
 for(const [label,term] of majorCases){
  for(const fuel of [0n,1n,2n,3n,6n,16n,64n])
   for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
    const oldContext={...majorScalar,maxRecDepth,recDepth},c=context(oldContext);
    compareMajor(get("psKernelWhnfWithRecursorFuel")(fuel,oldEq(fuel),oldContext,oldEmpty,term.term),
     get("psKernelExprV2TryWhnfCheckStateWithFuel")(fuel,c,initial(),term.id),label+"-public");
    publics++;
    for(const cheapRec of [false,true])for(const cheapProj of [false,true]){
     compareMajor(get("psKernelWhnfCoreWithRecursorFuel")(
      fuel,oldEq(fuel),oldContext,oldEmpty,term.term,cheapRec,cheapProj),
      get("psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel")(
       fuel,dagEq(fuel),local,c,initial(),term.id,cheapRec,cheapProj),label+"-core");
     cores++;
    }
   }
  for(const fuel of [0n,1n,2n,4n,16n])for(const recFuel of [0n,1n,2n,8n])
   for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
    const oldContext={...majorScalar,maxRecDepth,recDepth};
    compareMajor(get("psKernelWhnfWithFuel")(fuel)(
     get("psKernelReduceRecursorBoundedWithFuel")(recFuel)(oldEq(64n)))(
      oldContext)(oldEmpty)(term.term),
     get("psKernelExprV2TryWhnfOwnedWithReducerFuel")(fuel)(majorReducer(recFuel))(local)(
      context(oldContext))(initial())(term.id),label+"-fixed-owner");
    ownerCases++;
   }
  for(const fuel of [0n,1n,2n,3n,8n,32n])
   for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
    const oldContext={...majorScalar,maxRecDepth,recDepth};
    for(const cheapRec of [false,true])for(const cheapProj of [false,true]){
     compareMajor(get("psKernelReduceRecursorBoundedWithFuel")(fuel)(oldEq(64n))(
      oldContext)(oldEmpty)(term.term)(cheapRec)(cheapProj),
      majorReducer(fuel)(context(oldContext))(initial())(term.id)(cheapRec)(cheapProj),
      label+"-reducer",true);reducerCases++;
    }
   }
 }
 must(publics===126&&cores===504&&ownerCases===360&&reducerCases===432,"major-complete-resource-matrix");
 console.log("PSC1_V2_DAG_RECURSOR_MAJOR_MATRIX_JS: PASS public=126 core=504 owners=360 reducer=432");
 const majorRun=extra=>get("psKernelV1RunDag")(empty,nil,safe,majorInput,list([...majorCommands,...extra]));
 const majorReplies=array(accepted(majorRun(majorCases.map(([,term])=>C.whnf(term.id))),
  "major-public-batch").replies).slice(majorCommands.length);
 must(majorReplies.length===majorCases.length,"major-public-batch-complete");
 majorReplies.forEach((reply,i)=>{
  const [label,term,expected]=majorCases[i];
  must(same(reply,Reply.normalized(reply.value))&&exprEq(reply.value,expected.term),label+"-public-result");
  must(exprEq(accepted(get("psKernelV1Whnf")(majorSession,nil,safe,term.term),label+"-V1"),expected.term),
   label+"-V1-result");
 });
 for(const [label,type,value,shouldAccept] of majorDefinitions){
  const declaration=Request.definitionDecl({
   base:{name:name(label),levelParams:nil,type:type.term},value:value.term,hints,safety:safe});
  const request=D.definitionDecl({
   base:{name:name(label),levelParams:nil,type:type.id},value:value.id,hints,safety:safe});
  const reference=get("psKernelV1AdmitDeclaration")(majorSession,declaration);
  const actual=majorRun([C.admit(request)]);
  const resources=majorSession.resources;
  const direct=accepted(get("psKernelDagTryAdmitSimpleWithFuel")(
   resources.fuel,get("psKernelKernelSessionEnvironment")(majorSession),resources.maxRecDepth,resources.maxNatSize,
   owned.arena,owned.declarations,request,declaration),label+"-direct-V2-some");
  if(shouldAccept){
   const environment=accepted(direct,label+"-direct-V2-ok");
   must(!same(get("psKernelEnvironmentFind")(environment,name(label)),none),label+"-direct-V2-published");
  }else must(rejected(direct)&&rejected(reference)&&direct.error===reference.error.message,
   label+"-direct-V2-exact-error");
  if(shouldAccept){accepted(reference,label+"-V1-admission");accepted(actual,label+"-public-admission");}
  else{invalid(reference,label+"-V1-invalid");invalid(actual,label+"-public-invalid");}
 }
 console.log("PSC1_V2_DAG_RECURSOR_MAJOR_ADMISSION_JS: PASS valid=6 admitted=2 rejected=2");

 const modulus=BigInt(get("psKernelCacheHashModulus"));
 const tagRows=(rows,tag)=>{const xs=array(rows);return xs.length===1&&BigInt(xs[0].hash)===modulus+tag;};
 const markerInArena=(state,tag)=>{
  const rows=array(get("psKernelExprV2WhnfCacheEntries")(state.checkedInfer));
  if(rows.length!==1)return false;
  const found=get("psKernelExprV2PagedRequire")(state.whnf.arena,rows[0].result);
  return !rejected(found)&&same(accepted(found,"major-marker-node").node,
   get("PsKernelExprV2Node").lit(Literal.nat(12000n+tag)));
 };
 const tagged=(state,tag)=>state.nextFresh===tag&&tagRows(get("psKernelExprV2WhnfCacheEntries")(state.checkedInfer),tag)&&
  tagRows(state.success,tag)&&tagRows(get("psKernelExprV2WhnfCacheEntries")(state.inferOnly),tag)&&tagRows(get("psKernelExprV2WhnfCacheEntries")(state.unfold),tag)&&tagRows(state.failure,tag)&&markerInArena(state,tag);
 const stamp=(key,state,tag)=>{
  const made=accepted(get("psKernelExprV2PagedMkLit")(state.whnf.arena,Literal.nat(12000n+tag)),"major-stamp");
  const cache={source:key,result:made.snd,hash:modulus+tag},pair={left:key,right:key,hash:modulus+tag};
  return {whnf:{arena:made.fst,coreCache:get("psKernelExprV2WhnfCacheInsert")(state.whnf.coreCache,cache),
   publicCache:get("psKernelExprV2WhnfCacheInsert")(state.whnf.publicCache,cache),declarations:state.whnf.declarations},
   nextFresh:tag,checkedInfer:get("psKernelExprV2WhnfCacheFromList")(list([cache])),success:list([pair]),inferOnly:get("psKernelExprV2WhnfCacheFromList")(list([cache])),
   unfold:get("psKernelExprV2WhnfCacheFromList")(list([cache])),failure:list([pair])};
 };
 const callback=(seed,failAt,decline,expected,result,tag,state,root)=>{
  if(root!==expected||!tagged(state,tag))return error("major callback received wrong input or stale state");
  if(failAt===tag+1n-seed)return decline?none:error("MAJOR_INJECTED");
  return ok(stamp(expected,state,tag+1n),result);
 };
 const c=context(majorScalar),seed=30n,seeded=stamp(boxNeutral.id,initial(),seed);
 must(!tagged({...seeded,whnf:{...seeded.whnf,arena:owned.arena}},seed),"major-arena-loss-marker-detected");
 const denyEq=_c=>_s=>_a=>_b=>error("MAJOR_FORBIDDEN_DEFEQ");
 const oldW=_c=>s=>r=>Ex.ok({fst:r,snd:{...s,nextFresh:s.nextFresh+1n}});
 const oldC=c=>s=>r=>_cr=>_cp=>oldW(c)(s)(r);
 const oldI=_c=>s=>r=>exact(r,boxNeutral.term)?Ex.ok({fst:box.term,snd:{...s,nextFresh:s.nextFresh+1n}}):
  exact(r,box.term)?Ex.ok({fst:s1.term,snd:{...s,nextFresh:s.nextFresh+1n}}):Ex.error("MAJOR_OLD_INFER_INPUT");
 const oldD=_c=>_s=>_a=>_b=>Ex.error("MAJOR_FORBIDDEN_DEFEQ");
 let sequences=0,propagated=0;
 for(const cheapRec of [false,true])for(const cheapProj of [false,true]){
  const run=(failAt,decline)=>{
   const publicWhnf=_c=>s=>r=>s.nextFresh===seed?
    callback(seed,failAt,decline,boxNeutral.id,boxNeutral.id,seed,s,r):
    s.nextFresh===seed+2n?callback(seed,failAt,decline,box.id,box.id,seed+2n,s,r):
    callback(seed,failAt,decline,s1.id,s1.id,seed+4n,s,r);
   const coreWhnf=_c=>s=>r=>cr=>cp=>cr===cheapRec&&cp===cheapProj?
    callback(seed,failAt,decline,boxNeutral.id,boxNeutral.id,seed,s,r):error("MAJOR_CHEAP_FLAGS");
   const inferType=_c=>s=>r=>s.nextFresh===seed+1n?
    callback(seed,failAt,decline,boxNeutral.id,box.id,seed+1n,s,r):
    callback(seed,failAt,decline,box.id,s1.id,seed+3n,s,r);
   return get("psKernelExprV2TryReduceRecursorOwnedWith")(
    publicWhnf,coreWhnf,inferType,denyEq,c,seeded,orderRoot.id,cheapRec,cheapProj);
  };
  const actual=run(0n,false);
  compareMajor(get("psKernelReduceRecursorWith")(oldW,oldC,oldI,oldD,majorScalar,
   {...oldEmpty,nextFresh:seed},orderRoot.term,cheapRec,cheapProj),actual,"major-five-fixed-callbacks",true);
  const result=attempt(actual,"major-five-callbacks");
  must(tagged(result.fst,seed+5n),"major-all-six-fields-after-rule");
  must(array(get("psKernelExprV2WhnfCacheEntries")(result.fst.whnf.coreCache)).some(row=>BigInt(row.hash)===modulus+seed+5n),"major-core-retained");
  must(array(get("psKernelExprV2WhnfCacheEntries")(result.fst.whnf.publicCache)).some(row=>BigInt(row.hash)===modulus+seed+5n),"major-public-retained");
  must(!same(get("psKernelExprV2DeclarationRefFind")(result.fst.whnf.declarations)(boxRecName),none),
   "major-owner-retained");
  must(!same(result.snd,none),"major-rule-actually-reduced");
  accepted(get("psKernelExprV2PagedValidate")(result.fst.whnf.arena),"major-final-arena");
  sequences++;
  for(const failAt of [1n,2n,3n,4n,5n])for(const decline of [false,true]){
   const failure=run(failAt,decline);
   if(same(failure,none))must(decline,"major-outer-None-propagation");
   else{const result=accepted(failure,"major-propagated-some");
    must(!decline&&rejected(result)&&result.error==="MAJOR_INJECTED","major-exact-propagation");}
   propagated++;
  }
 }
 must(sequences===4&&propagated===40,"major-sequence-matrix");
 console.log("PSC1_V2_DAG_RECURSOR_MAJOR_STATE_JS: PASS sequence=4 propagated=40");

 let familyCases=0;
 for(const info of [natInfo,boxInfo]){
  const type=accepted(get("psKernelExprV2RecursorTypeOwner")(owned.declarations,info),"major-type-owner");
  for(const fuel of [0n,1n,2n,3n,4n,5n,8n])for(const index of [0n,1n,3n,4n,8n]){
   const expected=get("psKernelRecursorMajorInductWithFuel")(fuel)(info.base.type)(index);
   const actual=accepted(get("psKernelExprV2RecursorMajorInductWithFuel")(fuel)(owned.arena)(type)(index),
    "major-type-walk");
   must(same(expected,actual),"major-type-walk-exact");familyCases++;
  }
 }
 const bad=owned.arena.size+1n;
 must(same(accepted(get("psKernelExprV2RecursorMajorInductWithFuel")(0n)(owned.arena)(bad)(0n),
  "major-zero"),none),"major-type-zero-before-root");
 const expectedInvalid=get("psKernelExprV2PagedRequire")(owned.arena,bad);
 const actualInvalid=get("psKernelExprV2RecursorMajorInductWithFuel")(1n)(owned.arena)(bad)(0n);
 must(rejected(expectedInvalid)&&rejected(actualInvalid)&&expectedInvalid.error===actualInvalid.error,
  "major-type-positive-invalid-root");
 const forbidden=_c=>_s=>_r=>error("MAJOR_FORBIDDEN_CALLBACK");
 const unowned=get("psKernelExprV2CheckStateFromWhnf")(
  get("psKernelExprV2WhnfStateForDeclarations")(owned.arena,nil));
 const struct=(state,info,root)=>get("psKernelExprV2RecursorToStructureOwnedWith")(
  forbidden,forbidden,c,state,info,root);
 must(attempt(struct(unowned,boxInfo,boxMajor.id),"major-ctor-shortcut").snd===boxMajor.id,
  "major-constructor-before-owner");
 must(attempt(struct(initial(),natInfo,natNeutral.id),"major-recursive").snd===natNeutral.id,
  "major-recursive-family-never-infers");
 must(same(struct(unowned,natInfo,natNeutral.id),none),"major-missing-owner-decline");
 must(same(get("psKernelExprV2RecursorNormalizeMajor")(
  majorScalar,initial().whnf,natNeutral.id),none),"major-compatibility-scope-unchanged");
 for(const fuel of [0n,1n,2n,4n])for(const [count,index] of [[0n,0n],[1n,0n],[3n,0n],[3n,1n],[1n,2n]]){
  const expected=array(get("psKernelStructureFieldsWithFuel")(fuel)(boxName)(boxNeutral.term)(count)(index));
  const actual=accepted(get("psKernelExprV2RecursorStructureFieldsWithFuel")(fuel)(
   owned.arena)(boxName)(boxNeutral.id)(count)(index),"major-fields");
  const roots=array(actual.snd);must(roots.length===expected.length,"major-field-count-truncation");
  roots.forEach((root,i)=>must(exact(decoded(actual.fst,root),expected[i]),"major-field-order-exact"));
 }
 must(familyCases===70,"major-family-count");
 console.log("PSC1_V2_DAG_RECURSOR_MAJOR_FAMILY_JS: PASS comparisons=70 fields=20");

 const stringValues=["","a","é","e\u0301","🙂","a\u0000β"];
 let stringCases=0,stringFailures=0;
 arena=owned.arena;
 for(const value of stringValues){
  const major=build("Lit",E.lit(Literal.str(value)),Literal.str(value));
  const term=natRec(major);
  const state={...initial(),whnf:{...initial().whnf,arena}};
  const identity=_c=>s=>r=>ok(s,r);
  const normalized=attempt(get("psKernelExprV2RecursorNormalizeMajorOwnedWith")(
   identity,forbidden,c,state,natInfo,major.id),"String-major-normalize");
  must(exact(get("psKernelStringLitToConstructor")(value),decoded(normalized.fst.whnf.arena,normalized.snd)),
   "String-major-constructor-exact");
  // Intentionally ill-typed raw Nat-rec/String inputs only inspect callbacks.
  // These are never counted as admitted declarations.
  const seeded=stamp(major.id,state,60n);
  for(const cheapRec of [false,true])for(const cheapProj of [false,true]){
   const run=(failAt,decline)=>{
    const publicWhnf=_c=>s=>r=>s.nextFresh===60n?
     callback(60n,failAt,decline,major.id,major.id,60n,s,r):
     callback(60n,failAt,decline,r,r,61n,s,r);
    const coreWhnf=_c=>s=>r=>cr=>cp=>cr===cheapRec&&cp===cheapProj?
     callback(60n,failAt,decline,major.id,major.id,60n,s,r):error("STRING_MAJOR_CHEAP_FLAGS");
    return get("psKernelExprV2TryReduceRecursorOwnedWith")(
     publicWhnf,coreWhnf,forbidden,denyEq,c,seeded,term.id,cheapRec,cheapProj);
   };
   const actual=run(0n,false);
   const oldInfer=_c=>_s=>_r=>Ex.error("STRING_MAJOR_FORBIDDEN_INFERENCE");
   compareMajor(get("psKernelReduceRecursorWith")(oldW,oldC,oldInfer,oldD,majorScalar,
    {...oldEmpty,nextFresh:60n},term.term,cheapRec,cheapProj),actual,"String-public-callback",true);
   const result=attempt(actual,"String-major-two-states");
   must(tagged(result.fst,62n)&&same(result.snd,none),"String-major-two-complete-states");
   stringCases++;
   for(const decline of [false,true]){
    const failure=run(2n,decline);
    if(same(failure,none))must(decline,"String-second-public-None");
    else{const result=accepted(failure,"String-failure-some");
     must(!decline&&rejected(result)&&result.error==="MAJOR_INJECTED","String-second-public-error");}
    stringFailures++;
   }
  }
 }
 must(stringCases===24&&stringFailures===48,"String-major-matrix");
 console.log("PSC1_V2_DAG_RECURSOR_MAJOR_STRING_JS: PASS callbacks=24 propagated=48");
 arena=savedArena;
}

console.log("PSC1_V2_DAG_RECURSOR_UNIVERSE_NEGATIVES_JS: PASS cases=2");
console.log("PSC1_V2_DAG_RECURSOR_JS: PASS public=252 core=504 owners=720 reducer=72 privateIDs=9 assertions="+assertions);
