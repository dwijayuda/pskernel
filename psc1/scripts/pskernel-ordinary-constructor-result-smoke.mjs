import {pathToFileURL} from "node:url";
import path from "node:path";

// T05 private constructor-result helpers only. The reference helpers are frozen
// at 0d9f062846d109c362210d441df5fd407ca2cdd7:
// Ordinary/Constructor.lean blob 56a70b8ac94283694bf375a8d5c8e7adfd3859b7;
// Common/Occurrence.lean blob a8b911d20a603b46edcc63a0bf000c1bacec5341.
// This harness calls the actual new helpers directly. It does not admit a
// constructor, publish a declaration, or use the public admission fallback.
if(process.argv.length!==3)throw Error("PSC1_CONSTRUCTOR_RESULT_REQUIRES_GENERATED_KERNEL");
const kernelPath=path.resolve(process.argv[2]);
const k=await import(pathToFileURL(kernelPath).href);
const get=n=>{if(!(n in k))throw Error("PSC1_CONSTRUCTOR_RESULT_MISSING_EXPORT "+n);return k[n];};
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
  throw Error("PSC1_CONSTRUCTOR_RESULT_REJECTED "+label+": "+String(v?.error));
};
const rejected=v=>v&&Object.hasOwn(v,"error");
let assertions=0,section="harness";
const counts={};
const must=(condition,label)=>{
  if(condition!==true)throw Error("PSC1_CONSTRUCTOR_RESULT_JS_FAIL "+section+"/"+label);
  assertions++;counts[section]=(counts[section]??0)+1;
};
must(!same(ok("same"),err("same"))&&!same(none,Option.some(none)),"constructor-tags");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo"),Literal=get("PsKernelLiteral");
const name=s=>N.str(unit(N.anonymous),s);
const target=name("T05Result"),other=name("Other"),pn=name("parameter-p"),qn=name("parameter-q");
const u=L.param(name("u")),v=L.param(name("v")),zero=unit(L.zero),one=L.succ(zero);
const bi=unit(B.default),implicit=unit(B.implicit),strict=unit(B.strictImplicit),instance=unit(B.instImplicit);
const term=(kind,args,expr)=>({kind,args,expr});
const sort=l=>term("Sort",[l],E.sort(l));
const bv=i=>term("BVar",[i],E.bvar(i));
const fv=n=>term("FVar",[n],E.fvar(n));
const mv=n=>term("MVar",[n],E.mvar(n));
const cn=(n,levels=[])=>term("Const",[n,list(levels)],E.const(n,list(levels)));
const app=(f,a)=>term("App",[f,a],E.app(f.expr,a.expr));
const apps=(f,args)=>args.reduce(app,f);
const lam=(n,t,b)=>term("Lam",[n,t,b,bi],E.lam(n,t.expr,b.expr,bi));
const all=(n,t,b)=>term("Forall",[n,t,b,bi],E.forallE(n,t.expr,b.expr,bi));
const letE=(n,t,a,b)=>term("Let",[n,t,a,b,false],E.letE(n,t.expr,a.expr,b.expr,false));
const md=b=>term("MData",[4242n,b],E.mdata(4242n,b.expr));
const proj=(n,b)=>term("Proj",[n,0n,b],E.proj(n,0n,b.expr));
const lit=x=>term("Lit",[x],E.lit(x));
const s0=sort(zero),s1=sort(one),T=cn(target),U=cn(other),p=fv(pn),q=fv(qn),i=cn(name("index-i")),j=cn(name("index-j"));
const empty=unit(get("psKernelExprV2PagedEmpty"));
function builder(){
  let arena=empty;
  const memo=new Map();
  const add=t=>{
    if(memo.has(t))return memo.get(t);
    const args=t.args.map(x=>x&&typeof x==="object"&&Object.hasOwn(x,"expr")&&Object.hasOwn(x,"kind")?add(x):x);
    const result=accepted(get("psKernelExprV2PagedMk"+t.kind)(arena,...args),"build-"+t.kind);
    arena=result.fst;memo.set(t,result.snd);return result.snd;
  };
  return {add,get arena(){return arena;}};
}
function decoder(arena){
  const decoded=accepted(get("psKernelExprV2DecodeChecked")(arena),"decode-arena");
  return root=>accepted(get("psKernelExprV2DecodedRequire")(decoded,root),"decode-root");
}
const mapOption=(xs,f)=>same(xs,none)?none:Option.some(list(array(accepted(xs,"option")).map(f)));
const mapExcept=(xs,f)=>rejected(xs)?xs:ok(list(array(accepted(xs,"except")).map(f)));
const param=(n,type=s1,user=name("user"),info=bi)=>({internalName:n,userName:user,type,binderInfo:info});
const P=param(pn),Q=param(qn);
const oldParams=pars=>list(pars.map(x=>({...x,type:x.type.expr})));
const idParams=(b,pars)=>list(pars.map(x=>({...x,type:b.add(x.type)})));
const shapeError="simple inductive constructor must return the declared datatype with matching parameters and index arity";
const occurrenceError="simple inductive constructor return index contains a recursive occurrence";
const badRoot="PSKERNEL_V2_PAGED_INVALID_CHILD",fuelError="PSKERNEL_V2_ORDINARY_CONTAINS_CONST_FUEL";
const out=unit(get("psKernelTypeAnnotationOutParamName"));
const recursiveApp=app(U,T),targetProjection=proj(target,i),receiverProjection=proj(other,T);
const targetFVar=fv(target),namedBinder=lam(target,s0,bv(0n)),levelLookalike=sort(L.param(target));
const rows=[
  ["S01",[],[],0n,T,[]],
  ["S02",[P],[],0n,apps(T,[p]),[]],
  ["S03",[P,Q],[],0n,apps(T,[p,q]),[]],
  ["S04",[P],[],1n,apps(T,[p,i]),[i]],
  ["S05",[P],[],2n,apps(T,[p,i,j]),[i,j]],
  ["S06",[P],[u,v],1n,apps(cn(target,[u,v]),[p,i]),[i]],
  ["S07",[P],[],1n,apps(U,[p,i]),null],
  ["S08",[],[],0n,fv(target),null],
  ["S09",[P],[u],1n,apps(cn(target,[v]),[p,i]),null],
  ["S10",[P],[u],1n,apps(T,[p,i]),null],
  ["S11",[P],[u],1n,apps(cn(target,[u,v]),[p,i]),null],
  ["S12",[P],[u,v],1n,apps(cn(target,[v,u]),[p,i]),null],
  ["S13",[P,Q],[],0n,apps(T,[p]),null],
  ["S14",[P],[],0n,apps(T,[q]),null],
  ["S15",[P,Q],[],0n,apps(T,[q,p]),null],
  ["S16",[P,Q],[],0n,apps(T,[p,p]),null],
  ["S17",[P],[],0n,apps(T,[bv(0n)]),null],
  ["S18",[P],[],0n,apps(T,[mv(pn)]),null],
  ["S19",[P],[],0n,apps(T,[md(p)]),null],
  ["S20",[P],[],0n,apps(T,[app(lam(name("x"),s1,bv(0n)),p)]),null],
  ["S21",[P],[],0n,apps(T,[app(cn(out),p)]),null],
  ["S22",[P],[],2n,apps(T,[p,i]),null],
  ["S23",[P],[],1n,apps(T,[p,i,j]),null],
  ["S24",[P],[],1n,md(apps(T,[p,i])),null],
  ["S25",[P],[],1n,apps(app(lam(name("x"),s1,bv(0n)),T),[p,i]),null],
  ["S26",[P],[],1n,apps(T,[p,recursiveApp]),[recursiveApp]],
  ["S27",[P],[],1n,apps(T,[p,targetProjection]),[targetProjection]],
  ["S28",[P],[],1n,apps(T,[p,receiverProjection]),[receiverProjection]],
  ["S29",[P],[],1n,apps(T,[p,targetFVar]),[targetFVar]],
  ["S30",[P],[],1n,apps(T,[p,namedBinder]),[namedBinder]],
  ["S31",[P],[],1n,apps(T,[p,levelLookalike]),[levelLookalike]],
  ["S32",[P],[],2n,apps(T,[p,i,T]),[i,T]]
];
// Descriptor fields other than internalName cannot alter structural matching.
const variants=rows.filter(row=>["S04","S05","S14","S19"].includes(row[0])).flatMap(row=>
  [[s0,implicit],[sort(v),strict],[s1,instance]].map(([type,info],variant)=>
    [row[0]+"-descriptor-"+variant,row[1].map(x=>param(x.internalName,type,name("changed-user"),info)),...row.slice(2)]));
rows.push(...variants,
  ["shared-index",[P],[],2n,apps(T,[p,i,i]),[i,i]],
  ["shared-recursive-index",[P],[],2n,apps(T,[p,T,T]),[T,T]]);
if(rows.length!==46)throw Error("PSC1_CONSTRUCTOR_RESULT_SELECTOR_INVENTORY");
section="selector";
for(const [label,pars,levels,count,t,expected] of rows){
  const b=builder(),params=idParams(b,pars),root=b.add(t);
  // Expected suffixes reuse the original fixture objects and therefore retain
  // their exact IDs independently of structural interning behavior.
  const expectedIDs=expected===null?null:expected.map(x=>b.add(x));
  const arena=b.arena,decode=decoder(arena),old=oldParams(pars);
  const actual=accepted(get("psKernelExprV2OrdinaryInductiveAppIndices")(arena,target,list(levels),params,count,root),label);
  const reference=get("psKernelSimpleInductiveAppIndices")(target,list(levels),old,count,t.expr);
  must(same(mapOption(actual,decode),reference),label+"/selector-V1");
  const validated=get("psKernelExprV2OrdinaryValidateConstructorResult")(arena,target,list(levels),params,count,root);
  must(same(mapExcept(validated,decode),get("psKernelValidateSimpleConstructorResult")(target,list(levels),old,count,t.expr)),label+"/validator-V1");
  must(same(actual,expectedIDs===null?none:Option.some(list(expectedIDs))),label+"/original-index-IDs");
}

section="consumer";
const consumerRows=[
  [[],[],[]],[[],[i,p],[i,p]],[[P],[],null],[[P],[p],[]],[[P],[p,i],[i]],
  [[P,Q],[p,q,i,j],[i,j]],[[P],[q],null],[[P],[bv(0n)],null],[[P,Q],[p,p],null],[[P],[md(p)],null]
];
for(const [pars,args,expected] of consumerRows){
  const b=builder(),params=idParams(b,pars),ids=args.map(x=>b.add(x));
  const expectedIDs=expected===null?null:expected.map(x=>b.add(x)),arena=b.arena,decode=decoder(arena);
  const actual=accepted(get("psKernelExprV2OrdinaryConsumeResultParams")(params)(arena)(list(ids)),"consumer");
  must(same(actual,expectedIDs===null?none:Option.some(list(expectedIDs))),"exact-suffix");
  must(same(mapOption(actual,decode),get("psKernelConsumeSimpleResultParams")(oldParams(pars))(list(args.map(x=>x.expr)))),"V1-prefix");
}
const cb=builder(),cp=idParams(cb,[P]),cpq=idParams(cb,[P,Q]),pid=cb.add(p),qid=cb.add(q),ca=cb.arena;
for(const [pars,args,expected] of [
  [nil,[999999n],ok(Option.some(list([999999n])))],
  [cp,[qid,999999n],ok(none)],
  [cpq,[qid,999999n],ok(none)],
  [cpq,[pid,999999n],err(badRoot)],
  [cp,[pid,999999n],ok(Option.some(list([999999n])))],
  [cp,[999999n],err(badRoot)]
])must(same(get("psKernelExprV2OrdinaryConsumeResultParams")(pars)(ca)(list(args)),expected),"lookup-and-short-circuit");

section="occurrence";
const shared=md(T);
const occurrenceTerms=[
  bv(0n),fv(target),mv(target),sort(L.param(target)),T,U,cn(target,[v]),lit(Literal.nat(17n)),lit(Literal.str("T05")),
  app(T,U),app(U,T),app(U,U),
  lam(target,s0,bv(0n)),lam(name("x"),T,U),lam(name("x"),U,T),
  all(target,s0,bv(0n)),all(name("x"),T,U),all(name("x"),U,T),
  letE(target,s0,U,bv(0n)),letE(name("x"),T,U,U),letE(name("x"),U,T,U),letE(name("x"),U,U,T),
  md(U),md(T),proj(target,U),proj(other,T),proj(other,U),
  apps(U,[T,T]),app(shared,shared),all(name("x"),U,letE(name("y"),U,T,T))
];
if(occurrenceTerms.length!==30)throw Error("PSC1_CONSTRUCTOR_RESULT_OCCURRENCE_INVENTORY");
for(const t of occurrenceTerms){
  const b=builder(),root=b.add(t),arena=b.arena,entry=accepted(get("psKernelExprV2PagedRequire")(arena,root),"entry");
  for(const nameToFind of [target,other]){
    const reference=ok(get("psKernelExprContainsConst")(nameToFind,t.expr));
    must(same(get("psKernelExprV2OrdinaryContainsConstOnCanonical")(arena,nameToFind,root),reference),"canonical-V1");
    for(const bound of [entry.depth+1n,entry.depth+4n])
      must(same(get("psKernelExprV2OrdinaryContainsConstWithFuel")(bound)(arena)(nameToFind)(root),reference),"adequate-structural-bound");
    must(same(get("psKernelExprV2OrdinaryContainsConstWithFuel")(0n)(arena)(nameToFind)(root),err(fuelError)),"zero-before-node-kind");
  }
}

section="bounds";
must(same(get("psKernelExprV2OrdinaryContainsConstWithFuel")(0n)(empty)(target)(999999n),err(fuelError)),"zero-before-invalid-root");
must(same(get("psKernelExprV2OrdinaryContainsConstWithFuel")(1n)(empty)(target)(999999n),err(badRoot)),"positive-invalid-root");
const deep=app(U,U);
const boundRows=[
  [T,1n,ok(true)],[U,1n,ok(false)],[proj(target,U),1n,ok(true)],[proj(other,T),1n,err(fuelError)],
  [app(T,deep),2n,ok(true)],[app(deep,T),2n,err(fuelError)],
  [lam(name("x"),T,deep),2n,ok(true)],[all(name("x"),T,deep),2n,ok(true)],
  [letE(name("x"),T,deep,deep),2n,ok(true)],[letE(name("x"),U,T,deep),2n,ok(true)],
  [letE(name("x"),U,deep,T),2n,err(fuelError)],[md(T),1n,err(fuelError)],[md(T),2n,ok(true)],
  [app(U,T),2n,ok(true)]
];
for(const [t,bound,expected] of boundRows){
  const b=builder(),root=b.add(t);
  must(same(get("psKernelExprV2OrdinaryContainsConstWithFuel")(bound)(b.arena)(target)(root),expected),"ordered-branch-bound");
}

section="indexLists";
const ib=builder(),tid=ib.add(T),uid=ib.add(U),ia=ib.arena;
for(const [ids,expected] of [
  [[],ok(false)],[[uid,tid],ok(true)],[[tid,999999n],ok(true)],[[999999n,tid],err(badRoot)],
  [[uid,999999n],err(badRoot)],[[uid,uid],ok(false)],[[tid,tid],ok(true)]
])must(same(get("psKernelExprV2OrdinaryIndicesContainTarget")(ia,target,list(ids)),expected),"first-hit-first-error");

section="precedence";
for(const [pars,levels,count,t] of [
  [[P],[],1n,apps(U,[p,T])],[[P],[u],1n,apps(T,[p,T])],
  [[P],[],1n,apps(T,[q,T])],[[P],[],2n,apps(T,[p,T])]
]){
  const b=builder(),params=idParams(b,pars),root=b.add(t);
  must(same(get("psKernelExprV2OrdinaryValidateConstructorResult")(b.arena,target,list(levels),params,count,root),err(shapeError)),
    "shape-before-recursive-index");
}

const expectedCounts={harness:1,selector:138,consumer:26,occurrence:240,bounds:16,indexLists:7,precedence:4};
if(assertions!==432||!same(counts,expectedCounts))
  throw Error("PSC1_CONSTRUCTOR_RESULT_ASSERTION_INVENTORY "+JSON.stringify({assertions,counts}));
console.log("PSC1_ORDINARY_CONSTRUCTOR_RESULT_JS: PASS assertions=432 fullAdmission=false");
console.log(JSON.stringify({schema:"psc1-ordinary-constructor-result-v1",kernel:kernelPath,assertions,
  sectionAssertions:counts,selectorRows:46,occurrenceTerms:30,targetsPerOccurrence:2,
  fullAdmission:false,publicRoutingChanged:false}));
