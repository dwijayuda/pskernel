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

const json=x=>JSON.stringify(x,(_,v)=>typeof v==="bigint"?String(v):v);
const checkedResult=r=>{
  if(rejected(r))return {error:r.error};
  const replies=array(accepted(r,"batch-result").replies);
  if(replies.length!==1)throw Error("PSC1_DAG_WRONG_REPLY_COUNT");
  return {value:replies[0].value};
};
const sameOperation=(original,actual,compare)=>{
  if(rejected(original))return rejected(actual)&&json(original.error)===json(actual.error);
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
      must(rejected(actual)&&json(original.error)===json(actual.error),
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
        must(rejected(actual)&&json(original.error)===json(actual.error),
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
const source=readFileSync(filename,"utf8");
must(!/from\s*["'](?:lean|node:child_process)|require\(["'](?:lean|child_process)/.test(source),
  "independent-generated-runtime");
if(typeof global.gc==="function")global.gc();
console.log("PSC1_V2_DAG_JS_SUMMARY "+JSON.stringify({
  node:process.version,source_bytes:statSync(filename).size,
  peak_rss_kib:process.resourceUsage().maxRSS,
  post_gc_heap_bytes:process.memoryUsage().heapUsed,
  semantics:"complete KernelContract-v1 via one checked DAG input boundary",
  checker_representation:"DAG terminal inference/WHNF and checked structural shortcut; legacy composite fallback; incomplete"
}));
console.log("PSC1_V2_DAG_JS: PASS");
