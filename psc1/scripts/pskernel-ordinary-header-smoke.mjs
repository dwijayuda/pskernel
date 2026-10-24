import {pathToFileURL} from "node:url";
import path from "node:path";

// T05 header infrastructure only. This harness calls the actual direct workers;
// public ordinary admission/fallback cannot satisfy any header success below.
// Frozen V1 reference: psKernelAddSimpleInductive's header prefix, ending before
// initialInfo/work0, at 0d9f062846d109c362210d441df5fd407ca2cdd7 in
// Admission/Inductive/Ordinary/Admission.lean. Retained V1 helpers are the oracle.
// Frozen original Git blob: cb2e3a74cbf9ccc8a8484d1bc31d5ed82eda6490.
if(process.argv.length!==3)throw Error("PSC1_ORDINARY_HEADER_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(process.argv[2])).href);
const get=name=>{if(!(name in k))throw Error("PSC1_ORDINARY_HEADER_MISSING_EXPORT "+name);return k[name];};
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
const accepted=(value,label)=>{
  if(value&&Object.hasOwn(value,"value"))return value.value;
  throw Error("PSC1_ORDINARY_HEADER_REJECTED "+label+": "+String(value?.error));
};
const attempted=(value,label)=>accepted(accepted(value,label+"-direct-some"),label+"-direct-ok");
const rejected=value=>value&&Object.hasOwn(value,"error");
let assertions=0,section="harness";
const counts={};
const must=(condition,label)=>{
  if(condition!==true)throw Error("PSC1_ORDINARY_HEADER_JS_FAIL "+section+"/"+label);
  assertions++;counts[section]=(counts[section]??0)+1;
};
must(!same(ok("same"),err("same"))&&!same(none,Option.some(none)),"constructor-tags-not-erased");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Node=get("PsKernelExprV2Node"),Literal=get("PsKernelLiteral"),Safety=get("PsKernelDefinitionSafety");
const name=s=>N.str(unit(N.anonymous),s),child=(n,s)=>N.str(n,s);
const bi=unit(B.default),implicit=unit(B.implicit),strict=unit(B.strictImplicit),instance=unit(B.instImplicit);
const zero=unit(L.zero),one=L.succ(zero),owner=name("T05Header"),u=name("u"),v=name("v");
const term=(kind,args,expr)=>({kind,args,expr});
const sort=level=>term("Sort",[level],E.sort(level));
const s0=sort(zero),s1=sort(one),s2=sort(L.succ(one));
const bv=index=>term("BVar",[index],E.bvar(index));
const fv=n=>term("FVar",[n],E.fvar(n));
const mv=n=>term("MVar",[n],E.mvar(n));
const cn=(n,levels=[])=>term("Const",[n,list(levels)],E.const(n,list(levels)));
const app=(fn,arg)=>term("App",[fn,arg],E.app(fn.expr,arg.expr));
const apps=(fn,args)=>args.reduce(app,fn);
const all=(n,domain,body,info=bi)=>term("Forall",[name(n),domain,body,info],E.forallE(name(n),domain.expr,body.expr,info));
const lam=(n,domain,body)=>term("Lam",[name(n),domain,body,bi],E.lam(name(n),domain.expr,body.expr,bi));
const letE=(n,type,value,body)=>term("Let",[name(n),type,value,body,false],E.letE(name(n),type.expr,value.expr,body.expr,false));
const md=(tag,body)=>term("MData",[tag,body],E.mdata(tag,body.expr));
const proj=body=>term("Proj",[name("S"),0n,body],E.proj(name("S"),0n,body.expr));
const emptyArena=unit(get("psKernelExprV2PagedEmpty"));
function builder(){
  let arena=emptyArena;
  const memo=new Map();
  const add=t=>{
    if(memo.has(t))return memo.get(t);
    const args=t.args.map(x=>x&&typeof x==="object"&&Object.hasOwn(x,"expr")&&Object.hasOwn(x,"kind")?add(x):x);
    const built=accepted(get("psKernelExprV2PagedMk"+t.kind)(arena,...args),"fixture-"+t.kind);
    arena=built.fst;memo.set(t,built.snd);return built.snd;
  };
  return {add,get arena(){return arena;}};
}
const decode=(arena,root)=>accepted(get("psKernelExprV2DecodedRequire")(
  accepted(get("psKernelExprV2DecodeChecked")(arena),"decode-arena"),root),"decode-root");
const exprExact=(a,b)=>get("psKernelExprEqual")(a)(b)===true;
const env=unit(get("psKernelEnvironmentEmpty")),maxNat=unit(get("psKernelLeanNatMaxSizeDefault"));
const mkDecl=(type,params=0n,levels=[],ctors=[])=>({
  name:owner,type,params,levels,ctors:ctors.map((type,index)=>({name:N.num(child(owner,"mk"),BigInt(index)),type})),unsafe:false});
const legacy=d=>({name:d.name,type:d.type.expr,numParams:d.params,levelParams:list(d.levels),
  ctors:list(d.ctors.map(c=>({name:c.name,type:c.type.expr}))),isUnsafe:d.unsafe});
const build=d=>{const b=builder(),root=b.add(d.type);const ctors=d.ctors.map(c=>({name:c.name,type:b.add(c.type)}));
  return {arena:b.arena,value:{name:d.name,type:root,ctors:list(ctors)}};};
function frozenV1Header(fuel,environment,d,depth){
  const old=legacy(d),names=list([d.name,get("psKernelSimpleRecName")(d.name),...d.ctors.map(c=>c.name)]);
  if(get("psKernelNameHasDuplicates")(old.levelParams))return err("duplicate universe parameter");
  if(!get("psKernelSimpleNameListUnique")(names))return err("duplicate inductive, constructor, or recursor name");
  for(const guard of [
    ()=>get("psKernelCheckFreshInductiveNames")(names)(environment),
    ()=>get("psKernelSimpleCheckUniformOccurrences")(list([d.name]),old.levelParams,d.params,list(d.ctors.map(c=>c.type.expr))),
    ()=>get("psKernelCheckNoMVarNoFVar")(old.type),
    ()=>get("psKernelCheckLevelParams")(old.type,old.levelParams)]){
    const result=guard();if(rejected(result))return result;
  }
  const session=get("psKernelMkCheckerSession")(environment,old.levelParams,
    unit(d.unsafe?Safety.unsafeDef:Safety.safe),depth,maxNat);
  const checked=get("psKernelSessionCheck")(fuel,session,old.type);if(rejected(checked))return checked;
  const inferred=accepted(checked,"old-check");
  const sorted=get("psKernelSessionEnsureSort")(fuel,inferred.snd,inferred.fst);if(rejected(sorted))return sorted;
  const params=get("psKernelOpenSimpleHeaderParams")(fuel,accepted(sorted,"old-sort").snd,old.type,d.params);
  if(rejected(params))return params;
  const parameters=accepted(params,"old-parameters");
  const indicesResult=get("psKernelOpenSimpleHeaderIndices")(fuel,parameters.session,parameters.result);
  if(rejected(indicesResult))return indicesResult;
  const indices=accepted(indicesResult,"old-indices");
  if(!Object.hasOwn(indices.result,"level")||!same(indices.result,E.sort(indices.result.level)))
    return err("simple inductive result must be a sort");
  return ok({parameters,indices,resultLevel:indices.result.level});
}
const directHeader=(fuel,environment,d,depth,built)=>get("psKernelExprV2OrdinaryAnalyzeHeaderWithFuel")(
  fuel,environment,depth,maxNat,built.arena,nil,list(d.levels),d.params,built.value,d.unsafe);
const sameOpen=(old,actual)=>{
  const left=array(old.binders),right=array(actual.binders);
  return left.length===right.length&&old.session.state.nextFresh===actual.state.nextFresh&&
    exprExact(old.result,decode(actual.state.whnf.arena,actual.result))&&left.every((b,i)=>
      same(b.internalName,right[i].internalName)&&same(b.userName,right[i].userName)&&
      same(b.binderInfo,right[i].binderInfo)&&exprExact(b.type,decode(actual.state.whnf.arena,right[i].type)));
};
const headerSame=(old,attempt)=>{
  if(!attempt||!Object.hasOwn(attempt,"value"))return false;
  const actual=attempt.value;
  if(rejected(old))return rejected(actual)&&same(old,actual);
  if(rejected(actual))return false;
  const a=accepted(old,"old-analysis"),b=accepted(actual,"new-analysis");
  return sameOpen(a.parameters,b.parameters)&&sameOpen(a.indices,b.indices)&&same(a.resultLevel,b.resultLevel);
};
const self=cn(owner),selfU=cn(owner,[L.param(u)]);
const positives=[
  ["enum",mkDecl(s1,0n,[],[self])],
  ["parameter",mkDecl(all("A",s1,s1,implicit),1n,[],[all("A",s1,all("value",bv(0n),apps(self,[bv(1n)])))])],
  ["dependent-index",mkDecl(all("A",s1,all("a",bv(0n),s1,strict)),1n,[],[all("A",s1,all("a",bv(0n),apps(self,[bv(1n),bv(0n)])))])],
  ["universe",mkDecl(all("A",sort(L.param(u)),sort(L.param(u))),1n,[u],[all("A",sort(L.param(u)),all("value",bv(0n),apps(selfU,[bv(1n)])))])],
  ["two-parameters",mkDecl(all("A",s1,all("B",s1,s1,instance)),2n,[],[all("A",s1,all("B",s1,apps(self,[bv(1n),bv(0n)])))])],
  ["zero-parameter-index",mkDecl(all("A",s1,s1))],
  ["metadata",mkDecl(md(71n,s1),0n,[],[self])],
  ["beta",mkDecl(app(lam("T",s2,bv(0n)),s1),0n,[],[self])],
  ["let",mkDecl(letE("T",s2,s1,bv(0n)),0n,[],[self])],
  ["unsafe-header",{...mkDecl(s1,0n,[],[self]),unsafe:true}]
];
const negatives=[
  ["duplicate-level-first",mkDecl(mv(name("m")),1n,[u,u],[self])],
  ["uniform-before-header-mvar",mkDecl(mv(name("m")),1n,[],[self])],
  ["mvar-before-fvar-and-level",mkDecl(app(fv(name("x")),sort(L.mvar(u))))],
  ["fvar-before-undefined-level",mkDecl(app(fv(name("x")),sort(L.param(v))))],
  ["undefined-universe",mkDecl(sort(L.param(v)))],
  ["fewer-parameters",mkDecl(s1,1n)],
  ["non-sort-result",mkDecl(all("A",s1,bv(0n)))],
  ["illtyped-header",mkDecl(app(s0,s0))]
];
section="header";
for(const [label,d] of [...positives,...negatives]){
  const built=build(d);
  for(const fuel of [0n,1n,2n,3n,4n,8n,32n,4096n])for(const depth of [0n,1n,8n])
    must(headerSame(frozenV1Header(fuel,env,d,depth),directHeader(fuel,env,d,depth,built)),
      label+"/fuel="+fuel+"/depth="+depth);
}
for(const [label,d] of positives){
  const result=attempted(directHeader(4096n,env,d,0n,build(d)),label);
  must(BigInt(array(result.parameters.binders).length)===d.params&&!Object.hasOwn(result,"environment"),
    label+"/direct-success-is-only-header-analysis");
}
const collision={...mkDecl(mv(name("m")),1n,[],[self]),ctors:[{name:owner,type:self}]};
must(headerSame(frozenV1Header(4096n,env,collision,0n),directHeader(4096n,env,collision,0n,build(collision))),
  "duplicate-name-before-uniform-header");
const collisionEnv=accepted(get("psKernelAddAxiom")(4096n,env,
  {base:{name:owner,levelParams:nil,type:s1.expr},isUnsafe:false},0n,maxNat),"name-collision-fixture");
const freshFault=mkDecl(mv(name("m")),1n,[],[self]);
must(headerSame(frozenV1Header(4096n,collisionEnv,freshFault,0n),directHeader(4096n,collisionEnv,freshFault,0n,build(freshFault))),
  "fresh-name-before-uniform-header");

section="occurrence";
const c=cn(owner,[L.param(u)]),good=apps(c,[bv(0n)]);
const occurrenceCases=[c,good,apps(c,[bv(1n)]),apps(c,[s1]),apps(c,[bv(0n),s0]),
  apps(cn(owner),[bv(0n)]),apps(cn(owner,[L.param(u),L.param(u)]),[bv(0n)]),
  apps(c,[bv(1n),bv(0n)]),apps(c,[bv(0n),bv(1n)]),
  apps(cn(owner,[one]),[bv(0n)]),apps(cn(name("Other")),[good]),app(good,good),
  all("x",s1,good),all("x",good,s1),lam("x",s1,good),letE("x",s1,good,good),md(72n,good),proj(good),s0];
const declared=list([owner]),levels=list([L.param(u)]);
for(const t of occurrenceCases){
  const b=builder(),root=b.add(t),arena=b.arena;
  for(const offset of [0n,1n,2n])for(const params of [0n,1n,2n]){
    must(same(get("psKernelExprV2OrdinaryUniformOccurrenceHead")(arena,declared,levels,params,root,offset),
      get("psKernelSimpleCheckUniformOccurrenceHead")(declared,levels,params,t.expr,offset)),"head/count-level-args");
    for(const fuel of [0n,1n,2n,3n,8n,32n])
      must(same(get("psKernelExprV2OrdinaryUniformOccurrenceWithFuel")(fuel)(arena)(declared)(levels)(params)(root)(offset),
        get("psKernelSimpleCheckUniformOccurrenceWithFuel")(fuel)(declared)(levels)(params)(t.expr)(offset)),"fuel/order");
    must(same(get("psKernelExprV2OrdinaryUniformOccurrenceOnCanonical")(arena,declared,levels,params,root,offset),
      get("psKernelSimpleCheckUniformOccurrence")(declared,levels,params,t.expr,offset)),"wrapper/structural-bound");
  }
}
const sharedBuilder=builder(),shared=sharedBuilder.add(good),under=all("x",s1,good);
const bothTerm=app(good,under),both=sharedBuilder.add(bothTerm),sharedArena=sharedBuilder.arena;
const occurrence=(root,offset)=>get("psKernelExprV2OrdinaryUniformOccurrenceOnCanonical")(sharedArena,declared,levels,1n,root,offset);
must(same(occurrence(shared,1n),ok(undefined)),"shared-ID-valid-at-offset-one");
must(rejected(occurrence(shared,2n)),"shared-ID-invalid-at-offset-two");
must(same(occurrence(both,1n),get("psKernelSimpleCheckUniformOccurrence")(declared,levels,1n,bothTerm.expr,1n)),
  "shared-ID-revisited-under-binder");
const sharedNode=accepted(get("psKernelExprV2PagedRequire")(sharedArena,both),"shared-app").node;
const underNode=accepted(get("psKernelExprV2PagedRequire")(sharedArena,sharedNode.arg),"shared-forall").node;
must(sharedNode.fn===shared&&underNode.body===shared,"fixture-actually-shares-one-ID");
must(same(get("psKernelExprV2OrdinaryUniformOccurrenceWithFuel")(0n)(emptyArena)(declared)(levels)(1n)(999n)(0n),
  err("simple inductive uniform-occurrence budget exhausted")),"zero-before-invalid-ID");
must(same(get("psKernelExprV2OrdinaryUniformOccurrenceWithFuel")(1n)(emptyArena)(declared)(levels)(1n)(999n)(0n),
  err("PSKERNEL_V2_TRANSFORM_BAD_ROOT")),"positive-invalid-ID");
const listBuilder=builder(),listGood=listBuilder.add(all("A",s1,good)),listBad=listBuilder.add(c),listArena=listBuilder.arena;
const scan=roots=>get("psKernelExprV2OrdinaryUniformOccurrences")(list(roots))(listArena)(declared)(levels)(1n);
must(!rejected(scan([])),"empty-constructor-list");
must(!rejected(scan([listGood,listGood])),"repeated-valid-constructor-list");
must(same(scan([listBad,999n]),scan([listBad])),"first-occurrence-error-before-later-invalid-ID");
must(same(scan([999n,listBad]),err("PSKERNEL_V2_PAGED_INVALID_CHILD")),"first-invalid-ID-before-later-occurrence-error");

section="annotations";
const out=unit(get("psKernelTypeAnnotationOutParamName")),semi=unit(get("psKernelTypeAnnotationSemiOutParamName"));
const opt=unit(get("psKernelTypeAnnotationOptParamName")),auto=unit(get("psKernelTypeAnnotationAutoParamName"));
const wrap=(n,args)=>apps(cn(n),args);
const annotationCases=[s1,wrap(out,[]),wrap(out,[s1]),wrap(semi,[s1]),wrap(opt,[s1,s0]),wrap(auto,[s1,s0]),
  wrap(out,[s1,s0]),wrap(semi,[s1,s0]),wrap(opt,[s1]),wrap(auto,[s1]),wrap(opt,[s1,s0,s0]),
  wrap(child(name("Other"),"outParam"),[s1]),wrap(out,[wrap(auto,[wrap(semi,[s1]),s0])]),
  md(73n,wrap(out,[s1])),wrap(out,[md(74n,wrap(semi,[s1]))])];
for(const t of annotationCases){
  const b=builder(),root=b.add(t),arena=b.arena;
  for(const fuel of [0n,1n,2n,3n,8n]){
    const result=accepted(get("psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel")(fuel)(arena)(root),"annotation-fuel");
    must(exprExact(decode(arena,result),get("psKernelExprConsumeTypeAnnotationsWithFuel")(fuel)(t.expr)),
      "exact-name-arity-nesting-metadata");
  }
  const result=accepted(get("psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical")(arena,root),"annotation-wrapper");
  must(exprExact(decode(arena,result),get("psKernelExprConsumeTypeAnnotations")(t.expr)),"wrapper-bound");
}
must(same(get("psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel")(0n)(emptyArena)(999n),ok(999n)),"zero-before-invalid-ID");
must(same(get("psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel")(1n)(emptyArena)(999n),err("PSKERNEL_V2_TRANSFORM_BAD_ROOT")),"positive-invalid-ID");
must(same(get("psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical")(emptyArena,999n),err("PSKERNEL_V2_PAGED_INVALID_CHILD")),"wrapper-invalid-ID");
const metadataBuilder=builder(),metadataRoot=metadataBuilder.add(md(73n,wrap(out,[s1])));
must(accepted(get("psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical")(metadataBuilder.arena,metadataRoot),"metadata-retained")===metadataRoot,
  "metadata-is-not-peeled");

section="state";
const stateBuilder=builder(),sortId=stateBuilder.add(s1),originalDomain=md(75n,s1);
const consumedDomainId=stateBuilder.add(originalDomain),annotatedDomain=wrap(out,[originalDomain]);
const domainId=stateBuilder.add(annotatedDomain),headerId=stateBuilder.add(all("A",annotatedDomain,s1,implicit));
const scalar=get("psKernelMkCheckerSession")(env,nil,unit(Safety.safe),0n,maxNat).context;
const context=get("psKernelExprV2CheckContextEmpty")(scalar),modulus=unit(get("psKernelCacheHashModulus"));
function stamp(state,tag){
  const built=accepted(get("psKernelExprV2PagedMkLit")(state.whnf.arena,Literal.nat(12000n+tag)),"state-marker");
  const cache={source:sortId,result:built.snd,hash:modulus+tag},pair={left:sortId,right:sortId,hash:modulus+tag};
  const declaration={name:N.num(name("state"),tag),levelParams:nil,type:sortId,
    deltaValue:Option.some(built.snd),kind:unit(get("PsKernelExprV2DeclarationRefKind").definitionDecl)};
  return {whnf:{arena:built.fst,coreCache:list([cache]),publicCache:list([cache]),declarations:list([declaration])},
    nextFresh:100n+10n*tag,checkedInfer:list([cache]),success:list([pair]),inferOnly:list([cache]),unfold:list([cache]),failure:list([pair])};
}
function marker(state,tag,extra=0n){
  const rows=array(state.checkedInfer);if(rows.length!==1)return false;
  const cache={source:sortId,result:rows[0].result,hash:modulus+tag},pair={left:sortId,right:sortId,hash:modulus+tag};
  const declaration={name:N.num(name("state"),tag),levelParams:nil,type:sortId,deltaValue:Option.some(cache.result),
    kind:unit(get("PsKernelExprV2DeclarationRefKind").definitionDecl)};
  const node=get("psKernelExprV2PagedRequire")(state.whnf.arena,cache.result);
  return state.nextFresh===100n+10n*tag+extra&&[state.whnf.coreCache,state.whnf.publicCache,state.checkedInfer,state.inferOnly,state.unfold]
    .every(xs=>same(xs,list([cache])))&&[state.success,state.failure].every(xs=>same(xs,list([pair])))&&
    same(state.whnf.declarations,list([declaration]))&&!rejected(node)&&same(node.value.node,Node.lit(Literal.nat(12000n+tag)));
}
const initial=stamp(get("psKernelExprV2CheckStateEmpty")(stateBuilder.arena),0n);
for(const indexMode of [false,true]){
  function run(failAt=0,decline=false){
    const trace=[];
    const callback=kind=>fuel=>ctx=>state=>root=>{
      const stage=trace.length+1;trace.push({stage,kind,fuel,root});
      const expectedFuel=indexMode&&stage===4?6n:7n,expectedRoot=stage===1?headerId:stage===2?domainId:sortId;
      if(fuel!==expectedFuel||root!==expectedRoot||kind!==(stage===2?"check":"whnf")||
          !marker(state,BigInt(stage-1),stage===4?1n:0n)||ctx.scalar!==context.scalar||
          array(ctx.locals).length!==(stage===4?1:0))
        throw Error("T05_CALLBACK_WRONG_INPUT_OR_STALE_OWNER stage="+stage);
      if(stage===failAt)return decline?none:Option.some(err("T05_CALLBACK_INJECTED"));
      return Option.some(ok({fst:stamp(state,BigInt(stage)),snd:kind==="check"?sortId:root}));
    };
    const args=[callback("check"),callback("whnf"),7n,context,initial,headerId];
    const result=indexMode?get("psKernelExprV2OrdinaryOpenHeaderIndicesWith")(...args):
      get("psKernelExprV2OrdinaryOpenHeaderParamsWith")(...args,1n);
    return {result,trace};
  }
  const success=run(),result=attempted(success.result,"ordered-callbacks"),binders=array(result.binders);
  must(success.trace.length===4&&success.trace.map(x=>x.kind).join(",")==="whnf,check,whnf,whnf", "mandatory-callback-sequence");
  must(marker(result.state,4n),"all-owner-fields-and-appended-arena-propagated");
  must(binders.length===1&&same(binders[0].internalName,N.num(name("A"),130n))&&same(binders[0].userName,name("A"))&&
    binders[0].type===consumedDomainId&&exprExact(decode(result.state.whnf.arena,binders[0].type),originalDomain.expr)&&
    same(binders[0].binderInfo,implicit)&&array(result.context.locals).length===1&&
    array(result.context.locals)[0].type===consumedDomainId&&same(array(result.context.locals)[0].name,binders[0].internalName),
    "fresh-name-original-domain-binder-and-context");
  const indexState=stamp(result.state,9n),indexId=array(indexState.checkedInfer)[0].result;
  const indexContext=get("psKernelExprV2CheckContextWithLocal")(result.context,name("index-only"),name("index-user"),sortId,strict);
  const analysis={parameters:result,indices:{context:indexContext,state:indexState,binders:nil,result:indexId},resultLevel:zero};
  const fork=get("psKernelExprV2OrdinaryConstructorState")(analysis);
  must(marker(fork,4n)&&["checkedInfer","success","inferOnly","unfold","failure"].every(field=>fork[field]===result.state[field])&&
    fork.whnf.coreCache===result.state.whnf.coreCache&&fork.whnf.publicCache===result.state.whnf.publicCache&&
    fork.whnf.declarations===result.state.whnf.declarations,"fork-restores-exact-parameter-owner");
  must(fork.whnf.arena===indexState.whnf.arena&&exprExact(decode(fork.whnf.arena,indexId),E.lit(Literal.nat(12009n))),
    "fork-keeps-index-appended-ID");
  must(get("psKernelExprV2OrdinaryConstructorContext")(analysis)===result.context,"fork-keeps-parameter-context");
  for(const failAt of [1,2,3,4])for(const decline of [false,true]){
    const failed=run(failAt,decline);
    must(same(failed.result,decline?none:Option.some(err("T05_CALLBACK_INJECTED"))),"decline-error-propagation");
    must(failed.trace.length===failAt,"no-callback-after-decline-error");
  }
}
const forbidden=_fuel=>_ctx=>_state=>_root=>{throw Error("T05_CALLBACK_FORBIDDEN");};
must(same(get("psKernelExprV2OrdinaryOpenHeaderIndicesWorker")(0n)(forbidden)(forbidden)(context)(initial)(999n)(nil),
  Option.some(err("simple inductive index budget exhausted"))),"index-zero-before-lookup-callback");
let terminalTrace=[];
const terminal=fuel=>_ctx=>state=>root=>{terminalTrace.push(fuel);return Option.some(ok({fst:state,snd:root}));};
const terminalResult=get("psKernelExprV2OrdinaryOpenHeaderParamsWith")(forbidden,terminal,0n,context,initial,sortId,0n);
must(same(terminalTrace,[0n])&&attempted(terminalResult,"terminal-parameter").result===sortId,"parameter-zero-still-whnfs-original-fuel");
terminalTrace=[];
const indexResult=get("psKernelExprV2OrdinaryOpenHeaderIndicesWith")(forbidden,terminal,0n,context,initial,sortId);
must(same(terminalTrace,[0n])&&attempted(indexResult,"index-predecessor").result===sortId,"public-index-supplies-predecessor");

section="phases";
function runPhases(failAt=0,decline=false){
  const trace=[];
  const callback=kind=>fuel=>ctx=>state=>root=>{
    const stage=trace.length+1;trace.push(kind);
    if(fuel!==7n||root!==sortId||kind!==(stage===1?"check":"whnf")||ctx!==context||!marker(state,BigInt(stage-1)))
      throw Error("T05_PHASE_WRONG_INPUT_OR_STALE_OWNER");
    if(stage===failAt)return decline?none:Option.some(err("T05_PHASE_INJECTED"));
    let next=stamp(state,BigInt(stage)),result=root;
    if(stage===4){
      const built=accepted(get("psKernelExprV2PagedMkSort")(next.whnf.arena,L.succ(one)),"new-index-sort");
      next=get("psKernelExprV2CheckStateWithArena")(next,built.fst);result=built.snd;
    }
    return Option.some(ok({fst:next,snd:result}));
  };
  return {trace,result:get("psKernelExprV2OrdinaryHeaderPhasesWith")(
    callback("check"),callback("whnf"),7n,context,initial,sortId,0n)};
}
const phaseSuccess=runPhases(),phaseAnalysis=attempted(phaseSuccess.result,"complete-header-phases");
must(phaseSuccess.trace.join(",")==="check,whnf,whnf,whnf","whole-header-mandatory-phase-order");
must(marker(phaseAnalysis.parameters.state,3n)&&marker(phaseAnalysis.indices.state,4n),"both-complete-phase-owners-retained");
must(same(phaseAnalysis.resultLevel,L.succ(one))&&exprExact(decode(phaseAnalysis.indices.state.whnf.arena,phaseAnalysis.indices.result),s2.expr),
  "finish-reads-actual-returned-index-sort");
const phaseFork=get("psKernelExprV2OrdinaryConstructorState")(phaseAnalysis);
must(marker(phaseFork,3n)&&exprExact(decode(phaseFork.whnf.arena,phaseAnalysis.indices.result),s2.expr),
  "actual-phase-fork-keeps-original-parameter-fields-and-new-index-ID");
for(const failAt of [1,2,3,4])for(const decline of [false,true]){
  const failed=runPhases(failAt,decline);
  must(same(failed.result,decline?none:Option.some(err("T05_PHASE_INJECTED"))),"complete-header-propagates-decline-error");
  must(failed.trace.length===failAt,"complete-header-stops-after-decline-error");
}

section="topCallbacks";
for(const failPhase of ["check","whnf"])for(const decline of [false,true]){
  const d=positives[0][1],b=build(d),trace=[];
  const check=fuel=>ctx=>state=>root=>{
    trace.push("check");
    return failPhase==="check"?(decline?none:Option.some(err("T05_TOP_INJECTED"))):Option.some(ok({fst:state,snd:root}));
  };
  const whnf=_fuel=>_ctx=>_state=>_root=>{trace.push("whnf");return decline?none:Option.some(err("T05_TOP_INJECTED"));};
  const result=get("psKernelExprV2OrdinaryAnalyzeHeaderWith")(check,whnf,4096n,env,0n,maxNat,b.arena,nil,nil,0n,b.value,false);
  must(same(result,decline?none:Option.some(err("T05_TOP_INJECTED")))&&
    trace.join(",")===(failPhase==="check"?"check":"check,whnf"),"top-short-circuit-"+failPhase);
}
for(const d of [negatives[0][1],collision,negatives[1][1],negatives[2][1]]){
  const b=build(d),old=frozenV1Header(4096n,env,d,0n);
  const result=get("psKernelExprV2OrdinaryAnalyzeHeaderWith")(forbidden,forbidden,4096n,env,0n,maxNat,b.arena,nil,list(d.levels),d.params,b.value,d.unsafe);
  must(rejected(old)&&same(result,Option.some(old)),"static-cross-fault-before-any-callback");
}

// Fixed inventory: each count is a committed test-table requirement, independent
// of implementation return values. Counts cover original repeated matrix cases.
const expected={harness:1,header:444,occurrence:1378,annotations:94,state:47,phases:20,topCallbacks:8};
if(!same(counts,expected)||assertions!==1992)throw Error("PSC1_ORDINARY_HEADER_ASSERTION_COUNT "+JSON.stringify(counts));
console.log("PSC1_ORDINARY_HEADER_JS: PASS "+JSON.stringify({assertions:1992,sectionAssertions:counts,headerCases:432,
  positiveDirect:10,occurrenceFuelCases:1026,annotationFuelCases:75,callbackSequences:3,
  callbackFailures:24,headerOnly:true,fullAdmission:false,publicFallbackUsed:false}));
