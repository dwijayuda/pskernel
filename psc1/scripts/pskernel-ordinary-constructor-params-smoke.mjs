import {pathToFileURL} from "node:url";
import path from "node:path";

// Private T05 constructor-parameter prefix only. The frozen V1 reference is
// Ordinary/Constructor.lean at 0d9f062846d109c362210d441df5fd407ca2cdd7,
// Git blob 56a70b8ac94283694bf375a8d5c8e7adfd3859b7. The workflow must bind
// that exact reference, both harnesses and the complete generated kernel.
// Direct rows use actual header owners and actual owned DefEq. Callback rows
// separately test the protocol; their semantic-cache stamps are not judgments.
if(process.argv.length!==3)throw Error("PSC1_CONSTRUCTOR_PARAMS_REQUIRES_GENERATED_KERNEL");
const kernelPath=path.resolve(process.argv[2]),k=await import(pathToFileURL(kernelPath).href);
const get=n=>{if(!(n in k))throw Error("PSC1_CONSTRUCTOR_PARAMS_MISSING_EXPORT "+n);return k[n];};
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
  throw Error("PSC1_CONSTRUCTOR_PARAMS_REJECTED "+label+": "+String(v?.error));
};
const attempted=(v,label)=>accepted(accepted(v,label+"/some"),label+"/ok");
const rejected=v=>v&&Object.hasOwn(v,"error");
let assertions=0,section="harness";
const counts={};
const must=(condition,label)=>{
  if(condition!==true)throw Error("PSC1_CONSTRUCTOR_PARAMS_JS_FAIL "+section+"/"+label);
  assertions++;counts[section]=(counts[section]??0)+1;
};
must(!same(ok("same"),err("same"))&&!same(none,Option.some(none)),"constructor-tags");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),Safety=get("PsKernelDefinitionSafety"),Node=get("PsKernelExprV2Node");
const name=s=>N.str(unit(N.anonymous),s);
const bi=unit(B.default),implicit=unit(B.implicit),strict=unit(B.strictImplicit),instance=unit(B.instImplicit);
const zero=unit(L.zero),one=L.succ(zero),u=name("CtorParamU"),v=name("CtorParamV");
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
const h1=all("A",s1,s1,implicit),h2=all("A",s1,all("B",s1,s1,strict),implicit);
const hd=all("A",s1,all("a",bv(0n),s1,strict),implicit),ctor=all("X",s1,bv(0n));
const out=unit(get("psKernelTypeAnnotationOutParamName"));
const rows=[
  ["empty",s1,0n,s1,[],true],
  ["one",h1,1n,ctor,[],true],
  ["renamed-info",h1,1n,all("Different",s1,bv(0n),instance),[],true],
  ["two-independent",h2,2n,all("X",s1,all("Y",s1,all("z",bv(1n),bv(1n)))),[],true],
  ["two-dependent",hd,2n,all("X",s1,all("x",bv(0n),bv(1n))),[],true],
  ["under-binder",h1,1n,all("X",s1,all("z",bv(0n),bv(1n))),[],true],
  ["metadata-body",h1,1n,all("X",s1,md(177n,all("z",bv(0n),bv(1n)))),[],true],
  ["let-body",h1,1n,all("X",s1,letE("T",s1,bv(0n),bv(0n))),[],true],
  ["beta-domain",h1,1n,all("X",app(lam("T",s2,bv(0n)),s1),bv(0n)),[],true],
  ["metadata-domain",h1,1n,all("X",md(178n,s1),bv(0n)),[],true],
  ["universe",all("A",sort(L.param(u)),sort(L.param(u))),1n,all("X",sort(L.param(u)),bv(0n)),[u],true],
  ["wrong-domain",h1,1n,all("X",s0,bv(0n)),[],false],
  ["fewer-at-root",h1,1n,s1,[],false],
  ["fewer-after-one",h2,2n,all("X",s1,s1),[],false],
  ["whole-metadata",h1,1n,md(179n,ctor),[],false],
  ["whole-beta",h1,1n,app(lam("T",s2,ctor),s1),[],false],
  ["whole-let",h1,1n,letE("T",s2,s1,ctor),[],false],
  ["whole-annotation",h1,1n,app(cn(out),ctor),[],false]
];
if(rows.length!==18||rows.filter(row=>row[5]).length!==11)throw Error("PSC1_CONSTRUCTOR_PARAMS_DIRECT_INVENTORY");
function prepare(row){
  const [label,header,numParams,constructor,levels]=row;
  const initial=get("psKernelMkCheckerSession")(env,list(levels),unit(Safety.safe),0n,maxNat);
  const checked=accepted(get("psKernelSessionCheck")(4096n,initial,header.expr),label+"/old-check");
  const sorted=accepted(get("psKernelSessionEnsureSort")(4096n,checked.snd,checked.fst),label+"/old-sort");
  const old=accepted(get("psKernelOpenSimpleHeaderParams")(4096n,sorted.snd,header.expr,numParams),label+"/old-params");
  const b=builder(),headerID=b.add(header);
  const analysis=attempted(get("psKernelExprV2OrdinaryAnalyzeHeaderWithFuel")(
    4096n,env,0n,maxNat,b.arena,nil,list(levels),numParams,{name:name("CtorParamHeader"),type:headerID,ctors:nil},false),label+"/header");
  const parameterState=get("psKernelExprV2OrdinaryConstructorState")(analysis);
  const cb=builder(parameterState.whnf.arena),root=cb.add(constructor);
  const state=get("psKernelExprV2CheckStateWithArena")(parameterState,cb.arena);
  // Actual checked builders supply the same internal canonical precondition as
  // the native fixture importer; no research importer is added to SelfHost.
  accepted(get("psKernelExprV2DecodeChecked")(state.whnf.arena),label+"/canonical-fixture");
  return {old,context:get("psKernelExprV2OrdinaryConstructorContext")(analysis),state,parameters:analysis.parameters.binders,root};
}
const sameResult=(old,actual)=>{
  if(!actual||!Object.hasOwn(actual,"value"))return false;
  const got=actual.value;
  if(rejected(old))return same(old,got);
  if(rejected(got))return false;
  const left=accepted(old,"old-result"),right=accepted(got,"new-result");
  return exprExact(left.result,decode(right.fst.whnf.arena,right.snd))&&left.session.state.nextFresh===right.fst.nextFresh;
};
section="direct";
for(const row of rows){
  const f=prepare(row),label=row[0],type=row[3].expr;
  for(const fuel of [0n,1n,2n,3n,8n,4096n]){
    const raw=get("psKernelExprV2OrdinaryOpenConstructorParamsWorker")(fuel)
      (get("psKernelExprV2TryDefEqStateWithFuel"))(f.context)(f.state)(f.parameters)(f.root);
    must(sameResult(get("psKernelOpenSimpleConstructorParamsWithFuel")(fuel)(f.old.session)(f.old.binders)(type),raw),label+"/worker/"+fuel);
    const wrapped=get("psKernelExprV2OrdinaryOpenConstructorParamsWithFuel")(fuel,f.context,f.state,f.parameters,f.root);
    must(sameResult(get("psKernelOpenSimpleConstructorParams")(fuel,f.old.session,f.old.binders,type),wrapped),label+"/wrapper/"+fuel);
  }
  if(row[5]){
    const old=accepted(get("psKernelOpenSimpleConstructorParams")(4096n,f.old.session,f.old.binders,type),label+"/old-direct");
    const actual=attempted(get("psKernelExprV2OrdinaryOpenConstructorParamsWithFuel")(
      4096n,f.context,f.state,f.parameters,f.root),label+"/required-direct");
    must(exprExact(old.result,decode(actual.fst.whnf.arena,actual.snd))&&actual.fst.nextFresh===f.state.nextFresh&&
      old.session.state.nextFresh===f.old.session.state.nextFresh&&
      old.session.context.localContext.nextIndex===f.old.session.context.localContext.nextIndex&&
      array(old.session.context.localContext.decls).length===array(f.old.session.context.localContext.decls).length,
      label+"/positive-direct-no-local-or-fresh-allocation");
  }
}

section="protocol";
const proto=prepare(["sentinel",hd,2n,all("X",s1,all("x",bv(0n),app(bv(1n),bv(0n)))),[],true]);
const parameters=array(proto.parameters),modulus=unit(get("psKernelCacheHashModulus"));
const semantic=state=>({nextFresh:state.nextFresh,checkedInfer:state.checkedInfer,success:state.success,
  inferOnly:state.inferOnly,unfold:state.unfold,failure:state.failure,coreCache:state.whnf.coreCache,
  publicCache:state.whnf.publicCache,declarations:state.whnf.declarations});
const extendsArena=(after,before)=>{
  if(after.size<before.size)return false;
  for(let id=0n;id<before.size;id++)
    if(!same(get("psKernelExprV2PagedFind")(after,id),get("psKernelExprV2PagedFind")(before,id)))return false;
  return true;
};
function stamp(state,tag,owners){
  let arena=state.whnf.arena;
  const ids=[];
  for(let field=0n;field<8n;field++){
    const built=accepted(get("psKernelExprV2PagedMkLit")(arena,Literal.nat(13000n+100n*tag+field)),"marker");
    arena=built.fst;ids.push(built.snd);
  }
  const cache=field=>list([{source:parameters[0].type,result:ids[field],hash:modulus+100n*tag+BigInt(field)}]);
  const pair=field=>list([{left:parameters[0].type,right:ids[field],hash:modulus+100n*tag+BigInt(field)}]);
  const stamped={whnf:{arena,coreCache:cache(0),publicCache:cache(1),declarations:list([
    {name:N.num(name("private-state-marker"),tag),levelParams:nil,type:parameters[0].type,
      deltaValue:Option.some(ids[7]),kind:unit(get("PsKernelExprV2DeclarationRefKind").definitionDecl)}])},
    nextFresh:100n+10n*tag,checkedInfer:cache(2),inferOnly:cache(3),unfold:cache(4),success:pair(5),failure:pair(6)};
  owners.set(tag,stamped);return stamped;
}
const marker=(actual,expected)=>same(semantic(actual),semantic(expected))&&extendsArena(actual.whnf.arena,expected.whnf.arena);
function runProtocol(failAt=0,outcome="error"){
  const trace=[],owners=new Map(),initial=stamp(proto.state,0n,owners);
  const callback=fuel=>ctx=>state=>left=>right=>{
    const stage=trace.length+1;
    if(stage>2||fuel!==8n-BigInt(stage)||ctx!==proto.context||right!==parameters[stage-1].type||
      !marker(state,owners.get(BigInt(stage-1)))||
      !exprExact(decode(state.whnf.arena,left),stage===1?s1.expr:E.fvar(parameters[0].internalName)))
      throw Error("PSC1_CONSTRUCTOR_PARAMS_CALLBACK_INPUT stage="+stage);
    trace.push({fuel,ctx,left,right});
    if(stage===failAt){
      if(outcome==="decline")return none;
      if(outcome==="error")return Option.some(err("CTOR_PARAMS_INJECTED"));
      return Option.some(ok({fst:stamp(state,BigInt(stage),owners),snd:false}));
    }
    return Option.some(ok({fst:stamp(state,BigInt(stage),owners),snd:true}));
  };
  return {trace,owners,initial,result:get("psKernelExprV2OrdinaryOpenConstructorParamsWith")(
    callback,7n,proto.context,initial,proto.parameters,proto.root)};
}
const success=runProtocol(),result=attempted(success.result,"protocol"),last=success.owners.get(2n);
must(success.trace.length===2&&same(success.trace.map(x=>x.fuel),[7n,6n]),"predecessor-fuel-order");
must(same(semantic(result.fst),semantic(last)),"every-distinct-owner-field");
must(exprExact(decode(result.fst.whnf.arena,result.snd),E.app(E.fvar(parameters[0].internalName),E.fvar(parameters[1].internalName))),
  "dependent-substitution-uses-existing-names");
must(success.trace.every(x=>x.ctx===proto.context)&&array(proto.context.locals).length===2,"same-context-no-local-extension");
must(result.fst.whnf.arena.size>last.whnf.arena.size,"extends-complete-returned-owner");
must(result.fst.nextFresh===120n,"no-fresh-name-allocation");
must(["checkedInfer","inferOnly","unfold","success","failure"].every(field=>result.fst[field]===last[field])&&
  ["coreCache","publicCache","declarations"].every(field=>result.fst.whnf[field]===last.whnf[field]),"preserves-owner-field-identities");
must(extendsArena(result.fst.whnf.arena,last.whnf.arena)&&extendsArena(result.fst.whnf.arena,success.initial.whnf.arena),
  "old-and-callback-appended-IDs-survive");
const mismatch="simple inductive constructor parameter does not match the datatype parameter";
const budget="simple inductive constructor parameter budget exhausted";
const fewer="simple inductive constructor has fewer parameters than the datatype";
for(const failAt of [1,2])for(const outcome of ["decline","error","false"]){
  const failed=runProtocol(failAt,outcome);
  must(same(failed.result,outcome==="decline"?none:Option.some(err(outcome==="error"?"CTOR_PARAMS_INJECTED":mismatch))),
    "callback-"+outcome+"-propagation");
  must(failed.trace.length===failAt,"no-callback-after-"+outcome);
}

section="boundaries";
const single=prepare(rows[1]),singleParameter=single.parameters;
const forbidden=_fuel=>_ctx=>_state=>_left=>_right=>{throw Error("CTOR_PARAMS_FORBIDDEN_CALLBACK");};
const worker=(fuel,callback,fixture,pars,root)=>get("psKernelExprV2OrdinaryOpenConstructorParamsWorker")
  (fuel)(callback)(fixture.context)(fixture.state)(pars)(root);
const withCallback=(fuel,callback,fixture,pars,root)=>get("psKernelExprV2OrdinaryOpenConstructorParamsWith")
  (callback,fuel,fixture.context,fixture.state,pars,root);
must(same(worker(0n,forbidden,single,nil,999999n),Option.some(err(budget))),"zero-before-empty-invalid-root");
must(same(worker(0n,forbidden,single,singleParameter,999999n),Option.some(err(budget))),"zero-before-nonempty-invalid-root");
must(same(worker(1n,forbidden,single,nil,999999n),Option.some(ok({fst:single.state,snd:999999n}))),"successor-empty-no-lookup");
must(same(withCallback(0n,forbidden,single,nil,999999n),Option.some(ok({fst:single.state,snd:999999n}))),"wrapper-zero-empty-identity");
let calls=[];
const positive=fuel=>_ctx=>state=>left=>right=>{calls.push({fuel,left,right});return Option.some(ok({fst:state,snd:true}));};
const atOne=worker(1n,positive,single,singleParameter,single.root);
must(same(atOne,Option.some(err(budget))),"one-step-reaches-zero-before-empty-tail");
must(calls.length===1&&calls[0].fuel===0n,"one-step-callback-predecessor-zero");
calls=[];
const atTwo=worker(2n,positive,single,singleParameter,single.root),atTwoValue=attempted(atTwo,"two-units");
must(calls.length===1&&calls[0].fuel===1n&&atTwoValue.fst.nextFresh===single.state.nextFresh&&
  exprExact(decode(atTwoValue.fst.whnf.arena,atTwoValue.snd),E.fvar(array(singleParameter)[0].internalName)),"two-units-finish-one-parameter");
calls=[];
must(same(withCallback(1n,positive,single,singleParameter,single.root),atTwo)&&calls.length===1,"wrapper-adds-one-exactly");
const boundaryBuilder=builder(single.state.whnf.arena),nonforall=boundaryBuilder.add(s1),metadata=boundaryBuilder.add(md(179n,ctor)),
  annotation=boundaryBuilder.add(app(cn(out),ctor));
const boundary={...single,state:get("psKernelExprV2CheckStateWithArena")(single.state,boundaryBuilder.arena)};
must(same(worker(4n,forbidden,boundary,singleParameter,nonforall),Option.some(err(fewer))),"syntactic-nonforall-before-callback");
must(same(worker(4n,forbidden,boundary,singleParameter,metadata),Option.some(err(fewer))),"no-metadata-peeling");
must(same(worker(4n,forbidden,boundary,singleParameter,annotation),Option.some(err(fewer))),"no-annotation-consumption");
must(same(worker(4n,forbidden,boundary,singleParameter,999999n),Option.some(err("PSKERNEL_V2_PAGED_INVALID_CHILD"))),"lookup-error-before-callback");
const late=prepare(rows[13]);calls=[];
must(same(withCallback(7n,positive,late,late.parameters,late.root),Option.some(err(fewer)))&&calls.length===1,"fewer-after-first-substitution");
calls=[];
must(same(withCallback(0n,positive,single,singleParameter,single.root),Option.some(err(budget)))&&
  calls.length===1&&calls[0].fuel===0n,"wrapper-zero-calls-before-empty-tail-budget");

section="faults";
// Deliberately broken callback owners test error propagation only. They are
// outside canonical owner lineage and never count as positive admission rows.
let faultCalls=0;
const broken=equal=>_fuel=>_ctx=>state=>_left=>_right=>{
  faultCalls++;
  return Option.some(ok({fst:get("psKernelExprV2CheckStateWithArena")(state,empty),snd:equal}));
};
must(same(withCallback(7n,broken(true),single,singleParameter,single.root),Option.some(err("PSKERNEL_V2_TRANSFORM_BAD_ROOT"))),
  "instantiate-error-uses-returned-owner");
must(faultCalls===1,"instantiate-error-stops-after-one-callback");
faultCalls=0;
must(same(withCallback(7n,broken(false),single,singleParameter,single.root),Option.some(err(mismatch)))&&faultCalls===1,
  "false-before-broken-owner-instantiation");
const injected=_fuel=>_ctx=>_state=>_left=>_right=>Option.some(err("CTOR_PARAMS_FAULT_INJECTED"));
must(same(withCallback(7n,injected,single,singleParameter,single.root),Option.some(err("CTOR_PARAMS_FAULT_INJECTED"))),"error-before-instantiation");
const declined=_fuel=>_ctx=>_state=>_left=>_right=>none;
must(same(withCallback(7n,declined,single,singleParameter,single.root),none),"decline-before-instantiation");
faultCalls=0;
must(same(withCallback(7n,broken(true),proto,proto.parameters,proto.root),Option.some(err("PSKERNEL_V2_TRANSFORM_BAD_ROOT")))&&faultCalls===1,
  "instantiation-error-precedes-second-parameter");

const expectedCounts={harness:1,direct:227,protocol:20,boundaries:14,faults:6};
if(assertions!==268||!same(counts,expectedCounts))
  throw Error("PSC1_CONSTRUCTOR_PARAMS_ASSERTION_INVENTORY "+JSON.stringify({assertions,counts}));
console.log("PSC1_ORDINARY_CONSTRUCTOR_PARAMS_JS: PASS assertions=268 fullAdmission=false");
console.log(JSON.stringify({schema:"psc1-ordinary-constructor-params-v1",kernel:kernelPath,assertions,
  sectionAssertions:counts,directFixtures:18,fuelValues:6,interfaces:2,directComparisons:216,positiveDirect:11,
  fullAdmission:false,publicRoutingChanged:false}));
