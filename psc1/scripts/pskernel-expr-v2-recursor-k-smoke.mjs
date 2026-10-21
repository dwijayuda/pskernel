import {pathToFileURL} from "node:url";
import path from "node:path";

// All public fixtures use actual checked declarations and private metadata.
// Callback-only marker rows have impossible cache hashes and cannot establish
// judgments. None, errors, false DefEq and complete owner transport are distinct.
const filename=process.argv[2];
if(!filename)throw Error("PSC1_K_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_K_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_K_FAIL "+label);assertions++;};
const accepted=(x,label)=>{
 if(x&&typeof x==="object"&&Object.hasOwn(x,"value"))return x.value;
 const e=x&&typeof x==="object"?x.error:undefined;
 throw Error("PSC1_K_UNEXPECTED_REJECTION "+label+": "+(typeof e==="string"?e:e?.message??"missing value"));
};
const rejected=x=>Boolean(x&&typeof x==="object"&&Object.hasOwn(x,"error"));
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
 const ak=Reflect.ownKeys(a),bk=Reflect.ownKeys(b);
 return ak.length===bk.length&&ak.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
const List=get("List"),nil=unit(List.nil),Option=get("Option"),none=unit(Option.none),Ex=get("Except");
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(xs&&Object.hasOwn(xs,"head")){out.push(xs.head);xs=xs.tail;}return out;};
const attempt=(x,label)=>accepted(accepted(x,label+"-some"),label+"-ok");
const ok=(state,value)=>Option.some(Ex.ok({fst:state,snd:value}));
const error=message=>Option.some(Ex.error(message));
const invalid=(result,label)=>must(rejected(result)&&typeof result.error.message==="string"&&
 same(result.error,get("PsKernelError").rejectedInvalid(result.error.message)),label);
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),S=get("PsKernelDefinitionSafety"),CI=get("PsKernelConstantInfo");
const Request=get("PsKernelDeclarationRequest"),D=get("PsKernelDagDeclarationRequest");
const C=get("PsKernelDagCommand"),Reply=get("PsKernelDagReply");
const name=text=>N.str(unit(N.anonymous),text),one=L.succ(unit(L.zero));
const safe=unit(S.safe),hints=unit(get("PsKernelReducibilityHints").abbrevHint);
const exact=(a,b)=>get("psKernelExprEqual")(a)(b);
let arena=unit(get("psKernelExprV2PagedEmpty"));
const build=(kind,term,...args)=>{
 const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
 arena=result.fst;return {term,id:result.snd};
};
const cn=(n,levels=[])=>build("Const",E.const(n,list(levels)),n,list(levels));
const sort=level=>build("Sort",E.sort(level),level);
const bv=index=>build("BVar",E.bvar(index),index);
const mv=n=>build("MVar",E.mvar(name(n)),name(n));
const app=(f,a)=>build("App",E.app(f.term,a.term),f.id,a.id);
const apps=(f,args)=>args.reduce((x,y)=>app(x,y),f);
const lam=(n,t,b)=>build("Lam",E.lam(name(n),t.term,b.term,unit(B.default)),name(n),t.id,b.id,unit(B.default));
const forall=(n,t,b)=>build("Forall",E.forallE(name(n),t.term,b.term,unit(B.default)),name(n),t.id,b.id,unit(B.default));
const lit=n=>build("Lit",E.lit(Literal.nat(n)),Literal.nat(n));
const md=(tag,x)=>build("MData",E.mdata(tag,x.term),tag,x.id);
const letE=(n,t,v,b)=>build("Let",E.letE(name(n),t.term,v.term,b.term,false),name(n),t.id,v.id,b.id,false);
const natName=get("psKernelNatName"),unitName=name("KUnit"),unitCtor=N.str(unitName,"mk");
const eqName=name("KEquality"),eqCtor=N.str(eqName,"refl");
const unitProofName=name("KUnitProof"),eqProofName=name("KEqualityProof");
const nat=cn(natName),s1=sort(one),s0=sort(unit(L.zero)),zero=lit(0n),seven=lit(7n);
const unitType=cn(unitName),u=name("u"),universe=L.param(u);
const eqType=(level,a,x,y)=>apps(cn(eqName,[level]),[a,x,y]);
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty");
let session=empty,declarations=nil;
const commands=[];
const inductive=(label,n,levels,type,ctors,numParams)=>{
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request.ordinaryInductive({
  levelParams:list(levels),name:n,type:type.term,
  ctors:list(ctors.map(([name,type])=>({name,type:type.term}))),isUnsafe:false,numParams})),label).session;
 const request=D.ordinaryInductive(list(levels),numParams,
  {name:n,type:type.id,ctors:list(ctors.map(([name,type])=>({name,type:type.id})))},false);
 declarations=get("psKernelDagDeclarationsAfterAdmission")(request,declarations);commands.push(C.admit(request));
};
const theorem=(n,type,value)=>{
 session=accepted(get("psKernelV1AdmitDeclaration")(session,
  Request.theoremDecl({base:{name:n,levelParams:nil,type:type.term},value:value.term})),"checked-proof").session;
 const request=D.theoremDecl({name:n,levelParams:nil,type:type.id},value.id);
 declarations=get("psKernelDagDeclarationsAfterAdmission")(request,declarations);commands.push(C.admit(request));
};
inductive("Nat",natName,[],s1,[[get("psKernelNatZeroName"),nat],
 [get("psKernelNatSuccName"),forall("n",nat,nat)]],0n);
inductive("KUnit",unitName,[],s0,[[unitCtor,unitType]],0n);
const equalityDeclType=forall("A",sort(universe),forall("a",bv(0n),forall("b",bv(1n),s0)));
const equalityCtorType=forall("A",sort(universe),forall("a",bv(0n),eqType(universe,bv(1n),bv(0n),bv(0n))));
inductive("KEquality",eqName,[u],equalityDeclType,[[eqCtor,equalityCtorType]],2n);
const equalityType=eqType(one,nat,zero,zero),equalityValue=apps(cn(eqCtor,[one]),[nat,zero]);
theorem(unitProofName,unitType,cn(unitCtor));
theorem(eqProofName,equalityType,equalityValue);
const recInfo=n=>{
 const info=accepted(get("psKernelEnvironmentFind")(session.environment,get("psKernelSimpleRecName")(n)),"recursor");
 must(same(info,CI.recInfo(info.value)),"actual-recursor-kind");return info.value;
};
const unitInfo=recInfo(unitName),eqInfo=recInfo(eqName);
must(unitInfo.k===true&&eqInfo.k===true&&array(unitInfo.base.levelParams).length===1&&
 array(eqInfo.base.levelParams).length===2&&eqInfo.numParams===2n&&eqInfo.numIndices===1n,"actual-K-metadata");
const unitRec=(levels,major)=>apps(cn(unitInfo.base.name,levels),[lam("h",unitType,nat),seven,major]);
const equalityRec=major=>apps(cn(eqInfo.base.name,[one,one]),[
 nat,zero,lam("b",nat,lam("h",eqType(one,nat,zero,bv(0n)),nat)),seven,zero,major]);
const unitMajor=cn(unitProofName),major=cn(eqProofName);
const valid=[
 ["unit-constructor",unitRec([one],cn(unitCtor))],
 ["unit-theorem",unitRec([one],unitMajor)],
 ["unit-beta",unitRec([one],app(lam("h",unitType,bv(0n)),unitMajor))],
 ["unit-zeta",unitRec([one],letE("h",unitType,unitMajor,bv(0n)))],
 ["equality-constructor",equalityRec(equalityValue)],
 ["equality-theorem",equalityRec(major)]
];
const negatives=[
 ["missing-level",unitRec([],cn(unitCtor))],
 ["extra-level",unitRec([one,one],cn(unitCtor))],
 ["wrong-major",unitRec([one],zero)]
];
const kRoot=valid[0][1].id,badLevels=negatives[0][1].id;
const natRec=apps(cn(get("psKernelSimpleRecName")(natName),[one]),[
 lam("n",nat,nat),seven,lam("n",nat,lam("ih",nat,bv(0n))),cn(get("psKernelNatZeroName"))]);
const input=arena,built=accepted(get("psKernelExprV2DecodeChecked")(input),"input");
let generated={arena:input,built,declarations};
for(const command of commands)generated=accepted(get("psKernelDagGeneratedAfterCommand")(
 command,session.environment,generated),"generated-metadata");
accepted(get("psKernelExprV2PagedValidate")(generated.arena),"generated-arena");
const state=get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(generated.arena),
 get("psKernelExprV2WhnfStateForDeclarations")(generated.arena,generated.declarations));
const decode=(owner,root)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(owner.whnf.arena),"decode"),root),"decoded-root");
for(const info of [unitInfo,eqInfo]){
 const owner=accepted(get("psKernelExprV2DeclarationRefFind")(generated.declarations)(info.base.name),"K-owner");
 must(exact(info.base.type,decode(state,owner.type)),"K-owner-exact-type");
 must(get("psKernelExprV2DeclarationRefMatches")(owner,CI.recInfo(info)),"K-owner-authority");
 for(const rule of array(info.rules)){
  const root=accepted(get("psKernelExprV2RecursorRuleOwner")(generated.declarations,info,rule),"K-rule");
  must(exact(rule.rhs,decode(state,root)),"K-owner-exact-rule");
 }
}
const scalar=get("psKernelKernelSessionChecker")(session,nil,safe).context;
const context=get("psKernelExprV2CheckContextEmpty")(scalar);
const oldEmpty=get("psKernelCheckerStateEmpty"),oldEq=get("psKernelIsDefEqWithFuel");
const dagEq=get("psKernelExprV2TryDefEqStateWithFuel");
const localValue=c=>n=>get("psKernelExprV2CheckLocalValue")(c,n);
const reducer=fuel=>get("psKernelExprV2TryReduceRecursorOwnedWithFuel")(fuel)(dagEq(64n))(localValue);

const run=extra=>get("psKernelV1RunDag")(empty,nil,safe,input,list([...commands,...extra]));
for(const [label,term] of valid){
 const old=accepted(get("psKernelV1Whnf")(session,nil,safe,term.term),label+"-V1");
 must(exact(old,seven.term),label+"-checked-value");
 const own=attempt(get("psKernelExprV2TryWhnfCheckStateWithFuel")(4096n,context,state,term.id),label);
 must(exact(decode(own.fst,own.snd),seven.term),label+"-full-owner-value");
}
const batch=accepted(run(valid.map(([,term])=>C.whnf(term.id))),"real-batch");
const answers=array(batch.replies).slice(commands.length);
must(answers.length===6,"real-batch-count");
for(const answer of answers)must(same(answer,Reply.normalized(answer.value))&&exact(answer.value,seven.term),"real-batch-value");
for(const [label,term] of negatives){
 const old=get("psKernelV1Whnf")(session,nil,safe,term.term),own=run([C.whnf(term.id)]);
 invalid(old,label+"-V1");invalid(own,label+"-public");
 must(same(old.error,own.error),label+"-exact-public-error");
}
const good={base:{name:name("KChecked"),levelParams:nil,type:nat.id},value:kRoot,hints,safety:safe};
const admitted=accepted(run([C.admit(D.definitionDecl(good)),C.check(kRoot),C.isDefEq(kRoot,seven.id)]),"checked-definition");
const replies=array(admitted.replies);
must(replies.length===commands.length+3&&same(replies.at(-1),Reply.equal(true))&&
 same(replies.at(-2),Reply.checked(replies.at(-2).value))&&
 same(replies.at(-3),Reply.admitted(replies.at(-3).receipt)),"admission-check-defeq");
invalid(run([C.admit(D.definitionDecl({...good,
 base:{name:name("KRejected"),levelParams:nil,type:s1.id}}))]),"bad-definition");
must(same(get("psKernelEnvironmentFind")(empty.environment,unitName),none),"original-session-atomic");
const directAdmission=(label,request,shouldAccept)=>{
 const declaration=accepted(get("psKernelDagDecodeDeclaration")(built,request),label+"-boundary-decode");
 const original=get("psKernelV1AdmitDeclaration")(session,declaration);
 const observed=accepted(get("psKernelDagTryAdmitSimpleWithFuel")(
  session.resources.fuel,get("psKernelKernelSessionEnvironment")(session),
  session.resources.maxRecDepth,session.resources.maxNatSize,
  generated.arena,generated.declarations,request,declaration),label+"-strictly-supported");
 if(shouldAccept){
  const old=accepted(original,label+"-V1"),environment=accepted(observed,label+"-direct");
  const n=declaration.value.base.name;
  const actual=accepted(get("psKernelEnvironmentFind")(environment,n),label+"-published");
  const expected=accepted(get("psKernelEnvironmentFind")(old.session.environment,n),label+"-V1-published");
  must(same(actual,CI.defnInfo(actual.value))&&same(expected,CI.defnInfo(expected.value))&&
   exact(actual.value.base.type,expected.value.base.type)&&exact(actual.value.value,expected.value.value)&&
   same(actual.value.base.levelParams,expected.value.base.levelParams)&&same(actual.value.safety,safe),
   label+"-published-definition");
 }else{
  invalid(original,label+"-V1-invalid");
  must(rejected(observed)&&observed.error===original.error.message,label+"-invalid-exact-message");
 }
};
directAdmission("KChecked",D.definitionDecl(good),true);
directAdmission("KRejected",D.definitionDecl({...good,
 base:{name:name("KRejected"),levelParams:nil,type:s1.id}}),false);
console.log("PSC1_V2_K_GENERATED_DIRECT_ADMISSION_PASS cases=2");
console.log("PSC1_V2_K_GENERATED_CHECKED_PASS valid=6 invalid=3 declarations=2 batch=6");

const compare=(label,old,actual)=>{
 const observed=accepted(actual,label+"-owned");
 if(rejected(old)){must(rejected(observed)&&observed.error===old.error,label+"-exact-error");return;}
 const left=accepted(old,label+"-reference"),right=accepted(observed,label+"-result");
 must(exact(left.fst,decode(right.fst,right.snd)),label+"-exact-value");
};
const compareReduction=(label,old,actual)=>{
 const observed=accepted(actual,label+"-owned");
 if(rejected(old)){must(rejected(observed)&&observed.error===old.error,label+"-exact-error");return;}
 const left=accepted(old,label+"-reference"),right=accepted(observed,label+"-result");
 if(same(left.fst,none)){must(same(right.snd,none),label+"-no-reduction");return;}
 must(exact(accepted(left.fst,label+"-old-some"),
  decode(right.fst,accepted(right.snd,label+"-new-some"))),label+"-exact-reduction");
};
let publicCount=0,coreCount=0,reducerCount=0,fixedCount=0;
for(const [label,term] of valid){
 for(const fuel of [0n,1n,2n,3n,8n,64n])for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
  const scalarC={...scalar,maxRecDepth,recDepth},c=get("psKernelExprV2CheckContextEmpty")(scalarC);
  const key=label+"-"+fuel+"-"+maxRecDepth+"-"+recDepth;
  compare(key+"-public",get("psKernelWhnfWithRecursorFuel")(fuel,oldEq(fuel),scalarC,oldEmpty,term.term),
   get("psKernelExprV2TryWhnfCheckStateWithFuel")(fuel,c,state,term.id));publicCount++;
  for(const cheapRec of [false,true])for(const cheapProj of [false,true]){
   compare(key+"-core-"+cheapRec+"-"+cheapProj,
    get("psKernelWhnfCoreWithRecursorFuel")(fuel,oldEq(fuel),scalarC,oldEmpty,term.term,cheapRec,cheapProj),
    get("psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel")(
     fuel,dagEq(fuel),localValue,c,state,term.id,cheapRec,cheapProj));coreCount++;
  }
 }
}
for(const [label,term] of [...valid,...negatives])
 for(const fuel of [0n,1n,2n,3n,8n,64n])for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]])
  for(const cheapRec of [false,true])for(const cheapProj of [false,true]){
   const scalarC={...scalar,maxRecDepth,recDepth},c=get("psKernelExprV2CheckContextEmpty")(scalarC);
   compareReduction(label+"-reducer-"+fuel+"-"+maxRecDepth+"-"+recDepth+"-"+cheapRec+"-"+cheapProj,
    get("psKernelReduceRecursorBoundedWithFuel")(fuel)(oldEq(64n))(scalarC)(oldEmpty)(term.term)(cheapRec)(cheapProj),
    reducer(fuel)(c)(state)(term.id)(cheapRec)(cheapProj));reducerCount++;
  }
must(publicCount===108&&coreCount===432&&reducerCount===648,"matrix-count");
console.log("PSC1_V2_K_GENERATED_MATRIX_PASS public=108 core=432 reducer=648");
for(const [label,term] of valid)for(const structural of [0n,1n,2n,8n])for(const owner of [0n,1n,2n,8n]){
 compare(label+"-fixed-"+structural+"-"+owner,
  get("psKernelWhnfWithFuel")(structural)(
   get("psKernelReduceRecursorBoundedWithFuel")(owner)(oldEq(64n)))(scalar)(oldEmpty)(term.term),
  get("psKernelExprV2TryWhnfOwnedWithReducerFuel")(structural)(
   reducer(owner))(localValue)(context)(state)(term.id));fixedCount++;
}
must(fixedCount===96,"fixed-owner-count");
console.log("PSC1_V2_K_GENERATED_FIXED_OWNER_PASS cases=96");

const modulus=BigInt(get("psKernelCacheHashModulus"));
const cacheMark=(rows,mark)=>{const a=array(rows);return a.length===1&&BigInt(a[0].hash)===modulus+mark;};
const arenaMark=(owner,mark)=>{
 const rows=array(get("psKernelExprV2WhnfCacheEntries")(owner.whnf.coreCache));
 if(rows.length!==1)return false;
 const entry=get("psKernelExprV2PagedRequire")(owner.whnf.arena,rows[0].result);
 return !rejected(entry)&&same(entry.value.node,get("PsKernelExprV2Node").lit(Literal.nat(9000n+mark)));
};
const marked=(owner,mark)=>owner.nextFresh===mark&&arenaMark(owner,mark)&&
 [owner.whnf.coreCache,owner.whnf.publicCache,owner.checkedInfer,owner.inferOnly,owner.unfold]
  .every(cache=>cacheMark(get("psKernelExprV2WhnfCacheEntries")(cache),mark))&&
 [owner.success,owner.failure].every(rows=>cacheMark(rows,mark));
const stamp=(key,mark,owner)=>{
 const built=accepted(get("psKernelExprV2PagedMkLit")(owner.whnf.arena,Literal.nat(9000n+mark)),"marker-arena");
 const cache={source:key,result:built.snd,hash:modulus+mark},pair={left:key,right:key,hash:modulus+mark};
 return {whnf:{arena:built.fst,coreCache:get("psKernelExprV2WhnfCacheFromList")(list([cache])),publicCache:get("psKernelExprV2WhnfCacheFromList")(list([cache])),declarations:owner.whnf.declarations},
  nextFresh:mark,checkedInfer:get("psKernelExprV2WhnfCacheFromList")(list([cache])),success:list([pair]),inferOnly:get("psKernelExprV2WhnfCacheFromList")(list([cache])),unfold:get("psKernelExprV2WhnfCacheFromList")(list([cache])),failure:list([pair])};
};
const probeStep=(key,seed,stage,failAt,decline,owner)=>{
 if(!marked(owner,seed+stage-1n))return error("K_CALLBACK_STATE_OR_ORDER");
 if(stage===failAt)return decline?none:error("K_CALLBACK_SENTINEL");
 return Option.some(Ex.ok(stamp(key,seed+stage,owner)));
};
const withRoot=(value,root)=>{
 if(same(value,none))return none;
 const result=accepted(value,"probe-some");
 return rejected(result)?Option.some(result):ok(accepted(result,"probe-ok"),root);
};
const runProbe=(owner,appType,candidateType,seed,failAt,decline,equal)=>{
 const infer=_c=>next=>root=>{
  if(next.nextFresh===seed)return root===major.id?
   withRoot(probeStep(major.id,seed,1n,failAt,decline,next),appType):error("K_INITIAL_MAJOR");
  return root===major.id?error("K_CANDIDATE_NOT_CONSTRUCTED"):
   withRoot(probeStep(major.id,seed,3n,failAt,decline,next),candidateType);
 };
 const whnf=_c=>next=>root=>root===appType?
  withRoot(probeStep(major.id,seed,2n,failAt,decline,next),appType):error("K_TYPE_WHNF_ORDER");
 const defeq=_c=>next=>left=>right=>{
  if(left!==appType||right!==candidateType)return error("K_DEFEQ_ARGUMENT_ORDER");
  return withRoot(probeStep(major.id,seed,4n,failAt,decline,next),equal);
 };
 return get("psKernelExprV2RecursorKForFamilyOwnedWith")(
  whnf,infer,defeq,context,stamp(major.id,seed,owner),eqInfo,eqName,major.id);
};
arena=state.whnf.arena;
const paramMVar=mv("A"),indexMVar=md(7n,mv("index")),universeMVar=L.mvar(name("u"));
const candidate=(level,a)=>E.app(E.app(E.const(eqCtor,list([level])),a.term),zero.term);
const probeCases=[
 ["true",eqType(one,nat,zero,zero),true,4n,candidate(one,nat)],
 ["false",eqType(one,nat,zero,zero),false,4n,null],
 ["parameter-mvar",eqType(one,paramMVar,zero,zero),true,4n,candidate(one,paramMVar)],
 ["universe-mvar",eqType(universeMVar,nat,zero,zero),true,4n,candidate(universeMVar,nat)],
 ["index-mvar",eqType(one,nat,zero,indexMVar),true,2n,null],
 ["wrong-family",nat,true,2n,null],
 ["short-params",apps(cn(eqName,[one]),[nat]),true,2n,null],
 ["nonconstant-family",s0,true,2n,null]
];
let owners=0,propagated=0,metadata=0;
for(const [label,type,equal,steps,expected] of probeCases){
 const candidateType=md(77n,type);
 const owner=get("psKernelExprV2CheckStateWithArena")(state,arena);
 const entry=accepted(get("psKernelExprV2PagedRequire")(arena,type.id),"probe-type-entry");
 must(entry.hasExprMVar===get("psKernelExprHasMVarForK")(type.term),label+"-validated-mvar");metadata++;
 const spine=accepted(get("psKernelExprV2TransformAppSpineOnCanonical")(arena,type.id),"probe-spine");
 const hasIndex=accepted(get("psKernelExprV2RecursorKIndicesHaveMVar")(
  arena,get("psKernelExprV2QuotDrop")(eqInfo.numParams,spine.snd)),"probe-index-mvar");
 const oldIndices=list(array(get("psKernelExprGetAppArgs")(type.term)).slice(Number(eqInfo.numParams)));
 must(hasIndex===get("psKernelExprListAnyMVar")(oldIndices),label+"-index-correspondence");metadata++;
 for(const seed of [2n,11n]){
  const result=attempt(runProbe(owner,type.id,candidateType.id,seed,0n,false,equal),label);
  must(marked(result.fst,seed+steps),label+"-complete-owner");
  must(!same(get("psKernelExprV2DeclarationRefFind")(result.fst.whnf.declarations)(eqInfo.base.name),none),
   label+"-private-owner-retained");
  if(expected===null)must(result.snd===major.id,label+"-original-major");
  else must(exact(decode(result.fst,result.snd),expected),label+"-candidate-levels-params");
  accepted(get("psKernelExprV2PagedValidate")(result.fst.whnf.arena),label+"-arena");owners++;
 }
}
const standard=eqType(one,nat,zero,zero),candidateType=md(88n,standard);
const probeOwner=get("psKernelExprV2CheckStateWithArena")(state,arena);
for(const seed of [2n,11n])for(const failAt of [1n,2n,3n,4n])for(const decline of [false,true]){
 const value=runProbe(probeOwner,standard.id,candidateType.id,seed,failAt,decline,true);
 if(same(value,none))must(decline,"None-is-unsupported");
 else{
  const result=accepted(value,"failed-callback-some");
  must(!decline&&rejected(result)&&result.error==="K_CALLBACK_SENTINEL","exact-callback-failure");
 }
 propagated++;
}
must(owners===16&&propagated===16&&metadata===16,"owner-counts");
console.log("PSC1_V2_K_GENERATED_OWNER_PASS carrier=16 propagated=16 metadata=16");

const errorIs=(value,message,label)=>{
 const result=accepted(value,label+"-some");
 must(rejected(result)&&result.error===message,label);
};
for(const root of [kRoot,badLevels])errorIs(reducer(1n)(context)(state)(root)(false)(false),
 "kernel inference budget exhausted","K-before-constructor-and-universe-rule");
const nonK=attempt(reducer(1n)(context)(state)(natRec.id)(false)(false),"non-K-fuel-one");
must(!same(nonK.snd,none),"non-K-constructor-shortcut");
const unowned=get("psKernelExprV2CheckStateWithWhnf")(state,
 get("psKernelExprV2WhnfStateForDeclarations")(state.whnf.arena,nil));
must(same(reducer(1n)(context)(unowned)(kRoot)(false)(false),none),"missing-K-owner-explicit-None");
errorIs(reducer(0n)(context)(state)(state.whnf.arena.size+1n)(false)(false),
 "kernel recursor budget exhausted","zero-recursor-before-invalid-root");
console.log("PSC1_V2_K_GENERATED_ORDER_PASS guards=5");
console.log("PSC1_V2_RECURSOR_K_GENERATED_PASS assertions="+assertions);
