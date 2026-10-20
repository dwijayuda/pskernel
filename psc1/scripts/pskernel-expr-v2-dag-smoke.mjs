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
  checker_representation:"DAG terminal inference, terminal/metadata/beta/zeta WHNF with operation-owned function normalization and checked structural shortcut; legacy general checker fallback; incomplete"
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
  const attempted=get("psKernelExprV2TryWhnfWithFuel")(4096n)(checker.context)(graph.fst)(graph.snd);
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
        const attempted=get("psKernelExprV2TryWhnfWithFuel")(fuel)(checker.context)(betaArena)(root);
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
  const direct=get("psKernelExprV2TryWhnfWithFuel")(4n)(checker.context)(betaArena)(cacheRoot);
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
  const warmOld=accepted(get("psKernelSessionWhnf")(4n,checker,fixtures[0][1]),"warm-old");
  const warmAttempt=attemptedState(4n,checker.context,shared);
  must(warmAttempt&&typeof warmAttempt==="object"&&"value" in warmAttempt,"warm-dag-direct");
  const warmDag=accepted(warmAttempt.value,"warm-dag");
  const noCallback=()=>{throw Error("PSC1_DAG_UNEXPECTED_WARM_CORE_CALLBACK");};
  for(const context of [checker.context,{...checker.context,maxRecDepth:1n,recDepth:16n}]){
    for(const fuel of [0n,1n]){
      const original=get("psKernelWhnfCoreWithFuel")(fuel)
        (noCallback)(noCallback)(context)(warmOld.snd.state)(fixtures[0][1])(false)(false);
      const actual=get("psKernelExprV2TryWhnfCoreStateWithFuel")(fuel)
        (context)(warmDag.fst)(shared);
      compareState(original,actual,"state-warm-entry-guards-"+context.recDepth+"-"+fuel);
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
  must(array(openResult.fst.coreCache).length===0,"open-state-cache-ineligible");
  const letLocals=get("psKernelLocalContextAddLet")(checker.context.localContext,
    localName,localName,sort1,sort0);
  const letContext=get("psKernelCheckerContextWithLocalContext")(checker.context,letLocals);
  const declined=get("psKernelExprV2TryWhnfWithFuel")(64n)(letContext)(stateArena)(fvar);
  const Option=get("Option"),none=typeof Option.none==="function"?Option.none():Option.none;
  must(declined!==undefined&&sameRuntimeValue(declined,none),"local-let-value-explicit-fallback");
}
console.log("PSC1_V2_DAG_JS_WHNF_STATE: PASS");

reportDagSmoke();
