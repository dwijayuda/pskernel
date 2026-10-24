import {pathToFileURL} from "node:url";
import path from "node:path";

// Private T05 constructor loop, before recursor generation or publication.
// Compare the complete frozen V1 constructor loop at the same raw fuel.
// Decode the complete original input before header analysis; metadata uses
// that boundary snapshot while checking remains DAG-native.
if(process.argv.length!==3)throw Error("PSC1_CONSTRUCTOR_LOOP_REQUIRES_GENERATED_KERNEL");
const kernelPath=path.resolve(process.argv[2]),k=await import(pathToFileURL(kernelPath).href);
const get=n=>{if(!(n in k))throw Error("PSC1_CONSTRUCTOR_LOOP_MISSING_EXPORT "+n);return k[n];};
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
  throw Error("PSC1_CONSTRUCTOR_LOOP_REJECTED "+label+": "+String(v?.error));
};
const attempted=(v,label)=>accepted(accepted(v,label+"/some"),label+"/ok");
const rejected=v=>v&&Object.hasOwn(v,"error");
let assertions=0,section="harness";
const counts={};
const must=(condition,label)=>{
  if(condition!==true)throw Error("PSC1_CONSTRUCTOR_LOOP_JS_FAIL "+section+"/"+label);
  assertions++;counts[section]=(counts[section]??0)+1;
};
must(!same(ok("same"),err("same"))&&!same(none,Option.some(none)),"constructor-tags");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),Safety=get("PsKernelDefinitionSafety"),Node=get("PsKernelExprV2Node");
const name=s=>N.str(unit(N.anonymous),s);
const bi=unit(B.default),implicit=unit(B.implicit),strict=unit(B.strictImplicit),instance=unit(B.instImplicit);
const zero=unit(L.zero),one=L.succ(zero),u=name("LoopU"),v=name("LoopV");
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

const target=name("LoopT"),T=cn(target),ctorNames=[name("LoopT.c0"),name("LoopT.c1")];
const TI=x=>app(T,x),ih=all("i",s1,s1),ph=all("A",s1,s1,implicit);
const pctor=all("X",s1,all("x",bv(0n),TI(bv(1n))),implicit);
const fv=n=>term("FVar",[n],E.fvar(n));
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
const shapeEqual=(a,b,d)=>same(a.ctor.name,b.ctor.name)&&exprExact(a.ctor.type,d(b.ctor.type))&&
  bindersEqual(a.fields,b.fields,d)&&
  seqEqual(a.recursiveFields,b.recursiveFields,(x,y)=>binderEqual(x.field,y.field,d)&&
    bindersEqual(x.args,y.arguments,d)&&seqEqual(x.indices,y.indices,(i,j)=>exprExact(i,d(j))))&&
  seqEqual(a.resultIndices,b.resultIndices,(i,j)=>exprExact(i,d(j)));
const makeReference=ctor=>({name:ctor.name,levelParams:nil,type:ctor.type,deltaValue:none,
  kind:unit(RefKind.constructorDecl)});

function prepare(row){
  const levels=nil,initial=get("psKernelMkCheckerSession")(env,levels,unit(Safety.safe),0n,maxNat);
  const checked=accepted(get("psKernelSessionCheck")(4096n,initial,row.header.expr),row.label+"/old-check");
  const sorted=accepted(get("psKernelSessionEnsureSort")(4096n,checked.snd,checked.fst),row.label+"/old-sort");
  const oldParams=accepted(get("psKernelOpenSimpleHeaderParams")(
    4096n,sorted.snd,row.header.expr,row.n),row.label+"/old-params");
  const oldIndices=accepted(get("psKernelOpenSimpleHeaderIndices")(
    4096n,oldParams.session,oldParams.result),row.label+"/old-indices");
  if(!Object.hasOwn(oldIndices.result,"level"))throw Error("PSC1_CONSTRUCTOR_LOOP_OLD_HEADER_NOT_SORT");
  const resultLevel=oldIndices.result.level,b=builder(),headerId=b.add(row.header);
  const dagCtors=row.ctors.map((type,i)=>({name:ctorNames[i],type:b.add(type)}));
  const sourceArena=b.arena,built=accepted(get("psKernelExprV2DecodeChecked")(sourceArena),"original-boundary");
  const header=attempted(get("psKernelExprV2OrdinaryAnalyzeHeaderWithFuel")(
    4096n,env,0n,maxNat,sourceArena,nil,levels,row.n,
    {name:target,type:headerId,ctors:list(dagCtors)},false),row.label+"/header");
  const numIndices=BigInt(array(oldIndices.binders).length);
  if(numIndices!==BigInt(array(header.indices.binders).length)||
      get("psKernelLevelEq")(resultLevel)(header.resultLevel)!==true)
    throw Error("PSC1_CONSTRUCTOR_LOOP_HEADER_DISAGREEMENT");
  const info={base:{name:target,levelParams:levels,type:row.header.expr},numParams:row.n,numIndices,
    all:list([target]),ctors:list(dagCtors.map(c=>c.name)),numNested:0n,isRec:false,isReflexive:false,isUnsafe:false};
  const work=get("psKernelEnvironmentAddUnchecked")(env,CI.inductInfo(info));
  const parent=get("psKernelExprV2OrdinaryConstructorState")(header);
  const parameterContext=get("psKernelExprV2OrdinaryConstructorContext")(header);
  const context={scalar:get("psKernelCheckerContextWithEnvironment")(parameterContext.scalar,work),locals:parameterContext.locals};
  const reference={name:target,levelParams:levels,type:headerId,deltaValue:none,kind:unit(RefKind.inductiveDecl)};
  const state={...parent,whnf:{...parent.whnf,declarations:List.cons(reference,parent.whnf.declarations)}};
  const oldCtors=row.ctors.map((type,i)=>({name:ctorNames[i],type:type.expr}));
  const declaration={levelParams:levels,name:target,type:row.header.expr,ctors:list(oldCtors),isUnsafe:false,numParams:row.n};
  if(!arenaPrefix(state.whnf.arena,sourceArena))throw Error("PSC1_CONSTRUCTOR_LOOP_BOUNDARY_PREFIX");
  return {row,oldHeader:oldParams.session,oldParams:oldParams.binders,oldCtors,declaration,
    work,context,state,dagCtors,params:header.parameters.binders,numIndices,resultLevel,levels,
    built,sourceArena,headerId};
}
function oldReference(fuel,f){
  return applyCurried(get("psKernelAddSimpleConstructorsWithFuel")(fuel),[
    f.declaration,unit(Safety.safe),f.resultLevel,f.levels,f.oldParams,f.numIndices,
    f.oldHeader,f.work,0n,list(f.oldCtors)]);
}
const actualLoop=(fuel,f)=>get("psKernelExprV2OrdinaryAddConstructorsWithFuel")(
  fuel,f.built,target,f.row.n,false,f.levels,f.params,f.numIndices,f.resultLevel,
  f.context,f.state,0n,list(f.dagCtors));
function resultEqual(old,actual,f){
  if(!actual||!Object.hasOwn(actual,"value"))return false;
  const result=actual.value;
  if(rejected(old))return same(old,result);
  if(rejected(result))return false;
  const left=accepted(old,"old-loop"),right=accepted(result,"dag-loop"),d=graphDecode(right.state.whnf.arena);
  let refs=f.state.whnf.declarations;
  for(const ctor of f.dagCtors)refs=List.cons(makeReference(ctor),refs);
  const expectedContext={scalar:get("psKernelCheckerContextWithEnvironment")(
    f.context.scalar,left.environment),locals:f.context.locals};
  return seqEqual(left.shapes,right.shapes,(a,b)=>shapeEqual(a,b,d))&&
    array(right.shapes).every((shape,i)=>shape.ctor.type===f.dagCtors[i].type)&&
    environmentEqual(left.environment,right.context.scalar.environment)&&
    contextEqual(right.context,expectedContext)&&semanticStateEqual(right.state,f.state)&&
    referencesEqual(right.state.whnf.declarations,refs)&&
    arenaPrefix(right.state.whnf.arena,f.state.whnf.arena);
}
const rows=[
  {label:"empty-list",header:s1,n:0n,ctors:[],shapes:[]},
  {label:"single-empty",header:s1,n:0n,ctors:[T],shapes:[[0,0,0]]},
  {label:"two-fields",header:s1,n:0n,ctors:[all("p",s0,T),all("q",s0,all("r",s0,T))],
    shapes:[[1,0,0],[2,0,0]]},
  {label:"two-parameterized",header:ph,n:1n,ctors:[pctor,pctor],shapes:[[1,0,0],[1,0,0]]},
  {label:"indexed-recursive",header:ih,n:0n,ctors:[TI(s0),all("t",TI(s0),TI(s0))],
    shapes:[[0,0,1],[1,1,1]]},
  {label:"late-free-variable",header:s1,n:0n,ctors:[T,fv(name("LoopFree"))],
    error:"declaration has free variables"},
  {label:"late-wrong-result",header:s1,n:0n,ctors:[T,s0],
    error:"simple inductive constructor must return the declared datatype with matching parameters and index arity"},
  {label:"late-previous-reference",header:s1,n:0n,
    ctors:[T,all("p",letE("z",T,cn(ctorNames[0]),s0),T)],
    error:"simple inductive admission does not yet support nested recursive occurrences"}
];
if(rows.length!==8||rows.filter(row=>!row.error).length!==5)
  throw Error("PSC1_CONSTRUCTOR_LOOP_FIXTURE_INVENTORY");
const fuels=[0n,1n,2n,3n,8n,4096n],fixtures=rows.map(prepare);
let positive=0,negative=0;
section="matrix";
for(let i=0;i<rows.length;i++){
  const row=rows[i],f=fixtures[i];
  for(const fuel of fuels)
    must(resultEqual(oldReference(fuel,f),actualLoop(fuel,f),f),row.label+"/raw-fuel="+fuel);
  const actual=actualLoop(4096n,f);
  if(row.error){
    must(same(actual,Option.some(err(row.error))),row.label+"/required-error");
    negative++;
  }else{
    const result=attempted(actual,row.label+"/required-direct"),shapes=array(result.shapes);
    must(shapes.length===row.shapes.length&&shapes.every((shape,j)=>
      array(shape.fields).length===row.shapes[j][0]&&
      array(shape.recursiveFields).length===row.shapes[j][1]&&
      array(shape.resultIndices).length===row.shapes[j][2])&&
      (row.label!=="two-parameterized"||same(array(shapes[0].fields)[0].internalName,
        array(shapes[1].fields)[0].internalName)),row.label+"/required-shapes");
    positive++;
  }
}
// Synthetic analysis callbacks isolate loop sequencing and owner restoration.
// They are not independent checking or admission evidence. Deep snapshots also
// detect accidental generated mutation of an input owner after a failed tail.
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
const base=prepare({label:"protocol",header:s1,n:0n,ctors:[T,T],shapes:[[0,0,0],[0,0,0]]});
const [c0,c1]=base.dagCtors,sortId=base.headerId;
const cache=(source,result,tag)=>list([{source,result,hash:tag}]);
const pairs=(left,right,tag)=>list([{left,right,hash:tag}]);
const stamp=(state,tag,source,result,references)=>({...state,nextFresh:tag,
  whnf:{...state.whnf,coreCache:cache(source,result,tag+1n),publicCache:cache(source,result,tag+2n),
    declarations:references},
  checkedInfer:cache(source,result,tag+3n),inferOnly:cache(source,result,tag+4n),
  unfold:cache(source,result,tag+5n),success:pairs(source,result,tag+6n),
  failure:pairs(source,result,tag+7n)});
const header={...base,state:stamp(base.state,37n,c0.type,sortId,base.state.whnf.declarations)};
const baseline=capture({context:header.context,state:header.state,built:header.built});
const intact=()=>same(header.context,baseline.context)&&same(header.state,baseline.state)&&
  same(header.built,baseline.built)&&same(findInfo(header.context.scalar.environment,c0.name),none)&&
  same(findInfo(header.context.scalar.environment,c1.name),none);
const budget="simple inductive constructor admission budget exhausted";
const forbidden=_fuel=>_context=>_state=>_target=>_levels=>_params=>_numIndices=>_resultLevel=>_ctor=>{
  throw Error("PSC1_CONSTRUCTOR_LOOP_UNEXPECTED_CALLBACK");
};
const raw=(fuel,analyze,ctors=header.dagCtors,built=header.built)=>
  applyCurried(get("psKernelExprV2OrdinaryAddConstructorsWorker")(fuel),[
    analyze,built,target,0n,false,nil,header.params,header.numIndices,header.resultLevel,
    header.context,header.state,0n,list(ctors)]);
const checkCall=(fuel,context,state,nextTarget,levels,params,numIndices,resultLevel,ctor,
    expectedFuel,expectedContext,expectedState,expectedCtor)=>{
  if(fuel!==expectedFuel||!contextEqual(context,expectedContext)||!stateEqual(state,expectedState)||
      !same(nextTarget,target)||!same(levels,nil)||!same(params,header.params)||
      numIndices!==header.numIndices||!same(resultLevel,header.resultLevel)||
      !same(ctor.name,expectedCtor.name)||ctor.type!==expectedCtor.type)
    throw Error("PSC1_CONSTRUCTOR_LOOP_CALLBACK_OWNER");
};
function independentInstall(context,state,ctor,index,arena,numFields=0n){
  const type=accepted(get("psKernelExprV2DecodedRequire")(header.built,ctor.type),"protocol-original-type");
  const info={base:{name:ctor.name,levelParams:context.scalar.levelParams,type},
    induct:target,cidx:index,numParams:0n,numFields,isUnsafe:false};
  const work=get("psKernelEnvironmentAddUnchecked")(context.scalar.environment,CI.ctorInfo(info));
  return {
    context:{scalar:get("psKernelCheckerContextWithEnvironment")(context.scalar,work),locals:context.locals},
    state:{...state,whnf:{...state.whnf,arena,declarations:List.cons(makeReference(ctor),state.whnf.declarations)}}
  };
}
const appended0=accepted(get("psKernelExprV2PagedMkSort")(header.state.whnf.arena,one),"protocol-append-first");
const child0=stamp(get("psKernelExprV2CheckStateWithArena")(header.state,appended0.fst),
  101n,c0.type,appended0.snd,nil);
const installed0=independentInstall(header.context,header.state,c0,0n,appended0.fst,1n);
const appended1=accepted(get("psKernelExprV2PagedMkSort")(installed0.state.whnf.arena,one),"protocol-append-second");
const child1=stamp(get("psKernelExprV2CheckStateWithArena")(installed0.state,appended1.fst),
  201n,c1.type,appended1.snd,nil);
const installed1=independentInstall(installed0.context,installed0.state,c1,1n,appended1.fst,2n);
const childContext=context=>({scalar:{...context.scalar,eagerReduce:true,recDepth:29n},
  locals:list([{name:name("LoopTemporary"),userName:name("temporary"),type:sortId,binderInfo:bi,value:none}])});
const protocolBinder=i=>({internalName:name("LoopProtocolField"+i),userName:name("field"+i),type:sortId,binderInfo:bi});
const protocolFields0=list([protocolBinder(0)]),protocolFields1=list([protocolBinder(1),protocolBinder(2)]);
const shape=(ctor,ordinal)=>({ctor,fields:ordinal===0?protocolFields0:protocolFields1,recursiveFields:nil,resultIndices:nil});
const analyzed=(context,state,ctor,ordinal=0)=>({context:childContext(context),state,shape:shape(ctor,ordinal)});
let trace=[];
const callback=(firstFuel,secondMode="ok",firstCtor=c0,secondCtor=c1)=>
  fuel=>context=>state=>nextTarget=>levels=>params=>numIndices=>resultLevel=>ctor=>{
    const ordinal=trace.length;
    if(ordinal===0){
      checkCall(fuel,context,state,nextTarget,levels,params,numIndices,resultLevel,ctor,
        firstFuel,header.context,header.state,firstCtor);
      trace.push({fuel,name:ctor.name,root:ctor.type});
      return Option.some(ok(analyzed(context,child0,ctor)));
    }
    if(ordinal!==1)throw Error("PSC1_CONSTRUCTOR_LOOP_CALLBACK_COUNT");
    checkCall(fuel,context,state,nextTarget,levels,params,numIndices,resultLevel,ctor,
      firstFuel-1n,installed0.context,installed0.state,secondCtor);
    trace.push({fuel,name:ctor.name,root:ctor.type});
    if(secondMode==="decline")return none;
    if(secondMode==="error")return Option.some(err("second-analysis-sentinel"));
    return Option.some(ok(analyzed(context,child1,ctor,1)));
  };
const traceIs=fuels=>same(trace.map(item=>item.fuel),fuels);

must(same(raw(0n,forbidden,[]),Option.some(err(budget)))&&intact(),"zero-before-callbacks");
const emptyResult=attempted(raw(1n,forbidden,[]),"positive-empty");
must(contextEqual(emptyResult.context,header.context)&&stateEqual(emptyResult.state,header.state)&&
  same(emptyResult.shapes,nil)&&intact(),"positive-empty-identity");
trace=[];
must(same(raw(1n,callback(0n),[c0]),Option.some(err(budget)))&&traceIs([0n])&&intact(),
  "single-fuel-one-tail-exhaustion");
const decline=_fuel=>_context=>_state=>_target=>_levels=>_params=>_numIndices=>_resultLevel=>_ctor=>none;
const fail=_fuel=>_context=>_state=>_target=>_levels=>_params=>_numIndices=>_resultLevel=>_ctor=>
  Option.some(err("first-analysis-sentinel"));
must(same(raw(3n,decline),none)&&intact(),"first-decline");
must(same(raw(3n,fail),Option.some(err("first-analysis-sentinel")))&&intact(),"first-error");
const missing=999999n,missingResult=get("psKernelExprV2DecodedRequire")(header.built,missing);
if(!rejected(missingResult))throw Error("PSC1_CONSTRUCTOR_LOOP_MISSING_ROOT_FIXTURE");
const broken0={...c0,type:missing},broken1={...c1,type:missing};
trace=[];
must(same(raw(3n,callback(2n,"ok",broken0),[broken0]),Option.some(missingResult))&&
  traceIs([2n])&&intact(),"first-snapshot-error");
trace=[];
must(same(raw(3n,callback(2n,"decline")),none)&&traceIs([2n,1n])&&intact(),
  "second-decline-after-prefix");
trace=[];
must(same(raw(3n,callback(2n,"error")),Option.some(err("second-analysis-sentinel")))&&
  traceIs([2n,1n])&&intact(),"second-error-after-prefix");
trace=[];
must(same(raw(3n,callback(2n,"ok",c0,broken1),[c0,broken1]),Option.some(missingResult))&&
  traceIs([2n,1n])&&intact(),"second-snapshot-error-after-prefix");
trace=[];
const completed=attempted(raw(3n,callback(2n)),"protocol-complete");
const completedShapes=array(completed.shapes);
must(traceIs([2n,1n])&&completedShapes.length===2&&
  completedShapes.every((s,i)=>same(s.ctor.name,header.dagCtors[i].name)&&
    s.ctor.type===header.dagCtors[i].type&&same(s.fields,i===0?protocolFields0:protocolFields1)&&
    same(s.recursiveFields,nil)&&same(s.resultIndices,nil))&&
  environmentEqual(completed.context.scalar.environment,installed1.context.scalar.environment)&&
  intact(),"success-metadata-shape-order");
must(contextEqual(completed.context,installed1.context)&&stateEqual(completed.state,installed1.state)&&
  completed.state.nextFresh===37n&&completed.state.whnf.arena.size===header.state.whnf.arena.size+2n&&
  arenaPrefix(completed.state.whnf.arena,header.state.whnf.arena)&&
  !semanticStateEqual(child0,header.state)&&!semanticStateEqual(child1,header.state)&&
  intact(),"success-header-owner-reset");
const decoy={name:name("LoopDecoy"),type:appended0.snd};
const oneField={internalName:name("LoopProtocolField"),userName:name("field"),type:sortId,binderInfo:bi};
const fake={...analyzed(header.context,child0,c0),shape:{ctor:decoy,fields:list([oneField]),recursiveFields:nil,resultIndices:nil}};
const original=accepted(get("psKernelExprV2OrdinaryInstallConstructor")(
  header.built,target,0n,false,0n,header.context,header.state,c0,fake),"install-original");
const expectedOriginal=independentInstall(header.context,header.state,c0,0n,child0.whnf.arena,1n);
must(contextEqual(original.fst,expectedOriginal.context)&&stateEqual(original.snd,expectedOriginal.state)&&
  same(findInfo(original.fst.scalar.environment,decoy.name),none)&&intact(),"install-original-root-pairing");

const expectedCounts={harness:1,matrix:56,protocol:12};
if(!same(counts,expectedCounts)||assertions!==69||positive!==5||negative!==3)
  throw Error("PSC1_CONSTRUCTOR_LOOP_SECTION_INVENTORY");
console.log(JSON.stringify({schema:"psc1-ordinary-constructor-loop-v1",kernel:kernelPath,assertions,
  sectionAssertions:counts,rows:8,fuelValues:6,positive,negative,
  fullAdmission:false,publicRoutingChanged:false}));
console.log("PSC1_ORDINARY_CONSTRUCTOR_LOOP_JS: PASS assertions=69 fullAdmission=false");
