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
  checker_representation:"DAG terminal inference, beta/zeta/Nat/constructor-projection WHNF with separate core/public caches and checked quick DefEq rules; legacy general checker/delta/iota/admission fallback; incomplete"
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
  must(array(openResult.fst.coreCache).length===0&&
    array(openResult.fst.publicCache).length===0,"open-state-cache-ineligible");
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
    ["metadata-one-sided",qadd("MData",9n,q0),q0,E.mdata(9n,sort0),sort0],
    ["metadata-composite",qadd("MData",9n,redexId),qadd("MData",10n,q0),
      E.mdata(9n,redex),E.mdata(10n,sort0)],
    ["mixed-constructors",q0,qn0,sort0,E.lit(Literal.nat(0n))],
    ["constant-level-rule",qadd("Const",name("quick-missing"),list([L.max(L.zero,L.zero)])),
      qadd("Const",name("quick-missing"),list([L.zero])),
      E.const(name("quick-missing"),list([L.max(L.zero,L.zero)])),
      E.const(name("quick-missing"),list([L.zero]))]
  ];
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  for(const [label,leftId,rightId,left,right] of fallback){
    const checker=get("psKernelKernelSessionChecker")(session(),params,S.safe);
    must(sameRuntimeValue(quick(64n,checker.context,leftId,rightId),none),
      "quick-defeq-explicit-fallback-"+label);
    for(const fuel of [0n,1n,2n,3n,4n,8n,64n])for(const maxDepth of [0n,1n,2n]){
      const s=session(fuel,maxDepth);
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
    get("psKernelExprV2TryCheckCoreWithFuel")(fuel)
      (get("psKernelExprV2TryWhnfStateWithFuel")(fuel))
      (get("psKernelExprV2CheckContextEmpty")(context))(state)(root);
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
  must(sameRuntimeValue(direct.fst.whnf.publicCache,nil),"binder-scope-restores-public-cache");
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
    must(sameRuntimeValue(result.fst.checkedInfer,nil),"binder-literal-cache-ineligible");
  }
  const unsupported=[
    build("Let",E.letE(x,sort1,sort0,E.bvar(0n),false),x,s1.id,s0.id,b0.id,false),
    build("Proj",E.proj(name("binder-unknown-structure"),0n,sort0),
      name("binder-unknown-structure"),0n,s0.id)
  ];
  for(const node of unsupported){
    must(sameRuntimeValue(get("psKernelExprV2TryCheckWithFuel")(
      64n,checker.context,binderArena,node.id),none),"binder-explicit-full-checker-fallback");
    must(publicCheck(session(),node),"binder-fallback-public-parity");
  }
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
    const u1=L.succ(L.zero),duplicateUniverse=bs(L.max(u1,u1));
    const appFallbacks=[
      ["universe-conversion",app(lam(ax,duplicateUniverse,b0),s0),true],
      ["metadata-conversion",app(lam(ax,md(900n,s1),b0),s0),true],
      ["unequal-types",app(identity,s1),false]
    ];
    for(const [label,node,acceptedExpected] of appFallbacks){
      for(const fuel of [0n,1n,2n,3n,4n,8n,16n,64n]){
        const s=session(fuel,1n),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
        for(const recDepth of [0n,15n,16n]){
          const context={...checker.context,recDepth};
          const attempted=raw(fuel,context,emptyCheck(binderArena),node.id);
          if(!sameRuntimeValue(attempted,none)){
            compareRaw(get("psKernelSessionCheck")(fuel,{...checker,context},node.term),
              attempted,"application-fallback-guard-"+label+"-"+fuel+"-"+recDepth);
          }
        }
        must(publicCheck(s,node),"application-full-defeq-fallback-"+label+"-"+fuel);
      }
      const s=session(64n,1n),checker=get("psKernelKernelSessionChecker")(s,nil,S.safe);
      must(sameRuntimeValue(raw(64n,checker.context,emptyCheck(binderArena),node.id),none),
        "application-explicit-defeq-fallback-"+label);
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

reportDagSmoke();
