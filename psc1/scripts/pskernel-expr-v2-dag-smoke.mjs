import { pathToFileURL } from "node:url";
import { performance } from "node:perf_hooks";
import { readFileSync, statSync } from "node:fs";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_DAG_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{
  if(!(name in k))throw Error("PSC1_DAG_MISSING_EXPORT "+name);
  return k[name];
};
const must=(ok,label)=>{
  if(ok!==true)throw Error("PSC1_DAG_FAILED "+label+" result-type="+typeof ok);
  console.log("PSC1_DAG_PASS "+label);
};
const accepted=(r,label)=>{
  if(r&&typeof r==="object"&&"value" in r)return r.value;
  throw Error("PSC1_DAG_REJECTED "+label+" "+JSON.stringify(r,(_,v)=>typeof v==="bigint"?String(v):v));
};
const rejected=r=>r&&typeof r==="object"&&"error" in r;
const N=get("PsKernelName"),L=get("PsKernelLevel"),E=get("PsKernelExpr");
const B=get("PsKernelBinderInfo"),S=get("PsKernelDefinitionSafety");
const C=get("PsKernelDagCommand"),D=get("PsKernelDagDeclarationRequest");
const List=get("List"),nil=typeof List.nil==="function"?List.nil():List.nil;
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{
  const result=[];
  while(xs&&typeof xs==="object"&&"head" in xs){
    result.push(xs.head); xs=xs.tail;
  }
  return result;
};
const name=s=>N.str(N.anonymous,s);
const sort0=E.sort(L.zero),sort1=E.sort(L.succ(L.zero));
const equal=(left,right)=>get("psKernelExprEq")(left)(right);
const exact=(left,right)=>get("psKernelExprEqual")(left)(right);
must(equal(sort0,sort0)===true&&equal(sort0,sort1)===false&&
  exact(sort0,sort0)===true&&exact(sort0,sort1)===false,
  "equality-harness-rejects-unequal-terms");

{
  const x=name("equality-x"), y=name("equality-y");
  let deep=E.bvar(0n);
  for(let i=0;i<64;i++)deep=E.app(deep,deep);
  const hostile=[
    ["outer-tag",deep,sort0],
    ["app-first-child",E.app(sort0,deep),E.app(sort1,deep)],
    ["lam-type",E.lam(x,sort0,deep,B.default),E.lam(x,sort1,deep,B.default)],
    ["forall-type",E.forallE(x,sort0,deep,B.default),E.forallE(x,sort1,deep,B.default)],
    ["let-type",E.letE(x,sort0,deep,deep,false),E.letE(x,sort1,deep,deep,false)],
    ["let-value",E.letE(x,sort0,sort0,deep,false),E.letE(x,sort0,sort1,deep,false)],
    ["mdata-tag",E.mdata(7n,deep),E.mdata(8n,deep)],
    ["projection-name",E.proj(x,0n,deep),E.proj(y,0n,deep)],
    ["projection-index",E.proj(x,0n,deep),E.proj(x,1n,deep)],
  ];
  for(const [label,left,right] of hostile){
    must(equal(left,right)===false,"delayed-exprEq-"+label);
    must(exact(left,right)===false,"delayed-exprEqual-"+label);
  }
  must(exact(E.lam(x,deep,deep,B.default),E.lam(y,deep,deep,B.default))===false,
    "delayed-exact-lam-name");
  must(exact(E.forallE(x,deep,deep,B.default),E.forallE(y,deep,deep,B.default))===false,
    "delayed-exact-forall-name");
  must(exact(E.letE(x,deep,deep,deep,false),E.letE(y,deep,deep,deep,false))===false,
    "delayed-exact-let-name");
  for(const exportName of ["psKernelExprEq","psKernelExprEqual"]){
    const partial=get(exportName)(deep);
    must(typeof partial==="function"&&partial(sort0)===false,
      "delayed-staged-abi-"+exportName);
  }
  console.log("PSC1_EXPR_EQUALITY_DELAYED_JS: PASS hostile=21 staged=2 sharedDepth=64");
}
const run=get("psKernelV1RunDag");
const session=(fuel=4096n,depth=0n)=>accepted(
  get("psKernelKernelSessionEmpty")(
    {...get("psKernelResourcePolicyDefault"),fuel,maxRecDepth:depth},
    get("psKernelProviderDefault")),"empty-session");
const invoke=(a,commands,s=session())=>run(s,nil,S.safe,a,list(commands));
const empty=get("psKernelExprV2PagedEmpty");
const mk=(arena,kind,...args)=>accepted(
  get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
const decode=get("psKernelExprV2DecodeChecked");
const decoded=get("psKernelExprV2DecodedRequire");

let arena=empty;
const ids={};
const add=(key,kind,...args)=>{
  const result=mk(arena,kind,...args);
  arena=result.fst; ids[key]=result.snd; return result.snd;
};
add("s0","Sort",L.zero);
add("s1","Sort",L.succ(L.zero));
add("b0","BVar",0n);
add("f","FVar",name("f"));
add("m","MVar",name("m"));
add("const","Const",name("C"),nil);
add("app","App",ids.b0,ids.b0);
add("lam","Lam",name("x"),ids.s1,ids.b0,B.implicit);
add("forall","Forall",name("x"),ids.s1,ids.b0,B.strictImplicit);
add("let","Let",name("x"),ids.s1,ids.s0,ids.b0,true);
add("nat","Lit",get("PsKernelLiteral").nat(15n));
add("str","Lit",get("PsKernelLiteral").str("λ-雪"));
add("mdata","MData",73n,ids.b0);
add("proj","Proj",name("S"),2n,ids.b0);

{
  // Fuel remains the first staged ABI argument in these compatibility exports.
  // Real kernel state and a valid sort exercise both zero and successor arms.
  const scalar=get("psKernelKernelSessionChecker")(session(),nil,S.safe).context;
  const state=get("psKernelExprV2WhnfStateEmpty")(arena);
  const absent=get("Option").none;
  const localValue=_name=>absent;
  const forbidden=_context=>_state=>_root=>{throw Error("STAGED_WHNF_UNEXPECTED_CALLBACK");};
  let partials=0,executions=0;
  for(const fuel of [0n,1n]){
    const core=get("psKernelExprV2TryWhnfCoreModeWithLocalValuesFuel")(fuel);
    const publicWhnf=get("psKernelExprV2TryWhnfStateWithLocalValuesFuel")(fuel);
    must(typeof core==="function"&&typeof publicWhnf==="function","whnf-staged-fuel-arity-"+fuel);
    partials+=2;
    const values=[core(false)(localValue)(forbidden)(scalar)(state)(ids.s0),
      core(true)(localValue)(forbidden)(scalar)(state)(ids.s0),
      publicWhnf(localValue)(scalar)(state)(ids.s0)];
    for(const value of values){
      const result=accepted(value,"whnf-staged-attempt-"+fuel);
      if(fuel===0n)must(rejected(result)&&result.error==="kernel reduction budget exhausted",
        "whnf-staged-zero-error");
      else{
        const reduced=accepted(result,"whnf-staged-success");
        const built=accepted(decode(reduced.fst.arena),"whnf-staged-arena");
        must(exact(accepted(decoded(built,reduced.snd),"whnf-staged-result"),sort0)===true,
          "whnf-staged-successor-result");
      }
      executions++;
    }
  }
  must(partials===4&&executions===6,"whnf-staged-complete");
  console.log("PSC1_V2_DAG_JS_WHNF_STAGED_ABI: PASS exports=2 partials=4 executions=6");
}
const terms={
  s0:sort0,s1:sort1,b0:E.bvar(0n),f:E.fvar(name("f")),m:E.mvar(name("m")),
  const:E.const(name("C"),nil),app:E.app(E.bvar(0n),E.bvar(0n)),
  lam:E.lam(name("x"),sort1,E.bvar(0n),B.implicit),
  forall:E.forallE(name("x"),sort1,E.bvar(0n),B.strictImplicit),
  let:E.letE(name("x"),sort1,sort0,E.bvar(0n),true),
  nat:E.lit(get("PsKernelLiteral").nat(15n)),
  str:E.lit(get("PsKernelLiteral").str("λ-雪")),
  mdata:E.mdata(73n,E.bvar(0n)),proj:E.proj(name("S"),2n,E.bvar(0n))
};
const built=accepted(decode(arena),"all-constructor-decode");
for(const [key,id] of Object.entries(ids)){
  must(exact(accepted(decoded(built,id),"read-"+key),terms[key]),"exact-decode-"+key);
}
const shared=accepted(decoded(built,ids.app),"shared-app");
must(shared.fn!==undefined&&shared.fn===shared.arg,"decoder-preserves-physical-child-sharing");
must(built.size===arena.size,"each-unique-node-decoded-once");

// Constructor tags are Symbol properties in the authentic TypeScript backend.
// Error parity must preserve them, including nested resource-kind variants.
const sameRuntimeValue=(left,right)=>{
  if(left===right)return true;
  if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
  const keys=Reflect.ownKeys(left),otherKeys=Reflect.ownKeys(right);
  return keys.length===otherKeys.length&&keys.every(key=>
    Object.hasOwn(right,key)&&sameRuntimeValue(left[key],right[key]));
};
{
  const ErrorKind=get("PsKernelError"),Resource=get("PsKernelResourceError");
  const message="identical error payload";
  const errors=[
    ErrorKind.rejectedInvalid(message),ErrorKind.declinedUnsupported(message),
    ErrorKind.internalError(message),
    ...["fuel","recursionDepth","natSize","cancelled","declarationLimit","hostStack"]
      .map(kind=>ErrorKind.resourceExhausted(Resource[kind],message))
  ];
  for(let i=0;i<errors.length;i++)for(let j=0;j<errors.length;j++)
    must(sameRuntimeValue(errors[i],errors[j])===(i===j),
      "exact-public-error-tag-matrix-"+i+"-"+j);
  must(!sameRuntimeValue(ErrorKind.resourceExhausted(Resource.fuel,"a"),
    ErrorKind.resourceExhausted(Resource.fuel,"b")),"exact-public-error-message");

  must(!sameRuntimeValue(ErrorKind.rejectedInvalid(message),ErrorKind.declinedUnsupported(message)),
    "error-parity-preserves-symbol-constructor-kind");
  must(!sameRuntimeValue(ErrorKind.resourceExhausted(Resource.fuel,message),
    ErrorKind.resourceExhausted(Resource.cancelled,message)),
    "error-parity-preserves-nested-resource-kind");
  must(sameRuntimeValue(ErrorKind.resourceExhausted({...Resource.fuel},message),
    ErrorKind.resourceExhausted({...Resource.fuel},message)),
    "error-parity-compares-distinct-equivalent-resource-records");
}
const checkedResult=r=>{
  if(rejected(r))return {error:r.error};
  const replies=array(accepted(r,"batch-result").replies);
  if(replies.length!==1)throw Error("PSC1_DAG_WRONG_REPLY_COUNT");
  return {value:replies[0].value};
};
const sameOperation=(original,actual,compare)=>{
  if(rejected(original))return rejected(actual)&&sameRuntimeValue(original.error,actual.error);
  if(rejected(actual))return false;
  const expected=accepted(original,"legacy-operation");
  const replies=array(accepted(actual,"dag-operation").replies);
  return replies.length===1&&compare(expected,replies[0].value)===true;
};
for(const [key,id] of Object.entries(ids)){
  for(const fuel of [0n,1n,2n,4n,16n]){
    const s=session(fuel);
    const original=get("psKernelV1CheckExpression")(s,nil,S.safe,terms[key]);
    const actual=checkedResult(invoke(arena,[C.check(id)],s));
    if(rejected(original)){
      must(rejected(actual)&&sameRuntimeValue(original.error,actual.error),
        "same-negative-and-resource-"+key+"-"+fuel);
    }else{
      const expected=accepted(original,"legacy-check");
      must(!rejected(actual)&&exact(actual.value.type,expected.type)&&
        exact(actual.value.expression,expected.expression),
        "same-complete-check-"+key+"-"+fuel);
    }
    must(sameOperation(get("psKernelV1Whnf")(s,nil,S.safe,terms[key]),
      invoke(arena,[C.whnf(id)],s),exact),"same-whnf-resource-"+key+"-"+fuel);
    must(sameOperation(get("psKernelV1IsDefEq")(s,nil,S.safe,terms[key],terms[key]),
      invoke(arena,[C.isDefEq(id,id)],s),(a,b)=>a===b),
      "same-checked-identity-resource-"+key+"-"+fuel);
  }
}

for(const depth of [0,8,16,17,32,64]){
  let graph=mk(empty,"Sort",L.zero),term=sort0;
  for(let tag=0;tag<depth;tag++){
    graph=mk(graph.fst,"MData",BigInt(tag),graph.snd);
    term=E.mdata(BigInt(tag),term);
  }
  for(const fuel of [1n,BigInt(depth),BigInt(depth+1),4096n]){
    for(const recDepth of [0n,1n,4n]){
      const s=session(fuel,recDepth);
      const original=get("psKernelV1CheckExpression")(s,nil,S.safe,term);
      const actual=checkedResult(invoke(graph.fst,[C.check(graph.snd)],s));
      if(rejected(original)){
        must(rejected(actual)&&sameRuntimeValue(original.error,actual.error),
          "metadata-resource-parity-"+depth+"-"+fuel+"-"+recDepth);
      }else{
        must(!rejected(actual)&&equal(actual.value.type,sort1),
          "dag-native-metadata-check-"+depth+"-"+fuel+"-"+recDepth);
      }
      must(sameOperation(get("psKernelV1Whnf")(s,nil,S.safe,term),
        invoke(graph.fst,[C.whnf(graph.snd)],s),exact),
        "metadata-whnf-resource-"+depth+"-"+fuel+"-"+recDepth);
      must(sameOperation(get("psKernelV1IsDefEq")(s,nil,S.safe,term,term),
        invoke(graph.fst,[C.isDefEq(graph.snd,graph.snd)],s),(a,b)=>a===b),
        "metadata-identity-resource-"+depth+"-"+fuel+"-"+recDepth);
    }
  }
}

add("id","Lam",N.anonymous,ids.s1,ids.b0,B.default);
add("beta","App",ids.id,ids.s0);
add("zeta","Let",N.anonymous,ids.s1,ids.s0,ids.b0,false);
add("illtyped","App",ids.s0,ids.s0);
for(const root of [ids.beta,ids.zeta]){
  const result=accepted(invoke(arena,[
    C.check(root),C.whnf(root),C.isDefEq(root,ids.s0)]),"complete-operations");
  const replies=array(result.replies);
  must(replies.length===3&&equal(replies[0].value.type,sort1)&&
    equal(replies[1].value,sort0)&&replies[2].value===true,
    "complete-independent-check-whnf-defeq");
}
const different=accepted(invoke(arena,[C.isDefEq(ids.s0,ids.s1)]),"negative-defeq");
must(array(different.replies)[0].value===false,"negative-defeq");
must(rejected(invoke(arena,[C.isDefEq(ids.illtyped,ids.illtyped)])),
  "equal-node-id-still-requires-full-type-check");
must(rejected(invoke(arena,[C.check(arena.size)])),"invalid-root-rejected");

add("collision0","Lit",get("PsKernelLiteral").nat(0n));
add("collision1","Lit",get("PsKernelLiteral").nat(65521n));
const collisionLeft=accepted(get("psKernelExprV2PagedRequire")(arena,ids.collision0),"collision-left");
const collisionRight=accepted(get("psKernelExprV2PagedRequire")(arena,ids.collision1),"collision-right");
must(collisionLeft.hash===collisionRight.hash,"real-closed-term-hash-collision");
must(accepted(get("psKernelExprV2PagedEqChecked")(arena,ids.collision0,ids.collision1),"collision-equality")===false,
  "collision-never-proves-structural-equality");
for(const fuel of [0n,1n,2n,4n,16n]){
  const current=session(fuel);
  must(sameOperation(get("psKernelV1IsDefEq")(current,nil,S.safe,
    E.lit(get("PsKernelLiteral").nat(0n)),E.lit(get("PsKernelLiteral").nat(65521n))),
    invoke(arena,[C.isDefEq(ids.collision0,ids.collision1)],current),(a,b)=>a===b),
    "closed-collision-defeq-resource-"+fuel);
}
const collisionAnswer=accepted(invoke(arena,[C.isDefEq(ids.collision0,ids.collision1)]),"collision-defeq");
must(array(collisionAnswer.replies)[0].value===false,"collision-does-not-authorize-defeq");
add("alphaA","Lam",name("alpha-a"),ids.s1,ids.b0,B.default);
add("alphaB","Lam",name("alpha-b"),ids.s1,ids.b0,B.implicit);
const alphaAnswer=accepted(invoke(arena,[C.isDefEq(ids.alphaA,ids.alphaB)]),"alpha-defeq");
must(ids.alphaA!==ids.alphaB&&array(alphaAnswer.replies)[0].value===true,"distinct-id-structural-shortcut");
add("tagA","MData",0n,ids.s0);
add("tagB","MData",65521n,ids.s0);
must(accepted(get("psKernelExprV2PagedEqChecked")(arena,ids.tagA,ids.tagB),"tags-syntax")===false,
  "metadata-tags-structurally-distinct");
const tagAnswer=accepted(invoke(arena,[C.isDefEq(ids.tagA,ids.tagB)]),"tags-defeq");
must(array(tagAnswer.replies)[0].value===true,"structural-false-still-uses-full-defeq");
add("badCopy","App",ids.s0,ids.s0);
must(rejected(invoke(arena,[C.isDefEq(ids.illtyped,ids.badCopy)])),
  "distinct-ids-with-equal-illtyped-syntax-rejected");

const fEntry=accepted(get("psKernelExprV2PagedRequire")(arena,ids.f),"fvar-entry");
for(const changes of [
  {hash:fEntry.hash+1n},{looseRange:1n},{hasFVar:false},
  {hasExprMVar:true},{depth:0n}
]){
  const forged=get("psKernelExprV2PagedPush")(empty,{...fEntry,...changes}).fst;
  must(rejected(invoke(forged,[C.check(0n)])),"forged-metadata-"+Object.keys(changes)[0]);
}
for(const malformed of [
  {...arena,size:arena.size+1n},{...arena,pageLimit:0n},
  {...arena,pages:[arena.active],active:[]}
]){
  must(rejected(invoke(malformed,[C.check(0n)])),"malformed-layout");
}
const cyclic=get("psKernelExprV2PagedPush")(empty,{
  ...fEntry,node:get("PsKernelExprV2Node").mdata(0n,0n)}).fst;
must(rejected(invoke(cyclic,[C.check(0n)])),"cycle-rejected");
const siblingGood=mk(empty,"Sort",L.zero);
const siblingBad=mk(empty,"MVar",name("bad"));
accepted(invoke(siblingGood.fst,[C.check(siblingGood.snd)]),"sibling-good");
must(siblingGood.snd===siblingBad.snd&&
  rejected(invoke(siblingBad.fst,[C.check(siblingBad.snd)])),"no-cross-arena-verdict");

const alias=name("DagAlias");
add("alias","Const",alias,nil);
const definition={base:{name:alias,levelParams:nil,type:ids.s1},
  value:ids.s0,hints:get("PsKernelReducibilityHints").abbrevHint,safety:S.safe};
const unitName=name("DagUnit"),ctorName=N.str(unitName,"mk");
add("unit","Const",unitName,nil);
add("ctor","Const",ctorName,nil);
const inductive={name:unitName,type:ids.s1,
  ctors:list([{name:ctorName,type:ids.unit}])};
const commands=[
  C.admit(D.definitionDecl(definition)),C.whnf(ids.alias),
  C.admit(D.ordinaryInductive(nil,0n,inductive,false)),C.check(ids.ctor)
];
const admitted=accepted(invoke(arena,commands),"declaration-batch");
const replies=array(admitted.replies);
must(replies.length===4&&equal(replies[1].value,sort0)&&
  equal(replies[3].value.type,E.const(unitName,nil)),"real-definition-and-inductive-admission");
must(rejected(invoke(arena,[C.admit(D.definitionDecl({
  ...definition,base:{...definition.base,type:ids.s0}}))])),"invalid-definition");
must(rejected(invoke(arena,[C.admit(D.definitionDecl(definition)),
  C.admit(D.definitionDecl(definition))])),"duplicate-declaration");
const bounded=session();
bounded.resources={...bounded.resources,maxDeclarations:1n};
must(rejected(invoke(arena,commands,bounded)),"declaration-limit-preserved");
must(get("psKernelEnvironmentSize")(session().environment)===0n,
  "failed-batch-has-no-external-mutation");

let pages=empty;
for(let i=0;i<257;i++)pages=mk(pages,"BVar",BigInt(i)).fst;
const pagedDecoded=accepted(decode(pages),"pages-decode");
must(pagedDecoded.size===257n&&pagedDecoded.pages.length===4,"paged-decoder-growth");
for(const id of [0n,63n,64n,127n,128n,255n,256n]){
  must(exact(accepted(decoded(pagedDecoded,id),"page-boundary"),E.bvar(id)),
    "page-boundary-"+id);
}
// Portable DAG transformations: exact legacy parity and scoped memoization.
{
  const T=get("PsKernelExprV2Transform");
  const inst=get("psKernelExprV2PagedInstantiateAtChecked");
  const instRev=get("psKernelExprV2PagedInstantiateRevChecked");
  const abstract=get("psKernelExprV2PagedAbstractFVarsAtChecked");
  const levels=get("psKernelExprV2PagedInstantiateLevelParamsChecked");
  const bounded=get("psKernelExprV2TransformCheckedWithFuel");
  const originalInst=get("psKernelExprInstantiateAt");
  const originalRev=get("psKernelExprInstantiateRev");
  const originalAbstract=get("psKernelExprAbstractFVarsAt");
  // Declared entry arguments are flat; returned function values consume
  // one argument per arrow. Keep the strict unapplied-oracle guard below.
  const originalInstFuel=(fuel,term,start,values,offset)=>
    get("psKernelExprInstantiateAtChangedWithFuel")(fuel)(term)(start)(values)(offset).fst;
  const originalAbstractFuel=(fuel,term,names,offset)=>
    get("psKernelExprAbstractFVarsAtChangedWithFuel")(fuel)(term)(names)(offset).fst;
  const originalLevels=(term,params,values)=>
    get("psKernelExprInstantiateLevelParams")(term)(params)(values);
  let comparisons=0;
  const readGraph=(graph,label)=>accepted(
    decoded(accepted(decode(graph.fst),label+"-decode"),graph.snd),label+"-root");
  const parity=(label,result,expected)=>{
    if(!expected||typeof expected!=="object")throw Error("PSC1_TRANSFORM_UNAPPLIED_ORACLE "+label);
    const graph=accepted(result,label);
    must(exact(readGraph(graph,label),expected)===true,label);
    comparisons++;
    return graph;
  };
  let ta=arena;
  const append=(kind,...args)=>{
    const r=mk(ta,kind,...args);ta=r.fst;return r.snd;
  };
  const b2=append("BVar",2n);
  const u=name("transform-u"),v=name("transform-v");
  const uSort=append("Sort",L.param(u));
  const uConst=append("Const",name("Poly"),list([L.param(u),L.succ(L.param(u))]));
  const body=append("App",b2,ids.f);
  const inner=append("Lam",name("inner"),uSort,body,B.instImplicit);
  const nested=append("Forall",name("outer"),uSort,inner,B.strictImplicit);
  const nestedLet=append("Let",name("let"),uSort,b2,inner,true);
  const fixtureCases=Object.entries(terms).map(([key,term])=>({key,root:ids[key],term}));
  fixtureCases.push(
    {key:"universe-sort",root:uSort,term:E.sort(L.param(u))},
    {key:"universe-constant",root:uConst,term:E.const(name("Poly"),list([L.param(u),L.succ(L.param(u))]))},
    {key:"nested-binders",root:nested,term:E.forallE(name("outer"),E.sort(L.param(u)),
      E.lam(name("inner"),E.sort(L.param(u)),E.app(E.bvar(2n),terms.f),B.instImplicit),B.strictImplicit)},
    {key:"nested-let",root:nestedLet,term:E.letE(name("let"),E.sort(L.param(u)),E.bvar(2n),
      E.lam(name("inner"),E.sort(L.param(u)),E.app(E.bvar(2n),terms.f),B.instImplicit),true)}
  );
  const substitutions=[
    {ids:[],terms:[]},
    {ids:[b2],terms:[E.bvar(2n)]},
    {ids:[ids.s0,b2,ids.f],terms:[sort0,E.bvar(2n),terms.f]}
  ];
  const names=list([name("f"),name("unused"),name("f")]);
  for(const fixture of fixtureCases){
    for(let variant=0;variant<substitutions.length;variant++){
      const values=substitutions[variant],refs=list(values.ids),replacements=list(values.terms);
      for(const start of [0n,1n])for(const offset of [0n,2n]){
        parity("transform-multi-"+fixture.key+"-"+variant+"-"+start+"-"+offset,
          inst(ta,fixture.root,start,refs,offset),
          originalInst(fixture.term,start,replacements,offset));
      }
      parity("transform-reverse-"+fixture.key+"-"+variant,
        instRev(ta,fixture.root,refs),originalRev(fixture.term,replacements));
      for(const fuel of [0n,1n,3n]){
        const result=parity("transform-bounded-multi-"+fixture.key+"-"+variant+"-"+fuel,
          bounded(fuel,T.instantiate(0n,refs),ta,fixture.root,1n),
          originalInstFuel(fuel,fixture.term,0n,replacements,1n));
        if(fuel===0n)must(result.snd===fixture.root&&result.fst.size===ta.size,
          "transform-zero-budget-retains-subtree-"+fixture.key+"-"+variant);
      }
    }
    for(const offset of [0n,2n]){
      parity("transform-abstract-"+fixture.key+"-"+offset,
        abstract(ta,fixture.root,names,offset),originalAbstract(fixture.term,names,offset));
    }
    for(const fuel of [0n,1n,3n]){
      parity("transform-bounded-abstract-"+fixture.key+"-"+fuel,
        bounded(fuel,T.abstractFVars(names),ta,fixture.root,1n),
        originalAbstractFuel(fuel,fixture.term,names,1n));
    }
    for(const [label,params,values] of [
      ["empty",nil,nil],
      ["replace",list([u]),list([L.zero])],
      ["missing-value",list([u,v]),list([L.succ(L.zero)])]
    ]){
      const transformed=parity("transform-levels-"+fixture.key+"-"+label,
        levels(ta,fixture.root,params,values),originalLevels(fixture.term,params,values));
      if(label==="empty")must(transformed.snd===fixture.root&&transformed.fst.size===ta.size,
        "transform-unchanged-levels-retain-id-"+fixture.key);
    }
  }
  // One child occurs at two depths. Partial results must not cross budgets.
  let sx=mk(empty,"BVar",0n),sy=mk(sx.fst,"BVar",1n);
  const shared=mk(sy.fst,"App",sx.snd,sy.snd);
  const wrapped=mk(shared.fst,"MData",7n,shared.snd);
  const replacement=mk(wrapped.fst,"Sort",L.zero);
  const sharedTree=E.app(E.bvar(0n),E.bvar(1n));
  for(const reverse of [false,true]){
    const root=mk(replacement.fst,"App",reverse?wrapped.snd:shared.snd,reverse?shared.snd:wrapped.snd);
    const term=E.app(reverse?E.mdata(7n,sharedTree):sharedTree,
      reverse?sharedTree:E.mdata(7n,sharedTree));
    parity("transform-effective-budget-memo-"+reverse,
      bounded(3n,T.instantiate(0n,list([replacement.snd])),root.fst,root.snd,0n),
      originalInstFuel(3n,term,0n,list([sort0]),0n));
  }
  // A 25-node shared term represents 33,554,431 tree occurrences.
  // Inspect the graph directly without materializing that tree.
  let large=mk(get("psKernelExprV2PagedEmptyWithLimit")(3n),"BVar",0n);
  for(let i=0;i<24;i++)large=mk(large.fst,"App",large.snd,large.snd);
  const largeValue=mk(large.fst,"Sort",L.zero);
  must(accepted(get("psKernelExprV2TransformCountOnCanonical")(
    largeValue.fst,large.snd),"large-expanded-count")===33554431n,
    "transform-large-count-retains-occurrence-multiplicity");
  const largeResult=accepted(get("psKernelExprV2PagedInstantiateChecked")(
    largeValue.fst,large.snd,list([largeValue.snd])),"large-default-transform");
  must(largeResult.fst.size<=largeValue.fst.size+24n,
    "transform-large-default-bounds-allocation-by-shared-nodes");
  let cursor=largeResult.snd;
  for(let i=0;i<24;i++){
    const entry=accepted(get("psKernelExprV2PagedRequire")(largeResult.fst,cursor),"large-node");
    must(typeof entry.node.fn==="bigint"&&entry.node.fn===entry.node.arg,
      "transform-large-preserves-both-shared-edges-"+i);
    cursor=entry.node.fn;
  }
  must(cursor===largeValue.snd,"transform-large-reaches-original-replacement-id");
  const unchanged=accepted(abstract(largeResult.fst,largeResult.snd,
    list([name("unused")]),0n),"large-unchanged-abstraction");
  must(unchanged.snd===largeResult.snd&&unchanged.fst.size===largeResult.fst.size,
    "transform-large-unchanged-retains-id-without-materialization");
  const spine=accepted(get("psKernelExprV2PagedAppSpineChecked")(
    ta,ids.app),"transform-app-spine");
  const reapplied=accepted(get("psKernelExprV2PagedApplyArgsChecked")(
    ta,spine.fst,spine.snd),"transform-reapply-spine");
  must(exact(readGraph(reapplied,"transform-spine-roundtrip"),terms.app)===true,
    "transform-spine-preserves-argument-order");
  must(rejected(get("psKernelExprV2TransformAppSpineWithFuel")(0n)(ta)(ids.app)(nil))===true,
    "transform-spine-zero-fuel-rejected");
  must(rejected(inst(ta,ta.size,0n,nil,0n))===true,"transform-invalid-root");
  must(rejected(inst(ta,ids.s0,99n,list([ta.size]),0n))===true,
    "transform-invalid-replacement-rejected-before-pruning");
  must(rejected(bounded(0n,T.instantiate(0n,list([ta.size])),ta,ids.b0,0n))===true,
    "transform-zero-fuel-does-not-bypass-reference-validation");
  const forged=get("psKernelExprV2PagedPush")(empty,{...fEntry,hasFVar:false}).fst;
  must(rejected(bounded(0n,T.abstractFVars(nil),forged,0n,0n))===true,
    "transform-zero-fuel-does-not-bypass-metadata-validation");
  must(rejected(levels(forged,0n,nil,nil))===true,"transform-empty-levels-reject-forgery");
  must(rejected(abstract(cyclic,0n,nil,0n))===true,"transform-cycle-rejected");
  console.log("PSC1_V2_TRANSFORM_JS_SUMMARY "+JSON.stringify({
    comparisons,constructor_families:12,shared_depth:24,
    shared_input_nodes:Number(largeValue.fst.size),shared_output_nodes:Number(largeResult.fst.size),
    exact_comparison:true,large_graph_materialized:false
  }));
  console.log("PSC1_V2_TRANSFORM_JS: PASS");
}

const source=readFileSync(filename,"utf8");
must(!/from\s*["'](?:lean|node:child_process)|require\(["'](?:lean|child_process)/.test(source),
  "independent-generated-runtime");
function reportDagSmoke(){
if(typeof global.gc==="function")global.gc();
console.log("PSC1_V2_DAG_JS_SUMMARY "+JSON.stringify({
  node:process.version,source_bytes:statSync(filename).size,
  peak_rss_kib:process.resourceUsage().maxRSS,
  post_gc_heap_bytes:process.memoryUsage().heapUsed,
  semantics:"complete KernelContract-v1 via one checked DAG input boundary",
  checker_representation:"DAG checked binders, lets, admitted constants, applications and projections; typed local-value WHNF; scope-owned DefEq with binder spines, Bool reflection, cheap core and repeated quick comparison; direct axiom/definition/opaque/theorem, unsafe and mutual-definition admission; proof irrelevance, lazy delta, external types, iota and inductive admission fallback remain; incomplete"
}));
console.log("PSC1_V2_DAG_JS: PASS");
}



for(const wrappers of [0,1,5]){
  let graph=mk(empty,"Sort",L.zero); const s0=graph.snd;
  graph=mk(graph.fst,"Sort",L.succ(L.zero)); const s1=graph.snd;
  graph=mk(graph.fst,"BVar",1n); const b1=graph.snd;
  graph=mk(graph.fst,"Lam",name("inner"),s1,b1,B.implicit); const lam=graph.snd;
  graph=mk(graph.fst,"Let",name("x"),s1,s0,lam,false);
  let term=E.letE(name("x"),sort1,sort0,E.lam(name("inner"),sort1,E.bvar(1n),B.implicit),false);
  for(let tag=0;tag<wrappers;tag++){
    graph=mk(graph.fst,"MData",BigInt(tag),graph.snd);
    term=E.mdata(BigInt(tag),term);
  }
  for(const fuel of [0n,1n,2n,3n,4n,8n,16n,64n]){
    for(const depth of [0n,1n,2n]){
      const s=session(fuel,depth);
      must(sameOperation(get("psKernelV1Whnf")(s,nil,S.safe,term),
        invoke(graph.fst,[C.whnf(graph.snd)],s),exact),
        "zeta-complete-whnf-"+wrappers+"-"+fuel+"-"+depth);
    }
  }
  const checker=get("psKernelKernelSessionChecker")(session(),nil,S.safe);
  const attempted=get("psKernelExprV2TryWhnfWithFuel")(4096n,checker.context,graph.fst,graph.snd);
  must(attempted&&typeof attempted==="object"&&"value" in attempted,
    "zeta-executes-dag-native-worker-"+wrappers);
  const reduced=accepted(attempted.value,"zeta-native-worker");
  const rebuilt=accepted(decode(reduced.fst),"zeta-native-valid-result");
  const value=accepted(decoded(rebuilt,reduced.snd),"zeta-native-read");
  must(exact(value,E.lam(name("inner"),sort1,sort0,B.implicit)),
    "zeta-nested-binder-result-"+wrappers);
}
console.log("PSC1_V2_DAG_JS_ZETA: PASS");

// Direct syntactic-lambda beta spines preserve both original core visits.
{
  let betaArena=empty;
  const betaAdd=(kind,...args)=>{
    const next=mk(betaArena,kind,...args);
    betaArena=next.fst; return next.snd;
  };
  const bs0=betaAdd("Sort",L.zero);
  const bs1=betaAdd("Sort",L.succ(L.zero));
  const bs2=betaAdd("Sort",L.succ(L.succ(L.zero)));
  const bb0=betaAdd("BVar",0n),bb1=betaAdd("BVar",1n);
  const bx=name("beta-x"),by=name("beta-y"),bz=name("beta-z");
  const bi=betaAdd("Lam",bx,bs1,bb0,B.default);
  const identity=E.lam(bx,sort1,E.bvar(0n),B.default);
  const bsingle=betaAdd("App",bi,bs0);
  const inner=betaAdd("Lam",by,bs1,bb1,B.implicit);
  const partialHead=betaAdd("Lam",bx,bs1,inner,B.default);
  const bpartial=betaAdd("App",partialHead,bs0);
  const reverseInner=betaAdd("Lam",by,bs1,bb1,B.default);
  const reverseHead=betaAdd("Lam",bx,bs2,reverseInner,B.default);
  const reverseFirst=betaAdd("App",reverseHead,bs1);
  const breverse=betaAdd("App",reverseFirst,bs0);
  const tagged=betaAdd("MData",9n,bb0);
  const letBody=betaAdd("Let",by,bs1,bb0,tagged,false);
  const zetaHead=betaAdd("Lam",bx,bs1,letBody,B.default);
  const bzeta=betaAdd("App",zetaHead,bs0);
  const overZ=betaAdd("Lam",bz,bs1,bb1,B.default);
  const overY=betaAdd("Lam",by,bs1,overZ,B.default);
  const overBody=betaAdd("App",overY,bb0);
  const overX=betaAdd("Lam",bx,bs1,overBody,B.default);
  const overFirst=betaAdd("App",overX,bs0);
  const bover=betaAdd("App",overFirst,bs0);
  const sort2=E.sort(L.succ(L.succ(L.zero)));
  const fixtures=[
    [bsingle,E.app(identity,sort0),sort0],
    [bpartial,E.app(E.lam(bx,sort1,E.lam(by,sort1,E.bvar(1n),B.implicit),B.default),sort0),
      E.lam(by,sort1,sort0,B.implicit)],
    [breverse,E.app(E.app(E.lam(bx,sort2,E.lam(by,sort1,E.bvar(1n),B.default),B.default),sort1),sort0),
      sort1],
    [bzeta,E.app(E.lam(bx,sort1,E.letE(by,sort1,E.bvar(0n),E.mdata(9n,E.bvar(0n)),false),B.default),sort0),
      sort0],
    [bover,E.app(E.app(E.lam(bx,sort1,E.app(E.lam(by,sort1,E.lam(bz,sort1,E.bvar(1n),B.default),B.default),E.bvar(0n)),B.default),sort0),sort0),
      sort0]
  ];
  for(let index=0;index<fixtures.length;index++){
    const [root,term,expected]=fixtures[index];
    for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,16n,64n]){
      for(const depth of [0n,1n,2n]){
        const s=session(fuel,depth);
        must(sameOperation(get("psKernelV1Whnf")(s,nil,S.safe,term),
          invoke(betaArena,[C.whnf(root)],s),exact),
          "beta-complete-whnf-"+index+"-"+fuel+"-"+depth);
        const checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
        const old=get("psKernelSessionWhnf")(fuel,checker,term);
        const attempted=get("psKernelExprV2TryWhnfWithFuel")(fuel,checker.context,betaArena,root);
        must(attempted&&typeof attempted==="object"&&"value" in attempted,
          "beta-direct-worker-selected-"+index+"-"+fuel+"-"+depth);
        const direct=attempted.value;
        if(rejected(old)){
          must(rejected(direct)&&old.error===direct.error,
            "beta-direct-worker-error-parity-"+index+"-"+fuel+"-"+depth);
        }else{
          const result=accepted(direct,"beta-worker-result");
          const built=accepted(decode(result.fst),"beta-valid-result");
          const actual=accepted(decoded(built,result.snd),"beta-result-read");
          must(exact(actual,accepted(old,"beta-legacy-whnf").fst)&&exact(actual,expected),
            "beta-direct-worker-value-parity-"+index+"-"+fuel+"-"+depth);
        }
      }
    }
  }
  const functionType=betaAdd("Forall",N.anonymous,bs1,bs1,B.default);
  const cacheHead=betaAdd("Let",name("beta-f"),functionType,bi,bb0,false);
  const cacheInner=betaAdd("App",cacheHead,bs0);
  const cacheRoot=betaAdd("App",cacheHead,cacheInner);
  const legacyHead=E.letE(name("beta-f"),E.forallE(N.anonymous,sort1,sort1,B.default),
    identity,E.bvar(0n),false);
  const cacheTerm=E.app(legacyHead,E.app(legacyHead,sort0));
  const checker=get("psKernelKernelSessionChecker")(session(),nil,S.safe);
  const cached=accepted(get("psKernelSessionWhnf")(4n,checker,cacheTerm),"beta-cache-oracle");
  must(exact(cached.fst,sort0),"beta-cache-oracle-low-budget");
  const direct=get("psKernelExprV2TryWhnfWithFuel")(4n,checker.context,betaArena,cacheRoot);
  must(direct&&typeof direct==="object"&&"value" in direct,
    "beta-cache-sensitive-function-normalization-is-dag-native");
  const reduced=accepted(direct.value,"beta-cache-sensitive-direct-result");
  const cacheGraph=accepted(decode(reduced.fst),"beta-cache-sensitive-valid-arena");
  must(exact(accepted(decoded(cacheGraph,reduced.snd),"beta-cache-sensitive-decoded"),sort0),
    "beta-cache-sensitive-direct-value");
  for(const fuel of [0n,1n,2n,3n,4n,5n,8n,16n,64n]){
    const s=session(fuel);
    must(sameOperation(get("psKernelV1Whnf")(s,nil,S.safe,cacheTerm),
      invoke(betaArena,[C.whnf(cacheRoot)],s),exact),
      "beta-cache-sensitive-public-parity-"+fuel);
  }
}
console.log("PSC1_V2_DAG_JS_BETA: PASS");

{
  let stateArena=empty;
  const addState=(kind,...args)=>{
    const result=mk(stateArena,kind,...args);
    stateArena=result.fst; return result.snd;
  };
  const s0=addState("Sort",L.zero),s1=addState("Sort",L.succ(L.zero));
  const b0=addState("BVar",0n);
  const type=addState("Forall",N.anonymous,s1,s1,B.default);
  const aName=name("state-a"),bName=name("state-b");
  const ia=addState("Lam",aName,s1,b0,B.default);
  const ib=addState("Lam",bName,s1,b0,B.implicit);
  const ha=addState("Let",name("state-fa"),type,ia,b0,false);
  const hb=addState("Let",name("state-fb"),type,ib,b0,false);
  const innerA=addState("App",ha,s0),innerB=addState("App",hb,s0);
  const shared=addState("App",ha,innerA),copied=addState("App",ha,innerB);
  const syntax=addState("App",ha,hb);
  const tag0=addState("MData",0n,ia),tag1=addState("MData",65521n,ia);
  const hc0=addState("Let",name("state-c"),type,tag0,b0,false);
  const hc1=addState("Let",name("state-c"),type,tag1,b0,false);
  const collisionInner=addState("App",hc1,s0);
  const collision=addState("App",hc0,collisionInner);
  const metadataFn=addState("MData",73n,ia);
  const metadataApp=addState("App",metadataFn,s0);
  const ftype=E.forallE(N.anonymous,sort1,sort1,B.default);
  const identA=E.lam(aName,sort1,E.bvar(0n),B.default);
  const identB=E.lam(bName,sort1,E.bvar(0n),B.implicit);
  const headA=E.letE(name("state-fa"),ftype,identA,E.bvar(0n),false);
  const headB=E.letE(name("state-fb"),ftype,identB,E.bvar(0n),false);
  const c0=E.letE(name("state-c"),ftype,E.mdata(0n,identA),E.bvar(0n),false);
  const c1=E.letE(name("state-c"),ftype,E.mdata(65521n,identA),E.bvar(0n),false);
  const fixtures=[
    [shared,E.app(headA,E.app(headA,sort0))],
    [copied,E.app(headA,E.app(headB,sort0))],
    [syntax,E.app(headA,headB)],
    [collision,E.app(c0,E.app(c1,sort0))],
    [metadataApp,E.app(E.mdata(73n,identA),sort0)]
  ];
  const emptyState=()=>get("psKernelExprV2WhnfStateEmpty")(stateArena);
  const attemptedState=(fuel,context,root)=>
    get("psKernelExprV2TryWhnfStateWithFuel")(fuel)(context)(emptyState())(root);
  const compareState=(original,attempted,label)=>{
    must(attempted&&typeof attempted==="object"&&"value" in attempted,label+"-direct");
    const result=attempted.value;
    if(rejected(original)){
      must(rejected(result)&&original.error===result.error,label+"-error");
      return;
    }
    const reduced=accepted(result,label+"-result");
    const graph=accepted(decode(reduced.fst.arena),label+"-valid");
    const actual=accepted(decoded(graph,reduced.snd),label+"-decoded");
    must(exact(accepted(original,label+"-original").fst,actual),label+"-value");
  };
  for(let index=0;index<fixtures.length;index++){
    const [root,term]=fixtures[index];
    for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,12n,64n]){
      for(const depth of [0n,1n,2n]){
        const s=session(fuel,depth);
        const checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
        compareState(get("psKernelSessionWhnf")(fuel,checker,term),
          attemptedState(fuel,checker.context,root),
          "stateful-whnf-"+index+"-"+fuel+"-"+depth);
        must(sameOperation(get("psKernelV1Whnf")(s,nil,S.safe,term),
          invoke(stateArena,[C.whnf(root)],s),exact),
          "stateful-public-"+index+"-"+fuel+"-"+depth);
      }
    }
  }
  const checker=get("psKernelKernelSessionChecker")(session(),nil,S.safe);
  must(ha!==hb&&accepted(get("psKernelExprV2PagedEqOnCanonical")(stateArena,ha,hb),
    "state-alpha-keys")===true,"state-distinct-alpha-keys");
  const ca=accepted(get("psKernelExprV2PagedRequire")(stateArena,hc0),"collision-key0");
  const cb=accepted(get("psKernelExprV2PagedRequire")(stateArena,hc1),"collision-key1");
  must(ca.hash===cb.hash&&
    accepted(get("psKernelExprV2PagedEqOnCanonical")(stateArena,hc0,hc1),"collision-equality")===false,
    "state-real-hash-collision");
  const collisionOld=get("psKernelSessionWhnf")(5n,checker,fixtures[3][1]);
  must(rejected(collisionOld)&&collisionOld.error==="kernel reduction budget exhausted",
    "state-hash-collision-cannot-create-cache-hit");
  const exactOriginal=get("psKernelSessionWhnf")(4n,checker,fixtures[2][1]);
  const exactOld=accepted(exactOriginal,"state-exact-syntax");
  must(exact(exactOld.fst,identA)&&!exact(exactOld.fst,identB),
    "state-oracle-retains-first-cached-syntax");
  compareState(exactOriginal,attemptedState(4n,checker.context,syntax),
    "state-dag-retains-first-cached-syntax");
  must(rejected(invoke(stateArena,[C.whnf(syntax)])),"state-raw-syntax-fixture-rejected-publicly");
  const warmContext={...checker.context,maxRecDepth:1n};
  const warmChecker={...checker,context:warmContext};
  const warmOld=accepted(get("psKernelSessionWhnf")(4n,warmChecker,fixtures[0][1]),"warm-old");
  const warmAttempt=attemptedState(4n,warmContext,shared);
  must(warmAttempt&&typeof warmAttempt==="object"&&"value" in warmAttempt,"warm-dag-direct");
  const warmDag=accepted(warmAttempt.value,"warm-dag");
  const noCallback=()=>{throw Error("PSC1_DAG_UNEXPECTED_WARM_CORE_CALLBACK");};
  for(const context of [warmContext,{...warmContext,recDepth:16n}]){
    for(const fuel of [0n,1n]){
      const original=get("psKernelWhnfCoreWithFuel")(fuel)
        (noCallback)(noCallback)(context)(warmOld.snd.state)(fixtures[0][1])(false)(false);
      const actual=get("psKernelExprV2TryWhnfCoreStateWithFuel")(fuel,context,warmDag.fst,shared);
      compareState(original,actual,"state-warm-entry-guards-"+context.recDepth+"-"+fuel);
    }
  }
  for(const context of [warmContext,{...warmContext,recDepth:16n}]){
    for(const fuel of [0n,1n]){
      compareState(get("psKernelSessionWhnf")(fuel,{...warmOld.snd,context},fixtures[0][1]),
        get("psKernelExprV2TryWhnfStateWithFuel")(fuel)(context)(warmDag.fst)(shared),
        "public-warm-entry-guards-"+context.recDepth+"-"+fuel);
    }
  }
  const localName=name("state-local");
  const fvar=addState("FVar",localName),openRoot=addState("App",ia,fvar);
  const locals=get("psKernelLocalContextAddLocal")(checker.context.localContext,
    localName,localName,sort1,B.default);
  const localContext=get("psKernelCheckerContextWithLocalContext")(checker.context,locals);
  const openAttempt=attemptedState(64n,localContext,openRoot);
  must(openAttempt&&typeof openAttempt==="object"&&"value" in openAttempt,"open-state-direct");
  const openResult=accepted(openAttempt.value,"open-state-result");
  must(array(get("psKernelExprV2WhnfCacheEntries")(openResult.fst.coreCache)).length===0&&
    array(get("psKernelExprV2WhnfCacheEntries")(openResult.fst.publicCache)).length===0,"open-state-cache-ineligible");
  const letLocals=get("psKernelLocalContextAddLet")(checker.context.localContext,
    localName,localName,sort1,sort0);
  const letContext=get("psKernelCheckerContextWithLocalContext")(checker.context,letLocals);
  const declined=get("psKernelExprV2TryWhnfWithFuel")(64n,letContext,stateArena,fvar);
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  must(declined!==undefined&&sameRuntimeValue(declined,none),"local-let-value-explicit-fallback");
}
console.log("PSC1_V2_DAG_JS_WHNF_STATE: PASS");


{
  let reductionArena=empty;
  const addReduction=(kind,...args)=>{
    const result=mk(reductionArena,kind,...args);
    reductionArena=result.fst;return result.snd;
  };
  const literal=get("PsKernelLiteral"),natName=get("psKernelNatName");
  const numeral=value=>E.lit(literal.nat(value));
  const natID=value=>addReduction("Lit",literal.nat(value));
  const binary=(op,left,right)=>{
    const fn=addReduction("Const",N.str(natName,op),nil);
    const a=addReduction("MData",13n,natID(left)),b=addReduction("MData",17n,natID(right));
    const root=addReduction("App",addReduction("App",fn,a),b);
    const term=E.app(E.app(E.const(N.str(natName,op),nil),E.mdata(13n,numeral(left))),
      E.mdata(17n,numeral(right)));
    return [root,term];
  };
  const compareRaw=(fuel,checker,root,term,label)=>{
    const original=get("psKernelSessionWhnf")(fuel,checker,term);
    const attempt=get("psKernelExprV2TryWhnfStateWithFuel")(fuel)(checker.context)
      (get("psKernelExprV2WhnfStateEmpty")(reductionArena))(root);
    must(attempt&&typeof attempt==="object"&&"value" in attempt,label+"-direct");
    const actual=attempt.value;
    if(rejected(original)){
      must(rejected(actual)&&original.error===actual.error,label+"-error");
    }else{
      const result=accepted(actual,label+"-success");
      const built=accepted(decode(result.fst.arena),label+"-canonical-result");
      must(exact(accepted(decoded(built,result.snd),label+"-decode"),
        accepted(original,label+"-original").fst),label+"-exact-value");
    }
  };
  const initial=session(),checker=get("psKernelKernelSessionChecker")(initial,nil,S.safe);
  const outcomes=[
    ["add",numeral(13n)],["sub",numeral(5n)],["mul",numeral(36n)],
    ["pow",numeral(6561n)],["gcd",numeral(1n)],["mod",numeral(1n)],
    ["div",numeral(2n)],["beq",E.const(get("psKernelBoolFalseName"),nil)],
    ["ble",E.const(get("psKernelBoolFalseName"),nil)],["land",numeral(0n)],
    ["lor",numeral(13n)],["xor",numeral(13n)],["shiftLeft",numeral(144n)],
    ["shiftRight",numeral(0n)]
  ];
  for(const [op,expected]of outcomes){
    const [root,term]=binary(op,9n,4n);
    must(exact(accepted(get("psKernelSessionWhnf")(64n,checker,term),op+"-expected").fst,expected),
      "nat-independent-expected-"+op);
    for(const fuel of [0n,1n,2n,3n,4n,6n,12n,64n]){
      for(const depth of [0n,1n]){
        for(const maxNatSize of [0n,1n,get("psKernelLeanNatMaxSizeDefault")]){
          compareRaw(fuel,{...checker,context:{...checker.context,maxRecDepth:depth,maxNatSize}},
            root,term,"nat-full-pipeline-"+op+"-"+fuel+"-"+depth+"-"+maxNatSize);
        }
      }
    }
  }
  for(const [op,left,right]of [["pow",2n,4294967296n],["shiftLeft",1n,4294967296n],
      ["div",9n,0n],["mod",9n,0n],["pow",0n,0n]]){
    const [root,term]=binary(op,left,right);
    compareRaw(64n,checker,root,term,"nat-count-and-zero-"+op+"-"+left+"-"+right);
  }
  const rs0=addReduction("Sort",L.zero),rs1=addReduction("Sort",L.succ(L.zero));
  let deep=rs0;for(const tag of [3n,2n,1n])deep=addReduction("MData",tag,deep);
  const unknownFn=addReduction("Const",name("notNat"),nil);
  const unknownRoot=addReduction("App",addReduction("App",unknownFn,rs0),deep);
  const unknown=E.app(E.app(E.const(name("notNat"),nil),sort0),E.mdata(1n,E.mdata(2n,E.mdata(3n,sort0))));
  for(const fuel of [0n,1n,2n,3n,4n,5n,6n,16n])
    compareRaw(fuel,checker,unknownRoot,unknown,"nonprimitive-binary-order-"+fuel);
  const exhausted=get("psKernelSessionWhnf")(3n,checker,unknown);
  must(rejected(exhausted)&&exhausted.error==="kernel reduction budget exhausted",
    "nonprimitive-still-normalizes-both-operands");
  const Request=get("PsKernelDeclarationRequest"),nat=E.const(natName,nil);
  const natSession=accepted(get("psKernelV1AdmitDeclaration")(initial,Request.ordinaryInductive({
    levelParams:nil,name:natName,type:sort1,numParams:0n,isUnsafe:false,
    ctors:list([{name:get("psKernelNatZeroName"),type:nat},
      {name:get("psKernelNatSuccName"),type:E.forallE(name("n"),nat,nat,B.default)}])
  })),"real-Nat-admission").session;
  const succFn=addReduction("Const",get("psKernelNatSuccName"),nil);
  const succRoot=addReduction("App",succFn,addReduction("MData",3n,
    addReduction("App",succFn,natID(4n))));
  const succ=E.app(E.const(get("psKernelNatSuccName"),nil),
    E.mdata(3n,E.app(E.const(get("psKernelNatSuccName"),nil),numeral(4n))));
  for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,16n,64n]){
    for(const maxRecDepth of [0n,1n,2n]){
      const s={...natSession,resources:{...natSession.resources,fuel,maxRecDepth}};
      must(sameOperation(get("psKernelV1Whnf")(s,nil,S.safe,succ),
        invoke(reductionArena,[C.whnf(succRoot)],s),exact),
        "checked-Nat-successor-parity-"+fuel+"-"+maxRecDepth);
    }
  }
  const natReply=array(accepted(invoke(reductionArena,[C.whnf(succRoot)],natSession),
    "checked-Nat-successor").replies);
  must(natReply.length===1&&exact(natReply[0].value,numeral(6n)),"checked-Nat-successor-value");
  const box=name("DagProjectionBox"),ctor=N.str(box,"mk"),boxType=E.const(box,nil);
  const ctorType=E.forallE(name("A"),sort1,E.forallE(name("B"),sort1,boxType,B.default),B.default);
  const boxSession=accepted(get("psKernelV1AdmitDeclaration")(initial,Request.ordinaryInductive({
    levelParams:nil,name:box,type:E.sort(L.succ(L.succ(L.zero))),numParams:0n,isUnsafe:false,
    ctors:list([{name:ctor,type:ctorType}])
  })),"real-projection-inductive-admission").session;
  const boxChecker=get("psKernelKernelSessionChecker")(boxSession,nil,S.safe);
  const boxID=addReduction("Const",box,nil),ctorID=addReduction("Const",ctor,nil);
  const value=addReduction("App",addReduction("App",ctorID,addReduction("MData",7n,rs0)),
    addReduction("MData",9n,rs0));
  let unselected=rs0,unselectedTerm=sort0;
  for(const tag of [0n,1n,2n,3n]){
    unselected=addReduction("MData",tag,unselected);
    unselectedTerm=E.mdata(tag,unselectedTerm);
  }
  const budgetRoot=addReduction("Proj",box,0n,
    addReduction("App",addReduction("App",ctorID,rs0),unselected));
  const budgetTerm=E.proj(box,0n,E.app(E.app(E.const(ctor,nil),sort0),unselectedTerm));
  for(const fuel of [6n,7n]){
    const original=get("psKernelSessionWhnf")(fuel,boxChecker,budgetTerm);
    if(fuel===6n){
      must(rejected(original)&&original.error==="kernel reduction budget exhausted",
        "projection-unselected-field-budget-six");
    }else{
      must(exact(accepted(original,"projection-budget-seven").fst,sort0),
        "projection-unselected-field-budget-seven");
    }
    compareRaw(fuel,boxChecker,budgetRoot,budgetTerm,"projection-unselected-field-"+fuel);
  }
  console.log("PSC1_V2_DAG_JS_PROJECTION_UNSELECTED_FIELD: PASS");
  const b0=addReduction("BVar",0n);
  const betaValue=addReduction("App",addReduction("Lam",N.anonymous,boxID,b0,B.default),value);
  const changed=addReduction("App",addReduction("App",addReduction("MData",71n,ctorID),rs0),rs0);
  const oldValue=E.app(E.app(E.const(ctor,nil),E.mdata(7n,sort0)),E.mdata(9n,sort0));
  const oldBeta=E.app(E.lam(N.anonymous,boxType,E.bvar(0n),B.default),oldValue);
  const oldChanged=E.app(E.app(E.mdata(71n,E.const(ctor,nil)),sort0),sort0);
  const projectionFixtures=[
    [addReduction("Proj",box,0n,value),E.proj(box,0n,oldValue),true],
    [addReduction("Proj",box,1n,betaValue),E.proj(box,1n,oldBeta),true],
    [addReduction("Proj",box,1n,changed),E.proj(box,1n,oldChanged),true],
    [addReduction("Proj",box,2n,value),E.proj(box,2n,oldValue),false],
    [addReduction("Proj",box,4294967296n,betaValue),E.proj(box,4294967296n,oldBeta),false],
    [addReduction("Proj",name("OtherBox"),0n,value),E.proj(name("OtherBox"),0n,oldValue),false]
  ];
  for(let index=0;index<projectionFixtures.length;index++){
    const [root,term,valid]=projectionFixtures[index];
    for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,12n,64n]){
      for(const maxRecDepth of [0n,1n,2n]){
        const s={...boxSession,resources:{...boxSession.resources,fuel,maxRecDepth}};
        compareRaw(fuel,{...boxChecker,context:{...boxChecker.context,maxRecDepth}},
          root,term,"projection-raw-"+index+"-"+fuel+"-"+maxRecDepth);
        must(sameOperation(get("psKernelV1Whnf")(s,nil,S.safe,term),
          invoke(reductionArena,[C.whnf(root)],s),exact),
          "projection-public-"+index+"-"+fuel+"-"+maxRecDepth);
      }
    }
    const normalized=invoke(reductionArena,[C.whnf(root)],boxSession);
    if(valid){
      const replies=array(accepted(normalized,"projection-checked-result").replies);
      must(replies.length===1&&exact(replies[0].value,sort0),"projection-selected-field-"+index);
    }else{
      must(rejected(normalized)&&sameRuntimeValue(
        get("psKernelErrorOutcome")(normalized.error),get("PsKernelOutcome").rejectedInvalid),
        "invalid-projection-is-rejected-"+index);
    }
  }
  const parameterBox=name("DagParameterBox"),parameterCtor=N.str(parameterBox,"mk");
  const parameterType=E.forallE(name("A"),sort1,sort1,B.default);
  const parameterCtorType=E.forallE(name("A"),sort1,
    E.forallE(name("value"),E.bvar(0n),E.app(E.const(parameterBox,nil),E.bvar(1n)),B.default),B.default);
  const parameterSession=accepted(get("psKernelV1AdmitDeclaration")(natSession,Request.ordinaryInductive({
    levelParams:nil,name:parameterBox,type:parameterType,numParams:1n,isUnsafe:false,
    ctors:list([{name:parameterCtor,type:parameterCtorType}])
  })),"parameterized-inductive-admission").session;
  const parameterChecker=get("psKernelKernelSessionChecker")(parameterSession,nil,S.safe);
  const parameterCtorID=addReduction("Const",parameterCtor,nil),natTypeID=addReduction("Const",natName,nil);
  const parameterRoot=addReduction("Proj",parameterBox,0n,
    addReduction("App",addReduction("App",parameterCtorID,natTypeID),natID(4n)));
  const parameterTerm=E.proj(parameterBox,0n,E.app(E.app(E.const(parameterCtor,nil),nat),numeral(4n)));
  for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,16n,64n]){
    compareRaw(fuel,parameterChecker,parameterRoot,parameterTerm,"projection-parameter-offset-"+fuel);
    const s={...parameterSession,resources:{...parameterSession.resources,fuel}};
    must(sameOperation(get("psKernelV1Whnf")(s,nil,S.safe,parameterTerm),
      invoke(reductionArena,[C.whnf(parameterRoot)],s),exact),
      "parameterized-projection-public-"+fuel);
  }
  const parameterReply=array(accepted(invoke(reductionArena,[C.whnf(parameterRoot)],parameterSession),
    "parameter-projection-result").replies);
  must(parameterReply.length===1&&exact(parameterReply[0].value,numeral(4n)),
    "parameterized-projection-selects-field-not-parameter");
  const [projectionRoot,projectionTerm]=projectionFixtures[0];
  compareRaw(64n,checker,projectionRoot,projectionTerm,"projection-empty-environment-scope");
  must(rejected(invoke(reductionArena,[C.whnf(projectionRoot)],initial)),
    "projection-cannot-reuse-another-environment");
}
console.log("PSC1_V2_DAG_JS_NAT_PROJECTION: PASS");

{
  let arena=empty;
  const add=(kind,...args)=>{
    const result=mk(arena,kind,...args);arena=result.fst;return result.snd;
  };
  const typeId=add("Sort",L.succ(L.zero)),bodyId=add("BVar",0n);
  const alphaAId=add("Lam",name("public-a"),typeId,bodyId,B.default);
  const alphaBId=add("Lam",name("public-b"),typeId,bodyId,B.implicit);
  const collisionBodyA=add("MData",0n,bodyId),collisionBodyB=add("MData",65521n,bodyId);
  const collisionAId=add("Lam",name("public-c"),typeId,collisionBodyA,B.default);
  const collisionBId=add("Lam",name("public-c"),typeId,collisionBodyB,B.default);
  const alphaA=E.lam(name("public-a"),sort1,E.bvar(0n),B.default);
  const alphaB=E.lam(name("public-b"),sort1,E.bvar(0n),B.implicit);
  const collisionA=E.lam(name("public-c"),sort1,E.mdata(0n,E.bvar(0n)),B.default);
  const collisionB=E.lam(name("public-c"),sort1,E.mdata(65521n,E.bvar(0n)),B.default);
  must(alphaAId!==alphaBId,"public-cache-distinct-alpha-keys");
  must(accepted(get("psKernelExprV2PagedEqOnCanonical")(arena,alphaAId,alphaBId),
    "public-alpha-comparison"),"public-cache-alpha-key-equality");
  const ca=accepted(get("psKernelExprV2PagedRequire")(arena,collisionAId),"public-collision-a");
  const cb=accepted(get("psKernelExprV2PagedRequire")(arena,collisionBId),"public-collision-b");
  must(ca.hash===cb.hash&&get("psKernelExprHash")(collisionA)===get("psKernelExprHash")(collisionB),
    "public-cache-real-collision");
  must(!accepted(get("psKernelExprV2PagedEqOnCanonical")(arena,collisionAId,collisionBId),
    "public-collision-comparison"),"public-cache-unequal-collision-keys");
  const s=session(4096n,1n);
  const checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
  for(const [term,root]of [[alphaA,alphaAId],[alphaB,alphaBId],
      [collisionA,collisionAId],[collisionB,collisionBId]]){
    accepted(get("psKernelV1CheckExpression")(s,nil,S.safe,term),"public-cache-legacy-typed");
    accepted(get("psKernelV1RunDag")(s,nil,S.safe,arena,list([C.check(root)])),"public-cache-dag-typed");
  }
  const call=(fuel,context,state,root)=>
    get("psKernelExprV2TryWhnfStateWithFuel")(fuel)(context)(state)(root);
  const originalCall=(fuel,context,state,term)=>
    get("psKernelWhnfWithRecursorFuel")(fuel,get("psKernelIsDefEqWithFuel")(fuel),context,state,term);
  const compare=(original,attempted,label)=>{
    const result=accepted(attempted,label+"-direct");
    if(rejected(original)){
      must(rejected(result)&&original.error===result.error,label+"-error");return;
    }
    const reduced=accepted(result,label+"-result");
    const graph=accepted(decode(reduced.fst.arena),label+"-valid");
    const actual=accepted(decoded(graph,reduced.snd),label+"-decoded");
    must(exact(accepted(original,label+"-original").fst,actual),label+"-value");
  };
  const warmOriginal=accepted(get("psKernelSessionWhnf")(2n,checker,alphaA),
    "public-alpha-prime-original");
  const warmDag=accepted(accepted(call(2n,checker.context,
    get("psKernelExprV2WhnfStateEmpty")(arena),alphaAId),"public-alpha-prime-direct"),
    "public-alpha-prime-dag");
  for(const context of [checker.context,{...checker.context,recDepth:16n}]){
    const original=originalCall(1n,context,warmOriginal.snd.state,alphaB);
    const value=accepted(original,"public-alpha-warm-original").fst;
    must(exact(value,alphaA)&&!exact(value,alphaB),"public-cache-hit-retains-first-lambda-syntax");
    compare(original,call(1n,context,warmDag.fst,alphaBId),"public-cache-hit-precedes-core-depth");
    const exhausted=originalCall(0n,context,warmOriginal.snd.state,alphaB);
    must(rejected(exhausted)&&exhausted.error==="kernel reduction budget exhausted",
      "public-cache-hit-does-not-bypass-zero-fuel");
    compare(exhausted,call(0n,context,warmDag.fst,alphaBId),"public-cache-zero-fuel-parity");
  }
  const collisionOriginal=accepted(get("psKernelSessionWhnf")(2n,checker,collisionA),
    "public-collision-prime-original");
  const collisionDag=accepted(accepted(call(2n,checker.context,
    get("psKernelExprV2WhnfStateEmpty")(arena),collisionAId),"public-collision-prime-direct"),
    "public-collision-prime-dag");
  const collisionMiss=originalCall(1n,checker.context,collisionOriginal.snd.state,collisionB);
  must(rejected(collisionMiss)&&collisionMiss.error==="kernel reduction budget exhausted",
    "public-cache-collision-cannot-authorize-low-fuel-hit");
  compare(collisionMiss,call(1n,checker.context,collisionDag.fst,collisionBId),
    "public-cache-collision-miss-parity");
  console.log("PSC1_V2_DAG_JS_PUBLIC_CACHE: PASS");
}


// Definitive DAG quick DefEq rules keep the complete entry fuel/depth ordering.
// Unsupported pairs explicitly return None and restart the full public operation.
{
  let quickArena=empty;
  const qadd=(kind,...args)=>{
    const result=mk(quickArena,kind,...args);
    quickArena=result.fst;
    return result.snd;
  };
  const Literal=get("PsKernelLiteral");
  const u=L.param(name("quick-u")),v=L.param(name("quick-v"));
  const params=list([name("quick-u"),name("quick-v")]);
  const maxZero=E.sort(L.max(L.zero,L.zero));
  const imaxZero=E.sort(L.imax(L.succ(L.zero),L.zero));
  const q0=qadd("Sort",L.zero),q1=qadd("Sort",L.succ(L.zero));
  const qm=qadd("Sort",L.max(L.zero,L.zero));
  const qi=qadd("Sort",L.imax(L.succ(L.zero),L.zero));
  const quv=qadd("Sort",L.max(u,v)),qvu=qadd("Sort",L.max(v,u));
  const qu=qadd("Sort",u),qsu=qadd("Sort",L.succ(u));
  const q7a=qadd("Lit",Literal.nat(7n)),q7b=qadd("Lit",Literal.nat(7n));
  const qn0=qadd("Lit",Literal.nat(0n)),qnc=qadd("Lit",Literal.nat(65521n));
  const qs0=qadd("Lit",Literal.str("0"));
  const qsA=qadd("Lit",Literal.str("λ-雪")),qsB=qadd("Lit",Literal.str("λ-雨"));
  let nestedLeft=maxZero,nestedRight=sort0,nestedLeftId=qm,nestedRightId=q0;
  for(let tag=0n;tag<17n;tag++){
    nestedLeft=E.mdata(tag,nestedLeft);
    nestedRight=E.mdata(tag+65521n,nestedRight);
    nestedLeftId=qadd("MData",tag,nestedLeftId);
    nestedRightId=qadd("MData",tag+65521n,nestedRightId);
  }
  const fixtures=[
    ["sort-max-zero",qm,q0,maxZero,sort0,true],
    ["sort-imax-zero",qi,q0,imaxZero,sort0,true],
    ["sort-max-commute",quv,qvu,E.sort(L.max(u,v)),E.sort(L.max(v,u)),true],
    ["sort-distinct",q0,q1,sort0,sort1,false],
    ["sort-param-succ",qu,qsu,E.sort(u),E.sort(L.succ(u)),false],
    ["literal-equal",q7a,q7b,E.lit(Literal.nat(7n)),E.lit(Literal.nat(7n)),true],
    ["literal-hash-collision",qn0,qnc,E.lit(Literal.nat(0n)),E.lit(Literal.nat(65521n)),false],
    ["literal-kinds",qn0,qs0,E.lit(Literal.nat(0n)),E.lit(Literal.str("0")),false],
    ["literal-strings",qsA,qsB,E.lit(Literal.str("λ-雪")),E.lit(Literal.str("λ-雨")),false],
    ["metadata-equivalent",qadd("MData",0n,qm),qadd("MData",65521n,q0),
      E.mdata(0n,maxZero),E.mdata(65521n,sort0),true],
    ["metadata-distinct",qadd("MData",0n,q0),qadd("MData",1n,q1),
      E.mdata(0n,sort0),E.mdata(1n,sort1),false],
    ["metadata-nested",nestedLeftId,nestedRightId,nestedLeft,nestedRight,true]
  ];
  const boolEqual=(a,b)=>typeof a==="boolean"&&typeof b==="boolean"&&a===b;
  const quick=(fuel,context,left,right)=>
    get("psKernelExprV2TryQuickDefEqWithFuel")(fuel)(context)(quickArena)(left)(right);
  const publicQuick=(s,left,right)=>run(s,params,S.safe,quickArena,list([C.isDefEq(left,right)]));
  const compareRaw=(original,attempted,label)=>{
    must(attempted&&typeof attempted==="object"&&"value" in attempted,label+"-direct");
    const result=attempted.value;
    if(rejected(original)){
      must(rejected(result)&&original.error===result.error,label+"-error");
    }else{
      const expected=accepted(original,label+"-original").fst;
      const actual=accepted(result,label+"-result");
      must(boolEqual(expected,actual),label+"-value");
    }
  };
  for(const [label,leftId,rightId,left,right,expected] of fixtures){
    for(const fuel of [0n,1n,2n,3n,4n,8n,16n,17n,18n,64n]){
      for(const maxDepth of [0n,1n,2n]){
        const s=session(fuel,maxDepth);
        const checker=get("psKernelKernelSessionChecker")(s,params,S.safe);
        for(const recDepth of [0n,15n,16n]){
          const context={...checker.context,recDepth};
          compareRaw(get("psKernelSessionIsDefEq")(fuel,{...checker,context},left,right),
            quick(fuel,context,leftId,rightId),
            "quick-defeq-raw-"+label+"-"+fuel+"-"+maxDepth+"-"+recDepth);
        }
        must(sameOperation(get("psKernelV1IsDefEq")(s,params,S.safe,left,right),
          publicQuick(s,leftId,rightId),boolEqual),
          "quick-defeq-public-"+label+"-"+fuel+"-"+maxDepth);
      }
    }
    const s=session(),checker=get("psKernelKernelSessionChecker")(s,params,S.safe);
    must(boolEqual(accepted(accepted(quick(64n,checker.context,leftId,rightId),
      "quick-some-"+label),"quick-answer-"+label),expected),"quick-defeq-direct-answer-"+label);
    const replies=array(accepted(publicQuick(s,leftId,rightId),"quick-public-"+label).replies);
    must(replies.length===1&&boolEqual(replies[0].value,expected),
      "quick-defeq-checked-answer-"+label);
  }
  const bound=qadd("BVar",0n);
  const lam=qadd("Lam",name("quick-x"),q1,bound,B.default);
  const redexId=qadd("App",lam,q0);
  const redex=E.app(E.lam(name("quick-x"),sort1,E.bvar(0n),B.default),sort0);
  const fallback=[
    ["metadata-one-sided",qadd("MData",9n,q0),q0,E.mdata(9n,sort0),sort0,true],
    ["metadata-composite",qadd("MData",9n,redexId),qadd("MData",10n,q0),
      E.mdata(9n,redex),E.mdata(10n,sort0),true],
    ["mixed-constructors",q0,qn0,sort0,E.lit(Literal.nat(0n)),false],
    ["constant-level-rule",qadd("Const",name("quick-missing"),list([L.max(L.zero,L.zero)])),
      qadd("Const",name("quick-missing"),list([L.zero])),
      E.const(name("quick-missing"),list([L.max(L.zero,L.zero)])),
      E.const(name("quick-missing"),list([L.zero])),false]
  ];
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  for(const [label,leftId,rightId,left,right,directExpected] of fallback){
    const checker=get("psKernelKernelSessionChecker")(session(),params,S.safe);
    const selected=quick(64n,checker.context,leftId,rightId);
    if(directExpected)must(accepted(accepted(selected,"quick-prefix-some-"+label),
      "quick-prefix-answer-"+label)===true,"quick-defeq-prefix-direct-"+label);
    else if(label==="constant-level-rule"){
      const answer=accepted(selected,"quick-prefix-error-some-"+label);
      must(rejected(answer)&&answer.error==="unknown constant","quick-prefix-exact-unknown-constant");
      compareRaw(get("psKernelSessionIsDefEq")(64n,checker,left,right),selected,
        "quick-prefix-reference-unknown-constant");
    }else{
      const answer=accepted(accepted(selected,"quick-prefix-false-some-"+label),
        "quick-prefix-false-answer-"+label);
      must(label==="mixed-constructors"&&answer===false,"quick-prefix-exact-mixed-constructor-false");
    }
    for(const fuel of [0n,1n,2n,3n,4n,8n,64n])for(const maxDepth of [0n,1n,2n]){
      const s=session(fuel,maxDepth);
      const current=get("psKernelKernelSessionChecker")(s,params,S.safe);
      compareRaw(get("psKernelSessionIsDefEq")(fuel,current,left,right),
        quick(fuel,current.context,leftId,rightId),
        "quick-defeq-prefix-raw-"+label+"-"+fuel+"-"+maxDepth);
      must(sameOperation(get("psKernelV1IsDefEq")(s,params,S.safe,left,right),
        publicQuick(s,leftId,rightId),boolEqual),
        "quick-defeq-fallback-parity-"+label+"-"+fuel+"-"+maxDepth);
    }
  }
  const bad=E.app(sort0,sort0),badId=qadd("App",q0,q0);
  const badLeft=E.mdata(0n,bad),badRight=E.mdata(1n,bad);
  const badLeftId=qadd("MData",0n,badId),badRightId=qadd("MData",1n,badId);
  const s=session(),checker=get("psKernelKernelSessionChecker")(s,params,S.safe);
  must(accepted(accepted(quick(64n,checker.context,badLeftId,badRightId),
    "quick-invalid-some"),"quick-invalid-raw")===true,"quick-defeq-raw-rule-is-not-admission");
  const invalidPublic=publicQuick(s,badLeftId,badRightId);
  must(rejected(invalidPublic)&&sameOperation(
    get("psKernelV1IsDefEq")(s,params,S.safe,badLeft,badRight),invalidPublic,boolEqual),
    "quick-defeq-checks-both-metadata-operands-before-shortcut");
  for(const [leftId,rightId,left,right] of [
      [badLeftId,q0,badLeft,sort0],[q0,badRightId,sort0,badRight]]){
    const result=publicQuick(s,leftId,rightId);
    must(rejected(result)&&sameOperation(
      get("psKernelV1IsDefEq")(s,params,S.safe,left,right),result,boolEqual),
      "quick-defeq-neither-invalid-operand-can-be-skipped");
  }
}
console.log("PSC1_V2_DAG_JS_QUICK_DEFEQ: PASS");


{
  // Every reference is produced by successful complete admission in this arena.
  let arena=empty;
  const add=(kind,...args)=>{
    const result=mk(arena,kind,...args);arena=result.fst;return result.snd;
  };
  const ensure=(ok,label)=>{
    if(ok!==true)throw Error("PSC1_DAG_DELTA_FAILED "+label);
  };
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  const absent=value=>sameRuntimeValue(value,none);
  const u=name("delta-u"),polyName=name("DagDeltaPoly"),firstName=name("DagDeltaFirst");
  const aliasName=name("DagDeltaAlias"),opaqueName=name("DagDeltaOpaque");
  const theoremName=name("DagDeltaTheorem"),mutualA=name("DagDeltaMutualA");
  const mutualB=name("DagDeltaMutualB"),cycleA=name("DagDeltaCycleA"),cycleB=name("DagDeltaCycleB");
  const level2=L.succ(L.succ(L.zero));
  const s0=add("Sort",L.zero),s1=add("Sort",L.succ(L.zero)),su=add("Sort",L.param(u));
  const b0=add("BVar",0n),b1=add("BVar",1n);
  const innerType=add("Forall",name("x"),b0,b1,B.default);
  const innerBody=add("Lam",name("x"),b0,b0,B.default);
  const polyType=add("Forall",name("A"),su,innerType,B.default);
  const polyBody=add("Lam",name("A"),su,innerBody,B.default);
  const firstTypeTail=add("Forall",name("b"),s1,s1,B.default);
  const firstType=add("Forall",name("a"),s1,firstTypeTail,B.default);
  const firstBodyTail=add("Lam",name("b"),s1,b1,B.default);
  const firstBody=add("Lam",name("a"),s1,firstBodyTail,B.default);
  const proofType=add("Forall",name("P"),s0,innerType,B.default);
  const proofBody=add("Lam",name("P"),s0,innerBody,B.default);
  const poly=add("Const",polyName,list([level2]));
  const wrongArity=add("Const",polyName,nil);
  const partialPoly=add("App",poly,s1),appliedPoly=add("App",partialPoly,s0);
  const first=add("Const",firstName,nil),alias=add("Const",aliasName,nil);
  const opaqueRoot=add("Const",opaqueName,nil),theoremRoot=add("Const",theoremName,nil);
  const ma=add("Const",mutualA,nil),mb=add("Const",mutualB,nil);
  const ca=add("Const",cycleA,nil),cb=add("Const",cycleB,nil);
  let hidden=s0;for(const tag of [0n,1n,2n,3n])hidden=add("MData",tag,hidden);
  const ignoredArgument=add("App",add("App",first,s0),hidden);
  const hints=get("PsKernelReducibilityHints").abbrevHint;
  const base=(name,type,levelParams=nil)=>({name,type,levelParams});
  const def=(name,type,value,safety=S.safe,levelParams=nil)=>
    ({base:base(name,type,levelParams),value,hints,safety});
  const aliasDef=def(aliasName,s1,s0);
  const polyDef=def(polyName,polyType,polyBody,S.safe,list([u]));
  const firstDef=def(firstName,firstType,firstBody);
  const requests=[
    D.definitionDecl(aliasDef),D.definitionDecl(polyDef),D.definitionDecl(firstDef),
    D.opaqueDecl(base(opaqueName,s1),s0,false),D.theoremDecl(base(theoremName,proofType),proofBody),
    D.mutualDefinitions(list([
      def(mutualA,s1,mb,S.unsafeDef),def(mutualB,s1,s0,S.unsafeDef)])),
    D.mutualDefinitions(list([
      def(cycleA,s1,cb,S.unsafeDef),def(cycleB,s1,ca,S.unsafeDef)]))
  ];
  const built=accepted(decode(arena),"delta-canonical-decode"),initial=session();
  const emptyExecution={session:initial,declarations:nil};
  const step=(execution,request)=>get("psKernelDagRunCommand")(
    execution,nil,S.unsafeDef,arena,built,C.admit(request));
  const firstAdmission=accepted(step(emptyExecution,requests[0]),"delta-alias-admission");
  let execution=firstAdmission.snd;
  for(const request of requests.slice(1))
    execution=accepted(step(execution,request),"delta-successful-admission").snd;
  const find=n=>get("psKernelExprV2DeclarationRefFind")(execution.declarations)(n);
  must(array(execution.declarations).length===9,"delta-only-admitted-declarations-registered");
  must(accepted(accepted(find(polyName),"delta-poly-reference").deltaValue,"delta-poly-body")===polyBody,
    "delta-reference-retains-canonical-body-id");
  const theoremReference=accepted(find(theoremName),"delta-theorem-type-reference");
  const opaqueReference=accepted(find(opaqueName),"delta-opaque-type-reference");
  const referenceKinds=get("PsKernelExprV2DeclarationRefKind");
  must(absent(theoremReference.deltaValue)&&theoremReference.type===proofType&&
    sameRuntimeValue(theoremReference.kind,referenceKinds.theoremDecl),
    "delta-theorem-type-index-does-not-authorize-unfolding");
  must(absent(opaqueReference.deltaValue)&&opaqueReference.type===s1&&
    sameRuntimeValue(opaqueReference.kind,referenceKinds.opaqueDecl),
    "delta-opaque-type-index-does-not-authorize-unfolding");
  const checker=get("psKernelKernelSessionChecker")(execution.session,nil,S.unsafeDef);
  const state=()=>get("psKernelExprV2WhnfStateForDeclarations")(arena,execution.declarations);
  const raw=(fuel,context,root)=>
    get("psKernelExprV2TryWhnfStateWithFuel")(fuel)(context)(state())(root);
  const compareRaw=(fuel,context,root,term,label)=>{
    const original=get("psKernelSessionWhnf")(fuel,{...checker,context},term);
    const attempted=accepted(raw(fuel,context,root),label+"-direct");
    if(rejected(original)){
      ensure(rejected(attempted)&&original.error===attempted.error,label+"-error");
    }else{
      const actual=accepted(attempted,label+"-dag-result");
      const graph=accepted(decode(actual.fst.arena),label+"-valid");
      const value=accepted(decoded(graph,actual.snd),label+"-decoded");
      ensure(exact(accepted(original,label+"-original").fst,value),label+"-value");
    }
  };
  const sameValue=(left,right)=>{
    if(rejected(left)||rejected(right))
      return rejected(left)&&rejected(right)&&sameRuntimeValue(left.error,right.error);
    return exact(accepted(left,"delta-public-original"),accepted(right,"delta-public-dag"));
  };
  const cases=[
    [poly,E.lam(name("A"),E.sort(level2),E.lam(name("x"),E.bvar(0n),E.bvar(0n),B.default),B.default)],
    [partialPoly,E.lam(name("x"),sort1,E.bvar(0n),B.default)],
    [appliedPoly,sort0],[ignoredArgument,sort0],[alias,sort0],
    [opaqueRoot,E.const(opaqueName,nil)],[theoremRoot,E.const(theoremName,nil)],[ma,sort0]
  ];
  let parityCases=0;
  for(const [root,expected]of cases){
    const term=accepted(decoded(built,root),"delta-fixture");
    ensure(exact(accepted(get("psKernelSessionWhnf")(64n,checker,term),"delta-oracle").fst,expected),
      "reference-result-sanity-"+root);
    for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,12n,32n,64n]){
      for(const depth of [0n,1n,2n]){
        const context={...checker.context,maxRecDepth:depth};
        const label="delta-"+root+"-"+fuel+"-"+depth;
        compareRaw(fuel,context,root,term,label);
        const policySession={...execution.session,resources:{
          ...execution.session.resources,fuel,maxRecDepth:depth}};
        // The internal helper relies on RunDag's public preflight.
        const preflight=get("psKernelKernelSessionPreflight")(policySession);
        const actualPublic=rejected(preflight)?preflight:
          get("psKernelDagWhnfExpression")(policySession,nil,S.unsafeDef,arena,built,
            execution.declarations,root,term);
        ensure(sameValue(
          get("psKernelV1Whnf")(policySession,nil,S.unsafeDef,term),
          actualPublic),label+"-public");
        parityCases++;
      }
    }
    for(const recDepth of [15n,16n])
      compareRaw(64n,{...checker.context,maxRecDepth:1n,recDepth},root,term,
        "delta-exact-entry-depth-"+root+"-"+recDepth);
  }
  must(parityCases===264,"delta-raw-and-complete-public-resource-matrix");
  const ignored=accepted(decoded(built,ignoredArgument),"delta-ignored-term");
  const tooSmall=get("psKernelSessionWhnf")(5n,checker,ignored);
  must(rejected(tooSmall)&&tooSmall.error==="kernel reduction budget exhausted",
    "delta-normalizes-ignored-argument-before-unfolding");
  must(exact(accepted(get("psKernelSessionWhnf")(6n,checker,ignored),
    "delta-ignored-threshold").fst,sort0),"delta-ignored-argument-exact-threshold");
  const wrong=accepted(decoded(built,wrongArity),"delta-wrong-level-arity");
  for(const fuel of [0n,1n,2n,3n,8n])
    compareRaw(fuel,checker.context,wrongArity,wrong,"delta-wrong-arity-"+fuel);
  const isInvalid=result=>rejected(result)&&sameRuntimeValue(
    get("psKernelErrorOutcome")(result.error),get("PsKernelOutcome").rejectedInvalid);
  must(isInvalid(run(execution.session,nil,S.safe,arena,list([C.whnf(wrongArity)]))),
    "delta-public-rejects-wrong-universe-arity");
  const cycle=accepted(decoded(built,ca),"delta-cycle");
  for(const fuel of [0n,1n,2n,3n,4n,8n,16n]){
    const original=get("psKernelSessionWhnf")(fuel,checker,cycle);
    ensure(rejected(original)&&original.error==="kernel reduction budget exhausted",
      "delta-cycle-resource-"+fuel);
    compareRaw(fuel,checker.context,ca,cycle,"delta-cycle-parity-"+fuel);
  }
  must(true,"delta-mutual-cycle-exact-fuel-errors");
  const commands=requests.map(request=>C.admit(request));
  for(const [root,safety]of [[appliedPoly,S.safe],[ma,S.unsafeDef]]){
    const result=accepted(run(initial,nil,safety,arena,list([...commands,C.whnf(root)])),
      "delta-full-batch");
    const replies=array(result.replies);
    must(replies.length===commands.length+1&&exact(replies.at(-1).value,sort0),
      "delta-complete-public-admission-and-whnf");
  }
  must(isInvalid(run(initial,nil,S.safe,arena,list([
    C.whnf(alias),C.admit(D.definitionDecl(aliasDef))]))),
    "delta-future-admission-cannot-authorize-earlier-command");
  must(absent(get("psKernelExprV2TryWhnfWithFuel")(64n,checker.context,arena,appliedPoly)),
    "delta-preexisting-session-definition-explicit-fallback");
  const foreignSort=mk(empty,"Sort",L.succ(L.zero));
  must(foreignSort.snd===s0,"delta-foreign-arena-reuses-body-id");
  const foreignAlias=mk(foreignSort.fst,"Const",aliasName,nil);
  const foreignResult=accepted(run(execution.session,nil,S.safe,foreignAlias.fst,
    list([C.whnf(foreignAlias.snd)])),"delta-external-session");
  const foreignReplies=array(foreignResult.replies);
  must(foreignReplies.length===1&&exact(foreignReplies[0].value,sort0),
    "delta-body-index-does-not-escape-owning-arena");
  const badName=name("DagDeltaUnadmitted");
  const invalidRef={...aliasDef,base:{...aliasDef.base,name:badName},value:arena.size};
  const illTyped={...aliasDef,base:{...aliasDef.base,name:badName},value:s1};
  for(const bad of [invalidRef,illTyped]){
    must(isInvalid(step(emptyExecution,D.definitionDecl(bad))),
      "delta-failed-admission-produces-no-execution");
    must(isInvalid(run(initial,nil,S.safe,arena,list([C.admit(D.definitionDecl(bad))]))),
      "delta-invalid-or-illtyped-body-rejected-at-public-boundary");
  }
  must(array(emptyExecution.declarations).length===0&&
    get("psKernelEnvironmentSize")(initial.environment)===0n,
    "delta-failed-admission-preserves-empty-owner");
  const duplicate=step(execution,D.definitionDecl({...aliasDef,value:s1}));
  must(isInvalid(duplicate)&&accepted(accepted(find(aliasName),"delta-retained-alias").deltaValue,"delta-retained-body")===s0,
    "delta-duplicate-cannot-replace-registered-body");
  const bounded={...firstAdmission.snd,session:{...firstAdmission.snd.session,
    resources:{...firstAdmission.snd.session.resources,maxDeclarations:1n}}};
  const limited=step(bounded,D.definitionDecl(polyDef));
  must(rejected(limited)&&sameRuntimeValue(
    get("psKernelErrorOutcome")(limited.error),get("PsKernelOutcome").resourceExhausted)&&
    sameRuntimeValue(limited.error.resource,get("PsKernelResourceError").declarationLimit)&&
    array(bounded.declarations).length===1&&absent(
      get("psKernelExprV2DeclarationRefFind")(bounded.declarations)(polyName)),
    "delta-declaration-limit-failure-publishes-no-reference");
  let typedArena=arena;
  const addTyped=(kind,...args)=>{
    const result=mk(typedArena,kind,...args);typedArena=result.fst;return result.snd;
  };
  const safeAxiomName=name("DagIndexedType"),unsafeAxiomName=name("DagIndexedUnsafeType");
  const partialName=name("DagIndexedPartial"),unsafeOpaqueName=name("DagIndexedUnsafeOpaque");
  const safeAxiom=addTyped("Const",safeAxiomName,nil),unsafeAxiom=addTyped("Const",unsafeAxiomName,nil);
  const partialRoot=addTyped("Const",partialName,nil),unsafeOpaque=addTyped("Const",unsafeOpaqueName,nil);
  const unsafeWrongArity=addTyped("Const",mutualA,list([L.zero]));
  const unknownName=name("DagIndexedUnknown"),unknownRoot=addTyped("Const",unknownName,list([L.zero]));
  const typedBuilt=accepted(decode(typedArena),"constant-index-decode");
  const extraRequests=[
    D.axiomDecl(base(safeAxiomName,s1),false),
    D.axiomDecl(base(unsafeAxiomName,s1),true),
    D.definitionDecl(def(partialName,s1,s0,S.partialDef)),
    D.opaqueDecl(base(unsafeOpaqueName,s1),s0,true)
  ];
  let typedExecution=execution;
  for(const request of extraRequests){
    typedExecution=accepted(get("psKernelDagRunCommand")(typedExecution,nil,S.safe,
      typedArena,typedBuilt,C.admit(request)),"constant-index-admission").snd;
  }
  must(array(typedExecution.declarations).length===13,"constant-index-one-owner-table");
  for(const declaration of array(typedExecution.declarations)){
    const info=accepted(get("psKernelEnvironmentFind")(typedExecution.session.environment,
      declaration.name),"constant-index-live-declaration");
    must(get("psKernelExprV2DeclarationRefMatches")(declaration,info),
      "constant-index-live-metadata-correspondence");
    must(exact(accepted(decoded(typedBuilt,declaration.type),"constant-index-source-type"),
      get("psKernelConstantInfoType")(info)),"constant-index-original-type-installed-unchanged");
  }
  const compareType=(legacy,attempted,label,project=value=>value)=>{
    const reduced=accepted(attempted,label+"-direct");
    if(rejected(legacy)){
      ensure(rejected(reduced)&&legacy.error===reduced.error,label+"-error");
    }else{
      const result=accepted(reduced,label+"-result");
      const graph=accepted(decode(result.fst),label+"-valid");
      const actual=accepted(decoded(graph,result.snd),label+"-type");
      ensure(exact(project(accepted(legacy,label+"-original")),actual),label+"-value");
    }
  };
  const constantCases=[
    [poly,polyName,list([level2])],[alias,aliasName,nil],
    [opaqueRoot,opaqueName,nil],[theoremRoot,theoremName,nil],
    [ma,mutualA,nil],[safeAxiom,safeAxiomName,nil],
    [unsafeAxiom,unsafeAxiomName,nil],[partialRoot,partialName,nil],
    [unsafeOpaque,unsafeOpaqueName,nil]
  ];
  let constantParityCases=0;
  for(const [root,constantName,levels]of constantCases){
    const term=accepted(decoded(typedBuilt,root),"constant-index-fixture");
    for(const safety of [S.safe,S.unsafeDef,S.partialDef]){
      const checker=get("psKernelKernelSessionChecker")(typedExecution.session,nil,safety);
      for(const inferOnly of [false,true]){
        compareType(get("psKernelInferConstantType")(checker.context,constantName,levels,inferOnly),
          get("psKernelExprV2TryInferConstantType")(checker.context,typedArena,
            typedExecution.declarations,constantName,levels,inferOnly),
          "constant-index-reference-rule-"+root+"-"+inferOnly);
      }
      for(const fuel of [0n,1n,2n,3n,4n,8n,64n]){
        for(const recDepth of [0n,15n,16n]){
          const context={...checker.context,maxRecDepth:1n,recDepth};
          compareType(get("psKernelSessionCheck")(fuel,{...checker,context},term),
            get("psKernelExprV2TryCheckWithDeclarationsFuel")(fuel,context,typedArena,
              typedExecution.declarations,root),
            "constant-index-fuel-depth-"+root+"-"+fuel+"-"+recDepth,value=>value.fst);
          constantParityCases++;
        }
      }
    }
  }
  must(constantParityCases===567,"constant-index-direct-fuel-depth-safety-matrix");
  const safeChecker=get("psKernelKernelSessionChecker")(typedExecution.session,nil,S.safe);
  for(const [constantName,expected]of [
    [mutualA,"safe declaration uses unsafe constant"],
    [unsafeAxiomName,"safe declaration uses unsafe constant"],
    [unsafeOpaqueName,"safe declaration uses unsafe constant"],
    [partialName,"safe declaration uses partial constant"]
  ]){
    const result=accepted(get("psKernelExprV2TryInferConstantType")(safeChecker.context,
      typedArena,typedExecution.declarations,constantName,nil,false),"constant-index-safety-direct");
    must(rejected(result)&&result.error===expected,"constant-index-actual-environment-safety");
    must(exact(accepted(get("psKernelInferConstantType")(safeChecker.context,
      constantName,nil,true),"constant-index-infer-only"),sort1),
      "constant-index-infer-only-original-safety-skip");
  }
  const arity=accepted(get("psKernelExprV2TryInferConstantType")(safeChecker.context,
    typedArena,typedExecution.declarations,mutualA,list([L.zero]),false),"constant-index-arity-direct");
  must(rejected(arity)&&arity.error==="incorrect number of universe levels",
    "constant-index-arity-before-safety");
  const unknown=accepted(get("psKernelExprV2TryInferConstantType")(safeChecker.context,
    typedArena,typedExecution.declarations,unknownName,list([L.zero]),false),"constant-index-unknown-direct");
  must(rejected(unknown)&&unknown.error==="unknown constant","constant-index-lookup-before-arity");
  for(const root of [unsafeWrongArity,unknownRoot,wrongArity]){
    const term=accepted(decoded(typedBuilt,root),"constant-index-negative-term");
    compareType(get("psKernelSessionCheck")(8n,safeChecker,term),
      get("psKernelExprV2TryCheckWithDeclarationsFuel")(8n,safeChecker.context,typedArena,
        typedExecution.declarations,root),"constant-index-direct-negative-"+root,value=>value.fst);
  }
  must(absent(get("psKernelExprV2TryCheckWithFuel")(8n,safeChecker.context,typedArena,alias)),
    "constant-index-preexisting-session-explicit-fallback");
  const aliasReference=accepted(get("psKernelExprV2DeclarationRefFind")(
    typedExecution.declarations)(aliasName),"constant-index-alias-reference");
  for(const changed of [
    {...aliasReference,kind:get("PsKernelExprV2DeclarationRefKind").axiomDecl},
    {...aliasReference,levelParams:list([name("wrong-universe-owner")])}
  ]){
    must(absent(get("psKernelExprV2TryInferConstantType")(safeChecker.context,
      typedArena,list([changed]),aliasName,nil,false)),
      "constant-index-kind-or-parameter-mismatch-fallback");
  }
  const allCommands=[...requests,...extraRequests].map(request=>C.admit(request));
  const checkedBatch=accepted(run(initial,nil,S.safe,typedArena,
    list([...allCommands,C.check(poly)])),"constant-index-public-polymorphic-check");
  const polyExpected=E.forallE(name("A"),E.sort(level2),
    E.forallE(name("x"),E.bvar(0n),E.bvar(1n),B.default),B.default);
  const checkedReplies=array(checkedBatch.replies);
  must(checkedReplies.length===allCommands.length+1&&
    exact(checkedReplies.at(-1).value.type,polyExpected),"constant-index-complete-public-check");
  for(const root of [ma,unsafeAxiom,partialRoot,unsafeOpaque])
    must(isInvalid(run(initial,nil,S.safe,typedArena,list([...allCommands,C.check(root)]))),
      "constant-index-complete-public-unsafe-or-partial-rejection");
  const foreignCheck=accepted(run(typedExecution.session,nil,S.safe,foreignAlias.fst,
    list([C.check(foreignAlias.snd)])),"constant-index-foreign-arena");
  const foreignChecked=array(foreignCheck.replies);
  must(foreignChecked.length===1&&exact(foreignChecked[0].value.type,sort1),
    "constant-index-no-cross-arena-reference-leak");
  console.log("PSC1_V2_DAG_JS_CONSTANT_INDEX: PASS");
  console.log("PSC1_V2_DAG_JS_DELTA: PASS");
}

{
  const ErrorKind=get("PsKernelError"),Resource=get("PsKernelResourceError");
  const classify=get("psKernelErrorFromMessage");
  const prefixes=["","nested preprocessing: ","nested transformed admission: ",
    "nested original restoration: ","nested auxiliary restoration: ",
    "nested restored validation: "];
  const resources=[
    ["kernel reduction budget exhausted",Resource.fuel],
    ["kernel inference budget exhausted",Resource.fuel],
    ["deep recursion detected, use maxRecDepth to increase the limit",Resource.recursionDepth],
    ["the kernel refused a Nat numeral because its size exceeds the maximum",Resource.natSize],
    ["the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size",Resource.natSize]
  ];
  for(const prefix of prefixes){
    const invalid=prefix+"invalid projection: structure type mismatch";
    must(sameRuntimeValue(classify(invalid),ErrorKind.rejectedInvalid(invalid)),
      "nested-diagnostic-invalid-exact-"+prefix);
    const unsupported=prefix+"nested or invalid mutual inductive occurrence is not supported";
    must(sameRuntimeValue(classify(unsupported),ErrorKind.declinedUnsupported(unsupported)),
      "nested-diagnostic-unsupported-exact-"+prefix);
    for(const [body,resource]of resources){
      const message=prefix+body;
      must(sameRuntimeValue(classify(message),ErrorKind.resourceExhausted(resource,message)),
        "nested-diagnostic-resource-exact-"+message);
    }
  }
  for(const message of [
    "unrecognized diagnostic",
    "provider: invalid projection: structure type mismatch",
    "nested restored validation: unrecognized diagnostic",
    "nested restored validation: ",
    "nested restored validation:invalid projection: structure type mismatch",
    "nested restored validation: invalid projection: structure type mismatch trailing",
    "nested restored validation: nested restored validation: invalid projection: structure type mismatch",
    "nested preprocessing: nested restored validation: kernel reduction budget exhausted"
  ])must(sameRuntimeValue(classify(message),ErrorKind.internalError(message)),
    "nested-diagnostic-unknown-remains-internal-"+message);
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  must(sameRuntimeValue(get("psKernelResourceMessage")(
    "nested restored validation: kernel reduction budget exhausted"),none),
    "nested-diagnostic-resource-api-remains-bare");
  console.log("PSC1_V2_DAG_JS_NESTED_OUTCOMES: PASS");
}


// DAG binder checking owns local type IDs, fresh names and checked-inference caches.
{
  let binderArena=empty;
  const Lit=get("PsKernelLiteral");
  const build=(kind,term,...args)=>{
    const result=mk(binderArena,kind,...args);
    binderArena=result.fst;
    return {id:result.snd,term};
  };
  const bs=level=>build("Sort",E.sort(level),level);
  const bv=index=>build("BVar",E.bvar(index),index);
  const fv=n=>build("FVar",E.fvar(n),n);
  const mv=n=>build("MVar",E.mvar(n),n);
  const lit=value=>build("Lit",E.lit(value),value);
  const md=(tag,body)=>build("MData",E.mdata(tag,body.term),tag,body.id);
  const lam=(n,domain,body,bi=B.default)=>
    build("Lam",E.lam(n,domain.term,body.term,bi),n,domain.id,body.id,bi);
  const pi=(n,domain,body,bi=B.default)=>
    build("Forall",E.forallE(n,domain.term,body.term,bi),n,domain.id,body.id,bi);
  const app=(fn,arg)=>build("App",E.app(fn.term,arg.term),fn.id,arg.id);
  const s0=bs(L.zero),s1=bs(L.succ(L.zero)),b0=bv(0n),b1=bv(1n);
  const x=name("binder-x"),a=name("binder-a"),y=name("binder-y");
  const fixtures=[
    ["sort",s0],["literal-nat",lit(Lit.nat(65521n))],
    ["literal-string",lit(Lit.str("λ-雪"))],["loose",b0],
    ["unknown",fv(name("binder-outside"))],["metavariable",mv(name("binder-meta"))],
    ["identity",lam(x,s1,b0)],
    ["dependent-lambda",lam(a,s0,lam(x,b0,b0,B.instImplicit),B.implicit)],
    ["dependent-forall",pi(a,s0,pi(x,b0,b1,B.strictImplicit))],
    ["lambda-forall",lam(a,s0,pi(x,b0,b1),B.implicit)],
    ["metadata-body",lam(x,s1,md(7n,b0),B.implicit)],
    ["bad-domain",pi(x,lam(y,s1,b0),s0)],
    ["bad-codomain",pi(x,s0,lam(y,s1,b0))],
    ["raw-forged-fresh-name",lam(x,s1,fv(N.num(x,0n)))],
    ["unknown-under-binder",lam(x,s1,fv(name("binder-outside")))]
  ];
  const emptyCheck=arena=>get("psKernelExprV2CheckStateEmpty")(arena);
  const raw=(fuel,context,state,root)=>
    get("psKernelExprV2TryCheckStateWithFuel")(fuel,
      get("psKernelExprV2CheckContextEmpty")(context),state,root);
  const compareRaw=(original,attempted,label)=>{
    must(attempted&&typeof attempted==="object"&&"value" in attempted,label+"-direct");
    const result=attempted.value;
    if(rejected(original)){
      must(rejected(result)&&original.error===result.error,label+"-error");
    }else{
      const expected=accepted(original,label+"-original"),actual=accepted(result,label+"-result");
      const graph=accepted(decode(actual.fst.whnf.arena),label+"-graph");
      const type=accepted(decoded(graph,actual.snd),label+"-type");
      must(exact(expected.fst,type)===true,label+"-exact-type");
      must(expected.snd.state.nextFresh===actual.fst.nextFresh,label+"-fresh");
    }
  };
  const checkEqual=(expected,actual)=>
    exact(expected.expression,actual.expression)===true&&exact(expected.type,actual.type)===true;
  const publicCheck=(s,node)=>
    sameOperation(get("psKernelV1CheckExpression")(s,nil,S.safe,node.term),
      invoke(binderArena,[C.check(node.id)],s),checkEqual);
  for(const [label,node] of fixtures){
    for(const fuel of [0n,1n,2n,3n,4n,8n,16n,32n,64n])for(const maxDepth of [0n,1n,2n]){
      const s=session(fuel,maxDepth),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
      for(const recDepth of [0n,15n,16n]){
        const context={...checker.context,recDepth};
        compareRaw(get("psKernelSessionCheck")(fuel,{...checker,context},node.term),
          raw(fuel,context,emptyCheck(binderArena),node.id),
          "binder-"+label+"-"+fuel+"-"+maxDepth+"-"+recDepth);
      }
      must(publicCheck(s,node),"binder-public-"+label+"-"+fuel+"-"+maxDepth);
    }
  }
  let domain=s0;
  for(let tag=0n;tag<8n;tag++)domain=md(tag,domain);
  const reused=pi(x,domain,pi(y,domain,domain));
  const callback=lam(a,domain,pi(x,b0,b1),B.implicit);
  for(const [label,node] of [["cache-reuse",reused],["fixed-whnf-fuel",callback]]){
    for(const fuel of [0n,1n,7n,8n,9n,10n,11n,12n,16n,64n]){
      const s=session(fuel),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
      compareRaw(get("psKernelSessionCheck")(fuel,checker,node.term),
        raw(fuel,checker.context,emptyCheck(binderArena),node.id),label+"-"+fuel);
      must(publicCheck(s,node),label+"-public-"+fuel);
    }
    accepted(invoke(binderArena,[C.check(node.id)],session(10n)),label+"-exact-boundary-accepts");
  }
  const s=session(10n,1n),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
  const legacy=accepted(get("psKernelSessionCheck")(10n,checker,reused.term),"binder-warm-legacy");
  const direct=accepted(accepted(raw(10n,checker.context,emptyCheck(binderArena),reused.id),
    "binder-warm-some"),"binder-warm");
  must(direct.fst.nextFresh===2n,"binder-fresh-counter-after-two-scopes");
  must(sameRuntimeValue(get("psKernelExprV2WhnfCacheEntries")(direct.fst.whnf.publicCache),nil),"binder-scope-restores-public-cache");
  for(const [fuel,recDepth] of [[0n,0n],[1n,0n],[1n,16n]]){
    const context={...checker.context,recDepth};
    compareRaw(get("psKernelSessionCheck")(fuel,{...legacy.snd,context},domain.term),
      raw(fuel,context,direct.fst,domain.id),"binder-warm-entry-"+fuel+"-"+recDepth);
  }
  const cold=accepted(raw(1n,checker.context,emptyCheck(direct.fst.whnf.arena),domain.id),
    "binder-cold-some");
  must(rejected(cold)&&cold.error==="kernel inference budget exhausted","binder-cold-domain-fails");
  let hidden=s1;
  for(let tag=0n;tag<8n;tag++)hidden=md(tag+100n,hidden);
  const scoped=lam(x,s0,hidden);
  const scopedLegacy=accepted(get("psKernelSessionCheck")(10n,checker,scoped.term),"binder-scoped-legacy");
  const scopedDirect=accepted(accepted(raw(10n,checker.context,emptyCheck(binderArena),scoped.id),
    "binder-scoped-some"),"binder-scoped");
  const hiddenEntry=accepted(get("psKernelExprV2PagedRequire")(scopedDirect.fst.whnf.arena,hidden.id),
    "binder-hidden-entry");
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  must(sameRuntimeValue(accepted(get("psKernelExprV2CheckedInferFind")(
      scopedDirect.fst,hidden.id,hiddenEntry),"binder-hidden-cache"),none),
    "binder-closed-child-cache-does-not-escape");
  compareRaw(get("psKernelSessionCheck")(1n,scopedLegacy.snd,hidden.term),
    raw(1n,checker.context,scopedDirect.fst,hidden.id),"binder-no-child-cache-fuel-authority");
  const escapedName=N.num(x,0n),escaped=mk(scopedDirect.fst.whnf.arena,"FVar",escapedName);
  const escapedState=get("psKernelExprV2CheckStateWithArena")(scopedDirect.fst,escaped.fst);
  compareRaw(get("psKernelSessionCheck")(64n,scopedLegacy.snd,E.fvar(escapedName)),
    raw(64n,checker.context,escapedState,escaped.snd),"binder-no-local-context-escape");
  const levelA=N.num(name("binder-level"),0n),levelB=N.num(name("binder-level"),65521n);
  const sortA=bs(L.param(levelA)),sortB=bs(L.param(levelB));
  const entryA=accepted(get("psKernelExprV2PagedRequire")(binderArena,sortA.id),"binder-sort-a");
  const entryB=accepted(get("psKernelExprV2PagedRequire")(binderArena,sortB.id),"binder-sort-b");
  must(entryA.hash===entryB.hash,"binder-real-sort-hash-collision");
  const levelChecker=get("psKernelKernelSessionChecker")(session(),list([levelA,levelB]),S.safe);
  const levelLegacy=accepted(get("psKernelSessionCheck")(1n,levelChecker,sortA.term),"binder-level-legacy");
  const levelDirect=accepted(accepted(raw(1n,levelChecker.context,emptyCheck(binderArena),sortA.id),
    "binder-level-some"),"binder-level");
  compareRaw(get("psKernelSessionCheck")(1n,levelLegacy.snd,sortB.term),
    raw(1n,levelChecker.context,levelDirect.fst,sortB.id),"binder-collision-cannot-reuse-wrong-type");
  const locals=get("psKernelLocalContextAddLocal")(levelChecker.context.localContext,x,x,sort0,B.default);
  const outside=get("psKernelCheckerContextWithLocalContext")(levelChecker.context,locals);
  must(sameRuntimeValue(get("psKernelExprV2TryCheckWithFuel")(64n,outside,binderArena,sortA.id),none),
    "binder-does-not-drop-existing-legacy-locals");
  for(const node of [lit(Lit.nat(0n)),lit(Lit.nat(65521n)),lit(Lit.str("λ-雪"))]){
    for(const fuel of [0n,1n,2n,8n])for(const maxNatSize of [0n,7n,8n,16n]){
      const initial=session(fuel),s={...initial,resources:{...initial.resources,maxNatSize}};
      const checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
      compareRaw(get("psKernelSessionCheck")(fuel,checker,node.term),
        raw(fuel,checker.context,emptyCheck(binderArena),node.id),
        "binder-literal-resource-"+fuel+"-"+maxNatSize);
      must(publicCheck(s,node),"binder-literal-public-limit-"+fuel+"-"+maxNatSize);
    }
    const checker=get("psKernelKernelSessionChecker")(session(8n),nil,S.safe);
    const result=accepted(accepted(raw(8n,checker.context,emptyCheck(binderArena),node.id),
      "binder-literal-some"),"binder-literal");
    must(sameRuntimeValue(get("psKernelExprV2WhnfCacheEntries")(result.fst.checkedInfer),nil),"binder-literal-cache-ineligible");
  }
  const letNode=build("Let",E.letE(x,sort1,sort0,E.bvar(0n),false),
    x,s1.id,s0.id,b0.id,false);
  compareRaw(get("psKernelSessionCheck")(64n,checker,letNode.term),
    raw(64n,checker.context,emptyCheck(binderArena),letNode.id),"binder-let-now-direct");
  must(publicCheck(session(),letNode),"binder-let-public-parity");
  const invalidProjection=build("Proj",E.proj(name("binder-unknown-structure"),0n,sort0),
    name("binder-unknown-structure"),0n,s0.id);
  must(rejected(accepted(get("psKernelExprV2TryCheckWithFuel")(
    64n,checker.context,binderArena,invalidProjection.id),"binder-projection-direct")),
    "binder-projection-now-direct-negative");
  must(publicCheck(session(),invalidProjection),"binder-projection-public-negative-parity");
  const cheap=[
    s0,lam(x,s1,b0),app(lam(x,s1,b0),s0),app(lam(x,s1,s0),s1),
    app(lam(x,s1,b1),s0),app(lam(x,s1,md(7n,b0)),s0),
    app(app(lam(x,s1,lam(y,s1,b1)),s0),s1),
    app(app(lam(x,s1,b0),s0),s1)
  ];
  for(const node of cheap){
    const result=accepted(get("psKernelExprV2CheapBetaOnCanonical")(binderArena,node.id),
      "binder-cheap-beta");
    const graph=accepted(decode(result.fst),"binder-cheap-graph");
    const actual=accepted(decoded(graph,result.snd),"binder-cheap-result");
    must(exact(get("psKernelExprCheapBetaReduce")(node.term),actual)===true,
      "binder-exact-cheap-beta");
  }
  // Checked applications take the original structural-type-equality fast path.
  {
    const ax=name("app-x"),aa=name("app-a"),ay=name("app-y"),af=name("app-f");
    const identity=lam(ax,s1,b0);
    const family=lam(aa,s1,lam(ax,b0,b0),B.implicit);
    const proposition=pi(ax,s0,b0);
    let functionType=pi(ax,s1,s1);
    for(let tag=0n;tag<8n;tag++)functionType=md(tag+800n,functionType);
    const appFixtures=[
      ["identity",app(identity,s0)],
      ["dependent",app(family,s0)],
      ["dependent-second-argument",app(app(family,s0),proposition)],
      ["metadata-function",app(md(5n,identity),s0)],
      ["under-local-binders",
        lam(aa,s0,lam(ax,b0,app(lam(ay,b1,b0),b0)))],
      ["function-type-whnf",lam(af,functionType,app(b0,s0))],
      ["function-type-whnf-under-binder",lam(af,functionType,lam(ax,s0,app(b1,s0)))],
      ["invalid-function",app(s0,s0)],
      ["invalid-argument",app(identity,b0)]
    ];
    for(const [label,node] of appFixtures){
      for(const fuel of [0n,1n,2n,3n,4n,8n,10n,11n,12n,16n,32n,64n])
      for(const maxDepth of [0n,1n,2n]){
        const s=session(fuel,maxDepth),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
        for(const recDepth of [0n,13n,14n,15n,16n]){
          const context={...checker.context,recDepth};
          compareRaw(get("psKernelSessionCheck")(fuel,{...checker,context},node.term),
            raw(fuel,context,emptyCheck(binderArena),node.id),
            "application-"+label+"-"+fuel+"-"+maxDepth+"-"+recDepth);
        }
        must(publicCheck(s,node),"application-public-"+label+"-"+fuel+"-"+maxDepth);
      }
    }
    const appFallbacks=[
      ["metadata-conversion",app(lam(ax,md(900n,s1),b0),s0),true]
    ];
    for(const [label,node,acceptedExpected] of appFallbacks){
      for(const fuel of [0n,1n,2n,3n,4n,8n,16n,64n]){
        const s=session(fuel,1n),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
        for(const recDepth of [0n,15n,16n]){
          const context={...checker.context,recDepth};
          const attempted=raw(fuel,context,emptyCheck(binderArena),node.id);
          compareRaw(get("psKernelSessionCheck")(fuel,{...checker,context},node.term),
            attempted,"application-prefix-conversion-"+label+"-"+fuel+"-"+recDepth);
        }
        must(publicCheck(s,node),"application-prefix-conversion-public-"+label+"-"+fuel);
      }
      const s=session(64n,1n),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
      accepted(accepted(raw(64n,checker.context,emptyCheck(binderArena),node.id),
        "application-explicit-prefix-some-"+label),"application-explicit-prefix-success-"+label);
      const result=get("psKernelV1CheckExpression")(s,nil,S.safe,node.term);
      const isAccepted=result&&typeof result==="object"&&"value" in result;
      must(isAccepted===acceptedExpected,"application-defeq-result-"+label);
    }
    const numeralArgument=app(identity,lit(Lit.nat(0n)));
    for(const fuel of [0n,1n,2n,3n,4n,8n])for(const maxNatSize of [0n,7n]){
      const initial=session(fuel,1n),s={...initial,resources:{...initial.resources,maxNatSize}};
      const checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
      compareRaw(get("psKernelSessionCheck")(fuel,checker,numeralArgument.term),
        raw(fuel,checker.context,emptyCheck(binderArena),numeralArgument.id),
        "application-nat-limit-before-type-comparison-"+fuel+"-"+maxNatSize);
      must(publicCheck(s,numeralArgument),
        "application-public-nat-limit-before-type-comparison-"+fuel+"-"+maxNatSize);
    }
    const node=app(identity,s0);
    const s=session(64n,1n),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
    const legacy=accepted(get("psKernelSessionCheck")(64n,checker,node.term),"application-warm-legacy");
    const direct=accepted(accepted(raw(64n,checker.context,emptyCheck(binderArena),node.id),
      "application-warm-some"),"application-warm-result");
    const entry=accepted(get("psKernelExprV2PagedRequire")(direct.fst.whnf.arena,node.id),
      "application-source-entry");
    must(sameRuntimeValue(accepted(get("psKernelExprV2CheckedInferFind")(
      direct.fst,node.id,entry),"application-cache-lookup"),none),
      "application-ineligible-for-checked-cache");
    for(const recDepth of [0n,15n,16n]){
      const context={...checker.context,recDepth};
      compareRaw(get("psKernelSessionCheck")(1n,{...legacy.snd,context},node.term),
        raw(1n,context,direct.fst,node.id),
        "application-cannot-skip-function-check-on-warm-result-"+recDepth);
    }
  }
  console.log("PSC1_V2_DAG_JS_CHECK_APP: PASS");
}
console.log("PSC1_V2_DAG_JS_BINDER: PASS");


{
  const initial=session();
  const aName=name("DagIndexMutualA"),bName=name("DagIndexMutualB");
  const aCtor=N.str(aName,"mk"),bCtor=N.str(bName,"mk");
  let graph=empty;
  const build=(kind,...args)=>{const v=mk(graph,kind,...args);graph=v.fst;return v.snd;};
  const header=build("Sort",L.succ(L.zero));
  const a=build("Const",aName,nil),b=build("Const",bName,nil);
  const ca=build("Const",aCtor,nil),cb=build("Const",bCtor,nil);
  const first={name:aName,type:header,ctors:list([{name:aCtor,type:a}])};
  const second={name:bName,type:header,ctors:list([{name:bCtor,type:b}])};
  const group={levelParams:nil,numParams:0n,types:list([first,second]),isUnsafe:false};
  const request=D.mutualInductive(group),input=accepted(decode(graph),"mutual-index-input");
  const emptyOwner={session:initial,declarations:nil};
  const execution=accepted(get("psKernelDagRunCommand")(emptyOwner,nil,S.safe,graph,input,
    C.admit(request)),"mutual-index-admission").snd;
  must(array(execution.declarations).length===4,"mutual-index-input-count");
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  for(const declaration of array(execution.declarations)){
    const info=accepted(get("psKernelEnvironmentFind")(execution.session.environment,
      declaration.name),"mutual-index-live-info");
    must(get("psKernelExprV2DeclarationRefMatches")(declaration,info)&&
      sameRuntimeValue(declaration.deltaValue,none)&&
      exact(accepted(decoded(input,declaration.type),"mutual-index-input-type"),
        get("psKernelConstantInfoType")(info)),"mutual-index-original-type-correspondence");
  }
  const compare=(owner,roots,label)=>{
    const checker=get("psKernelKernelSessionChecker")(owner.session,nil,S.safe);
    let comparisons=0;
    for(const root of roots)for(const fuel of [0n,1n,2n,8n])
      for(const recDepth of [0n,15n,16n]){
        const context={...checker.context,maxRecDepth:1n,recDepth};
        const term=accepted(decoded(input,root),label+"-term");
        const original=get("psKernelSessionCheck")(fuel,{...checker,context},term);
        const attempted=accepted(get("psKernelExprV2TryCheckWithDeclarationsFuel")(
          fuel,context,graph,owner.declarations,root),label+"-required-direct");
        if(rejected(original)){
          if(!rejected(attempted)||original.error!==attempted.error)
            throw Error(label+" error parity "+root+"/"+fuel+"/"+recDepth);
        }else{
          const inferred=accepted(attempted,label+"-success");
          const resultGraph=accepted(decode(inferred.fst),label+"-result-graph");
          if(!exact(accepted(original,label+"-original").fst,
            accepted(decoded(resultGraph,inferred.snd),label+"-result-type")))
            throw Error(label+" type parity "+root+"/"+fuel+"/"+recDepth);
        }
        comparisons++;
      }
    return comparisons;
  };
  must(compare(execution,[a,b,ca,cb],"mutual-index")===48,
    "mutual-index-direct-fuel-depth-matrix");
  const checker=get("psKernelKernelSessionChecker")(execution.session,nil,S.safe);
  const recName=get("psKernelSimpleRecName")(aName);
  const recInfo=accepted(get("psKernelEnvironmentFind")(execution.session.environment,
    recName),"mutual-index-generated-recursor");
  const recLevels=list(array(get("psKernelConstantInfoLevelParams")(recInfo)).map(()=>L.zero));
  const withRec=mk(graph,"Const",recName,recLevels);
  must(sameRuntimeValue(get("psKernelExprV2DeclarationRefFind")(execution.declarations)(recName),none),
    "mutual-index-no-generated-recursor-ref");
  must(sameRuntimeValue(get("psKernelExprV2TryCheckWithDeclarationsFuel")(
    64n,checker.context,withRec.fst,execution.declarations,withRec.snd),none),
    "mutual-index-correct-arity-generated-recursor-fallback");
  const publicResult=accepted(run(initial,nil,S.safe,withRec.fst,
    list([C.admit(request),C.check(a),C.check(ca),C.check(b),C.check(cb),C.check(withRec.snd)])),
    "mutual-index-complete-public-checks");
  must(array(publicResult.replies).length===6,"mutual-index-public-reply-count");
  const isInvalid=result=>rejected(result)&&sameRuntimeValue(
    get("psKernelErrorOutcome")(result.error),get("PsKernelOutcome").rejectedInvalid);
  const badFirst={...first,ctors:list([{name:aCtor,type:b}])};
  const bad=D.mutualInductive({...group,types:list([badFirst,second])});
  must(isInvalid(get("psKernelDagRunCommand")(emptyOwner,nil,S.safe,graph,input,C.admit(bad)))&&
    array(emptyOwner.declarations).length===0,"mutual-index-failed-bundle-no-owner");
  must(array(get("psKernelDagDeclarationsAfterAdmission")(D.nestedInductive(group),nil)).length===0,
    "mutual-index-nested-restoration-fallback");
  must(isInvalid(run(initial,nil,S.safe,graph,list([
    C.admit(D.mutualInductive({...group,isUnsafe:true})),C.check(ca)]))),
    "mutual-index-live-unsafe-constructor-rejection");
  const ordinary=D.ordinaryInductive(nil,0n,first,false);
  const ordinaryOwner=accepted(get("psKernelDagRunCommand")(emptyOwner,nil,S.safe,graph,input,
    C.admit(ordinary)),"ordinary-index-admission").snd;
  must(array(ordinaryOwner.declarations).length===2,"ordinary-index-input-count");
  for(const declaration of array(ordinaryOwner.declarations)){
    const info=accepted(get("psKernelEnvironmentFind")(ordinaryOwner.session.environment,
      declaration.name),"ordinary-index-live-info");
    must(get("psKernelExprV2DeclarationRefMatches")(declaration,info)&&
      sameRuntimeValue(declaration.deltaValue,none)&&
      exact(accepted(decoded(input,declaration.type),"ordinary-index-input-type"),
        get("psKernelConstantInfoType")(info)),"ordinary-index-original-type-correspondence");
  }
  must(compare(ordinaryOwner,[a,ca],"ordinary-index")===24,
    "ordinary-index-direct-fuel-depth-matrix");
  console.log("PSC1_V2_DAG_JS_MUTUAL_INDEX: PASS");
}


// Complete checked projection rules use one admitted declaration owner.
{
  let graph=empty;
  const a=name("projection-A"),x=name("projection-x"),p=name("projection-P"),u=name("projection-u");
  const pairName=name("DagCheckDependentPair"),polyName=name("DagCheckPolyBox");
  const dataPropName=name("DagCheckDataProp"),proofName=name("DagCheckProofBox");
  const pairCtor=N.str(pairName,"mk"),polyCtor=N.str(polyName,"mk");
  const dataPropCtor=N.str(dataPropName,"mk"),proofCtor=N.str(proofName,"mk");
  const build=(kind,term,...args)=>{
    const result=mk(graph,kind,...args); graph=result.fst; return {id:result.snd,term};
  };
  const sort=level=>build("Sort",E.sort(level),level);
  const bv=index=>build("BVar",E.bvar(index),index);
  const con=(n,levels=[])=>build("Const",E.const(n,list(levels)),n,list(levels));
  const app=(fn,arg)=>build("App",E.app(fn.term,arg.term),fn.id,arg.id);
  const pi=(n,d,b)=>build("Forall",E.forallE(n,d.term,b.term,B.default),n,d.id,b.id,B.default);
  const lam=(n,d,b)=>build("Lam",E.lam(n,d.term,b.term,B.default),n,d.id,b.id,B.default);
  const md=(tag,b)=>build("MData",E.mdata(tag,b.term),tag,b.id);
  const proj=(n,index,b)=>build("Proj",E.proj(n,index,b.term),n,index,b.id);
  const u1=L.succ(L.zero),lu=L.param(u),s0=sort(L.zero),s1=sort(u1);
  const su=sort(lu),s2=sort(L.succ(u1)),b0=bv(0n),b1=bv(1n);
  const pairType=con(pairName),dataPropType=con(dataPropName);
  const dependentCtor=result=>pi(a,s1,pi(x,b0,result));
  const polyType=pi(a,su,su),polyCtorType=pi(a,su,pi(x,b0,app(con(polyName,[lu]),b1)));
  const proofType=pi(p,s0,s0),proofCtorType=pi(p,s0,pi(x,b0,app(con(proofName),b1)));
  const specifications=[
    [pairName,[],s2,dependentCtor(pairType),0n],
    [polyName,[u],polyType,polyCtorType,1n],
    [dataPropName,[],s0,dependentCtor(dataPropType),0n],
    [proofName,[],proofType,proofCtorType,1n]
  ];
  const requests=specifications.map(([n,levels,type,ctorType,numParams])=>
    D.ordinaryInductive(list(levels),numParams,{
      name:n,type:type.id,ctors:list([{name:N.str(n,"mk"),type:ctorType.id}])
    },false));
  const tautology=pi(p,s0,pi(x,b0,b1)),tautologyProof=lam(p,s0,lam(x,b0,b0));
  const pairValue=app(app(con(pairCtor),s0),tautology);
  const polyValue=app(app(con(polyCtor,[u1]),s0),tautology);
  const dataPropValue=app(app(con(dataPropCtor),s0),tautology);
  const proofValue=app(app(con(proofCtor),tautology),tautologyProof);
  const pairFirst=proj(pairName,0n,pairValue),pairSecond=proj(pairName,1n,pairValue);
  let hiddenPair=pairValue;
  for(let tag=0n;tag<8n;tag++)hiddenPair=md(tag+910n,hiddenPair);
  const fixtures=[
    ["dependent-first",pairFirst],["dependent-second",pairSecond],
    ["parameter-and-universe",proj(polyName,0n,polyValue)],
    ["proof-field",proj(proofName,0n,proofValue)],
    ["proof-data-field",proj(dataPropName,0n,dataPropValue)],
    ["proof-dependent-data-field",proj(dataPropName,1n,dataPropValue)],
    ["metadata-value",proj(pairName,1n,hiddenPair)],
    ["under-binder",lam(x,pairType,proj(pairName,1n,b0))],
    ["wrong-type-name",proj(polyName,0n,pairValue)],
    ["invalid-index",proj(pairName,2n,pairValue)],
    ["large-index",proj(pairName,4294967296n,pairValue)],
    ["non-structure",proj(pairName,0n,s0)],
    ["invalid-value-before-index",proj(pairName,4294967296n,b0)]
  ];
  const input=accepted(decode(graph),"projection-input");
  const initial=session();
  let execution={session:initial,declarations:nil};
  for(const request of requests){
    execution=accepted(get("psKernelDagRunCommand")(
      execution,nil,S.safe,graph,input,C.admit(request)),"projection-admission").snd;
  }
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  must(array(execution.declarations).length===8,"projection-index-original-input-types-only");
  for(const declaration of array(execution.declarations)){
    const info=accepted(get("psKernelEnvironmentFind")(
      execution.session.environment,declaration.name),"projection-index-live-info");
    const type=accepted(decoded(input,declaration.type),"projection-index-input-type");
    must(get("psKernelExprV2DeclarationRefMatches")(declaration,info)===true&&
      exact(type,get("psKernelConstantInfoType")(info))===true,
      "projection-index-type-correspondence");
    must(sameRuntimeValue(declaration.deltaValue,none),"projection-index-has-no-delta-body");
  }
  const checker=get("psKernelKernelSessionChecker")(execution.session,nil,S.safe);
  const stateFor=arena=>get("psKernelExprV2CheckStateWithWhnf")(
    get("psKernelExprV2CheckStateEmpty")(arena),
    get("psKernelExprV2WhnfStateForDeclarations")(arena,execution.declarations));
  const raw=(fuel,context,state,root)=>get("psKernelExprV2TryCheckStateWithFuel")(fuel,
    get("psKernelExprV2CheckContextEmpty")(context),state,root);
  const compareRaw=(original,attempted,label)=>{
    must(attempted&&typeof attempted==="object"&&"value" in attempted,label+"-direct");
    const actual=attempted.value;
    if(rejected(original)){
      must(rejected(actual)&&original.error===actual.error,label+"-error");
    }else{
      const expected=accepted(original,label+"-original"),result=accepted(actual,label+"-result");
      const decodedGraph=accepted(decode(result.fst.whnf.arena),label+"-graph");
      const type=accepted(decoded(decodedGraph,result.snd),label+"-type");
      must(exact(expected.fst,type)===true,label+"-exact-type");
      must(expected.snd.state.nextFresh===result.fst.nextFresh,label+"-fresh");
    }
  };
  const sameChecked=(left,right)=>{
    if(rejected(left)||rejected(right))
      return rejected(left)&&rejected(right)&&sameRuntimeValue(left.error,right.error);
    const a=accepted(left,"projection-public-left"),b=accepted(right,"projection-public-right");
    return exact(a.expression,b.expression)===true&&exact(a.type,b.type)===true;
  };
  for(const [label,node] of fixtures){
    for(const fuel of [0n,1n,2n,3n,4n,5n,6n,8n,10n,12n,16n,32n,64n])
    for(const maxDepth of [0n,1n,2n]){
      for(const recDepth of [0n,13n,14n,15n,16n]){
        const context={...checker.context,maxRecDepth:maxDepth,recDepth};
        compareRaw(get("psKernelSessionCheck")(fuel,{...checker,context},node.term),
          raw(fuel,context,stateFor(graph),node.id),
          "projection-check-"+label+"-"+fuel+"-"+maxDepth+"-"+recDepth);
      }
      const s={...execution.session,resources:{...execution.session.resources,fuel,maxRecDepth:maxDepth}};
      const preflight=get("psKernelKernelSessionPreflight")(s);
      const actual=rejected(preflight)?preflight:get("psKernelDagCheckExpression")(
        s,nil,S.safe,graph,input,execution.declarations,node.id,node.term);
      must(sameChecked(get("psKernelV1CheckExpression")(s,nil,S.safe,node.term),actual),
        "projection-public-fuel-"+label+"-"+fuel+"-"+maxDepth);
    }
    const original=get("psKernelV1CheckExpression")(execution.session,nil,S.safe,node.term);
    const actual=run(initial,nil,S.safe,graph,list([...requests.map(r=>C.admit(r)),C.check(node.id)]));
    if(rejected(original)){
      must(rejected(actual)&&sameRuntimeValue(original.error,actual.error),
        "projection-real-batch-negative-"+label);
    }else{
      const expected=accepted(original,"projection-real-legacy");
      const result=accepted(actual,"projection-real-batch");
      const replies=array(result.replies),last=replies.at(-1);
      must(replies.length===requests.length+1&&last&&typeof last==="object"&&"value" in last,
        "projection-real-batch-reply-"+label);
      must(exact(expected.expression,last.value.expression)===true&&
        exact(expected.type,last.value.type)===true,"projection-real-batch-positive-"+label);
    }
  }

  const boundedContext={...checker.context,maxRecDepth:1n};
  const legacyWarm=accepted(get("psKernelSessionCheck")(
    64n,{...checker,context:boundedContext},pairFirst.term),"projection-warm-legacy");
  const dagWarm=accepted(accepted(raw(64n,boundedContext,stateFor(graph),pairFirst.id),
    "projection-warm-some"),"projection-warm-result");
  for(const [fuel,recDepth] of [[0n,0n],[1n,0n],[1n,15n],[1n,16n]]){
    const context={...boundedContext,recDepth};
    compareRaw(get("psKernelSessionCheck")(fuel,{...legacyWarm.snd,context},pairFirst.term),
      raw(fuel,context,dagWarm.fst,pairFirst.id),"projection-warm-cache-entry-"+fuel+"-"+recDepth);
  }
  const secondType=accepted(get("psKernelSessionCheck")(64n,checker,pairSecond.term),
    "projection-dependent-legacy-type");
  must(exact(secondType.fst,pairFirst.term)===true,
    "projection-dependent-result-keeps-earlier-projection");
  for(const [node,message] of [
    [fixtures[4][1],"invalid projection: proof structure field is not a proposition"],
    [fixtures[5][1],"invalid projection: proof structure depends on data field"]
  ]){
    const result=get("psKernelSessionCheck")(64n,checker,node.term);
    must(rejected(result)&&result.error===message,"projection-proof-structure-rejection");
  }
  must(sameRuntimeValue(get("psKernelExprV2TryCheckWithFuel")(
    64n,checker.context,graph,pairFirst.id),none),"projection-external-owner-remains-fallback");
  const whnf=context=>state=>root=>
    get("psKernelExprV2CheckWhnfWithFuel")(64n,context,state,root);
  const check=context=>state=>root=>
    get("psKernelExprV2TryCheckStateWithFuel")(64n,context,state,root);
  const context=get("psKernelExprV2CheckContextEmpty")(checker.context);
  const paramZero=accepted(get("psKernelExprV2CheckProjectionApplyParamsWithFuel")(0n)
    (whnf)(context)(stateFor(graph))(nil)(0n)(0n)(pairFirst.id),"projection-param-zero-some");
  must(rejected(paramZero)&&paramZero.error==="kernel projection parameter budget exhausted",
    "projection-parameter-zero-budget");
  const fieldZero=accepted(get("psKernelExprV2CheckProjectionSkipFieldsWithFuel")(0n)
    (check)(whnf)(context)(stateFor(graph))(pairName)(pairFirst.id)(false)(0n)(0n)(pairFirst.id),
    "projection-field-zero-some");
  must(rejected(fieldZero)&&fieldZero.error==="kernel projection field budget exhausted",
    "projection-field-zero-budget");
  const sortZero=accepted(get("psKernelExprV2CheckProjectionSortWith")(
    context=>state=>root=>get("psKernelExprV2CheckWhnfWithFuel")(0n,context,state,root),
    context,stateFor(graph),s0.id),
    "projection-sort-zero-some");
  must(rejected(sortZero)&&sortZero.error==="kernel reduction budget exhausted",
    "projection-sort-does-not-skip-whnf-budget");
  console.log("PSC1_V2_DAG_JS_CHECK_PROJECTION: PASS");
}

// Checked lets own local values and restore child semantic caches.
{
  let letArena=empty;
  const Lit=get("PsKernelLiteral");
  const build=(kind,term,...args)=>{
    const result=mk(letArena,kind,...args);
    letArena=result.fst;
    return {id:result.snd,term};
  };
  const bs=level=>build("Sort",E.sort(level),level);
  const bv=index=>build("BVar",E.bvar(index),index);
  const fv=n=>build("FVar",E.fvar(n),n);
  const lit=value=>build("Lit",E.lit(value),value);
  const md=(tag,body)=>build("MData",E.mdata(tag,body.term),tag,body.id);
  const lam=(n,domain,body,bi=B.default)=>
    build("Lam",E.lam(n,domain.term,body.term,bi),n,domain.id,body.id,bi);
  const pi=(n,domain,body,bi=B.default)=>
    build("Forall",E.forallE(n,domain.term,body.term,bi),n,domain.id,body.id,bi);
  const app=(fn,arg)=>build("App",E.app(fn.term,arg.term),fn.id,arg.id);
  const le=(n,type,value,body,nondep=false)=>
    build("Let",E.letE(n,type.term,value.term,body.term,nondep),
      n,type.id,value.id,body.id,nondep);
  const one=L.succ(L.zero),two=L.succ(one);
  const s0=bs(L.zero),s1=bs(one),s2=bs(two),b0=bv(0n),b1=bv(1n);
  const duplicateOne=bs(L.max(one,one));
  const x=name("let-x"),a=name("let-a"),f=name("let-f"),y=name("let-y");
  const functionType=pi(x,s1,s1);
  let hiddenFunctionType=functionType;
  for(let tag=0n;tag<8n;tag++)hiddenFunctionType=md(9100n+tag,hiddenFunctionType);
  const fixtures=[
    ["unused",le(a,s1,s0,s1)],
    ["body-local",le(a,s1,s0,b0)],
    ["nondep-hint",le(a,s1,s0,s1,true)],
    ["dependent-result",le(a,s1,s0,lam(x,b0,b0))],
    ["sort-local-value",le(a,s2,s1,pi(x,b0,pi(y,b0,b1)))],
    ["function-local-value",le(a,s2,functionType,lam(f,b0,app(b0,s0)))],
    ["function-local-value-metadata",le(a,s2,hiddenFunctionType,lam(f,b0,app(b0,s0)))],
    ["nested-same-name",le(a,s1,s0,le(a,s1,b0,b0))],
    ["inside-lambda",lam(x,s1,le(y,s1,b0,b0))],
    ["sort-conversion",le(a,duplicateOne,s0,b0)],
    ["metadata-body",le(a,s1,s0,md(3n,b0))],
    ["bad-value-type",le(a,s1,s1,b0)],
    ["bad-declared-type",le(a,lam(x,s1,b0),s0,b0)],
    ["loose-value",le(a,s1,b0,b0)],
    ["unknown-body",le(a,s1,s0,fv(name("let-outside")))],
    ["bad-body-app",le(a,s1,s0,app(s0,s0))]
  ];
  const numeralBody=le(a,s1,s0,lit(Lit.nat(65521n)));
  const escaped=fv(N.num(a,0n));
  const cacheX=name("let-cache-x"),cacheW=name("let-cache-w");
  const cacheA=name("let-cache-a"),cacheB=name("let-cache-b");
  let outerLeft=s1,outerRight=duplicateOne,innerLeft=s2,innerRight=bs(L.max(two,two));
  for(let tag=0n;tag<8n;tag++){
    outerLeft=md(9200n+tag,outerLeft);outerRight=md(9300n+tag,outerRight);
    innerLeft=md(9400n+tag,innerLeft);innerRight=md(9500n+tag,innerRight);
  }
  const cacheTerm=le(cacheA,outerRight,fv(cacheX),le(cacheB,innerRight,fv(cacheW),s0));
  const wx=name("let-whnf-x"),wy=name("let-whnf-y"),wf=name("let-whnf-f");
  const wxNode=fv(wx),wyNode=fv(wy),wfNode=fv(wf);
  const identity=lam(name("let-whnf-arg"),s1,b0);
  const identityType=pi(name("let-whnf-arg"),s1,s1);
  const localApp=app(wfNode,s0);
  let metadataAlias=wyNode;
  for(let tag=0n;tag<8n;tag++)metadataAlias=md(tag,metadataAlias);
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  const emptyCheck=arena=>get("psKernelExprV2CheckStateEmpty")(arena);
  const emptyContext=context=>get("psKernelExprV2CheckContextEmpty")(context);
  const raw=(fuel,context,state,root)=>
    get("psKernelExprV2TryCheckStateWithFuel")(fuel,context,state,root);
  const eqRaw=(fuel,context,state,left,right)=>
    get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(context)(state)(left)(right);
  const compareRaw=(original,attempted,label)=>{
    const actual=accepted(attempted,label+"-direct");
    if(rejected(original))must(rejected(actual)&&original.error===actual.error,label+"-error");
    else {
      const expected=accepted(original,label+"-original"),result=accepted(actual,label+"-actual");
      const graph=accepted(decode(result.fst.whnf.arena),label+"-graph");
      must(exact(expected.fst,accepted(decoded(graph,result.snd),label+"-type"))===true,
        label+"-exact-type");
      must(expected.snd.state.nextFresh===result.fst.nextFresh,label+"-fresh");
    }
  };
  const compareEq=(original,attempted,label)=>{
    const actual=accepted(attempted,label+"-direct");
    if(rejected(original))must(rejected(actual)&&original.error===actual.error,label+"-error");
    else {
      const expected=accepted(original,label+"-original"),result=accepted(actual,label+"-actual");
      must(typeof expected.fst==="boolean"&&typeof result.snd==="boolean"&&
        expected.fst===result.snd,label+"-boolean");
    }
  };
  const checkEqual=(expected,actual)=>
    exact(expected.expression,actual.expression)===true&&exact(expected.type,actual.type)===true;
  const publicCheck=(s,node)=>sameOperation(
    get("psKernelV1CheckExpression")(s,nil,S.safe,node.term),
    invoke(letArena,[C.check(node.id)],s),checkEqual);

  for(const [label,node] of fixtures){
    for(const fuel of [0n,1n,2n,3n,4n,8n,10n,11n,12n,16n,64n])
      for(const maxDepth of [0n,1n]){
        const s=session(fuel,maxDepth),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
        for(const recDepth of [0n,15n,16n]){
          const context={...checker.context,recDepth};
          compareRaw(get("psKernelSessionCheck")(fuel,{...checker,context},node.term),
            raw(fuel,emptyContext(context),emptyCheck(letArena),node.id),
            "let-"+label+"-"+fuel+"-"+maxDepth+"-"+recDepth);
        }
        must(publicCheck(s,node),"let-public-"+label+"-"+fuel+"-"+maxDepth);
      }
  }
  for(const fuel of [0n,1n,2n,3n,8n])for(const limit of [0n,7n,8n,16n]){
    const initial=session(fuel),s={...initial,resources:{...initial.resources,maxNatSize:limit}};
    const checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
    compareRaw(get("psKernelSessionCheck")(fuel,checker,numeralBody.term),
      raw(fuel,emptyContext(checker.context),emptyCheck(letArena),numeralBody.id),
      "let-numeral-order-"+fuel+"-"+limit);
    must(publicCheck(s,numeralBody),"let-numeral-public-order-"+fuel+"-"+limit);
  }
  const base=get("psKernelKernelSessionChecker")(session(64n,1n),nil,S.safe);
  const warmNode=fixtures[1][1];
  const legacyWarm=accepted(get("psKernelSessionCheck")(64n,base,warmNode.term),"let-warm-legacy");
  const directWarm=accepted(accepted(raw(64n,emptyContext(base.context),emptyCheck(letArena),
    warmNode.id),"let-warm-some"),"let-warm-result");
  for(const [fuel,recDepth] of [[0n,0n],[1n,0n],[1n,15n],[1n,16n]]){
    const context={...base.context,recDepth};
    compareRaw(get("psKernelSessionCheck")(fuel,{...legacyWarm.snd,context},warmNode.term),
      raw(fuel,emptyContext(context),directWarm.fst,warmNode.id),
      "let-warm-entry-"+fuel+"-"+recDepth);
  }
  compareRaw(get("psKernelSessionCheck")(64n,legacyWarm.snd,escaped.term),
    raw(64n,emptyContext(base.context),directWarm.fst,escaped.id),"let-local-value-does-not-escape");
  console.log("PSC1_V2_DAG_JS_CHECK_LET: PASS");

  const cacheOld1=get("psKernelLocalContextAddLocal")(
    base.context.localContext,cacheX,cacheX,outerLeft.term,B.default);
  const cacheOld2=get("psKernelLocalContextAddLocal")(
    cacheOld1,cacheW,cacheW,innerLeft.term,B.default);
  const cacheOldContext=get("psKernelCheckerContextWithLocalContext")(base.context,cacheOld2);
  const cacheTyped1=get("psKernelExprV2CheckContextWithLocal")(
    emptyContext(base.context),cacheX,cacheX,outerLeft.id,B.default);
  const cacheTyped=get("psKernelExprV2CheckContextWithLocal")(
    cacheTyped1,cacheW,cacheW,innerLeft.id,B.default);
  const cacheLegacy=accepted(get("psKernelSessionCheck")(
    64n,{...base,context:cacheOldContext},cacheTerm.term),"let-cache-legacy");
  const cacheDirect=accepted(accepted(raw(64n,cacheTyped,emptyCheck(letArena),cacheTerm.id),
    "let-cache-some"),"let-cache-result");
  must(cacheLegacy.snd.state.nextFresh===2n&&cacheDirect.fst.nextFresh===2n,
    "let-nested-scopes-preserve-monotone-fresh");
  for(const [fuel,recDepth] of [[0n,0n],[1n,0n],[1n,15n],[1n,16n]]){
    const old={...cacheOldContext,recDepth},typed={...cacheTyped,scalar:{...base.context,recDepth}};
    compareEq(get("psKernelSessionIsDefEq")(
      fuel,{...cacheLegacy.snd,context:old},outerLeft.term,outerRight.term),
      eqRaw(fuel,typed,cacheDirect.fst,outerLeft.id,outerRight.id),
      "let-parent-success-entry-"+fuel+"-"+recDepth);
  }
  const parentHit=accepted(accepted(eqRaw(1n,cacheTyped,cacheDirect.fst,
    outerLeft.id,outerRight.id),"let-parent-hit-some"),"let-parent-hit-result");
  must(parentHit.snd===true,"let-parent-comparison-survives-scope");
  const cold=eqRaw(1n,cacheTyped,emptyCheck(letArena),outerLeft.id,outerRight.id);
  compareEq(get("psKernelSessionIsDefEq")(
    1n,{...base,context:cacheOldContext},outerLeft.term,outerRight.term),cold,
    "let-parent-cold-needs-recursion");
  const coldResult=accepted(cold,"let-cold-some");
  must(rejected(coldResult)&&coldResult.error==="kernel definitional equality budget exhausted",
    "let-parent-cold-is-not-syntax");
  const child=eqRaw(1n,cacheTyped,cacheDirect.fst,innerLeft.id,innerRight.id);
  compareEq(get("psKernelSessionIsDefEq")(
    1n,cacheLegacy.snd,innerLeft.term,innerRight.term),child,
    "let-child-success-pair-restored-away");
  const childResult=accepted(child,"let-child-some");
  must(rejected(childResult)&&childResult.error==="kernel definitional equality budget exhausted",
    "let-child-comparison-cannot-authorize-parent");
  console.log("PSC1_V2_DAG_JS_LET_CACHE_SCOPE: PASS");

  const old1=get("psKernelLocalContextAddLet")(base.context.localContext,wx,wx,s1.term,s0.term);
  const old2=get("psKernelLocalContextAddLet")(old1,wy,wy,s1.term,wxNode.term);
  const old3=get("psKernelLocalContextAddLet")(old2,wf,wf,identityType.term,identity.term);
  const new1=get("psKernelExprV2CheckContextWithLet")(emptyContext(base.context),wx,wx,s1.id,s0.id);
  const new2=get("psKernelExprV2CheckContextWithLet")(new1,wy,wy,s1.id,wxNode.id);
  const new3=get("psKernelExprV2CheckContextWithLet")(new2,wf,wf,identityType.id,identity.id);
  const shadowOld=get("psKernelLocalContextAddLocal")(old3,wx,wx,s1.term,B.default);
  const shadowNew=get("psKernelExprV2CheckContextWithLocal")(new3,wx,wx,s1.id,B.default);
  const whnfRaw=(fuel,context,state,root)=>
    get("psKernelExprV2CheckWhnfWithFuel")(fuel,context,state,root);
  const compareWhnf=(original,attempted,label)=>{
    const actual=accepted(attempted,label+"-direct");
    if(rejected(original))must(rejected(actual)&&actual.error===original.error,label+"-error");
    else {
      const expected=accepted(original,label+"-original"),result=accepted(actual,label+"-actual");
      const graph=accepted(decode(result.fst.arena),label+"-graph");
      must(exact(expected.fst,accepted(decoded(graph,result.snd),label+"-expr"))===true,
        label+"-exact");
    }
  };
  const whnfCases=[
    ["one-local",wxNode,old3,new3],["alias-chain",wyNode,old3,new3],
    ["metadata-chain",metadataAlias,old3,new3],["local-function",localApp,old3,new3],
    ["value-free-shadow",wxNode,shadowOld,shadowNew]
  ];
  for(const [label,node,oldLocals,newLocals] of whnfCases){
    for(const maxRecDepth of [0n,1n])for(const recDepth of [0n,15n,16n]){
      const scalar={...base.context,maxRecDepth,recDepth};
      const old=get("psKernelCheckerContextWithLocalContext")(scalar,oldLocals);
      const next={...newLocals,scalar};
      for(const fuel of [0n,1n,2n,3n,4n,12n,64n]){
        const state=get("psKernelExprV2WhnfStateEmpty")(letArena);
        compareWhnf(get("psKernelSessionWhnf")(fuel,{...base,context:old},node.term),
          whnfRaw(fuel,next,state,node.id),"let-local-public-"+label+"-"+fuel+"-"+recDepth);
        for(const cheapProj of [false,true]){
          const core=get("psKernelExprV2CheckWhnfCoreWithFuel")(fuel,next,state,node.id,cheapProj);
          compareWhnf(get("psKernelWhnfCoreWithRecursorFuel")(fuel,
            get("psKernelIsDefEqWithFuel")(fuel),old,base.state,node.term,false,cheapProj),
            core,"let-local-core-"+label+"-"+fuel+"-"+recDepth+"-"+cheapProj);
        }
      }
    }
  }
  const whnfState=get("psKernelExprV2WhnfStateEmpty")(letArena);
  const exhausted=accepted(whnfRaw(2n,new3,whnfState,wxNode.id),"let-local-fuel-two-direct");
  must(rejected(exhausted)&&exhausted.error==="kernel reduction budget exhausted",
    "let-local-public-keeps-predecessor-core-budget");
  compareWhnf(get("psKernelSessionWhnf")(3n,
    {...base,context:get("psKernelCheckerContextWithLocalContext")(base.context,old3)},wxNode.term),
    whnfRaw(3n,new3,whnfState,wxNode.id),"let-local-fuel-three");
  const mixed={...shadowNew,
    scalar:get("psKernelCheckerContextWithLocalContext")(base.context,old3)};
  must(sameRuntimeValue(whnfRaw(64n,mixed,whnfState,wxNode.id),none),
    "let-mixed-local-representations-request-fallback");
  for(const cheapProj of [false,true])must(sameRuntimeValue(
    get("psKernelExprV2CheckWhnfCoreWithFuel")(64n,mixed,whnfState,wxNode.id,cheapProj),none),
    "let-mixed-core-representations-request-fallback-"+cheapProj);
  const badState=emptyCheck(letArena);
  const opened={context:emptyContext(base.context),parent:badState,fresh:wx,body:b1.id};
  must(get("psKernelExprHasLooseBVarAt")(b1.term,0n)===false,
    "let-range-is-not-exact-index-occurrence");
  must(sameRuntimeValue(get("psKernelExprV2CheckCloseLet")(opened,badState,b1.id,b1.id,
    wy,s1.id,s0.id,false),none),"let-close-unproved-context-requests-fallback");
  console.log("PSC1_V2_DAG_JS_LET_LOCAL_WHNF: PASS");
}

{
  let pairArena=empty;
  const build=(kind,term,...args)=>{
    const result=mk(pairArena,kind,...args);pairArena=result.fst;
    return {id:result.snd,term};
  };
  const bs=level=>build("Sort",E.sort(level),level);
  const md=(tag,body)=>build("MData",E.mdata(tag,body.term),tag,body.id);
  const one=L.succ(L.zero),s1=bs(one),equivalent=bs(L.max(one,one));
  const left=md(0n,s1),right=md(1n,equivalent),collision=md(65521n,s1);
  const copyLeft=md(0n,s1),copyRight=md(1n,equivalent);
  const localName=name("pair-local");
  const localNode=build("FVar",E.fvar(localName),localName);
  const Lit=get("PsKernelLiteral");
  const lit=value=>build("Lit",E.lit(value),value);
  const negatives=[
    ["sort-false",bs(L.zero),s1],
    ["literal-false",lit(Lit.nat(7n)),lit(Lit.nat(8n))],
    ["string-false",lit(Lit.str("a")),lit(Lit.str("b"))]
  ];
  const checker=get("psKernelKernelSessionChecker")(session(64n,1n),nil,S.safe);
  const ctx=scalar=>get("psKernelExprV2CheckContextEmpty")(scalar);
  const context=ctx(checker.context),emptyState=get("psKernelExprV2CheckStateEmpty")(pairArena);
  const raw=(fuel,context,state,left,right)=>
    get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(context)(state)(left)(right);
  const compare=(original,attempted,label)=>{
    const actual=accepted(attempted,label+"-direct");
    if(rejected(original))must(rejected(actual)&&actual.error===original.error,label+"-error");
    else{
      const expected=accepted(original,label+"-original"),result=accepted(actual,label+"-actual");
      must(typeof expected.fst==="boolean"&&typeof result.snd==="boolean"&&
        expected.fst===result.snd,label+"-boolean");
    }
  };
  const legacy=accepted(get("psKernelSessionIsDefEq")(
    64n,checker,left.term,right.term),"pair-prime-legacy");
  const direct=accepted(accepted(raw(64n,context,emptyState,left.id,right.id),
    "pair-prime-some"),"pair-prime-result");
  must(legacy.fst===true&&direct.snd===true,"pair-prime-true");
  must(array(direct.fst.success).length===2,"pair-prime-child-and-parent");
  must(left.id!==copyLeft.id&&right.id!==copyRight.id,"pair-distinct-structural-copies");
  for(const [label,l,r] of [["forward",left,right],["reverse",right,left],
    ["structural-copy",copyLeft,copyRight]]){
    for(const fuel of [0n,1n,2n])for(const recDepth of [0n,15n,16n]){
      const scalar={...checker.context,recDepth};
      compare(get("psKernelSessionIsDefEq")(fuel,{...legacy.snd,context:scalar},l.term,r.term),
        raw(fuel,ctx(scalar),direct.fst,l.id,r.id),"pair-warm-"+label+"-"+fuel+"-"+recDepth);
    }
  }
  const duplicate=accepted(get("psKernelExprV2CheckStateDefEqFinish")(
    direct.fst,copyRight.id,copyLeft.id,true),"pair-duplicate-finish");
  must(duplicate.snd===true&&array(duplicate.fst.success).length===array(direct.fst.success).length,
    "pair-success-set-deduplicates");
  const untouched=accepted(get("psKernelExprV2CheckStateDefEqFinish")(
    direct.fst,left.id,right.id,false),"pair-false-finish");
  must(untouched.snd===false&&array(untouched.fst.success).length===array(direct.fst.success).length,
    "pair-false-does-not-publish");
  const entry=id=>accepted(get("psKernelExprV2PagedRequire")(pairArena,id),"pair-entry");
  must(entry(left.id).hash===entry(collision.id).hash&&
    equal(left.term,collision.term)===false,"pair-real-unequal-hash-collision");
  for(const pair of array(direct.fst.success)){
    const expected=(entry(pair.left).hash+entry(pair.right).hash)%get("psKernelCacheHashModulus");
    must(pair.hash===expected,"pair-original-modular-hash-filter");
  }
  const contains=(state,l,r)=>accepted(get("psKernelExprV2DefEqPairContains")(
    pairArena,state.success,l,r),"pair-contains");
  must(contains(direct.fst,collision.id,right.id)===false,
    "pair-hash-collision-cannot-authorize-hit");
  const missed=raw(1n,context,direct.fst,collision.id,right.id);
  compare(get("psKernelSessionIsDefEq")(1n,legacy.snd,collision.term,right.term),missed,
    "pair-collision-low-fuel");
  const missedResult=accepted(missed,"pair-collision-some");
  must(rejected(missedResult)&&missedResult.error==="kernel definitional equality budget exhausted",
    "pair-collision-keeps-child-fuel-error");

  compare(get("psKernelSessionIsDefEq")(1n,checker,left.term,right.term),
    raw(1n,context,emptyState,left.id,right.id),"pair-fresh-owner-has-no-receipt");
  const localResult=accepted(accepted(raw(1n,context,emptyState,localNode.id,localNode.id),
    "pair-local-some"),"pair-local-result");
  must(localResult.snd===true&&array(localResult.fst.success).length===0,
    "pair-free-variable-syntax-does-not-publish");
  must(contains(localResult.fst,localNode.id,localNode.id)===false,
    "pair-free-variable-is-not-semantic-key");
  must(rejected(get("psKernelExprV2DefEqPairContains")(
    pairArena,direct.fst.success,pairArena.size,right.id)),"pair-invalid-query-id-rejected");
  const secondLegacy=accepted(get("psKernelSessionIsDefEq")(
    64n,legacy.snd,right.term,collision.term),"pair-second-legacy");
  const secondDirect=accepted(accepted(raw(64n,context,direct.fst,right.id,collision.id),
    "pair-second-some"),"pair-second-result");
  must(secondLegacy.fst===true&&secondDirect.snd===true&&
    contains(secondDirect.fst,left.id,collision.id)===false,"pair-no-transitive-closure");
  compare(get("psKernelSessionIsDefEq")(1n,secondLegacy.snd,left.term,collision.term),
    raw(1n,context,secondDirect.fst,left.id,collision.id),"pair-transitivity-keeps-fuel-error");
  for(const [label,l,r] of negatives){
    for(const fuel of [0n,1n,2n,8n])for(const recDepth of [0n,15n,16n]){
      const scalar={...checker.context,recDepth};
      compare(get("psKernelSessionIsDefEq")(fuel,{...checker,context:scalar},l.term,r.term),
        raw(fuel,ctx(scalar),emptyState,l.id,r.id),"pair-"+label+"-"+fuel+"-"+recDepth);
    }
    const result=accepted(accepted(raw(8n,context,emptyState,l.id,r.id),
      "pair-negative-some-"+label),"pair-negative-result-"+label);
    must(result.snd===false&&array(result.fst.success).length===0,
      "pair-negative-does-not-publish-"+label);
  }
  console.log("PSC1_V2_DAG_JS_STATEFUL_DEFEQ: PASS");
}

{
  let convertArena=empty;
  const build=(kind,term,...args)=>{
    const result=mk(convertArena,kind,...args);convertArena=result.fst;
    return {id:result.snd,term};
  };
  const bs=level=>build("Sort",E.sort(level),level);
  const bv=index=>build("BVar",E.bvar(index),index);
  const fv=n=>build("FVar",E.fvar(n),n);
  const md=(tag,body)=>build("MData",E.mdata(tag,body.term),tag,body.id);
  const lam=(n,domain,body)=>build("Lam",E.lam(n,domain.term,body.term,B.default),
    n,domain.id,body.id,B.default);
  const pi=(n,domain,body)=>build("Forall",E.forallE(n,domain.term,body.term,B.default),
    n,domain.id,body.id,B.default);
  const app=(fn,arg)=>build("App",E.app(fn.term,arg.term),fn.id,arg.id);
  const le=(n,type,value,body)=>build("Let",E.letE(n,type.term,value.term,body.term,false),
    n,type.id,value.id,body.id,false);
  const cn=(n,levels=nil)=>build("Const",E.const(n,levels),n,levels);
  const one=L.succ(L.zero),s0=bs(L.zero),s1=bs(one),s2=bs(L.succ(one));
  const duplicate=bs(L.max(one,one)),b0=bv(0n),b1=bv(1n);
  const x=name("app-convert-x"),f=name("app-convert-f");
  const leftType=md(610n,s1),rightType=md(611n,duplicate);
  const functionType=pi(x,rightType,s1);
  const fixtures=[
    ["sort-equivalent",app(lam(x,duplicate,b0),s0),true],
    ["sort-different",app(lam(x,s1,b0),s1),false],
    ["paired-metadata",lam(f,functionType,lam(x,leftType,app(b1,b0))),true],
    ["paired-metadata-different",lam(f,functionType,lam(x,md(610n,s2),app(b1,b0))),false]
  ];
  const emptyContext=scalar=>get("psKernelExprV2CheckContextEmpty")(scalar);
  const emptyState=()=>get("psKernelExprV2CheckStateEmpty")(convertArena);
  const raw=(fuel,context,state,root)=>
    get("psKernelExprV2TryCheckStateWithFuel")(fuel,context,state,root);
  const compare=(original,attempted,label)=>{
    const actual=accepted(attempted,label+"-direct");
    if(rejected(original))must(rejected(actual)&&actual.error===original.error,label+"-error");
    else{
      const expected=accepted(original,label+"-original"),result=accepted(actual,label+"-actual");
      const graph=accepted(decode(result.fst.whnf.arena),label+"-graph");
      must(exact(expected.fst,accepted(decoded(graph,result.snd),label+"-type"))===true,
        label+"-exact-type");
      must(expected.snd.state.nextFresh===result.fst.nextFresh,label+"-fresh");
    }
  };
  const checkEqual=(expected,actual)=>exact(expected.expression,actual.expression)===true&&
    exact(expected.type,actual.type)===true;
  for(const [label,node,expectedAccepted] of fixtures){
    for(const fuel of [0n,1n,2n,3n,4n,8n,10n,11n,12n,16n,32n,64n])
      for(const maxDepth of [0n,1n,2n]){
        const s=session(fuel,maxDepth),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
        for(const recDepth of [0n,13n,14n,15n,16n]){
          const scalar={...checker.context,recDepth};
          compare(get("psKernelSessionCheck")(fuel,{...checker,context:scalar},node.term),
            raw(fuel,emptyContext(scalar),emptyState(),node.id),
            "app-conversion-"+label+"-"+fuel+"-"+maxDepth+"-"+recDepth);
        }
        must(sameOperation(get("psKernelV1CheckExpression")(s,nil,S.safe,node.term),
          invoke(convertArena,[C.check(node.id)],s),checkEqual),
          "app-conversion-public-"+label+"-"+fuel+"-"+maxDepth);
      }
    const result=invoke(convertArena,[C.check(node.id)],session(64n));
    const isAccepted=result&&typeof result==="object"&&"value" in result;
    must(isAccepted===expectedAccepted,"app-conversion-result-"+label);
  }
  console.log("PSC1_V2_DAG_JS_APP_CONVERSION: PASS");

  const cacheX=name("app-cache-x"),cacheF=name("app-cache-f"),cacheA=name("app-cache-let");
  let cacheLeft=s1,cacheRight=duplicate;
  for(let tag=0n;tag<8n;tag++){
    cacheLeft=md(10100n+tag,cacheLeft);cacheRight=md(10200n+tag,cacheRight);
  }
  const cacheFunction=pi(name("app-cache-domain"),cacheRight,s1);
  const cacheXNode=fv(cacheX),cacheFNode=fv(cacheF);
  const prime=le(cacheA,cacheRight,cacheXNode,s0),cacheApp=app(cacheFNode,cacheXNode);
  const checker=get("psKernelKernelSessionChecker")(session(64n,1n),nil,S.safe);
  const old1=get("psKernelLocalContextAddLocal")(
    checker.context.localContext,cacheX,cacheX,cacheLeft.term,B.default);
  const old2=get("psKernelLocalContextAddLocal")(
    old1,cacheF,cacheF,cacheFunction.term,B.default);
  const oldContext=get("psKernelCheckerContextWithLocalContext")(checker.context,old2);
  const typed1=get("psKernelExprV2CheckContextWithLocal")(
    emptyContext(checker.context),cacheX,cacheX,cacheLeft.id,B.default);
  const typedContext=get("psKernelExprV2CheckContextWithLocal")(
    typed1,cacheF,cacheF,cacheFunction.id,B.default);
  const legacy=accepted(get("psKernelSessionCheck")(
    64n,{...checker,context:oldContext},prime.term),"app-prime-legacy");
  const direct=accepted(accepted(raw(64n,typedContext,emptyState(),prime.id),
    "app-prime-some"),"app-prime-result");
  const contains=state=>accepted(get("psKernelExprV2DefEqPairContains")(
    state.whnf.arena,state.success,cacheLeft.id,cacheRight.id),"app-pair-contains");
  must(contains(direct.fst)===true,"app-let-primes-own-success-pair");
  for(const fuel of [0n,1n,2n,3n,8n,64n])for(const recDepth of [0n,13n,14n,15n,16n]){
    const old={...oldContext,recDepth};
    const typed={...typedContext,scalar:{...checker.context,recDepth}};
    compare(get("psKernelSessionCheck")(fuel,{...legacy.snd,context:old},cacheApp.term),
      raw(fuel,typed,direct.fst,cacheApp.id),"app-warm-conversion-"+fuel+"-"+recDepth);
    compare(get("psKernelSessionCheck")(fuel,{...checker,context:old},cacheApp.term),
      raw(fuel,typed,emptyState(),cacheApp.id),"app-cold-conversion-"+fuel+"-"+recDepth);
  }
  const warm=accepted(accepted(raw(2n,typedContext,direct.fst,cacheApp.id),
    "app-two-fuel-some"),"app-two-fuel-result");
  must(warm.fst.nextFresh===direct.fst.nextFresh,"app-warm-two-fuel-uses-own-pair");
  const cold=accepted(raw(2n,typedContext,emptyState(),cacheApp.id),"app-cold-two-some");
  must(rejected(cold)&&cold.error==="kernel definitional equality budget exhausted",
    "app-cold-two-fuel-keeps-defeq-budget");
  const coldLegacy=accepted(get("psKernelSessionCheck")(
    64n,{...checker,context:oldContext},cacheApp.term),"app-cold-legacy");
  const coldDirect=accepted(accepted(raw(64n,typedContext,emptyState(),cacheApp.id),
    "app-cold-some"),"app-cold-result");
  must(contains(coldDirect.fst)===true,"app-retains-new-comparison-state");
  compare(get("psKernelSessionCheck")(2n,coldLegacy.snd,cacheApp.term),
    raw(2n,typedContext,coldDirect.fst,cacheApp.id),"app-reuses-new-comparison-state");

  const syntaxX=name("app-syntax-x"),syntaxF=name("app-syntax-f");
  const syntaxType=pi(name("app-syntax-domain"),s1,s1);
  const syntaxApp=app(fv(syntaxF),fv(syntaxX));
  const oldSyntax1=get("psKernelLocalContextAddLocal")(
    checker.context.localContext,syntaxX,syntaxX,s1.term,B.default);
  const oldSyntax2=get("psKernelLocalContextAddLocal")(
    oldSyntax1,syntaxF,syntaxF,syntaxType.term,B.default);
  const oldSyntax=get("psKernelCheckerContextWithLocalContext")(checker.context,oldSyntax2);
  const typedSyntax1=get("psKernelExprV2CheckContextWithLocal")(
    emptyContext(checker.context),syntaxX,syntaxX,s1.id,B.default);
  const typedSyntax=get("psKernelExprV2CheckContextWithLocal")(
    typedSyntax1,syntaxF,syntaxF,syntaxType.id,B.default);
  const syntaxState=emptyState();
  compare(get("psKernelSessionCheck")(2n,{...checker,context:oldSyntax},syntaxApp.term),
    raw(2n,typedSyntax,syntaxState,syntaxApp.id),"app-syntax-original-shortcut");
  const syntaxResult=accepted(accepted(raw(2n,typedSyntax,syntaxState,syntaxApp.id),
    "app-syntax-some"),"app-syntax-result");
  must(array(syntaxResult.fst.success).length===0,
    "app-syntax-does-not-enter-defeq-or-publish-pair");
  console.log("PSC1_V2_DAG_JS_APP_CONVERSION_CACHE: PASS");

  const marker=cn(get("psKernelEagerReduceName"));
  const markerLevels=cn(get("psKernelEagerReduceName"),list([L.zero]));
  const oneArg=app(marker,s0),twoArgs=app(oneArg,s1);
  const markers=[
    ["arity-zero",marker,false],["arity-one",oneArg,false],
    ["arity-two",twoArgs,true],["arity-three",app(twoArgs,s0),false],
    ["levels-do-not-change-marker",app(app(markerLevels,s0),s1),true],
    ["metadata-head",app(app(md(8n,marker),s0),s1),false],
    ["metadata-whole",md(8n,twoArgs),false],
    ["metadata-argument",app(oneArg,md(8n,s1)),true],
    ["wrong-name",app(app(cn(name("not-eagerReduce")),s0),s1),false]
  ];
  const markerLocal=name("app-marker-local");
  for(const [label,node,expected] of markers){
    must(get("psKernelExprIsEagerReduce")(node.term)===expected,
      "app-original-marker-"+label);
    for(const initial of [false,true]){
      const scalar={...checker.context,eagerReduce:initial,recDepth:7n,maxNatSize:1234n};
      const context=get("psKernelExprV2CheckContextWithLocal")(
        emptyContext(scalar),markerLocal,markerLocal,s1.id,B.default);
      const actual=accepted(get("psKernelExprV2CheckApplicationEqContext")(
        context,convertArena,node.id),"app-eager-context");
      must(sameRuntimeValue(actual,{...context,scalar:{...scalar,eagerReduce:initial||expected}}),
        "app-eager-exact-context-"+label+"-"+initial);
      must(rejected(get("psKernelExprV2CheckApplicationEqContext")(
        context,convertArena,convertArena.size)),"app-eager-invalid-id-"+label+"-"+initial);
    }
  }
  console.log("PSC1_V2_DAG_JS_APP_EAGER_CONTEXT: PASS");
}

{
  const H=get("PsKernelReducibilityHints"),Reply=get("PsKernelDagReply"),
    Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  const declName=name("AdmissionCase"),u=name("admission-u"),x=name("admission-x");
  let graph=empty;
  const put=(kind,...args)=>{const r=mk(graph,kind,...args);graph=r.fst;return r.snd;};
  const base=(params,type)=>({name:declName,levelParams:list(params),type});
  const s0=put("Sort",L.zero),s1=put("Sort",L.succ(L.zero)),
    equivalentS1=put("Sort",L.max(L.succ(L.zero),L.succ(L.zero))),
    su=put("Sort",L.param(u)),sm=put("Sort",L.mvar(u)),mv=put("MVar",u),fv=put("FVar",u),
    b0=put("BVar",0n),bothBad=put("App",mv,fv),
    unknown=put("Const",name("admission-unknown"),nil),
    identity=put("Lam",x,s1,b0,B.default),identityType=put("Forall",x,s1,s1,B.default),
    hiddenS1=put("MData",901n,s1),b1=put("BVar",1n),
    proofTailType=put("Forall",x,b0,b1,B.default),proofTail=put("Lam",x,b0,b0,B.default),
    proofType=put("Forall",u,s0,proofTailType,B.default),proof=put("Lam",u,s0,proofTail,B.default);
  const defn=(type,value,safety)=>D.definitionDecl({base:base([],type),value,
    hints:H.regular(7n),safety});
  const cases=[
    ["axiom-safe",D.axiomDecl(base([],s1),false),true],
    ["axiom-unsafe",D.axiomDecl(base([],s1),true),true],
    ["definition-safe",defn(s1,s0,S.safe),true],
    ["definition-partial",defn(s1,s0,S.partialDef),true],
    ["opaque-safe",D.opaqueDecl(base([],s1),s0,false),true],
    ["opaque-unsafe-annotation",D.opaqueDecl(base([],s1),s0,true),true],
    ["definition-mismatch",defn(s1,s1,S.safe),true],
    ["opaque-mismatch",D.opaqueDecl(base([],s1),s1,false),true],
    ["universe-equivalence",defn(equivalentS1,s0,S.safe),true],
    ["lambda-body",defn(identityType,identity,S.safe),true],
    ["polymorphic-header",D.axiomDecl(base([u],su),false),true],
    ["header-mvar-before-fvar",D.axiomDecl(base([],bothBad),false),true],
    ["header-level-mvar",D.axiomDecl(base([u],sm),false),true],
    ["header-fvar",D.axiomDecl(base([],fv),false),true],
    ["duplicate-universe-before-mvar",D.axiomDecl(base([u,u],mv),false),true],
    ["undefined-universe-before-body-mvar",defn(su,mv,S.safe),true],
    ["body-mvar-before-fvar",defn(s1,bothBad,S.safe),true],
    ["body-fvar",defn(s1,fv,S.safe),true],
    ["body-undefined-universe",defn(s1,su,S.safe),true],
    ["header-loose-bvar",D.axiomDecl(base([],b0),false),true],
    ["body-loose-bvar",defn(s1,b0,S.safe),true],
    ["unknown-header",D.axiomDecl(base([],unknown),false),true],
    ["header-not-sort",D.axiomDecl(base([],identity),false),true],
    ["final-defeq-prefix",defn(hiddenS1,s0,S.safe),true],
    ["unsafe-definition-direct",defn(s1,s0,S.unsafeDef),true],
    ["theorem-direct",D.theoremDecl(base([],proofType),proof),true]
  ];
  const built=accepted(decode(graph),"admission-matrix-decode");
  let comparisons=0;
  for(const [label,request,directExpected] of cases){
    const oldRequest=accepted(get("psKernelDagDecodeDeclaration")(built,request),
      "admission-matrix-request-"+label);
    for(const fuel of [0n,1n,2n,3n,4n,5n,8n,64n])for(const maxDepth of [0n,1n]){
      const seed=session(fuel,maxDepth);
      const direct=get("psKernelDagTryAdmitSimpleWithFuel")(
        fuel,get("psKernelKernelSessionEnvironment")(seed),maxDepth,
        seed.resources.maxNatSize,graph,nil,request,oldRequest);
      const selected=!sameRuntimeValue(direct,none);
      if(!selected)must(!directExpected,"admission-permitted-fallback-"+label);
      else{
        const attempted=accepted(direct,"admission-direct-some-"+label);
        must(sameRuntimeValue(get("psKernelV1DispatchDeclaration")(seed,oldRequest),
          get("psKernelV1EnvironmentOutcome")(attempted)),
          "admission-raw-parity-"+label+"-"+fuel+"-"+maxDepth);
      }
      const original=get("psKernelV1AdmitDeclaration")(seed,oldRequest),
        actual=run(seed,nil,S.safe,graph,list([C.admit(request)]));
      if(rejected(original)||rejected(actual)){
        must(rejected(original)&&rejected(actual)&&sameRuntimeValue(original.error,actual.error),
          "admission-public-error-"+label+"-"+fuel+"-"+maxDepth);
      }else{
        const a=accepted(original,"admission-public-old"),b=accepted(actual,"admission-public-dag");
        must(sameRuntimeValue(a.session,b.session)&&
          sameRuntimeValue(b.replies,list([Reply.admitted(a.declaration.receipt)])),
          "admission-public-result-"+label+"-"+fuel+"-"+maxDepth);
        for(const info of array(b.session.environment.constants)){
          const stored=accepted(get("psKernelEnvironmentFind")(
            b.session.environment,get("psKernelConstantInfoName")(info)),"admission-index");
          must(sameRuntimeValue(info,stored),"admission-list-index-correspondence-"+label);
        }
      }
      if(fuel===64n)must(selected===directExpected,"admission-explicit-path-"+label);
      comparisons++;
    }
  }
  must(comparisons===416,"admission-matrix-count");
  console.log("PSC1_V2_DAG_JS_SIMPLE_ADMISSION_MATRIX: PASS");
}

{
  const H=get("PsKernelReducibilityHints"),CI=get("PsKernelConstantInfo");
  for(const [layers,fuel,maxDepth,coldMessage] of [
    [4,5n,0n,"kernel inference budget exhausted"],
    [14,64n,1n,"deep recursion detected, use maxRecDepth to increase the limit"]
  ]){
    const seed=session(fuel,maxDepth),aName=name("AdmissionHeaderA"+layers),
      dName=name("AdmissionHeaderD"+layers),xName=name("admission-header-x");
    let graph=empty;
    const put=(kind,...args)=>{const r=mk(graph,kind,...args);graph=r.fst;return r.snd;};
    let typeRoot=put("Sort",L.succ(L.zero));
    for(let tag=0;tag<layers;tag++)typeRoot=put("MData",BigInt(tag),typeRoot);
    const b0=put("BVar",0n),fn=put("Lam",xName,typeRoot,b0,B.default),
      aRoot=put("Const",aName,nil),bodyRoot=put("App",fn,aRoot);
    const built=accepted(decode(graph),"admission-shared-decode");
    const type=accepted(decoded(built,typeRoot),"admission-shared-type"),
      body=accepted(decoded(built,bodyRoot),"admission-shared-body");
    const aRequest=D.axiomDecl({name:aName,levelParams:nil,type:typeRoot},false);
    const dRequest=D.definitionDecl({
      base:{name:dName,levelParams:nil,type:typeRoot},value:bodyRoot,
      hints:H.abbrevHint,safety:S.safe});
    const admitted=accepted(get("psKernelDagRunCommand")(
      {session:seed,declarations:nil},nil,S.safe,graph,built,C.admit(aRequest)),
      "admission-shared-admit-axiom");
    const owner=admitted.snd,checker=get("psKernelKernelSessionChecker")(owner.session,nil,S.safe);
    const context=get("psKernelExprV2CheckContextEmpty")(checker.context);
    const initial=get("psKernelExprV2CheckStateWithWhnf")(
      get("psKernelExprV2CheckStateEmpty")(graph),
      get("psKernelExprV2WhnfStateForDeclarations")(graph,owner.declarations));
    const base={name:dName,levelParams:nil,type},
      value={base,value:body,hints:H.abbrevHint,safety:S.safe};
    const oldHeader=accepted(get("psKernelCheckConstantBaseWithSession")(
      fuel,checker,base),"admission-shared-old-header");
    const afterHeader=accepted(accepted(get("psKernelExprV2AdmissionCheckHeaderWithFuel")(
      fuel,context,initial,base,typeRoot),"admission-shared-header-some"),
      "admission-shared-header-ok");
    const oldBody=accepted(get("psKernelCheckDefinitionBodyWithSession")(
      fuel,oldHeader,value),"admission-shared-old-body");
    const warmBody=accepted(get("psKernelExprV2AdmissionCheckBodyWithFuel")(
      fuel,context,afterHeader,base,typeRoot,body,bodyRoot,"definition type mismatch"),
      "admission-shared-body-some");
    accepted(warmBody,"admission-shared-body-ok");
    must(oldBody.state.nextFresh===1n,"admission-shared-header-fresh-counter-"+layers);
    const coldLegacy=get("psKernelCheckDefinitionBodyWithSession")(fuel,checker,value),
      coldDag=accepted(get("psKernelExprV2AdmissionCheckBodyWithFuel")(
        fuel,context,initial,base,typeRoot,body,bodyRoot,"definition type mismatch"),
        "admission-cold-body-some");
    must(rejected(coldLegacy)&&rejected(coldDag)&&
      coldLegacy.error===coldMessage&&coldDag.error===coldMessage,
      "admission-fresh-body-would-change-resource-result-"+layers);
    const request=accepted(get("psKernelDagDecodeDeclaration")(built,dRequest),
      "admission-shared-request");
    accepted(accepted(get("psKernelDagTryAdmitSimpleWithFuel")(
      fuel,get("psKernelKernelSessionEnvironment")(owner.session),maxDepth,
      owner.session.resources.maxNatSize,graph,owner.declarations,dRequest,request),
      "admission-shared-selected"),"admission-shared-direct-ok");
    const original=accepted(get("psKernelV1AdmitDeclaration")(owner.session,request),
      "admission-shared-original");
    const actual=accepted(run(seed,nil,S.safe,graph,list([C.admit(aRequest),C.admit(dRequest)])),
      "admission-shared-public");
    must(sameRuntimeValue(actual.session,original.session),
      "admission-shared-public-complete-parity-"+layers);
    const info=accepted(get("psKernelEnvironmentFind")(actual.session.environment,dName),
      "admission-shared-info");
    // Decode an independent expected record through authentic PSC1 constructors;
    // hand-written JS structure literals lack their nominal Symbol brands.
    const expectedDefinition=accepted(get("psKernelDagDecodeDefinition")(built,{
      base:{name:dName,levelParams:nil,type:typeRoot},value:bodyRoot,
      hints:H.abbrevHint,safety:S.safe}),"admission-shared-expected-definition");
    must(sameRuntimeValue(info,CI.defnInfo(expectedDefinition)),
      "admission-shared-stored-definition-"+layers);
    const replies=array(actual.replies),first=replies[0].receipt,second=replies[1].receipt;
    must(replies.length===2&&first.declarationsBefore===0n&&first.declarationsAfter===1n&&
      second.declarationsBefore===1n&&second.declarationsAfter===2n,
      "admission-shared-ordered-receipts-"+layers);
    const unsafeRequest=D.definitionDecl({
      base:{name:dName,levelParams:nil,type:typeRoot},value:bodyRoot,
      hints:H.abbrevHint,safety:S.unsafeDef});
    const unsafeDeclaration=accepted(get("psKernelDagDecodeDeclaration")(built,unsafeRequest),
      "unsafe-fresh-body-declaration");
    const unsafeDirect=accepted(get("psKernelDagTryAdmitSimpleWithFuel")(
      fuel,get("psKernelKernelSessionEnvironment")(owner.session),maxDepth,
      owner.session.resources.maxNatSize,graph,owner.declarations,unsafeRequest,unsafeDeclaration),
      "unsafe-fresh-body-selected");
    must(rejected(unsafeDirect)&&unsafeDirect.error===coldMessage,
      "unsafe-admission-discards-header-owner-before-body-"+layers);
    const unsafeOriginal=get("psKernelV1AdmitDeclaration")(owner.session,unsafeDeclaration),
      unsafeActual=run(seed,nil,S.safe,graph,list([C.admit(aRequest),C.admit(unsafeRequest)]));
    must(rejected(unsafeOriginal)&&rejected(unsafeActual)&&
      sameRuntimeValue(unsafeOriginal.error,unsafeActual.error)&&
      sameRuntimeValue(unsafeOriginal.error,get("psKernelErrorFromMessage")(coldMessage)),
      "unsafe-admission-fresh-body-exact-public-resource-result-"+layers);
  }
  console.log("PSC1_V2_DAG_JS_ADMISSION_SHARED_STATE: PASS");
  console.log("PSC1_V2_DAG_JS_UNSAFE_FRESH_BODY: PASS");
}

{
  const H=get("PsKernelReducibilityHints"),ErrorKind=get("PsKernelError"),
    Resource=get("PsKernelResourceError"),Reply=get("PsKernelDagReply"),
    Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  const seed=session(64n,1n),uName=name("AdmissionUnsafe"),pName=name("AdmissionPartial"),
    aName=name("AdmissionSafetyTarget");
  let graph=empty;
  const put=(kind,...args)=>{const r=mk(graph,kind,...args);graph=r.fst;return r.snd;};
  const s0=put("Sort",L.zero),s1=put("Sort",L.succ(L.zero)),
    unsafeRoot=put("Const",uName,nil),partialRoot=put("Const",pName,nil),
    mv=put("MVar",name("admission-policy-mvar"));
  const built=accepted(decode(graph),"admission-policy-decode"),base=type=>({name:aName,levelParams:nil,type});
  const unsafeRequest=D.axiomDecl({name:uName,levelParams:nil,type:s1},true),
    partialRequest=D.definitionDecl({base:{name:pName,levelParams:nil,type:s1},
      value:s0,hints:H.abbrevHint,safety:S.partialDef});
  const first=accepted(get("psKernelDagRunCommand")(
    {session:seed,declarations:nil},nil,S.safe,graph,built,C.admit(unsafeRequest)),"admission-policy-unsafe");
  const owner=accepted(get("psKernelDagRunCommand")(
    first.snd,nil,S.safe,graph,built,C.admit(partialRequest)),"admission-policy-partial").snd;
  const defn=(value,safety)=>D.definitionDecl({base:base(s1),value,hints:H.abbrevHint,safety});
  const compare=(old,actual,label)=>{
    if(rejected(old)||rejected(actual)){
      must(rejected(old)&&rejected(actual)&&sameRuntimeValue(old.error,actual.error),label);
    }else{
      const a=accepted(old,label+"-old"),b=accepted(actual,label+"-dag");
      must(sameRuntimeValue(a.session,b.session)&&
        sameRuntimeValue(b.replies,list([Reply.admitted(a.declaration.receipt)])),label);
    }
  };
  for(const [label,request,acceptedExpected,directExpected] of [
    ["unsafe-header-safe",D.axiomDecl(base(unsafeRoot),false),false,true],
    ["unsafe-header-unsafe",D.axiomDecl(base(unsafeRoot),true),true,true],
    ["partial-header-safe",D.axiomDecl(base(partialRoot),false),false,true],
    ["partial-header-unsafe",D.axiomDecl(base(partialRoot),true),true,true],
    ["unsafe-body-safe",defn(unsafeRoot,S.safe),false,true],
    ["unsafe-body-partial",defn(unsafeRoot,S.partialDef),false,true],
    ["partial-body-partial",defn(partialRoot,S.partialDef),false,true],
    ["unsafe-body-opaque",D.opaqueDecl(base(s1),unsafeRoot,true),false,true],
    ["unsafe-body-unsafe",defn(unsafeRoot,S.unsafeDef),true,true]
  ]){
    const declaration=accepted(get("psKernelDagDecodeDeclaration")(built,request),"admission-safety-request");
    const attempted=get("psKernelDagTryAdmitSimpleWithFuel")(
      64n,get("psKernelKernelSessionEnvironment")(owner.session),1n,owner.session.resources.maxNatSize,
      graph,owner.declarations,request,declaration);
    const selected=!sameRuntimeValue(attempted,none);
    must(selected===directExpected,"admission-safety-path-"+label);
    if(selected)must(!rejected(accepted(attempted,"admission-safety-some"))===acceptedExpected,
      "admission-safety-direct-decision-"+label);
    const original=get("psKernelV1AdmitDeclaration")(owner.session,declaration);
    must(!rejected(original)===acceptedExpected,"admission-safety-original-decision-"+label);
    compare(original,run(owner.session,nil,S.safe,graph,list([C.admit(request)])),
      "admission-safety-public-parity-"+label);
    const whole=run(seed,nil,S.safe,graph,
      list([C.admit(unsafeRequest),C.admit(partialRequest),C.admit(request)]));
    if(rejected(original)||rejected(whole)){
      must(rejected(original)&&rejected(whole)&&sameRuntimeValue(original.error,whole.error),
        "admission-safety-same-batch-error-"+label);
    }else must(sameRuntimeValue(accepted(original,"admission-whole-old").session,
      accepted(whole,"admission-whole-dag").session),"admission-safety-same-batch-result-"+label);
  }
  const duplicate=D.axiomDecl({name:uName,levelParams:list([aName,aName]),type:mv},false);
  const duplicateDecl=accepted(get("psKernelDagDecodeDeclaration")(built,duplicate),"admission-duplicate-request");
  const duplicateResult=get("psKernelDagAdmitDeclaration")(
    owner.session,graph,owner.declarations,duplicate,duplicateDecl);
  must(rejected(duplicateResult)&&sameRuntimeValue(duplicateResult.error,
    ErrorKind.rejectedInvalid("already declared")),"admission-existing-name-before-static-errors");
  const valid=defn(s0,S.safe),bad=defn(s1,S.safe),
    limited={...owner.session,resources:{...owner.session.resources,maxDeclarations:2n}};
  for(const request of [valid,bad]){
    const declaration=accepted(get("psKernelDagDecodeDeclaration")(built,request),"admission-limit-request");
    compare(get("psKernelV1AdmitDeclaration")(limited,declaration),
      run(limited,nil,S.safe,graph,list([C.admit(request)])),"admission-limit-after-complete-check");
  }
  const validDecl=accepted(get("psKernelDagDecodeDeclaration")(built,valid),"admission-valid-request");
  const limitedResult=get("psKernelDagAdmitDeclaration")(
    limited,graph,owner.declarations,valid,validDecl);
  must(rejected(limitedResult)&&sameRuntimeValue(limitedResult.error,
    ErrorKind.resourceExhausted(Resource.declarationLimit,"declaration limit exceeded")),
    "admission-limit-exact-outcome");
  const malformed=D.axiomDecl({name:uName,levelParams:nil,type:graph.size},false),
    decodeFailure=get("psKernelDagDecodeDeclaration")(built,malformed),
    malformedResult=run(owner.session,nil,S.safe,graph,list([C.admit(malformed)]));
  must(rejected(decodeFailure)&&rejected(malformedResult)&&sameRuntimeValue(
    malformedResult.error,ErrorKind.rejectedInvalid(decodeFailure.error)),
    "admission-malformed-id-before-duplicate-name");
  const cancelled={...owner.session,resources:{...owner.session.resources,cancelled:true}};
  const declined=run(cancelled,nil,S.safe,graph,list([C.admit(malformed)]));
  must(rejected(declined)&&sameRuntimeValue(declined.error,
    ErrorKind.resourceExhausted(Resource.cancelled,"resource policy declined operation before entry")),
    "admission-preflight-before-malformed-id");
  must(array(owner.declarations).length===2&&sameRuntimeValue(
    get("psKernelExprV2DeclarationRefFind")(owner.declarations)(aName),none),
    "admission-failure-does-not-publish-index");
  must(sameRuntimeValue(get("psKernelEnvironmentFind")(owner.session.environment,aName),none),
    "admission-failure-does-not-install-target");
  console.log("PSC1_V2_DAG_JS_ADMISSION_POLICY_SAFETY: PASS");
}

{
  const H=get("PsKernelReducibilityHints");
  const seed=session(64n,1n),aName=name("AdmissionGuardA"),dName=name("AdmissionGuardD");
  let graph=empty;
  const put=(kind,...args)=>{const r=mk(graph,kind,...args);graph=r.fst;return r.snd;};
  const s1=put("Sort",L.succ(L.zero)),leftType=put("MData",11n,s1),
    rightType=put("MData",12n,s1),bodyRoot=put("Const",aName,nil);
  const built=accepted(decode(graph),"admission-final-decode");
  const request=D.axiomDecl({name:aName,levelParams:nil,type:leftType},false);
  const owner=accepted(get("psKernelDagRunCommand")(
    {session:seed,declarations:nil},nil,S.safe,graph,built,C.admit(request)),
    "admission-final-axiom").snd;
  const declaredType=accepted(decoded(built,rightType),"admission-final-type"),
    body=accepted(decoded(built,bodyRoot),"admission-final-body"),
    base={name:dName,levelParams:nil,type:declaredType},
    value={base,value:body,hints:H.abbrevHint,safety:S.safe};
  for(const [fuel,recDepth,expected] of [
    [1n,0n,"kernel definitional equality budget exhausted"],
    [64n,15n,"deep recursion detected, use maxRecDepth to increase the limit"],
    [64n,14n,null]
  ]){
    const checker=get("psKernelKernelSessionChecker")(owner.session,nil,S.safe),
      scalar={...checker.context,recDepth},
      context=get("psKernelExprV2CheckContextEmpty")(scalar),
      state=get("psKernelExprV2CheckStateWithWhnf")(
        get("psKernelExprV2CheckStateEmpty")(graph),
        get("psKernelExprV2WhnfStateForDeclarations")(graph,owner.declarations));
    const legacy=get("psKernelCheckDefinitionBodyWithSession")(fuel,{...checker,context:scalar},value),
      actual=accepted(get("psKernelExprV2AdmissionCheckBodyWithFuel")(
        fuel,context,state,base,rightType,body,bodyRoot,"definition type mismatch"),
        "admission-final-direct-some");
    if(expected===null){
      accepted(legacy,"admission-final-legacy-success");
      accepted(actual,"admission-final-dag-success");
    }else must(rejected(legacy)&&rejected(actual)&&legacy.error===expected&&actual.error===expected,
      "admission-final-defeq-entry-guards-"+fuel+"-"+recDepth);
  }
  const checker=get("psKernelKernelSessionChecker")(owner.session,nil,S.safe),
    legacy=get("psKernelSessionEnsureSort")(0n,checker,sort1),
    actual=accepted(get("psKernelExprV2AdmissionEnsureSortWithFuel")(
      0n,get("psKernelExprV2CheckContextEmpty")(checker.context),
      get("psKernelExprV2CheckStateEmpty")(graph),s1),"admission-ensure-sort-zero-some");
  must(rejected(legacy)&&rejected(actual)&&legacy.error===actual.error&&
    legacy.error==="kernel reduction budget exhausted",
    "admission-ensure-sort-always-enters-whnf-even-sort");
  const leftExpression=accepted(decoded(built,leftType),"admission-final-warm-left"),
    oldWarm=accepted(get("psKernelSessionIsDefEq")(
      64n,checker,leftExpression,declaredType),"admission-final-old-warm"),
    initial=get("psKernelExprV2CheckStateWithWhnf")(
      get("psKernelExprV2CheckStateEmpty")(graph),
      get("psKernelExprV2WhnfStateForDeclarations")(graph,owner.declarations)),
    dagWarm=accepted(accepted(get("psKernelExprV2TryDefEqStateWithFuel")(64n)
      (get("psKernelExprV2CheckContextEmpty")(checker.context))(initial)(leftType)(rightType),
      "admission-final-dag-warm-some"),"admission-final-dag-warm");
  must(oldWarm.fst===true&&dagWarm.snd===true,"admission-final-warm-pair-established");
  const warmScalar={...checker.context,recDepth:15n};
  accepted(get("psKernelCheckDefinitionBodyWithSession")(
    64n,{...oldWarm.snd,context:warmScalar},value),"admission-final-old-retains-success");
  accepted(accepted(get("psKernelExprV2AdmissionCheckBodyWithFuel")(
    64n,get("psKernelExprV2CheckContextEmpty")(warmScalar),dagWarm.fst,
    base,rightType,body,bodyRoot,"definition type mismatch"),
    "admission-final-dag-retains-success-some"),"admission-final-dag-retains-success");
  console.log("PSC1_V2_DAG_JS_ADMISSION_FINAL_GUARDS: PASS");
}

{
  const H=get("PsKernelReducibilityHints"),Reply=get("PsKernelDagReply"),
    Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  const target=name("DagTheoremTarget"),pName=name("DagTheoremP"),proofName=name("DagTheoremProof"),
    qName=name("DagTheoremQ"),otherName=name("DagTheoremOtherProof"),
    unsafePName=name("DagTheoremUnsafeP"),unsafeProofName=name("DagTheoremUnsafeProof"),
    partialName=name("DagTheoremPartialProof"),zeroPName=name("DagTheoremZeroP"),
    zeroProofName=name("DagTheoremZeroProof"),u=name("dag-theorem-u"),x=name("dag-theorem-x");
  let graph=empty;
  const put=(kind,...args)=>{const r=mk(graph,kind,...args);graph=r.fst;return r.snd;};
  const s0=put("Sort",L.zero),s1=put("Sort",L.succ(L.zero)),
    normalizedZero=put("Sort",L.imax(L.param(u),L.zero)),
    p=put("Const",pName,nil),proof=put("Const",proofName,nil),q=put("Const",qName,nil),
    other=put("Const",otherName,nil),unsafeP=put("Const",unsafePName,nil),
    unsafeProof=put("Const",unsafeProofName,nil),partialProof=put("Const",partialName,nil),
    zeroP=put("Const",zeroPName,list([L.param(u)])),
    zeroProof=put("Const",zeroProofName,list([L.param(u)])),
    mv=put("MVar",u),fv=put("FVar",u),undefinedSort=put("Sort",L.param(u)),
    b0=put("BVar",0n),b1=put("BVar",1n),tailType=put("Forall",x,b0,b1,B.default),
    tailProof=put("Lam",x,b0,b0,B.default),identityType=put("Forall",u,s0,tailType,B.default),
    identityProof=put("Lam",u,s0,tailProof,B.default),hiddenP=put("MData",81n,p),
    hiddenProof=put("MData",82n,proof);
  const built=accepted(decode(graph),"theorem-matrix-decode"),
    seedBase=(name,params,type)=>({name,levelParams:list(params),type});
  const seedRequests=[
    D.axiomDecl(seedBase(pName,[],s0),false),D.axiomDecl(seedBase(proofName,[],p),false),
    D.axiomDecl(seedBase(qName,[],s0),false),D.axiomDecl(seedBase(otherName,[],q),false),
    D.axiomDecl(seedBase(unsafePName,[],s0),true),D.axiomDecl(seedBase(unsafeProofName,[],p),true),
    D.definitionDecl({base:seedBase(partialName,[],p),value:proof,hints:H.abbrevHint,safety:S.partialDef}),
    D.axiomDecl(seedBase(zeroPName,[u],normalizedZero),false),
    D.axiomDecl(seedBase(zeroProofName,[u],zeroP),false)
  ];
  const seed=session(64n,1n);let owner={session:seed,declarations:nil};
  for(const request of seedRequests)owner=accepted(get("psKernelDagRunCommand")(
    owner,nil,S.safe,graph,built,C.admit(request)),"theorem-seed-admission").snd;
  const theorem=(params,type,value)=>D.theoremDecl(seedBase(target,params,type),value);
  const cases=[
    ["constant-proof",theorem([],p,proof),true,null],
    ["metadata-proof",theorem([],p,hiddenProof),true,null],
    ["identity-proof",theorem([],identityType,identityProof),true,null],
    ["normalized-zero-universe",theorem([u],zeroP,zeroProof),true,null],
    ["nonprop-before-body-mvar",theorem([],s0,mv),true,"theorem type is not a proposition"],
    ["nonprop-before-body-fvar",theorem([],s1,fv),true,"theorem type is not a proposition"],
    ["prop-body-mvar",theorem([],p,mv),true,"declaration has metavariables"],
    ["prop-body-fvar",theorem([],p,fv),true,"declaration has free variables"],
    ["prop-body-undefined-universe",theorem([],p,undefinedSort),true,
      "invalid reference to undefined universe level parameter"],
    ["header-mvar-before-body",theorem([],mv,fv),true,"declaration has metavariables"],
    ["duplicate-universe-before-header",theorem([u,u],mv,proof),true,"duplicate universe parameter"],
    ["unsafe-header",theorem([],unsafeP,proof),true,null],
    ["unsafe-proof",theorem([],p,unsafeProof),true,null],
    ["partial-proof",theorem([],p,partialProof),true,null],
    ["different-proposition-proof-comparison",theorem([],p,other),true,"theorem proof type mismatch"],
    ["metadata-comparison-prefix",theorem([],hiddenP,proof),true,null]
  ];
  const publicCompare=(original,actual,label)=>{
    if(rejected(original)||rejected(actual))must(rejected(original)&&rejected(actual)&&
      sameRuntimeValue(original.error,actual.error),label+"-error");
    else{const a=accepted(original,label+"-old"),b=accepted(actual,label+"-dag");
      must(sameRuntimeValue(a.session,b.session)&&
        sameRuntimeValue(b.replies,list([Reply.admitted(a.declaration.receipt)])),label+"-result");}
  };
  let comparisons=0;
  for(const [label,request,directAt64,messageAt64] of cases){
    const declaration=accepted(get("psKernelDagDecodeDeclaration")(built,request),"theorem-request");
    for(const fuel of [0n,1n,2n,3n,4n,8n,64n])for(const maxRecDepth of [0n,1n]){
      const current={...owner.session,resources:{...owner.session.resources,fuel,maxRecDepth}};
      const direct=get("psKernelDagTryAdmitSimpleWithFuel")(fuel,
        get("psKernelKernelSessionEnvironment")(current),maxRecDepth,current.resources.maxNatSize,
        graph,owner.declarations,request,declaration);
      const selected=!sameRuntimeValue(direct,none);
      if(label==="different-proposition-proof-comparison")
        must(selected,"theorem-different-proposition-has-direct-decision");
      if(selected)must(sameRuntimeValue(get("psKernelV1DispatchDeclaration")(current,declaration),
        get("psKernelV1EnvironmentOutcome")(accepted(direct,"theorem-raw-some"))),
        "theorem-raw-parity-"+label+"-"+fuel+"-"+maxRecDepth);
      const original=get("psKernelV1AdmitDeclaration")(current,declaration);
      publicCompare(original,run(current,nil,S.safe,graph,list([C.admit(request)])),
        "theorem-public-"+label+"-"+fuel+"-"+maxRecDepth);
      if(fuel===64n){
        must(selected===directAt64,"theorem-selected-path-"+label);
        if(messageAt64!==null)must(rejected(original)&&sameRuntimeValue(original.error,
          get("PsKernelError").rejectedInvalid(messageAt64)),"theorem-exact-message-"+label);
        const full=run(session(fuel,maxRecDepth),nil,S.safe,graph,
          list([...seedRequests.map(request=>C.admit(request)),C.admit(request)]));
        if(rejected(original)||rejected(full))must(rejected(original)&&rejected(full)&&
          sameRuntimeValue(original.error,full.error),"theorem-same-batch-error-"+label);
        else{const a=accepted(original,"theorem-whole-old"),b=accepted(full,"theorem-whole-dag");
          must(sameRuntimeValue(a.session,b.session)&&array(b.replies).length===seedRequests.length+1,
            "theorem-same-batch-result-"+label);}
        const command=get("psKernelDagRunCommand")({session:current,declarations:owner.declarations},
          nil,S.safe,graph,built,C.admit(request));
        if(rejected(original)||rejected(command))must(rejected(original)&&rejected(command)&&
          sameRuntimeValue(original.error,command.error),"theorem-owner-command-error-"+label);
        else{const a=accepted(original,"theorem-command-old"),b=accepted(command,"theorem-command-dag");
          must(sameRuntimeValue(a.session,b.snd.session)&&
            array(b.snd.declarations).length===array(owner.declarations).length+1,
            "theorem-owner-command-result-"+label);}
      }
      comparisons++;
    }
  }
  must(comparisons===224,"theorem-admission-matrix-count");
  const request=theorem([],p,proof),declaration=accepted(
    get("psKernelDagDecodeDeclaration")(built,request),"theorem-external-request");
  must(sameRuntimeValue(get("psKernelDagTryAdmitSimpleWithFuel")(64n,
    get("psKernelKernelSessionEnvironment")(owner.session),1n,owner.session.resources.maxNatSize,
    graph,nil,request,declaration),none),"theorem-external-index-explicit-fallback");
  const admitted=accepted(get("psKernelDagRunCommand")(
    owner,nil,S.safe,graph,built,C.admit(request)),"theorem-index-admitted");
  const reference=accepted(get("psKernelExprV2DeclarationRefFind")(
    admitted.snd.declarations)(target),"theorem-type-reference");
  must(reference.type===p&&sameRuntimeValue(reference.deltaValue,none),
    "theorem-index-published-only-with-checked-type");
  must(array(owner.declarations).length===seedRequests.length&&sameRuntimeValue(
    get("psKernelEnvironmentFind")(owner.session.environment,target),none),
    "theorem-original-owner-unmodified");
  console.log("PSC1_V2_DAG_JS_THEOREM_ADMISSION_MATRIX: PASS");
}
{
  const u=name("dag-isprop-u"),x=name("dag-isprop-x");let graph=empty;
  const put=(kind,...args)=>{const r=mk(graph,kind,...args);graph=r.fst;return r.snd;};
  const s0=put("Sort",L.zero),b0=put("BVar",0n),b1=put("BVar",1n),
    tail=put("Forall",x,b0,b1,B.default),typeRoot=put("Forall",u,s0,tail,B.default);
  let built=accepted(decode(graph),"isprop-decode");
  const type=accepted(decoded(built,typeRoot),"isprop-type"),seed=session(64n,1n),
    checker=get("psKernelKernelSessionChecker")(seed,nil,S.safe),
    context=get("psKernelExprV2CheckContextEmpty")(checker.context),
    initial=get("psKernelExprV2CheckStateEmpty")(graph),
    base={name:name("DagIsPropHeader"),levelParams:nil,type};
  const oldHeader=accepted(get("psKernelCheckConstantBaseWithSession")(64n,checker,base),"isprop-old-header");
  const afterHeader=accepted(accepted(get("psKernelExprV2AdmissionCheckHeaderWithFuel")(
    64n,context,initial,base,typeRoot),"isprop-header-some"),"isprop-header");
  const oldProp=accepted(get("psKernelSessionIsProp")(64n,oldHeader,type),"isprop-old");
  const dagProp=accepted(accepted(get("psKernelExprV2AdmissionIsPropWithFuel")(
    64n,context,afterHeader,typeRoot),"isprop-some"),"isprop-result");
  must(oldHeader.state.nextFresh===2n&&afterHeader.nextFresh===2n&&oldProp.fst===true&&dagProp.snd===true&&
    oldProp.snd.state.nextFresh===4n&&dagProp.fst.nextFresh===4n,
    "theorem-isprop-has-independent-infer-entry");
  must(array(get("psKernelExprV2WhnfCacheEntries")(afterHeader.inferOnly)).length===0&&array(get("psKernelExprV2WhnfCacheEntries")(dagProp.fst.inferOnly)).length>0&&
    array(get("psKernelExprV2WhnfCacheEntries")(dagProp.fst.checkedInfer)).length===array(get("psKernelExprV2WhnfCacheEntries")(afterHeader.checkedInfer)).length,
    "theorem-infer-only-does-not-publish-checked-judgment");
  const warmScalar={...checker.context,recDepth:15n};
  const warmOld=accepted(get("psKernelSessionIsProp")(
    64n,{...oldProp.snd,context:warmScalar},type),"isprop-warm-old");
  const warmDag=accepted(accepted(get("psKernelExprV2AdmissionIsPropWithFuel")(
    64n,get("psKernelExprV2CheckContextEmpty")(warmScalar),dagProp.fst,typeRoot),
    "isprop-warm-some"),"isprop-warm-dag");
  must(warmOld.fst===true&&warmDag.snd===true&&warmOld.snd.state.nextFresh===warmDag.fst.nextFresh&&
    warmDag.fst.nextFresh===4n,"theorem-isprop-retains-returned-infer-owner");
  const coldOld=get("psKernelSessionIsProp")(64n,{...oldHeader,context:warmScalar},type);
  const coldDag=accepted(get("psKernelExprV2AdmissionIsPropWithFuel")(
    64n,get("psKernelExprV2CheckContextEmpty")(warmScalar),afterHeader,typeRoot),"isprop-cold-some");
  must(rejected(coldOld)&&rejected(coldDag)&&coldOld.error===coldDag.error&&
    coldOld.error==="deep recursion detected, use maxRecDepth to increase the limit",
    "theorem-isprop-cold-owner-does-not-pass-warm-depth");
  for(const [fuel,recDepth,wanted] of [
    [0n,0n,"kernel inference budget exhausted"],
    [64n,16n,"deep recursion detected, use maxRecDepth to increase the limit"]]){
    const scalar={...checker.context,recDepth};
    const original=get("psKernelSessionIsProp")(fuel,{...oldProp.snd,context:scalar},type);
    const actual=accepted(get("psKernelExprV2AdmissionIsPropWithFuel")(
      fuel,get("psKernelExprV2CheckContextEmpty")(scalar),dagProp.fst,typeRoot),"isprop-guard-some");
    must(rejected(original)&&rejected(actual)&&original.error===actual.error&&original.error===wanted,
      "theorem-isprop-entry-guards-before-warm-cache");
  }
  const pName=name("DagIsPropHiddenSort"),hiddenSort=put("MData",93n,s0),p=put("Const",pName,nil);
  built=accepted(decode(graph),"isprop-hidden-decode");
  const request=D.axiomDecl({name:pName,levelParams:nil,type:hiddenSort},false);
  const owner=accepted(get("psKernelDagRunCommand")(
    {session:seed,declarations:nil},nil,S.safe,graph,built,C.admit(request)),"isprop-hidden-admit").snd;
  const hiddenChecker=get("psKernelKernelSessionChecker")(owner.session,nil,S.safe),
    hiddenContext=get("psKernelExprV2CheckContextEmpty")(hiddenChecker.context),
    hiddenInitial=get("psKernelExprV2CheckStateWithWhnf")(
      get("psKernelExprV2CheckStateEmpty")(graph),
      get("psKernelExprV2WhnfStateForDeclarations")(graph,owner.declarations)),
    expr=accepted(decoded(built,p),"isprop-hidden-expression");
  const oldInferred=accepted(get("psKernelSessionInfer")(1n,hiddenChecker,expr),"isprop-hidden-old-infer");
  const dagInferred=accepted(accepted(get("psKernelExprV2TryInferStateWithFuel")(
    1n,hiddenContext,hiddenInitial,p),"isprop-hidden-infer-some"),"isprop-hidden-infer");
  const original=get("psKernelSessionIsProp")(1n,oldInferred.snd,expr);
  const actual=accepted(get("psKernelExprV2AdmissionIsPropWithFuel")(
    1n,hiddenContext,dagInferred.fst,p),"isprop-whnf-some");
  must(rejected(original)&&rejected(actual)&&original.error===actual.error&&
    original.error==="kernel reduction budget exhausted",
    "theorem-isprop-mandatory-whnf-after-cached-inference");
  console.log("PSC1_V2_DAG_JS_THEOREM_ISPROP_STATE: PASS");
}

{
  let spineArena=empty;
  const build=(kind,term,...args)=>{
    const result=mk(spineArena,kind,...args);spineArena=result.fst;
    return {id:result.snd,term};
  };
  const bs=level=>build("Sort",E.sort(level),level);
  const bv=index=>build("BVar",E.bvar(index),index);
  const md=(tag,body)=>build("MData",E.mdata(tag,body.term),tag,body.id);
  const bind=(isLambda,n,domain,body,info=B.default)=>build(
    isLambda?"Lam":"Forall",
    isLambda?E.lam(n,domain.term,body.term,info):E.forallE(n,domain.term,body.term,info),
    n,domain.id,body.id,info);
  const app=(fn,arg)=>build("App",E.app(fn.term,arg.term),fn.id,arg.id);
  const one=L.succ(L.zero),s0=bs(L.zero),s1=bs(one);
  const m0=bs(L.max(L.zero,L.zero)),m1=bs(L.max(one,one));
  const b0=bv(0n),b1=bv(1n),b2=bv(2n);
  const x=name("spine-x"),y=name("spine-y"),a=name("spine-a"),b=name("spine-b");
  const typed=scalar=>get("psKernelExprV2CheckContextEmpty")(scalar);
  const freshState=()=>get("psKernelExprV2CheckStateEmpty")(spineArena);
  const raw=(fuel,context,state,left,right)=>
    get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(context)(state)(left)(right);
  const original=(fuel,context,state,left,right)=>
    get("psKernelIsDefEqWithFuel")(fuel)(context)(state)(left)(right);
  const boolEqual=(left,right)=>typeof left==="boolean"&&typeof right==="boolean"&&left===right;
  const compare=(expectedAttempt,actualAttempt,label)=>{
    const actual=accepted(actualAttempt,label+"-direct");
    if(rejected(expectedAttempt)){
      must(rejected(actual)&&actual.error===expectedAttempt.error,label+"-error");
    }else{
      const expected=accepted(expectedAttempt,label+"-original");
      const result=accepted(actual,label+"-actual");
      must(boolEqual(expected.fst,result.snd),label+"-boolean");
      must(expected.snd.nextFresh===result.fst.nextFresh,label+"-fresh");
    }
  };
  const publicPair=(s,left,right)=>invoke(spineArena,[C.isDefEq(left.id,right.id)],s);
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  for(const isLambda of [true,false]){
    const binder=(n,domain,body,info=B.default)=>bind(isLambda,n,domain,body,info);
    const fixtures=[
      ["alpha",binder(x,s1,b0,B.implicit),binder(y,s1,b0,B.strictImplicit),true],
      ["dependent-universe",binder(x,s1,b0),binder(y,m1,b0),true],
      ["closed-body",binder(x,s1,s0),binder(y,s1,m0),true],
      ["different-domain",binder(x,s0,s0),binder(y,s1,s0),false],
      ["different-body",binder(x,s1,s0),binder(y,s1,s1),false],
      ["nested-dependent",binder(x,s1,binder(a,b0,b1)),
        binder(y,m1,binder(b,b0,b1)),true],
      ["nested-closed",binder(x,s1,binder(a,s1,md(1n,s0))),
        binder(y,s1,binder(b,s1,md(2n,m0))),true],
      ["metadata-body",binder(x,s1,md(1n,b0)),binder(y,s1,md(2n,b0)),true],
      ["metadata-domain",binder(x,md(1n,s1),b0),binder(y,md(2n,m1),b0),true]
    ];
    if(isLambda)fixtures.push(["opposite-tail",
      binder(x,s1,bind(false,a,s1,md(1n,s0))),
      binder(y,s1,bind(false,b,s1,md(2n,m0))),true]);
    for(const [label,left,right,answer] of fixtures){
      for(const fuel of [0n,1n,2n,3n,4n,8n,16n,64n])for(const maxRecDepth of [0n,1n,2n]){
        const s=session(fuel,maxRecDepth);
        const checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
        for(const recDepth of [0n,13n,14n,15n,16n]){
          const scalar={...checker.context,recDepth};
          compare(original(fuel,scalar,checker.state,left.term,right.term),
            raw(fuel,typed(scalar),freshState(),left.id,right.id),
            "binder-spine-raw-"+isLambda+"-"+label+"-"+fuel+"-"+maxRecDepth+"-"+recDepth);
        }
        must(sameOperation(get("psKernelV1IsDefEq")(s,nil,S.safe,left.term,right.term),
          publicPair(s,left,right),boolEqual),
          "binder-spine-public-"+isLambda+"-"+label+"-"+fuel+"-"+maxRecDepth);
      }
      const s=session(64n),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
      const result=accepted(accepted(raw(64n,typed(checker.context),freshState(),left.id,right.id),
        "binder-spine-answer-some"),"binder-spine-answer-result");
      must(boolEqual(result.snd,answer),"binder-spine-answer-"+isLambda+"-"+label);
      const replies=array(accepted(publicPair(s,left,right),"binder-spine-checked-answer").replies);
      must(replies.length===1&&boolEqual(replies[0].value,answer),
        "binder-spine-checked-answer-"+isLambda+"-"+label);
    }
  }
  console.log("PSC1_V2_DAG_JS_BINDER_SPINE: PASS");
  for(const isLambda of [true,false]){
    const binder=(n,domain,body)=>bind(isLambda,n,domain,body);
    const deepLeft=binder(x,s1,binder(a,s1,binder(x,s1,md(1n,b2))));
    const deepRight=binder(y,s1,binder(b,s1,binder(y,s1,md(2n,b2))));
    const fixtures=[
      ["three-binders",deepLeft,deepRight,nil,nil],
      ["domain-callback",binder(x,s1,b0),binder(y,m1,b0),nil,nil],
      ["incoming-reverse-subst",binder(x,b0,md(1n,b1)),
        binder(y,b0,md(2n,b1)),list([s1.term]),list([s1.id])]
    ];
    const oldSpine=get(isLambda?"psKernelDefEqLambdaSpineWithFuel":
      "psKernelDefEqForallSpineWithFuel");
    const newSpine=get("psKernelExprV2DefEqBinderSpineWithFuel");
    const base=get("psKernelKernelSessionChecker")(session(64n,1n),nil,S.safe);
    for(const [label,left,right,oldSubst,newSubst] of fixtures){
      for(const spineFuel of [0n,1n,2n,3n,4n,5n,8n,64n]){
        for(const callbackFuel of [0n,1n,2n,3n,4n,64n]){
          for(const recDepth of [0n,14n,15n,16n]){
            const scalar={...base.context,recDepth};
            const expected=oldSpine(spineFuel)(get("psKernelIsDefEqWithFuel")(callbackFuel))
              (scalar)(base.state)(left.term)(right.term)(oldSubst);
            const actual=newSpine(spineFuel)(isLambda)
              (get("psKernelExprV2TryDefEqStateWithFuel")(callbackFuel))
              (typed(scalar))(freshState())(left.id)(right.id)(newSubst);
            compare(expected,actual,"binder-spine-budget-"+isLambda+"-"+label+
              "-"+spineFuel+"-"+callbackFuel+"-"+recDepth);
          }
        }
      }
    }
    const zero=accepted(newSpine(0n)(isLambda)
      (get("psKernelExprV2TryDefEqStateWithFuel")(64n))
      (typed(base.context))(freshState())(spineArena.size)(spineArena.size)(nil),
      "binder-spine-zero-invalid-some");
    must(rejected(zero)&&zero.error===(isLambda?
      "kernel defeq lambda-spine budget exhausted":"kernel defeq forall-spine budget exhausted"),
      "binder-spine-zero-precedes-node-lookup-"+isLambda);
  }
  {
    // Never decode the graph or construct its exponentially expanded legacy tree.
    let sharedArena=empty;
    const s0Result=mk(sharedArena,"Sort",L.zero);sharedArena=s0Result.fst;
    const sharedSort0=s0Result.snd;
    let shared=sharedSort0;
    for(let i=0;i<24;i++){
      const result=mk(sharedArena,"Forall",x,shared,shared,B.default);
      sharedArena=result.fst;shared=result.snd;
    }
    must(accepted(get("psKernelExprV2TransformCountOnCanonical")(sharedArena,shared),
      "binder-shared-expanded-count")===33554431n,"binder-shared-exact-expanded-count");
    const maxResult=mk(sharedArena,"Sort",L.max(L.zero,L.zero));sharedArena=maxResult.fst;
    const leftResult=mk(sharedArena,"Lam",x,shared,sharedSort0,B.default);sharedArena=leftResult.fst;
    const rightResult=mk(sharedArena,"Lam",y,shared,maxResult.snd,B.default);sharedArena=rightResult.fst;
    const leftCount=accepted(get("psKernelExprV2TransformCountOnCanonical")(sharedArena,leftResult.snd),
      "binder-shared-left-count");
    const rightCount=accepted(get("psKernelExprV2TransformCountOnCanonical")(sharedArena,rightResult.snd),
      "binder-shared-right-count");
    must(1n+leftCount+rightCount===67108867n,"binder-shared-original-default-budget");
    const base=get("psKernelKernelSessionChecker")(session(64n),nil,S.safe);
    const result=accepted(accepted(raw(3n,typed(base.context),
      get("psKernelExprV2CheckStateEmpty")(sharedArena),leftResult.snd,rightResult.snd),
      "binder-shared-direct-some"),"binder-shared-direct-result");
    must(result.snd===true&&result.fst.nextFresh===0n,
      "binder-shared-default-does-not-build-expanded-budget-closure-chain");
  }
  console.log("PSC1_V2_DAG_JS_BINDER_SPINE_BUDGET: PASS");
  for(const isLambda of [true,false]){
    const binder=(n,domain,body)=>bind(isLambda,n,domain,body);
    let parentLeft=s1,parentRight=m1,childLeft=s0,childRight=m0;
    for(let i=0n;i<8n;i++){
      parentLeft=md(100n+i,parentLeft);parentRight=md(200n+i,parentRight);
      childLeft=md(300n+i,childLeft);childRight=md(400n+i,childRight);
    }
    const left=binder(x,parentLeft,binder(a,childLeft,b1));
    const right=binder(y,parentRight,binder(b,childRight,b1));
    const closedLeft=binder(x,s1,childLeft),closedRight=binder(y,s1,childRight);
    const base=get("psKernelKernelSessionChecker")(session(64n,1n),nil,S.safe);
    const context=typed(base.context);
    const oldPrime=accepted(original(64n,base.context,base.state,left.term,right.term),
      "binder-cache-prime-original");
    const newPrime=accepted(accepted(raw(64n,context,freshState(),left.id,right.id),
      "binder-cache-prime-some"),"binder-cache-prime-result");
    must(oldPrime.fst===true&&newPrime.snd===true&&
      oldPrime.snd.nextFresh===2n&&newPrime.fst.nextFresh===2n,
      "binder-cache-two-dependent-locals-"+isLambda);
    const contains=(state,l,r)=>accepted(get("psKernelExprV2DefEqPairContains")(
      state.whnf.arena,state.success,l.id,r.id),"binder-cache-contains");
    must(contains(newPrime.fst,parentLeft,parentRight)===true,
      "binder-domain-success-predates-local-scope-"+isLambda);
    must(contains(newPrime.fst,childLeft,childRight)===false,
      "binder-inner-domain-success-restored-away-"+isLambda);
    for(const [label,l,r] of [["root",left,right],["parent",parentLeft,parentRight],
      ["child",childLeft,childRight]]){
      for(const [fuel,recDepth] of [[0n,0n],[1n,0n],[1n,15n],[1n,16n]]){
        const scalar={...base.context,recDepth};
        compare(original(fuel,scalar,oldPrime.snd,l.term,r.term),
          raw(fuel,typed(scalar),newPrime.fst,l.id,r.id),
          "binder-cache-warm-"+isLambda+"-"+label+"-"+fuel+"-"+recDepth);
      }
    }
    const childAttempt=accepted(raw(1n,context,newPrime.fst,childLeft.id,childRight.id),
      "binder-child-miss-some");
    must(rejected(childAttempt)&&childAttempt.error==="kernel definitional equality budget exhausted",
      "binder-child-scope-cannot-authorize-low-fuel-query-"+isLambda);
    const oldClosed=accepted(original(64n,base.context,base.state,closedLeft.term,closedRight.term),
      "binder-closed-prime-original");
    const newClosed=accepted(accepted(raw(64n,context,freshState(),closedLeft.id,closedRight.id),
      "binder-closed-prime-some"),"binder-closed-prime-result");
    must(oldClosed.fst===true&&newClosed.snd===true&&
      oldClosed.snd.nextFresh===0n&&newClosed.fst.nextFresh===0n,
      "binder-closed-bodies-allocate-no-fresh-local-"+isLambda);
    must(contains(newClosed.fst,childLeft,childRight)===true,
      "binder-closed-body-success-remains-in-owner-"+isLambda);
    compare(original(1n,base.context,oldClosed.snd,childLeft.term,childRight.term),
      raw(1n,context,newClosed.fst,childLeft.id,childRight.id),
      "binder-closed-body-warm-hit-"+isLambda);
  }
  console.log("PSC1_V2_DAG_JS_BINDER_SPINE_CACHE: PASS");
  for(const isLambda of [true,false]){
    const binder=(n,domain,body)=>bind(isLambda,n,domain,body);
    const redex=app(bind(true,a,s1,b0),s0);
    const fixtures=[
      ["one-sided-metadata",binder(x,s1,md(9n,s0)),binder(y,s1,s0),true],
      ["beta-body",binder(x,s1,redex),binder(y,s1,s0),true],
      ["unequal-spine-length",binder(x,s1,binder(a,s1,s0)),binder(y,s1,s0),false]
    ];
    const base=get("psKernelKernelSessionChecker")(session(64n),nil,S.safe);
    for(const [label,left,right,directExpected] of fixtures){
      const selected=raw(64n,typed(base.context),freshState(),left.id,right.id);
      must(accepted(accepted(selected,"binder-prefix-some-"+label),
        "binder-prefix-result-"+label).snd===directExpected,"binder-spine-prefix-direct-"+isLambda+"-"+label);
      for(const fuel of [0n,1n,2n,3n,4n,8n,64n])for(const maxRecDepth of [0n,1n]){
        const s=session(fuel,maxRecDepth);
        const current=get("psKernelKernelSessionChecker")(s,nil,S.safe);
        compare(original(fuel,current.context,current.state,left.term,right.term),
          raw(fuel,typed(current.context),freshState(),left.id,right.id),
          "binder-spine-prefix-raw-"+isLambda+"-"+label+"-"+fuel+"-"+maxRecDepth);
        must(sameOperation(get("psKernelV1IsDefEq")(s,nil,S.safe,left.term,right.term),
          publicPair(s,left,right),boolEqual),
          "binder-spine-fallback-parity-"+isLambda+"-"+label+"-"+fuel+"-"+maxRecDepth);
      }
    }
  }
  {
    const missingName=name("spine-missing");
    const missing=build("MVar",E.mvar(missingName),missingName);
    const invalid=[
      ["forall-lambda-body",
        bind(false,x,s1,bind(true,a,s1,md(1n,s0))),
        bind(false,y,s1,bind(true,b,s1,md(2n,m0)))],
      ["metavariable-domain",bind(true,x,missing,s0),bind(true,y,missing,m0)]
    ];
    const s=session(64n),base=get("psKernelKernelSessionChecker")(s,nil,S.safe);
    for(const [label,left,right] of invalid){
      const result=accepted(accepted(raw(64n,typed(base.context),freshState(),left.id,right.id),
        "binder-invalid-raw-some"),"binder-invalid-raw-result");
      must(result.snd===true,"binder-raw-comparison-does-not-admit-"+label);
      for(const [side,l,r] of [["both",left,right],["left",left,s0],["right",s0,right]]){
        const expected=get("psKernelV1IsDefEq")(s,nil,S.safe,l.term,r.term);
        const actual=publicPair(s,l,r);
        must(rejected(expected)&&rejected(actual)&&sameOperation(expected,actual,boolEqual),
          "binder-public-checks-invalid-"+label+"-"+side);
      }
    }
  }
  console.log("PSC1_V2_DAG_JS_BINDER_SPINE_FALLBACK: PASS");
}

{
  const H=get("PsKernelReducibilityHints"),Reply=get("PsKernelDagReply"),
    CI=get("PsKernelConstantInfo"),Option=get("Option"),
    none=typeof Option.none==="function"?Option.none():Option.none;
  const target=name("DagUnsafeTarget"),externalName=name("DagUnsafeExternal"),
    partialName=name("DagUnsafePartial"),u=name("dag-unsafe-u"),x=name("dag-unsafe-x");
  let graph=empty;
  const put=(kind,...args)=>{const r=mk(graph,kind,...args);graph=r.fst;return r.snd;};
  const s0=put("Sort",L.zero),s1=put("Sort",L.succ(L.zero)),
    su=put("Sort",L.param(u)),su1=put("Sort",L.succ(L.param(u))),
    self=put("Const",target,nil),external=put("Const",externalName,nil),
    partialValue=put("Const",partialName,nil),missing=put("Const",name("DagUnsafeMissing"),nil),
    mv=put("MVar",u),fv=put("FVar",u),b0=put("BVar",0n),
    recursiveApp=put("App",self,b0),recursiveBody=put("Lam",x,s1,recursiveApp,B.default),
    functionType=put("Forall",x,s1,s1,B.default),hiddenType=put("MData",107n,s1);
  const built=accepted(decode(graph),"unsafe-matrix-decode"),
    base=(name,params,type)=>({name,levelParams:list(params),type});
  const seedRequests=[D.axiomDecl(base(externalName,[],s1),true),
    D.definitionDecl({base:base(partialName,[],s1),value:s0,hints:H.abbrevHint,safety:S.partialDef})];
  const seed=session(64n,1n);let owner={session:seed,declarations:nil};
  for(const item of seedRequests)owner=accepted(get("psKernelDagRunCommand")(
    owner,nil,S.safe,graph,built,C.admit(item)),"unsafe-seed-admission").snd;
  const input=(params,type,value)=>({base:base(target,params,type),value,
    hints:H.abbrevHint,safety:S.unsafeDef});
  const request=(params,type,value)=>D.definitionDecl(input(params,type,value));
  const cases=[
    ["self-value",request([],s1,self),true,null],
    ["self-function",request([],functionType,recursiveBody),true,null],
    ["nonrecursive",request([],s1,s0),true,null],
    ["unsafe-external",request([],s1,external),true,null],
    ["partial-external",request([],s1,partialValue),true,null],
    ["polymorphic",request([u],su1,su),true,null],
    ["self-unavailable-in-header",request([],self,s0),true,null],
    ["unknown-body",request([],s1,missing),true,null],
    ["body-mvar",request([],s1,mv),true,"declaration has metavariables"],
    ["body-fvar",request([],s1,fv),true,"declaration has free variables"],
    ["type-mismatch",request([],s1,s1),true,"definition type mismatch"],
    ["undefined-level-before-body",request([],su,mv),true,
      "invalid reference to undefined universe level parameter"],
    ["duplicate-level-before-body",request([u,u],s1,mv),true,"duplicate universe parameter"],
    ["final-comparison-prefix",request([],hiddenType,s0),true,null]
  ];
  const publicCompare=(original,actual,label)=>{
    if(rejected(original)||rejected(actual))must(rejected(original)&&rejected(actual)&&
      sameRuntimeValue(original.error,actual.error),label+"-error");
    else{const a=accepted(original,label+"-old"),b=accepted(actual,label+"-dag");
      must(sameRuntimeValue(a.session,b.session)&&
        sameRuntimeValue(b.replies,list([Reply.admitted(a.declaration.receipt)])),label+"-result");}
  };
  let comparisons=0;
  for(const [label,candidate,directAt64,messageAt64] of cases){
    const declaration=accepted(get("psKernelDagDecodeDeclaration")(built,candidate),"unsafe-request");
    for(const fuel of [0n,1n,2n,3n,4n,8n,64n])for(const maxRecDepth of [0n,1n]){
      const current={...owner.session,resources:{...owner.session.resources,fuel,maxRecDepth}};
      const direct=get("psKernelDagTryAdmitSimpleWithFuel")(fuel,
        get("psKernelKernelSessionEnvironment")(current),maxRecDepth,current.resources.maxNatSize,
        graph,owner.declarations,candidate,declaration);
      const selected=!sameRuntimeValue(direct,none);
      if(selected)must(sameRuntimeValue(get("psKernelV1DispatchDeclaration")(current,declaration),
        get("psKernelV1EnvironmentOutcome")(accepted(direct,"unsafe-raw-some"))),
        "unsafe-raw-parity-"+label+"-"+fuel+"-"+maxRecDepth);
      const original=get("psKernelV1AdmitDeclaration")(current,declaration);
      publicCompare(original,run(current,nil,S.safe,graph,list([C.admit(candidate)])),
        "unsafe-public-"+label+"-"+fuel+"-"+maxRecDepth);
      if(fuel===64n){
        must(selected===directAt64,"unsafe-selected-path-"+label);
        if(messageAt64!==null)must(rejected(original)&&sameRuntimeValue(original.error,
          get("PsKernelError").rejectedInvalid(messageAt64)),"unsafe-exact-message-"+label);
        const full=run(session(fuel,maxRecDepth),nil,S.safe,graph,
          list([...seedRequests.map(item=>C.admit(item)),C.admit(candidate)]));
        if(rejected(original)||rejected(full))must(rejected(original)&&rejected(full)&&
          sameRuntimeValue(original.error,full.error),"unsafe-same-batch-error-"+label);
        else{const a=accepted(original,"unsafe-whole-old"),b=accepted(full,"unsafe-whole-dag");
          must(sameRuntimeValue(a.session,b.session)&&array(b.replies).length===seedRequests.length+1,
            "unsafe-same-batch-result-"+label);}
      }
      comparisons++;
    }
  }
  must(comparisons===196,"unsafe-admission-matrix-count");
  const selfSource=input([],s1,self),selfRequest=D.definitionDecl(selfSource),
    selfDeclaration=accepted(get("psKernelDagDecodeDeclaration")(built,selfRequest),"unsafe-self-declaration"),
    selfValue=accepted(get("psKernelDagDecodeDefinition")(built,selfSource),"unsafe-self-expected-record");
  for(const safety of [S.safe,S.partialDef])must(sameRuntimeValue(
    get("psKernelDagTryAdmitUnsafeDefinitionWithFuel")(64n,
      get("psKernelKernelSessionEnvironment")(owner.session),1n,owner.session.resources.maxNatSize,
      graph,owner.declarations,{...selfSource,safety},{...selfValue,safety}),none),
    "unsafe-private-helper-requires-actual-unsafe-safety");
  const headerSelf=request([],self,s0),headerDeclaration=accepted(
    get("psKernelDagDecodeDeclaration")(built,headerSelf),"unsafe-header-self-declaration");
  const headerOld=get("psKernelV1AdmitDeclaration")(owner.session,headerDeclaration),
    headerDirect=accepted(get("psKernelDagTryAdmitSimpleWithFuel")(64n,
      get("psKernelKernelSessionEnvironment")(owner.session),1n,owner.session.resources.maxNatSize,
      graph,owner.declarations,headerSelf,headerDeclaration),"unsafe-header-self-selected");
  must(rejected(headerOld)&&rejected(headerDirect)&&sameRuntimeValue(headerOld.error,
    get("psKernelErrorFromMessage")(headerDirect.error)),"unsafe-self-not-visible-while-checking-header");
  const limited={...owner.session,resources:{...owner.session.resources,maxDeclarations:2n}};
  for(const candidate of [selfRequest,request([],s1,s1)]){
    const declaration=accepted(get("psKernelDagDecodeDeclaration")(built,candidate),"unsafe-limit-declaration");
    publicCompare(get("psKernelV1AdmitDeclaration")(limited,declaration),
      run(limited,nil,S.safe,graph,list([C.admit(candidate)])),"unsafe-declaration-limit-check-order");
  }
  const limitResult=get("psKernelDagAdmitDeclaration")(
    limited,graph,owner.declarations,selfRequest,selfDeclaration);
  must(rejected(limitResult)&&sameRuntimeValue(limitResult.error,
    get("PsKernelError").resourceExhausted(get("PsKernelResourceError").declarationLimit,
      "declaration limit exceeded")),"unsafe-valid-self-reaches-limit-after-body");
  const badRequest=request([],s1,s1),badDeclaration=accepted(
    get("psKernelDagDecodeDeclaration")(built,badRequest),"unsafe-bad-declaration"),
    badResult=get("psKernelDagAdmitDeclaration")(
      limited,graph,owner.declarations,badRequest,badDeclaration);
  must(rejected(badResult)&&sameRuntimeValue(badResult.error,
    get("PsKernelError").rejectedInvalid("definition type mismatch")),
    "unsafe-bad-body-precedes-declaration-limit");
  must(sameRuntimeValue(get("psKernelEnvironmentFind")(owner.session.environment,target),none)&&
    sameRuntimeValue(get("psKernelExprV2DeclarationRefFind")(owner.declarations)(target),none),
    "unsafe-failed-private-admission-does-not-publish-environment-or-index");
  const published=accepted(get("psKernelDagRunCommand")(
    owner,nil,S.safe,graph,built,C.admit(selfRequest)),"unsafe-self-published");
  const reference=accepted(get("psKernelExprV2DeclarationRefFind")(
    published.snd.declarations)(target),"unsafe-self-reference");
  must(reference.type===s1&&sameRuntimeValue(reference.deltaValue,Option.some(self))&&
    sameRuntimeValue(reference.kind,get("PsKernelExprV2DeclarationRefKind").definitionDecl),
    "unsafe-success-publishes-original-input-ids");
  const stored=accepted(get("psKernelEnvironmentFind")(
    published.snd.session.environment,target),"unsafe-stored-self");
  must(sameRuntimeValue(stored,CI.defnInfo(selfValue)),
    "unsafe-success-stores-exact-recursive-body-and-safety");
  const selfExpression=accepted(decoded(built,self),"unsafe-self-expression"),
    oldSafe=get("psKernelV1CheckExpression")(published.snd.session,nil,S.safe,selfExpression),
    commands=list([...seedRequests.map(item=>C.admit(item)),C.admit(selfRequest),C.check(self)]),
    safeBatch=run(seed,nil,S.safe,graph,commands);
  must(rejected(oldSafe)&&rejected(safeBatch)&&sameRuntimeValue(oldSafe.error,safeBatch.error),
    "unsafe-admission-never-authorizes-safe-use");
  const unsafeBatch=accepted(run(seed,nil,S.unsafeDef,graph,commands),"unsafe-check-context"),
    replies=array(unsafeBatch.replies),last=replies.at(-1);
  must(last!==undefined&&sameRuntimeValue(last,Reply.checked(last.value))&&
    exact(last.value.type,sort1)&&exact(last.value.expression,selfExpression),
    "unsafe-admitted-self-is-checkable-in-unsafe-context");
  const externalRequest=request([],s1,external),externalDeclaration=accepted(
    get("psKernelDagDecodeDeclaration")(built,externalRequest),"unsafe-external-declaration");
  must(sameRuntimeValue(get("psKernelDagTryAdmitSimpleWithFuel")(64n,
    get("psKernelKernelSessionEnvironment")(owner.session),1n,owner.session.resources.maxNatSize,
    graph,nil,externalRequest,externalDeclaration),none),
    "unsafe-missing-external-type-index-declines-entire-attempt");
  publicCompare(get("psKernelV1AdmitDeclaration")(owner.session,externalDeclaration),
    run(owner.session,nil,S.safe,graph,list([C.admit(externalRequest)])),
    "unsafe-external-session-fallback-preserves-public-result");
  console.log("PSC1_V2_DAG_JS_UNSAFE_ADMISSION: PASS");
}

{
  let prefixArena=empty;
  const build=(kind,term,...args)=>{
    const result=mk(prefixArena,kind,...args);prefixArena=result.fst;
    return {id:result.snd,term};
  };
  const bs=level=>build("Sort",E.sort(level),level);
  const bv=index=>build("BVar",E.bvar(index),index);
  const md=(tag,body)=>build("MData",E.mdata(tag,body.term),tag,body.id);
  const lam=(n,domain,body,info=B.default)=>
    build("Lam",E.lam(n,domain.term,body.term,info),n,domain.id,body.id,info);
  const pi=(n,domain,body,info=B.default)=>
    build("Forall",E.forallE(n,domain.term,body.term,info),n,domain.id,body.id,info);
  const app=(fn,arg)=>build("App",E.app(fn.term,arg.term),fn.id,arg.id);
  const letE=(n,type,value,body)=>build("Let",
    E.letE(n,type.term,value.term,body.term,false),n,type.id,value.id,body.id,false);
  const con=(n,levels=nil)=>build("Const",E.const(n,levels),n,levels);
  const fvar=n=>build("FVar",E.fvar(n),n);
  const proj=(n,index,major)=>build("Proj",E.proj(n,index,major.term),n,index,major.id);
  const one=L.succ(L.zero),s0=bs(L.zero),s1=bs(one),s2=bs(L.succ(one));
  const m0=bs(L.max(L.zero,L.zero)),b0=bv(0n),b1=bv(1n);
  const x=name("prefix-x"),y=name("prefix-y"),f=name("prefix-f");
  const identity=lam(x,s1,b0),functionType=pi(x,s1,s1);
  const beta=app(identity,s0),zeta=letE(x,s1,s0,b0);
  const hiddenLambda=letE(f,functionType,lam(x,s1,md(1n,b0)),b0);
  const otherLambda=lam(y,s1,md(2n,b0),B.implicit);
  const hiddenForall=letE(x,s2,s1,pi(y,b0,b1));
  const typed=context=>get("psKernelExprV2CheckContextEmpty")(context);
  const freshState=()=>get("psKernelExprV2CheckStateEmpty")(prefixArena);
  const freshWhnf=()=>get("psKernelExprV2WhnfStateEmpty")(prefixArena);
  const raw=(fuel,context,state,left,right)=>
    get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(context)(state)(left)(right);
  const original=(fuel,context,state,left,right)=>
    get("psKernelIsDefEqWithFuel")(fuel)(context)(state)(left)(right);
  const core=(fuel,context,state,root,cheap)=>
    get("psKernelExprV2CheckWhnfCoreWithFuel")(fuel,context,state,root,cheap);
  const oldCore=(fuel,context,state,node,cheap)=>
    get("psKernelWhnfCoreWithRecursorFuel")(fuel,get("psKernelIsDefEqWithFuel")(fuel),
      context,state,node.term,false,cheap);
  const boolEqual=(a,b)=>typeof a==="boolean"&&typeof b==="boolean"&&a===b;
  const compare=(oldAttempt,newAttempt,label)=>{
    const attempt=accepted(newAttempt,label+"-direct");
    if(rejected(oldAttempt))must(rejected(attempt)&&attempt.error===oldAttempt.error,label+"-error");
    else{
      const a=accepted(oldAttempt,label+"-old"),b=accepted(attempt,label+"-new");
      must(boolEqual(a.fst,b.snd),label+"-bool");
      must(a.snd.nextFresh===b.fst.nextFresh,label+"-fresh");
    }
  };
  const compareWhnf=(oldAttempt,newAttempt,label)=>{
    const attempt=accepted(newAttempt,label+"-direct");
    if(rejected(oldAttempt))must(rejected(attempt)&&attempt.error===oldAttempt.error,label+"-error");
    else{
      const a=accepted(oldAttempt,label+"-old"),b=accepted(attempt,label+"-new");
      const graph=accepted(decode(b.fst.arena),label+"-graph");
      const value=accepted(decoded(graph,b.snd),label+"-value");
      must(exact(a.fst,value)===true,label+"-exact");
    }
  };
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  const fuelCases=[0n,1n,2n,3n,4n,5n,6n,8n,16n,64n];
  const fixtures=[
    ["metadata-left",md(1n,s0),s0,true],
    ["metadata-right",s0,md(2n,s0),true],
    ["metadata-negative",md(1n,s0),s1,false],
    ["metadata-beta",md(1n,beta),md(2n,s0),true],
    ["beta-left",beta,s0,true],["beta-right",s0,beta,true],
    ["beta-negative",beta,s1,false],["zeta-left",zeta,s0,true],
    ["zeta-right",s0,zeta,true],["zeta-negative",zeta,s1,false],
    ["zeta-unused",letE(x,s1,s0,s1),s1,true],
    ["reduced-lambda-syntax",letE(f,functionType,identity,b0),lam(y,s1,b0,B.implicit),true],
    ["reduced-lambda-spine",hiddenLambda,otherLambda,true],
    ["reduced-forall",hiddenForall,pi(y,s1,s1),true],
    ["reduced-sort-equivalence",md(8n,m0),s0,true]
  ];
  for(const [label,left,right,wanted] of fixtures){
    for(const fuel of fuelCases)for(const maxRecDepth of [0n,1n,2n]){
      const current=session(fuel,maxRecDepth),checker=get("psKernelKernelSessionChecker")(current,nil,S.safe);
      for(const recDepth of [0n,13n,14n,15n,16n]){
        const scalar={...checker.context,recDepth};
        compare(original(fuel,scalar,checker.state,left.term,right.term),
          raw(fuel,typed(scalar),freshState(),left.id,right.id),
          "prefix-raw-"+label+"-"+fuel+"-"+maxRecDepth+"-"+recDepth);
      }
      must(sameOperation(get("psKernelV1IsDefEq")(current,nil,S.safe,left.term,right.term),
        invoke(prefixArena,[C.isDefEq(left.id,right.id)],current),boolEqual),
        "prefix-public-"+label+"-"+fuel+"-"+maxRecDepth);
    }
    const checker=get("psKernelKernelSessionChecker")(session(64n),nil,S.safe);
    const result=accepted(accepted(raw(64n,typed(checker.context),freshState(),left.id,right.id),
      "prefix-answer-some"),"prefix-answer-result");
    must(boolEqual(result.snd,wanted),"prefix-answer-"+label);
  }
  console.log("PSC1_V2_DAG_JS_DEFEQ_PREFIX: PASS");
  {
    const missing=name("CheapCoreMissingStructure");
    const cases=[
      ["beta",beta],["zeta",zeta],["metadata",md(1n,beta)],
      ["nested",letE(x,s1,beta,md(2n,b0))],
      ["stuck-projection",proj(missing,0n,beta)]
    ];
    for(const [label,node] of cases){
      for(const fuel of fuelCases)for(const maxRecDepth of [0n,1n,2n]){
        const checker=get("psKernelKernelSessionChecker")(session(fuel,maxRecDepth),nil,S.safe);
        for(const recDepth of [0n,13n,14n,15n,16n])for(const cheap of [false,true]){
          const scalar={...checker.context,recDepth};
          compareWhnf(oldCore(fuel,scalar,checker.state,node,cheap),
            core(fuel,typed(scalar),freshWhnf(),node.id,cheap),
            "cheap-core-"+label+"-"+fuel+"-"+maxRecDepth+"-"+recDepth+"-"+cheap);
        }
      }
      const checker=get("psKernelKernelSessionChecker")(session(64n,1n),nil,S.safe);
      const result=accepted(accepted(core(64n,typed(checker.context),freshWhnf(),node.id,true),
        "cheap-prime-some"),"cheap-prime-result");
      must(array(get("psKernelExprV2WhnfCacheEntries")(result.fst.coreCache)).length===0&&array(get("psKernelExprV2WhnfCacheEntries")(result.fst.publicCache)).length===0,
        "cheap-core-no-new-publications-"+label);
    }
    const copy=letE(y,s1,s0,b0);
    must(copy.id!==zeta.id&&accepted(get("psKernelExprV2PagedEqOnCanonical")(
      prefixArena,copy.id,zeta.id),"cheap-alpha-eq")===true,"cheap-distinct-alpha-equal-keys");
    const checker=get("psKernelKernelSessionChecker")(session(64n,1n),nil,S.safe);
    const context=typed(checker.context);
    const oldWarm=accepted(oldCore(64n,checker.context,checker.state,zeta,false),"full-core-old-prime");
    const newWarm=accepted(accepted(core(64n,context,freshWhnf(),zeta.id,false),
      "full-core-new-prime-some"),"full-core-new-prime");
    must(array(get("psKernelExprV2WhnfCacheEntries")(newWarm.fst.coreCache)).length>0,"full-core-prime-publishes");
    for(const node of [zeta,copy])for(const fuel of [0n,1n,2n])for(const recDepth of [0n,15n,16n]){
      const scalar={...checker.context,recDepth};
      compareWhnf(oldCore(fuel,scalar,oldWarm.snd,node,true),
        core(fuel,typed(scalar),newWarm.fst,node.id,true),
        "cheap-warm-read-entry-guards-"+node.id+"-"+fuel+"-"+recDepth);
    }
    const hit=accepted(accepted(core(1n,context,newWarm.fst,copy.id,true),
      "cheap-hit-some"),"cheap-hit");
    must(array(get("psKernelExprV2WhnfCacheEntries")(hit.fst.coreCache)).length===array(get("psKernelExprV2WhnfCacheEntries")(newWarm.fst.coreCache)).length&&
      array(get("psKernelExprV2WhnfCacheEntries")(hit.fst.publicCache)).length===array(get("psKernelExprV2WhnfCacheEntries")(newWarm.fst.publicCache)).length,
      "cheap-core-full-cache-hit-does-not-publish");
    const oldCheap=accepted(oldCore(64n,checker.context,checker.state,zeta,true),"old-cheap-prime");
    const newCheap=accepted(accepted(core(64n,context,freshWhnf(),zeta.id,true),
      "new-cheap-prime-some"),"new-cheap-prime");
    const exhausted=core(1n,context,newCheap.fst,zeta.id,true);
    compareWhnf(oldCore(1n,checker.context,oldCheap.snd,zeta,true),exhausted,
      "cheap-prime-does-not-authorize-lower-fuel");
    const failure=accepted(exhausted,"cheap-unpublished-query-some");
    must(rejected(failure)&&failure.error==="kernel reduction budget exhausted",
      "cheap-prime-low-fuel-still-errors");
    console.log("PSC1_V2_DAG_JS_CHEAP_CORE_POLICY: PASS");
  }
  {
    const box=name("PrefixCheapBox"),ctor=N.str(box,"mk"),boxType=con(box),ctorNode=con(ctor);
    const ctorType=pi(name("A"),s1,pi(name("B"),s1,boxType));
    const Request=get("PsKernelDeclarationRequest");
    const seed=session(64n,1n);
    const admitted=accepted(get("psKernelV1AdmitDeclaration")(seed,Request.ordinaryInductive({
      levelParams:nil,name:box,type:s2.term,numParams:0n,isUnsafe:false,
      ctors:list([{name:ctor,type:ctorType.term}])
    })),"cheap-projection-real-inductive-admission").session;
    const checker=get("psKernelKernelSessionChecker")(admitted,nil,S.safe);
    const hidden=md(10n,md(11n,md(12n,md(13n,s0))));
    const node=proj(box,0n,app(app(ctorNode,s0),hidden));
    for(const fuel of fuelCases)for(const maxRecDepth of [0n,1n,2n]){
      for(const recDepth of [0n,13n,14n,15n,16n])for(const cheap of [false,true]){
        const scalar={...checker.context,maxRecDepth,recDepth};
        compareWhnf(oldCore(fuel,scalar,checker.state,node,cheap),
          core(fuel,typed(scalar),freshWhnf(),node.id,cheap),
          "cheap-projection-actual-constructor-"+fuel+"-"+maxRecDepth+"-"+recDepth+"-"+cheap);
      }
    }
    const cheap=accepted(accepted(core(3n,typed(checker.context),freshWhnf(),node.id,true),
      "cheap-projection-three-some"),"cheap-projection-three");
    const cheapGraph=accepted(decode(cheap.fst.arena),"cheap-projection-three-graph");
    must(exact(accepted(decoded(cheapGraph,cheap.snd),"cheap-projection-three-value"),sort0)===true&&
      array(get("psKernelExprV2WhnfCacheEntries")(cheap.fst.coreCache)).length===0&&array(get("psKernelExprV2WhnfCacheEntries")(cheap.fst.publicCache)).length===0,
      "cheap-projection-skips-unselected-public-work");
    const full=accepted(core(3n,typed(checker.context),freshWhnf(),node.id,false),
      "full-projection-three-some");
    must(rejected(full)&&full.error==="kernel reduction budget exhausted",
      "full-projection-runs-public-major-pipeline");
    const stuck=proj(name("PrefixUnknownStructure"),0n,beta);
    for(const cheapMode of [false,true]){
      let oldCalls=0,newCalls=0;
      const oldDeny=context=>state=>expr=>{
        oldCalls++;
        return get("psKernelWhnfWithRecursorFuel")(0n,get("psKernelIsDefEqWithFuel")(0n),context,state,expr);
      };
      const newDeny=context=>state=>root=>{
        newCalls++;
        return get("psKernelExprV2TryWhnfStateWithFuel")(0n)(context)(state)(root);
      };
      const noRecursor=()=>{throw Error("PREFIX_UNEXPECTED_RECURSOR_CALLBACK");};
      const expected=get("psKernelWhnfCoreWithFuel")(4n)
        (oldDeny)(noRecursor)(checker.context)(checker.state)(stuck.term)(false)(cheapMode);
      const actual=get("psKernelExprV2TryWhnfCoreModeWithLocalValuesFuel")(4n)
        (cheapMode)(_=>none)(newDeny)(checker.context)(freshWhnf())(stuck.id);
      compareWhnf(expected,actual,"cheap-projection-callback-sentinel-"+cheapMode);
      must(oldCalls===(cheapMode?0:1)&&newCalls===oldCalls,
        "cheap-projection-selects-exact-callback-"+cheapMode);
    }
    const text=get("PsKernelLiteral").str("abc");
    const textNode=build("Lit",E.lit(text),text);
    const stringProjection=proj(name("String"),0n,textNode);
    for(const cheapMode of [false,true])
      compareWhnf(oldCore(64n,checker.context,checker.state,stringProjection,cheapMode),
        core(64n,typed(checker.context),freshWhnf(),stringProjection.id,cheapMode),
        "cheap-projection-string-expansion-exact-"+cheapMode);
    console.log("PSC1_V2_DAG_JS_CHEAP_PROJECTION_POLICY: PASS");
  }
  {
    const boolName=name("Bool"),boolType=con(boolName);
    const boolTrue=con(get("psKernelBoolTrueName")),boolFalse=con(get("psKernelBoolFalseName"));
    const localName=name("prefix-reflect-x"),localNode=fvar(localName);
    const closed=letE(localName,boolType,boolTrue,b0);
    const Request=get("PsKernelDeclarationRequest");
    const admitted=accepted(get("psKernelV1AdmitDeclaration")(session(64n,1n),
      Request.ordinaryInductive({levelParams:nil,name:boolName,type:sort1,numParams:0n,isUnsafe:false,
        ctors:list([{name:get("psKernelBoolFalseName"),type:boolType.term},
          {name:get("psKernelBoolTrueName"),type:boolType.term}])})),
      "prefix-real-Bool-admission").session;
    const checker=get("psKernelKernelSessionChecker")(admitted,nil,S.safe);
    for(const fuel of fuelCases)for(const maxRecDepth of [0n,1n,2n]){
      for(const recDepth of [0n,13n,14n,15n,16n]){
        const scalar={...checker.context,maxRecDepth,recDepth};
        compare(original(fuel,scalar,checker.state,closed.term,boolTrue.term),
          raw(fuel,typed(scalar),freshState(),closed.id,boolTrue.id),
          "prefix-closed-reflection-"+fuel+"-"+maxRecDepth+"-"+recDepth);
      }
      const current={...admitted,resources:{...admitted.resources,fuel,maxRecDepth}};
      must(sameOperation(get("psKernelV1IsDefEq")(current,nil,S.safe,closed.term,boolTrue.term),
        invoke(prefixArena,[C.isDefEq(closed.id,boolTrue.id)],current),boolEqual),
        "prefix-reflection-public-"+fuel+"-"+maxRecDepth);
    }
    const oldLocals=get("psKernelLocalContextAddLet")(checker.context.localContext,
      localName,localName,boolType.term,boolTrue.term);
    const withValue=scalar=>get("psKernelExprV2CheckContextWithLet")(
      typed(scalar),localName,localName,boolType.id,boolTrue.id);
    for(const eagerReduce of [false,true]){
      for(const fuel of fuelCases)for(const maxRecDepth of [0n,1n,2n]){
        for(const recDepth of [0n,13n,14n,15n,16n]){
          const scalar={...checker.context,eagerReduce,maxRecDepth,recDepth};
          const oldContext=get("psKernelCheckerContextWithLocalContext")(scalar,oldLocals);
          compare(original(fuel,oldContext,checker.state,localNode.term,boolTrue.term),
            raw(fuel,withValue(scalar),freshState(),localNode.id,boolTrue.id),
            "prefix-local-reflection-"+eagerReduce+"-"+fuel+"-"+maxRecDepth+"-"+recDepth);
        }
      }
      const scalar={...checker.context,eagerReduce},context=withValue(scalar);
      const boundary=accepted(raw(3n,context,freshState(),localNode.id,boolTrue.id),
        "prefix-eager-boundary-some");
      if(eagerReduce)must(rejected(boundary)&&boundary.error==="kernel reduction budget exhausted",
        "prefix-eager-public-whnf-budget");
      else{
        const result=accepted(boundary,"prefix-inert-core-result");
        must(result.snd===true&&array(result.fst.success).length===0,
          "prefix-inert-core-budget-and-open-cache");
      }
      const warm=accepted(accepted(raw(64n,context,freshState(),localNode.id,boolTrue.id),
        "prefix-local-success-some"),"prefix-local-success");
      must(warm.snd===true&&array(warm.fst.success).length===0,
        "prefix-free-variable-success-never-published-"+eagerReduce);
      const valueFree=get("psKernelExprV2CheckContextWithLocal")(
        typed(scalar),localName,localName,boolType.id,B.default);
      must(sameRuntimeValue(raw(64n,valueFree,freshState(),localNode.id,boolTrue.id),none),
        "prefix-value-free-local-remains-undecided-"+eagerReduce);
    }
    must(sameRuntimeValue(raw(64n,typed(checker.context),freshState(),closed.id,boolFalse.id),none),
      "prefix-reflection-is-not-a-false-constructor-rule");
    must(sameOperation(get("psKernelV1IsDefEq")(admitted,nil,S.safe,closed.term,boolFalse.term),
      invoke(prefixArena,[C.isDefEq(closed.id,boolFalse.id)],admitted),boolEqual),
      "prefix-false-constructor-fallback-public-parity");
    console.log("PSC1_V2_DAG_JS_DEFEQ_REFLECTION: PASS");
  }
  {
    const checker=get("psKernelKernelSessionChecker")(session(64n,1n),nil,S.safe);
    const context=typed(checker.context);
    const gx=name("prefix-guard-x"),gy=name("prefix-guard-y");
    const open=fvar(gx),truth=con(get("psKernelBoolTrueName")),falsehood=con(get("psKernelBoolFalseName"));
    const polyTruth=con(get("psKernelBoolTrueName"),list([L.zero])),hiddenTruth=md(1n,truth);
    const leftLambda=lam(gx,s1,md(1n,b0)),rightLambda=lam(gy,s1,md(2n,b0));
    const initial=freshState();
    let whnfCalls=0;
    const denyWhnf=ctx=>state=>root=>{
      whnfCalls++;
      return core(0n,ctx,state,root,false);
    };
    for(const [left,right,eagerReduce,wantedCalls] of [
      [s0,truth,false,1],[open,truth,false,0],[open,truth,true,1],
      [s0,falsehood,true,0],[s0,polyTruth,true,0],[s0,hiddenTruth,true,0]]){
      whnfCalls=0;
      const current={...context,scalar:{...context.scalar,eagerReduce}};
      const attempt=accepted(get("psKernelExprV2DefEqReflectionWith")(
        denyWhnf,current,initial,left.id,right.id),"prefix-reflection-gate-some");
      must(whnfCalls===wantedCalls,"prefix-reflection-exact-callback-gate");
      if(wantedCalls)must(rejected(attempt)&&attempt.error==="kernel reduction budget exhausted",
        "prefix-reflection-preserves-callback-error");
      else{
        const result=accepted(attempt,"prefix-reflection-undecided");
        must(sameRuntimeValue(result.snd,none)&&array(result.fst.success).length===0,
          "prefix-reflection-undecided-is-not-false");
      }
    }
    let defeqCalls=0;
    const denyDefEq=ctx=>state=>left=>right=>{
      defeqCalls++;return raw(0n,ctx,state,left,right);
    };
    const oldDeny=ctx=>state=>left=>right=>original(0n,ctx,state,left,right);
    const blocked={...context,scalar:{...context.scalar,recDepth:16n}};
    const oldQuick=accepted(get("psKernelDefEqQuick")(
      oldDeny,blocked.scalar,checker.state,s0.term,m0.term,false),"prefix-old-second-quick");
    const newQuick=accepted(accepted(get("psKernelExprV2DefEqQuickWith")(
      denyDefEq,blocked,initial,s0.id,m0.id,false),"prefix-new-second-quick-some"),
      "prefix-new-second-quick");
    must(accepted(oldQuick.fst,"prefix-old-second-quick-decision")===true&&
      accepted(newQuick.snd,"prefix-new-second-quick-decision")===true&&
      array(newQuick.fst.success).length===0&&defeqCalls===0,
      "prefix-second-quick-has-no-extra-entry-or-publication");
    compare(original(64n,blocked.scalar,checker.state,s0.term,m0.term),
      raw(64n,blocked,initial,s0.id,m0.id),"prefix-real-entry-still-checks-depth");
    const oldWarm=accepted(original(64n,checker.context,checker.state,zeta.term,m0.term),
      "prefix-old-original-pair-prime");
    const newWarm=accepted(accepted(raw(64n,context,initial,zeta.id,m0.id),
      "prefix-new-original-pair-prime-some"),"prefix-new-original-pair-prime");
    const contains=(left,right)=>accepted(get("psKernelExprV2DefEqPairContains")(
      newWarm.fst.whnf.arena,newWarm.fst.success,left,right),"prefix-pair-contains");
    must(newWarm.snd===true&&contains(zeta.id,m0.id)===true&&contains(s0.id,m0.id)===false,
      "prefix-second-quick-publishes-only-original-pair");
    for(const fuel of [0n,1n,2n])for(const recDepth of [0n,15n,16n]){
      const scalar={...checker.context,recDepth};
      compare(original(fuel,scalar,oldWarm.snd,zeta.term,m0.term),
        raw(fuel,typed(scalar),newWarm.fst,zeta.id,m0.id),
        "prefix-warm-original-pair-guards-"+fuel+"-"+recDepth);
    }
    const unsupported=_=>_=>_=>_=>none;
    whnfCalls=0;
    must(sameRuntimeValue(get("psKernelExprV2DefEqPrefixWith")(
      unsupported,denyWhnf,denyWhnf,context,initial,leftLambda.id,rightLambda.id),none)&&
      whnfCalls===0,"prefix-unsupported-quick-descendant-aborts-before-whnf");
    whnfCalls=0;defeqCalls=0;
    const initialQuick=accepted(accepted(get("psKernelExprV2DefEqPrefixWith")(
      denyDefEq,denyWhnf,denyWhnf,context,initial,s0.id,m0.id),
      "prefix-definitive-initial-some"),"prefix-definitive-initial-result");
    must(initialQuick.snd===true&&whnfCalls===0&&defeqCalls===0,
      "prefix-definitive-initial-quick-skips-whnf");
    console.log("PSC1_V2_DAG_JS_DEFEQ_PREFIX_GUARDS: PASS");
  }
}

{
  const H=get("PsKernelReducibilityHints"),Reply=get("PsKernelDagReply"),
    CI=get("PsKernelConstantInfo"),Option=get("Option"),
    none=typeof Option.none==="function"?Option.none():Option.none;
  const aName=name("DagMutualAdmissionA"),bName=name("DagMutualAdmissionB"),
    externalName=name("DagMutualAdmissionExternal"),u=name("dag-mutual-u"),
    v=name("dag-mutual-v"),x=name("dag-mutual-x");
  let graph=empty;
  const put=(kind,...args)=>{const r=mk(graph,kind,...args);graph=r.fst;return r.snd;};
  const s0=put("Sort",L.zero),s1=put("Sort",L.succ(L.zero)),
    su=put("Sort",L.param(u)),su1=put("Sort",L.succ(L.param(u))),
    ca=put("Const",aName,nil),cb=put("Const",bName,nil),external=put("Const",externalName,nil),
    mv=put("MVar",u),fv=put("FVar",u),b0=put("BVar",0n),
    appA=put("App",ca,b0),appB=put("App",cb,b0),
    bodyA=put("Lam",x,s1,appB,B.default),bodyB=put("Lam",x,s1,appA,B.default),
    functionType=put("Forall",x,s1,s1,B.default);
  const built=accepted(decode(graph),"mutual-matrix-decode");
  const input=(name,params,type,value,safety)=>({base:{name,levelParams:list(params),type},
    value,hints:H.abbrevHint,safety});
  const a=(params,type,value,safety)=>input(aName,params,type,value,safety),
    b=(params,type,value,safety)=>input(bName,params,type,value,safety),
    unsafePair=[a([],s1,cb,S.unsafeDef),b([],s1,ca,S.unsafeDef)],
    partialPair=[a([],s1,cb,S.partialDef),b([],s1,ca,S.partialDef)],
    unsafeFunctions=[a([],functionType,bodyA,S.unsafeDef),b([],functionType,bodyB,S.unsafeDef)],
    partialFunctions=[a([],functionType,bodyA,S.partialDef),b([],functionType,bodyB,S.partialDef)];
  const seedRequest=D.axiomDecl({name:externalName,levelParams:nil,type:s1},true),seed=session(64n,1n),
    owner=accepted(get("psKernelDagRunCommand")(
      {session:seed,declarations:nil},nil,S.safe,graph,built,C.admit(seedRequest)),"mutual-seed").snd;
  const cases=[
    ["empty",[],false,"invalid empty mutual definition"],
    ["safe-group",[a([],s1,s0,S.safe)],false,
      "invalid mutual definition, declaration is not tagged as unsafe/partial"],
    ["unsafe-self",[a([],s1,ca,S.unsafeDef)],true,null],
    ["unsafe-forward-peers",unsafePair,true,null],
    ["partial-forward-peers",partialPair,true,null],
    ["unsafe-functions",unsafeFunctions,true,null],
    ["partial-functions",partialFunctions,true,null],
    ["unsafe-external",[a([],s1,external,S.unsafeDef)],true,null],
    ["partial-rejects-unsafe-external",[a([],s1,external,S.partialDef)],false,null],
    ["polymorphic",[a([u],su1,su,S.unsafeDef),b([u],su1,su,S.unsafeDef)],true,null],
    ["safety-before-other-header-errors",[a([],s1,s0,S.unsafeDef),a([u],mv,mv,S.partialDef)],false,
      "invalid mutual definition, declarations must have the same safety annotation"],
    ["parameter-list-before-duplicate-and-mvar",[a([u],s1,s0,S.unsafeDef),a([],mv,mv,S.unsafeDef)],false,
      "invalid mutual definition, declarations must have the same universe level parameters"],
    ["ordered-parameters",[a([u,v],s1,s0,S.unsafeDef),b([v,u],s1,s0,S.unsafeDef)],false,
      "invalid mutual definition, declarations must have the same universe level parameters"],
    ["duplicate-name-before-header-mvar",[a([],s1,s0,S.unsafeDef),a([],mv,mv,S.unsafeDef)],false,
      "invalid mutual definition, duplicate declaration name"],
    ["existing-name",[input(externalName,[],s1,s0,S.unsafeDef)],false,"already declared"],
    ["peer-unavailable-in-header",[a([],cb,mv,S.unsafeDef),b([],s1,s0,S.unsafeDef)],false,null],
    ["all-headers-before-any-body",[a([],s1,mv,S.unsafeDef),b([],fv,s0,S.unsafeDef)],false,
      "declaration has free variables"],
    ["first-body-before-second-body",[a([],s1,mv,S.unsafeDef),b([],s1,fv,S.unsafeDef)],false,
      "declaration has metavariables"],
    ["first-body-mismatch-before-later-mvar",[a([],s1,s1,S.unsafeDef),b([],s1,mv,S.unsafeDef)],false,
      "definition type mismatch"],
    ["body-level-guard",[a([],s1,su,S.unsafeDef)],false,
      "invalid reference to undefined universe level parameter"]
  ];
  const publicCompare=(original,actual,label)=>{
    if(rejected(original)||rejected(actual))must(rejected(original)&&rejected(actual)&&
      sameRuntimeValue(original.error,actual.error),label+"-error");
    else{const left=accepted(original,label+"-old"),right=accepted(actual,label+"-dag");
      must(sameRuntimeValue(left.session,right.session)&&
        sameRuntimeValue(right.replies,list([Reply.admitted(left.declaration.receipt)])),label+"-result");}
  };
  let comparisons=0;
  for(const [label,inputs,acceptedAt64,messageAt64] of cases){
    const candidate=D.mutualDefinitions(list(inputs)),declaration=accepted(
      get("psKernelDagDecodeDeclaration")(built,candidate),"mutual-request");
    for(const fuel of [0n,1n,2n,3n,4n,8n,64n])for(const maxRecDepth of [0n,1n]){
      const current={...owner.session,resources:{...owner.session.resources,fuel,maxRecDepth}};
      const direct=accepted(get("psKernelDagTryAdmitSimpleWithFuel")(fuel,
        get("psKernelKernelSessionEnvironment")(current),maxRecDepth,current.resources.maxNatSize,
        graph,owner.declarations,candidate,declaration),"mutual-required-direct-"+label+"-"+fuel);
      must(sameRuntimeValue(get("psKernelV1DispatchDeclaration")(current,declaration),
        get("psKernelV1EnvironmentOutcome")(direct)),"mutual-raw-parity-"+label+"-"+fuel+"-"+maxRecDepth);
      const original=get("psKernelV1AdmitDeclaration")(current,declaration);
      publicCompare(original,run(current,nil,S.safe,graph,list([C.admit(candidate)])),
        "mutual-public-"+label+"-"+fuel+"-"+maxRecDepth);
      if(fuel===64n){
        must((!rejected(original))===acceptedAt64,"mutual-expected-decision-"+label);
        if(messageAt64!==null)must(rejected(original)&&sameRuntimeValue(original.error,
          get("PsKernelError").rejectedInvalid(messageAt64)),"mutual-exact-message-"+label);
        const whole=run(session(fuel,maxRecDepth),nil,S.safe,graph,
          list([C.admit(seedRequest),C.admit(candidate)]));
        if(rejected(original)||rejected(whole))must(rejected(original)&&rejected(whole)&&
          sameRuntimeValue(original.error,whole.error),"mutual-same-batch-error-"+label);
        else{const left=accepted(original,"mutual-whole-old"),right=accepted(whole,"mutual-whole-dag");
          must(sameRuntimeValue(left.session,right.session)&&array(right.replies).length===2,
            "mutual-same-batch-result-"+label);}
      }
      comparisons++;
    }
  }
  must(comparisons===280,"mutual-admission-matrix-count");
  const partialRequest=D.mutualDefinitions(list(partialPair)),partialDeclaration=accepted(
    get("psKernelDagDecodeDeclaration")(built,partialRequest),"mutual-partial-declaration"),
    published=accepted(get("psKernelDagRunCommand")(
      owner,nil,S.safe,graph,built,C.admit(partialRequest)),"mutual-published");
  must(sameRuntimeValue(published.fst,Reply.admitted(published.fst.receipt))&&
    published.fst.receipt.declarationsBefore===1n&&published.fst.receipt.declarationsAfter===3n,
    "mutual-public-receipt-installs-whole-group");
  for(const value of partialPair){
    const reference=accepted(get("psKernelExprV2DeclarationRefFind")(
      published.snd.declarations)(value.base.name),"mutual-published-reference"),
      expected=accepted(get("psKernelDagDecodeDefinition")(built,value),"mutual-expected-record"),
      stored=accepted(get("psKernelEnvironmentFind")(
        published.snd.session.environment,value.base.name),"mutual-stored-definition");
    must(reference.type===value.base.type&&sameRuntimeValue(reference.deltaValue,Option.some(value.value))&&
      sameRuntimeValue(reference.kind,get("PsKernelExprV2DeclarationRefKind").definitionDecl),
      "mutual-success-publishes-original-peer-ids");
    must(sameRuntimeValue(stored,CI.defnInfo(expected)),"mutual-stored-partial-body-and-annotation");
  }
  const aExpression=accepted(decoded(built,ca),"mutual-a-expression"),
    oldSafe=get("psKernelV1CheckExpression")(published.snd.session,nil,S.safe,aExpression),
    safeBatch=run(seed,nil,S.safe,graph,list([C.admit(seedRequest),C.admit(partialRequest),C.check(ca)]));
  must(rejected(oldSafe)&&rejected(safeBatch)&&sameRuntimeValue(oldSafe.error,safeBatch.error),
    "mutual-partial-admission-never-authorizes-safe-use");
  const partialBatch=accepted(run(seed,nil,S.partialDef,graph,
    list([C.admit(seedRequest),C.admit(partialRequest),C.check(ca),C.check(cb)])),"mutual-partial-context"),
    replies=array(partialBatch.replies),left=replies.at(-2),right=replies.at(-1);
  must(left!==undefined&&right!==undefined&&sameRuntimeValue(left,Reply.checked(left.value))&&
    sameRuntimeValue(right,Reply.checked(right.value))&&exact(left.value.type,sort1)&&exact(right.value.type,sort1),
    "mutual-partial-context-can-check-both-peers");
  const limited={...owner.session,resources:{...owner.session.resources,maxDeclarations:2n}},
    badRequest=D.mutualDefinitions(list([a([],s1,s1,S.unsafeDef),b([],s1,s0,S.unsafeDef)])),
    badDeclaration=accepted(get("psKernelDagDecodeDeclaration")(built,badRequest),"mutual-bad-declaration");
  for(const [candidate,declaration] of [[partialRequest,partialDeclaration],[badRequest,badDeclaration]])
    publicCompare(get("psKernelV1AdmitDeclaration")(limited,declaration),
      run(limited,nil,S.safe,graph,list([C.admit(candidate)])),"mutual-limit-after-complete-body-check");
  const validLimit=get("psKernelDagAdmitDeclaration")(
    limited,graph,owner.declarations,partialRequest,partialDeclaration),
    invalidLimit=get("psKernelDagAdmitDeclaration")(
      limited,graph,owner.declarations,badRequest,badDeclaration);
  must(rejected(validLimit)&&sameRuntimeValue(validLimit.error,
    get("PsKernelError").resourceExhausted(get("PsKernelResourceError").declarationLimit,
      "declaration limit exceeded")),"mutual-valid-group-reaches-declaration-limit");
  must(rejected(invalidLimit)&&sameRuntimeValue(invalidLimit.error,
    get("PsKernelError").rejectedInvalid("definition type mismatch")),
    "mutual-invalid-first-body-precedes-declaration-limit");
  const malformed=D.mutualDefinitions(list([
    input(externalName,[],s1,s0,S.unsafeDef),b([],s1,graph.size,S.unsafeDef)])),
    malformedDecoded=get("psKernelDagDecodeDeclaration")(built,malformed),
    malformedPublic=run(owner.session,nil,S.safe,graph,list([C.admit(malformed)]));
  must(rejected(malformedDecoded)&&rejected(malformedPublic)&&sameRuntimeValue(malformedPublic.error,
    get("PsKernelError").rejectedInvalid(malformedDecoded.error)),
    "mutual-malformed-second-id-precedes-first-header-error");
  const cancelled={...owner.session,resources:{...owner.session.resources,cancelled:true}},
    cancellation=run(cancelled,nil,S.safe,graph,list([C.admit(malformed)])),
    preflight=get("psKernelKernelSessionPreflight")(cancelled);
  must(rejected(cancellation)&&rejected(preflight)&&sameRuntimeValue(cancellation.error,preflight.error),
    "mutual-preflight-precedes-malformed-member");
  must(sameRuntimeValue(get("psKernelEnvironmentFind")(owner.session.environment,aName),none)&&
    sameRuntimeValue(get("psKernelExprV2DeclarationRefFind")(owner.declarations)(aName),none),
    "mutual-private-failure-does-not-publish-environment-or-index");
  const externalRequest=D.mutualDefinitions(list([a([],s1,external,S.unsafeDef)])),
    externalDeclaration=accepted(get("psKernelDagDecodeDeclaration")(built,externalRequest),
      "mutual-external-declaration");
  must(sameRuntimeValue(get("psKernelDagTryAdmitSimpleWithFuel")(64n,
    get("psKernelKernelSessionEnvironment")(owner.session),1n,owner.session.resources.maxNatSize,
    graph,nil,externalRequest,externalDeclaration),none),"mutual-preexisting-session-type-explicit-fallback");
  publicCompare(get("psKernelV1AdmitDeclaration")(owner.session,externalDeclaration),
    run(owner.session,nil,S.safe,graph,list([C.admit(externalRequest)])),
    "mutual-preexisting-session-public-fallback-parity");
  console.log("PSC1_V2_DAG_JS_MUTUAL_ADMISSION: PASS");
}

{
  const H=get("PsKernelReducibilityHints");
  for(const [layers,fuel,maxDepth,coldMessage] of [
    [4,5n,0n,"kernel inference budget exhausted"],
    [15,64n,1n,"deep recursion detected, use maxRecDepth to increase the limit"]
  ])for(const safety of [S.unsafeDef,S.partialDef]){
    const seed=session(fuel,maxDepth),aName=name("MutualFreshA"+layers),
      bName=name("MutualFreshB"+layers),x=name("mutual-fresh-x");
    let graph=empty;
    const put=(kind,...args)=>{const r=mk(graph,kind,...args);graph=r.fst;return r.snd;};
    const s1=put("Sort",L.succ(L.zero));let firstBody=s1;
    for(let tag=0;tag<layers;tag++)firstBody=put("MData",BigInt(tag),firstBody);
    const s2=put("Sort",L.succ(L.succ(L.zero))),b0=put("BVar",0n),
      secondBody=put("Lam",x,firstBody,b0,B.default),
      secondType=put("Forall",x,s1,s1,B.default),built=accepted(decode(graph),"mutual-fresh-decode"),
      firstExpression=accepted(decoded(built,firstBody),"mutual-fresh-first-expression"),
      secondExpression=accepted(decoded(built,secondBody),"mutual-fresh-second-expression"),
      checker=get("psKernelKernelSessionChecker")(seed,nil,safety),
      context=get("psKernelExprV2CheckContextEmpty")(checker.context),
      initial=get("psKernelExprV2CheckStateEmpty")(graph);
    const oldPrimed=accepted(get("psKernelSessionCheck")(fuel,checker,firstExpression),"mutual-old-primed"),
      primed=accepted(accepted(get("psKernelExprV2TryCheckStateWithFuel")(
        fuel,context,initial,firstBody),"mutual-prime-selected"),"mutual-prime-ok"),
      oldWarm=accepted(get("psKernelSessionCheck")(
        fuel,oldPrimed.snd,secondExpression),"mutual-old-warm"),
      warm=accepted(accepted(get("psKernelExprV2TryCheckStateWithFuel")(
        fuel,context,primed.fst,secondBody),"mutual-warm-selected"),"mutual-warm-ok"),
      resultGraph=accepted(decode(warm.fst.whnf.arena),"mutual-warm-result-graph"),
      resultType=accepted(decoded(resultGraph,warm.snd),"mutual-warm-type");
    must(exact(oldWarm.fst,resultType)&&oldWarm.snd.state.nextFresh===warm.fst.nextFresh,
      "mutual-member-cache-sharing-would-change-result-"+layers);
    const oldCold=get("psKernelSessionCheck")(fuel,checker,secondExpression),
      cold=accepted(get("psKernelExprV2TryCheckStateWithFuel")(
        fuel,context,initial,secondBody),"mutual-cold-selected");
    must(rejected(oldCold)&&rejected(cold)&&oldCold.error===coldMessage&&cold.error===coldMessage,
      "mutual-next-member-fresh-cache-resource-error-"+layers);
    const inputs=[
      {base:{name:aName,levelParams:nil,type:s2},value:firstBody,hints:H.abbrevHint,safety},
      {base:{name:bName,levelParams:nil,type:secondType},value:secondBody,hints:H.abbrevHint,safety}],
      request=D.mutualDefinitions(list(inputs)),declaration=accepted(
        get("psKernelDagDecodeDeclaration")(built,request),"mutual-fresh-request"),
      direct=accepted(get("psKernelDagTryAdmitSimpleWithFuel")(fuel,
        get("psKernelKernelSessionEnvironment")(seed),maxDepth,seed.resources.maxNatSize,
        graph,nil,request,declaration),"mutual-fresh-selected");
    must(rejected(direct)&&direct.error===coldMessage,"mutual-admission-resets-owner-for-each-body-"+layers);
    const original=get("psKernelV1AdmitDeclaration")(seed,declaration),
      actual=run(seed,nil,S.safe,graph,list([C.admit(request)]));
    must(rejected(original)&&rejected(actual)&&sameRuntimeValue(original.error,actual.error)&&
      sameRuntimeValue(original.error,get("psKernelErrorFromMessage")(coldMessage)),
      "mutual-fresh-owner-public-resource-parity-"+layers);
  }
  console.log("PSC1_V2_DAG_JS_MUTUAL_FRESH_MEMBER: PASS");
}

reportDagSmoke();
