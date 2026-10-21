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
for(const info of [natInfo,boxInfo]){
 const owner=accepted(get("psKernelExprV2DeclarationRefFind")(generated.declarations)(info.base.name),"owner");
 must(exact(info.base.type,decoded(generated.arena,owner.type)),"generated-type-exact");
 must(get("psKernelExprV2DeclarationRefMatches")(owner,CI.recInfo(info)),"generated-live-kind");
 for(const rule of array(info.rules)){
  const rhs=accepted(get("psKernelExprV2RecursorRuleOwner")(generated.declarations,info,rule),"rule-owner");
  must(exact(rule.rhs,decoded(generated.arena,rhs)),"generated-rule-exact");
 }
}
must(same(get("psKernelExprV2DeclarationRefFind")(generated.declarations)(kInfo.base.name),none),"K-owner-absent");
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
 return Option.some(Ex.ok({fst:{...s,publicCache:list([{source:r,result:r,hash:entry.hash}])},snd:r}));
};
const marked=accepted(accepted(direct(markWhnf,initial(),literal.id),"marked-some"),"marked-ok");
must(!same(marked.snd,none)&&array(marked.fst.publicCache).length===1,"callback-state-preserved");
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
console.log("PSC1_V2_DAG_RECURSOR_UNIVERSE_NEGATIVES_JS: PASS cases=2");
console.log("PSC1_V2_DAG_RECURSOR_JS: PASS public=252 core=504 owners=720 reducer=72 privateIDs=9 assertions="+assertions);
