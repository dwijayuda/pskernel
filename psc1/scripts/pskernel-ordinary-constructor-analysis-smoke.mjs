import {pathToFileURL} from "node:url";
import path from "node:path";

// Private T05 single-constructor analysis, before recursor generation or publication.
// Compare the actual frozen V1 constructor loop on a singleton declaration.
// Checked header fixtures provide provisional target metadata; the constructor
// enters as the original closed type, with no pre-opened parameter or field.
if(process.argv.length!==3)throw Error("PSC1_CONSTRUCTOR_ANALYSIS_REQUIRES_GENERATED_KERNEL");
const kernelPath=path.resolve(process.argv[2]),k=await import(pathToFileURL(kernelPath).href);
const get=n=>{if(!(n in k))throw Error("PSC1_CONSTRUCTOR_ANALYSIS_MISSING_EXPORT "+n);return k[n];};
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
  throw Error("PSC1_CONSTRUCTOR_ANALYSIS_REJECTED "+label+": "+String(v?.error));
};
const attempted=(v,label)=>accepted(accepted(v,label+"/some"),label+"/ok");
const rejected=v=>v&&Object.hasOwn(v,"error");
let assertions=0,section="harness";
const counts={};
const must=(condition,label)=>{
  if(condition!==true)throw Error("PSC1_CONSTRUCTOR_ANALYSIS_JS_FAIL "+section+"/"+label);
  assertions++;counts[section]=(counts[section]??0)+1;
};
must(!same(ok("same"),err("same"))&&!same(none,Option.some(none)),"constructor-tags");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),Safety=get("PsKernelDefinitionSafety"),Node=get("PsKernelExprV2Node");
const name=s=>N.str(unit(N.anonymous),s);
const bi=unit(B.default),implicit=unit(B.implicit),strict=unit(B.strictImplicit),instance=unit(B.instImplicit);
const zero=unit(L.zero),one=L.succ(zero),u=name("CtorAnalysisU"),v=name("CtorAnalysisV");
const term=(kind,args,expr)=>({kind,args,expr});
const sort=l=>term("Sort",[l],E.sort(l));
const bv=i=>term("BVar",[i],E.bvar(i));
const cn=(n,levels=[])=>term("Const",[n,list(levels)],E.const(n,list(levels)));
const app=(f,a)=>term("App",[f,a],E.app(f.expr,a.expr));
const all=(n,t,b,info=bi)=>term("Forall",[name(n),t,b,info],E.forallE(name(n),t.expr,b.expr,info));
const lam=(n,t,b)=>term("Lam",[name(n),t,b,bi],E.lam(name(n),t.expr,b.expr,bi));
const letE=(n,t,a,b)=>term("Let",[name(n),t,a,b,false],E.letE(name(n),t.expr,a.expr,b.expr,false));
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

const target=name("CtorAnalysisT"),T=cn(target),ctorName=name("CtorAnalysisT.mk");
const TI=x=>app(T,x);
const ih=all("i",s1,s1),ph=all("A",s1,s1,implicit);
const fn=all("a",s0,T);
const fv=n=>term("FVar",[n],E.fvar(n));
const CI=get("PsKernelConstantInfo"),RefKind=get("PsKernelExprV2DeclarationRefKind");
const applyCurried=(fn,args)=>args.reduce((next,arg)=>next(arg),fn);

function prepare(row){
  const levels=nil;
  const initial=get("psKernelMkCheckerSession")(env,levels,unit(Safety.safe),0n,maxNat);
  const checked=accepted(get("psKernelSessionCheck")(4096n,initial,row.header.expr),row.label+"/old-check");
  const sorted=accepted(get("psKernelSessionEnsureSort")(4096n,checked.snd,checked.fst),row.label+"/old-sort");
  const oldParams=accepted(get("psKernelOpenSimpleHeaderParams")(4096n,sorted.snd,row.header.expr,row.n),row.label+"/old-params");
  const oldIndices=accepted(get("psKernelOpenSimpleHeaderIndices")(4096n,oldParams.session,oldParams.result),row.label+"/old-indices");
  if(!Object.hasOwn(oldIndices.result,"level"))throw Error("PSC1_CONSTRUCTOR_ANALYSIS_OLD_HEADER_NOT_SORT");
  const resultLevel=oldIndices.result.level;
  const b=builder(),headerId=b.add(row.header);
  const header=attempted(get("psKernelExprV2OrdinaryAnalyzeHeaderWithFuel")(
    4096n,env,0n,maxNat,b.arena,nil,levels,row.n,{name:target,type:headerId,ctors:nil},false),row.label+"/header");
  const numIndices=BigInt(array(oldIndices.binders).length);
  if(numIndices!==BigInt(array(header.indices.binders).length)||
      get("psKernelLevelEq")(resultLevel)(header.resultLevel)!==true)
    throw Error("PSC1_CONSTRUCTOR_ANALYSIS_HEADER_DISAGREEMENT");
  const info={base:{name:target,levelParams:levels,type:row.header.expr},numParams:row.n,numIndices,
    all:list([target]),ctors:list([ctorName]),numNested:0n,isRec:false,isReflexive:false,isUnsafe:false};
  const work=get("psKernelEnvironmentAddUnchecked")(env,CI.inductInfo(info));
  const parameterState=get("psKernelExprV2OrdinaryConstructorState")(header);
  const parameterContext=get("psKernelExprV2OrdinaryConstructorContext")(header);
  const context={scalar:get("psKernelCheckerContextWithEnvironment")(parameterContext.scalar,work),locals:parameterContext.locals};
  const cb=builder(parameterState.whnf.arena),root=cb.add(row.ctor);
  const reference={name:target,levelParams:levels,type:headerId,deltaValue:none,kind:unit(RefKind.inductiveDecl)};
  const state={...parameterState,whnf:{...parameterState.whnf,arena:cb.arena,
    declarations:List.cons(reference,parameterState.whnf.declarations)}};
  const oldCtor={name:ctorName,type:row.ctor.expr};
  const declaration={levelParams:levels,name:target,type:row.header.expr,ctors:list([oldCtor]),isUnsafe:false,numParams:row.n};
  return {oldHeader:oldParams.session,oldParams:oldParams.binders,oldCtor,declaration,work,context,state,
    ctor:{name:ctorName,type:root},params:header.parameters.binders,numIndices,resultLevel,levels};
}
const graphDecode=arena=>{
  const graph=accepted(get("psKernelExprV2DecodeChecked")(arena),"result-canonical");
  return root=>accepted(get("psKernelExprV2DecodedRequire")(graph,root),"result-root");
};
const binderEqual=(a,b,d)=>same(a.internalName,b.internalName)&&same(a.userName,b.userName)&&
  same(a.binderInfo,b.binderInfo)&&exprExact(a.type,d(b.type));
const seqEqual=(left,right,equal)=>{
  const a=array(left),b=array(right);
  return a.length===b.length&&a.every((value,i)=>equal(value,b[i]));
};
const bindersEqual=(a,b,d)=>seqEqual(a,b,(x,y)=>binderEqual(x,y,d));
const localsEqual=(old,context,d)=>seqEqual(old.context.localContext.decls,context.locals,(a,b)=>
  same(get("psKernelLocalDeclName")(a),b.name)&&same(get("psKernelLocalDeclUserName")(a),b.userName)&&
  same(get("psKernelLocalDeclBinderInfo")(a),b.binderInfo)&&exprExact(get("psKernelLocalDeclType")(a),d(b.type))&&
  same(get("psKernelLocalDeclValue")(a),none)&&same(b.value,none));
function arenaPrefix(after,before){
  if(after.size<before.size||after.pageLimit!==before.pageLimit)return false;
  for(let id=0n;id<before.size;id++)
    if(!same(get("psKernelExprV2PagedFind")(after,id),get("psKernelExprV2PagedFind")(before,id)))return false;
  return true;
}
function oldReference(fuel,f){
  return applyCurried(get("psKernelAddSimpleConstructorsWithFuel")(fuel+1n),[
    f.declaration,unit(Safety.safe),f.resultLevel,f.levels,f.oldParams,f.numIndices,
    f.oldHeader,f.work,0n,list([f.oldCtor])]);
}
function oldSuccessfulOwner(fuel,f){
  const owner=get("psKernelSessionWithEnvironment")(f.oldHeader,f.work);
  const parameters=accepted(get("psKernelOpenSimpleConstructorParams")(
    fuel,owner,f.oldParams,f.oldCtor.type),"old-successful-parameters");
  return accepted(get("psKernelOpenSimpleConstructorFields")(
    fuel,parameters.session,target,f.levels,f.oldParams,f.numIndices,f.resultLevel,parameters.result),
    "old-successful-fields").session;
}
function analyze(fuel,f){
  return get("psKernelExprV2OrdinaryAnalyzeConstructorWithFuel")(
    fuel,f.context,f.state,target,f.levels,f.params,f.numIndices,f.resultLevel,f.ctor);
}
function resultEqual(old,actual,fuel,f){
  if(!actual||!Object.hasOwn(actual,"value"))return false;
  const got=actual.value;
  if(rejected(old))return same(old,got);
  if(rejected(got))return false;
  const oldShapes=array(accepted(old,"old-reference").shapes);
  if(oldShapes.length!==1)return false;
  const left=oldShapes[0],right=accepted(got,"new-analysis"),shape=right.shape,d=graphDecode(right.state.whnf.arena);
  const owner=oldSuccessfulOwner(fuel,f);
  return same(left.ctor.name,shape.ctor.name)&&shape.ctor.type===f.ctor.type&&
    exprExact(left.ctor.type,d(shape.ctor.type))&&bindersEqual(left.fields,shape.fields,d)&&
    seqEqual(left.recursiveFields,shape.recursiveFields,(a,b)=>
      binderEqual(a.field,b.field,d)&&bindersEqual(a.args,b.arguments,d)&&
      seqEqual(a.indices,b.indices,(x,y)=>exprExact(x,d(y))))&&
    seqEqual(left.resultIndices,shape.resultIndices,(x,y)=>exprExact(x,d(y)))&&
    owner.state.nextFresh===right.state.nextFresh&&localsEqual(owner,right.context,d)&&
    same(right.context.scalar,f.context.scalar)&&same(right.state.whnf.declarations,f.state.whnf.declarations)&&
    arenaPrefix(right.state.whnf.arena,f.state.whnf.arena);
}
const rows=[
  {label:"empty",header:s1,n:0n,ctor:T,shape:[0,0,0]},
  {label:"prop-field",header:s1,n:0n,ctor:all("p",s0,T),shape:[1,0,0]},
  {label:"direct-recursive",header:s1,n:0n,ctor:all("t",T,T),shape:[1,1,0]},
  {label:"function-following",header:s1,n:0n,ctor:all("f",fn,all("q",s0,T)),shape:[2,1,0]},
  {label:"parameterized",header:ph,n:1n,ctor:all("X",s1,all("x",bv(0n),TI(bv(1n))),implicit),shape:[1,0,0]},
  {label:"indexed",header:ih,n:0n,ctor:all("t",TI(s0),TI(s0)),shape:[1,1,1]},
  {label:"free-variable",header:s1,n:0n,ctor:fv(name("CtorAnalysisFree")),
    error:"declaration has free variables"},
  {label:"undefined-universe",header:s1,n:0n,ctor:sort(L.param(name("CtorAnalysisUndef"))),
    error:"invalid reference to undefined universe level parameter"},
  {label:"ill-typed-domain",header:s1,n:0n,ctor:all("x",app(s0,s0),T),
    error:"expected function type"},
  {label:"wrong-result",header:s1,n:0n,ctor:s0,
    error:"simple inductive constructor must return the declared datatype with matching parameters and index arity"},
  {label:"negative-function",header:s1,n:0n,ctor:all("f",all("x",T,T),T),
    error:"recursive function argument contains a negative recursive occurrence"},
  {label:"recursive-result-index",header:ih,n:0n,ctor:TI(TI(s0)),
    error:"simple inductive constructor return index contains a recursive occurrence"}
];
if(rows.length!==12||rows.filter(row=>!row.error).length!==6)
  throw Error("PSC1_CONSTRUCTOR_ANALYSIS_FIXTURE_INVENTORY");
const fuels=[0n,1n,2n,3n,8n,4096n];
const fixtures=rows.map(prepare);
let positive=0,negative=0;
section="matrix";
for(let index=0;index<rows.length;index++){
  const row=rows[index],f=fixtures[index];
  for(const fuel of fuels)
    must(resultEqual(oldReference(fuel,f),analyze(fuel,f),fuel,f),row.label+"/fuel="+fuel);
  const actual=analyze(4096n,f);
  if(row.error){
    must(same(actual,Option.some(err(row.error))),row.label+"/required-error");
    negative++;
  }else{
    const result=attempted(actual,row.label+"/required-direct"),shape=result.shape;
    must(array(shape.fields).length===row.shape[0]&&
      array(shape.recursiveFields).length===row.shape[1]&&
      array(shape.resultIndices).length===row.shape[2],row.label+"/required-direct-shape");
    positive++;
  }
}
// Dependency-callback probes exercise phase ownership only. Their sentinel
// caches and references are deliberately synthetic and are never presented as
// successful independent type checking or admission.
section="protocol";
const forbidden=()=>{throw Error("PSC1_CONSTRUCTOR_ANALYSIS_UNEXPECTED_CALLBACK");};
const decline=_fuel=>_context=>_state=>_root=>none;
const fail=message=>_fuel=>_context=>_state=>_root=>Option.some(err(message));
const withCallbacks=(f,check,whnf,defeq=forbidden)=>
  get("psKernelExprV2OrdinaryAnalyzeConstructorWith")(check,whnf,defeq,7n,
    f.context,f.state,target,f.levels,f.params,f.numIndices,f.resultLevel,f.ctor);
must(same(withCallbacks(fixtures[6],forbidden,forbidden),
  Option.some(err("declaration has free variables"))),"static-precedes-callbacks");
const pb=builder(fixtures[0].state.whnf.arena),sortId=pb.add(s1);
const base={...fixtures[0],state:get("psKernelExprV2CheckStateWithArena")(fixtures[0].state,pb.arena)};
must(same(withCallbacks(base,decline,forbidden),none),"closed-check-decline");
must(same(withCallbacks(base,fail("closed-check-sentinel"),forbidden),
  Option.some(err("closed-check-sentinel"))),"closed-check-error");
const checkedIdentity=_fuel=>_context=>state=>_root=>Option.some(ok({fst:state,snd:sortId}));
must(same(withCallbacks(base,checkedIdentity,decline),none),"sort-decline");
must(same(withCallbacks(base,checkedIdentity,fail("closed-sort-sentinel")),
  Option.some(err("closed-sort-sentinel"))),"sort-error");
const nonsort=_fuel=>_context=>state=>_root=>Option.some(ok({fst:state,snd:base.ctor.type}));
must(same(withCallbacks(base,checkedIdentity,nonsort),
  Option.some(err("expected sort"))),"nonsort-before-opening");

const header={...base,state:{...base.state,nextFresh:37n}};
const expectedClosedContext=get("psKernelMkCheckerSession")(
  header.context.scalar.environment,header.context.scalar.levelParams,header.context.scalar.safety,
  header.context.scalar.maxRecDepth,header.context.scalar.maxNatSize).context;
const cache=tag=>list([{source:header.ctor.type,result:sortId,hash:tag}]);
const pairs=tag=>list([{left:header.ctor.type,right:sortId,hash:tag}]);
const stamp=(state,tag)=>({...state,nextFresh:tag,
  whnf:{...state.whnf,coreCache:cache(tag),publicCache:cache(tag+1n),
    declarations:List.cons({name:name("CtorAnalysisClosed"+tag),levelParams:nil,type:sortId,
      deltaValue:none,kind:unit(RefKind.inductiveDecl)},state.whnf.declarations)},
  checkedInfer:cache(tag+2n),inferOnly:cache(tag+3n),unfold:cache(tag+4n),
  success:pairs(tag+5n),failure:pairs(tag+6n)});
const parentStamped=stamp(header.state,37n);
header.state={...parentStamped,whnf:{...parentStamped.whnf,
  declarations:header.state.whnf.declarations}};
const trace=[];
let checkedState,checkedRoot,sortedState;
const checkOwned=fuel=>context=>state=>root=>{
  trace.push("check");
  if(fuel!==7n||root!==header.ctor.type||!same(context.locals,nil)||
      !same(context.scalar,expectedClosedContext)||state.nextFresh!==0n||
      !same(state.whnf.arena,header.state.whnf.arena)||
      !same(state.whnf.declarations,header.state.whnf.declarations)||
      ![state.whnf.coreCache,state.whnf.publicCache,state.checkedInfer,
        state.inferOnly,state.unfold,state.success,state.failure].every(value=>same(value,nil)))
    throw Error("PSC1_CONSTRUCTOR_ANALYSIS_CLOSED_OWNER_NOT_FRESH");
  const built=accepted(get("psKernelExprV2PagedMkSort")(state.whnf.arena,one),"check-append");
  checkedState=stamp(get("psKernelExprV2CheckStateWithArena")(state,built.fst),101n);
  checkedRoot=built.snd;
  return Option.some(ok({fst:checkedState,snd:checkedRoot}));
};
const whnfOwned=fuel=>context=>state=>root=>{
  trace.push("sort");
  if(fuel!==7n||root!==checkedRoot||!same(state,checkedState)||
      !same(context.locals,nil)||!same(context.scalar,expectedClosedContext))
    throw Error("PSC1_CONSTRUCTOR_ANALYSIS_SORT_OWNER_LOST");
  const built=accepted(get("psKernelExprV2PagedMkSort")(state.whnf.arena,one),"sort-append");
  sortedState=stamp(get("psKernelExprV2CheckStateWithArena")(state,built.fst),201n);
  return Option.some(ok({fst:sortedState,snd:built.snd}));
};
const owned=attempted(withCallbacks(header,checkOwned,whnfOwned),"owner-fork");
const expectedState=get("psKernelExprV2CheckStateWithArena")(header.state,sortedState.whnf.arena);
must(same(owned.context,header.context)&&same(owned.state,expectedState)&&
  same(owned.shape.ctor.name,header.ctor.name)&&owned.shape.ctor.type===header.ctor.type&&
  same(owned.shape.fields,nil)&&same(owned.shape.recursiveFields,nil)&&same(owned.shape.resultIndices,nil),
  "closed-owner-stamps-do-not-leak");
must(same(trace,["check","sort"])&&owned.state.nextFresh===37n&&
  owned.state.whnf.arena.size===header.state.whnf.arena.size+2n&&
  arenaPrefix(owned.state.whnf.arena,header.state.whnf.arena)&&
  Object.hasOwn(get("psKernelExprV2PagedFind")(owned.state.whnf.arena,checkedRoot),"value"),
  "closed-arena-appends-survive-exact-callback-order");

const expectedCounts={harness:1,matrix:84,protocol:8};
if(!same(counts,expectedCounts)||assertions!==93||positive!==6||negative!==6)
  throw Error("PSC1_CONSTRUCTOR_ANALYSIS_SECTION_INVENTORY");
const report={schema:"psc1-ordinary-constructor-analysis-v1",kernel:kernelPath,assertions,
  sectionAssertions:counts,rows:12,fuelValues:6,positive,negative,
  fullAdmission:false,publicRoutingChanged:false};
console.log(JSON.stringify(report));
console.log("PSC1_ORDINARY_CONSTRUCTOR_ANALYSIS_JS: PASS assertions=93 fullAdmission=false");
