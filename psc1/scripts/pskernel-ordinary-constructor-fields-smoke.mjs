import {pathToFileURL} from "node:url";
import path from "node:path";

// Private T05 constructor fields and recursive-argument analysis.
// The frozen V1 constructor worker and actual owned DAG callbacks are compared.
// Header-derived provisional metadata is internal test setup, not admission.
// No public fallback is called and no generated recursor is published.
if(process.argv.length!==3)throw Error("PSC1_CONSTRUCTOR_FIELDS_REQUIRES_GENERATED_KERNEL");
const kernelPath=path.resolve(process.argv[2]),k=await import(pathToFileURL(kernelPath).href);
const get=n=>{if(!(n in k))throw Error("PSC1_CONSTRUCTOR_FIELDS_MISSING_EXPORT "+n);return k[n];};
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
  throw Error("PSC1_CONSTRUCTOR_FIELDS_REJECTED "+label+": "+String(v?.error));
};
const attempted=(v,label)=>accepted(accepted(v,label+"/some"),label+"/ok");
const rejected=v=>v&&Object.hasOwn(v,"error");
let assertions=0,section="harness";
const counts={};
const must=(condition,label)=>{
  if(condition!==true)throw Error("PSC1_CONSTRUCTOR_FIELDS_JS_FAIL "+section+"/"+label);
  assertions++;counts[section]=(counts[section]??0)+1;
};
must(!same(ok("same"),err("same"))&&!same(none,Option.some(none)),"constructor-tags");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),Safety=get("PsKernelDefinitionSafety"),Node=get("PsKernelExprV2Node");
const name=s=>N.str(unit(N.anonymous),s);
const bi=unit(B.default),implicit=unit(B.implicit),strict=unit(B.strictImplicit),instance=unit(B.instImplicit);
const zero=unit(L.zero),one=L.succ(zero),u=name("CtorFieldsU"),v=name("CtorFieldsV");
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

const target=name("CtorFieldsT"),T=cn(target);
const TI=x=>app(T,x),TI2=(x,y)=>app(app(T,x),y);
const ih1=all("i",s1,s1),ih2=all("i",s1,all("j",s1,s1));
const ph=all("A",s1,s1,implicit),pctor=all("X",s1,all("t",app(T,bv(0n)),app(T,bv(1n))),implicit);
const fn1=all("a",s0,T),fn2=all("a",s0,all("b",s0,T));
const fieldsRows=[
  {label:"empty",header:s1,n:0n,ctor:T,fields:0,recursive:0},
  {label:"prop-value",header:s1,n:0n,ctor:all("p",s0,T),fields:1,recursive:0},
  {label:"two-fields",header:s1,n:0n,ctor:all("p",s0,all("q",s0,T)),fields:2,recursive:0},
  {label:"direct-recursive",header:s1,n:0n,ctor:all("t",T,T),fields:1,recursive:1},
  {label:"function-one",header:s1,n:0n,ctor:all("f",fn1,T),fields:1,recursive:1},
  {label:"function-two",header:s1,n:0n,ctor:all("f",fn2,T),fields:1,recursive:1},
  {label:"scope-after-function",header:s1,n:0n,ctor:all("f",fn2,all("p",s0,all("q",s0,T))),fields:3,recursive:1},
  {label:"metadata-domain",header:s1,n:0n,ctor:all("t",md(217n,T),T),fields:1,recursive:1},
  {label:"beta-domain",header:s1,n:0n,ctor:all("t",app(lam("X",s1,bv(0n)),T),T),fields:1,recursive:1},
  {label:"erased-occurrence",header:s1,n:0n,ctor:all("p",app(lam("X",s1,s0),T),T),error:"simple inductive admission does not yet support nested recursive occurrences"},
  {label:"negative-function",header:s1,n:0n,ctor:all("f",all("x",T,T),T),error:"recursive function argument contains a negative recursive occurrence"},
  {label:"universe-overflow",header:s1,n:0n,ctor:all("A",s1,T),error:"simple inductive constructor field universe is too large"},
  {label:"whole-metadata",header:s1,n:0n,ctor:md(218n,all("t",T,T)),fields:0,recursive:0},
  {label:"whole-beta",header:s1,n:0n,ctor:app(lam("X",s1,all("t",T,T)),s0),fields:0,recursive:0},
  {label:"whole-let",header:s1,n:0n,ctor:letE("X",s1,s0,all("t",T,T)),fields:0,recursive:0},
  {label:"prop-exception",header:s0,n:0n,ctor:all("A",s1,T),fields:1,recursive:0},
  {label:"indexed",header:ih1,n:0n,ctor:all("t",TI(s0),TI(s0)),fields:1,recursive:1},
  {label:"indexed-repeated",header:ih2,n:0n,ctor:all("t",TI2(s0,s0),TI2(s0,s0)),fields:1,recursive:1},
  {label:"recursive-index",header:ih1,n:0n,ctor:all("t",TI(TI(s0)),TI(s0)),error:"recursive argument index contains a recursive occurrence"},
  {label:"parameterized",header:ph,n:1n,ctor:pctor,fields:1,recursive:1},
  {label:"wrong-field-parameter",header:ph,n:1n,ctor:all("X",s1,all("t",TI(s0),app(T,bv(1n))),implicit),error:"simple inductive admission does not yet support nested recursive occurrences"}
];
if(fieldsRows.length!==21||fieldsRows.filter(r=>!r.error).length!==16)throw Error("PSC1_CONSTRUCTOR_FIELDS_FIXTURE_INVENTORY");
const CI=get("PsKernelConstantInfo"),RefKind=get("PsKernelExprV2DeclarationRefKind");
function prepare(row){
  const levels=nil,initial=get("psKernelMkCheckerSession")(env,levels,unit(Safety.safe),0n,maxNat);
  const checked=accepted(get("psKernelSessionCheck")(4096n,initial,row.header.expr),row.label+"/old-check");
  const sorted=accepted(get("psKernelSessionEnsureSort")(4096n,checked.snd,checked.fst),row.label+"/old-sort");
  const oldParams=accepted(get("psKernelOpenSimpleHeaderParams")(4096n,sorted.snd,row.header.expr,row.n),row.label+"/old-params");
  const oldIndices=accepted(get("psKernelOpenSimpleHeaderIndices")(4096n,oldParams.session,oldParams.result),row.label+"/old-indices");
  const b=builder(),headerId=b.add(row.header);
  const analysis=attempted(get("psKernelExprV2OrdinaryAnalyzeHeaderWithFuel")(
    4096n,env,0n,maxNat,b.arena,nil,levels,row.n,{name:target,type:headerId,ctors:nil},false),row.label+"/header");
  if(!exprExact(oldIndices.result,E.sort(analysis.resultLevel)))throw Error("PSC1_CONSTRUCTOR_FIELDS_HEADER_UNIVERSE");
  const oldResultLevel=oldIndices.result.level;
  const numIndices=BigInt(array(analysis.indices.binders).length);
  if(numIndices!==BigInt(array(oldIndices.binders).length))throw Error("PSC1_CONSTRUCTOR_FIELDS_HEADER_ARITY");
  const info={base:{name:target,levelParams:levels,type:row.header.expr},numParams:row.n,numIndices,
    all:list([target]),ctors:nil,numNested:0n,isRec:false,isReflexive:false,isUnsafe:false};
  const work=get("psKernelEnvironmentAddUnchecked")(env,CI.inductInfo(info));
  const oldOwner=get("psKernelSessionWithEnvironment")(oldParams.session,work);
  const oldOpened=accepted(get("psKernelOpenSimpleConstructorParams")(4096n,oldOwner,oldParams.binders,row.ctor.expr),row.label+"/old-prefix");
  const parameterState=get("psKernelExprV2OrdinaryConstructorState")(analysis);
  const parameterContext=get("psKernelExprV2OrdinaryConstructorContext")(analysis);
  const context={scalar:get("psKernelCheckerContextWithEnvironment")(parameterContext.scalar,work),locals:parameterContext.locals};
  const cb=builder(parameterState.whnf.arena),root=cb.add(row.ctor);
  const ref={name:target,levelParams:levels,type:headerId,deltaValue:none,kind:unit(RefKind.inductiveDecl)};
  const state={...parameterState,whnf:{...parameterState.whnf,arena:cb.arena,declarations:List.cons(ref,parameterState.whnf.declarations)}};
  const opened=attempted(get("psKernelExprV2OrdinaryOpenConstructorParamsWithFuel")(
    4096n,context,state,analysis.parameters.binders,root),row.label+"/prefix");
  return {old:oldOpened.session,oldType:oldOpened.result,oldParams:oldParams.binders,context,
    state:opened.fst,root:opened.snd,params:analysis.parameters.binders,
    numIndices,resultLevel:oldResultLevel};
}
const graphDecode=arena=>{
  const graph=accepted(get("psKernelExprV2DecodeChecked")(arena),"result-canonical");
  return root=>accepted(get("psKernelExprV2DecodedRequire")(graph,root),"result-root");
};
const binderEqual=(left,right,decodeId)=>same(left.internalName,right.internalName)&&same(left.userName,right.userName)&&
  same(left.binderInfo,right.binderInfo)&&exprExact(left.type,decodeId(right.type));
const seqEqual=(left,right,equal)=>{
  const a=array(left),b=array(right);return a.length===b.length&&a.every((v,i)=>equal(v,b[i]));
};
const bindersEqual=(a,b,decodeId)=>seqEqual(a,b,(x,y)=>binderEqual(x,y,decodeId));
const localsEqual=(old,context,decodeId)=>seqEqual(old.context.localContext.decls,context.locals,(a,b)=>
  same(get("psKernelLocalDeclName")(a),b.name)&&same(get("psKernelLocalDeclUserName")(a),b.userName)&&
  same(get("psKernelLocalDeclBinderInfo")(a),b.binderInfo)&&exprExact(get("psKernelLocalDeclType")(a),decodeId(b.type))&&
  same(get("psKernelLocalDeclValue")(a),none)&&same(b.value,none));
function arenaPrefix(after,before){
  if(after.size<before.size||after.pageLimit!==before.pageLimit)return false;
  for(let id=0n;id<before.size;id++)
    if(!same(get("psKernelExprV2PagedFind")(after,id),get("psKernelExprV2PagedFind")(before,id)))return false;
  return true;
}
function fieldEqual(old,actual,fixture){
  if(!actual||!Object.hasOwn(actual,"value"))return false;
  const got=actual.value;
  if(rejected(old))return same(old,got);
  if(rejected(got))return false;
  const left=accepted(old,"old-field"),right=accepted(got,"new-field"),d=graphDecode(right.state.whnf.arena);
  return exprExact(left.result,d(right.result))&&left.session.state.nextFresh===right.state.nextFresh&&
    bindersEqual(left.fields,right.fields,d)&&
    seqEqual(left.recursiveFields,right.recursiveFields,(a,b)=>
      binderEqual(a.field,b.field,d)&&bindersEqual(a.args,b.arguments,d)&&
      seqEqual(a.indices,b.indices,(x,y)=>exprExact(x,d(y))))&&
    localsEqual(left.session,right.context,d)&&
    same(right.state.whnf.declarations,fixture.state.whnf.declarations)&&
    arenaPrefix(right.state.whnf.arena,fixture.state.whnf.arena);
}
const fuels=[0n,1n,2n,3n,8n,4096n];
let positiveFields=0,negativeFields=0;
section="fields";
for(const row of fieldsRows){
  const f=prepare(row);
  for(const fuel of fuels){
    const old=get("psKernelOpenSimpleConstructorFields")(fuel,f.old,target,nil,f.oldParams,f.numIndices,f.resultLevel,f.oldType);
    const actual=get("psKernelExprV2OrdinaryOpenConstructorFieldsWithFuel")(
      fuel,f.context,f.state,target,nil,f.params,f.numIndices,f.resultLevel,f.root);
    must(fieldEqual(old,actual,f),row.label+"/fuel="+fuel);
  }
  const actual=get("psKernelExprV2OrdinaryOpenConstructorFieldsWithFuel")(
    4096n,f.context,f.state,target,nil,f.params,f.numIndices,f.resultLevel,f.root);
  if(row.error){
    must(same(actual,Option.some(err(row.error))),row.label+"/required-error");negativeFields++;
  }else{
    const got=attempted(actual,row.label+"/required-direct");
    must(array(got.fields).length===row.fields&&array(got.recursiveFields).length===row.recursive,
      row.label+"/required-direct-shape");positiveFields++;
    if(row.label==="function-two"||row.label==="scope-after-function"){
      const recursive=array(got.recursiveFields);
      if(array(recursive[0].arguments).length!==2)throw Error("PSC1_CONSTRUCTOR_FIELDS_MISSING_TEMP_ARGS");
    }
    if(row.label==="scope-after-function"){
      const fields=array(got.fields),args=array(array(got.recursiveFields)[0].arguments);
      const locals=array(got.context.locals);
      if(locals.length!==3||locals.some(l=>args.some(a=>same(a.internalName,l.name)))||
          !same(locals[0].name,fields[2].internalName))
        throw Error("PSC1_CONSTRUCTOR_FIELDS_TEMP_SCOPE_LEAK");
    }
  }
}

const recRows=[
  {label:"nonrecursive-sort",header:s1,expr:s0,args:null},
  {label:"direct",header:s1,expr:T,args:0,indices:0},
  {label:"function-one",header:s1,expr:fn1,args:1,indices:0},
  {label:"function-two",header:s1,expr:fn2,args:2,indices:0},
  {label:"metadata",header:s1,expr:md(219n,T),args:0,indices:0},
  {label:"beta",header:s1,expr:app(lam("X",s1,bv(0n)),T),args:0,indices:0},
  {label:"negative",header:s1,expr:all("x",T,T),error:"recursive function argument contains a negative recursive occurrence"},
  {label:"erased",header:s1,expr:app(lam("X",s1,s0),T),error:"simple inductive admission does not yet support nested recursive occurrences"},
  {label:"surplus-argument",header:s1,expr:TI(s0),error:"simple inductive admission does not yet support nested recursive occurrences"},
  {label:"indexed",header:ih1,expr:TI(s0),args:0,indices:1},
  {label:"indexed-repeated",header:ih2,expr:TI2(s0,s0),args:0,indices:2},
  {label:"recursive-index",header:ih1,expr:TI(TI(s0)),error:"recursive argument index contains a recursive occurrence"},
  {label:"function-index",header:ih1,expr:all("i",s1,TI(bv(0n))),args:1,indices:1},
  {label:"nonrecursive-function",header:s1,expr:all("p",s0,s0),args:null},
  {label:"lambda-occurrence",header:s1,expr:lam("p",s0,T),error:"simple inductive admission does not yet support nested recursive occurrences"}
];
if(recRows.length!==15||recRows.filter(r=>!r.error).length!==10)throw Error("PSC1_RECURSIVE_ARGUMENT_FIXTURE_INVENTORY");
function recursiveEqual(old,actual,fixture){
  if(!actual||!Object.hasOwn(actual,"value"))return false;
  const got=actual.value;
  if(rejected(old))return same(old,got);
  if(rejected(got))return false;
  const left=accepted(old,"old-recursive"),right=accepted(got,"new-recursive"),d=graphDecode(right.state.whnf.arena);
  let info=false;
  if(same(left.recursiveInfo,none))info=same(right.recursiveInfo,none);
  else if(right.recursiveInfo&&Object.hasOwn(right.recursiveInfo,"value")){
    const a=accepted(left.recursiveInfo,"old-rec-info"),b=accepted(right.recursiveInfo,"new-rec-info");
    info=bindersEqual(a.fst,b.fst,d)&&seqEqual(a.snd,b.snd,(x,y)=>exprExact(x,d(y)));
  }
  return info&&left.session.state.nextFresh===right.state.nextFresh&&localsEqual(left.session,right.context,d)&&
    same(right.state.whnf.declarations,fixture.state.whnf.declarations)&&
    arenaPrefix(right.state.whnf.arena,fixture.state.whnf.arena);
}
let positiveRecursive=0,negativeRecursive=0;
section="recursive";
for(const row of recRows){
  const f=prepare({label:"rec/"+row.label,header:row.header,n:0n,ctor:T});
  const b=builder(f.state.whnf.arena),root=b.add(row.expr);
  const state=get("psKernelExprV2CheckStateWithArena")(f.state,b.arena);
  for(const fuel of fuels){
    const old=get("psKernelAnalyzeSimpleRecursiveArgument")(fuel,f.old,target,nil,f.oldParams,f.numIndices,row.expr.expr);
    const actual=get("psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWithFuel")(
      fuel,f.context,state,target,nil,f.params,f.numIndices,root);
    must(recursiveEqual(old,actual,{...f,state}),row.label+"/fuel="+fuel);
  }
  const actual=get("psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWithFuel")(
    4096n,f.context,state,target,nil,f.params,f.numIndices,root);
  if(row.error){
    must(same(actual,Option.some(err(row.error))),row.label+"/required-error");negativeRecursive++;
  }else{
    const got=attempted(actual,row.label+"/required-direct");
    let shape;
    if(row.args===null)shape=same(got.recursiveInfo,none);
    else {
      const info=accepted(got.recursiveInfo,row.label+"/required-info");
      shape=array(info.fst).length===row.args&&array(info.snd).length===row.indices;
      if(row.label==="indexed-repeated"){
        const ids=array(info.snd);
        if(ids[0]!==ids[1])throw Error("PSC1_RECURSIVE_ARGUMENT_INDEX_ID_ORDER");
      }
    }
    must(shape,row.label+"/required-direct-shape");positiveRecursive++;
  }
}

const applyCurried=(fn,args)=>args.reduce((next,arg)=>next(arg),fn);
const callbackDecline=_fuel=>_context=>_state=>_root=>none;
const callbackError=message=>_fuel=>_context=>_state=>_root=>Option.some(err(message));
const callbackForbidden=()=>{throw Error("PSC1_CONSTRUCTOR_FIELDS_UNEXPECTED_CALLBACK");};
const analyzeActual=fuel=>context=>state=>targetName=>levels=>params=>numIndices=>root=>
  get("psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWithFuel")(fuel,context,state,targetName,levels,params,numIndices,root);
function rawFields(fuel,check,whnf,analyze,f,root){
  return applyCurried(get("psKernelExprV2OrdinaryOpenConstructorFieldsWorker")(fuel),
    [check,whnf,analyze,f.context,f.state,target,nil,f.params,f.numIndices,f.resultLevel,root,nil,nil]);
}
function rawRecursive(fuel,check,whnf,f,root){
  return applyCurried(get("psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker")(fuel),
    [check,whnf,f.context,f.state,target,nil,f.params,f.numIndices,root,nil]);
}
section="boundaries";
const boundaryBase=prepare(fieldsRows[0]);
const boundaryBuilder=builder(boundaryBase.state.whnf.arena);
const terminalId=boundaryBuilder.add(s0),forallId=boundaryBuilder.add(all("x",T,T));
const boundary={...boundaryBase,state:get("psKernelExprV2CheckStateWithArena")(boundaryBase.state,boundaryBuilder.arena)};
must(same(rawFields(0n,callbackForbidden,callbackForbidden,callbackForbidden,boundary,999999n),
  Option.some(err("simple inductive field budget exhausted"))),"fields-zero-before-invalid-root");
must(same(rawFields(1n,callbackForbidden,callbackForbidden,callbackForbidden,boundary,999999n),
  Option.some(err("PSKERNEL_V2_PAGED_INVALID_CHILD"))),"fields-positive-invalid-before-callbacks");
const terminal=attempted(rawFields(1n,callbackForbidden,callbackForbidden,callbackForbidden,boundary,terminalId),"terminal");
must(same(terminal.state,boundary.state)&&same(terminal.context,boundary.context)&&
  terminal.result===terminalId&&same(terminal.fields,nil)&&same(terminal.recursiveFields,nil),
  "terminal-keeps-complete-owner-without-callbacks");
must(same(rawFields(1n,callbackDecline,callbackForbidden,callbackForbidden,boundary,forallId),none),"field-check-decline");
must(same(rawFields(1n,callbackError("field-check-sentinel"),callbackForbidden,callbackForbidden,boundary,forallId),
  Option.some(err("field-check-sentinel"))),"field-check-error");
must(same(rawRecursive(0n,callbackForbidden,callbackForbidden,boundary,999999n),
  Option.some(err("simple inductive recursive-argument budget exhausted"))),"recursive-zero-before-root-or-whnf");
must(same(rawRecursive(1n,callbackForbidden,callbackDecline,boundary,999999n),none),"recursive-whnf-decline");
must(same(rawRecursive(1n,callbackForbidden,callbackError("recursive-whnf-sentinel"),boundary,999999n),
  Option.some(err("recursive-whnf-sentinel"))),"recursive-whnf-error");

section="recursorGuard";
const guardBase=prepare(fieldsRows[0]),recName=name("CtorFieldsGuardRec");
const gb=builder(guardBase.state.whnf.arena),guardRoot=gb.add(app(cn(recName),T));
const erasedRoot=gb.add(app(cn(recName),s0));
const guardState=get("psKernelExprV2CheckStateWithArena")(guardBase.state,gb.arena);
const recInfo={base:{name:recName,levelParams:nil,type:s1.expr},all:list([target]),numParams:0n,
  numIndices:0n,numMotives:0n,numMinors:0n,rules:nil,k:false,isUnsafe:false};
const withInfo=info=>({...guardBase.context,scalar:get("psKernelCheckerContextWithEnvironment")(
  guardBase.context.scalar,get("psKernelEnvironmentAddUnchecked")(guardBase.context.scalar.environment,info))});
const recContext=withInfo(CI.recInfo(recInfo));
const axiomContext=withInfo(CI.axiomInfo({base:recInfo.base,isUnsafe:false}));
const unsafeContext={...recContext,scalar:{...recContext.scalar,safety:unit(Safety.unsafeDef)}};
// These seven fixtures exercise only the private kind/occurrence guard.
// The synthetic metadata is never claimed admitted, installed publicly, or used
// as successful proof-checking evidence.
const guard=(context,root)=>get("psKernelExprV2OrdinaryInvalidRecursorOccurrence")(context,guardState,target,root);
must(same(guard(recContext,guardRoot),ok(true)),"safe-live-recursor-target");
must(same(guard(unsafeContext,guardRoot),ok(false)),"unsafe-retains-unsupported-boundary");
must(same(guard(guardBase.context,guardRoot),ok(false)),"missing-live-head");
must(same(guard(axiomContext,guardRoot),ok(false)),"live-axiom-is-not-recursor");
must(same(guard(recContext,erasedRoot),ok(false)),"reduced-target-absent");
must(same(guard(unsafeContext,999999n),ok(false)),"unsafe-precedes-invalid-id");
must(same(guard(recContext,999999n),err("PSKERNEL_V2_PAGED_INVALID_CHILD")),"safe-invalid-id");
const expectedCounts={harness:1,fields:147,recursive:105,boundaries:8,recursorGuard:7};
if(!same(counts,expectedCounts)||assertions!==268||positiveFields!==16||negativeFields!==5||
    positiveRecursive!==10||negativeRecursive!==5)throw Error("PSC1_CONSTRUCTOR_FIELDS_SECTION_INVENTORY");
const report={schema:"psc1-ordinary-constructor-fields-v1",kernel:kernelPath,assertions,
  sectionAssertions:counts,fieldRows:21,recursiveRows:15,fuelValues:6,
  positiveFields,negativeFields,positiveRecursive,negativeRecursive,
  fullAdmission:false,publicRoutingChanged:false};
console.log(JSON.stringify(report));
console.log("PSC1_ORDINARY_CONSTRUCTOR_FIELDS_JS: PASS assertions=268 fullAdmission=false");
