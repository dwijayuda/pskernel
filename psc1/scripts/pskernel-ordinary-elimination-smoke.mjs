import {pathToFileURL} from "node:url";
import path from "node:path";

// Private elimination policy, before recursor generation or publication.
// Each policy row first passes the frozen V1 constructor loop. Raw telescope
// and callback controls test helper behavior without asserting admission.
// Structural membership preserves syntactic equality, including its deliberate
// distinction between a whole result argument and a beta-equivalent argument.
if(process.argv.length!==3)throw Error("PSC1_ELIMINATION_REQUIRES_GENERATED_KERNEL");
const kernelPath=path.resolve(process.argv[2]),k=await import(pathToFileURL(kernelPath).href);
const get=n=>{if(!(n in k))throw Error("PSC1_ELIMINATION_MISSING_EXPORT "+n);return k[n];};
const unit=x=>typeof x==="function"?x():x;
const List=get("List"),Option=get("Option"),Except=get("Except");
const nil=unit(List.nil),none=unit(Option.none),ok=Except.ok,err=Except.error;
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const a=[];while(xs&&Object.hasOwn(xs,"head")){a.push(xs.head);xs=xs.tail;}return a;};
const same=(a,b)=>{
  if(a===b)return true;
  if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
  const ak=Reflect.ownKeys(a),bk=Reflect.ownKeys(b);
  return ak.length===bk.length&&ak.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
const accepted=(v,label)=>{
  if(v&&Object.hasOwn(v,"value"))return v.value;
  throw Error("PSC1_ELIMINATION_REJECTED "+label+": "+String(v?.error));
};
const attempted=(v,label)=>accepted(accepted(v,label+"/some"),label+"/ok");
const rejected=v=>v&&Object.hasOwn(v,"error");
let assertions=0,section="harness";
const counts={};
const must=(condition,label)=>{
  if(condition!==true)throw Error("PSC1_ELIMINATION_JS_FAIL "+section+"/"+label);
  assertions++;counts[section]=(counts[section]??0)+1;
};
must(!same(ok("same"),err("same"))&&!same(none,Option.some(none)),"constructor-tags");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),Safety=get("PsKernelDefinitionSafety"),Node=get("PsKernelExprV2Node");
const name=s=>N.str(unit(N.anonymous),s);
const bi=unit(B.default),implicit=unit(B.implicit),strict=unit(B.strictImplicit),instance=unit(B.instImplicit);
const zero=unit(L.zero),one=L.succ(zero),u=name("ElimU"),v=name("ElimV");
const term=(kind,args,expr)=>({kind,args,expr});
const sort=l=>term("Sort",[l],E.sort(l));
const bv=i=>term("BVar",[i],E.bvar(i));
const cn=(n,levels=[])=>term("Const",[n,list(levels)],E.const(n,list(levels)));
const app=(f,a)=>term("App",[f,a],E.app(f.expr,a.expr));
const all=(n,t,b,info=bi)=>term("Forall",[name(n),t,b,info],E.forallE(name(n),t.expr,b.expr,info));
const lam=(n,t,b,info=bi)=>term("Lam",[name(n),t,b,info],E.lam(name(n),t.expr,b.expr,info));
const letE=(n,t,a,b,nondep=false)=>term("Let",[name(n),t,a,b,nondep],E.letE(name(n),t.expr,a.expr,b.expr,nondep));
const md=(tag,b)=>term("MData",[tag,b],E.mdata(tag,b.expr));
const s0=sort(zero),s1=sort(one),s2=sort(L.succ(one));
const empty=unit(get("psKernelExprV2PagedEmpty"));
function builder(initial=empty){
  let arena=initial;
  const memo=new Map();
  const add=t=>{
    if(memo.has(t))return memo.get(t);
    const args=t.args.map(x=>x&&typeof x==="object"&&Object.hasOwn(x,"expr")&&Object.hasOwn(x,"kind")?add(x):x);
    const result=accepted(get("psKernelExprV2PagedMk"+t.kind)(arena,...args),"build-"+t.kind);
    arena=result.fst;memo.set(t,result.snd);return result.snd;
  };
  return {add,get arena(){return arena;}};
}
const decode=(arena,root)=>accepted(get("psKernelExprV2DecodedRequire")(
  accepted(get("psKernelExprV2DecodeChecked")(arena),"decode-arena"),root),"decode-root");
const exprExact=(a,b)=>get("psKernelExprEqual")(a)(b)===true;
const env=unit(get("psKernelEnvironmentEmpty")),maxNat=unit(get("psKernelLeanNatMaxSizeDefault"));

const CI=get("PsKernelConstantInfo"),RefKind=get("PsKernelExprV2DeclarationRefKind");
const applyCurried=(fn,args)=>args.reduce((next,arg)=>next(arg),fn);
const seqEqual=(left,right,equal)=>{
  const a=array(left),b=array(right);
  return a.length===b.length&&a.every((value,i)=>equal(value,b[i]));
};
const graphDecode=arena=>{
  const built=accepted(get("psKernelExprV2DecodeChecked")(arena),"result-canonical");
  return root=>accepted(get("psKernelExprV2DecodedRequire")(built,root),"result-root");
};
const binderEqual=(a,b,d)=>same(a.internalName,b.internalName)&&same(a.userName,b.userName)&&
  same(a.binderInfo,b.binderInfo)&&exprExact(a.type,d(b.type));
const bindersEqual=(a,b,d)=>seqEqual(a,b,(x,y)=>binderEqual(x,y,d));
const ctorMetadataEqual=(a,b)=>same(a.base.name,b.base.name)&&
  same(a.base.levelParams,b.base.levelParams)&&exprExact(a.base.type,b.base.type)&&
  same(a.induct,b.induct)&&a.cidx===b.cidx&&a.numParams===b.numParams&&
  a.numFields===b.numFields&&a.isUnsafe===b.isUnsafe;
const inductMetadataEqual=(a,b)=>same(a.base.name,b.base.name)&&
  same(a.base.levelParams,b.base.levelParams)&&exprExact(a.base.type,b.base.type)&&
  a.numParams===b.numParams&&a.numIndices===b.numIndices&&same(a.all,b.all)&&
  same(a.ctors,b.ctors)&&a.numNested===b.numNested&&a.isRec===b.isRec&&
  a.isReflexive===b.isReflexive&&a.isUnsafe===b.isUnsafe;
const tagged=(info,ctor)=>info&&Object.hasOwn(info,"value")&&same(info,ctor(info.value));
const constantEqual=(a,b)=>{
  if(tagged(a,CI.ctorInfo)&&tagged(b,CI.ctorInfo))return ctorMetadataEqual(a.value,b.value);
  if(tagged(a,CI.inductInfo)&&tagged(b,CI.inductInfo))return inductMetadataEqual(a.value,b.value);
  return false;
};
const findInfo=(environment,n)=>get("psKernelEnvironmentFind")(environment,n);
function environmentEqual(a,b){
  if(a.quotInitialized!==b.quotInitialized||!same(a.runtime,b.runtime)||
      !seqEqual(a.constants,b.constants,constantEqual))return false;
  return array(a.constants).every(info=>{
    const n=get("psKernelConstantInfoName")(info),left=findInfo(a,n),right=findInfo(b,n);
    return left&&right&&Object.hasOwn(left,"value")&&Object.hasOwn(right,"value")&&
      constantEqual(left.value,right.value);
  });
}
const referencesEqual=(a,b)=>seqEqual(a,b,(x,y)=>same(x.name,y.name)&&
  same(x.levelParams,y.levelParams)&&x.type===y.type&&same(x.deltaValue,y.deltaValue)&&same(x.kind,y.kind));
const cacheEqual=(a,b)=>seqEqual(a,b,(x,y)=>x.source===y.source&&x.result===y.result&&x.hash===y.hash);
const pairsEqual=(a,b)=>seqEqual(a,b,(x,y)=>x.left===y.left&&x.right===y.right&&x.hash===y.hash);
const semanticStateEqual=(a,b)=>a.nextFresh===b.nextFresh&&
  cacheEqual(a.whnf.coreCache,b.whnf.coreCache)&&cacheEqual(a.whnf.publicCache,b.whnf.publicCache)&&
  cacheEqual(a.checkedInfer,b.checkedInfer)&&cacheEqual(a.inferOnly,b.inferOnly)&&
  cacheEqual(a.unfold,b.unfold)&&pairsEqual(a.success,b.success)&&pairsEqual(a.failure,b.failure);
function arenaPrefix(after,before){
  if(after.size<before.size||after.pageLimit!==before.pageLimit)return false;
  for(let id=0n;id<before.size;id++)
    if(!same(get("psKernelExprV2PagedFind")(after,id),get("psKernelExprV2PagedFind")(before,id)))return false;
  return true;
}
const stateEqual=(a,b)=>semanticStateEqual(a,b)&&referencesEqual(a.whnf.declarations,b.whnf.declarations)&&
  a.whnf.arena.size===b.whnf.arena.size&&arenaPrefix(a.whnf.arena,b.whnf.arena);
const scalarEqual=(a,b)=>same(a.localContext,b.localContext)&&same(a.levelParams,b.levelParams)&&
  same(a.safety,b.safety)&&a.eagerReduce===b.eagerReduce&&same(a.nativeEvaluator,b.nativeEvaluator)&&
  a.maxRecDepth===b.maxRecDepth&&a.maxNatSize===b.maxNatSize&&a.recDepth===b.recDepth&&
  environmentEqual(a.environment,b.environment);
const contextEqual=(a,b)=>scalarEqual(a.scalar,b.scalar)&&same(a.locals,b.locals);

const target=name("ElimT"),T=cn(target),ctorNames=[name("ElimT.c0"),name("ElimT.c1")];
const TI=x=>app(T,x),indexedHeader=all("A",s1,s0);
const indexedCtor=all("A",s1,TI(bv(0n)));
const parameterHeader=all("P",s0,s0,implicit);
const parameterCtor=all("P",s0,all("p",bv(0n),TI(bv(1n))),implicit);
function prepare(row){
  const levels=nil,initial=get("psKernelMkCheckerSession")(env,levels,unit(Safety.safe),0n,maxNat);
  const checked=accepted(get("psKernelSessionCheck")(4096n,initial,row.header.expr),row.label+"/old-check");
  const sorted=accepted(get("psKernelSessionEnsureSort")(4096n,checked.snd,checked.fst),row.label+"/old-sort");
  const oldParams=accepted(get("psKernelOpenSimpleHeaderParams")(
    4096n,sorted.snd,row.header.expr,row.n),row.label+"/old-params");
  const oldIndices=accepted(get("psKernelOpenSimpleHeaderIndices")(
    4096n,oldParams.session,oldParams.result),row.label+"/old-indices");
  if(!Object.hasOwn(oldIndices.result,"level"))throw Error("PSC1_ELIMINATION_OLD_HEADER_NOT_SORT");
  const resultLevel=oldIndices.result.level,b=builder(),headerId=b.add(row.header);
  const dagCtors=row.ctors.map((type,i)=>({name:ctorNames[i],type:b.add(type)}));
  const sourceArena=b.arena;
  accepted(get("psKernelExprV2DecodeChecked")(sourceArena),"original-boundary");
  const header=attempted(get("psKernelExprV2OrdinaryAnalyzeHeaderWithFuel")(
    4096n,env,0n,maxNat,sourceArena,nil,levels,row.n,
    {name:target,type:headerId,ctors:nil},false),row.label+"/header");
  const numIndices=BigInt(array(oldIndices.binders).length);
  if(numIndices!==BigInt(array(header.indices.binders).length)||
      get("psKernelLevelEq")(resultLevel)(header.resultLevel)!==true)
    throw Error("PSC1_ELIMINATION_HEADER_DISAGREEMENT");
  const info={base:{name:target,levelParams:levels,type:row.header.expr},numParams:row.n,numIndices,
    all:list([target]),ctors:list(dagCtors.map(c=>c.name)),numNested:0n,isRec:false,isReflexive:false,isUnsafe:false};
  const work0=get("psKernelEnvironmentAddUnchecked")(env,CI.inductInfo(info));
  const oldCtors=row.ctors.map((type,i)=>({name:ctorNames[i],type:type.expr}));
  const declaration={levelParams:levels,name:target,type:row.header.expr,ctors:list(oldCtors),
    isUnsafe:false,numParams:row.n};
  const admitted=accepted(applyCurried(get("psKernelAddSimpleConstructorsWithFuel")(4097n),[
    declaration,unit(Safety.safe),resultLevel,levels,oldParams.binders,numIndices,
    oldParams.session,work0,0n,list(oldCtors)]),row.label+"/frozen-constructor-admission");
  const finalInfo={...info,isRec:get("psKernelSimpleHasRecursiveFields")(admitted.shapes),
    isReflexive:get("psKernelSimpleHasReflexiveFields")(admitted.shapes)};
  const work1=get("psKernelEnvironmentReplaceUnchecked")(admitted.environment,CI.inductInfo(finalInfo));
  const oldSession=get("psKernelSessionWithEnvironment")(oldParams.session,work1);
  const parent=get("psKernelExprV2OrdinaryConstructorState")(header);
  const parameterContext=get("psKernelExprV2OrdinaryConstructorContext")(header);
  const context={scalar:get("psKernelCheckerContextWithEnvironment")(parameterContext.scalar,work1),
    locals:parameterContext.locals};
  let declarations=List.cons({name:target,levelParams:levels,type:headerId,
    deltaValue:none,kind:unit(RefKind.inductiveDecl)},parent.whnf.declarations);
  for(const ctor of dagCtors)declarations=List.cons({name:ctor.name,levelParams:levels,type:ctor.type,
    deltaValue:none,kind:unit(RefKind.constructorDecl)},declarations);
  const state={...parent,whnf:{...parent.whnf,declarations}};
  if(!arenaPrefix(state.whnf.arena,sourceArena))throw Error("PSC1_ELIMINATION_BOUNDARY_PREFIX");
  return {row,oldSession,oldParams:oldParams.binders,oldCtors,context,state,
    params:header.parameters.binders,resultLevel,dagCtors,headerId,sourceArena,admitted};
}
const rawWorker=(fuel,check,whnf,context,state,type,revNonProp)=>
  applyCurried(get("psKernelExprV2OrdinaryCtorAllowsLargeElimWorker")(fuel),
    [check,whnf,context,state,type,revNonProp]);
const actualCheck=fuel=>context=>state=>root=>
  get("psKernelExprV2TryCheckStateWithFuel")(fuel,context,state,root);
const actualWhnf=fuel=>context=>state=>root=>
  get("psKernelExprV2TryWhnfCheckStateWithFuel")(fuel,context,state,root);
const fuels=[0n,1n,2n,3n,8n,4096n];
const rows=[
  {label:"nonprop-fast",header:s1,n:0n,ctors:[all("P",s0,T)],expected:false},
  {label:"prop-empty",header:s0,n:0n,ctors:[],expected:false},
  {label:"prop-multiple",header:s0,n:0n,ctors:[T,T],expected:true},
  {label:"prop-empty-ctor",header:s0,n:0n,ctors:[T],expected:false},
  {label:"proof-field",header:s0,n:0n,ctors:[all("p",T,T)],expected:false},
  {label:"proposition-field",header:s0,n:0n,ctors:[all("P",s0,T)],expected:true},
  {label:"indexed-exact",header:indexedHeader,n:0n,ctors:[indexedCtor],expected:false},
  {label:"indexed-beta",header:indexedHeader,n:0n,
    ctors:[all("A",s1,TI(app(lam("Z",s1,bv(0n)),bv(0n))))],expected:true},
  {label:"parameter-proof",header:parameterHeader,n:1n,ctors:[parameterCtor],expected:false}
];
const fixtures=rows.map(prepare);
section="policy";
for(const f of fixtures){
  for(const fuel of fuels){
    const old=get("psKernelSimpleElimOnlyAtZero")(fuel,f.oldSession,f.oldParams,f.resultLevel,list(f.oldCtors));
    const actual=get("psKernelExprV2OrdinaryElimOnlyAtZeroWithFuel")(
      fuel,f.context,f.state,f.params,f.resultLevel,list(f.dagCtors));
    must(same(actual,Option.some(old)),f.row.label+"/fuel="+fuel);
  }
  const old=get("psKernelSimpleElimOnlyAtZero")(4096n,f.oldSession,f.oldParams,f.resultLevel,list(f.oldCtors));
  const actual=get("psKernelExprV2OrdinaryElimOnlyAtZeroWithFuel")(
    4096n,f.context,f.state,f.params,f.resultLevel,list(f.dagCtors));
  must(same(old,ok(f.row.expected))&&same(actual,Option.some(ok(f.row.expected))),f.row.label+"/required-outcome");
}
section="raw";
const rawRows=[
  {label:"plain",type:indexedCtor},
  {label:"metadata",type:md(1n,indexedCtor)},
  {label:"let",type:letE("unused",s1,s0,indexedCtor,true)},
  {label:"beta",type:app(lam("unused",s1,indexedCtor),s0)}
];
const indexed=fixtures[6];
for(const row of rawRows){
  const b=builder(indexed.state.whnf.arena),type=b.add(row.type);
  const state=get("psKernelExprV2CheckStateWithArena")(indexed.state,b.arena);
  for(const fuel of fuels){
    const old=applyCurried(get("psKernelSimpleCtorAllowsLargeElimWithFuel")(fuel),
      [indexed.oldSession,row.type.expr,nil]);
    const actual=rawWorker(fuel,actualCheck,actualWhnf,indexed.context,state,type,nil);
    must(same(actual,Option.some(old)),row.label+"/fuel="+fuel);
  }
  const old=applyCurried(get("psKernelSimpleCtorAllowsLargeElimWithFuel")(4096n),
    [indexed.oldSession,row.type.expr,nil]);
  const actual=rawWorker(4096n,actualCheck,actualWhnf,indexed.context,state,type,nil);
  must(same(old,ok(true))&&same(actual,Option.some(ok(true))),row.label+"/required-outcome");
}

section="member";
const member=get("psKernelExprV2OrdinaryEliminationMember");
const allMembers=get("psKernelExprV2OrdinaryEliminationAllMembers");
const oldMember=get("psKernelSimpleExprMember"),oldAll=get("psKernelSimpleAllExprsMember");
function memberPair(label,left,right,expected,distinct=false){
  const first=builder(),a=first.add(left),second=builder(first.arena),b=second.add(right);
  must(oldMember(left.expr,list([right.expr]))===expected&&
    same(member(second.arena,a,list([b])),ok(expected))&&(!distinct||a!==b),label);
}
const memberBuilder=builder(),memberA=memberBuilder.add(s0),memberB=memberBuilder.add(s1);
const memberArena=memberBuilder.arena,badMember=memberArena.size+100n;
must(oldMember(s0.expr,list([s0.expr]))===true&&
  same(member(memberArena,memberA,list([memberA])),ok(true)),"shared-ID");
memberPair("duplicate-ID",s0,s0,true,true);
memberPair("renamed-forall-info",all("x",s0,bv(0n)),all("y",s0,bv(0n),implicit),true);
memberPair("renamed-lam-info",lam("x",s0,bv(0n)),lam("y",s0,bv(0n),instance),true);
memberPair("renamed-let",letE("x",s1,s0,bv(0n)),letE("y",s1,s0,bv(0n)),true);
memberPair("let-nondep",letE("x",s1,s0,bv(0n),false),letE("x",s1,s0,bv(0n),true),false);
memberPair("mdata-tags",md(2n,s0),md(3n,s0),false);
memberPair("beta-syntax",app(lam("x",s1,bv(0n)),s0),s0,false);
must(oldMember(s0.expr,nil)===false&&oldAll(nil,list([s0.expr]))===true&&
  same(member(memberArena,badMember,nil),ok(false))&&
  same(allMembers(memberArena,nil,list([badMember])),ok(true)),"nil-boundaries");
must(oldAll(list([s0.expr,s1.expr,s0.expr]),list([s1.expr,s0.expr]))===true&&
  same(allMembers(memberArena,list([memberA,memberB,memberA]),list([memberB,memberA])),ok(true)),"repeated-all");
must(oldAll(list([s0.expr,s1.expr]),list([s0.expr]))===false&&
  same(allMembers(memberArena,list([memberA,memberB]),list([memberA])),ok(false)),"missing-all");
must(same(member(memberArena,memberA,list([memberA,badMember])),ok(true))&&
  same(member(memberArena,badMember,list([memberA])),err("PSKERNEL_V2_PAIR_CHECK_INVALID_LEFT"))&&
  same(member(memberArena,memberA,list([badMember])),err("PSKERNEL_V2_PAIR_CHECK_INVALID_RIGHT")),
  "invalid-short-circuit");

// Protocol-only owners deliberately contain distinct cache/reference markers.
// Only injected callbacks see these states; no real checking judgment or public
// admission uses a marker. Capture inputs independently to detect mutation.
section="protocol";
function capture(value,seen=new Map()){
  if(value===null||typeof value!=="object")return value;
  if(seen.has(value))return seen.get(value);
  const copy=Array.isArray(value)?[]:Object.create(Object.getPrototypeOf(value));
  seen.set(value,copy);
  for(const key of Reflect.ownKeys(value)){
    const descriptor=Object.getOwnPropertyDescriptor(value,key);
    if(Object.hasOwn(descriptor,"value"))descriptor.value=capture(descriptor.value,seen);
    Object.defineProperty(copy,key,descriptor);
  }
  return copy;
}
const cache=(source,result,tag)=>list([{source,result,hash:tag}]);
const pairs=(left,right,tag)=>list([{left,right,hash:tag}]);
const stamp=(state,fresh,source,result,declarations)=>({...state,nextFresh:fresh,
  whnf:{...state.whnf,coreCache:cache(source,result,fresh+1n),
    publicCache:cache(source,result,fresh+2n),declarations},
  checkedInfer:cache(source,result,fresh+3n),success:pairs(source,result,fresh+4n),
  inferOnly:cache(source,result,fresh+5n),unfold:cache(source,result,fresh+6n),
  failure:pairs(source,result,fresh+7n)});
const protocolBuilder=builder(indexed.state.whnf.arena),sortId=protocolBuilder.add(s1);
const targetId=protocolBuilder.add(T);
const annotationName=unit(get("psKernelTypeAnnotationOutParamName"));
const originalDomain=app(cn(annotationName),s1),originalBody=TI(bv(0n));
const domainId=protocolBuilder.add(originalDomain),bodyId=protocolBuilder.add(originalBody);
const user=name("field");
const builtForall=accepted(get("psKernelExprV2PagedMkForall")(
  protocolBuilder.arena,user,domainId,bodyId,implicit),"protocol-forall");
const forallId=builtForall.snd,context=indexed.context;
const parent=stamp(get("psKernelExprV2CheckStateWithArena")(indexed.state,builtForall.fst),
  37n,sortId,targetId,indexed.state.whnf.declarations);
const baseline=capture({context,parent}),intact=()=>same(context,baseline.context)&&same(parent,baseline.parent);
const bad=parent.whnf.arena.size+100n,badCtor={name:name("invalid-root"),type:bad};
const forbidden=_fuel=>_context=>_state=>_root=>{throw Error("PSC1_ELIMINATION_UNEXPECTED_CALLBACK");};
const defeqForbidden=_fuel=>_context=>_state=>_left=>_right=>{throw Error("PSC1_ELIMINATION_UNEXPECTED_DEFEQ");};
const decline=_fuel=>_context=>_state=>_root=>none;
const fail=message=>_fuel=>_context=>_state=>_root=>Option.some(err(message));
const policy=(level,ctors)=>get("psKernelExprV2OrdinaryElimOnlyAtZeroWith")(
  forbidden,forbidden,defeqForbidden,0n,context,parent,nil,level,list(ctors));
must(same(policy(one,[badCtor]),Option.some(ok(false)))&&
  same(policy(zero,[]),Option.some(ok(false)))&&
  same(policy(zero,[badCtor,badCtor]),Option.some(ok(true)))&&intact(),"policy-shortcuts");
must(same(rawWorker(0n,forbidden,forbidden,context,parent,bad,list([bad])),
  Option.some(err("simple inductive elimination budget exhausted")))&&intact(),"zero-before-callback");
must(same(rawWorker(8n,forbidden,decline,context,parent,bad,nil),none)&&intact(),"whnf-decline");
must(same(rawWorker(8n,forbidden,fail("WHNF_SENTINEL"),context,parent,bad,nil),
  Option.some(err("WHNF_SENTINEL")))&&intact(),"whnf-error-before-invalid-root");
const stepWith=(check,whnf,rev=nil)=>get("psKernelExprV2OrdinaryEliminationStepWith")(
  check,whnf,7n,context,parent,user,domainId,bodyId,implicit,rev);
must(same(stepWith(decline,forbidden),none)&&intact(),"check-decline-before-sort");
must(same(stepWith(fail("CHECK_SENTINEL"),forbidden),Option.some(err("CHECK_SENTINEL")))&&
  intact(),"check-error-before-sort");
const checkSort=_fuel=>_context=>state=>_root=>Option.some(ok({fst:state,snd:sortId}));
must(same(stepWith(checkSort,decline),none)&&intact(),"sort-decline");
must(same(stepWith(checkSort,fail("SORT_SENTINEL")),Option.some(err("SORT_SENTINEL")))&&
  intact(),"sort-error");
const nonSort=_fuel=>_context=>state=>_root=>Option.some(ok({fst:state,snd:targetId}));
must(same(stepWith(checkSort,nonSort),Option.some(err("expected sort")))&&intact(),"sort-nonsort");
const parameter=fixtures[8],parameterBaseline=capture(parameter.state);
const withParameter=defeq=>get("psKernelExprV2OrdinaryCtorAllowsLargeElimWith")(
  forbidden,forbidden,defeq,8n,parameter.context,parameter.state,parameter.params,parameter.dagCtors[0].type);
const defeqNone=_fuel=>_context=>_state=>_left=>_right=>none;
const defeqError=_fuel=>_context=>_state=>_left=>_right=>Option.some(err("DEFEQ_SENTINEL"));
const defeqFalse=_fuel=>_context=>state=>_left=>_right=>Option.some(ok({fst:state,snd:false}));
must(same(withParameter(defeqNone),none)&&
  same(withParameter(defeqError),Option.some(err("DEFEQ_SENTINEL")))&&
  same(withParameter(defeqFalse),Option.some(err(
    "simple inductive constructor parameter does not match the datatype parameter")))&&
  same(parameter.state,parameterBaseline)&&intact(),"parameter-failures");
const checkedAppend=accepted(get("psKernelExprV2PagedMkSort")(parent.whnf.arena,one),"check-append");
const checkedType=checkedAppend.snd;
const checkedRef={name:name("protocol-check"),levelParams:nil,type:checkedType,
  deltaValue:none,kind:unit(RefKind.constructorDecl)};
const checked=stamp(get("psKernelExprV2CheckStateWithArena")(parent,checkedAppend.fst),
  101n,domainId,checkedType,list([checkedRef]));
const sortedAppend=accepted(get("psKernelExprV2PagedMkSort")(checked.whnf.arena,one),"sort-append");
const propAppend=accepted(get("psKernelExprV2PagedMkSort")(sortedAppend.fst,zero),"prop-append");
const sortedType=sortedAppend.snd,propType=propAppend.snd;
const sortedRef={name:name("protocol-sort"),levelParams:nil,type:sortedType,
  deltaValue:none,kind:unit(RefKind.constructorDecl)};
const sorted=stamp(get("psKernelExprV2CheckStateWithArena")(checked,propAppend.fst),
  201n,checkedType,sortedType,list([sortedRef,checkedRef]));
const markersBaseline=capture({checked,sorted});
const markersIntact=()=>same(checked,markersBaseline.checked)&&same(sorted,markersBaseline.sorted);
let trace=[];
const checkStep=fuel=>ctx=>owner=>root=>{
  if(fuel!==7n||!contextEqual(ctx,context)||!stateEqual(owner,parent)||root!==domainId)
    throw Error("PSC1_ELIMINATION_STEP_CHECK_OWNER");
  trace.push("check:7");return Option.some(ok({fst:checked,snd:checkedType}));
};
const sortStep=fuel=>ctx=>owner=>root=>{
  if(fuel!==7n||!contextEqual(ctx,context)||!stateEqual(owner,checked)||root!==checkedType)
    throw Error("PSC1_ELIMINATION_STEP_SORT_OWNER");
  trace.push("sort:7");return Option.some(ok({fst:sorted,snd:sortedType}));
};
const step=attempted(stepWith(checkStep,sortStep,list([sortId])),"step-full-owner");
const propStep=accepted(get("psKernelExprV2OrdinaryEliminationAfterSort")(
  context,{fst:sorted,snd:zero},user,domainId,bodyId,implicit,list([sortId])),"prop-step");
const domainEntry=accepted(get("psKernelExprV2PagedRequire")(parent.whnf.arena,domainId),"annotated-domain");
if(!same(domainEntry.node,Node.app(domainEntry.node.fn,domainEntry.node.arg)))
  throw Error("PSC1_ELIMINATION_PROTOCOL_DOMAIN_NOT_APP");
const localDomain=domainEntry.node.arg,fresh=N.num(user,201n);
const expectedContext=get("psKernelExprV2CheckContextWithLocal")(context,fresh,user,localDomain,implicit);
const expectedSemantic=get("psKernelExprV2CheckStateFreshName")(sorted,user).snd;
const expectedBody=E.app(T.expr,E.fvar(fresh)),decoded=graphDecode(step.state.whnf.arena);
const decodedProp=graphDecode(propStep.state.whnf.arena),nonProp=array(step.revNonProp);
must(same(trace,["check:7","sort:7"])&&
  contextEqual(step.context,expectedContext)&&contextEqual(propStep.context,expectedContext)&&
  semanticStateEqual(step.state,expectedSemantic)&&semanticStateEqual(propStep.state,expectedSemantic)&&
  referencesEqual(step.state.whnf.declarations,sorted.whnf.declarations)&&
  referencesEqual(propStep.state.whnf.declarations,sorted.whnf.declarations)&&
  arenaPrefix(step.state.whnf.arena,sorted.whnf.arena)&&
  arenaPrefix(propStep.state.whnf.arena,sorted.whnf.arena)&&
  step.state.whnf.arena.size>sorted.whnf.arena.size&&
  exprExact(decoded(localDomain),s1.expr)&&exprExact(decoded(step.body),expectedBody)&&
  exprExact(decodedProp(propStep.body),expectedBody)&&nonProp.length===2&&
  nonProp[1]===sortId&&nonProp[0]!==sortId&&exprExact(decoded(nonProp[0]),E.fvar(fresh))&&
  same(propStep.revNonProp,list([sortId]))&&parent.nextFresh===37n&&
  checked.nextFresh===101n&&sorted.nextFresh===201n&&step.state.nextFresh===202n&&
  propStep.state.nextFresh===202n&&intact()&&markersIntact(),"step-full-owner");
const outerRef={name:name("protocol-outer"),levelParams:nil,type:forallId,
  deltaValue:none,kind:unit(RefKind.constructorDecl)};
const outer=stamp(parent,61n,forallId,domainId,list([outerRef]));
const checkWorker=fuel=>ctx=>owner=>root=>{
  if(fuel!==7n||!contextEqual(ctx,context)||!stateEqual(owner,outer)||root!==domainId)
    throw Error("PSC1_ELIMINATION_WORKER_CHECK_OWNER");
  trace.push("check:7");return Option.some(ok({fst:checked,snd:checkedType}));
};
const whnfWorker=(proofField,wholeArgument)=>fuel=>ctx=>owner=>root=>{
  if(fuel===7n&&contextEqual(ctx,context)&&stateEqual(owner,parent)&&root===forallId){
    trace.push("outer:7");return Option.some(ok({fst:outer,snd:forallId}));
  }
  if(fuel===7n&&contextEqual(ctx,context)&&stateEqual(owner,checked)&&root===checkedType){
    trace.push("sort:7");return Option.some(ok({fst:sorted,snd:proofField?propType:sortedType}));
  }
  if(fuel===6n&&contextEqual(ctx,expectedContext)&&stateEqual(owner,step.state)&&root===step.body){
    trace.push("terminal:6");return Option.some(ok({fst:owner,snd:wholeArgument?root:targetId}));
  }
  throw Error("PSC1_ELIMINATION_WORKER_WHNF_OWNER");
};
const runWorker=(proofField,wholeArgument,expected)=>{
  trace=[];
  const actual=rawWorker(8n,checkWorker,whnfWorker(proofField,wholeArgument),context,parent,forallId,nil);
  return same(actual,Option.some(ok(expected)))&&
    same(trace,["outer:7","check:7","sort:7","terminal:6"])&&intact()&&markersIntact();
};
must(runWorker(false,true,true)&&runWorker(false,false,false)&&runWorker(true,false,true),
  "worker-full-owner");
const expectedCounts={harness:1,policy:63,raw:28,member:12,protocol:12};
if(!same(counts,expectedCounts)||assertions!==116||rows.length!==9||rawRows.length!==4||fuels.length!==6)
  throw Error("PSC1_ELIMINATION_SECTION_INVENTORY");
console.log(JSON.stringify({schema:"psc1-ordinary-elimination-v1",kernel:kernelPath,assertions,
  sectionAssertions:counts,policyRows:9,rawRows:4,fuelValues:6,
  fullAdmission:false,publicRoutingChanged:false}));
console.log("PSC1_ORDINARY_ELIMINATION_JS: PASS assertions=116 fullAdmission=false");
